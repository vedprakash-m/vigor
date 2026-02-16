"""
Trust State Machine unit tests.
Tests the 5-phase trust progression, Safety Breaker, and trust_score logic.
Trust score uses 0-100 scale matching iOS.

We mock out the Cosmos SDK at import time to avoid the heavy azure-cosmos
dependency chain during tests.
"""

import sys
from unittest.mock import AsyncMock, MagicMock

import pytest

# Patch azure.cosmos.aio before importing our module
_cosmos_aio_mock = MagicMock()
sys.modules.setdefault("azure.cosmos.aio", _cosmos_aio_mock)
sys.modules.setdefault("azure.cosmos.exceptions", MagicMock())

from shared.cosmos_db import CosmosDBClient  # noqa: E402


# =============================================================================
# Helpers
# =============================================================================


def _make_client() -> CosmosDBClient:
    """Return a CosmosDBClient without calling initialize()."""
    client = CosmosDBClient()
    # Stub containers so ensure_initialized() doesn't try to connect
    client.client = True  # truthy sentinel
    client.containers = {}
    return client


def _default_state(
    phase: str = "observer",
    trust_score: float = 0.0,
    consecutive_deletes: int = 0,
) -> dict:
    return {
        "id": "test-id",
        "userId": "user@test.com",
        "phase": phase,
        "trust_score": trust_score,
        "consecutive_deletes": consecutive_deletes,
        "events": [],
    }


# =============================================================================
# _calculate_trust_delta
# =============================================================================


class TestCalculateTrustDelta:
    """Pure function — no I/O."""

    def setup_method(self):
        self.client = _make_client()

    def test_completed_workout_positive(self):
        assert self.client._calculate_trust_delta("completed_workout", "observer") == 5.0

    def test_missed_workout_negative(self):
        assert self.client._calculate_trust_delta("missed_workout", "observer") == -8.0

    def test_missed_workout_excuse_small_negative(self):
        assert self.client._calculate_trust_delta("missed_workout_excuse", "scheduler") == -2.0

    def test_user_deleted_block_large_negative(self):
        assert self.client._calculate_trust_delta("user_deleted_block", "auto_scheduler") == -15.0

    def test_suggestion_accepted(self):
        assert self.client._calculate_trust_delta("suggestion_accepted", "observer") == 3.0

    def test_auto_scheduled_completed(self):
        assert self.client._calculate_trust_delta("auto_scheduled_completed", "auto_scheduler") == 7.0

    def test_transformed_schedule_accepted(self):
        assert self.client._calculate_trust_delta("transformed_schedule_accepted", "transformer") == 8.0

    def test_unknown_event_zero(self):
        """_calculate_trust_delta still returns 0.0 for unrecognised types."""
        assert self.client._calculate_trust_delta("something_random", "observer") == 0.0


# =============================================================================
# _downgrade_phase (Safety Breaker)
# =============================================================================


class TestDowngradePhase:
    def setup_method(self):
        self.client = _make_client()

    def test_full_ghost_downgrades_to_transformer(self):
        assert self.client._downgrade_phase("full_ghost") == "transformer"

    def test_transformer_downgrades_to_auto_scheduler(self):
        assert self.client._downgrade_phase("transformer") == "auto_scheduler"

    def test_auto_scheduler_downgrades_to_scheduler(self):
        assert self.client._downgrade_phase("auto_scheduler") == "scheduler"

    def test_scheduler_downgrades_to_observer(self):
        assert self.client._downgrade_phase("scheduler") == "observer"

    def test_observer_cannot_downgrade_further(self):
        assert self.client._downgrade_phase("observer") == "observer"


# =============================================================================
# record_trust_event (integration — mocked I/O)
# =============================================================================


class TestRecordTrustEvent:
    """Tests the full record_trust_event flow with mocked Cosmos."""

    def setup_method(self):
        self.client = _make_client()
        self.client.ensure_initialized = AsyncMock()
        self.client.query_documents = AsyncMock(return_value=[])
        self.client.upsert_document = AsyncMock(side_effect=lambda c, d: d)

    @pytest.mark.asyncio
    async def test_new_user_gets_default_state(self):
        """First event should create a new observer state at trust_score 5.0."""
        result = await self.client.record_trust_event(
            "user@test.com", {"event_type": "completed_workout"}
        )
        assert result["phase"] == "observer"
        assert result["trust_score"] == 5.0
        # Verify persistence was called
        self.client.upsert_document.assert_called_once()
        args = self.client.upsert_document.call_args
        assert args[0][0] == "trust_states"

    @pytest.mark.asyncio
    async def test_trust_score_clamped_at_zero(self):
        """Trust score should never go below 0.0."""
        self.client.query_documents = AsyncMock(
            return_value=[_default_state(trust_score=1.0)]
        )
        result = await self.client.record_trust_event(
            "user@test.com", {"event_type": "missed_workout"}  # delta = -8.0
        )
        assert result["trust_score"] == 0.0

    @pytest.mark.asyncio
    async def test_trust_score_clamped_at_hundred(self):
        """Trust score should never exceed 100.0."""
        self.client.query_documents = AsyncMock(
            return_value=[_default_state(phase="full_ghost", trust_score=99.0)]
        )
        result = await self.client.record_trust_event(
            "user@test.com",
            {"event_type": "transformed_schedule_accepted"},  # delta = +8.0
        )
        assert result["trust_score"] == 100.0

    @pytest.mark.asyncio
    async def test_safety_breaker_on_three_deletes(self):
        """3 consecutive user_deleted_block events should downgrade phase."""
        state = _default_state(
            phase="auto_scheduler", trust_score=55.0, consecutive_deletes=2
        )
        self.client.query_documents = AsyncMock(return_value=[state])

        result = await self.client.record_trust_event(
            "user@test.com", {"event_type": "user_deleted_block"}
        )
        # Phase should have been downgraded from auto_scheduler → scheduler
        assert result["phase"] == "scheduler"
        assert result["consecutive_deletes"] == 0  # reset after downgrade

    @pytest.mark.asyncio
    async def test_positive_event_resets_consecutive_deletes(self):
        """completed_workout should reset consecutive_deletes to 0."""
        state = _default_state(consecutive_deletes=2)
        self.client.query_documents = AsyncMock(return_value=[state])

        result = await self.client.record_trust_event(
            "user@test.com", {"event_type": "completed_workout"}
        )
        assert result["consecutive_deletes"] == 0

    @pytest.mark.asyncio
    async def test_suggestion_accepted_resets_consecutive_deletes(self):
        state = _default_state(consecutive_deletes=1)
        self.client.query_documents = AsyncMock(return_value=[state])

        result = await self.client.record_trust_event(
            "user@test.com", {"event_type": "suggestion_accepted"}
        )
        assert result["consecutive_deletes"] == 0

    @pytest.mark.asyncio
    async def test_ios_phase_accepted(self):
        """Backend accepts phase from iOS event_data when provided."""
        state = _default_state(phase="observer", trust_score=22.0)
        self.client.query_documents = AsyncMock(return_value=[state])

        result = await self.client.record_trust_event(
            "user@test.com",
            {"event_type": "completed_workout", "phase": "scheduler"},
        )
        assert result["trust_score"] == pytest.approx(27.0, abs=1e-9)
        assert result["phase"] == "scheduler"  # accepted from iOS

    @pytest.mark.asyncio
    async def test_legacy_confidence_migrated(self):
        """Legacy confidence (0-1) field should be migrated to trust_score (0-100)."""
        legacy_state = {
            "id": "test-id",
            "userId": "user@test.com",
            "phase": "observer",
            "confidence": 0.25,
            "consecutive_deletes": 0,
            "events": [],
        }
        self.client.query_documents = AsyncMock(return_value=[legacy_state])

        result = await self.client.record_trust_event(
            "user@test.com", {"event_type": "completed_workout"}  # +5.0
        )
        assert result["trust_score"] == pytest.approx(30.0, abs=1e-9)
        assert "confidence" not in result

    @pytest.mark.asyncio
    async def test_invalid_event_type_raises_value_error(self):
        """record_trust_event rejects event types not in VALID_TRUST_EVENT_TYPES."""
        self.client.query_documents = AsyncMock(return_value=[_default_state()])
        with pytest.raises(ValueError, match="Invalid trust event type"):
            await self.client.record_trust_event(
                "user@test.com", {"event_type": "something_random"}
            )

    @pytest.mark.asyncio
    async def test_missing_event_type_raises_value_error(self):
        """record_trust_event rejects missing event_type (defaults to 'unknown')."""
        self.client.query_documents = AsyncMock(return_value=[_default_state()])
        with pytest.raises(ValueError, match="Invalid trust event type"):
            await self.client.record_trust_event("user@test.com", {})

    @pytest.mark.asyncio
    async def test_state_is_persisted_via_upsert(self):
        """record_trust_event must call upsert_document to persist."""
        await self.client.record_trust_event(
            "user@test.com", {"event_type": "completed_workout"}
        )
        self.client.upsert_document.assert_awaited_once()
        container_name = self.client.upsert_document.call_args[0][0]
        assert container_name == "trust_states"

"""
Trust State Machine unit tests.
Tests the 5-phase trust progression, Safety Breaker, and confidence logic.

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
    confidence: float = 0.0,
    consecutive_deletes: int = 0,
) -> dict:
    return {
        "id": "test-id",
        "userId": "user@test.com",
        "phase": phase,
        "confidence": confidence,
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
        assert self.client._calculate_trust_delta("completed_workout", "observer") == 0.05

    def test_missed_workout_negative(self):
        assert self.client._calculate_trust_delta("missed_workout", "observer") == -0.08

    def test_missed_workout_excuse_small_negative(self):
        assert self.client._calculate_trust_delta("missed_workout_excuse", "scheduler") == -0.02

    def test_user_deleted_block_large_negative(self):
        assert self.client._calculate_trust_delta("user_deleted_block", "auto_scheduler") == -0.15

    def test_suggestion_accepted(self):
        assert self.client._calculate_trust_delta("suggestion_accepted", "observer") == 0.03

    def test_auto_scheduled_completed(self):
        assert self.client._calculate_trust_delta("auto_scheduled_completed", "auto_scheduler") == 0.07

    def test_transformed_schedule_accepted(self):
        assert self.client._calculate_trust_delta("transformed_schedule_accepted", "transformer") == 0.08

    def test_unknown_event_zero(self):
        assert self.client._calculate_trust_delta("something_random", "observer") == 0.0


# =============================================================================
# _check_phase_progression
# =============================================================================


class TestCheckPhaseProgression:
    def setup_method(self):
        self.client = _make_client()

    def test_observer_at_zero(self):
        assert self.client._check_phase_progression("observer", 0.0) == "observer"

    def test_observer_to_scheduler_at_025(self):
        assert self.client._check_phase_progression("observer", 0.25) == "scheduler"

    def test_scheduler_to_auto_scheduler_at_050(self):
        assert self.client._check_phase_progression("scheduler", 0.50) == "auto_scheduler"

    def test_auto_scheduler_to_transformer_at_070(self):
        assert self.client._check_phase_progression("auto_scheduler", 0.70) == "transformer"

    def test_transformer_to_full_ghost_at_085(self):
        assert self.client._check_phase_progression("transformer", 0.85) == "full_ghost"

    def test_full_ghost_at_10(self):
        assert self.client._check_phase_progression("full_ghost", 1.0) == "full_ghost"

    def test_boundary_stays_in_lower_band(self):
        """0.24 is still observer (threshold is 0.25)."""
        assert self.client._check_phase_progression("observer", 0.24) == "observer"


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
        """First event should create a new observer state at confidence 0.05."""
        result = await self.client.record_trust_event(
            "user@test.com", {"event_type": "completed_workout"}
        )
        assert result["phase"] == "observer"
        assert result["confidence"] == 0.05
        # Verify persistence was called
        self.client.upsert_document.assert_called_once()
        args = self.client.upsert_document.call_args
        assert args[0][0] == "trust_states"

    @pytest.mark.asyncio
    async def test_confidence_clamped_at_zero(self):
        """Confidence should never go below 0.0."""
        self.client.query_documents = AsyncMock(
            return_value=[_default_state(confidence=0.01)]
        )
        result = await self.client.record_trust_event(
            "user@test.com", {"event_type": "missed_workout"}  # delta = -0.08
        )
        assert result["confidence"] == 0.0

    @pytest.mark.asyncio
    async def test_confidence_clamped_at_one(self):
        """Confidence should never exceed 1.0."""
        self.client.query_documents = AsyncMock(
            return_value=[_default_state(phase="full_ghost", confidence=0.99)]
        )
        result = await self.client.record_trust_event(
            "user@test.com",
            {"event_type": "transformed_schedule_accepted"},  # delta = +0.08
        )
        assert result["confidence"] == 1.0

    @pytest.mark.asyncio
    async def test_safety_breaker_on_three_deletes(self):
        """3 consecutive user_deleted_block events should downgrade phase."""
        state = _default_state(
            phase="auto_scheduler", confidence=0.55, consecutive_deletes=2
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
    async def test_phase_progression_across_boundary(self):
        """Enough positive events should push from observer to scheduler."""
        state = _default_state(phase="observer", confidence=0.22)
        self.client.query_documents = AsyncMock(return_value=[state])

        result = await self.client.record_trust_event(
            "user@test.com", {"event_type": "completed_workout"}  # +0.05 → 0.27
        )
        assert result["confidence"] == pytest.approx(0.27, abs=1e-9)
        assert result["phase"] == "scheduler"

    @pytest.mark.asyncio
    async def test_state_is_persisted_via_upsert(self):
        """record_trust_event must call upsert_document to persist."""
        await self.client.record_trust_event(
            "user@test.com", {"event_type": "completed_workout"}
        )
        self.client.upsert_document.assert_awaited_once()
        container_name = self.client.upsert_document.call_args[0][0]
        assert container_name == "trust_states"

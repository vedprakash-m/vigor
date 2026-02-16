"""
CosmosDBClient data layer tests.
Validates that CRUD operations target the correct containers.
"""

import sys
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock

import pytest

# Patch azure.cosmos.aio before importing our module
sys.modules.setdefault("azure.cosmos.aio", MagicMock())
sys.modules.setdefault("azure.cosmos.exceptions", MagicMock())

from shared.cosmos_db import CosmosDBClient  # noqa: E402


# ---------------------------------------------------------------------------
# Helper: build a CosmosDBClient with mock containers
# ---------------------------------------------------------------------------

def _make_client_with_mock_containers() -> CosmosDBClient:
    """
    Return a CosmosDBClient whose containers are AsyncMock objects
    so we can verify which container is targeted.
    """
    client = CosmosDBClient()
    client.client = MagicMock()  # truthy sentinel — prevents re-initialization

    mock_containers = {}
    for name in [
        "users", "workouts", "workout_logs", "ai_coach_messages",
        "ghost_actions", "trust_states", "training_blocks",
        "phenome", "decision_receipts", "push_queue",
    ]:
        mock_container = AsyncMock()
        # Default upsert_item returns the document
        mock_container.upsert_item = AsyncMock(side_effect=lambda body, **kw: body)
        mock_container.create_item = AsyncMock(side_effect=lambda body, **kw: body)

        # query_items returns an async iterator
        async def _empty_iter(*a, **kw):
            return
            yield  # noqa  — makes this an async generator

        mock_container.query_items = MagicMock(return_value=_empty_iter())
        mock_containers[name] = mock_container

    client.containers = mock_containers
    return client


# ---------------------------------------------------------------------------
# Test: store_decision_receipt writes to decision_receipts container
# ---------------------------------------------------------------------------

class TestStoreDecisionReceipt:
    @pytest.mark.asyncio
    async def test_writes_to_decision_receipts_container(self):
        client = _make_client_with_mock_containers()

        receipt_data = {
            "decision_type": "workout_swap",
            "inputs": {"old": "run"},
            "output": {"new": "swim"},
            "explanation": "Tired legs",
            "timestamp": "2025-01-01T00:00:00Z",
        }
        result = await client.store_decision_receipt("user@test.com", receipt_data)

        assert result["userId"] == "user@test.com"
        assert result["decision_type"] == "workout_swap"
        # Must have written to decision_receipts, not users
        client.containers["decision_receipts"].create_item.assert_awaited_once()
        client.containers["users"].create_item.assert_not_awaited()

    @pytest.mark.asyncio
    async def test_explanation_truncated_to_1000_chars(self):
        client = _make_client_with_mock_containers()

        receipt_data = {
            "decision_type": "block_create",
            "inputs": {},
            "output": {},
            "explanation": "x" * 2000,
            "timestamp": "2025-01-01T00:00:00Z",
        }
        result = await client.store_decision_receipt("user@test.com", receipt_data)
        assert len(result["explanation"]) == 1000

    @pytest.mark.asyncio
    async def test_decision_type_truncated_to_100_chars(self):
        client = _make_client_with_mock_containers()

        receipt_data = {
            "decision_type": "a" * 200,
            "inputs": {},
            "output": {},
            "explanation": "ok",
            "timestamp": "2025-01-01T00:00:00Z",
        }
        result = await client.store_decision_receipt("user@test.com", receipt_data)
        assert len(result["decision_type"]) == 100

    @pytest.mark.asyncio
    async def test_oversize_inputs_replaced_with_truncation_marker(self):
        client = _make_client_with_mock_containers()

        receipt_data = {
            "decision_type": "block_create",
            "inputs": {"big": "v" * 15_000},
            "output": {"small": "ok"},
            "explanation": "fine",
            "timestamp": "2025-01-01T00:00:00Z",
        }
        result = await client.store_decision_receipt("user@test.com", receipt_data)
        assert result["inputs"] == {"_truncated": True, "length": pytest.approx(15_012, abs=10)}
        assert result["output"] == {"small": "ok"}  # not truncated

    @pytest.mark.asyncio
    async def test_oversize_output_replaced_with_truncation_marker(self):
        client = _make_client_with_mock_containers()

        receipt_data = {
            "decision_type": "block_create",
            "inputs": {"ok": True},
            "output": {"huge": "z" * 15_000},
            "explanation": "fine",
            "timestamp": "2025-01-01T00:00:00Z",
        }
        result = await client.store_decision_receipt("user@test.com", receipt_data)
        assert result["output"]["_truncated"] is True
        assert result["inputs"] == {"ok": True}  # not truncated


# ---------------------------------------------------------------------------
# Test: get_decision_receipts reads from decision_receipts container
# ---------------------------------------------------------------------------

class TestGetDecisionReceipts:
    @pytest.mark.asyncio
    async def test_queries_decision_receipts_container(self):
        client = _make_client_with_mock_containers()

        # Set up the query to return a result via the correct container
        async def _receipt_iter(*a, **kw):
            yield {"id": "r-1", "decision_type": "block_create"}

        client.containers["decision_receipts"].query_items = MagicMock(
            return_value=_receipt_iter()
        )

        results = await client.get_decision_receipts(limit=10)

        assert len(results) == 1
        assert results[0]["id"] == "r-1"
        # Verify query hit decision_receipts, not users
        client.containers["decision_receipts"].query_items.assert_called_once()


# ---------------------------------------------------------------------------
# Test: create_chat_session uses ai_coach_messages container
# ---------------------------------------------------------------------------

class TestCreateChatSession:
    @pytest.mark.asyncio
    async def test_uses_ai_coach_messages_container(self):
        client = _make_client_with_mock_containers()

        chat_data = {
            "id": "sess-1",
            "userId": "user@test.com",
            "messages": [],
        }
        await client.create_chat_session(chat_data)

        # Must have written to ai_coach_messages, not chat_sessions (which doesn't exist)
        client.containers["ai_coach_messages"].upsert_item.assert_awaited_once()


# ---------------------------------------------------------------------------
# Test: count_documents maps types to correct containers
# ---------------------------------------------------------------------------

class TestCountDocuments:
    @pytest.mark.asyncio
    async def test_user_type_goes_to_users_container(self):
        client = _make_client_with_mock_containers()

        async def _count_iter(*a, **kw):
            yield 5

        client.containers["users"].query_items = MagicMock(
            return_value=_count_iter()
        )

        result = await client.count_documents("user")
        assert result == 5

    @pytest.mark.asyncio
    async def test_workout_type_goes_to_workouts_container(self):
        client = _make_client_with_mock_containers()

        async def _count_iter(*a, **kw):
            yield 3

        client.containers["workouts"].query_items = MagicMock(
            return_value=_count_iter()
        )

        result = await client.count_documents("workout")
        assert result == 3

    @pytest.mark.asyncio
    async def test_other_type_goes_to_ai_coach_messages(self):
        client = _make_client_with_mock_containers()

        async def _count_iter(*a, **kw):
            yield 7

        client.containers["ai_coach_messages"].query_items = MagicMock(
            return_value=_count_iter()
        )

        result = await client.count_documents("chat")
        assert result == 7


# ---------------------------------------------------------------------------
# Test: record_trust_event persists via upsert_document
# ---------------------------------------------------------------------------

class TestRecordTrustEventPersistence:
    @pytest.mark.asyncio
    async def test_persists_updated_state(self):
        client = _make_client_with_mock_containers()

        # get_trust_state returns None (new user) via query_documents
        async def _empty(*a, **kw):
            return
            yield  # noqa

        client.containers["trust_states"].query_items = MagicMock(
            return_value=_empty()
        )

        await client.record_trust_event(
            "user@test.com", {"event_type": "completed_workout"}
        )

        # Must have persisted to trust_states via upsert_item
        client.containers["trust_states"].upsert_item.assert_awaited_once()
        # upsert_item is called positionally or via body= kwarg
        call_args = client.containers["trust_states"].upsert_item.call_args
        persisted = call_args[1].get("body") or call_args[0][0]
        assert persisted["userId"] == "user@test.com"
        assert persisted["trust_score"] == 5.0


# ---------------------------------------------------------------------------
# Test: WS-15D schema normalization helpers
# ---------------------------------------------------------------------------


class TestSchemaNormalization:
    def test_normalize_trust_state_document_migrates_legacy_fields(self):
        client = _make_client_with_mock_containers()

        raw = {
            "id": "ts-1",
            "userId": "user@test.com",
            "trust_phase": "full-ghost",
            "confidence": 0.84,
            "updatedAt": "2025-01-01T00:00:00Z",
        }

        normalized = client._normalize_trust_state_document(raw)

        assert normalized["phase"] == "full_ghost"
        assert normalized["trust_score"] == 84.0
        assert "confidence" not in normalized

    def test_normalize_admin_user_outputs_frontend_shape(self):
        client = _make_client_with_mock_containers()

        raw = {
            "id": "u-1",
            "email": "u1@example.com",
            "display_name": "User One",
            "subscription_tier": "premium",
            "trust_phase": "auto_scheduler",
            "confidence": 0.7,
            "watch_connected": True,
            "created_at": "2025-01-01T00:00:00Z",
            "last_active": "2025-01-02T00:00:00Z",
        }

        normalized = client._normalize_admin_user(raw)

        assert normalized["trustPhase"] == "Auto-Scheduler"
        assert normalized["trustScore"] == 70.0
        assert normalized["watchStatus"] == "CONNECTED"
        assert normalized["tier"] == "premium"


class TestTrustDistributionNormalization:
    @pytest.mark.asyncio
    async def test_distribution_handles_mixed_sources(self):
        client = _make_client_with_mock_containers()

        async def _query_documents(container_name, query, parameters):
            if container_name == "trust_states":
                return [
                    {"userId": "u1@example.com", "phase": "observer"},
                    {"userId": "u2@example.com", "trust_phase": "full-ghost"},
                ]
            if container_name == "users":
                return [
                    {"email": "u2@example.com", "trust_phase": "scheduler"},
                    {"email": "u3@example.com", "trustPhase": "transformer"},
                ]
            return []

        client.query_documents = AsyncMock(side_effect=_query_documents)

        distribution = await client.get_trust_distribution()

        assert distribution["observer"] == 1
        assert distribution["full_ghost"] == 1
        assert distribution["transformer"] == 1
        assert distribution["scheduler"] == 0


class TestGhostAnalyticsNormalization:
    @pytest.mark.asyncio
    async def test_analytics_accepts_mixed_timestamp_and_outcome_fields(self):
        client = _make_client_with_mock_containers()

        now = datetime.now(timezone.utc)
        recent_iso = (now - timedelta(days=1)).isoformat()
        old_iso = (now - timedelta(days=40)).isoformat()

        async def _query_documents(container_name, query, parameters):
            if container_name == "decision_receipts":
                return [
                    {"createdAt": recent_iso, "decisionOutcome": "accepted", "confidence": 0.9},
                    {"timestamp": recent_iso, "outcome": "modified", "decision_type": "transform"},
                    {"created_at": recent_iso, "result": "rejected"},
                    {"timestamp": old_iso, "outcome": "accepted"},
                ]
            if container_name == "workouts":
                return [{"type": "workout_mutation", "timestamp": recent_iso}]
            if container_name == "users":
                return [0]
            return []

        client.query_documents = AsyncMock(side_effect=_query_documents)

        analytics = await client.get_ghost_analytics(days=7)

        assert analytics["total_decisions"] == 3
        assert analytics["accept_rate"] == pytest.approx(33.3, abs=0.1)
        assert analytics["modify_rate"] == pytest.approx(33.3, abs=0.1)
        assert analytics["reject_rate"] == pytest.approx(33.3, abs=0.1)
        assert analytics["total_mutations"] == 2

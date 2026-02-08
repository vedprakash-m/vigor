"""
CosmosDBClient data layer tests.
Validates that CRUD operations target the correct containers.
"""

import sys
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
        assert persisted["confidence"] == 0.05

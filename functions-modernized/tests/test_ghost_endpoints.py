"""
Ghost Blueprint endpoint tests.
Tests the HTTP endpoints in ghost_bp with mocked auth and Cosmos.
"""

import json
import sys
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import azure.functions as func
import pytest

# Patch azure.cosmos.aio before any blueprint import
sys.modules.setdefault("azure.cosmos.aio", MagicMock())
sys.modules.setdefault("azure.cosmos.exceptions", MagicMock())


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_request(
    method: str = "GET",
    url: str = "https://vigor-functions.azurewebsites.net/api/ghost/trust",
    body: dict | None = None,
    headers: dict | None = None,
    params: dict | None = None,
) -> func.HttpRequest:
    return func.HttpRequest(
        method=method,
        url=url,
        headers=headers or {},
        params=params or {},
        route_params={},
        body=json.dumps(body).encode() if body else b"",
    )


def _json(resp: func.HttpResponse) -> dict:
    return json.loads(resp.get_body().decode())


# ---------------------------------------------------------------------------
# Test: GET /ghost/trust — returns default state for unknown user
# ---------------------------------------------------------------------------

class TestGhostTrustGet:
    @pytest.mark.asyncio
    async def test_returns_default_state_for_new_user(self):
        from blueprints.ghost_bp import ghost_trust

        mock_client = AsyncMock()
        mock_client.get_trust_state = AsyncMock(return_value=None)

        with (
            patch(
                "blueprints.ghost_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "test@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            resp = await ghost_trust(_make_request(method="GET"))

        assert resp.status_code == 200
        data = _json(resp)
        assert data["phase"] == "observer"
        assert data["trust_score"] == 0.0


# ---------------------------------------------------------------------------
# Test: POST /ghost/trust — updates trust state
# ---------------------------------------------------------------------------

class TestGhostTrustPost:
    @pytest.mark.asyncio
    async def test_valid_event_updates_state(self):
        from blueprints.ghost_bp import ghost_trust

        updated = {
            "userId": "test@example.com",
            "phase": "observer",
            "trust_score": 5.0,
            "consecutive_deletes": 0,
        }
        mock_client = AsyncMock()
        mock_client.record_trust_event = AsyncMock(return_value=updated)

        with (
            patch(
                "blueprints.ghost_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "test@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                body={
                    "event_type": "completed_workout",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                },
            )
            resp = await ghost_trust(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["trust_score"] == 5.0
        mock_client.record_trust_event.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_missing_fields_returns_400(self):
        from blueprints.ghost_bp import ghost_trust

        mock_client = AsyncMock()

        with (
            patch(
                "blueprints.ghost_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "test@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(method="POST", body={"event_type": "completed_workout"})
            resp = await ghost_trust(req)

        assert resp.status_code == 400


# ---------------------------------------------------------------------------
# Test: POST /ghost/decision-receipt — stores receipt
# ---------------------------------------------------------------------------

class TestGhostDecisionReceipt:
    @pytest.mark.asyncio
    async def test_stores_receipt(self):
        from blueprints.ghost_bp import ghost_decision_receipt

        stored = {"id": "r-1", "decision_type": "workout_swap"}
        mock_client = AsyncMock()
        mock_client.store_decision_receipt = AsyncMock(return_value=stored)

        with (
            patch(
                "blueprints.ghost_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "test@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/ghost/decision-receipt",
                body={
                    "decision_type": "workout_swap",
                    "inputs": {"old": "run"},
                    "output": {"new": "swim"},
                    "explanation": "Recovery day",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                },
            )
            resp = await ghost_decision_receipt(req)

        assert resp.status_code == 201
        mock_client.store_decision_receipt.assert_awaited_once()


# ---------------------------------------------------------------------------
# Test: POST /ghost/device-token — register token
# ---------------------------------------------------------------------------

class TestGhostDeviceToken:
    VALID_TOKEN = "a" * 64  # 64-char hex

    @pytest.mark.asyncio
    async def test_register_valid_token(self):
        from blueprints.ghost_bp import ghost_device_token

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(
            return_value={"id": "test@example.com", "email": "test@example.com"}
        )
        mock_client.upsert_document = AsyncMock()

        with (
            patch(
                "blueprints.ghost_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "test@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/ghost/device-token",
                body={"device_token": self.VALID_TOKEN, "platform": "ios"},
            )
            resp = await ghost_device_token(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["status"] == "registered"
        # Verify token was persisted on user doc
        mock_client.upsert_document.assert_awaited_once()
        persisted = mock_client.upsert_document.call_args[0][1]
        assert persisted["apns_device_token"] == self.VALID_TOKEN

    @pytest.mark.asyncio
    async def test_invalid_token_returns_400(self):
        from blueprints.ghost_bp import ghost_device_token

        mock_client = AsyncMock()

        with (
            patch(
                "blueprints.ghost_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "test@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/ghost/device-token",
                body={"device_token": "too-short"},
            )
            resp = await ghost_device_token(req)

        assert resp.status_code == 400

    @pytest.mark.asyncio
    async def test_delete_removes_token(self):
        from blueprints.ghost_bp import ghost_device_token

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(
            return_value={
                "id": "test@example.com",
                "email": "test@example.com",
                "apns_device_token": "a" * 64,
            }
        )
        mock_client.upsert_document = AsyncMock()

        with (
            patch(
                "blueprints.ghost_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "test@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="DELETE",
                url="https://vigor-functions.azurewebsites.net/api/ghost/device-token",
            )
            resp = await ghost_device_token(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["status"] == "removed"
        persisted = mock_client.upsert_document.call_args[0][1]
        assert persisted["apns_device_token"] is None


# ---------------------------------------------------------------------------
# Test: auth rejection
# ---------------------------------------------------------------------------

class TestGhostAuthRejection:
    @pytest.mark.asyncio
    async def test_unauthenticated_returns_401(self):
        from blueprints.ghost_bp import ghost_trust

        with patch(
            "blueprints.ghost_bp.get_current_user_from_token",
            new=AsyncMock(return_value=None),
        ):
            resp = await ghost_trust(_make_request())

        assert resp.status_code == 401


# ---------------------------------------------------------------------------
# Test: POST /ghost/phenome/sync
# ---------------------------------------------------------------------------

class TestGhostPhenomeSync:
    @pytest.mark.asyncio
    async def test_client_newer_updates_server(self):
        from blueprints.ghost_bp import ghost_phenome_sync

        mock_client = AsyncMock()
        mock_client.get_phenome_store = AsyncMock(
            return_value={"version": 1, "data": {}}
        )
        mock_client.update_phenome_store = AsyncMock()

        with (
            patch(
                "blueprints.ghost_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "test@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/ghost/phenome/sync",
                body={
                    "store_type": "raw_signal",
                    "version": 5,
                    "data": {"hr_avg": 72},
                },
            )
            resp = await ghost_phenome_sync(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["status"] == "updated"
        assert data["version"] == 5


# ---------------------------------------------------------------------------
# Test: POST /ghost/health
# ---------------------------------------------------------------------------


class TestGhostHealth:
    @pytest.mark.asyncio
    async def test_persists_health_snapshot(self):
        from blueprints.ghost_bp import ghost_health

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(
            return_value={"id": "test@example.com", "email": "test@example.com"}
        )
        mock_client.upsert_document = AsyncMock()

        with (
            patch(
                "blueprints.ghost_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "test@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/ghost/health",
                body={"mode": "LOW_POWER", "battery": 0.42},
            )
            resp = await ghost_health(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["status"] == "ok"
        mock_client.upsert_document.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_unauthenticated_returns_401(self):
        from blueprints.ghost_bp import ghost_health

        with patch(
            "blueprints.ghost_bp.get_current_user_from_token",
            new=AsyncMock(return_value=None),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/ghost/health",
                body={"mode": "NORMAL"},
            )
            resp = await ghost_health(req)

        assert resp.status_code == 401

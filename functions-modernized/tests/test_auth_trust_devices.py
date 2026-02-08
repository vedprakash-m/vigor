"""
Auth, Trust alias, and Device endpoint tests.
Tests auth_bp: GET /auth/me, GET /user/profile
Tests trust_bp: POST /trust/event, GET /trust/history
Tests devices_bp: POST /devices/register, POST /devices/push-token
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
    url: str = "https://vigor-functions.azurewebsites.net/api/auth/me",
    body: dict | None = None,
) -> func.HttpRequest:
    return func.HttpRequest(
        method=method,
        url=url,
        headers={},
        params={},
        route_params={},
        body=json.dumps(body).encode() if body else b"",
    )


def _json(resp: func.HttpResponse) -> dict:
    return json.loads(resp.get_body().decode())


# ===========================================================================
# GET /auth/me
# ===========================================================================


class TestAuthMe:
    @pytest.mark.asyncio
    async def test_returns_profile(self):
        from blueprints.auth_bp import get_current_user

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(
            return_value={"id": "u@e.com", "email": "u@e.com", "tier": "free"}
        )

        with (
            patch(
                "blueprints.auth_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "u@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            resp = await get_current_user(_make_request())

        assert resp.status_code == 200
        data = _json(resp)
        assert data["email"] == "u@e.com"

    @pytest.mark.asyncio
    async def test_new_user_gets_default_profile(self):
        from blueprints.auth_bp import get_current_user

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(return_value=None)

        with (
            patch(
                "blueprints.auth_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "new@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            resp = await get_current_user(_make_request())

        assert resp.status_code == 200
        data = _json(resp)
        assert data["email"] == "new@e.com"
        assert data["tier"] == "free"

    @pytest.mark.asyncio
    async def test_unauthenticated_returns_401(self):
        from blueprints.auth_bp import get_current_user

        with patch(
            "blueprints.auth_bp.get_current_user_from_token",
            new=AsyncMock(return_value=None),
        ):
            resp = await get_current_user(_make_request())

        assert resp.status_code == 401


# ===========================================================================
# GET /user/profile — alias
# ===========================================================================


class TestUserProfileAlias:
    @pytest.mark.asyncio
    async def test_alias_delegates_to_users_profile(self):
        from blueprints.auth_bp import user_profile_alias

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(
            return_value={"id": "u@e.com", "email": "u@e.com"}
        )

        with (
            patch(
                "blueprints.auth_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "u@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/user/profile"
            )
            resp = await user_profile_alias(req)

        assert resp.status_code == 200


# ===========================================================================
# POST /trust/event
# ===========================================================================


class TestTrustEvent:
    @pytest.mark.asyncio
    async def test_records_event(self):
        from blueprints.trust_bp import trust_record_event

        updated = {"phase": "observer", "confidence": 0.05}
        mock_client = AsyncMock()
        mock_client.record_trust_event = AsyncMock(return_value=updated)

        with (
            patch(
                "blueprints.trust_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/trust/event",
                body={
                    "event": "completed_workout",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                },
            )
            resp = await trust_record_event(req)

        assert resp.status_code == 200
        mock_client.record_trust_event.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_missing_event_type_returns_400(self):
        from blueprints.trust_bp import trust_record_event

        mock_client = AsyncMock()
        with (
            patch(
                "blueprints.trust_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/trust/event",
                body={"timestamp": "2026-01-01T00:00:00Z"},
            )
            resp = await trust_record_event(req)

        assert resp.status_code == 400


# ===========================================================================
# GET /trust/history
# ===========================================================================


class TestTrustHistory:
    @pytest.mark.asyncio
    async def test_returns_history(self):
        from blueprints.trust_bp import trust_get_history

        mock_client = AsyncMock()
        mock_client.get_trust_state = AsyncMock(
            return_value={"confidence": 0.35, "phase": "scheduler"}
        )
        mock_client.get_trust_history = AsyncMock(
            return_value=[
                {"event_type": "completed_workout", "timestamp": "2026-01-01"},
                {"event_type": "phase_transition", "timestamp": "2026-01-02"},
            ]
        )

        with (
            patch(
                "blueprints.trust_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/trust/history"
            )
            resp = await trust_get_history(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["currentScore"] == 0.35
        assert data["currentPhase"] == "scheduler"
        assert len(data["history"]) == 2
        assert len(data["phaseTransitions"]) == 1


# ===========================================================================
# POST /devices/register
# ===========================================================================


class TestDeviceRegister:
    @pytest.mark.asyncio
    async def test_registers_device(self):
        from blueprints.devices_bp import register_device

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(
            return_value={"id": "t@e.com", "email": "t@e.com", "devices": []}
        )
        mock_client.upsert_document = AsyncMock()

        with (
            patch(
                "blueprints.devices_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/devices/register",
                body={
                    "deviceId": "ABC-123",
                    "deviceType": "iphone",
                    "osVersion": "19.3",
                    "appVersion": "1.0.0",
                    "capabilities": ["push", "healthkit"],
                    "isPrimary": True,
                },
            )
            resp = await register_device(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["status"] == "registered"

    @pytest.mark.asyncio
    async def test_missing_device_id_returns_400(self):
        from blueprints.devices_bp import register_device

        mock_client = AsyncMock()
        with (
            patch(
                "blueprints.devices_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/devices/register",
                body={"deviceType": "iphone"},
            )
            resp = await register_device(req)

        assert resp.status_code == 400


# ===========================================================================
# POST /devices/push-token
# ===========================================================================


class TestDevicePushToken:
    VALID_TOKEN = "b" * 64

    @pytest.mark.asyncio
    async def test_registers_push_token(self):
        from blueprints.devices_bp import register_push_token

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(
            return_value={"id": "t@e.com", "email": "t@e.com"}
        )
        mock_client.upsert_document = AsyncMock()

        with (
            patch(
                "blueprints.devices_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/devices/push-token",
                body={"token": self.VALID_TOKEN},
            )
            resp = await register_push_token(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["status"] == "registered"

    @pytest.mark.asyncio
    async def test_invalid_token_returns_400(self):
        from blueprints.devices_bp import register_push_token

        with patch(
            "blueprints.devices_bp.get_current_user_from_token",
            new=AsyncMock(return_value={"email": "t@e.com"}),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/devices/push-token",
                body={"token": "short"},
            )
            resp = await register_push_token(req)

        assert resp.status_code == 400

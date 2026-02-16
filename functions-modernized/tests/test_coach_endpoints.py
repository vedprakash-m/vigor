"""
Coach Blueprint endpoint tests.
Tests coach_bp: POST /coach/chat, GET /coach/history,
POST /coach/recommend, GET /coach/recovery
"""

import json
import sys
import types
from unittest.mock import AsyncMock, MagicMock, patch

import azure.functions as func
import pytest

# Patch azure.cosmos.aio before any blueprint import
sys.modules.setdefault("azure.cosmos.aio", MagicMock())
sys.modules.setdefault("azure.cosmos.exceptions", MagicMock())

# Pre-seed shared sub-modules so ``from shared.openai_client import OpenAIClient``
# doesn't trigger the real (heavy) import during tests.
_mock_openai_mod = types.ModuleType("shared.openai_client")
_mock_openai_mod.OpenAIClient = MagicMock  # type: ignore[attr-defined]
sys.modules.setdefault("shared.openai_client", _mock_openai_mod)

_mock_rl_mod = types.ModuleType("shared.rate_limiter")
_mock_rl_mod.RateLimiter = MagicMock  # type: ignore[attr-defined]
_mock_rl_mod.apply_ai_generation_limit = AsyncMock(return_value=None)  # type: ignore[attr-defined]
_mock_rl_mod.apply_rate_limit = AsyncMock(return_value=None)  # type: ignore[attr-defined]
sys.modules.setdefault("shared.rate_limiter", _mock_rl_mod)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_request(
    method: str = "GET",
    url: str = "https://vigor-functions.azurewebsites.net/api/coach/chat",
    body: dict | None = None,
    params: dict | None = None,
) -> func.HttpRequest:
    return func.HttpRequest(
        method=method,
        url=url,
        headers={},
        params=params or {},
        route_params={},
        body=json.dumps(body).encode() if body else b"",
    )


def _json(resp: func.HttpResponse) -> dict:
    return json.loads(resp.get_body().decode())


# ===========================================================================
# POST /coach/chat
# ===========================================================================


class TestCoachChat:
    @pytest.mark.asyncio
    async def test_valid_chat_returns_response(self):
        from blueprints.coach_bp import coach_chat

        mock_client = AsyncMock()
        mock_client.get_conversation_history = AsyncMock(return_value=[])
        mock_client.get_user_profile = AsyncMock(return_value={"email": "t@e.com"})
        mock_client.save_chat_messages = AsyncMock()
        mock_client.get_daily_ai_spend = AsyncMock(return_value=0.5)

        mock_ai = MagicMock()
        mock_ai.coach_chat = AsyncMock(return_value="Stay hydrated!")

        mock_rate = MagicMock()
        mock_rate.check_rate_limit = AsyncMock(return_value=True)

        with (
            patch(
                "blueprints.coach_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
            patch("shared.openai_client.OpenAIClient", return_value=mock_ai),
            patch("shared.rate_limiter.RateLimiter", return_value=mock_rate),
        ):
            req = _make_request(method="POST", body={"message": "How much water?"})
            resp = await coach_chat(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["response"] == "Stay hydrated!"

    @pytest.mark.asyncio
    async def test_missing_message_returns_400(self):
        from blueprints.coach_bp import coach_chat

        mock_client = AsyncMock()
        mock_rate = MagicMock()
        mock_rate.check_rate_limit = AsyncMock(return_value=True)

        with (
            patch(
                "blueprints.coach_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
            patch("shared.rate_limiter.RateLimiter", return_value=mock_rate),
        ):
            req = _make_request(method="POST", body={"not_message": "oops"})
            resp = await coach_chat(req)

        assert resp.status_code == 422  # Pydantic validation error (missing required field)

    @pytest.mark.asyncio
    async def test_unauthenticated_returns_401(self):
        from blueprints.coach_bp import coach_chat

        with patch(
            "blueprints.coach_bp.get_current_user_from_token",
            new=AsyncMock(return_value=None),
        ):
            resp = await coach_chat(
                _make_request(method="POST", body={"message": "hi"})
            )

        assert resp.status_code == 401


# ===========================================================================
# GET /coach/history
# ===========================================================================


class TestCoachHistory:
    @pytest.mark.asyncio
    async def test_returns_history(self):
        from blueprints.coach_bp import coach_history

        mock_client = AsyncMock()
        mock_client.get_conversation_history = AsyncMock(
            return_value=[{"role": "user", "content": "hi"}]
        )

        with (
            patch(
                "blueprints.coach_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/coach/history"
            )
            resp = await coach_history(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert len(data) == 1


# ===========================================================================
# POST /coach/recommend
# ===========================================================================


class TestCoachRecommend:
    @pytest.mark.asyncio
    async def test_returns_recommendation(self):
        from blueprints.coach_bp import coach_recommend

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(
            return_value={"email": "t@e.com", "fitness_level": "intermediate"}
        )

        mock_ai = MagicMock()
        mock_ai.generate_workout = AsyncMock(
            return_value={
                "name": "Morning Run",
                "description": "Light jog to start the day",
            }
        )

        mock_rate = MagicMock()
        mock_rate.check_rate_limit = AsyncMock(return_value=True)

        with (
            patch(
                "blueprints.coach_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
            patch("shared.openai_client.OpenAIClient", return_value=mock_ai),
            patch("shared.rate_limiter.RateLimiter", return_value=mock_rate),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/coach/recommend",
                body={"availableWindows": [], "trustPhase": "observer"},
            )
            resp = await coach_recommend(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert "workoutType" in data
        assert "confidence" in data

    @pytest.mark.asyncio
    async def test_empty_body_returns_400(self):
        from blueprints.coach_bp import coach_recommend

        mock_rate = MagicMock()
        mock_rate.check_rate_limit = AsyncMock(return_value=True)

        with (
            patch(
                "blueprints.coach_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch("shared.rate_limiter.RateLimiter", return_value=mock_rate),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/coach/recommend",
            )
            resp = await coach_recommend(req)

        assert resp.status_code == 400


# ===========================================================================
# GET /coach/recovery
# ===========================================================================


class TestCoachRecovery:
    @pytest.mark.asyncio
    async def test_fully_rested_user(self):
        from blueprints.coach_bp import coach_recovery

        mock_client = AsyncMock()
        mock_client.get_user_workout_logs = AsyncMock(return_value=[])
        mock_client.get_trust_state = AsyncMock(return_value=None)

        with (
            patch(
                "blueprints.coach_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/coach/recovery"
            )
            resp = await coach_recovery(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["score"] == 100.0
        assert data["status"] == "recovered"
        assert data["suggestedRestDays"] == 0

    @pytest.mark.asyncio
    async def test_fatigued_user(self):
        from blueprints.coach_bp import coach_recovery

        mock_client = AsyncMock()
        # 8 workouts in 14 days → fatigued
        mock_client.get_user_workout_logs = AsyncMock(
            return_value=[{"id": f"w-{i}"} for i in range(8)]
        )
        mock_client.get_trust_state = AsyncMock(return_value=None)

        with (
            patch(
                "blueprints.coach_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/coach/recovery"
            )
            resp = await coach_recovery(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["status"] == "fatigued"
        assert data["suggestedRestDays"] >= 2


# ===========================================================================
# POST /coach/generate-workout — compatibility alias
# ===========================================================================


class TestCoachGenerateWorkout:
    @pytest.mark.asyncio
    async def test_returns_generated_workout(self):
        from blueprints.coach_bp import coach_generate_workout

        mock_client = AsyncMock()
        mock_client.get_user_profile = AsyncMock(return_value={"email": "t@e.com"})

        mock_ai = MagicMock()
        mock_ai.generate_workout = AsyncMock(
            return_value={"name": "Intervals", "description": "Quality work"}
        )

        with (
            patch(
                "blueprints.coach_bp.get_current_user_from_token",
                new=AsyncMock(return_value={"email": "t@e.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
            patch(
                "shared.rate_limiter.apply_ai_generation_limit",
                new=AsyncMock(return_value=None),
            ),
            patch("shared.openai_client.OpenAIClient", return_value=mock_ai),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/coach/generate-workout",
                body={"durationMinutes": 30},
            )
            resp = await coach_generate_workout(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["name"] == "Intervals"

    @pytest.mark.asyncio
    async def test_unauthenticated_returns_401(self):
        from blueprints.coach_bp import coach_generate_workout

        with patch(
            "blueprints.coach_bp.get_current_user_from_token",
            new=AsyncMock(return_value=None),
        ):
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/coach/generate-workout",
                body={"durationMinutes": 30},
            )
            resp = await coach_generate_workout(req)

        assert resp.status_code == 401

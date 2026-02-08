"""
Admin Blueprint endpoint tests.
Tests admin_bp: GET /admin/ghost/health, GET /admin/ghost/trust-distribution,
GET /admin/ghost/analytics, GET /admin/ghost/users,
GET /admin/ghost/decision-receipts, GET /admin/ghost/safety-breakers,
GET/PUT /admin/ai-pipeline-config, admin auth gate rejection
"""

import json
import sys
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
    url: str = "https://vigor-functions.azurewebsites.net/api/admin/ghost/health",
    params: dict | None = None,
) -> func.HttpRequest:
    return func.HttpRequest(
        method="GET",
        url=url,
        headers={},
        params=params or {},
        route_params={},
        body=b"",
    )


def _json(resp: func.HttpResponse) -> dict:
    return json.loads(resp.get_body().decode())


def _admin_and_cosmos(mock_client):
    """Return a pair of context-managers that mock admin auth + Cosmos client."""
    admin_p = patch(
        "blueprints.admin_bp.require_admin_user",
        new=AsyncMock(return_value={"email": "admin@example.com"}),
    )
    cosmos_p = patch(
        "shared.cosmos_db.get_global_client",
        new=AsyncMock(return_value=mock_client),
    )
    return admin_p, cosmos_p


# ===========================================================================
# GET /admin/ghost/health
# ===========================================================================


class TestAdminGhostHealth:
    @pytest.mark.asyncio
    async def test_returns_health_structure(self):
        from blueprints.admin_bp import get_ghost_health

        mock_client = AsyncMock()
        mock_client.get_ghost_health_metrics = AsyncMock(
            return_value={
                "overall_status": "healthy",
                "components": [],
                "phenome_stores": [],
                "safety_breakers": [],
            }
        )

        with (
            patch(
                "blueprints.admin_bp.require_admin_user",
                new=AsyncMock(return_value={"email": "admin@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            resp = await get_ghost_health(_make_request())

        assert resp.status_code == 200
        data = _json(resp)
        assert "mode" in data
        assert "components" in data

    @pytest.mark.asyncio
    async def test_non_admin_rejected(self):
        from blueprints.admin_bp import get_ghost_health

        with patch(
            "blueprints.admin_bp.require_admin_user",
            new=AsyncMock(return_value=None),
        ):
            resp = await get_ghost_health(_make_request())

        assert resp.status_code == 403


# ===========================================================================
# GET /admin/ghost/trust-distribution
# ===========================================================================


class TestAdminTrustDistribution:
    @pytest.mark.asyncio
    async def test_returns_phases(self):
        from blueprints.admin_bp import get_trust_distribution

        mock_client = AsyncMock()
        mock_client.get_trust_distribution = AsyncMock(
            return_value={"observer": 10, "scheduler": 5}
        )

        with (
            patch(
                "blueprints.admin_bp.require_admin_user",
                new=AsyncMock(return_value={"email": "admin@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/admin/ghost/trust-distribution"
            )
            resp = await get_trust_distribution(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert "phases" in data


# ===========================================================================
# GET /admin/ghost/analytics
# ===========================================================================


class TestAdminGhostAnalytics:
    @pytest.mark.asyncio
    async def test_returns_analytics(self):
        from blueprints.admin_bp import get_ghost_analytics

        mock_client = AsyncMock()
        mock_client.get_ghost_analytics = AsyncMock(
            return_value={
                "period": "7d",
                "total_decisions": 100,
                "total_mutations": 20,
                "accept_rate": 85.0,
                "modify_rate": 10.0,
                "reject_rate": 5.0,
                "safety_breakers": 1,
                "avg_confidence": 0.82,
                "trust_distribution": {},
            }
        )

        with (
            patch(
                "blueprints.admin_bp.require_admin_user",
                new=AsyncMock(return_value={"email": "admin@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/admin/ghost/analytics",
                params={"days": "7"},
            )
            resp = await get_ghost_analytics(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["total_decisions"] == 100


# ===========================================================================
# GET /admin/ghost/users
# ===========================================================================


class TestAdminUsers:
    @pytest.mark.asyncio
    async def test_returns_users_list(self):
        from blueprints.admin_bp import get_admin_users

        mock_client = AsyncMock()
        mock_client.get_all_users_admin = AsyncMock(
            return_value=[{"id": "u-1", "email": "u@e.com"}]
        )

        with (
            patch(
                "blueprints.admin_bp.require_admin_user",
                new=AsyncMock(return_value={"email": "admin@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/admin/ghost/users"
            )
            resp = await get_admin_users(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert "users" in data
        assert len(data["users"]) == 1


# ===========================================================================
# GET /admin/ghost/decision-receipts
# ===========================================================================


class TestAdminDecisionReceipts:
    @pytest.mark.asyncio
    async def test_returns_receipts(self):
        from blueprints.admin_bp import get_decision_receipts

        mock_client = AsyncMock()
        mock_client.get_decision_receipts = AsyncMock(
            return_value=[{"id": "dr-1", "decision_type": "schedule"}]
        )

        with (
            patch(
                "blueprints.admin_bp.require_admin_user",
                new=AsyncMock(return_value={"email": "admin@example.com"}),
            ),
            patch(
                "shared.cosmos_db.get_global_client",
                new=AsyncMock(return_value=mock_client),
            ),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/admin/ghost/decision-receipts"
            )
            resp = await get_decision_receipts(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert "receipts" in data


# ===========================================================================
# Admin auth gate — applies to all endpoints
# ===========================================================================


class TestAdminAuthGate:
    @pytest.mark.asyncio
    async def test_cost_metrics_rejects_non_admin(self):
        from blueprints.admin_bp import get_cost_metrics

        with patch(
            "blueprints.admin_bp.require_admin_user",
            new=AsyncMock(return_value=None),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/admin/ai/cost-metrics"
            )
            resp = await get_cost_metrics(req)

        assert resp.status_code == 403

    @pytest.mark.asyncio
    async def test_safety_breakers_rejects_non_admin(self):
        from blueprints.admin_bp import get_safety_breaker_events

        with patch(
            "blueprints.admin_bp.require_admin_user",
            new=AsyncMock(return_value=None),
        ):
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/admin/ghost/safety-breakers"
            )
            resp = await get_safety_breaker_events(req)

        assert resp.status_code == 403


# ===========================================================================
# GET/PUT /admin/ai-pipeline-config
# ===========================================================================


class TestAIPipelineConfig:
    @pytest.mark.asyncio
    async def test_get_returns_config(self):
        from blueprints.admin_bp import ai_pipeline_config

        mock_client = AsyncMock()
        mock_client.get_ai_pipeline_config = AsyncMock(
            return_value={
                "maxExercisesPerWorkout": 10,
                "maxWorkoutDuration": 60,
                "requestTimeout": 30,
            }
        )

        admin_p, cosmos_p = _admin_and_cosmos(mock_client)
        with admin_p, cosmos_p:
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/admin/ai-pipeline-config"
            )
            resp = await ai_pipeline_config(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["maxExercisesPerWorkout"] == 10

    @pytest.mark.asyncio
    async def test_get_returns_defaults_when_no_config(self):
        from blueprints.admin_bp import ai_pipeline_config

        mock_client = AsyncMock()
        mock_client.get_ai_pipeline_config = AsyncMock(return_value=None)

        admin_p, cosmos_p = _admin_and_cosmos(mock_client)
        with admin_p, cosmos_p:
            req = _make_request(
                url="https://vigor-functions.azurewebsites.net/api/admin/ai-pipeline-config"
            )
            resp = await ai_pipeline_config(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["maxExercisesPerWorkout"] == 8  # default
        assert data["maxWorkoutDuration"] == 90  # default

    @pytest.mark.asyncio
    async def test_put_updates_config(self):
        from blueprints.admin_bp import ai_pipeline_config

        mock_client = AsyncMock()
        mock_client.get_ai_pipeline_config = AsyncMock(
            return_value={
                "maxExercisesPerWorkout": 8,
                "maxWorkoutDuration": 90,
                "requestTimeout": 30,
            }
        )
        mock_client.upsert_ai_pipeline_config = AsyncMock()

        admin_p, cosmos_p = _admin_and_cosmos(mock_client)
        with admin_p, cosmos_p:
            req = func.HttpRequest(
                method="PUT",
                url="https://vigor-functions.azurewebsites.net/api/admin/ai-pipeline-config",
                headers={},
                params={},
                route_params={},
                body=json.dumps({"maxWorkoutDuration": 120}).encode(),
            )
            resp = await ai_pipeline_config(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["maxWorkoutDuration"] == 120
        mock_client.upsert_ai_pipeline_config.assert_called_once()

    @pytest.mark.asyncio
    async def test_put_rejects_non_admin(self):
        from blueprints.admin_bp import ai_pipeline_config

        with patch(
            "blueprints.admin_bp.require_admin_user",
            new=AsyncMock(return_value=None),
        ):
            req = func.HttpRequest(
                method="PUT",
                url="https://vigor-functions.azurewebsites.net/api/admin/ai-pipeline-config",
                headers={},
                params={},
                route_params={},
                body=json.dumps({"maxWorkoutDuration": 120}).encode(),
            )
            resp = await ai_pipeline_config(req)

        assert resp.status_code == 403

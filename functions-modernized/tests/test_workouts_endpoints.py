"""
Workout & Block endpoint tests.
Tests workouts_bp: POST /workouts, GET /workouts, GET /workouts/{id},
POST /blocks/sync, POST /blocks/outcome
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
    method: str = "GET",
    url: str = "https://vigor-functions.azurewebsites.net/api/workouts",
    body: dict | None = None,
    params: dict | None = None,
    route_params: dict | None = None,
) -> func.HttpRequest:
    return func.HttpRequest(
        method=method,
        url=url,
        headers={},
        params=params or {},
        route_params=route_params or {},
        body=json.dumps(body).encode() if body else b"",
    )


def _json(resp: func.HttpResponse) -> dict:
    return json.loads(resp.get_body().decode())


def _auth_and_cosmos(mock_client):
    """Return context manager patches for auth + cosmos."""
    return (
        patch(
            "blueprints.workouts_bp.get_current_user_from_token",
            new=AsyncMock(return_value={"email": "test@example.com"}),
        ),
        patch(
            "shared.cosmos_db.get_global_client",
            new=AsyncMock(return_value=mock_client),
        ),
    )


# ===========================================================================
# POST /workouts — record completed workout
# ===========================================================================


class TestRecordWorkout:
    @pytest.mark.asyncio
    async def test_records_valid_workout(self):
        from blueprints.workouts_bp import record_workout

        mock_client = AsyncMock()
        mock_client.create_workout_log = AsyncMock(
            return_value={"id": "w-1", "type": "run"}
        )

        with _auth_and_cosmos(mock_client)[0], _auth_and_cosmos(mock_client)[1]:
            req = _make_request(
                method="POST",
                body={"type": "run", "durationMinutes": 30},
            )
            resp = await record_workout(req)

        assert resp.status_code == 201
        mock_client.create_workout_log.assert_awaited_once()

    @pytest.mark.asyncio
    async def test_missing_type_returns_400(self):
        from blueprints.workouts_bp import record_workout

        mock_client = AsyncMock()
        auth_p, cosmos_p = _auth_and_cosmos(mock_client)

        with auth_p, cosmos_p:
            req = _make_request(method="POST", body={"durationMinutes": 30})
            resp = await record_workout(req)

        assert resp.status_code == 400

    @pytest.mark.asyncio
    async def test_unauthenticated_returns_401(self):
        from blueprints.workouts_bp import record_workout

        with patch(
            "blueprints.workouts_bp.get_current_user_from_token",
            new=AsyncMock(return_value=None),
        ):
            resp = await record_workout(_make_request(method="POST", body={"type": "run"}))

        assert resp.status_code == 401


# ===========================================================================
# GET /workouts — list user workouts
# ===========================================================================


class TestGetUserWorkouts:
    @pytest.mark.asyncio
    async def test_returns_workouts(self):
        from blueprints.workouts_bp import get_user_workouts

        mock_client = AsyncMock()
        mock_client.get_user_workouts = AsyncMock(
            return_value=[{"id": "w-1"}, {"id": "w-2"}]
        )

        auth_p, cosmos_p = _auth_and_cosmos(mock_client)
        with auth_p, cosmos_p:
            resp = await get_user_workouts(_make_request())

        assert resp.status_code == 200
        data = _json(resp)
        assert len(data) == 2


# ===========================================================================
# GET /workouts/{id} — get single workout
# ===========================================================================


class TestWorkoutDetail:
    @pytest.mark.asyncio
    async def test_returns_workout(self):
        from blueprints.workouts_bp import workout_detail

        mock_client = AsyncMock()
        mock_client.get_workout = AsyncMock(return_value={"id": "w-1", "type": "run"})

        auth_p, cosmos_p = _auth_and_cosmos(mock_client)
        with auth_p, cosmos_p:
            req = func.HttpRequest(
                method="GET",
                url="https://vigor-functions.azurewebsites.net/api/workouts/w-1",
                headers={},
                params={},
                route_params={"workout_id": "w-1"},
                body=b"",
            )
            resp = await workout_detail(req)

        assert resp.status_code == 200

    @pytest.mark.asyncio
    async def test_not_found_returns_404(self):
        from blueprints.workouts_bp import workout_detail

        mock_client = AsyncMock()
        mock_client.get_workout = AsyncMock(return_value=None)

        auth_p, cosmos_p = _auth_and_cosmos(mock_client)
        with auth_p, cosmos_p:
            req = func.HttpRequest(
                method="GET",
                url="https://vigor-functions.azurewebsites.net/api/workouts/w-nope",
                headers={},
                params={},
                route_params={"workout_id": "w-nope"},
                body=b"",
            )
            resp = await workout_detail(req)

        assert resp.status_code == 404


# ===========================================================================
# POST /blocks/sync — sync training blocks
# ===========================================================================


class TestSyncTrainingBlocks:
    @pytest.mark.asyncio
    async def test_syncs_new_blocks(self):
        from blueprints.workouts_bp import sync_training_blocks

        mock_client = AsyncMock()
        mock_client.create_training_block = AsyncMock(
            return_value={"id": "b-new", "status": "scheduled"}
        )

        auth_p, cosmos_p = _auth_and_cosmos(mock_client)
        with auth_p, cosmos_p:
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/blocks/sync",
                body={
                    "blocks": [
                        {
                            "start_time": "2026-02-08T06:00:00Z",
                            "duration_minutes": 45,
                            "workout_type": "run",
                        }
                    ]
                },
            )
            resp = await sync_training_blocks(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert len(data["blocks"]) == 1

    @pytest.mark.asyncio
    async def test_empty_blocks_array(self):
        from blueprints.workouts_bp import sync_training_blocks

        mock_client = AsyncMock()
        auth_p, cosmos_p = _auth_and_cosmos(mock_client)
        with auth_p, cosmos_p:
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/blocks/sync",
                body={"blocks": []},
            )
            resp = await sync_training_blocks(req)

        assert resp.status_code == 200
        data = _json(resp)
        assert data["blocks"] == []


# ===========================================================================
# POST /blocks/outcome — record block outcome
# ===========================================================================


class TestRecordBlockOutcome:
    @pytest.mark.asyncio
    async def test_records_outcome(self):
        from blueprints.workouts_bp import record_block_outcome

        mock_client = AsyncMock()
        mock_client.update_training_block = AsyncMock(
            return_value={"id": "b-1", "status": "completed"}
        )

        auth_p, cosmos_p = _auth_and_cosmos(mock_client)
        with auth_p, cosmos_p:
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/blocks/outcome",
                body={"blockId": "b-1", "outcome": "completed"},
            )
            resp = await record_block_outcome(req)

        assert resp.status_code == 200

    @pytest.mark.asyncio
    async def test_missing_fields_returns_400(self):
        from blueprints.workouts_bp import record_block_outcome

        mock_client = AsyncMock()
        auth_p, cosmos_p = _auth_and_cosmos(mock_client)
        with auth_p, cosmos_p:
            req = _make_request(
                method="POST",
                url="https://vigor-functions.azurewebsites.net/api/blocks/outcome",
                body={"blockId": "b-1"},
            )
            resp = await record_block_outcome(req)

        assert resp.status_code == 400

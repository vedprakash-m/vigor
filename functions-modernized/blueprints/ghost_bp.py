"""
Ghost Engine Blueprint
Endpoints: ghost/silent-push, ghost/trust, ghost/schedule, ghost/phenome/sync,
           ghost/decision-receipt, timer triggers
"""

import logging
from datetime import datetime, timezone

import azure.functions as func

from shared.auth import get_current_user_from_token
from shared.helpers import error_response, success_response

logger = logging.getLogger(__name__)

ghost_bp = func.Blueprint()


@ghost_bp.route(
    route="ghost/silent-push", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def ghost_silent_push(req: func.HttpRequest) -> func.HttpResponse:
    """Silent Push Trigger — P0 for Ghost survival (PRD §3.4)"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()
        user_id = current_user["email"]
        pending_actions = await client.get_pending_ghost_actions(user_id)

        push_payload = {
            "user_id": user_id,
            "trigger_type": "morning_cycle",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "actions": pending_actions or [],
            "priority": "high",
        }
        await client.queue_silent_push(user_id, push_payload)

        return success_response(
            {
                "status": "queued",
                "actions_count": len(pending_actions or []),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        )

    except Exception as e:
        logger.error(f"Ghost silent push error: {str(e)}")
        return error_response("Internal server error", status_code=500)


@ghost_bp.route(
    route="ghost/trust",
    methods=["GET", "POST"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def ghost_trust(req: func.HttpRequest) -> func.HttpResponse:
    """Trust State API — 5-phase state machine (PRD §2.2.2)"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()
        user_id = current_user["email"]

        if req.method == "GET":
            trust_state = await client.get_trust_state(user_id)
            if not trust_state:
                trust_state = {
                    "user_id": user_id,
                    "phase": "observer",
                    "confidence": 0.0,
                    "consecutive_deletes": 0,
                    "last_updated": datetime.now(timezone.utc).isoformat(),
                }
            return success_response(trust_state)

        elif req.method == "POST":
            try:
                event_data = req.get_json()
            except ValueError:
                return error_response(
                    "Invalid JSON", status_code=400, code="INVALID_JSON"
                )

            required_fields = ["event_type", "timestamp"]
            missing = [f for f in required_fields if f not in event_data]
            if missing:
                return error_response(
                    f"Missing required fields: {', '.join(missing)}",
                    status_code=400,
                    code="MISSING_FIELDS",
                )

            updated_state = await client.record_trust_event(user_id, event_data)
            return success_response(updated_state)

        return error_response("Method not allowed", status_code=405)

    except Exception as e:
        logger.error(f"Ghost trust API error: {str(e)}")
        return error_response("Internal server error", status_code=500)


@ghost_bp.route(
    route="ghost/schedule",
    methods=["GET", "POST", "PUT"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def ghost_schedule(req: func.HttpRequest) -> func.HttpResponse:
    """Schedule Sync API — calendar-centric training blocks (PRD §3.1)"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()
        user_id = current_user["email"]

        if req.method == "GET":
            try:
                week_offset = int(req.params.get("week_offset", 0))
            except (ValueError, TypeError):
                week_offset = 0
            blocks = await client.get_training_blocks(user_id, week_offset)
            return success_response({"blocks": blocks, "week_offset": week_offset})

        elif req.method == "POST":
            try:
                block_data = req.get_json()
            except ValueError:
                return error_response(
                    "Invalid JSON", status_code=400, code="INVALID_JSON"
                )

            required_fields = ["start_time", "duration_minutes", "workout_type"]
            missing = [f for f in required_fields if f not in block_data]
            if missing:
                return error_response(
                    f"Missing required fields: {', '.join(missing)}",
                    status_code=400,
                    code="MISSING_FIELDS",
                )

            created_block = await client.create_training_block(user_id, block_data)
            return success_response(created_block, status_code=201)

        elif req.method == "PUT":
            try:
                block_data = req.get_json()
            except ValueError:
                return error_response(
                    "Invalid JSON", status_code=400, code="INVALID_JSON"
                )

            if "block_id" not in block_data:
                return error_response(
                    "block_id required for update",
                    status_code=400,
                    code="MISSING_FIELD",
                )

            updated_block = await client.update_training_block(
                user_id, block_data["block_id"], block_data
            )
            return success_response(updated_block)

        return error_response("Method not allowed", status_code=405)

    except Exception as e:
        logger.error(f"Ghost schedule API error: {str(e)}")
        return error_response("Internal server error", status_code=500)


@ghost_bp.route(
    route="ghost/phenome/sync",
    methods=["POST"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def ghost_phenome_sync(req: func.HttpRequest) -> func.HttpResponse:
    """Phenome Sync API — 3-store architecture (Tech Spec §2.3)"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()
        user_id = current_user["email"]

        try:
            sync_data = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        if not sync_data or "store_type" not in sync_data:
            return error_response(
                "store_type required (raw_signal|derived_state|behavioral_memory)",
                status_code=400,
                code="MISSING_FIELD",
            )

        store_type = sync_data["store_type"]
        client_version = sync_data.get("version", 0)
        client_data = sync_data.get("data", {})

        server_data = await client.get_phenome_store(user_id, store_type)
        server_version = server_data.get("version", 0) if server_data else 0

        if client_version > server_version:
            await client.update_phenome_store(
                user_id, store_type, client_data, client_version
            )
            return success_response(
                {"status": "updated", "version": client_version, "conflicts": []}
            )
        elif server_version > client_version:
            return success_response(
                {
                    "status": "outdated",
                    "version": server_version,
                    "data": server_data.get("data", {}) if server_data else {},
                    "conflicts": [],
                }
            )
        else:
            return success_response(
                {"status": "synced", "version": server_version, "conflicts": []}
            )

    except Exception as e:
        logger.error(f"Ghost phenome sync error: {str(e)}")
        return error_response("Internal server error", status_code=500)


@ghost_bp.route(
    route="ghost/decision-receipt",
    methods=["POST"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def ghost_decision_receipt(req: func.HttpRequest) -> func.HttpResponse:
    """Decision Receipt API — forensic log (PRD §4.2)"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()
        user_id = current_user["email"]

        try:
            receipt_data = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        required_fields = [
            "decision_type",
            "inputs",
            "output",
            "explanation",
            "timestamp",
        ]
        missing = [f for f in required_fields if f not in receipt_data]
        if missing:
            return error_response(
                f"Missing required fields: {', '.join(missing)}",
                status_code=400,
                code="MISSING_FIELDS",
            )

        stored_receipt = await client.store_decision_receipt(user_id, receipt_data)
        return success_response(stored_receipt, status_code=201)

    except Exception as e:
        logger.error(f"Ghost decision receipt error: {str(e)}")
        return error_response("Internal server error", status_code=500)


# =============================================================================
# Timer triggers
# =============================================================================


@ghost_bp.timer_trigger(
    schedule="0 55 5 * * *", arg_name="timer", run_on_startup=False
)
async def ghost_morning_wake_trigger(timer: func.TimerRequest) -> None:
    """Morning Ghost wake cycle (5:55 AM UTC) — PRD §3.4"""
    try:
        from shared.cosmos_db import get_global_client

        logger.info("Ghost morning wake trigger fired")
        client = await get_global_client()
        active_users = await client.get_active_users_for_morning_push()

        for user in active_users:
            try:
                push_payload = {
                    "user_id": user["id"],
                    "trigger_type": "morning_cycle",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "actions": [
                        "run_morning_cycle",
                        "check_schedule",
                        "update_recovery",
                    ],
                    "priority": "high",
                }
                await client.queue_silent_push(user["id"], push_payload)
                logger.info(f"Queued morning push for user {user['id']}")
            except Exception as user_error:
                logger.error(
                    f"Error queueing push for user {user['id']}: {user_error}"
                )

    except Exception as e:
        logger.error(f"Ghost morning wake trigger error: {str(e)}")


@ghost_bp.timer_trigger(
    schedule="0 0 21 * * 0", arg_name="timer", run_on_startup=False
)
async def ghost_sunday_evening_trigger(timer: func.TimerRequest) -> None:
    """Sunday evening week planning (9 PM UTC Sunday) — PRD §3.2"""
    try:
        from shared.cosmos_db import get_global_client

        logger.info("Ghost Sunday evening trigger fired")
        client = await get_global_client()
        users_for_planning = await client.get_users_for_weekly_planning()

        for user in users_for_planning:
            try:
                push_payload = {
                    "user_id": user["id"],
                    "trigger_type": "weekly_planning",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "actions": ["propose_week_schedule", "show_value_receipt"],
                    "priority": "normal",
                }
                await client.queue_silent_push(user["id"], push_payload)
                logger.info(f"Queued weekly planning push for user {user['id']}")
            except Exception as user_error:
                logger.error(
                    f"Error queueing weekly push for user {user['id']}: {user_error}"
                )

    except Exception as e:
        logger.error(f"Ghost Sunday evening trigger error: {str(e)}")

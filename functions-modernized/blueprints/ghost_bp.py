"""
Ghost Engine Blueprint
Endpoints: ghost/silent-push, ghost/trust, ghost/schedule, ghost/phenome/sync,
           ghost/decision-receipt, ghost/device-token, timer triggers
"""

import logging
import re
from datetime import datetime, timezone

import azure.functions as func

from shared.auth import get_current_user_from_token
from shared.helpers import error_response, success_response

logger = logging.getLogger(__name__)

ghost_bp = func.Blueprint()


# =============================================================================
# APNs push delivery helper
# =============================================================================


async def _deliver_push_to_user(
    user_id: str, payload: dict, cosmos_client
) -> dict:
    """
    Deliver a silent push to a single user via APNs.
    Returns delivery result dict. Clears stored token on APNs 410 (Unregistered).
    """
    try:
        # Get user's device token
        user_profile = await cosmos_client.get_user_profile(user_id)
        device_token = (user_profile or {}).get("apns_device_token")

        if not device_token:
            return {"user_id": user_id, "status": "skipped", "reason": "no_device_token"}

        from shared.apns_client import get_apns_client

        apns = await get_apns_client()
        result = await apns.send_silent_push(device_token, payload)

        # Handle APNs 410 Unregistered — clear stale token
        if result.get("code") == 410:
            logger.warning(f"Device token unregistered for {user_id}, clearing")
            await cosmos_client.upsert_document(
                "users",
                {**user_profile, "apns_device_token": None},
            )
            result["token_cleared"] = True

        result["user_id"] = user_id
        return result

    except Exception as e:
        logger.error(f"Push delivery failed for {user_id}: {e}")
        return {"user_id": user_id, "status": "error", "error": str(e)}


@ghost_bp.route(
    route="ghost/sync", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def ghost_sync(req: func.HttpRequest) -> func.HttpResponse:
    """Ghost State Sync — iOS cold-start & periodic sync (PRD §3.2)

    iOS ``VigorAPIClient.syncGhostState()`` POSTs a ``GhostStateDTO`` and
    expects a ``GhostSyncResponse`` back (trust score, phase, pending actions,
    server time).
    """
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()
        user_id = current_user["email"]

        # Parse optional client state
        try:
            body = req.get_json()
        except ValueError:
            body = {}

        # Store device health snapshot on user doc if provided
        if body:
            user_profile = await client.get_user_profile(user_id)
            if user_profile:
                user_profile["last_ghost_sync"] = datetime.now(timezone.utc).isoformat()
                user_profile["ghost_health_mode"] = body.get("healthMode", "NORMAL")
                user_profile["device_id"] = body.get("deviceId")
                await client.upsert_document("users", user_profile)

        # Get current trust state
        trust_state = await client.get_trust_state(user_id)
        trust_score = (trust_state or {}).get("confidence", 0.0)
        trust_phase = (trust_state or {}).get("phase", "observer")

        # Get pending actions
        pending_actions = await client.get_pending_ghost_actions(user_id)
        actions_out = [
            {
                "id": a.get("id", ""),
                "type": a.get("trigger_type", a.get("type", "")),
                "payload": a.get("payload", {}),
                "expiresAt": a.get("expires_at", datetime.now(timezone.utc).isoformat()),
            }
            for a in (pending_actions or [])
        ]

        return success_response({
            "trustScore": trust_score,
            "trustPhase": trust_phase,
            "pendingActions": actions_out,
            "serverTime": datetime.now(timezone.utc).isoformat(),
        })

    except Exception as e:
        logger.error(f"Ghost sync error: {str(e)}")
        return error_response("Internal server error", status_code=500)


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

        # Deliver immediately via APNs
        delivery = await _deliver_push_to_user(user_id, push_payload, client)

        return success_response(
            {
                "status": "queued",
                "delivery": delivery.get("status", "unknown"),
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
# Device Token Management
# =============================================================================

_DEVICE_TOKEN_RE = re.compile(r"^[0-9a-fA-F]{64}$")


@ghost_bp.route(
    route="ghost/device-token",
    methods=["POST", "DELETE"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def ghost_device_token(req: func.HttpRequest) -> func.HttpResponse:
    """Device Token API — register/remove APNs token for push delivery"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()
        user_id = current_user["email"]

        if req.method == "POST":
            try:
                body = req.get_json()
            except ValueError:
                return error_response(
                    "Invalid JSON", status_code=400, code="INVALID_JSON"
                )

            device_token = (body or {}).get("device_token", "")
            if not device_token or not _DEVICE_TOKEN_RE.match(device_token):
                return error_response(
                    "device_token must be a 64-character hex string",
                    status_code=400,
                    code="INVALID_TOKEN",
                )

            # Store token on the user document
            user_profile = await client.get_user_profile(user_id)
            if not user_profile:
                user_profile = {"id": user_id, "email": user_id}

            user_profile["apns_device_token"] = device_token
            user_profile["apns_platform"] = body.get("platform", "ios")
            user_profile["apns_registered_at"] = datetime.now(
                timezone.utc
            ).isoformat()
            await client.upsert_document("users", user_profile)

            logger.info(f"Device token registered for {user_id}")
            return success_response(
                {"status": "registered", "token_prefix": device_token[:8] + "..."}
            )

        elif req.method == "DELETE":
            user_profile = await client.get_user_profile(user_id)
            if user_profile:
                user_profile["apns_device_token"] = None
                user_profile["apns_platform"] = None
                await client.upsert_document("users", user_profile)

            logger.info(f"Device token removed for {user_id}")
            return success_response({"status": "removed"})

        return error_response("Method not allowed", status_code=405)

    except Exception as e:
        logger.error(f"Ghost device token error: {str(e)}")
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

                # Deliver via APNs
                delivery = await _deliver_push_to_user(
                    user["id"], push_payload, client
                )
                logger.info(
                    f"Morning push for {user['id']}: {delivery.get('status')}"
                )
            except Exception as user_error:
                logger.error(
                    f"Error processing morning push for {user['id']}: {user_error}"
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

                # Deliver via APNs
                delivery = await _deliver_push_to_user(
                    user["id"], push_payload, client
                )
                logger.info(
                    f"Weekly push for {user['id']}: {delivery.get('status')}"
                )
            except Exception as user_error:
                logger.error(
                    f"Error processing weekly push for {user['id']}: {user_error}"
                )

    except Exception as e:
        logger.error(f"Ghost Sunday evening trigger error: {str(e)}")

"""
Trust State Blueprint — iOS-facing aliases
Endpoints: trust/event, trust/history

These endpoints match the paths called by iOS ``VigorAPIClient.swift``.
The underlying logic delegates to the same Cosmos operations used by
``ghost_bp.ghost_trust``.
"""

import logging
from datetime import datetime, timezone

import azure.functions as func

from shared.auth import get_current_user_from_token
from shared.helpers import error_response, success_response

logger = logging.getLogger(__name__)

trust_bp = func.Blueprint()


@trust_bp.route(
    route="trust/event", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def trust_record_event(req: func.HttpRequest) -> func.HttpResponse:
    """Record a trust event — iOS ``recordTrustEvent``

    Accepts ``TrustEventDTO`` with ``event`` (event_type) and ``timestamp``.
    """
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        try:
            body = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        if not body:
            return error_response(
                "Request body required", status_code=400, code="EMPTY_BODY"
            )

        # Include iOS phase in event data if provided
        event_data = {
            "event_type": body.get("event_type") or body.get("event", ""),
            "timestamp": body.get("timestamp", datetime.now(timezone.utc).isoformat()),
        }
        if body.get("context"):
            event_data["context"] = body["context"]
        if body.get("phase"):
            event_data["phase"] = body["phase"]
        if body.get("trust_score") is not None:
            event_data["trust_score"] = body["trust_score"]

        if not event_data["event_type"]:
            return error_response(
                "Missing required field: event_type (or event)",
                status_code=400,
                code="MISSING_FIELD",
            )

        client = await get_global_client()
        user_id = current_user["email"]
        try:
            updated_state = await client.record_trust_event(user_id, event_data)
        except ValueError as ve:
            return error_response(str(ve), status_code=400, code="INVALID_EVENT_TYPE")
        return success_response(updated_state)

    except Exception as e:
        logger.error(f"Trust record event error: {str(e)}")
        return error_response("Internal server error", status_code=500)


@trust_bp.route(
    route="trust/history", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS
)
async def trust_get_history(req: func.HttpRequest) -> func.HttpResponse:
    """Get trust history — iOS ``getTrustHistory``

    Returns ``TrustHistoryResponse``: currentScore, currentPhase, history
    entries, and phase transitions.
    """
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()
        user_id = current_user["email"]

        trust_state = await client.get_trust_state(user_id)
        # Use trust_score (0-100 scale) matching iOS; fall back to confidence (0-1) migrated
        current_score = (trust_state or {}).get("trust_score",
                         (trust_state or {}).get("confidence", 0.0) * 100.0)
        current_phase = (trust_state or {}).get("phase", "observer")

        # Get trust event history from trust_states container
        history_entries = await client.get_trust_history(user_id)

        # Separate out phase transitions
        phase_transitions = [
            e for e in history_entries if e.get("event_type") == "phase_transition"
        ]

        return success_response({
            "currentScore": current_score,
            "currentPhase": current_phase,
            "history": history_entries,
            "phaseTransitions": phase_transitions,
        })

    except Exception as e:
        logger.error(f"Trust get history error: {str(e)}")
        return error_response("Internal server error", status_code=500)

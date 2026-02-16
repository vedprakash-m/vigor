"""
Workout Management Blueprint
Endpoints: workouts/generate, workouts, workouts/{id}, workouts/{id}/sessions,
           workouts/history, blocks/sync, blocks/outcome
"""

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict
from uuid import uuid4

import azure.functions as func

from shared.auth import get_current_user_from_token
from shared.helpers import error_response, parse_pagination, parse_request_body, success_response
from shared.models import WorkoutGenerationRequest, WorkoutSessionRequest

logger = logging.getLogger(__name__)

workouts_bp = func.Blueprint()


@workouts_bp.route(
    route="workouts/generate", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def generate_workout(req: func.HttpRequest) -> func.HttpResponse:
    """Generate personalized workout using OpenAI gpt-5-mini"""
    try:
        from shared.cosmos_db import get_global_client
        from shared.openai_client import OpenAIClient
        from shared.rate_limiter import apply_ai_generation_limit

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        rate_response = await apply_ai_generation_limit(req, user_id=current_user["email"])
        if rate_response:
            return rate_response

        parsed, err = parse_request_body(req, WorkoutGenerationRequest)
        if err:
            return err

        client = await get_global_client()

        # Validate budget before AI operation
        budget_check = await _validate_ai_budget(client)
        if not budget_check["approved"]:
            return error_response(
                "AI budget exceeded",
                status_code=429,
                code="BUDGET_EXCEEDED",
                details=budget_check.get("reason"),
            )

        user_profile = await client.get_user_profile(current_user["email"])
        if not user_profile:
            user_profile = {
                "email": current_user["email"],
                "fitness_level": "beginner",
                "fitness_goals": ["general_fitness"],
                "available_equipment": ["bodyweight"],
            }

        ai_client = OpenAIClient()
        workout = await ai_client.generate_workout(
            user_profile=user_profile, preferences=parsed.model_dump()
        )

        # Safety validation on AI-generated workout
        from shared.models import WorkoutSafetyValidator

        violations = WorkoutSafetyValidator.validate(workout)
        if violations:
            logger.warning(f"AI workout safety violations: {violations}")
            return error_response(
                "Generated workout failed safety checks",
                status_code=422,
                code="UNSAFE_WORKOUT",
                details="; ".join(violations),
            )

        saved_workout = await client.create_workout(
            user_id=current_user["email"], workout_data=workout
        )
        return success_response(saved_workout, status_code=201)

    except Exception as e:
        logger.error(f"Error generating workout: {str(e)}")
        return error_response("Failed to generate workout", status_code=500)


@workouts_bp.route(
    route="workouts", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS
)
async def get_user_workouts(req: func.HttpRequest) -> func.HttpResponse:
    """Get user's workout collection"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        # Compatibility path for iOS client:
        # GET /workouts?days=30 should return workout logs (history),
        # while canonical /workouts returns workout plans.
        days_param = req.params.get("days")

        limit, offset = parse_pagination(req)
        client = await get_global_client()

        if days_param is not None:
            try:
                days = max(1, min(int(days_param), 365))
            except (ValueError, TypeError):
                days = 30

            logs = await client.get_user_workout_logs(
                user_id=current_user["email"], limit=max(limit, 200)
            )
            cutoff = datetime.now(timezone.utc) - timedelta(days=days)

            filtered_logs = []
            for item in logs:
                completed_at_raw = item.get("completedAt") or item.get("completed_at")
                if not completed_at_raw:
                    continue
                try:
                    completed_at = datetime.fromisoformat(
                        str(completed_at_raw).replace("Z", "+00:00")
                    )
                except ValueError:
                    continue

                if completed_at >= cutoff:
                    filtered_logs.append(item)

            return success_response(filtered_logs)

        workouts = await client.get_user_workouts(
            user_id=current_user["email"], limit=limit, offset=offset
        )
        return success_response(workouts)

    except Exception as e:
        logger.error(f"Error getting workouts: {str(e)}")
        return error_response("Failed to retrieve workouts", status_code=500)


@workouts_bp.route(
    route="workouts/{workout_id}",
    methods=["GET", "DELETE"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def workout_detail(req: func.HttpRequest) -> func.HttpResponse:
    """Get or delete specific workout"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        workout_id = req.route_params.get("workout_id")
        if not workout_id:
            return error_response("workout_id is required", status_code=400, code="MISSING_PARAM")
        client = await get_global_client()

        if req.method == "GET":
            workout = await client.get_workout(workout_id, current_user["email"])
            if not workout:
                return error_response(
                    "Workout not found", status_code=404, code="NOT_FOUND"
                )
            return success_response(workout)

        elif req.method == "DELETE":
            success = await client.delete_workout(workout_id, current_user["email"])
            if not success:
                return error_response(
                    "Workout not found", status_code=404, code="NOT_FOUND"
                )
            return func.HttpResponse(status_code=204)

        return error_response("Method not allowed", status_code=405)

    except Exception as e:
        logger.error(f"Error in workout detail: {str(e)}")
        return error_response("Internal server error", status_code=500)


@workouts_bp.route(
    route="workouts/{workout_id}/sessions",
    methods=["POST"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def log_workout_session(req: func.HttpRequest) -> func.HttpResponse:
    """Log completed workout session"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        workout_id = req.route_params.get("workout_id")

        parsed, err = parse_request_body(req, WorkoutSessionRequest)
        if err:
            return err

        client = await get_global_client()
        workout_log = await client.create_workout_log(
            user_id=current_user["email"],
            workout_id=workout_id,
            session_data=parsed.model_dump(),
        )
        return success_response(workout_log, status_code=201)

    except Exception as e:
        logger.error(f"Error logging workout session: {str(e)}")
        return error_response("Failed to log workout session", status_code=500)


@workouts_bp.route(
    route="workouts/history", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS
)
async def get_workout_history(req: func.HttpRequest) -> func.HttpResponse:
    """Get user's workout log history"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        limit, _ = parse_pagination(req, max_limit=100, default_limit=50)
        client = await get_global_client()
        logs = await client.get_user_workout_logs(
            user_id=current_user["email"], limit=limit
        )
        return success_response(logs)

    except Exception as e:
        logger.error(f"Error getting workout history: {str(e)}")
        return error_response("Failed to retrieve workout history", status_code=500)


@workouts_bp.route(
    route="workouts/log", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def log_workout_compat(req: func.HttpRequest) -> func.HttpResponse:
    """Compatibility alias for frontend `/workouts/log` endpoint.

    Canonical route is `/workouts/{workout_id}/sessions` or `/workouts` (record).
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

        workout_id = body.get("workoutId") if isinstance(body, dict) else None
        duration = (body or {}).get("actualDuration") or (body or {}).get("durationMinutes")
        rating = (body or {}).get("rating")

        if not duration:
            return error_response(
                "Missing required field: actualDuration",
                status_code=400,
                code="MISSING_FIELD",
            )

        session_payload: Dict[str, Any] = {
            "exercises": (body or {}).get("exercisesCompleted", []),
            "durationMinutes": int(duration),
            "intensity": int(rating) if isinstance(rating, (int, float)) else 5,
            "notes": (body or {}).get("notes"),
        }

        client = await get_global_client()
        workout_log = await client.create_workout_log(
            user_id=current_user["email"],
            workout_id=workout_id,
            session_data=session_payload,
        )
        return success_response(workout_log, status_code=201)

    except Exception as e:
        logger.error(f"Error in workouts/log compatibility endpoint: {str(e)}")
        return error_response("Failed to log workout", status_code=500)


# =============================================================================
# iOS-facing endpoints (VigorAPIClient.swift contract)
# =============================================================================


@workouts_bp.route(
    route="workouts", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def record_workout(req: func.HttpRequest) -> func.HttpResponse:
    """Record a completed workout — iOS ``recordWorkout``"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        try:
            workout_data = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        if not workout_data or "type" not in workout_data:
            return error_response(
                "Missing required field: type",
                status_code=400,
                code="MISSING_FIELD",
            )

        client = await get_global_client()
        workout_log = await client.create_workout_log(
            user_id=current_user["email"],
            workout_id=workout_data.get("id", str(uuid4())),
            session_data=workout_data,
        )
        return success_response(workout_log, status_code=201)

    except Exception as e:
        logger.error(f"Error recording workout: {str(e)}")
        return error_response("Failed to record workout", status_code=500)


@workouts_bp.route(
    route="blocks/sync", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def sync_training_blocks(req: func.HttpRequest) -> func.HttpResponse:
    """Sync training blocks — iOS ``syncTrainingBlocks``"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        try:
            body = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        blocks = (body or {}).get("blocks", [])
        if not isinstance(blocks, list):
            return error_response(
                "blocks must be an array", status_code=400, code="INVALID_BODY"
            )

        client = await get_global_client()
        user_id = current_user["email"]

        synced_blocks = []
        conflict_resolutions = []
        for block in blocks:
            block_id = block.get("id")
            if block_id:
                # Try update
                try:
                    updated = await client.update_training_block(
                        user_id, block_id, block
                    )
                    synced_blocks.append(updated)
                except ValueError:
                    # Block doesn't exist — create it
                    created = await client.create_training_block(user_id, block)
                    synced_blocks.append(created)
            else:
                created = await client.create_training_block(user_id, block)
                synced_blocks.append(created)

        return success_response({
            "blocks": synced_blocks,
            "conflictResolutions": conflict_resolutions,
        })

    except Exception as e:
        logger.error(f"Error syncing training blocks: {str(e)}")
        return error_response("Failed to sync training blocks", status_code=500)


@workouts_bp.route(
    route="blocks/outcome", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def record_block_outcome(req: func.HttpRequest) -> func.HttpResponse:
    """Record block outcome — iOS ``reportBlockOutcome``"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        try:
            body = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        block_id = (body or {}).get("blockId")
        outcome = (body or {}).get("outcome")
        if not block_id or not outcome:
            return error_response(
                "Missing required fields: blockId, outcome",
                status_code=400,
                code="MISSING_FIELDS",
            )

        client = await get_global_client()
        user_id = current_user["email"]

        update_data = {
            "status": outcome,
            "outcome_recorded_at": datetime.now(timezone.utc).isoformat(),
        }
        if body.get("completedWorkoutId"):
            update_data["completed_workout_id"] = body["completedWorkoutId"]
        if body.get("missedReason"):
            update_data["missed_reason"] = body["missedReason"]

        updated_block = await client.update_training_block(
            user_id, block_id, update_data
        )
        return success_response(updated_block)

    except ValueError:
        return error_response("Block not found", status_code=404, code="NOT_FOUND")
    except Exception as e:
        logger.error(f"Error recording block outcome: {str(e)}")
        return error_response("Failed to record block outcome", status_code=500)


# Private helper
async def _validate_ai_budget(cosmos_client: Any) -> Dict[str, Any]:
    """Validate AI budget before operation"""
    try:
        from shared.config import get_settings

        settings = get_settings()
        current_spend = await cosmos_client.get_daily_ai_spend()
        monthly_budget = float(settings.AI_MONTHLY_BUDGET)
        daily_budget = monthly_budget / 30

        if current_spend >= daily_budget * 0.9:
            return {
                "approved": False,
                "reason": "Daily AI budget nearly exceeded",
                "current_spend": current_spend,
                "daily_budget": daily_budget,
            }
        return {"approved": True, "remaining_budget": daily_budget - current_spend}

    except Exception as e:
        logger.error(f"Error validating budget: {str(e)}")
        return {"approved": False, "reason": "Budget validation failed"}

"""
Workout Management Blueprint
Endpoints: workouts/generate, workouts, workouts/{id}, workouts/{id}/sessions, workouts/history
"""

import logging
from typing import Any, Dict

import azure.functions as func

from shared.auth import get_current_user_from_token
from shared.helpers import error_response, parse_pagination, success_response

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
        from shared.rate_limiter import RateLimiter

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        rate_limiter = RateLimiter()
        if not await rate_limiter.check_rate_limit(
            key=f"workout_gen:{current_user['email']}",
            limit=50,
            window=86400,
        ):
            return error_response(
                "Rate limit exceeded. Please try again later.",
                status_code=429,
                code="RATE_LIMITED",
            )

        try:
            workout_request = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

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
            user_profile=user_profile, preferences=workout_request
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

        limit, offset = parse_pagination(req)
        client = await get_global_client()
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

        try:
            session_data = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        client = await get_global_client()
        workout_log = await client.create_workout_log(
            user_id=current_user["email"],
            workout_id=workout_id,
            session_data=session_data,
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

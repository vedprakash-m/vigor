"""
AI Coach Chat Blueprint
Endpoints: coach/chat, coach/history, coach/recommend, coach/recovery
"""

import logging
from datetime import datetime, timezone

import azure.functions as func

from shared.auth import get_current_user_from_token
from shared.helpers import error_response, parse_pagination, success_response

logger = logging.getLogger(__name__)

coach_bp = func.Blueprint()


@coach_bp.route(
    route="coach/chat", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def coach_chat(req: func.HttpRequest) -> func.HttpResponse:
    """Chat with AI coach using OpenAI gpt-5-mini"""
    try:
        from shared.cosmos_db import get_global_client
        from shared.openai_client import OpenAIClient
        from shared.rate_limiter import RateLimiter

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        rate_limiter = RateLimiter()
        if not await rate_limiter.check_rate_limit(
            key=f"coach_chat:{current_user['email']}",
            limit=50,
            window=86400,
        ):
            return error_response(
                "Rate limit exceeded", status_code=429, code="RATE_LIMITED"
            )

        try:
            message_data = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        if not message_data or "message" not in message_data:
            return error_response(
                "Missing required field: message",
                status_code=400,
                code="MISSING_FIELD",
            )

        client = await get_global_client()

        # Validate budget
        from shared.config import get_settings

        settings = get_settings()
        current_spend = await client.get_daily_ai_spend()
        monthly_budget = float(settings.AI_MONTHLY_BUDGET)
        daily_budget = monthly_budget / 30
        if current_spend >= daily_budget * 0.9:
            return error_response(
                "AI budget exceeded", status_code=429, code="BUDGET_EXCEEDED"
            )

        conversation_history = await client.get_conversation_history(
            current_user["email"], limit=10
        )
        user_profile = await client.get_user_profile(current_user["email"])

        ai_client = OpenAIClient()
        ai_response = await ai_client.coach_chat(
            message=message_data["message"],
            history=conversation_history,
            user_context=user_profile,
        )

        now = datetime.now(timezone.utc).isoformat()
        await client.save_chat_messages(
            [
                {
                    "role": "user",
                    "content": message_data["message"],
                    "userId": current_user["email"],
                    "createdAt": now,
                },
                {
                    "role": "assistant",
                    "content": ai_response,
                    "userId": current_user["email"],
                    "providerUsed": "gpt-5-mini",
                    "createdAt": now,
                },
            ]
        )

        return success_response({"response": ai_response})

    except Exception as e:
        logger.error(f"Error in coach chat: {str(e)}")
        return error_response("Failed to process chat message", status_code=500)


@coach_bp.route(
    route="coach/history",
    methods=["GET", "DELETE"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def coach_history(req: func.HttpRequest) -> func.HttpResponse:
    """Get or clear coach conversation history"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()

        if req.method == "GET":
            limit, _ = parse_pagination(req, max_limit=100, default_limit=50)
            history = await client.get_conversation_history(
                current_user["email"], limit=limit
            )
            return success_response(history)

        elif req.method == "DELETE":
            await client.clear_conversation_history(current_user["email"])
            return success_response({"message": "Conversation history cleared"})

        return error_response("Method not allowed", status_code=405)

    except Exception as e:
        logger.error(f"Error in coach history: {str(e)}")
        return error_response("Failed to process history request", status_code=500)


# =============================================================================
# iOS-facing endpoints (VigorAPIClient.swift contract)
# =============================================================================


@coach_bp.route(
    route="coach/recommend", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def coach_recommend(req: func.HttpRequest) -> func.HttpResponse:
    """AI workout recommendation — iOS ``getWorkoutRecommendation``

    Accepts ``WorkoutContext`` with recent workouts, sleep, HRV, trust phase,
    and available windows.  Returns a ``WorkoutRecommendation``.
    """
    try:
        from shared.cosmos_db import get_global_client
        from shared.openai_client import OpenAIClient
        from shared.rate_limiter import RateLimiter

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        rate_limiter = RateLimiter()
        if not await rate_limiter.check_rate_limit(
            key=f"coach_recommend:{current_user['email']}",
            limit=30,
            window=86400,
        ):
            return error_response(
                "Rate limit exceeded", status_code=429, code="RATE_LIMITED"
            )

        try:
            context = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        if not context:
            return error_response(
                "Workout context required",
                status_code=400,
                code="EMPTY_BODY",
            )

        client = await get_global_client()
        user_profile = await client.get_user_profile(current_user["email"])
        if not user_profile:
            user_profile = {
                "email": current_user["email"],
                "fitness_level": "beginner",
            }

        # Build recommendation request for OpenAI
        ai_client = OpenAIClient()

        preferences = {
            "durationMinutes": context.get("suggestedDuration", 45),
            "focusAreas": [],
            "difficulty": "moderate",
        }

        # Adjust difficulty based on recovery / HRV
        if context.get("hrvData"):
            trend = context["hrvData"].get("trend", "stable")
            if trend == "declining":
                preferences["difficulty"] = "easy"
            elif trend == "improving":
                preferences["difficulty"] = "hard"

        workout = await ai_client.generate_workout(
            user_profile=user_profile, preferences=preferences
        )

        # Build iOS-compatible response
        available_windows = context.get("availableWindows", [])
        suggested_window = available_windows[0] if available_windows else {
            "start": datetime.now(timezone.utc).isoformat(),
            "end": datetime.now(timezone.utc).isoformat(),
            "durationMinutes": preferences["durationMinutes"],
            "conflictLevel": "none",
        }

        return success_response({
            "workoutType": workout.get("name", "Custom Workout"),
            "suggestedWindow": suggested_window,
            "reasoning": workout.get("description", "AI-generated recommendation"),
            "confidence": 0.85,
            "alternatives": [],
        })

    except Exception as e:
        logger.error(f"Error in coach recommend: {str(e)}")
        return error_response("Failed to generate recommendation", status_code=500)


@coach_bp.route(
    route="coach/recovery", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS
)
async def coach_recovery(req: func.HttpRequest) -> func.HttpResponse:
    """Recovery assessment — iOS ``getRecoveryAssessment``

    Analyses recent workouts, rest days, and trust state to produce a
    recovery score and recommendation.
    """
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()
        user_id = current_user["email"]

        # Get recent workout logs
        logs = await client.get_user_workout_logs(user_id, limit=14)

        # Simple heuristic: score based on rest days & volume
        total_workouts = len(logs)
        if total_workouts == 0:
            score = 100.0
            status = "recovered"
            suggestion = "You're fully rested! Time to start your fitness journey."
            rest_days = 0
        elif total_workouts <= 3:
            score = 85.0
            status = "recovered"
            suggestion = "Good recovery. You're ready for your next workout."
            rest_days = 0
        elif total_workouts <= 6:
            score = 60.0
            status = "recovering"
            suggestion = "Consider a lighter session or active recovery today."
            rest_days = 1
        else:
            score = 35.0
            status = "fatigued"
            suggestion = "High training volume detected. A rest day is recommended."
            rest_days = 2

        factors = [
            {
                "name": "Recent Volume",
                "value": float(total_workouts),
                "impact": "negative" if total_workouts > 5 else "positive",
                "description": f"{total_workouts} workouts in last 14 days",
            },
        ]

        # Get trust state for additional context
        trust_state = await client.get_trust_state(user_id)
        if trust_state:
            factors.append({
                "name": "Trust Phase",
                "value": trust_state.get("confidence", 0),
                "impact": "neutral",
                "description": f"Phase: {trust_state.get('phase', 'observer')}",
            })

        return success_response({
            "score": score,
            "status": status,
            "factors": factors,
            "recommendation": suggestion,
            "suggestedRestDays": rest_days,
        })

    except Exception as e:
        logger.error(f"Error in coach recovery: {str(e)}")
        return error_response("Failed to assess recovery", status_code=500)

"""
AI Coach Chat Blueprint
Endpoints: coach/chat, coach/history, coach/recommend, coach/recovery
"""

import logging
from datetime import datetime, timezone

import azure.functions as func

from shared.auth import get_current_user_from_token
from shared.helpers import error_response, parse_pagination, parse_request_body, success_response
from shared.models import CoachChatRequest, WorkoutContextRequest

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
        from shared.rate_limiter import apply_ai_generation_limit

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        rate_response = await apply_ai_generation_limit(req, user_id=current_user["email"])
        if rate_response:
            return rate_response

        parsed, err = parse_request_body(req, CoachChatRequest)
        if err:
            return err

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
            message=parsed.message,
            history=conversation_history,
            user_context=user_profile,
        )

        now = datetime.now(timezone.utc).isoformat()
        await client.save_chat_messages(
            [
                {
                    "role": "user",
                    "content": parsed.message,
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
        from shared.rate_limiter import apply_ai_generation_limit

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        rate_response = await apply_ai_generation_limit(req, user_id=current_user["email"])
        if rate_response:
            return rate_response

        parsed, err = parse_request_body(req, WorkoutContextRequest)
        if err:
            return err

        context = parsed.model_dump()

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

        # Get HRV and sleep data from phenome store if available
        hrv_trend = None
        sleep_quality = None
        try:
            phenome_data = await client.get_phenome_store(user_id, "raw_signal")
            if phenome_data and isinstance(phenome_data, dict) and isinstance(phenome_data.get("data"), dict):
                pd = phenome_data["data"]
                hrv_trend = pd.get("hrv_trend")
                raw_sleep = pd.get("sleep_quality")
                if isinstance(raw_sleep, (int, float)):
                    sleep_quality = raw_sleep
        except Exception:
            pass  # Gracefully degrade if phenome store unavailable

        # Multi-factor recovery scoring
        total_workouts = len(logs)

        # Base score from workout volume
        if total_workouts == 0:
            volume_score = 100.0
        elif total_workouts <= 3:
            volume_score = 85.0
        elif total_workouts <= 6:
            volume_score = 60.0
        else:
            volume_score = 35.0

        # HRV modifier (±15 points)
        hrv_modifier = 0.0
        if hrv_trend == "improving":
            hrv_modifier = 10.0
        elif hrv_trend == "declining":
            hrv_modifier = -15.0
        elif hrv_trend == "stable":
            hrv_modifier = 5.0

        # Sleep modifier (±10 points)
        sleep_modifier = 0.0
        if sleep_quality is not None:
            if sleep_quality >= 80:
                sleep_modifier = 10.0
            elif sleep_quality >= 60:
                sleep_modifier = 0.0
            else:
                sleep_modifier = -10.0

        score = max(0.0, min(100.0, volume_score + hrv_modifier + sleep_modifier))

        if score >= 75:
            status = "recovered"
            suggestion = "Good recovery. You're ready for your next workout."
            rest_days = 0
        elif score >= 50:
            status = "recovering"
            suggestion = "Consider a lighter session or active recovery today."
            rest_days = 1
        else:
            status = "fatigued"
            suggestion = "High training load or low recovery signals. A rest day is recommended."
            rest_days = 2

        factors = [
            {
                "name": "Recent Volume",
                "value": float(total_workouts),
                "impact": "negative" if total_workouts > 5 else "positive",
                "description": f"{total_workouts} workouts in last 14 days",
            },
        ]

        if hrv_trend:
            factors.append({
                "name": "HRV Trend",
                "value": hrv_modifier,
                "impact": "negative" if hrv_modifier < 0 else "positive",
                "description": f"HRV trend: {hrv_trend}",
            })

        if sleep_quality is not None:
            factors.append({
                "name": "Sleep Quality",
                "value": float(sleep_quality),
                "impact": "negative" if sleep_quality < 60 else "positive",
                "description": f"Recent sleep quality: {sleep_quality}%",
            })

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

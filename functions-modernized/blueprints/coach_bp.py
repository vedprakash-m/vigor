"""
AI Coach Chat Blueprint
Endpoints: coach/chat, coach/history
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

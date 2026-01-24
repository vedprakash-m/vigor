"""
Vigor Backend - Azure Functions App
Single resource group (vigor-rg), Cosmos DB Serverless, Azure OpenAI gpt-4o-mini
Production domain: vigor.vedprakash.net
"""

import azure.functions as func
import json
import logging
import os
from datetime import datetime, timezone
from typing import Dict, Any, Optional

# Import shared modules
from shared.auth import get_current_user_from_token, require_admin_user
from shared.cosmos_db import CosmosDBClient
from shared.openai_client import OpenAIClient
from shared.models import (
    UserProfile, WorkoutPlan, WorkoutLog, AICoachMessage,
    WorkoutGenerationRequest, CoachChatRequest
)
from shared.rate_limiter import RateLimiter
from shared.config import get_settings

# Initialize components
settings = get_settings()
cosmos_db = CosmosDBClient()
ai_client = OpenAIClient()
rate_limiter = RateLimiter()

# Create Function App
app = func.FunctionApp()

# Configure logging
logging.basicConfig(level=getattr(logging, settings.LOG_LEVEL))
logger = logging.getLogger(__name__)

# =============================================================================
# AUTHENTICATION & USER MANAGEMENT
# =============================================================================

@app.route(route="auth/me", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def get_current_user(req: func.HttpRequest) -> func.HttpResponse:
    """Get current user profile from Microsoft Entra ID token"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized - Valid Microsoft Entra ID token required"}),
                status_code=401,
                mimetype="application/json"
            )

        # Get full profile from Cosmos DB using email as key
        profile = await cosmos_db.get_user_profile(current_user["email"])
        if not profile:
            # Return basic user info if no full profile exists
            profile = {
                "id": current_user["email"],
                "email": current_user["email"],
                "username": current_user.get("username", current_user["email"].split("@")[0]),
                "tier": current_user.get("tier", "free"),
                "fitness_level": "beginner",
                "fitness_goals": ["general_fitness"],
                "available_equipment": ["none"]
            }

        return func.HttpResponse(
            json.dumps(profile),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error getting current user: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json"
        )

@app.route(route="users/profile", methods=["GET", "PUT"], auth_level=func.AuthLevel.ANONYMOUS)
async def user_profile(req: func.HttpRequest) -> func.HttpResponse:
    """Get or update user profile"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json"
            )

        if req.method == "GET":
            profile = await cosmos_db.get_user_profile(current_user["email"])
            return func.HttpResponse(
                json.dumps(profile),
                status_code=200,
                mimetype="application/json"
            )

        elif req.method == "PUT":
            # Rate limiting
            if not await rate_limiter.check_rate_limit(
                key=f"profile_update:{current_user['email']}",
                limit=10,
                window=3600  # 10 updates per hour
            ):
                return func.HttpResponse(
                    json.dumps({"error": "Rate limit exceeded"}),
                    status_code=429,
                    mimetype="application/json"
                )

            profile_data = req.get_json()
            updated_profile = await cosmos_db.update_user_profile(
                current_user["email"],
                profile_data
            )

            return func.HttpResponse(
                json.dumps(updated_profile),
                status_code=200,
                mimetype="application/json"
            )

    except Exception as e:
        logger.error(f"Error in user profile: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json"
        )

# =============================================================================
# AI-POWERED WORKOUT GENERATION
# =============================================================================

@app.route(route="workouts/generate", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def generate_workout(req: func.HttpRequest) -> func.HttpResponse:
    """Generate personalized workout using OpenAI gpt-4o-mini"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json"
            )

        # Rate limiting - 50 workout generations per day
        if not await rate_limiter.check_rate_limit(
            key=f"workout_gen:{current_user['email']}",
            limit=50,
            window=86400  # 24 hours
        ):
            return func.HttpResponse(
                json.dumps({"error": "Rate limit exceeded. Please try again later."}),
                status_code=429,
                mimetype="application/json"
            )

        workout_request = req.get_json()

        # Validate budget before AI operation
        budget_check = await validate_ai_budget(current_user["email"])
        if not budget_check["approved"]:
            return func.HttpResponse(
                json.dumps({
                    "error": "AI budget exceeded",
                    "details": budget_check["reason"]
                }),
                status_code=429,
                mimetype="application/json"
            )

        # Get user profile for context
        user_profile = await cosmos_db.get_user_profile(current_user["email"])

        # Generate workout with OpenAI
        workout = await ai_client.generate_workout(
            user_profile=user_profile,
            preferences=workout_request
        )

        # Store in Cosmos DB
        saved_workout = await cosmos_db.create_workout(
            user_id=current_user["email"],
            workout_data=workout
        )

        return func.HttpResponse(
            json.dumps(saved_workout),
            status_code=201,
            mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error generating workout: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to generate workout"}),
            status_code=500,
            mimetype="application/json"
        )

# =============================================================================
# AI COACH CHAT
# =============================================================================

@app.route(route="coach/chat", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def coach_chat(req: func.HttpRequest) -> func.HttpResponse:
    """Chat with AI coach using OpenAI gpt-4o-mini"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json"
            )

        # Rate limiting - 50 chat messages per day
        if not await rate_limiter.check_rate_limit(
            key=f"coach_chat:{current_user['email']}",
            limit=50,
            window=86400  # 24 hours
        ):
            return func.HttpResponse(
                json.dumps({"error": "Rate limit exceeded"}),
                status_code=429,
                mimetype="application/json"
            )

        message_data = req.get_json()

        # Validate budget
        budget_check = await validate_ai_budget(current_user["email"])
        if not budget_check["approved"]:
            return func.HttpResponse(
                json.dumps({"error": "AI budget exceeded"}),
                status_code=429,
                mimetype="application/json"
            )

        # Get conversation history from Cosmos DB
        conversation_history = await cosmos_db.get_conversation_history(
            current_user["email"],
            limit=10
        )

        # Get user context
        user_profile = await cosmos_db.get_user_profile(current_user["email"])

        # Generate response with OpenAI
        ai_response = await ai_client.coach_chat(
            message=message_data["message"],
            history=conversation_history,
            user_context=user_profile
        )

        # Save both messages to Cosmos DB
        await cosmos_db.save_chat_messages([
            {
                "role": "user",
                "content": message_data["message"],
                "userId": current_user["email"],
                "createdAt": datetime.utcnow().isoformat()
            },
            {
                "role": "assistant",
                "content": ai_response,
                "userId": current_user["email"],
                "providerUsed": "gpt-4o-mini",
                "createdAt": datetime.utcnow().isoformat()
            }
        ])

        return func.HttpResponse(
            json.dumps({"response": ai_response}),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error in coach chat: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to process chat message"}),
            status_code=500,
            mimetype="application/json"
        )


@app.route(route="coach/history", methods=["GET", "DELETE"], auth_level=func.AuthLevel.ANONYMOUS)
async def coach_history(req: func.HttpRequest) -> func.HttpResponse:
    """Get or clear coach conversation history"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json"
            )

        if req.method == "GET":
            limit = int(req.params.get("limit", 50))
            history = await cosmos_db.get_conversation_history(
                current_user["email"],
                limit=limit
            )
            return func.HttpResponse(
                json.dumps(history),
                status_code=200,
                mimetype="application/json"
            )

        elif req.method == "DELETE":
            await cosmos_db.clear_conversation_history(current_user["email"])
            return func.HttpResponse(
                json.dumps({"message": "Conversation history cleared"}),
                status_code=200,
                mimetype="application/json"
            )

    except Exception as e:
        logger.error(f"Error in coach history: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to process history request"}),
            status_code=500,
            mimetype="application/json"
        )


# =============================================================================
# WORKOUT MANAGEMENT
# =============================================================================

@app.route(route="workouts", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def get_user_workouts(req: func.HttpRequest) -> func.HttpResponse:
    """Get user's workout collection"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json"
            )

        # Get query parameters
        limit = int(req.params.get("limit", 20))
        offset = int(req.params.get("offset", 0))

        workouts = await cosmos_db.get_user_workouts(
            user_id=current_user["email"],
            limit=limit,
            offset=offset
        )

        return func.HttpResponse(
            json.dumps(workouts),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error getting workouts: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to retrieve workouts"}),
            status_code=500,
            mimetype="application/json"
        )

@app.route(route="workouts/{workout_id}", methods=["GET", "DELETE"], auth_level=func.AuthLevel.ANONYMOUS)
async def workout_detail(req: func.HttpRequest) -> func.HttpResponse:
    """Get or delete specific workout"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json"
            )

        workout_id = req.route_params.get("workout_id")

        if req.method == "GET":
            workout = await cosmos_db.get_workout(workout_id, current_user["email"])
            if not workout:
                return func.HttpResponse(
                    json.dumps({"error": "Workout not found"}),
                    status_code=404,
                    mimetype="application/json"
                )

            return func.HttpResponse(
                json.dumps(workout),
                status_code=200,
                mimetype="application/json"
            )

        elif req.method == "DELETE":
            success = await cosmos_db.delete_workout(workout_id, current_user["email"])
            if not success:
                return func.HttpResponse(
                    json.dumps({"error": "Workout not found"}),
                    status_code=404,
                    mimetype="application/json"
                )

            return func.HttpResponse(status_code=204)

    except Exception as e:
        logger.error(f"Error in workout detail: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json"
        )

# =============================================================================
# WORKOUT SESSION LOGGING
# =============================================================================

@app.route(route="workouts/{workout_id}/sessions", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def log_workout_session(req: func.HttpRequest) -> func.HttpResponse:
    """Log completed workout session"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json"
            )

        workout_id = req.route_params.get("workout_id")
        session_data = req.get_json()

        workout_log = await cosmos_db.create_workout_log(
            user_id=current_user["email"],
            workout_id=workout_id,
            session_data=session_data
        )

        return func.HttpResponse(
            json.dumps(workout_log),
            status_code=201,
            mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error logging workout session: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to log workout session"}),
            status_code=500,
            mimetype="application/json"
        )


@app.route(route="workouts/history", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def get_workout_history(req: func.HttpRequest) -> func.HttpResponse:
    """Get user's workout log history"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json"
            )

        limit = int(req.params.get("limit", 50))
        logs = await cosmos_db.get_user_workout_logs(
            user_id=current_user["email"],
            limit=limit
        )

        return func.HttpResponse(
            json.dumps(logs),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error getting workout history: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to retrieve workout history"}),
            status_code=500,
            mimetype="application/json"
        )


# =============================================================================
# ADMIN ENDPOINTS
# =============================================================================

@app.route(route="admin/ai/cost-metrics", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def get_cost_metrics(req: func.HttpRequest) -> func.HttpResponse:
    """Get AI cost metrics (admin only)"""
    try:
        admin_user = await require_admin_user(req)
        if not admin_user:
            return func.HttpResponse(
                json.dumps({"error": "Admin access required"}),
                status_code=403,
                mimetype="application/json"
            )

        # Query Cosmos DB for cost metrics
        cost_metrics = await cosmos_db.get_ai_cost_metrics()

        return func.HttpResponse(
            json.dumps({
                "daily_spend": cost_metrics.get("daily_spend", 0),
                "monthly_budget": 50.0,  # Fixed budget for OpenAI gpt-4o-mini
                "budget_utilization": cost_metrics.get("budget_utilization", 0),
                "provider_breakdown": {"gpt-4o-mini": cost_metrics.get("total_spend", 0)},
                "total_requests_today": cost_metrics.get("requests_today", 0)
            }),
            status_code=200,
            mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error getting cost metrics: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to retrieve cost metrics"}),
            status_code=500,
            mimetype="application/json"
        )

# =============================================================================
# BUDGET VALIDATION & TIMER FUNCTIONS
# =============================================================================

async def validate_ai_budget(user_id: str) -> Dict[str, Any]:
    """Validate AI budget before operation"""
    try:
        current_spend = await cosmos_db.get_daily_ai_spend()
        monthly_budget = float(settings.AI_MONTHLY_BUDGET)
        daily_budget = monthly_budget / 30  # Approximate daily budget

        if current_spend >= daily_budget * 0.9:  # 90% threshold
            return {
                "approved": False,
                "reason": "Daily AI budget nearly exceeded",
                "current_spend": current_spend,
                "daily_budget": daily_budget
            }

        return {
            "approved": True,
            "remaining_budget": daily_budget - current_spend
        }

    except Exception as e:
        logger.error(f"Error validating budget: {str(e)}")
        return {"approved": False, "reason": "Budget validation failed"}

# Timer trigger for budget monitoring - runs hourly in production
# Note: Requires Azure Storage for local development (Azurite emulator)
@app.timer_trigger(schedule="0 0 * * * *", arg_name="timer", run_on_startup=False)
async def budget_monitoring_timer(timer: func.TimerRequest) -> None:
    """Hourly budget monitoring and alerting"""
    try:
        logger.info("Running budget monitoring check...")

        current_spend = await cosmos_db.get_daily_ai_spend()
        daily_threshold = float(settings.AI_COST_THRESHOLD)

        if current_spend > daily_threshold:
            logger.warning(f"AI spend threshold exceeded: ${current_spend}")
            # Here you could add alerting logic (email, Slack, etc.)

    except Exception as e:
        logger.error(f"Error in budget monitoring: {str(e)}")

# =============================================================================
# HEALTH CHECK
# =============================================================================

@app.route(route="health", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint"""
    try:
        # Check Cosmos DB connection
        cosmos_health = await cosmos_db.health_check()

        # Check OpenAI API
        ai_health = ai_client.is_available()

        health_status = {
            "status": "healthy" if cosmos_health and ai_health else "unhealthy",
            "timestamp": datetime.utcnow().isoformat(),
            "services": {
                "cosmos_db": "healthy" if cosmos_health else "unhealthy",
                "azure_openai": "healthy" if ai_health else "unhealthy"
            },
            "version": "2.0.0"
        }

        status_code = 200 if cosmos_health and ai_health else 503

        return func.HttpResponse(
            json.dumps(health_status),
            status_code=status_code,
            mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return func.HttpResponse(
            json.dumps({
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }),
            status_code=503,
            mimetype="application/json"
        )


# SIMPLE HEALTH CHECK - No external dependencies
@app.route(route="health-simple", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def health_simple(req: func.HttpRequest) -> func.HttpResponse:
    """Simple health check without external dependencies"""
    try:
        return func.HttpResponse(
            json.dumps({
                "status": "healthy",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "message": "Function App is running",
                "version": "1.0.0-modernized-auth"
            }),
            status_code=200,
            mimetype="application/json"
        )
    except Exception as e:
        return func.HttpResponse(
            json.dumps({"status": "error", "error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )

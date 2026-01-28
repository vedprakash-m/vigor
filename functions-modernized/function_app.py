"""
Vigor Backend - Azure Functions App
Single resource group (vigor-rg), Cosmos DB Serverless, Azure OpenAI gpt-5-mini
Production domain: vigor.vedprakash.net
"""

import json
import logging
from datetime import datetime, timezone
from typing import Any, Dict

import azure.functions as func

# Import shared modules
from shared.auth import get_current_user_from_token, require_admin_user
from shared.config import get_settings
from shared.cosmos_db import CosmosDBClient
from shared.openai_client import OpenAIClient
from shared.rate_limiter import RateLimiter

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
                json.dumps(
                    {"error": "Unauthorized - Valid Microsoft Entra ID token required"}
                ),
                status_code=401,
                mimetype="application/json",
            )

        # Get full profile from Cosmos DB using email as key
        profile = await cosmos_db.get_user_profile(current_user["email"])
        if not profile:
            # Return basic user info if no full profile exists
            profile = {
                "id": current_user["email"],
                "email": current_user["email"],
                "username": current_user.get(
                    "username", current_user["email"].split("@")[0]
                ),
                "tier": current_user.get("tier", "free"),
                "fitness_level": "beginner",
                "fitness_goals": ["general_fitness"],
                "available_equipment": ["none"],
            }

        return func.HttpResponse(
            json.dumps(profile), status_code=200, mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error getting current user: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json",
        )


@app.route(
    route="users/profile", methods=["GET", "PUT"], auth_level=func.AuthLevel.ANONYMOUS
)
async def user_profile(req: func.HttpRequest) -> func.HttpResponse:
    """Get or update user profile"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        if req.method == "GET":
            profile = await cosmos_db.get_user_profile(current_user["email"])
            return func.HttpResponse(
                json.dumps(profile), status_code=200, mimetype="application/json"
            )

        elif req.method == "PUT":
            # Rate limiting
            if not await rate_limiter.check_rate_limit(
                key=f"profile_update:{current_user['email']}",
                limit=10,
                window=3600,  # 10 updates per hour
            ):
                return func.HttpResponse(
                    json.dumps({"error": "Rate limit exceeded"}),
                    status_code=429,
                    mimetype="application/json",
                )

            profile_data = req.get_json()
            updated_profile = await cosmos_db.update_user_profile(
                current_user["email"], profile_data
            )

            return func.HttpResponse(
                json.dumps(updated_profile),
                status_code=200,
                mimetype="application/json",
            )

    except Exception as e:
        logger.error(f"Error in user profile: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json",
        )


# =============================================================================
# AI-POWERED WORKOUT GENERATION
# =============================================================================


@app.route(
    route="workouts/generate", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def generate_workout(req: func.HttpRequest) -> func.HttpResponse:
    """Generate personalized workout using OpenAI gpt-5-mini"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        # Rate limiting - 50 workout generations per day
        if not await rate_limiter.check_rate_limit(
            key=f"workout_gen:{current_user['email']}",
            limit=50,
            window=86400,  # 24 hours
        ):
            return func.HttpResponse(
                json.dumps({"error": "Rate limit exceeded. Please try again later."}),
                status_code=429,
                mimetype="application/json",
            )

        workout_request = req.get_json()

        # Validate budget before AI operation
        budget_check = await validate_ai_budget(current_user["email"])
        if not budget_check["approved"]:
            return func.HttpResponse(
                json.dumps(
                    {"error": "AI budget exceeded", "details": budget_check["reason"]}
                ),
                status_code=429,
                mimetype="application/json",
            )

        # Get user profile for context
        user_profile = await cosmos_db.get_user_profile(current_user["email"])

        # Use default profile if not found
        if not user_profile:
            user_profile = {
                "email": current_user["email"],
                "fitness_level": "beginner",
                "fitness_goals": ["general_fitness"],
                "available_equipment": ["bodyweight"],
            }

        # Generate workout with OpenAI
        workout = await ai_client.generate_workout(
            user_profile=user_profile, preferences=workout_request
        )

        # Store in Cosmos DB
        saved_workout = await cosmos_db.create_workout(
            user_id=current_user["email"], workout_data=workout
        )

        return func.HttpResponse(
            json.dumps(saved_workout), status_code=201, mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error generating workout: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to generate workout"}),
            status_code=500,
            mimetype="application/json",
        )


# =============================================================================
# AI COACH CHAT
# =============================================================================


@app.route(route="coach/chat", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def coach_chat(req: func.HttpRequest) -> func.HttpResponse:
    """Chat with AI coach using OpenAI gpt-5-mini"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        # Rate limiting - 50 chat messages per day
        if not await rate_limiter.check_rate_limit(
            key=f"coach_chat:{current_user['email']}",
            limit=50,
            window=86400,  # 24 hours
        ):
            return func.HttpResponse(
                json.dumps({"error": "Rate limit exceeded"}),
                status_code=429,
                mimetype="application/json",
            )

        message_data = req.get_json()

        # Validate budget
        budget_check = await validate_ai_budget(current_user["email"])
        if not budget_check["approved"]:
            return func.HttpResponse(
                json.dumps({"error": "AI budget exceeded"}),
                status_code=429,
                mimetype="application/json",
            )

        # Get conversation history from Cosmos DB
        conversation_history = await cosmos_db.get_conversation_history(
            current_user["email"], limit=10
        )

        # Get user context
        user_profile = await cosmos_db.get_user_profile(current_user["email"])

        # Generate response with OpenAI
        ai_response = await ai_client.coach_chat(
            message=message_data["message"],
            history=conversation_history,
            user_context=user_profile,
        )

        # Save both messages to Cosmos DB
        await cosmos_db.save_chat_messages(
            [
                {
                    "role": "user",
                    "content": message_data["message"],
                    "userId": current_user["email"],
                    "createdAt": datetime.utcnow().isoformat(),
                },
                {
                    "role": "assistant",
                    "content": ai_response,
                    "userId": current_user["email"],
                    "providerUsed": "gpt-5-mini",
                    "createdAt": datetime.utcnow().isoformat(),
                },
            ]
        )

        return func.HttpResponse(
            json.dumps({"response": ai_response}),
            status_code=200,
            mimetype="application/json",
        )

    except Exception as e:
        logger.error(f"Error in coach chat: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to process chat message"}),
            status_code=500,
            mimetype="application/json",
        )


@app.route(
    route="coach/history",
    methods=["GET", "DELETE"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def coach_history(req: func.HttpRequest) -> func.HttpResponse:
    """Get or clear coach conversation history"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        if req.method == "GET":
            limit = int(req.params.get("limit", 50))
            history = await cosmos_db.get_conversation_history(
                current_user["email"], limit=limit
            )
            return func.HttpResponse(
                json.dumps(history), status_code=200, mimetype="application/json"
            )

        elif req.method == "DELETE":
            await cosmos_db.clear_conversation_history(current_user["email"])
            return func.HttpResponse(
                json.dumps({"message": "Conversation history cleared"}),
                status_code=200,
                mimetype="application/json",
            )

    except Exception as e:
        logger.error(f"Error in coach history: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to process history request"}),
            status_code=500,
            mimetype="application/json",
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
                mimetype="application/json",
            )

        # Get query parameters
        limit = int(req.params.get("limit", 20))
        offset = int(req.params.get("offset", 0))

        workouts = await cosmos_db.get_user_workouts(
            user_id=current_user["email"], limit=limit, offset=offset
        )

        return func.HttpResponse(
            json.dumps(workouts), status_code=200, mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error getting workouts: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to retrieve workouts"}),
            status_code=500,
            mimetype="application/json",
        )


@app.route(
    route="workouts/{workout_id}",
    methods=["GET", "DELETE"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def workout_detail(req: func.HttpRequest) -> func.HttpResponse:
    """Get or delete specific workout"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        workout_id = req.route_params.get("workout_id")

        if req.method == "GET":
            workout = await cosmos_db.get_workout(workout_id, current_user["email"])
            if not workout:
                return func.HttpResponse(
                    json.dumps({"error": "Workout not found"}),
                    status_code=404,
                    mimetype="application/json",
                )

            return func.HttpResponse(
                json.dumps(workout), status_code=200, mimetype="application/json"
            )

        elif req.method == "DELETE":
            success = await cosmos_db.delete_workout(workout_id, current_user["email"])
            if not success:
                return func.HttpResponse(
                    json.dumps({"error": "Workout not found"}),
                    status_code=404,
                    mimetype="application/json",
                )

            return func.HttpResponse(status_code=204)

    except Exception as e:
        logger.error(f"Error in workout detail: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json",
        )


# =============================================================================
# WORKOUT SESSION LOGGING
# =============================================================================


@app.route(
    route="workouts/{workout_id}/sessions",
    methods=["POST"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def log_workout_session(req: func.HttpRequest) -> func.HttpResponse:
    """Log completed workout session"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        workout_id = req.route_params.get("workout_id")
        session_data = req.get_json()

        workout_log = await cosmos_db.create_workout_log(
            user_id=current_user["email"],
            workout_id=workout_id,
            session_data=session_data,
        )

        return func.HttpResponse(
            json.dumps(workout_log), status_code=201, mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error logging workout session: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to log workout session"}),
            status_code=500,
            mimetype="application/json",
        )


@app.route(
    route="workouts/history", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS
)
async def get_workout_history(req: func.HttpRequest) -> func.HttpResponse:
    """Get user's workout log history"""
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        limit = int(req.params.get("limit", 50))
        logs = await cosmos_db.get_user_workout_logs(
            user_id=current_user["email"], limit=limit
        )

        return func.HttpResponse(
            json.dumps(logs), status_code=200, mimetype="application/json"
        )

    except Exception as e:
        logger.error(f"Error getting workout history: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to retrieve workout history"}),
            status_code=500,
            mimetype="application/json",
        )


# =============================================================================
# ADMIN ENDPOINTS
# =============================================================================


@app.route(
    route="admin/ai/cost-metrics", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS
)
async def get_cost_metrics(req: func.HttpRequest) -> func.HttpResponse:
    """Get AI cost metrics (admin only)"""
    try:
        admin_user = await require_admin_user(req)
        if not admin_user:
            return func.HttpResponse(
                json.dumps({"error": "Admin access required"}),
                status_code=403,
                mimetype="application/json",
            )

        # Query Cosmos DB for cost metrics
        cost_metrics = await cosmos_db.get_ai_cost_metrics()

        return func.HttpResponse(
            json.dumps(
                {
                    "daily_spend": cost_metrics.get("daily_spend", 0),
                    "monthly_budget": 50.0,  # Fixed budget for OpenAI gpt-5-mini
                    "budget_utilization": cost_metrics.get("budget_utilization", 0),
                    "provider_breakdown": {
                        "gpt-5-mini": cost_metrics.get("total_spend", 0)
                    },
                    "total_requests_today": cost_metrics.get("requests_today", 0),
                }
            ),
            status_code=200,
            mimetype="application/json",
        )

    except Exception as e:
        logger.error(f"Error getting cost metrics: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to retrieve cost metrics"}),
            status_code=500,
            mimetype="application/json",
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
                "daily_budget": daily_budget,
            }

        return {"approved": True, "remaining_budget": daily_budget - current_spend}

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
# GHOST API - iOS App Native Endpoints (P0 for Platform Survival)
# =============================================================================


@app.route(route="ghost/silent-push", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def ghost_silent_push(req: func.HttpRequest) -> func.HttpResponse:
    """
    Silent Push Trigger - P0 for Ghost survival
    Called by Timer Function at 5:55 AM user-local-time to wake iOS app
    Per PRD §3.4: "If not implemented as P0, Ghost dies after 3 days of non-use"
    """
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        # Get user's pending actions from Phenome
        user_id = current_user["email"]
        pending_actions = await cosmos_db.get_pending_ghost_actions(user_id)

        # Build silent push payload
        push_payload = {
            "user_id": user_id,
            "trigger_type": "morning_cycle",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "actions": pending_actions or [],
            "priority": "high"
        }

        # Note: Actual APNs push is handled by separate APNs integration
        # This endpoint prepares the payload and queues the push
        await cosmos_db.queue_silent_push(user_id, push_payload)

        return func.HttpResponse(
            json.dumps({
                "status": "queued",
                "actions_count": len(pending_actions or []),
                "timestamp": datetime.now(timezone.utc).isoformat()
            }),
            status_code=200,
            mimetype="application/json",
        )

    except Exception as e:
        logger.error(f"Ghost silent push error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json",
        )


@app.route(route="ghost/trust", methods=["GET", "POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def ghost_trust(req: func.HttpRequest) -> func.HttpResponse:
    """
    Trust State API - Sync trust phase between device and server
    Per PRD §2.2.2: 5-phase state machine with Safety Breaker
    """
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        user_id = current_user["email"]

        if req.method == "GET":
            # Get current trust state
            trust_state = await cosmos_db.get_trust_state(user_id)
            if not trust_state:
                trust_state = {
                    "user_id": user_id,
                    "phase": "observer",
                    "confidence": 0.0,
                    "consecutive_deletes": 0,
                    "last_updated": datetime.now(timezone.utc).isoformat()
                }
            return func.HttpResponse(
                json.dumps(trust_state),
                status_code=200,
                mimetype="application/json",
            )

        elif req.method == "POST":
            # Record trust event
            event_data = req.get_json()

            # Validate event structure
            required_fields = ["event_type", "timestamp"]
            if not all(field in event_data for field in required_fields):
                return func.HttpResponse(
                    json.dumps({"error": "Missing required fields: event_type, timestamp"}),
                    status_code=400,
                    mimetype="application/json",
                )

            # Store event and update trust state
            updated_state = await cosmos_db.record_trust_event(user_id, event_data)

            return func.HttpResponse(
                json.dumps(updated_state),
                status_code=200,
                mimetype="application/json",
            )

    except Exception as e:
        logger.error(f"Ghost trust API error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json",
        )


@app.route(route="ghost/schedule", methods=["GET", "POST", "PUT"], auth_level=func.AuthLevel.ANONYMOUS)
async def ghost_schedule(req: func.HttpRequest) -> func.HttpResponse:
    """
    Schedule Sync API - Bidirectional sync of training blocks
    Per PRD §3.1: Calendar-centric UX with training blocks as events
    """
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        user_id = current_user["email"]

        if req.method == "GET":
            # Get scheduled blocks
            week_offset = int(req.params.get("week_offset", 0))
            blocks = await cosmos_db.get_training_blocks(user_id, week_offset)
            return func.HttpResponse(
                json.dumps({"blocks": blocks, "week_offset": week_offset}),
                status_code=200,
                mimetype="application/json",
            )

        elif req.method == "POST":
            # Create new training block
            block_data = req.get_json()

            # Validate block structure
            required_fields = ["start_time", "duration_minutes", "workout_type"]
            if not all(field in block_data for field in required_fields):
                return func.HttpResponse(
                    json.dumps({"error": f"Missing required fields: {required_fields}"}),
                    status_code=400,
                    mimetype="application/json",
                )

            created_block = await cosmos_db.create_training_block(user_id, block_data)
            return func.HttpResponse(
                json.dumps(created_block),
                status_code=201,
                mimetype="application/json",
            )

        elif req.method == "PUT":
            # Update training block (reschedule/modify)
            block_data = req.get_json()

            if "block_id" not in block_data:
                return func.HttpResponse(
                    json.dumps({"error": "block_id required for update"}),
                    status_code=400,
                    mimetype="application/json",
                )

            updated_block = await cosmos_db.update_training_block(
                user_id,
                block_data["block_id"],
                block_data
            )
            return func.HttpResponse(
                json.dumps(updated_block),
                status_code=200,
                mimetype="application/json",
            )

    except Exception as e:
        logger.error(f"Ghost schedule API error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json",
        )


@app.route(route="ghost/phenome/sync", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def ghost_phenome_sync(req: func.HttpRequest) -> func.HttpResponse:
    """
    Phenome Sync API - Bi-directional sync of user's Phenome data
    Per Tech Spec §2.3: 3-store architecture (RawSignal, DerivedState, BehavioralMemory)
    """
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        user_id = current_user["email"]
        sync_data = req.get_json()

        # Validate sync payload
        if not sync_data or "store_type" not in sync_data:
            return func.HttpResponse(
                json.dumps({"error": "store_type required (raw_signal|derived_state|behavioral_memory)"}),
                status_code=400,
                mimetype="application/json",
            )

        store_type = sync_data["store_type"]
        client_version = sync_data.get("version", 0)
        client_data = sync_data.get("data", {})

        # Get server version
        server_data = await cosmos_db.get_phenome_store(user_id, store_type)
        server_version = server_data.get("version", 0) if server_data else 0

        if client_version > server_version:
            # Client has newer data - update server
            await cosmos_db.update_phenome_store(user_id, store_type, client_data, client_version)
            return func.HttpResponse(
                json.dumps({
                    "status": "updated",
                    "version": client_version,
                    "conflicts": []
                }),
                status_code=200,
                mimetype="application/json",
            )
        elif server_version > client_version:
            # Server has newer data - send to client
            return func.HttpResponse(
                json.dumps({
                    "status": "outdated",
                    "version": server_version,
                    "data": server_data.get("data", {}),
                    "conflicts": []
                }),
                status_code=200,
                mimetype="application/json",
            )
        else:
            # Versions match - no sync needed
            return func.HttpResponse(
                json.dumps({
                    "status": "synced",
                    "version": server_version,
                    "conflicts": []
                }),
                status_code=200,
                mimetype="application/json",
            )

    except Exception as e:
        logger.error(f"Ghost phenome sync error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json",
        )


@app.route(route="ghost/decision-receipt", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def ghost_decision_receipt(req: func.HttpRequest) -> func.HttpResponse:
    """
    Decision Receipt API - Store forensic log of Ghost decisions
    Per PRD §4.2: "Why did my score change?" explainability
    """
    try:
        current_user = await get_current_user_from_token(req)
        if not current_user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json",
            )

        user_id = current_user["email"]
        receipt_data = req.get_json()

        # Validate receipt structure
        required_fields = ["decision_type", "inputs", "output", "explanation", "timestamp"]
        if not all(field in receipt_data for field in required_fields):
            return func.HttpResponse(
                json.dumps({"error": f"Missing required fields: {required_fields}"}),
                status_code=400,
                mimetype="application/json",
            )

        # Store with 90-day TTL
        stored_receipt = await cosmos_db.store_decision_receipt(user_id, receipt_data)

        return func.HttpResponse(
            json.dumps(stored_receipt),
            status_code=201,
            mimetype="application/json",
        )

    except Exception as e:
        logger.error(f"Ghost decision receipt error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json",
        )


# =============================================================================
# GHOST TIMER FUNCTIONS (Silent Push Triggers)
# =============================================================================


@app.timer_trigger(schedule="0 55 5 * * *", arg_name="timer", run_on_startup=False)
async def ghost_morning_wake_trigger(timer: func.TimerRequest) -> None:
    """
    Timer trigger for morning Ghost wake cycle (5:55 AM UTC)
    Per PRD §3.4: Silent push to wake iOS app for morning cycle

    Note: This runs at 5:55 AM UTC. For user-local-time triggers,
    each user's timezone must be tracked and individual pushes scheduled.
    """
    try:
        logger.info("Ghost morning wake trigger fired")

        # Get all active users with their timezones
        active_users = await cosmos_db.get_active_users_for_morning_push()

        for user in active_users:
            try:
                # Queue silent push for each user
                push_payload = {
                    "user_id": user["id"],
                    "trigger_type": "morning_cycle",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "actions": ["run_morning_cycle", "check_schedule", "update_recovery"],
                    "priority": "high"
                }
                await cosmos_db.queue_silent_push(user["id"], push_payload)
                logger.info(f"Queued morning push for user {user['id']}")
            except Exception as user_error:
                logger.error(f"Error queueing push for user {user['id']}: {user_error}")

    except Exception as e:
        logger.error(f"Ghost morning wake trigger error: {str(e)}")


@app.timer_trigger(schedule="0 0 21 * * 0", arg_name="timer", run_on_startup=False)
async def ghost_sunday_evening_trigger(timer: func.TimerRequest) -> None:
    """
    Timer trigger for Sunday evening week planning (9 PM UTC Sunday)
    Per PRD §3.2: Weekly structure, not daily nagging
    """
    try:
        logger.info("Ghost Sunday evening trigger fired")

        # Get users due for weekly planning
        users_for_planning = await cosmos_db.get_users_for_weekly_planning()

        for user in users_for_planning:
            try:
                push_payload = {
                    "user_id": user["id"],
                    "trigger_type": "weekly_planning",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "actions": ["propose_week_schedule", "show_value_receipt"],
                    "priority": "normal"
                }
                await cosmos_db.queue_silent_push(user["id"], push_payload)
                logger.info(f"Queued weekly planning push for user {user['id']}")
            except Exception as user_error:
                logger.error(f"Error queueing weekly push for user {user['id']}: {user_error}")

    except Exception as e:
        logger.error(f"Ghost Sunday evening trigger error: {str(e)}")


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
                "azure_openai": "healthy" if ai_health else "unhealthy",
            },
            "version": "3.0.0-ghost",
        }

        status_code = 200 if cosmos_health and ai_health else 503

        return func.HttpResponse(
            json.dumps(health_status),
            status_code=status_code,
            mimetype="application/json",
        )

    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return func.HttpResponse(
            json.dumps(
                {
                    "status": "unhealthy",
                    "error": str(e),
                    "timestamp": datetime.utcnow().isoformat(),
                }
            ),
            status_code=503,
            mimetype="application/json",
        )


# SIMPLE HEALTH CHECK - No external dependencies
@app.route(route="health-simple", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def health_simple(req: func.HttpRequest) -> func.HttpResponse:
    """Simple health check without external dependencies"""
    try:
        return func.HttpResponse(
            json.dumps(
                {
                    "status": "healthy",
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "message": "Function App is running",
                    "version": "3.0.0-ghost",
                }
            ),
            status_code=200,
            mimetype="application/json",
        )
    except Exception as e:
        return func.HttpResponse(
            json.dumps({"status": "error", "error": str(e)}),
            status_code=500,
            mimetype="application/json",
        )

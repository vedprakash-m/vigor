"""
Cosmos DB client for Vigor Functions
Handles all database operations with Cosmos DB Serverless NoSQL schema
"""

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import uuid4

from azure.cosmos.aio import ContainerProxy, CosmosClient, DatabaseProxy
from azure.cosmos.exceptions import CosmosHttpResponseError

from .config import get_settings

logger = logging.getLogger(__name__)


class CosmosDBClient:
    """Cosmos DB client for Vigor application"""

    def __init__(self):
        self.settings = get_settings()
        self.client: Optional[CosmosClient] = None
        self.database: Optional[DatabaseProxy] = None
        self.containers: Dict[str, ContainerProxy] = {}

    async def initialize(self):
        """Initialize Cosmos DB client and containers"""
        try:
            endpoint = self.settings.cosmos_endpoint
            key = self.settings.cosmos_key
            database = self.settings.cosmos_database

            if not endpoint or not key:
                raise ValueError(
                    f"Cosmos DB credentials not configured. Endpoint: {bool(endpoint)}, Key: {bool(key)}"
                )

            logger.info(f"Initializing Cosmos DB client for database: {database}")

            self.client = CosmosClient(url=endpoint, credential=key)

            self.database = self.client.get_database_client(database)

            # Initialize container references
            self.containers = {
                "users": self.database.get_container_client("users"),
                "workouts": self.database.get_container_client("workouts"),
                "workout_logs": self.database.get_container_client("workout_logs"),
                "ai_coach_messages": self.database.get_container_client(
                    "ai_coach_messages"
                ),
            }

            logger.info("Cosmos DB client initialized successfully")

        except Exception as e:
            logger.error(f"Failed to initialize Cosmos DB client: {str(e)}")
            raise

    async def ensure_initialized(self):
        """Ensure client is initialized"""
        if self.client is None:
            await self.initialize()

    # =============================================================================
    # USER OPERATIONS
    # =============================================================================

    async def get_user_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user profile by user ID (email)"""
        await self.ensure_initialized()

        try:
            container = self.containers["users"]

            # Query by email since id and partition key may not match
            query = "SELECT * FROM c WHERE c.email = @email OR c.id = @email"
            parameters = [{"name": "@email", "value": user_id}]

            result = []
            async for item in container.query_items(
                query=query,
                parameters=parameters,
            ):
                result.append(item)

            if result:
                return result[0]
            return None

        except CosmosHttpResponseError as e:
            if e.status_code == 404:
                return None
            logger.error(f"Error getting user profile: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error getting user profile: {str(e)}")
            raise

    async def create_user_profile(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create new user profile"""
        await self.ensure_initialized()

        try:
            user_id = user_data.get("userId", str(uuid4()))
            user_document = {
                "id": user_id,
                "userId": user_id,  # Partition key
                "email": user_data["email"],
                "username": user_data.get("username"),
                "profile": user_data.get(
                    "profile",
                    {
                        "fitnessLevel": "beginner",
                        "goals": [],
                        "equipment": "bodyweight",
                        "tier": "free",
                    },
                ),
                "preferences": user_data.get(
                    "preferences",
                    {"workoutDuration": 45, "restDays": [], "notifications": True},
                ),
                "createdAt": datetime.now(timezone.utc).isoformat(),
                "updatedAt": datetime.now(timezone.utc).isoformat(),
            }

            container = self.containers["users"]
            response = await container.create_item(body=user_document)
            return response

        except Exception as e:
            logger.error(f"Error creating user profile: {str(e)}")
            raise

    async def update_user_profile(
        self, user_id: str, update_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Update user profile"""
        await self.ensure_initialized()

        try:
            # Get existing profile
            existing_profile = await self.get_user_profile(user_id)
            if not existing_profile:
                raise ValueError(f"User profile not found: {user_id}")

            # Update fields
            existing_profile.update(update_data)
            existing_profile["updatedAt"] = datetime.now(timezone.utc).isoformat()

            container = self.containers["users"]
            response = await container.replace_item(item=user_id, body=existing_profile)
            return response

        except Exception as e:
            logger.error(f"Error updating user profile: {str(e)}")
            raise

    # =============================================================================
    # WORKOUT OPERATIONS
    # =============================================================================

    async def create_workout(
        self, user_id: str, workout_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Create new workout plan"""
        await self.ensure_initialized()

        try:
            workout_id = str(uuid4())
            workout_document = {
                "id": workout_id,
                "userId": user_id,  # Partition key
                "name": workout_data["name"],
                "description": workout_data.get("description"),
                "exercises": workout_data["exercises"],
                "metadata": {
                    "difficulty": workout_data.get("difficulty", "moderate"),
                    "estimatedDuration": workout_data.get("estimatedDuration", 45),
                    "equipmentNeeded": workout_data.get("equipmentNeeded", []),
                    "aiProviderUsed": "gpt-5-mini",
                    "tags": workout_data.get("tags", []),
                },
                "createdAt": datetime.now(timezone.utc).isoformat(),
            }

            container = self.containers["workouts"]
            response = await container.create_item(body=workout_document)
            return response

        except Exception as e:
            logger.error(f"Error creating workout: {str(e)}")
            raise

    async def get_user_workouts(
        self, user_id: str, limit: int = 20, offset: int = 0
    ) -> List[Dict[str, Any]]:
        """Get user's workout plans"""
        await self.ensure_initialized()

        try:
            container = self.containers["workouts"]

            query = """
                SELECT * FROM c
                WHERE c.userId = @user_id
                ORDER BY c.createdAt DESC
                OFFSET @offset LIMIT @limit
            """

            parameters = [
                {"name": "@user_id", "value": user_id},
                {"name": "@offset", "value": offset},
                {"name": "@limit", "value": limit},
            ]

            items = []
            async for item in container.query_items(
                query=query, parameters=parameters, partition_key=user_id
            ):
                items.append(item)

            return items

        except Exception as e:
            logger.error(f"Error getting user workouts: {str(e)}")
            raise

    async def get_workout(
        self, workout_id: str, user_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get specific workout by ID"""
        await self.ensure_initialized()

        try:
            container = self.containers["workouts"]
            response = await container.read_item(item=workout_id, partition_key=user_id)
            return response

        except Exception as e:
            if hasattr(e, "status_code") and e.status_code == 404:
                return None
            logger.error(f"Error getting workout: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error getting workout: {str(e)}")
            raise

    async def delete_workout(self, workout_id: str, user_id: str) -> bool:
        """Delete workout plan"""
        await self.ensure_initialized()

        try:
            container = self.containers["workouts"]
            await container.delete_item(item=workout_id, partition_key=user_id)
            return True

        except CosmosHttpResponseError as e:
            if e.status_code == 404:
                return False
            logger.error(f"Error deleting workout: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error deleting workout: {str(e)}")
            raise

    # =============================================================================
    # WORKOUT LOG OPERATIONS
    # =============================================================================

    async def create_workout_log(
        self, user_id: str, workout_id: Optional[str], session_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Create workout session log"""
        await self.ensure_initialized()

        try:
            log_id = str(uuid4())
            log_document = {
                "id": log_id,
                "userId": user_id,  # Partition key
                "workoutPlanId": workout_id,
                "exercisesCompleted": session_data["exercises"],
                "durationMinutes": session_data["durationMinutes"],
                "intensity": session_data.get("intensity", 5),
                "notes": session_data.get("notes"),
                "completedAt": datetime.now(timezone.utc).isoformat(),
            }

            container = self.containers["workout_logs"]
            response = await container.create_item(body=log_document)
            return response

        except Exception as e:
            logger.error(f"Error creating workout log: {str(e)}")
            raise

    async def get_user_workout_logs(
        self, user_id: str, limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Get user's workout session logs"""
        await self.ensure_initialized()

        try:
            container = self.containers["workout_logs"]

            query = """
                SELECT * FROM c
                WHERE c.userId = @user_id
                ORDER BY c.completedAt DESC
                OFFSET 0 LIMIT @limit
            """

            parameters = [
                {"name": "@user_id", "value": user_id},
                {"name": "@limit", "value": limit},
            ]

            items = []
            async for item in container.query_items(
                query=query, parameters=parameters, partition_key=user_id
            ):
                items.append(item)

            return items

        except Exception as e:
            logger.error(f"Error getting workout logs: {str(e)}")
            raise

    # =============================================================================
    # AI CHAT OPERATIONS
    # =============================================================================

    async def save_chat_messages(
        self, messages: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Save AI chat messages"""
        await self.ensure_initialized()

        try:
            container = self.containers["ai_coach_messages"]
            saved_messages = []

            for message in messages:
                message_id = str(uuid4())
                message_document = {
                    "id": message_id,
                    "userId": message["userId"],  # Partition key
                    "role": message["role"],
                    "content": message["content"],
                    "providerUsed": message.get("providerUsed", "gpt-5-mini"),
                    "tokensUsed": message.get("tokensUsed"),
                    "responseTimeMs": message.get("responseTimeMs"),
                    "createdAt": message.get(
                        "createdAt", datetime.now(timezone.utc).isoformat()
                    ),
                }

                response = await container.create_item(body=message_document)
                saved_messages.append(response)

            return saved_messages

        except Exception as e:
            logger.error(f"Error saving chat messages: {str(e)}")
            raise

    async def get_conversation_history(
        self, user_id: str, limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get recent conversation history"""
        await self.ensure_initialized()

        try:
            container = self.containers["ai_coach_messages"]

            query = """
                SELECT * FROM c
                WHERE c.userId = @user_id
                ORDER BY c.createdAt DESC
                OFFSET 0 LIMIT @limit
            """

            parameters = [
                {"name": "@user_id", "value": user_id},
                {"name": "@limit", "value": limit},
            ]

            items = []
            async for item in container.query_items(
                query=query, parameters=parameters, partition_key=user_id
            ):
                items.append(item)

            # Return in chronological order (oldest first)
            return list(reversed(items))

        except Exception as e:
            logger.error(f"Error getting conversation history: {str(e)}")
            raise

    async def clear_conversation_history(self, user_id: str) -> bool:
        """Clear all conversation history for a user"""
        await self.ensure_initialized()

        try:
            container = self.containers["ai_coach_messages"]

            # Query all messages for this user
            query = "SELECT c.id FROM c WHERE c.userId = @user_id"
            parameters = [{"name": "@user_id", "value": user_id}]

            # Delete each message
            async for item in container.query_items(
                query=query, parameters=parameters, partition_key=user_id
            ):
                await container.delete_item(item=item["id"], partition_key=user_id)

            logger.info(f"Cleared conversation history for user: {user_id}")
            return True

        except Exception as e:
            logger.error(f"Error clearing conversation history: {str(e)}")
            raise

    # =============================================================================
    # COST TRACKING & ANALYTICS
    # =============================================================================

    async def get_daily_ai_spend(self) -> float:
        """Get current daily AI spend across all users"""
        await self.ensure_initialized()

        try:
            today = datetime.now(timezone.utc).date().isoformat()

            container = self.containers["ai_coach_messages"]
            # Use VALUE for cross-partition aggregate queries
            query = """
                SELECT VALUE COUNT(1)
                FROM c
                WHERE STARTSWITH(c.createdAt, @today)
            """

            parameters = [{"name": "@today", "value": today}]

            result = []
            async for item in container.query_items(
                query=query,
                parameters=parameters,
            ):
                result.append(item)

            message_count = result[0] if result else 0

            # Estimate cost: $0.01 per message (rough estimate for OpenAI gpt-5-mini)
            estimated_cost = message_count * 0.01
            return estimated_cost

        except Exception as e:
            logger.error(f"Error getting daily AI spend: {str(e)}")
            return 0.0

    async def get_ai_cost_metrics(self) -> Dict[str, Any]:
        """Get comprehensive AI cost metrics"""
        await self.ensure_initialized()

        try:
            daily_spend = await self.get_daily_ai_spend()

            # Get message counts for today
            today = datetime.now(timezone.utc).date().isoformat()
            container = self.containers["ai_coach_messages"]

            # Use VALUE for cross-partition aggregate queries
            query = """
                SELECT VALUE COUNT(1)
                FROM c
                WHERE STARTSWITH(c.createdAt, @today)
            """

            parameters = [{"name": "@today", "value": today}]

            result = []
            async for item in container.query_items(
                query=query,
                parameters=parameters,
            ):
                result.append(item)

            requests_today = result[0] if result else 0

            return {
                "daily_spend": daily_spend,
                "total_spend": daily_spend,  # For now, same as daily
                "budget_utilization": (daily_spend / 1.67)
                * 100,  # $50/30 days = $1.67/day
                "requests_today": requests_today,
            }

        except Exception as e:
            logger.error(f"Error getting cost metrics: {str(e)}")
            return {
                "daily_spend": 0.0,
                "total_spend": 0.0,
                "budget_utilization": 0.0,
                "requests_today": 0,
            }

    # =============================================================================
    # HEALTH CHECK
    # =============================================================================

    async def health_check(self) -> bool:
        """Check Cosmos DB connectivity"""
        try:
            await self.ensure_initialized()

            # Simple connectivity check - just verify we can read database properties
            # This avoids issues with cross-partition queries on empty containers
            if self.database:
                # Reading database properties confirms connectivity
                await self.database.read()
                return True
            return False

        except Exception as e:
            logger.error(f"Cosmos DB health check failed: {str(e)}")
            return False

    # =============================================================================
    # MIGRATION SUPPORT METHODS
    # =============================================================================

    async def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Get user by email address"""
        await self.ensure_initialized()

        try:
            container = self.containers["users"]
            query = "SELECT * FROM c WHERE c.type = 'user' AND c.email = @email"
            parameters = [{"name": "@email", "value": email}]

            items = container.query_items(
                query=query,
                parameters=parameters,
            )

            async for item in items:
                return item

            return None

        except Exception as e:
            logger.error(f"Error getting user by email {email}: {str(e)}")
            return None

    async def create_user(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new user document"""
        await self.ensure_initialized()

        try:
            return await self.upsert_document("users", user_data)
        except Exception as e:
            logger.error(f"Error creating user: {str(e)}")
            raise

    async def create_workout_simple(
        self, workout_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Create a new workout document (simplified wrapper)"""
        await self.ensure_initialized()

        try:
            return await self.upsert_document("workouts", workout_data)
        except Exception as e:
            logger.error(f"Error creating workout: {str(e)}")
            raise

    async def create_chat_session(self, chat_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new chat session document"""
        await self.ensure_initialized()

        try:
            return await self.upsert_document("chat_sessions", chat_data)
        except Exception as e:
            logger.error(f"Error creating chat session: {str(e)}")
            raise

    async def count_documents(self, document_type: str) -> int:
        """Count documents of a specific type"""
        await self.ensure_initialized()

        try:
            # Determine container based on document type
            container_name = (
                "users"
                if document_type == "user"
                else "workouts" if document_type == "workout" else "chat_sessions"
            )

            container = self.containers[container_name]
            query = "SELECT VALUE COUNT(1) FROM c WHERE c.type = @type"
            parameters = [{"name": "@type", "value": document_type}]

            items = container.query_items(
                query=query,
                parameters=parameters,
            )

            async for item in items:
                return item

            return 0

        except Exception as e:
            logger.error(f"Error counting documents of type {document_type}: {str(e)}")
            return 0

    async def upsert_document(
        self, container_name: str, document: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Insert or update a document in the specified container"""
        await self.ensure_initialized()

        try:
            container = self.containers[container_name]
            result = await container.upsert_item(document)
            logger.debug(
                f"Upserted document in {container_name}: {document.get('id', 'unknown')}"
            )
            return result
        except Exception as e:
            logger.error(f"Error upserting document in {container_name}: {str(e)}")
            raise

    async def delete_document(
        self, container_name: str, document_id: str, partition_key: str
    ) -> bool:
        """Delete a document from the specified container"""
        await self.ensure_initialized()

        try:
            container = self.containers[container_name]
            await container.delete_item(document_id, partition_key=partition_key)
            logger.debug(f"Deleted document {document_id} from {container_name}")
            return True
        except Exception as e:
            logger.error(
                f"Error deleting document {document_id} from {container_name}: {str(e)}"
            )
            return False

    async def query_documents(
        self,
        container_name: str,
        query: str,
        parameters: Optional[List[Dict[str, Any]]] = None,
    ) -> List[Dict[str, Any]]:
        """Query documents from a container"""
        await self.ensure_initialized()

        try:
            container = self.containers[container_name]

            items = container.query_items(
                query=query,
                parameters=parameters or [],
            )

            results = []
            async for item in items:
                results.append(item)

            return results

        except Exception as e:
            logger.error(f"Error querying documents from {container_name}: {str(e)}")
            return []

    # =============================================================================
    # GHOST API - iOS App Native Support
    # =============================================================================

    async def get_pending_ghost_actions(self, user_id: str) -> List[Dict[str, Any]]:
        """Get pending Ghost actions for a user (for silent push payload)"""
        await self.ensure_initialized()

        try:
            # Check for pending schedule confirmations, workout feedback, etc.
            query = """
                SELECT * FROM c
                WHERE c.userId = @userId
                AND c.status = 'pending'
                AND c.type IN ('block_proposal', 'workout_feedback', 'trust_progress')
            """
            parameters = [{"name": "@userId", "value": user_id}]

            return await self.query_documents("ghost_actions", query, parameters)
        except Exception as e:
            logger.warning(f"Error getting pending ghost actions: {e}")
            return []

    async def queue_silent_push(self, user_id: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Queue a silent push notification for delivery via APNs"""
        await self.ensure_initialized()

        try:
            push_doc = {
                "id": str(uuid4()),
                "userId": user_id,
                "payload": payload,
                "status": "queued",
                "created_at": datetime.now(timezone.utc).isoformat(),
                "ttl": 3600  # 1 hour TTL
            }

            # Note: This would go to a dedicated container for push queue
            # For now, we'll use a generic approach
            container = self.containers.get("push_queue")
            if container:
                await container.create_item(body=push_doc)

            return push_doc
        except Exception as e:
            logger.error(f"Error queueing silent push: {e}")
            return {"id": str(uuid4()), "status": "error", "error": str(e)}

    async def get_trust_state(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get current trust state for a user"""
        await self.ensure_initialized()

        try:
            query = "SELECT * FROM c WHERE c.userId = @userId"
            parameters = [{"name": "@userId", "value": user_id}]

            results = await self.query_documents("trust_states", query, parameters)
            return results[0] if results else None
        except Exception as e:
            logger.warning(f"Error getting trust state: {e}")
            return None

    async def record_trust_event(self, user_id: str, event_data: Dict[str, Any]) -> Dict[str, Any]:
        """Record a trust event and update trust state"""
        await self.ensure_initialized()

        try:
            # Get current state
            current_state = await self.get_trust_state(user_id)

            if not current_state:
                current_state = {
                    "id": str(uuid4()),
                    "userId": user_id,
                    "phase": "observer",
                    "confidence": 0.0,
                    "consecutive_deletes": 0,
                    "events": []
                }

            # Calculate delta based on event type
            event_type = event_data.get("event_type", "unknown")
            delta = self._calculate_trust_delta(event_type, current_state["phase"])

            # Update state
            current_state["confidence"] = max(0.0, min(1.0, current_state["confidence"] + delta))
            current_state["last_updated"] = datetime.now(timezone.utc).isoformat()

            # Handle Safety Breaker
            if event_type == "user_deleted_block":
                current_state["consecutive_deletes"] = current_state.get("consecutive_deletes", 0) + 1
                if current_state["consecutive_deletes"] >= 3:
                    current_state["phase"] = self._downgrade_phase(current_state["phase"])
                    current_state["consecutive_deletes"] = 0
            elif event_type in ["completed_workout", "suggestion_accepted"]:
                current_state["consecutive_deletes"] = 0

            # Check for phase progression
            current_state["phase"] = self._check_phase_progression(
                current_state["phase"],
                current_state["confidence"]
            )

            # TODO: Store event record when trust_events container is available
            # Event would include: id, userId, event_type, delta, timestamp, metadata

            return current_state

        except Exception as e:
            logger.error(f"Error recording trust event: {e}")
            raise

    def _calculate_trust_delta(self, event_type: str, current_phase: str) -> float:
        """Calculate trust delta based on event type"""
        deltas = {
            "completed_workout": 0.05,
            "missed_workout": -0.08,
            "missed_workout_excuse": -0.02,
            "user_deleted_block": -0.15,
            "suggestion_accepted": 0.03,
            "auto_scheduled_completed": 0.07,
            "transformed_schedule_accepted": 0.08,
        }
        return deltas.get(event_type, 0.0)

    def _downgrade_phase(self, phase: str) -> str:
        """Downgrade trust phase by one level (Safety Breaker)"""
        phase_order = ["observer", "scheduler", "auto_scheduler", "transformer", "full_ghost"]
        current_idx = phase_order.index(phase) if phase in phase_order else 0
        new_idx = max(0, current_idx - 1)
        return phase_order[new_idx]

    def _check_phase_progression(self, phase: str, confidence: float) -> str:
        """Check if confidence warrants phase change"""
        thresholds = {
            "observer": (0.0, 0.25),
            "scheduler": (0.25, 0.50),
            "auto_scheduler": (0.50, 0.70),
            "transformer": (0.70, 0.85),
            "full_ghost": (0.85, 1.0)
        }

        for phase_name, (min_conf, max_conf) in thresholds.items():
            if min_conf <= confidence < max_conf:
                return phase_name

        return "full_ghost" if confidence >= 0.85 else phase

    async def get_training_blocks(self, user_id: str, week_offset: int = 0) -> List[Dict[str, Any]]:
        """Get training blocks for a user (for schedule sync)"""
        await self.ensure_initialized()

        try:
            # Calculate week boundaries
            from datetime import timedelta
            today = datetime.now(timezone.utc).date()
            week_start = today - timedelta(days=today.weekday()) + timedelta(weeks=week_offset)
            week_end = week_start + timedelta(days=7)

            query = """
                SELECT * FROM c
                WHERE c.userId = @userId
                AND c.start_time >= @weekStart
                AND c.start_time < @weekEnd
                ORDER BY c.start_time
            """
            parameters = [
                {"name": "@userId", "value": user_id},
                {"name": "@weekStart", "value": week_start.isoformat()},
                {"name": "@weekEnd", "value": week_end.isoformat()}
            ]

            return await self.query_documents("training_blocks", query, parameters)
        except Exception as e:
            logger.warning(f"Error getting training blocks: {e}")
            return []

    async def create_training_block(self, user_id: str, block_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new training block"""
        await self.ensure_initialized()

        try:
            block = {
                "id": str(uuid4()),
                "userId": user_id,
                "start_time": block_data["start_time"],
                "duration_minutes": block_data["duration_minutes"],
                "workout_type": block_data["workout_type"],
                "status": block_data.get("status", "scheduled"),
                "created_at": datetime.now(timezone.utc).isoformat(),
                "source": block_data.get("source", "ghost_auto"),
                "calendar_event_id": block_data.get("calendar_event_id")
            }

            container = self.containers.get("training_blocks") or self.containers["workouts"]
            await container.create_item(body=block)
            return block

        except Exception as e:
            logger.error(f"Error creating training block: {e}")
            raise

    async def update_training_block(
        self, user_id: str, block_id: str, block_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Update an existing training block"""
        await self.ensure_initialized()

        try:
            container = self.containers.get("training_blocks") or self.containers["workouts"]

            # Get existing block
            query = "SELECT * FROM c WHERE c.id = @blockId AND c.userId = @userId"
            parameters = [
                {"name": "@blockId", "value": block_id},
                {"name": "@userId", "value": user_id}
            ]

            results = []
            async for item in container.query_items(query=query, parameters=parameters):
                results.append(item)

            if not results:
                raise ValueError(f"Block {block_id} not found")

            existing = results[0]

            # Update fields
            for key in ["start_time", "duration_minutes", "workout_type", "status"]:
                if key in block_data:
                    existing[key] = block_data[key]

            existing["updated_at"] = datetime.now(timezone.utc).isoformat()

            await container.replace_item(item=existing["id"], body=existing)
            return existing

        except Exception as e:
            logger.error(f"Error updating training block: {e}")
            raise

    async def get_phenome_store(
        self, user_id: str, store_type: str
    ) -> Optional[Dict[str, Any]]:
        """Get Phenome store data for sync"""
        await self.ensure_initialized()

        try:
            query = "SELECT * FROM c WHERE c.userId = @userId AND c.store_type = @storeType"
            parameters = [
                {"name": "@userId", "value": user_id},
                {"name": "@storeType", "value": store_type}
            ]

            results = await self.query_documents("phenome", query, parameters)
            return results[0] if results else None

        except Exception as e:
            logger.warning(f"Error getting phenome store: {e}")
            return None

    async def update_phenome_store(
        self, user_id: str, store_type: str, data: Dict[str, Any], version: int
    ) -> Dict[str, Any]:
        """Update Phenome store data"""
        await self.ensure_initialized()

        try:
            store_doc = {
                "id": f"{user_id}_{store_type}",
                "userId": user_id,
                "store_type": store_type,
                "data": data,
                "version": version,
                "updated_at": datetime.now(timezone.utc).isoformat()
            }

            container = self.containers.get("phenome") or self.containers["users"]
            await container.upsert_item(body=store_doc)
            return store_doc

        except Exception as e:
            logger.error(f"Error updating phenome store: {e}")
            raise

    async def store_decision_receipt(
        self, user_id: str, receipt_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Store a Ghost decision receipt with 90-day TTL"""
        await self.ensure_initialized()

        try:
            receipt = {
                "id": str(uuid4()),
                "userId": user_id,
                "decision_type": receipt_data["decision_type"],
                "inputs": receipt_data["inputs"],
                "output": receipt_data["output"],
                "explanation": receipt_data["explanation"],
                "timestamp": receipt_data["timestamp"],
                "ttl": 90 * 24 * 3600  # 90 days in seconds
            }

            container = self.containers.get("decision_receipts") or self.containers["users"]
            await container.create_item(body=receipt)
            return receipt

        except Exception as e:
            logger.error(f"Error storing decision receipt: {e}")
            raise

    async def get_active_users_for_morning_push(self) -> List[Dict[str, Any]]:
        """Get users who should receive morning push (for timer trigger)"""
        await self.ensure_initialized()

        try:
            # Get users who have been active in last 7 days and have push enabled
            seven_days_ago = (
                datetime.now(timezone.utc) - __import__('datetime').timedelta(days=7)
            ).isoformat()

            query = """
                SELECT c.id, c.email, c.timezone, c.push_enabled
                FROM c
                WHERE c.last_active >= @since
                AND (c.push_enabled = true OR NOT IS_DEFINED(c.push_enabled))
            """
            parameters = [{"name": "@since", "value": seven_days_ago}]

            return await self.query_documents("users", query, parameters)

        except Exception as e:
            logger.warning(f"Error getting users for morning push: {e}")
            return []

    async def get_users_for_weekly_planning(self) -> List[Dict[str, Any]]:
        """Get users who need weekly planning notification"""
        await self.ensure_initialized()

        try:
            # Get users who haven't had a weekly plan created this week
            query = """
                SELECT c.id, c.email, c.timezone
                FROM c
                WHERE c.trust_phase IN ('scheduler', 'auto_scheduler', 'transformer', 'full_ghost')
            """

            return await self.query_documents("users", query, [])

        except Exception as e:
            logger.warning(f"Error getting users for weekly planning: {e}")
            return []

    # =============================================================================
    # CLEANUP
    # =============================================================================

    async def close(self):
        """Close Cosmos DB client"""
        if self.client:
            await self.client.close()
            self.client = None
            self.database = None
            self.containers = {}


# =============================================================================
# GLOBAL CLIENT INSTANCE AND HELPER FUNCTIONS
# =============================================================================

# Global Cosmos DB client instance
_global_client: Optional[CosmosDBClient] = None


async def get_global_client() -> CosmosDBClient:
    """Get global Cosmos DB client instance"""
    global _global_client
    if _global_client is None:
        _global_client = CosmosDBClient()
        await _global_client.initialize()
    return _global_client


def get_cosmos_container(container_name: str):
    """Synchronous helper to get container (for use in auth module)"""
    import asyncio

    try:
        # Try to get existing event loop
        loop = asyncio.get_event_loop()
        if loop.is_running():
            # If we're in an async context, we need to handle this differently
            # For now, return a container proxy directly
            settings = get_settings()
            from azure.cosmos import CosmosClient

            client = CosmosClient(
                url=settings.COSMOS_DB_ENDPOINT, credential=settings.COSMOS_DB_KEY
            )
            database = client.get_database_client(settings.COSMOS_DB_DATABASE)
            return database.get_container_client(container_name)
        else:
            # Create new event loop for sync access
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            client = loop.run_until_complete(get_global_client())
            return client.containers[container_name]
    except Exception as e:
        logger.error(f"Error getting container {container_name}: {str(e)}")
        # Fallback to direct connection
        settings = get_settings()
        from azure.cosmos import CosmosClient

        client = CosmosClient(
            url=settings.COSMOS_DB_ENDPOINT, credential=settings.COSMOS_DB_KEY
        )
        database = client.get_database_client(settings.COSMOS_DB_DATABASE)
        return database.get_container_client(container_name)

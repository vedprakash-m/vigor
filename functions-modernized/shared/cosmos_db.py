"""
Cosmos DB client for Vigor Functions
Handles all database operations wit            return user_document
            
        except Exception as e:
            if hasattr(e, 'status_code') and e.status_code == 404:
                return None
             except Exception as e:
            if hasattr(e, 'status_code') and e.status_code == 404:
                return True
            logger.error(f"Error deleting workout: {str(e)}")
            raise  logger.error(f"Error getting user profile: {str(e)}")
            raiseodernized NoSQL schema
"""

import asyncio
import json
import logging
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any, Union
from uuid import uuid4

from azure.cosmos.aio import CosmosClient, DatabaseProxy, ContainerProxy
from azure.cosmos import PartitionKey
from azure.core.exceptions import AzureError

from .config import get_settings
from .models import UserProfile, WorkoutPlan, WorkoutLog, AICoachMessage

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
            self.client = CosmosClient(
                url=self.settings.COSMOS_DB_ENDPOINT,
                credential=self.settings.COSMOS_DB_KEY
            )
            
            self.database = self.client.get_database_client(
                self.settings.COSMOS_DB_DATABASE
            )
            
            # Initialize container references
            self.containers = {
                "users": self.database.get_container_client("users"),
                "workouts": self.database.get_container_client("workouts"),
                "workout_logs": self.database.get_container_client("workout_logs"),
                "ai_coach_messages": self.database.get_container_client("ai_coach_messages")
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
        """Get user profile by user ID"""
        await self.ensure_initialized()
        
        try:
            container = self.containers["users"]
            response = await container.read_item(
                item=user_id,
                partition_key=user_id
            )
            return response
            
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
                "profile": user_data.get("profile", {
                    "fitnessLevel": "beginner",
                    "goals": [],
                    "equipment": "bodyweight",
                    "tier": "free"
                }),
                "preferences": user_data.get("preferences", {
                    "workoutDuration": 45,
                    "restDays": [],
                    "notifications": True
                }),
                "createdAt": datetime.now(timezone.utc).isoformat(),
                "updatedAt": datetime.now(timezone.utc).isoformat()
            }
            
            container = self.containers["users"]
            response = await container.create_item(body=user_document)
            return response
            
        except Exception as e:
            logger.error(f"Error creating user profile: {str(e)}")
            raise
    
    async def update_user_profile(self, user_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
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
            response = await container.replace_item(
                item=user_id,
                body=existing_profile
            )
            return response
            
        except Exception as e:
            logger.error(f"Error updating user profile: {str(e)}")
            raise
    
    # =============================================================================
    # WORKOUT OPERATIONS
    # =============================================================================
    
    async def create_workout(self, user_id: str, workout_data: Dict[str, Any]) -> Dict[str, Any]:
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
                    "aiProviderUsed": "gemini-flash-2.5",
                    "tags": workout_data.get("tags", [])
                },
                "createdAt": datetime.now(timezone.utc).isoformat()
            }
            
            container = self.containers["workouts"]
            response = await container.create_item(body=workout_document)
            return response
            
        except Exception as e:
            logger.error(f"Error creating workout: {str(e)}")
            raise
    
    async def get_user_workouts(self, user_id: str, limit: int = 20, offset: int = 0) -> List[Dict[str, Any]]:
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
                {"name": "@limit", "value": limit}
            ]
            
            items = []
            async for item in container.query_items(
                query=query,
                parameters=parameters,
                partition_key=user_id
            ):
                items.append(item)
                
            return items
            
        except Exception as e:
            logger.error(f"Error getting user workouts: {str(e)}")
            raise
    
    async def get_workout(self, workout_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Get specific workout by ID"""
        await self.ensure_initialized()
        
        try:
            container = self.containers["workouts"]
            response = await container.read_item(
                item=workout_id,
                partition_key=user_id
            )
            return response
            
        except Exception as e:
            if hasattr(e, 'status_code') and e.status_code == 404:
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
            await container.delete_item(
                item=workout_id,
                partition_key=user_id
            )
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
    
    async def create_workout_log(self, user_id: str, workout_id: Optional[str], session_data: Dict[str, Any]) -> Dict[str, Any]:
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
                "completedAt": datetime.now(timezone.utc).isoformat()
            }
            
            container = self.containers["workout_logs"]
            response = await container.create_item(body=log_document)
            return response
            
        except Exception as e:
            logger.error(f"Error creating workout log: {str(e)}")
            raise
    
    async def get_user_workout_logs(self, user_id: str, limit: int = 20) -> List[Dict[str, Any]]:
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
                {"name": "@limit", "value": limit}
            ]
            
            items = []
            async for item in container.query_items(
                query=query,
                parameters=parameters,
                partition_key=user_id
            ):
                items.append(item)
                
            return items
            
        except Exception as e:
            logger.error(f"Error getting workout logs: {str(e)}")
            raise
    
    # =============================================================================
    # AI CHAT OPERATIONS
    # =============================================================================
    
    async def save_chat_messages(self, messages: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
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
                    "providerUsed": message.get("providerUsed", "gemini-flash-2.5"),
                    "tokensUsed": message.get("tokensUsed"),
                    "responseTimeMs": message.get("responseTimeMs"),
                    "createdAt": message.get("createdAt", datetime.now(timezone.utc).isoformat())
                }
                
                response = await container.create_item(body=message_document)
                saved_messages.append(response)
                
            return saved_messages
            
        except Exception as e:
            logger.error(f"Error saving chat messages: {str(e)}")
            raise
    
    async def get_conversation_history(self, user_id: str, limit: int = 10) -> List[Dict[str, Any]]:
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
                {"name": "@limit", "value": limit}
            ]
            
            items = []
            async for item in container.query_items(
                query=query,
                parameters=parameters,
                partition_key=user_id
            ):
                items.append(item)
                
            # Return in chronological order (oldest first)
            return list(reversed(items))
            
        except Exception as e:
            logger.error(f"Error getting conversation history: {str(e)}")
            raise
    
    # =============================================================================
    # COST TRACKING & ANALYTICS
    # =============================================================================
    
    async def get_daily_ai_spend(self) -> float:
        """Get current daily AI spend across all users"""
        await self.ensure_initialized()
        
        try:
            # For now, return a mock value
            # In production, this would query usage metrics
            today = datetime.now(timezone.utc).date().isoformat()
            
            container = self.containers["ai_coach_messages"]
            query = """
                SELECT COUNT(1) as message_count 
                FROM c 
                WHERE STARTSWITH(c.createdAt, @today)
            """
            
            parameters = [{"name": "@today", "value": today}]
            
            result = []
            async for item in container.query_items(query=query, parameters=parameters):
                result.append(item)
            
            message_count = result[0]["message_count"] if result else 0
            
            # Estimate cost: $0.01 per message (rough estimate for Gemini Flash)
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
            
            query = """
                SELECT COUNT(1) as count 
                FROM c 
                WHERE STARTSWITH(c.createdAt, @today)
            """
            
            parameters = [{"name": "@today", "value": today}]
            
            result = []
            async for item in container.query_items(query=query, parameters=parameters):
                result.append(item)
            
            requests_today = result[0]["count"] if result else 0
            
            return {
                "daily_spend": daily_spend,
                "total_spend": daily_spend,  # For now, same as daily
                "budget_utilization": (daily_spend / 1.67) * 100,  # $50/30 days = $1.67/day
                "requests_today": requests_today
            }
            
        except Exception as e:
            logger.error(f"Error getting cost metrics: {str(e)}")
            return {
                "daily_spend": 0.0,
                "total_spend": 0.0,
                "budget_utilization": 0.0,
                "requests_today": 0
            }
    
    # =============================================================================
    # HEALTH CHECK
    # =============================================================================
    
    async def health_check(self) -> bool:
        """Check Cosmos DB connectivity"""
        try:
            await self.ensure_initialized()
            
            # Try to read from users container
            container = self.containers["users"]
            query = "SELECT TOP 1 c.id FROM c"
            
            async for _ in container.query_items(query=query):
                break
                
            return True
            
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
                enable_cross_partition_query=True
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
    
    async def create_workout(self, workout_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new workout document"""
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
            container_name = "users" if document_type == "user" else \
                           "workouts" if document_type == "workout" else \
                           "chat_sessions"
            
            container = self.containers[container_name]
            query = "SELECT VALUE COUNT(1) FROM c WHERE c.type = @type"
            parameters = [{"name": "@type", "value": document_type}]
            
            items = container.query_items(
                query=query,
                parameters=parameters,
                enable_cross_partition_query=True
            )
            
            async for item in items:
                return item
            
            return 0
            
        except Exception as e:
            logger.error(f"Error counting documents of type {document_type}: {str(e)}")
            return 0

    async def upsert_document(self, container_name: str, document: Dict[str, Any]) -> Dict[str, Any]:
        """Insert or update a document in the specified container"""
        await self.ensure_initialized()
        
        try:
            container = self.containers[container_name]
            result = await container.upsert_item(document)
            logger.debug(f"Upserted document in {container_name}: {document.get('id', 'unknown')}")
            return result
        except Exception as e:
            logger.error(f"Error upserting document in {container_name}: {str(e)}")
            raise
    
    async def delete_document(self, container_name: str, document_id: str, partition_key: str) -> bool:
        """Delete a document from the specified container"""
        await self.ensure_initialized()
        
        try:
            container = self.containers[container_name]
            await container.delete_item(document_id, partition_key=partition_key)
            logger.debug(f"Deleted document {document_id} from {container_name}")
            return True
        except Exception as e:
            logger.error(f"Error deleting document {document_id} from {container_name}: {str(e)}")
            return False
    
    async def query_documents(self, container_name: str, query: str, parameters: Optional[List[Dict[str, Any]]] = None) -> List[Dict[str, Any]]:
        """Query documents from a container"""
        await self.ensure_initialized()
        
        try:
            container = self.containers[container_name]
            
            items = container.query_items(
                query=query,
                parameters=parameters or [],
                enable_cross_partition_query=True
            )
            
            results = []
            async for item in items:
                results.append(item)
            
            return results
            
        except Exception as e:
            logger.error(f"Error querying documents from {container_name}: {str(e)}")
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
                url=settings.COSMOS_DB_ENDPOINT,
                credential=settings.COSMOS_DB_KEY
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
            url=settings.COSMOS_DB_ENDPOINT,
            credential=settings.COSMOS_DB_KEY
        )
        database = client.get_database_client(settings.COSMOS_DB_DATABASE)
        return database.get_container_client(container_name)

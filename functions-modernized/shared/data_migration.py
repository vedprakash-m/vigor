"""
Data migration utilities for migrating from PostgreSQL to Cosmos DB
Handles conversion of relational data to document-based NoSQL structure
"""

import asyncio
import json
import logging
from datetime import datetime, timezone
from typing import Dict, List, Any, Optional
import uuid

from cosmos_db import CosmosDBClient
from config import get_settings

logger = logging.getLogger(__name__)


class DataMigrationError(Exception):
    """Custom data migration error"""
    pass


class PostgreSQLToCosmosDBMigrator:
    """Migrates data from PostgreSQL to Cosmos DB"""
    
    def __init__(self):
        self.settings = get_settings()
        self.cosmos_client = None
    
    async def initialize(self):
        """Initialize Cosmos DB client"""
        try:
            self.cosmos_client = CosmosDBClient()
            await self.cosmos_client.initialize()
            logger.info("Cosmos DB client initialized for migration")
        except Exception as e:
            logger.error(f"Failed to initialize Cosmos DB client: {str(e)}")
            raise DataMigrationError(f"Initialization failed: {str(e)}")
    
    async def migrate_users(self, users_data: List[Dict[str, Any]]) -> int:
        """Migrate users from PostgreSQL to Cosmos DB"""
        try:
            migrated_count = 0
            
            for user_data in users_data:
                # Convert PostgreSQL user to Cosmos DB document
                user_doc = {
                    "id": str(user_data.get("id", uuid.uuid4())),
                    "type": "user",
                    "email": user_data.get("email"),
                    "username": user_data.get("username"),
                    "password_hash": user_data.get("password_hash"),
                    "tier": user_data.get("tier", "free"),
                    "is_active": user_data.get("is_active", True),
                    "created_at": self._convert_timestamp(user_data.get("created_at")),
                    "updated_at": self._convert_timestamp(user_data.get("updated_at")),
                    "last_login": self._convert_timestamp(user_data.get("last_login")),
                    "profile": {
                        "first_name": user_data.get("first_name"),
                        "last_name": user_data.get("last_name"),
                        "age": user_data.get("age"),
                        "fitness_level": user_data.get("fitness_level"),
                        "goals": user_data.get("goals", []),
                        "preferences": user_data.get("preferences", {})
                    },
                    "usage_stats": {
                        "workouts_generated": 0,
                        "ai_chats_used": 0,
                        "last_workout_date": None,
                        "total_sessions": 0
                    },
                    "partition_key": user_data.get("email")  # Partition by email
                }
                
                # Create user document
                await self.cosmos_client.create_user(user_doc)
                migrated_count += 1
                logger.info(f"Migrated user: {user_doc['email']}")
            
            logger.info(f"Successfully migrated {migrated_count} users")
            return migrated_count
            
        except Exception as e:
            logger.error(f"Error migrating users: {str(e)}")
            raise DataMigrationError(f"User migration failed: {str(e)}")
    
    async def migrate_workouts(self, workouts_data: List[Dict[str, Any]]) -> int:
        """Migrate workouts from PostgreSQL to Cosmos DB"""
        try:
            migrated_count = 0
            
            for workout_data in workouts_data:
                # Convert PostgreSQL workout to Cosmos DB document
                workout_doc = {
                    "id": str(workout_data.get("id", uuid.uuid4())),
                    "type": "workout",
                    "user_id": str(workout_data.get("user_id")),
                    "title": workout_data.get("title"),
                    "description": workout_data.get("description"),
                    "difficulty": workout_data.get("difficulty", "medium"),
                    "duration_minutes": workout_data.get("duration_minutes", 30),
                    "workout_type": workout_data.get("workout_type", "general"),
                    "equipment": workout_data.get("equipment", []),
                    "exercises": self._convert_exercises(workout_data.get("exercises", [])),
                    "ai_generated": workout_data.get("ai_generated", True),
                    "generation_prompt": workout_data.get("generation_prompt"),
                    "created_at": self._convert_timestamp(workout_data.get("created_at")),
                    "updated_at": self._convert_timestamp(workout_data.get("updated_at")),
                    "is_public": workout_data.get("is_public", False),
                    "tags": workout_data.get("tags", []),
                    "calories_estimate": workout_data.get("calories_estimate"),
                    "completion_stats": {
                        "times_completed": 0,
                        "last_completed": None,
                        "average_rating": None,
                        "completion_rate": 0.0
                    },
                    "partition_key": str(workout_data.get("user_id"))  # Partition by user_id
                }
                
                # Create workout document
                await self.cosmos_client.create_workout(workout_doc)
                migrated_count += 1
                logger.info(f"Migrated workout: {workout_doc['title']} for user {workout_doc['user_id']}")
            
            logger.info(f"Successfully migrated {migrated_count} workouts")
            return migrated_count
            
        except Exception as e:
            logger.error(f"Error migrating workouts: {str(e)}")
            raise DataMigrationError(f"Workout migration failed: {str(e)}")
    
    async def migrate_chat_sessions(self, chat_data: List[Dict[str, Any]]) -> int:
        """Migrate AI chat sessions from PostgreSQL to Cosmos DB"""
        try:
            migrated_count = 0
            
            for chat_session in chat_data:
                # Convert PostgreSQL chat to Cosmos DB document
                chat_doc = {
                    "id": str(chat_session.get("id", uuid.uuid4())),
                    "type": "chat_session",
                    "user_id": str(chat_session.get("user_id")),
                    "title": chat_session.get("title", "AI Coach Session"),
                    "created_at": self._convert_timestamp(chat_session.get("created_at")),
                    "updated_at": self._convert_timestamp(chat_session.get("updated_at")),
                    "messages": self._convert_chat_messages(chat_session.get("messages", [])),
                    "session_stats": {
                        "message_count": len(chat_session.get("messages", [])),
                        "total_tokens_used": chat_session.get("total_tokens", 0),
                        "session_duration_minutes": chat_session.get("duration_minutes", 0)
                    },
                    "context": {
                        "user_goals": chat_session.get("user_goals", []),
                        "current_workout_plan": chat_session.get("current_workout"),
                        "fitness_level": chat_session.get("fitness_level")
                    },
                    "partition_key": str(chat_session.get("user_id"))  # Partition by user_id
                }
                
                # Create chat session document
                await self.cosmos_client.create_chat_session(chat_doc)
                migrated_count += 1
                logger.info(f"Migrated chat session: {chat_doc['title']} for user {chat_doc['user_id']}")
            
            logger.info(f"Successfully migrated {migrated_count} chat sessions")
            return migrated_count
            
        except Exception as e:
            logger.error(f"Error migrating chat sessions: {str(e)}")
            raise DataMigrationError(f"Chat migration failed: {str(e)}")
    
    def _convert_timestamp(self, timestamp: Any) -> Optional[str]:
        """Convert various timestamp formats to ISO string"""
        try:
            if timestamp is None:
                return None
            
            if isinstance(timestamp, str):
                return timestamp
            
            if hasattr(timestamp, 'isoformat'):
                return timestamp.isoformat()
            
            # Handle Unix timestamp
            if isinstance(timestamp, (int, float)):
                return datetime.fromtimestamp(timestamp, tz=timezone.utc).isoformat()
            
            return str(timestamp)
            
        except Exception as e:
            logger.warning(f"Error converting timestamp {timestamp}: {str(e)}")
            return None
    
    def _convert_exercises(self, exercises: List[Any]) -> List[Dict[str, Any]]:
        """Convert exercise data to proper format"""
        try:
            if isinstance(exercises, str):
                # If exercises is a JSON string, parse it
                exercises = json.loads(exercises)
            
            if not isinstance(exercises, list):
                return []
            
            converted_exercises = []
            for exercise in exercises:
                if isinstance(exercise, dict):
                    converted_exercise = {
                        "name": exercise.get("name", "Unknown Exercise"),
                        "sets": exercise.get("sets", 1),
                        "reps": exercise.get("reps", 10),
                        "duration_seconds": exercise.get("duration_seconds"),
                        "rest_seconds": exercise.get("rest_seconds", 60),
                        "instructions": exercise.get("instructions", ""),
                        "equipment": exercise.get("equipment", []),
                        "muscle_groups": exercise.get("muscle_groups", []),
                        "calories_per_set": exercise.get("calories_per_set", 0)
                    }
                    converted_exercises.append(converted_exercise)
                elif isinstance(exercise, str):
                    # Simple exercise name
                    converted_exercises.append({
                        "name": exercise,
                        "sets": 3,
                        "reps": 10,
                        "rest_seconds": 60,
                        "instructions": "",
                        "equipment": [],
                        "muscle_groups": [],
                        "calories_per_set": 5
                    })
            
            return converted_exercises
            
        except Exception as e:
            logger.warning(f"Error converting exercises: {str(e)}")
            return []
    
    def _convert_chat_messages(self, messages: List[Any]) -> List[Dict[str, Any]]:
        """Convert chat messages to proper format"""
        try:
            if isinstance(messages, str):
                messages = json.loads(messages)
            
            if not isinstance(messages, list):
                return []
            
            converted_messages = []
            for message in messages:
                if isinstance(message, dict):
                    converted_message = {
                        "id": str(message.get("id", uuid.uuid4())),
                        "role": message.get("role", "user"),  # "user" or "assistant"
                        "content": message.get("content", ""),
                        "timestamp": self._convert_timestamp(message.get("timestamp")),
                        "token_count": message.get("token_count", 0),
                        "metadata": message.get("metadata", {})
                    }
                    converted_messages.append(converted_message)
            
            return converted_messages
            
        except Exception as e:
            logger.warning(f"Error converting chat messages: {str(e)}")
            return []
    
    async def validate_migration(self) -> Dict[str, Any]:
        """Validate the migration by checking document counts and data integrity"""
        try:
            validation_results = {
                "success": True,
                "errors": [],
                "counts": {},
                "sample_checks": {}
            }
            
            # Count documents by type
            user_count = await self.cosmos_client.count_documents("user")
            workout_count = await self.cosmos_client.count_documents("workout")
            chat_count = await self.cosmos_client.count_documents("chat_session")
            
            validation_results["counts"] = {
                "users": user_count,
                "workouts": workout_count,
                "chat_sessions": chat_count,
                "total": user_count + workout_count + chat_count
            }
            
            # Sample data validation
            if user_count > 0:
                sample_user = await self.cosmos_client.get_user_by_email("sample@test.com")
                validation_results["sample_checks"]["user_structure"] = sample_user is not None
            
            logger.info(f"Migration validation completed: {validation_results}")
            return validation_results
            
        except Exception as e:
            logger.error(f"Error during migration validation: {str(e)}")
            return {
                "success": False,
                "errors": [str(e)],
                "counts": {},
                "sample_checks": {}
            }
    
    async def cleanup(self):
        """Cleanup resources"""
        try:
            if self.cosmos_client:
                await self.cosmos_client.close()
            logger.info("Migration cleanup completed")
        except Exception as e:
            logger.error(f"Error during cleanup: {str(e)}")


async def run_migration_from_json(json_file_path: str) -> Dict[str, Any]:
    """Run migration from exported JSON data"""
    try:
        migrator = PostgreSQLToCosmosDBMigrator()
        await migrator.initialize()
        
        # Load data from JSON file
        with open(json_file_path, 'r') as f:
            migration_data = json.load(f)
        
        results = {
            "users_migrated": 0,
            "workouts_migrated": 0,
            "chats_migrated": 0,
            "errors": []
        }
        
        # Migrate users
        if "users" in migration_data:
            results["users_migrated"] = await migrator.migrate_users(migration_data["users"])
        
        # Migrate workouts
        if "workouts" in migration_data:
            results["workouts_migrated"] = await migrator.migrate_workouts(migration_data["workouts"])
        
        # Migrate chat sessions
        if "chat_sessions" in migration_data:
            results["chats_migrated"] = await migrator.migrate_chat_sessions(migration_data["chat_sessions"])
        
        # Validate migration
        validation = await migrator.validate_migration()
        results["validation"] = validation
        
        await migrator.cleanup()
        
        logger.info(f"Migration completed: {results}")
        return results
        
    except Exception as e:
        logger.error(f"Migration failed: {str(e)}")
        raise DataMigrationError(f"Migration execution failed: {str(e)}")


if __name__ == "__main__":
    # Example usage
    import sys
    
    async def main():
        if len(sys.argv) < 2:
            print("Usage: python data_migration.py <json_file_path>")
            return
        
        json_file = sys.argv[1]
        results = await run_migration_from_json(json_file)
        print(f"Migration Results: {json.dumps(results, indent=2)}")
    
    asyncio.run(main())

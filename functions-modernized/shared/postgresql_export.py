"""
PostgreSQL data export script for migration to Cosmos DB
Exports users, workouts, and chat sessions to JSON format for migration
"""

import json
import logging
import asyncio
from datetime import datetime, timezone
from typing import Dict, List, Any, Optional
import os
import sys

# Add the backend path to import legacy models
sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', '.archive', 'legacy-backend'))

try:
    from sqlalchemy import create_engine, text
    from sqlalchemy.orm import sessionmaker
    import psycopg2
except ImportError:
    print("SQLAlchemy and psycopg2 required for PostgreSQL export")
    print("Install with: pip install sqlalchemy psycopg2-binary")
    sys.exit(1)

logger = logging.getLogger(__name__)


class PostgreSQLExporter:
    """Export data from PostgreSQL database for Cosmos DB migration"""
    
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.engine = None
        self.session = None
    
    def connect(self):
        """Connect to PostgreSQL database"""
        try:
            self.engine = create_engine(self.database_url)
            Session = sessionmaker(bind=self.engine)
            self.session = Session()
            logger.info("Connected to PostgreSQL database")
        except Exception as e:
            logger.error(f"Failed to connect to PostgreSQL: {str(e)}")
            raise
    
    def disconnect(self):
        """Disconnect from database"""
        try:
            if self.session:
                self.session.close()
            if self.engine:
                self.engine.dispose()
            logger.info("Disconnected from PostgreSQL database")
        except Exception as e:
            logger.error(f"Error disconnecting: {str(e)}")
    
    def export_users(self) -> List[Dict[str, Any]]:
        """Export all users from PostgreSQL"""
        try:
            # Raw SQL query to get user data
            query = text("""
                SELECT 
                    id, email, username, password_hash, tier,
                    is_active, created_at, updated_at, last_login,
                    first_name, last_name, age, fitness_level,
                    goals, preferences
                FROM users
                ORDER BY created_at
            """)
            
            result = self.session.execute(query)
            users = []
            
            for row in result:
                user_data = {
                    "id": row.id,
                    "email": row.email,
                    "username": row.username,
                    "password_hash": row.password_hash,
                    "tier": row.tier or "free",
                    "is_active": row.is_active if row.is_active is not None else True,
                    "created_at": row.created_at.isoformat() if row.created_at else None,
                    "updated_at": row.updated_at.isoformat() if row.updated_at else None,
                    "last_login": row.last_login.isoformat() if row.last_login else None,
                    "first_name": row.first_name,
                    "last_name": row.last_name,
                    "age": row.age,
                    "fitness_level": row.fitness_level,
                    "goals": self._parse_json_field(row.goals),
                    "preferences": self._parse_json_field(row.preferences)
                }
                users.append(user_data)
            
            logger.info(f"Exported {len(users)} users")
            return users
            
        except Exception as e:
            logger.error(f"Error exporting users: {str(e)}")
            return []
    
    def export_workouts(self) -> List[Dict[str, Any]]:
        """Export all workouts from PostgreSQL"""
        try:
            query = text("""
                SELECT 
                    id, user_id, title, description, difficulty,
                    duration_minutes, workout_type, equipment,
                    exercises, ai_generated, generation_prompt,
                    created_at, updated_at, is_public, tags,
                    calories_estimate
                FROM workouts
                ORDER BY created_at
            """)
            
            result = self.session.execute(query)
            workouts = []
            
            for row in result:
                workout_data = {
                    "id": row.id,
                    "user_id": row.user_id,
                    "title": row.title,
                    "description": row.description,
                    "difficulty": row.difficulty or "medium",
                    "duration_minutes": row.duration_minutes or 30,
                    "workout_type": row.workout_type or "general",
                    "equipment": self._parse_json_field(row.equipment),
                    "exercises": self._parse_json_field(row.exercises),
                    "ai_generated": row.ai_generated if row.ai_generated is not None else True,
                    "generation_prompt": row.generation_prompt,
                    "created_at": row.created_at.isoformat() if row.created_at else None,
                    "updated_at": row.updated_at.isoformat() if row.updated_at else None,
                    "is_public": row.is_public if row.is_public is not None else False,
                    "tags": self._parse_json_field(row.tags),
                    "calories_estimate": row.calories_estimate
                }
                workouts.append(workout_data)
            
            logger.info(f"Exported {len(workouts)} workouts")
            return workouts
            
        except Exception as e:
            logger.error(f"Error exporting workouts: {str(e)}")
            return []
    
    def export_chat_sessions(self) -> List[Dict[str, Any]]:
        """Export chat sessions from PostgreSQL"""
        try:
            # This assumes chat data is stored in a chats or chat_sessions table
            # Adjust the query based on actual schema
            query = text("""
                SELECT 
                    id, user_id, title, messages, created_at, updated_at,
                    total_tokens, duration_minutes, user_goals,
                    current_workout, fitness_level
                FROM chat_sessions
                ORDER BY created_at
            """)
            
            try:
                result = self.session.execute(query)
                chat_sessions = []
                
                for row in result:
                    chat_data = {
                        "id": row.id,
                        "user_id": row.user_id,
                        "title": row.title or "AI Coach Session",
                        "messages": self._parse_json_field(row.messages),
                        "created_at": row.created_at.isoformat() if row.created_at else None,
                        "updated_at": row.updated_at.isoformat() if row.updated_at else None,
                        "total_tokens": row.total_tokens or 0,
                        "duration_minutes": row.duration_minutes or 0,
                        "user_goals": self._parse_json_field(row.user_goals),
                        "current_workout": row.current_workout,
                        "fitness_level": row.fitness_level
                    }
                    chat_sessions.append(chat_data)
                
                logger.info(f"Exported {len(chat_sessions)} chat sessions")
                return chat_sessions
                
            except Exception as table_error:
                logger.warning(f"Chat sessions table not found or accessible: {str(table_error)}")
                logger.info("Skipping chat sessions export")
                return []
            
        except Exception as e:
            logger.error(f"Error exporting chat sessions: {str(e)}")
            return []
    
    def _parse_json_field(self, field_value: Any) -> Any:
        """Parse JSON field from PostgreSQL"""
        try:
            if field_value is None:
                return None
            
            if isinstance(field_value, str):
                # Try to parse as JSON
                try:
                    return json.loads(field_value)
                except json.JSONDecodeError:
                    return field_value
            
            # If it's already a dict/list, return as-is
            if isinstance(field_value, (dict, list)):
                return field_value
            
            return field_value
            
        except Exception as e:
            logger.warning(f"Error parsing JSON field: {str(e)}")
            return field_value
    
    def export_all_data(self) -> Dict[str, Any]:
        """Export all data from PostgreSQL"""
        try:
            export_data = {
                "export_timestamp": datetime.now(timezone.utc).isoformat(),
                "source_database": "postgresql",
                "target_database": "cosmosdb",
                "users": self.export_users(),
                "workouts": self.export_workouts(),
                "chat_sessions": self.export_chat_sessions()
            }
            
            # Add summary statistics
            export_data["summary"] = {
                "total_users": len(export_data["users"]),
                "total_workouts": len(export_data["workouts"]),
                "total_chat_sessions": len(export_data["chat_sessions"]),
                "total_records": (len(export_data["users"]) + 
                                len(export_data["workouts"]) + 
                                len(export_data["chat_sessions"]))
            }
            
            logger.info(f"Export completed: {export_data['summary']}")
            return export_data
            
        except Exception as e:
            logger.error(f"Error during data export: {str(e)}")
            raise


def export_postgresql_data(database_url: str, output_file: str) -> bool:
    """Main function to export PostgreSQL data to JSON file"""
    try:
        exporter = PostgreSQLExporter(database_url)
        exporter.connect()
        
        # Export all data
        export_data = exporter.export_all_data()
        
        # Write to JSON file
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(export_data, f, indent=2, ensure_ascii=False)
        
        exporter.disconnect()
        
        print(f"Data exported successfully to: {output_file}")
        print(f"Summary: {export_data['summary']}")
        return True
        
    except Exception as e:
        logger.error(f"Export failed: {str(e)}")
        print(f"Export failed: {str(e)}")
        return False


def create_sample_export_data() -> Dict[str, Any]:
    """Create sample export data for testing migration without PostgreSQL"""
    return {
        "export_timestamp": datetime.now(timezone.utc).isoformat(),
        "source_database": "sample_data",
        "target_database": "cosmosdb",
        "users": [
            {
                "id": 1,
                "email": "testuser@vigor.com",
                "username": "testuser",
                "password_hash": "hashed_password_123",
                "tier": "free",
                "is_active": True,
                "created_at": "2024-01-01T10:00:00Z",
                "updated_at": "2024-08-29T10:00:00Z",
                "last_login": "2024-08-28T10:00:00Z",
                "first_name": "Test",
                "last_name": "User",
                "age": 30,
                "fitness_level": "intermediate",
                "goals": ["lose_weight", "build_muscle"],
                "preferences": {"workout_time": "morning", "difficulty": "medium"}
            }
        ],
        "workouts": [
            {
                "id": 1,
                "user_id": 1,
                "title": "Morning Cardio",
                "description": "Quick cardio workout",
                "difficulty": "beginner",
                "duration_minutes": 20,
                "workout_type": "cardio",
                "equipment": [],
                "exercises": [
                    {
                        "name": "Jumping Jacks",
                        "sets": 3,
                        "reps": 20,
                        "rest_seconds": 30
                    }
                ],
                "ai_generated": True,
                "generation_prompt": "Create a quick morning cardio routine",
                "created_at": "2024-08-01T10:00:00Z",
                "updated_at": "2024-08-01T10:00:00Z",
                "is_public": False,
                "tags": ["cardio", "morning"],
                "calories_estimate": 150
            }
        ],
        "chat_sessions": [
            {
                "id": 1,
                "user_id": 1,
                "title": "Fitness Goals Discussion",
                "messages": [
                    {
                        "id": 1,
                        "role": "user",
                        "content": "What's the best way to start working out?",
                        "timestamp": "2024-08-01T10:00:00Z"
                    },
                    {
                        "id": 2,
                        "role": "assistant",
                        "content": "Start with light cardio and bodyweight exercises...",
                        "timestamp": "2024-08-01T10:01:00Z"
                    }
                ],
                "created_at": "2024-08-01T10:00:00Z",
                "updated_at": "2024-08-01T10:05:00Z",
                "total_tokens": 150,
                "duration_minutes": 5,
                "user_goals": ["lose_weight"],
                "current_workout": None,
                "fitness_level": "beginner"
            }
        ],
        "summary": {
            "total_users": 1,
            "total_workouts": 1,
            "total_chat_sessions": 1,
            "total_records": 3
        }
    }


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Export PostgreSQL data for Cosmos DB migration")
    parser.add_argument("--database-url", help="PostgreSQL database URL")
    parser.add_argument("--output", default="migration_data.json", help="Output JSON file")
    parser.add_argument("--sample", action="store_true", help="Create sample data instead of real export")
    
    args = parser.parse_args()
    
    if args.sample:
        # Create sample data for testing
        sample_data = create_sample_export_data()
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(sample_data, f, indent=2, ensure_ascii=False)
        print(f"Sample data created: {args.output}")
    else:
        if not args.database_url:
            print("Database URL required for real export")
            print("Use --sample to create sample data for testing")
            sys.exit(1)
        
        success = export_postgresql_data(args.database_url, args.output)
        sys.exit(0 if success else 1)

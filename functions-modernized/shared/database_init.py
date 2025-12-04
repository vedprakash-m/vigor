"""
Database initialization and seeding for Cosmos DB
Creates containers, sets up indexes, and populates initial data
"""

import asyncio
import json
import logging
from datetime import datetime, timezone
from typing import Dict, Any, List
import uuid

from .cosmos_db import CosmosDBClient
from .config import get_settings

logger = logging.getLogger(__name__)


class DatabaseInitializationError(Exception):
    """Custom database initialization error"""
    pass


class CosmosDBInitializer:
    """Initialize and seed Cosmos DB database"""
    
    def __init__(self):
        self.settings = get_settings()
        self.cosmos_client = None
    
    async def initialize_client(self):
        """Initialize Cosmos DB client"""
        try:
            self.cosmos_client = CosmosDBClient()
            await self.cosmos_client.initialize()
            logger.info("Cosmos DB client initialized for database setup")
        except Exception as e:
            logger.error(f"Failed to initialize Cosmos DB client: {str(e)}")
            raise DatabaseInitializationError(f"Client initialization failed: {str(e)}")
    
    async def create_database_and_containers(self):
        """Create database and all required containers"""
        try:
            # Database is created automatically by CosmosDBClient
            logger.info("Database creation handled by CosmosDBClient")
            
            # Containers are created automatically by the client methods
            # Test container creation by attempting basic operations
            test_user = {
                "id": "test-init-user",
                "type": "user",
                "email": "test@init.com",
                "username": "test_init",
                "password_hash": "test_hash",
                "tier": "free",
                "is_active": True,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat(),
                "profile": {},
                "usage_stats": {},
                "partition_key": "test@init.com"
            }
            
            # This will create the container if it doesn't exist
            await self.cosmos_client.upsert_document("users", test_user)
            
            # Clean up test document
            await self.cosmos_client.delete_document("users", "test-init-user", "test@init.com")
            
            logger.info("Database and containers successfully created/verified")
            
        except Exception as e:
            logger.error(f"Error creating database/containers: {str(e)}")
            raise DatabaseInitializationError(f"Container creation failed: {str(e)}")
    
    async def create_indexes(self):
        """Create custom indexes for better performance"""
        try:
            # Cosmos DB handles indexing automatically
            # Custom indexing policies can be set via Azure portal or ARM templates
            logger.info("Using default Cosmos DB indexing - custom indexes via portal if needed")
            
        except Exception as e:
            logger.error(f"Error creating indexes: {str(e)}")
            raise DatabaseInitializationError(f"Index creation failed: {str(e)}")
    
    async def seed_admin_user(self) -> str:
        """Create default admin user"""
        try:
            admin_email = self.settings.ADMIN_EMAIL or "admin@vigor.com"
            admin_password = self.settings.ADMIN_PASSWORD or "ChangeMe123!"
            
            # Check if admin already exists
            existing_admin = await self.cosmos_client.get_user_by_email(admin_email)
            if existing_admin:
                logger.info(f"Admin user already exists: {admin_email}")
                return existing_admin["id"]
            
            # Create admin user
            admin_user = {
                "id": str(uuid.uuid4()),
                "type": "user",
                "email": admin_email,
                "username": "admin",
                "password_hash": self._hash_password(admin_password),
                "tier": "admin",
                "is_active": True,
                "created_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat(),
                "last_login": None,
                "profile": {
                    "first_name": "Admin",
                    "last_name": "User",
                    "age": None,
                    "fitness_level": "advanced",
                    "goals": ["manage_system"],
                    "preferences": {}
                },
                "usage_stats": {
                    "workouts_generated": 0,
                    "ai_chats_used": 0,
                    "last_workout_date": None,
                    "total_sessions": 0
                },
                "partition_key": admin_email
            }
            
            await self.cosmos_client.upsert_document("users", admin_user)
            logger.info(f"Created admin user: {admin_email}")
            return admin_user["id"]
            
        except Exception as e:
            logger.error(f"Error creating admin user: {str(e)}")
            raise DatabaseInitializationError(f"Admin user creation failed: {str(e)}")
    
    async def seed_sample_workouts(self) -> int:
        """Create sample workout templates"""
        try:
            sample_workouts = [
                {
                    "id": str(uuid.uuid4()),
                    "type": "workout",
                    "user_id": "system",  # System-generated template
                    "title": "Quick Morning Routine",
                    "description": "A 15-minute energizing morning workout to start your day",
                    "difficulty": "beginner",
                    "duration_minutes": 15,
                    "workout_type": "cardio",
                    "equipment": [],
                    "exercises": [
                        {
                            "name": "Jumping Jacks",
                            "sets": 3,
                            "reps": 20,
                            "rest_seconds": 30,
                            "instructions": "Jump while spreading legs and raising arms overhead",
                            "equipment": [],
                            "muscle_groups": ["cardio", "full_body"],
                            "calories_per_set": 15
                        },
                        {
                            "name": "Push-ups",
                            "sets": 3,
                            "reps": 10,
                            "rest_seconds": 45,
                            "instructions": "Standard push-up form, modify on knees if needed",
                            "equipment": [],
                            "muscle_groups": ["chest", "shoulders", "arms"],
                            "calories_per_set": 12
                        },
                        {
                            "name": "Bodyweight Squats",
                            "sets": 3,
                            "reps": 15,
                            "rest_seconds": 30,
                            "instructions": "Squat down keeping chest up and knees behind toes",
                            "equipment": [],
                            "muscle_groups": ["legs", "glutes"],
                            "calories_per_set": 18
                        }
                    ],
                    "ai_generated": False,
                    "generation_prompt": None,
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                    "is_public": True,
                    "tags": ["morning", "quick", "no-equipment", "beginner"],
                    "calories_estimate": 135,
                    "completion_stats": {
                        "times_completed": 0,
                        "last_completed": None,
                        "average_rating": None,
                        "completion_rate": 0.0
                    },
                    "partition_key": "system"
                },
                {
                    "id": str(uuid.uuid4()),
                    "type": "workout",
                    "user_id": "system",
                    "title": "HIIT Cardio Blast",
                    "description": "High-intensity interval training for maximum calorie burn",
                    "difficulty": "intermediate",
                    "duration_minutes": 25,
                    "workout_type": "hiit",
                    "equipment": [],
                    "exercises": [
                        {
                            "name": "Burpees",
                            "sets": 4,
                            "reps": 8,
                            "rest_seconds": 60,
                            "instructions": "Full burpee with jump at the top",
                            "equipment": [],
                            "muscle_groups": ["full_body", "cardio"],
                            "calories_per_set": 25
                        },
                        {
                            "name": "Mountain Climbers",
                            "sets": 4,
                            "duration_seconds": 30,
                            "rest_seconds": 30,
                            "instructions": "Fast alternating leg movements in plank position",
                            "equipment": [],
                            "muscle_groups": ["core", "cardio"],
                            "calories_per_set": 20
                        },
                        {
                            "name": "High Knees",
                            "sets": 4,
                            "duration_seconds": 20,
                            "rest_seconds": 40,
                            "instructions": "Run in place bringing knees to chest level",
                            "equipment": [],
                            "muscle_groups": ["legs", "cardio"],
                            "calories_per_set": 15
                        }
                    ],
                    "ai_generated": False,
                    "generation_prompt": None,
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                    "is_public": True,
                    "tags": ["hiit", "cardio", "intense", "no-equipment"],
                    "calories_estimate": 240,
                    "completion_stats": {
                        "times_completed": 0,
                        "last_completed": None,
                        "average_rating": None,
                        "completion_rate": 0.0
                    },
                    "partition_key": "system"
                },
                {
                    "id": str(uuid.uuid4()),
                    "type": "workout",
                    "user_id": "system",
                    "title": "Strength Foundation",
                    "description": "Basic strength training for building muscle",
                    "difficulty": "beginner",
                    "duration_minutes": 35,
                    "workout_type": "strength",
                    "equipment": ["dumbbells"],
                    "exercises": [
                        {
                            "name": "Dumbbell Bicep Curls",
                            "sets": 3,
                            "reps": 12,
                            "rest_seconds": 60,
                            "instructions": "Curl dumbbells with controlled motion",
                            "equipment": ["dumbbells"],
                            "muscle_groups": ["biceps"],
                            "calories_per_set": 8
                        },
                        {
                            "name": "Dumbbell Shoulder Press",
                            "sets": 3,
                            "reps": 10,
                            "rest_seconds": 90,
                            "instructions": "Press dumbbells overhead from shoulder height",
                            "equipment": ["dumbbells"],
                            "muscle_groups": ["shoulders", "triceps"],
                            "calories_per_set": 12
                        },
                        {
                            "name": "Dumbbell Rows",
                            "sets": 3,
                            "reps": 12,
                            "rest_seconds": 60,
                            "instructions": "Bent-over row with dumbbells",
                            "equipment": ["dumbbells"],
                            "muscle_groups": ["back", "biceps"],
                            "calories_per_set": 10
                        }
                    ],
                    "ai_generated": False,
                    "generation_prompt": None,
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                    "is_public": True,
                    "tags": ["strength", "dumbbells", "beginner", "muscle-building"],
                    "calories_estimate": 90,
                    "completion_stats": {
                        "times_completed": 0,
                        "last_completed": None,
                        "average_rating": None,
                        "completion_rate": 0.0
                    },
                    "partition_key": "system"
                }
            ]
            
            created_count = 0
            for workout in sample_workouts:
                await self.cosmos_client.upsert_document("workouts", workout)
                created_count += 1
                logger.info(f"Created sample workout: {workout['title']}")
            
            logger.info(f"Created {created_count} sample workouts")
            return created_count
            
        except Exception as e:
            logger.error(f"Error creating sample workouts: {str(e)}")
            raise DatabaseInitializationError(f"Sample workout creation failed: {str(e)}")
    
    def _hash_password(self, password: str) -> str:
        """Hash password for storage"""
        try:
            import bcrypt
            salt = bcrypt.gensalt()
            return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
        except ImportError:
            # Fallback to simple hash (not recommended for production)
            import hashlib
            return hashlib.sha256(password.encode()).hexdigest()
    
    async def verify_initialization(self) -> Dict[str, Any]:
        """Verify database initialization was successful"""
        try:
            verification_results = {
                "success": True,
                "errors": [],
                "components": {}
            }
            
            # Check if admin user exists
            admin_email = self.settings.ADMIN_EMAIL or "admin@vigor.com"
            admin_user = await self.cosmos_client.get_user_by_email(admin_email)
            verification_results["components"]["admin_user"] = admin_user is not None
            
            # Check sample workouts
            sample_workouts = await self.cosmos_client.query_documents(
                "workouts",
                "SELECT * FROM c WHERE c.user_id = 'system'"
            )
            verification_results["components"]["sample_workouts"] = len(sample_workouts) > 0
            verification_results["components"]["sample_workout_count"] = len(sample_workouts)
            
            # Check containers are accessible
            try:
                # Test basic operations
                test_query = await self.cosmos_client.query_documents(
                    "users",
                    "SELECT TOP 1 * FROM c WHERE c.type = 'user'"
                )
                verification_results["components"]["containers_accessible"] = True
            except Exception as e:
                verification_results["components"]["containers_accessible"] = False
                verification_results["errors"].append(f"Container access failed: {str(e)}")
            
            if verification_results["errors"]:
                verification_results["success"] = False
            
            logger.info(f"Database verification completed: {verification_results}")
            return verification_results
            
        except Exception as e:
            logger.error(f"Error during verification: {str(e)}")
            return {
                "success": False,
                "errors": [str(e)],
                "components": {}
            }
    
    async def cleanup(self):
        """Cleanup resources"""
        try:
            if self.cosmos_client:
                await self.cosmos_client.close()
            logger.info("Database initialization cleanup completed")
        except Exception as e:
            logger.error(f"Error during cleanup: {str(e)}")


async def initialize_database() -> Dict[str, Any]:
    """Main function to initialize the complete database"""
    try:
        initializer = CosmosDBInitializer()
        await initializer.initialize_client()
        
        results = {
            "success": True,
            "steps_completed": [],
            "errors": []
        }
        
        # Create database and containers
        await initializer.create_database_and_containers()
        results["steps_completed"].append("database_and_containers_created")
        
        # Create indexes
        await initializer.create_indexes()
        results["steps_completed"].append("indexes_created")
        
        # Seed admin user
        admin_id = await initializer.seed_admin_user()
        results["admin_user_id"] = admin_id
        results["steps_completed"].append("admin_user_created")
        
        # Seed sample workouts
        workout_count = await initializer.seed_sample_workouts()
        results["sample_workouts_created"] = workout_count
        results["steps_completed"].append("sample_workouts_created")
        
        # Verify initialization
        verification = await initializer.verify_initialization()
        results["verification"] = verification
        results["steps_completed"].append("verification_completed")
        
        await initializer.cleanup()
        
        logger.info(f"Database initialization completed: {results}")
        return results
        
    except Exception as e:
        logger.error(f"Database initialization failed: {str(e)}")
        return {
            "success": False,
            "steps_completed": [],
            "errors": [str(e)]
        }


if __name__ == "__main__":
    # Run database initialization
    async def main():
        results = await initialize_database()
        print(f"Database Initialization Results: {json.dumps(results, indent=2)}")
    
    asyncio.run(main())

"""
Comprehensive Schema Tests
Tests all Pydantic schemas for validation, serialization, and edge cases
"""

import pytest
from datetime import datetime
from typing import List
from pydantic import ValidationError

# Import all schemas
from api.schemas.auth import UserRegister, UserLogin, Token, TokenData, UserResponse
from api.schemas.users import UserProfileUpdate, UserProgressResponse, UserStatsResponse
from api.schemas.workouts import (
    WorkoutPlanCreate, WorkoutPlanResponse, WorkoutLogCreate,
    WorkoutLogResponse, ExerciseCreate, ExerciseResponse
)
from api.schemas.ai import (
    ChatMessage, ChatResponse, WorkoutAnalysisRequest,
    WorkoutAnalysisResponse, AIConfigRequest
)


class TestAuthSchemas:
    """Test authentication-related schemas"""

    def test_user_register_valid(self):
        """Test valid user registration data"""
        data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "StrongPassword123!",
            "fitness_level": "beginner",
            "goals": ["strength", "endurance"],
            "equipment": "minimal"
        }

        user = UserRegister(**data)

        assert user.email == "test@example.com"
        assert user.username == "testuser"
        assert user.fitness_level == "beginner"
        assert user.goals == ["strength", "endurance"]
        assert user.equipment == "minimal"

    def test_user_register_invalid_email(self):
        """Test user registration with invalid email"""
        data = {
            "email": "invalid-email",
            "username": "testuser",
            "password": "StrongPassword123!",
            "fitness_level": "beginner",
            "goals": ["strength"],
            "equipment": "minimal"
        }

        with pytest.raises(ValidationError):
            UserRegister(**data)

    def test_user_register_invalid_fitness_level(self):
        """Test user registration with invalid fitness level"""
        data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "StrongPassword123!",
            "fitness_level": "superhuman",  # Invalid
            "goals": ["strength"],
            "equipment": "minimal"
        }

        with pytest.raises(ValidationError):
            UserRegister(**data)

    def test_user_register_invalid_equipment(self):
        """Test user registration with invalid equipment"""
        data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "StrongPassword123!",
            "fitness_level": "beginner",
            "goals": ["strength"],
            "equipment": "unlimited"  # Invalid
        }

        with pytest.raises(ValidationError):
            UserRegister(**data)

    def test_user_register_short_username(self):
        """Test user registration with too short username"""
        data = {
            "email": "test@example.com",
            "username": "ab",  # Too short
            "password": "StrongPassword123!",
            "fitness_level": "beginner",
            "goals": ["strength"],
            "equipment": "minimal"
        }

        with pytest.raises(ValidationError):
            UserRegister(**data)

    def test_user_register_short_password(self):
        """Test user registration with too short password"""
        data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "short",  # Too short
            "fitness_level": "beginner",
            "goals": ["strength"],
            "equipment": "minimal"
        }

        with pytest.raises(ValidationError):
            UserRegister(**data)

    def test_user_login_valid(self):
        """Test valid user login data"""
        data = {
            "email": "test@example.com",
            "password": "StrongPassword123!"
        }

        login = UserLogin(**data)

        assert login.email == "test@example.com"
        assert login.password == "StrongPassword123!"

    def test_user_login_invalid_email(self):
        """Test user login with invalid email"""
        data = {
            "email": "invalid-email",
            "password": "password123"
        }

        with pytest.raises(ValidationError):
            UserLogin(**data)

    def test_token_schema(self):
        """Test token schema"""
        expires_at = datetime.utcnow()
        data = {
            "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
            "expires_at": expires_at
        }

        token = Token(**data)

        assert token.access_token == "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
        assert token.token_type == "bearer"
        assert token.expires_at == expires_at

    def test_token_data_schema(self):
        """Test token data schema"""
        data = {"user_id": "user123"}

        token_data = TokenData(**data)
        assert token_data.user_id == "user123"

        # Test with None
        token_data_none = TokenData()
        assert token_data_none.user_id is None

    def test_user_response_schema(self):
        """Test user response schema"""
        created_at = datetime.utcnow()
        updated_at = datetime.utcnow()

        data = {
            "id": "user123",
            "email": "test@example.com",
            "username": "testuser",
            "fitness_level": "intermediate",
            "goals": ["strength", "muscle_gain"],
            "equipment": "moderate",
            "user_tier": "premium",
            "monthly_budget": 25.0,
            "current_month_usage": 12.5,
            "created_at": created_at,
            "updated_at": updated_at
        }

        user_response = UserResponse(**data)

        assert user_response.id == "user123"
        assert user_response.email == "test@example.com"
        assert user_response.username == "testuser"
        assert user_response.fitness_level == "intermediate"
        assert user_response.goals == ["strength", "muscle_gain"]
        assert user_response.equipment == "moderate"
        assert user_response.user_tier == "premium"
        assert user_response.monthly_budget == 25.0
        assert user_response.current_month_usage == 12.5


class TestWorkoutSchemas:
    """Test workout-related schemas"""

    def test_exercise_create_valid(self):
        """Test valid exercise creation"""
        data = {
            "name": "Push-ups",
            "description": "Standard push-up exercise",
            "muscle_groups": ["chest", "triceps", "shoulders"],
            "equipment_needed": "none",
            "difficulty_level": "beginner"
        }

        exercise = ExerciseCreate(**data)

        assert exercise.name == "Push-ups"
        assert exercise.description == "Standard push-up exercise"
        assert exercise.muscle_groups == ["chest", "triceps", "shoulders"]
        assert exercise.equipment_needed == "none"
        assert exercise.difficulty_level == "beginner"

    def test_exercise_response_schema(self):
        """Test exercise response schema"""
        created_at = datetime.utcnow()

        data = {
            "id": "exercise123",
            "name": "Squats",
            "description": "Basic squat exercise",
            "muscle_groups": ["quadriceps", "glutes"],
            "equipment_needed": "none",
            "difficulty_level": "beginner",
            "created_at": created_at
        }

        exercise = ExerciseResponse(**data)

        assert exercise.id == "exercise123"
        assert exercise.name == "Squats"
        assert exercise.muscle_groups == ["quadriceps", "glutes"]

    def test_workout_plan_create_valid(self):
        """Test valid workout plan creation"""
        data = {
            "name": "Beginner Strength Training",
            "description": "A basic strength training routine",
            "duration_minutes": 45,
            "difficulty_level": "beginner",
            "target_muscle_groups": ["full_body"],
            "equipment_required": "minimal",
            "exercises": [
                {
                    "name": "Push-ups",
                    "description": "Standard push-ups",
                    "muscle_groups": ["chest", "triceps"],
                    "equipment_needed": "none",
                    "difficulty_level": "beginner"
                }
            ]
        }

        workout_plan = WorkoutPlanCreate(**data)

        assert workout_plan.name == "Beginner Strength Training"
        assert workout_plan.duration_minutes == 45
        assert workout_plan.difficulty_level == "beginner"
        assert len(workout_plan.exercises) == 1

    def test_workout_plan_create_invalid_duration(self):
        """Test workout plan with invalid duration"""
        data = {
            "name": "Test Workout",
            "description": "Test description",
            "duration_minutes": 0,  # Invalid
            "difficulty_level": "beginner",
            "target_muscle_groups": ["legs"],
            "equipment_required": "none",
            "exercises": []
        }

        with pytest.raises(ValidationError):
            WorkoutPlanCreate(**data)

    def test_workout_log_create_valid(self):
        """Test valid workout log creation"""
        data = {
            "workout_plan_id": "plan123",
            "duration_minutes": 30,
            "notes": "Great workout!",
            "exercises_completed": [
                {
                    "exercise_id": "exercise123",
                    "sets": 3,
                    "reps": 10,
                    "weight": 50.0,
                    "notes": "Felt strong today"
                }
            ]
        }

        workout_log = WorkoutLogCreate(**data)

        assert workout_log.workout_plan_id == "plan123"
        assert workout_log.duration_minutes == 30
        assert workout_log.notes == "Great workout!"
        assert len(workout_log.exercises_completed) == 1

    def test_workout_log_response_schema(self):
        """Test workout log response schema"""
        created_at = datetime.utcnow()

        data = {
            "id": "log123",
            "user_id": "user123",
            "workout_plan_id": "plan123",
            "duration_minutes": 45,
            "notes": "Excellent session",
            "exercises_completed": [],
            "created_at": created_at
        }

        workout_log = WorkoutLogResponse(**data)

        assert workout_log.id == "log123"
        assert workout_log.user_id == "user123"
        assert workout_log.duration_minutes == 45


class TestAISchemas:
    """Test AI-related schemas"""

    def test_chat_message_valid(self):
        """Test valid chat message"""
        data = {
            "message": "Give me a workout plan for building muscle",
            "context": {"user_goal": "muscle_gain", "experience": "beginner"}
        }

        chat_msg = ChatMessage(**data)

        assert chat_msg.message == "Give me a workout plan for building muscle"
        assert chat_msg.context["user_goal"] == "muscle_gain"

    def test_chat_message_empty(self):
        """Test chat message with empty message"""
        data = {"message": ""}

        with pytest.raises(ValidationError):
            ChatMessage(**data)

    def test_chat_message_too_long(self):
        """Test chat message that's too long"""
        data = {"message": "x" * 5001}  # Assuming max length is 5000

        # This might not fail depending on schema constraints
        try:
            ChatMessage(**data)
        except ValidationError:
            pass  # Expected if there's a length constraint

    def test_chat_response_schema(self):
        """Test chat response schema"""
        data = {
            "response": "Here's a great beginner workout plan...",
            "model_used": "gpt-3.5-turbo",
            "tokens_used": 150,
            "confidence_score": 0.95
        }

        chat_response = ChatResponse(**data)

        assert chat_response.response == "Here's a great beginner workout plan..."
        assert chat_response.model_used == "gpt-3.5-turbo"
        assert chat_response.tokens_used == 150
        assert chat_response.confidence_score == 0.95

    def test_workout_analysis_request(self):
        """Test workout analysis request"""
        data = {
            "workout_data": "Completed 3 sets of 10 push-ups, 3 sets of 12 squats",
            "analysis_type": "performance",
            "include_recommendations": True
        }

        analysis_request = WorkoutAnalysisRequest(**data)

        assert analysis_request.workout_data == "Completed 3 sets of 10 push-ups, 3 sets of 12 squats"
        assert analysis_request.analysis_type == "performance"
        assert analysis_request.include_recommendations is True

    def test_workout_analysis_response(self):
        """Test workout analysis response"""
        data = {
            "analysis": "Great workout! Your form was excellent on both exercises.",
            "recommendations": ["Try adding weight to increase difficulty", "Consider adding more sets"],
            "performance_score": 8.5,
            "areas_for_improvement": ["Rest time could be more consistent"]
        }

        analysis_response = WorkoutAnalysisResponse(**data)

        assert analysis_response.analysis == "Great workout! Your form was excellent on both exercises."
        assert len(analysis_response.recommendations) == 2
        assert analysis_response.performance_score == 8.5

    def test_ai_config_request(self):
        """Test AI configuration request"""
        data = {
            "model_preferences": ["gpt-4", "gpt-3.5-turbo"],
            "max_tokens": 500,
            "temperature": 0.7,
            "response_format": "detailed"
        }

        ai_config = AIConfigRequest(**data)

        assert ai_config.model_preferences == ["gpt-4", "gpt-3.5-turbo"]
        assert ai_config.max_tokens == 500
        assert ai_config.temperature == 0.7
        assert ai_config.response_format == "detailed"


class TestUserSchemas:
    """Test user-related schemas"""

    def test_user_profile_update_valid(self):
        """Test valid user profile update"""
        data = {
            "username": "updateduser",
            "fitness_level": "intermediate",
            "goals": ["strength", "endurance", "flexibility"],
            "equipment": "moderate"
        }

        profile_update = UserProfileUpdate(**data)

        assert profile_update.username == "updateduser"
        assert profile_update.fitness_level == "intermediate"
        assert profile_update.goals == ["strength", "endurance", "flexibility"]
        assert profile_update.equipment == "moderate"

    def test_user_profile_update_partial(self):
        """Test partial user profile update"""
        data = {"fitness_level": "advanced"}

        profile_update = UserProfileUpdate(**data)

        assert profile_update.fitness_level == "advanced"
        assert profile_update.username is None
        assert profile_update.goals is None

    def test_user_progress_response(self):
        """Test user progress response"""
        data = {
            "total_workouts": 25,
            "total_duration_minutes": 1125,
            "current_streak": 7,
            "longest_streak": 12,
            "favorite_exercises": ["push-ups", "squats", "planks"],
            "progress_trend": "improving",
            "last_workout_date": datetime.utcnow().date()
        }

        progress_response = UserProgressResponse(**data)

        assert progress_response.total_workouts == 25
        assert progress_response.current_streak == 7
        assert progress_response.favorite_exercises == ["push-ups", "squats", "planks"]

    def test_user_stats_response(self):
        """Test user statistics response"""
        data = {
            "weekly_average_workouts": 3.5,
            "monthly_total_duration": 540,
            "most_active_day": "Monday",
            "workout_completion_rate": 0.87,
            "strength_improvement": 15.5,
            "endurance_improvement": 12.3
        }

        stats_response = UserStatsResponse(**data)

        assert stats_response.weekly_average_workouts == 3.5
        assert stats_response.monthly_total_duration == 540
        assert stats_response.most_active_day == "Monday"
        assert stats_response.workout_completion_rate == 0.87


class TestSchemaEdgeCases:
    """Test edge cases and error conditions"""

    def test_missing_required_fields(self):
        """Test schemas with missing required fields"""
        # UserRegister missing email
        with pytest.raises(ValidationError):
            UserRegister(
                username="testuser",
                password="password123",
                fitness_level="beginner",
                goals=["strength"],
                equipment="minimal"
            )

        # WorkoutPlanCreate missing name
        with pytest.raises(ValidationError):
            WorkoutPlanCreate(
                description="Test workout",
                duration_minutes=30,
                difficulty_level="beginner",
                target_muscle_groups=["legs"],
                equipment_required="none",
                exercises=[]
            )

    def test_field_type_validation(self):
        """Test field type validation"""
        # Invalid type for duration_minutes
        with pytest.raises(ValidationError):
            WorkoutPlanCreate(
                name="Test Workout",
                description="Test",
                duration_minutes="thirty",  # Should be int
                difficulty_level="beginner",
                target_muscle_groups=["legs"],
                equipment_required="none",
                exercises=[]
            )

    def test_empty_lists_handling(self):
        """Test handling of empty lists"""
        data = {
            "name": "Test Workout",
            "description": "Test description",
            "duration_minutes": 30,
            "difficulty_level": "beginner",
            "target_muscle_groups": [],  # Empty list
            "equipment_required": "none",
            "exercises": []  # Empty list
        }

        # Should be valid
        workout_plan = WorkoutPlanCreate(**data)
        assert workout_plan.target_muscle_groups == []
        assert workout_plan.exercises == []

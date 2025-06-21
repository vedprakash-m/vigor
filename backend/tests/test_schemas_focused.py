"""
Focused Schema Tests
Tests actual Pydantic schemas for validation and edge cases
"""

from datetime import datetime

import pytest
from pydantic import ValidationError

from api.schemas.ai import ChatMessage, ChatResponse

# Import actual schemas
from api.schemas.auth import Token, TokenData, UserLogin, UserRegister, UserResponse
from api.schemas.users import (
    ProgressMetricCreate,
    UserProfileResponse,
    UserProfileUpdate,
)
from api.schemas.workouts import (
    AIWorkoutRequest,
    Exercise,
    ExerciseSet,
    WorkoutLogCreate,
    WorkoutPlan,
    WorkoutPlanCreate,
    WorkoutPlanRequest,
    WorkoutSession,
)
from database.models import Equipment, FitnessLevel, Goal


class TestAuthSchemas:
    """Test authentication schemas"""

    def test_user_register_valid(self):
        """Test valid user registration"""
        data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "StrongPassword123!",
            "fitness_level": "beginner",
            "goals": ["strength", "endurance"],
            "equipment": "minimal",
        }

        user = UserRegister(**data)

        assert user.email == "test@example.com"
        assert user.username == "testuser"
        assert user.fitness_level == "beginner"
        assert user.goals == ["strength", "endurance"]

    def test_user_register_validation_errors(self):
        """Test user registration validation errors"""
        # Invalid email
        with pytest.raises(ValidationError):
            UserRegister(
                email="invalid-email",
                username="testuser",
                password="StrongPassword123!",
                fitness_level="beginner",
                goals=["strength"],
                equipment="minimal",
            )

        # Short username
        with pytest.raises(ValidationError):
            UserRegister(
                email="test@example.com",
                username="ab",  # Too short
                password="StrongPassword123!",
                fitness_level="beginner",
                goals=["strength"],
                equipment="minimal",
            )

        # Short password
        with pytest.raises(ValidationError):
            UserRegister(
                email="test@example.com",
                username="testuser",
                password="short",  # Too short
                fitness_level="beginner",
                goals=["strength"],
                equipment="minimal",
            )

    def test_user_login_schema(self):
        """Test user login schema"""
        data = {"email": "test@example.com", "password": "password123"}

        login = UserLogin(**data)
        assert login.email == "test@example.com"
        assert login.password == "password123"

    def test_token_schema(self):
        """Test token schema"""
        expires_at = datetime.utcnow()
        data = {"access_token": "jwt_token_here", "expires_at": expires_at}

        token = Token(**data)
        assert token.access_token == "jwt_token_here"
        assert token.token_type == "bearer"  # Default value
        assert token.expires_at == expires_at

    def test_token_data_schema(self):
        """Test token data schema"""
        # With user_id
        token_data = TokenData(user_id="user123")
        assert token_data.user_id == "user123"

        # Without user_id (optional)
        token_data_none = TokenData()
        assert token_data_none.user_id is None


class TestWorkoutSchemas:
    """Test workout schemas"""

    def test_exercise_set_schema(self):
        """Test exercise set schema"""
        data = {
            "reps": "8-12",
            "weight": 50.0,
            "rest": "60 seconds",
            "notes": "Felt strong",
        }

        exercise_set = ExerciseSet(**data)
        assert exercise_set.reps == "8-12"
        assert exercise_set.weight == 50.0
        assert exercise_set.rest == "60 seconds"
        assert exercise_set.notes == "Felt strong"

    def test_exercise_set_optional_fields(self):
        """Test exercise set with optional fields"""
        # All optional fields can be None
        exercise_set = ExerciseSet()
        assert exercise_set.reps is None
        assert exercise_set.weight is None
        assert exercise_set.rest is None
        assert exercise_set.notes is None

    def test_exercise_schema(self):
        """Test exercise schema"""
        sets_data = [
            {"reps": "10", "weight": 45.0},
            {"reps": "10", "weight": 45.0},
            {"reps": "8", "weight": 50.0},
        ]

        data = {
            "name": "Bench Press",
            "muscle_groups": ["chest", "triceps", "shoulders"],
            "sets": sets_data,
            "instructions": "Keep your back flat on the bench",
        }

        exercise = Exercise(**data)
        assert exercise.name == "Bench Press"
        assert exercise.muscle_groups == ["chest", "triceps", "shoulders"]
        assert len(exercise.sets) == 3
        assert exercise.instructions == "Keep your back flat on the bench"

    def test_workout_plan_schema(self):
        """Test workout plan schema"""
        exercise_data = {
            "name": "Push-ups",
            "muscle_groups": ["chest", "triceps"],
            "sets": [{"reps": "10"}],
        }

        data = {
            "name": "Upper Body Workout",
            "description": "Focus on upper body strength",
            "exercises": [exercise_data],
            "estimated_duration_minutes": 45,
            "difficulty_level": "intermediate",
            "equipment_needed": ["dumbbells"],
            "notes": "Great for building strength",
        }

        workout = WorkoutPlan(**data)
        assert workout.name == "Upper Body Workout"
        assert workout.estimated_duration_minutes == 45
        assert workout.difficulty_level == "intermediate"
        assert len(workout.exercises) == 1

    def test_workout_plan_validation(self):
        """Test workout plan validation"""
        # Invalid duration (must be > 0)
        with pytest.raises(ValidationError):
            WorkoutPlan(
                name="Test Workout",
                description="Test",
                exercises=[],
                estimated_duration_minutes=0,  # Invalid
                difficulty_level="beginner",
            )

        # Invalid difficulty level
        with pytest.raises(ValidationError):
            WorkoutPlan(
                name="Test Workout",
                description="Test",
                exercises=[],
                estimated_duration_minutes=30,
                difficulty_level="superhuman",  # Invalid
            )

    def test_workout_plan_request_schema(self):
        """Test workout plan request schema"""
        data = {
            "goals": ["strength", "muscle_gain"],
            "fitness_level": "intermediate",
            "available_equipment": ["dumbbells", "barbell"],
            "duration_minutes": 60,
            "focus_areas": ["upper_body"],
            "notes": "I want to focus on compound movements",
        }

        request = WorkoutPlanRequest(**data)
        assert request.goals == ["strength", "muscle_gain"]
        assert request.fitness_level == "intermediate"
        assert request.duration_minutes == 60

    def test_workout_plan_request_validation(self):
        """Test workout plan request validation"""
        # Duration too short
        with pytest.raises(ValidationError):
            WorkoutPlanRequest(
                goals=["strength"],
                fitness_level="beginner",
                available_equipment=[],
                duration_minutes=10,  # Too short (minimum 15)
            )

        # Duration too long
        with pytest.raises(ValidationError):
            WorkoutPlanRequest(
                goals=["strength"],
                fitness_level="beginner",
                available_equipment=[],
                duration_minutes=150,  # Too long (maximum 120)
            )

    def test_workout_log_create_schema(self):
        """Test workout log creation schema"""
        exercise_data = {
            "name": "Squats",
            "muscle_groups": ["quadriceps"],
            "sets": [{"reps": "12", "weight": 100.0}],
        }

        data = {
            "plan_id": "plan123",
            "duration_minutes": 45,
            "exercises": [exercise_data],
            "notes": "Great workout session!",
            "rating": 5,
        }

        log = WorkoutLogCreate(**data)
        assert log.plan_id == "plan123"
        assert log.duration_minutes == 45
        assert log.rating == 5

    def test_workout_log_validation(self):
        """Test workout log validation"""
        # Invalid duration
        with pytest.raises(ValidationError):
            WorkoutLogCreate(
                plan_id="plan123", duration_minutes=0, exercises=[]  # Invalid
            )

        # Invalid rating
        with pytest.raises(ValidationError):
            WorkoutLogCreate(
                plan_id="plan123",
                duration_minutes=30,
                exercises=[],
                rating=6,  # Invalid (max 5)
            )

    def test_ai_workout_request_schema(self):
        """Test AI workout request schema"""
        data = {
            "goals": ["fat_loss", "endurance"],
            "equipment": "minimal",
            "duration_minutes": 30,
            "focus_areas": ["cardio", "core"],
        }

        request = AIWorkoutRequest(**data)
        assert request.goals == ["fat_loss", "endurance"]
        assert request.equipment == "minimal"
        assert request.duration_minutes == 30


class TestUserSchemas:
    """Test user schemas"""

    def test_user_profile_update_schema(self):
        """Test user profile update schema"""
        data = {
            "fitness_level": FitnessLevel.INTERMEDIATE,
            "goals": [Goal.STRENGTH, Goal.MUSCLE_GAIN],
            "equipment": Equipment.MODERATE,
            "injuries": ["lower_back"],
            "preferences": {"workout_time": "morning", "music": True},
        }

        update = UserProfileUpdate(**data)
        assert update.fitness_level == FitnessLevel.INTERMEDIATE
        assert Goal.STRENGTH in update.goals
        assert update.equipment == Equipment.MODERATE

    def test_user_profile_update_partial(self):
        """Test partial user profile update"""
        # Only updating fitness level
        update = UserProfileUpdate(fitness_level=FitnessLevel.ADVANCED)
        assert update.fitness_level == FitnessLevel.ADVANCED
        assert update.goals is None
        assert update.equipment is None

    def test_progress_metric_create_schema(self):
        """Test progress metric creation schema"""
        data = {
            "weight": 175.5,
            "body_fat": 15.2,
            "measurements": {"chest": 42.0, "waist": 34.0},
            "notes": "Feeling stronger this week",
        }

        metric = ProgressMetricCreate(**data)
        assert metric.weight == 175.5
        assert metric.body_fat == 15.2
        assert metric.measurements["chest"] == 42.0

    def test_progress_metric_all_optional(self):
        """Test progress metric with all optional fields"""
        # All fields are optional
        metric = ProgressMetricCreate()
        assert metric.weight is None
        assert metric.body_fat is None
        assert metric.measurements is None
        assert metric.notes is None


class TestAISchemas:
    """Test AI schemas"""

    def test_chat_message_schema(self):
        """Test chat message schema"""
        data = {
            "message": "Give me a workout plan for building muscle",
            "context": {"user_goal": "muscle_gain"},
        }

        chat_msg = ChatMessage(**data)
        assert chat_msg.message == "Give me a workout plan for building muscle"
        assert chat_msg.context["user_goal"] == "muscle_gain"

    def test_chat_response_schema(self):
        """Test chat response schema"""
        data = {
            "response": "Here's a great muscle-building workout...",
            "model_used": "gpt-3.5-turbo",
            "tokens_used": 150,
            "confidence_score": 0.92,
        }

        response = ChatResponse(**data)
        assert response.response == "Here's a great muscle-building workout..."
        assert response.model_used == "gpt-3.5-turbo"
        assert response.tokens_used == 150


class TestSchemaEdgeCases:
    """Test edge cases and error handling"""

    def test_empty_lists(self):
        """Test schemas with empty lists"""
        # Exercise with empty muscle_groups should fail
        with pytest.raises(ValidationError):
            Exercise(
                name="Test Exercise",
                muscle_groups=[],  # Empty list might be invalid
                sets=[],
            )

    def test_missing_required_fields(self):
        """Test missing required fields"""
        # Missing required fields should raise ValidationError
        with pytest.raises(ValidationError):
            WorkoutPlan(
                # Missing name
                description="Test workout",
                exercises=[],
                estimated_duration_minutes=30,
                difficulty_level="beginner",
            )

    def test_field_constraints(self):
        """Test field constraints"""
        # Test string length constraints
        with pytest.raises(ValidationError):
            WorkoutPlanCreate(
                name="",  # Empty name should fail min_length constraint
                description="Test",
                exercises=[],
                duration_minutes=30,
            )

    def test_numeric_constraints(self):
        """Test numeric field constraints"""
        # Test positive number constraints
        with pytest.raises(ValidationError):
            WorkoutLogCreate(
                plan_id="plan123",
                duration_minutes=-10,  # Negative duration should fail
                exercises=[],
            )

        # Test rating bounds
        with pytest.raises(ValidationError):
            WorkoutLogCreate(
                plan_id="plan123",
                duration_minutes=30,
                exercises=[],
                rating=0,  # Below minimum rating
            )

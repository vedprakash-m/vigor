"""Basic model and schema tests"""

from datetime import datetime

import pytest

from api.schemas.auth import UserLogin, UserRegister
from api.schemas.workouts import Exercise, ExerciseSet
from database.models import Equipment, FitnessLevel, Goal, UserProfile, UserTier


def test_user_tier_enum():
    """Test UserTier enum values"""
    assert UserTier.FREE.value == "free"
    assert UserTier.PREMIUM.value == "premium"
    assert UserTier.UNLIMITED.value == "unlimited"


def test_fitness_level_enum():
    """Test FitnessLevel enum values"""
    assert FitnessLevel.BEGINNER.value == "beginner"
    assert FitnessLevel.INTERMEDIATE.value == "intermediate"
    assert FitnessLevel.ADVANCED.value == "advanced"


def test_goal_enum():
    """Test Goal enum values"""
    assert Goal.WEIGHT_LOSS.value == "weight_loss"
    assert Goal.MUSCLE_GAIN.value == "muscle_gain"
    assert Goal.STRENGTH.value == "strength"
    assert Goal.ENDURANCE.value == "endurance"


def test_equipment_enum():
    """Test Equipment enum values"""
    assert Equipment.NONE.value == "none"
    assert Equipment.DUMBBELLS.value == "dumbbells"
    assert Equipment.RESISTANCE_BANDS.value == "resistance_bands"
    assert Equipment.PULL_UP_BAR.value == "pull_up_bar"
    assert Equipment.FULL_GYM.value == "full_gym"


def test_user_profile_creation():
    """Test UserProfile model creation"""
    user = UserProfile(
        email="test@example.com",
        username="testuser",
        hashed_password="hashed_pwd",
        is_active=True,
        user_tier=UserTier.FREE,
        fitness_level=FitnessLevel.BEGINNER,
        goals=[Goal.STRENGTH],
        equipment=[Equipment.DUMBBELLS],
    )

    assert user.email == "test@example.com"
    assert user.username == "testuser"
    assert user.is_active is True
    assert user.user_tier == UserTier.FREE
    assert user.fitness_level == FitnessLevel.BEGINNER


def test_user_register_schema():
    """Test UserRegister schema"""
    data = UserRegister(
        email="test@example.com",
        username="testuser",
        password="StrongPassword123!",
        fitness_level="beginner",
        goals=["strength"],
        equipment="minimal",
    )

    assert data.email == "test@example.com"
    assert data.username == "testuser"
    assert data.fitness_level == "beginner"


def test_user_login_schema():
    """Test UserLogin schema"""
    data = UserLogin(email="test@example.com", password="password123")

    assert data.email == "test@example.com"
    assert data.password == "password123"


def test_exercise_set_schema():
    """Test ExerciseSet schema"""
    data = ExerciseSet(reps="10", weight=50.0, rest="60 seconds")

    assert data.reps == "10"
    assert data.weight == 50.0
    assert data.rest == "60 seconds"


def test_exercise_set_optional_fields():
    """Test ExerciseSet with optional fields"""
    data = ExerciseSet()

    assert data.reps is None
    assert data.weight is None
    assert data.rest is None
    assert data.notes is None


def test_exercise_schema():
    """Test Exercise schema"""
    sets_data = [
        ExerciseSet(reps="10", weight=45.0),
        ExerciseSet(reps="8", weight=50.0),
    ]

    data = Exercise(
        name="Bench Press", muscle_groups=["chest", "triceps"], sets=sets_data
    )

    assert data.name == "Bench Press"
    assert data.muscle_groups == ["chest", "triceps"]
    assert len(data.sets) == 2

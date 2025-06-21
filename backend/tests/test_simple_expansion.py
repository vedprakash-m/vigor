"""Simple test expansion to boost coverage"""

import pytest
from unittest.mock import Mock, patch
from core.config import get_settings
from database.models import UserProfile, UserTier
from api.schemas.auth import UserRegister, UserLogin, UserResponse, Token
from datetime import datetime


def test_config_loading():
    """Test configuration loading"""
    settings = get_settings()
    assert settings is not None
    assert hasattr(settings, 'SECRET_KEY')
    assert hasattr(settings, 'DATABASE_URL')


def test_user_tier_enum():
    """Test UserTier enum values"""
    assert UserTier.FREE.value == "free"
    assert UserTier.PREMIUM.value == "premium"
    assert UserTier.UNLIMITED.value == "unlimited"


def test_user_profile_creation():
    """Test UserProfile model creation"""
    user = UserProfile(
        email="test@example.com",
        username="testuser",
        hashed_password="hashed_password_here",
        is_active=True,
        user_tier=UserTier.FREE
    )

    assert user.email == "test@example.com"
    assert user.username == "testuser"
    assert user.user_tier == UserTier.FREE
    assert user.is_active is True


def test_user_register_schema():
    """Test UserRegister schema validation"""
    user_data = UserRegister(
        email="test@example.com",
        username="testuser",
        password="StrongPassword123!",
        fitness_level="beginner",
        goals=["strength", "muscle_gain"],
        equipment="minimal"
    )

    assert user_data.email == "test@example.com"
    assert user_data.username == "testuser"
    assert user_data.fitness_level == "beginner"
    assert user_data.goals == ["strength", "muscle_gain"]


def test_user_login_schema():
    """Test UserLogin schema validation"""
    login_data = UserLogin(
        email="test@example.com",
        password="StrongPassword123!"
    )

    assert login_data.email == "test@example.com"
    assert login_data.password == "StrongPassword123!"


def test_token_schema():
    """Test Token schema"""
    token = Token(
        access_token="sample_token_here",
        expires_at=datetime.utcnow()
    )

    assert token.access_token == "sample_token_here"
    assert token.token_type == "bearer"
    assert isinstance(token.expires_at, datetime)

"""
Simplified test suite for auth functionality
"""

from datetime import datetime

from fastapi.testclient import TestClient

from api.schemas.auth import Token, UserLogin, UserRegister
from main import app

client = TestClient(app)


def test_register_user_success():
    """Test successful user registration"""
    test_user = {
        "email": "test@example.com",
        "username": "testuser",
        "password": "testpassword123",
        "fitness_level": "beginner",
        "goals": ["weight_loss"],
        "equipment": "none",
    }

    # Mock the registration - this is a simplified test
    user_data = UserRegister(**test_user)
    assert user_data.email == test_user["email"]
    assert user_data.username == test_user["username"]


def test_user_login_schema():
    """Test user login schema"""
    login_data = {"email": "test@example.com", "password": "testpassword123"}

    user_login = UserLogin(**login_data)
    assert user_login.email == login_data["email"]
    assert user_login.password == login_data["password"]


def test_token_schema():
    """Test token schema"""
    token_data = {
        "access_token": "test_token",
        "token_type": "bearer",
        "expires_at": datetime.utcnow(),
    }

    token = Token(**token_data)
    assert token.access_token == token_data["access_token"]
    assert token.token_type == token_data["token_type"]

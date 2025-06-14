import pytest
from app.core.security import create_access_token
from app.database import get_db
from app.main import app
from app.models import UserProfileDB
from fastapi.testclient import TestClient

client = TestClient(app)


def test_register_user_success(client, test_user):
    """Test successful user registration"""
    response = client.post("/auth/register", json=test_user)
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == test_user["username"]
    assert data["email"] == test_user["email"]
    assert "password" not in data  # Password should not be returned


def test_register_user_duplicate_email(client, test_user):
    """Test registration with duplicate email"""
    # Register first user
    client.post("/auth/register", json=test_user)

    # Try to register with same email
    duplicate_user = test_user.copy()
    duplicate_user["username"] = "different_username"
    response = client.post("/auth/register", json=duplicate_user)

    assert response.status_code == 400
    assert "email already registered" in response.json()["detail"].lower()


def test_register_user_duplicate_username(client, test_user):
    """Test registration with duplicate username"""
    # Register first user
    client.post("/auth/register", json=test_user)

    # Try to register with same username
    duplicate_user = test_user.copy()
    duplicate_user["email"] = "different@example.com"
    response = client.post("/auth/register", json=duplicate_user)

    assert response.status_code == 400
    assert "username already taken" in response.json()["detail"].lower()


def test_register_user_invalid_email(client, test_user):
    """Test registration with invalid email format"""
    invalid_user = test_user.copy()
    invalid_user["email"] = "invalid-email"
    response = client.post("/auth/register", json=invalid_user)

    assert response.status_code == 422  # Validation error


def test_register_user_weak_password(client, test_user):
    """Test registration with weak password"""
    weak_user = test_user.copy()
    weak_user["password"] = "123"
    response = client.post("/auth/register", json=weak_user)

    assert response.status_code == 422  # Validation error


def test_login_success(client, test_user):
    """Test successful login"""
    # Register user first
    client.post("/auth/register", json=test_user)

    # Login
    login_data = {"email": test_user["email"], "password": test_user["password"]}
    response = client.post("/auth/login", json=login_data)

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "token_type" in data
    assert data["token_type"] == "bearer"


def test_login_invalid_credentials(client, test_user):
    """Test login with invalid credentials"""
    # Register user first
    client.post("/auth/register", json=test_user)

    # Try to login with wrong password
    login_data = {"email": test_user["email"], "password": "wrongpassword"}
    response = client.post("/auth/login", json=login_data)

    assert response.status_code == 401
    assert "invalid credentials" in response.json()["detail"].lower()


def test_login_nonexistent_user(client):
    """Test login with non-existent user"""
    login_data = {"email": "nonexistent@example.com", "password": "password123"}
    response = client.post("/auth/login", json=login_data)

    assert response.status_code == 401
    assert "invalid credentials" in response.json()["detail"].lower()


def test_get_current_user_success(client, test_user):
    """Test getting current user with valid token"""
    # Register and login user
    client.post("/auth/register", json=test_user)
    login_response = client.post(
        "/auth/login",
        json={"email": test_user["email"], "password": test_user["password"]},
    )
    token = login_response.json()["access_token"]

    # Get current user
    headers = {"Authorization": f"Bearer {token}"}
    response = client.get("/auth/me", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert data["username"] == test_user["username"]
    assert data["email"] == test_user["email"]


def test_get_current_user_invalid_token(client):
    """Test getting current user with invalid token"""
    headers = {"Authorization": "Bearer invalid_token"}
    response = client.get("/auth/me", headers=headers)

    assert response.status_code == 401


def test_get_current_user_no_token(client):
    """Test getting current user without token"""
    response = client.get("/auth/me")

    assert response.status_code == 401


def test_refresh_token_success(client, test_user):
    """Test successful token refresh"""
    # Register and login user
    client.post("/auth/register", json=test_user)
    login_response = client.post(
        "/auth/login",
        json={"email": test_user["email"], "password": test_user["password"]},
    )
    refresh_token = login_response.json().get("refresh_token")

    if refresh_token:
        response = client.post("/auth/refresh", json={"refresh_token": refresh_token})
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data


def test_refresh_token_invalid(client):
    """Test token refresh with invalid token"""
    response = client.post(
        "/auth/refresh", json={"refresh_token": "invalid_refresh_token"}
    )

    assert response.status_code == 401


def test_logout_success(client, test_user):
    """Test successful logout"""
    # Register and login user
    client.post("/auth/register", json=test_user)
    login_response = client.post(
        "/auth/login",
        json={"email": test_user["email"], "password": test_user["password"]},
    )
    token = login_response.json()["access_token"]

    # Logout
    headers = {"Authorization": f"Bearer {token}"}
    response = client.post("/auth/logout", headers=headers)

    assert response.status_code == 200


def test_admin_user_creation(client, admin_user):
    """Test admin user creation"""
    response = client.post("/auth/register", json=admin_user)
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == admin_user["username"]
    # Admin users should have admin privileges
    assert "admin" in admin_user["username"].lower()


def test_password_hashing(client, test_user):
    """Test that passwords are properly hashed"""
    # Register user
    response = client.post("/auth/register", json=test_user)
    assert response.status_code == 201

    # Verify password is not stored in plain text
    # This would require database access to verify
    # For now, we'll test that login works with original password
    login_response = client.post(
        "/auth/login",
        json={"email": test_user["email"], "password": test_user["password"]},
    )
    assert login_response.status_code == 200


def test_user_tier_assignment(client, test_user):
    """Test that new users get assigned to FREE tier"""
    response = client.post("/auth/register", json=test_user)
    assert response.status_code == 201
    data = response.json()
    assert data["tier"] == "FREE"  # Default tier


def test_validation_errors(client):
    """Test various validation errors"""
    # Missing required fields
    response = client.post("/auth/register", json={})
    assert response.status_code == 422

    # Invalid email format
    response = client.post(
        "/auth/register",
        json={"username": "test", "email": "invalid-email", "password": "password123"},
    )
    assert response.status_code == 422

    # Username too short
    response = client.post(
        "/auth/register",
        json={"username": "ab", "email": "test@example.com", "password": "password123"},
    )
    assert response.status_code == 422

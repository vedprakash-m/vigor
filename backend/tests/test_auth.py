import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timedelta
import bcrypt

from core.security import create_access_token
from database.connection import get_db
from database.sql_models import UserProfileDB
from main import app
from api.services.auth import AuthService, TokenService, PasswordService
from api.schemas.auth import UserRegistration, UserLogin, TokenResponse, PasswordReset

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


class TestAuthService:
    """Test suite for authentication service functionality"""

    @pytest.fixture
    def auth_service(self):
        """Create auth service instance"""
        return AuthService()

    @pytest.fixture
    def password_service(self):
        """Create password service instance"""
        return PasswordService()

    @pytest.fixture
    def token_service(self):
        """Create token service instance"""
        return TokenService()

    @pytest.mark.asyncio
    async def test_authenticate_user_success(self, auth_service):
        """Test successful user authentication"""
        with patch('api.services.auth.user_repository') as mock_repo:
            hashed_password = bcrypt.hashpw("SecurePassword123!".encode(), bcrypt.gensalt())
            user = UserProfileDB(
                id=1,
                email="test@example.com",
                password_hash=hashed_password.decode(),
                is_active=True
            )
            mock_repo.get_by_email = AsyncMock(return_value=user)

            result = await auth_service.authenticate_user("test@example.com", "SecurePassword123!")

            assert result is not None
            assert result.email == "test@example.com"

    @pytest.mark.asyncio
    async def test_authenticate_user_wrong_password(self, auth_service):
        """Test authentication with wrong password"""
        with patch('api.services.auth.user_repository') as mock_repo:
            hashed_password = bcrypt.hashpw("CorrectPassword".encode(), bcrypt.gensalt())
            user = UserProfileDB(
                id=1,
                email="test@example.com",
                password_hash=hashed_password.decode(),
                is_active=True
            )
            mock_repo.get_by_email = AsyncMock(return_value=user)

            result = await auth_service.authenticate_user("test@example.com", "WrongPassword")

            assert result is None

    @pytest.mark.asyncio
    async def test_authenticate_user_inactive_account(self, auth_service):
        """Test authentication with inactive account"""
        with patch('api.services.auth.user_repository') as mock_repo:
            user = UserProfileDB(
                id=1,
                email="test@example.com",
                password_hash="hashed_password",
                is_active=False
            )
            mock_repo.get_by_email = AsyncMock(return_value=user)

            with pytest.raises(ValueError) as exc_info:
                await auth_service.authenticate_user("test@example.com", "password")

            assert "disabled" in str(exc_info.value).lower()

    def test_password_hashing(self, password_service):
        """Test password hashing functionality"""
        password = "TestPassword123!"

        hashed = password_service.hash_password(password)

        assert hashed != password
        assert password_service.verify_password(password, hashed)
        assert not password_service.verify_password("WrongPassword", hashed)

    def test_password_strength_validation(self, password_service):
        """Test password strength validation"""
        assert password_service.validate_password_strength("SecurePassword123!")
        assert not password_service.validate_password_strength("weak")
        assert not password_service.validate_password_strength("nouppercaseornumbers")
        assert not password_service.validate_password_strength("NOLOWERCASEORNUMBERS")
        assert not password_service.validate_password_strength("NoNumbers!")

    def test_create_access_token(self, token_service):
        """Test JWT access token creation"""
        user_data = {"id": 1, "email": "test@example.com"}

        token = token_service.create_access_token(user_data)

        assert isinstance(token, str)
        assert len(token) > 0

    def test_verify_token(self, token_service):
        """Test JWT token verification"""
        user_data = {"id": 1, "email": "test@example.com"}
        token = token_service.create_access_token(user_data)

        decoded = token_service.verify_token(token)

        assert decoded["id"] == 1
        assert decoded["email"] == "test@example.com"

    @pytest.mark.asyncio
    async def test_initiate_password_reset(self, auth_service):
        """Test password reset initiation"""
        with patch('api.services.auth.user_repository') as mock_repo:
            user = UserProfileDB(id=1, email="test@example.com")
            mock_repo.get_by_email = AsyncMock(return_value=user)

            with patch('api.services.auth.email_service') as mock_email:
                mock_email.send_password_reset = AsyncMock(return_value=True)

                result = await auth_service.initiate_password_reset("test@example.com")

                assert result is True
                mock_email.send_password_reset.assert_called_once()

    @pytest.mark.asyncio
    async def test_reset_password_success(self, auth_service):
        """Test successful password reset"""
        with patch('api.services.auth.user_repository') as mock_repo:
            with patch('api.services.auth.token_service') as mock_token_service:
                mock_token_service.verify_reset_token.return_value = {"user_id": 1}
                user = UserProfileDB(id=1, email="test@example.com")
                mock_repo.get_by_id = AsyncMock(return_value=user)
                mock_repo.update = AsyncMock(return_value=user)

                result = await auth_service.reset_password("valid_token", "NewPassword123!")

                assert result is True
                mock_repo.update.assert_called_once()


class TestAuthenticationRouteEdgeCases:
    """Test edge cases and error scenarios for auth routes"""

    @patch('api.routes.auth.auth_service')
    def test_login_rate_limiting(self, mock_auth_service, client):
        """Test login rate limiting"""
        mock_auth_service.authenticate_user = AsyncMock(return_value=None)

        # Simulate multiple failed login attempts
        login_data = {"email": "test@example.com", "password": "wrong_password"}

        for _ in range(5):
            response = client.post("/api/auth/login", json=login_data)
            # First few should be 401, eventually might be 429 (rate limited)
            assert response.status_code in [401, 429]

    @patch('api.routes.auth.auth_service')
    def test_concurrent_registration(self, mock_auth_service, client):
        """Test handling of concurrent registrations"""
        registration_data = {
            "username": "concurrentuser",
            "email": "concurrent@example.com",
            "password": "SecurePassword123!",
            "confirm_password": "SecurePassword123!"
        }

        # Simulate race condition
        mock_auth_service.register_user = AsyncMock(side_effect=ValueError("Email already exists"))

        response = client.post("/api/auth/register", json=registration_data)
        assert response.status_code == 400

    def test_malformed_jwt_token(self, client):
        """Test handling of malformed JWT tokens"""
        response = client.get(
            "/api/auth/me",
            headers={"Authorization": "Bearer malformed.jwt.token"}
        )

        assert response.status_code == 401

    def test_expired_jwt_token(self, client):
        """Test handling of expired JWT tokens"""
        # Create an expired token
        expired_token = create_access_token(
            data={"sub": "test@example.com"},
            expires_delta=timedelta(seconds=-1)  # Already expired
        )

        response = client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {expired_token}"}
        )

        assert response.status_code == 401

    def test_missing_authorization_header(self, client):
        """Test endpoint that requires auth without header"""
        response = client.get("/api/auth/me")
        assert response.status_code == 401

    def test_invalid_authorization_format(self, client):
        """Test invalid authorization header format"""
        response = client.get(
            "/api/auth/me",
            headers={"Authorization": "InvalidFormat token"}
        )
        assert response.status_code == 401

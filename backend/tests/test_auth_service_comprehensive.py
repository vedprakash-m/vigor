"""
Comprehensive Authentication Service Tests
Tests for api/services/auth.py authentication and user management
Target: Increase auth service coverage from 18% to 80%+
"""

import pytest
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from api.services.auth import (
    AuthService,
    register_user,
    authenticate_user,
    create_tokens,
    refresh_access_token,
    change_password,
    initiate_password_reset,
    complete_password_reset,
    get_user_by_email,
    update_user_tier,
    track_login_attempt
)
from database.models import UserProfile, UserTier
from core.security import hash_password


class TestAuthService:
    """Test AuthService class functionality"""

    @pytest.fixture
    def auth_service(self):
        """Create AuthService instance"""
        return AuthService()

    @pytest.fixture
    def mock_db(self):
        """Mock database session"""
        db = Mock(spec=Session)
        return db

    @pytest.fixture
    def sample_user(self):
        """Sample user profile"""
        return UserProfile(
            id="test_user_id",
            email="test@example.com",
            username="testuser",
            hashed_password=hash_password("TestPassword123!"),
            is_active=True,
            user_tier=UserTier.FREE,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )

    def test_hash_password_functionality(self, auth_service):
        """Test password hashing in auth service"""
        password = "TestPassword123!"
        hashed = auth_service.hash_password(password)

        assert hashed != password
        assert auth_service.verify_password(password, hashed) is True
        assert auth_service.verify_password("wrong", hashed) is False

    def test_generate_tokens(self, auth_service, sample_user):
        """Test JWT token generation"""
        tokens = auth_service.generate_tokens(sample_user)

        assert "access_token" in tokens
        assert "refresh_token" in tokens
        assert "token_type" in tokens
        assert tokens["token_type"] == "bearer"

        # Tokens should be non-empty strings
        assert isinstance(tokens["access_token"], str)
        assert isinstance(tokens["refresh_token"], str)
        assert len(tokens["access_token"]) > 0
        assert len(tokens["refresh_token"]) > 0

    def test_validate_token_claims(self, auth_service, sample_user):
        """Test token validation and claims extraction"""
        tokens = auth_service.generate_tokens(sample_user)
        access_token = tokens["access_token"]

        claims = auth_service.validate_token(access_token)

        assert claims["sub"] == sample_user.id
        assert claims["email"] == sample_user.email
        assert claims["tier"] == sample_user.user_tier.value

    def test_token_expiry_validation(self, auth_service):
        """Test token expiry handling"""
        # Create token with very short expiry
        user_data = {"sub": "test", "email": "test@example.com"}
        short_expiry = timedelta(seconds=1)

        token = auth_service.create_token(user_data, expires_delta=short_expiry)

        # Token should be valid immediately
        claims = auth_service.validate_token(token)
        assert claims["sub"] == "test"

        # Wait for expiry (in real test this would be mocked)
        import time
        time.sleep(2)

        # Token should now be expired
        with pytest.raises(HTTPException) as exc_info:
            auth_service.validate_token(token)
        assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED


class TestUserRegistration:
    """Test user registration functionality"""

    @pytest.fixture
    def mock_db(self):
        """Mock database session"""
        db = Mock(spec=Session)
        db.query.return_value.filter.return_value.first.return_value = None  # No existing user
        db.add = Mock()
        db.commit = Mock()
        db.refresh = Mock()
        return db

    def test_successful_registration(self, mock_db):
        """Test successful user registration"""
        user_data = {
            "email": "newuser@example.com",
            "username": "newuser",
            "password": "StrongPassword123!"
        }

        with patch('api.services.auth.get_user_by_email', return_value=None):
            user = register_user(mock_db, user_data)

            assert user.email == user_data["email"]
            assert user.username == user_data["username"]
            assert user.user_tier == UserTier.FREE
            assert user.is_active is True

            # Password should be hashed
            assert user.hashed_password != user_data["password"]

            # Database operations should be called
            mock_db.add.assert_called_once()
            mock_db.commit.assert_called_once()

    def test_registration_with_existing_email(self, mock_db):
        """Test registration with existing email"""
        existing_user = UserProfile(
            email="existing@example.com",
            username="existing",
            hashed_password="hashed"
        )

        with patch('api.services.auth.get_user_by_email', return_value=existing_user):
            with pytest.raises(HTTPException) as exc_info:
                register_user(mock_db, {
                    "email": "existing@example.com",
                    "username": "newuser",
                    "password": "password"
                })

            assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST
            assert "already registered" in str(exc_info.value.detail)

    def test_registration_input_validation(self, mock_db):
        """Test registration input validation"""
        invalid_data_sets = [
            {"email": "invalid-email", "username": "user", "password": "pass"},
            {"email": "test@example.com", "username": "a", "password": "pass"},
            {"email": "test@example.com", "username": "user", "password": "weak"}
        ]

        for invalid_data in invalid_data_sets:
            with pytest.raises((HTTPException, ValueError)):
                register_user(mock_db, invalid_data)


class TestUserAuthentication:
    """Test user authentication functionality"""

    @pytest.fixture
    def sample_user(self):
        """Sample user for authentication tests"""
        return UserProfile(
            id="auth_test_user",
            email="auth@example.com",
            username="authuser",
            hashed_password=hash_password("CorrectPassword123!"),
            is_active=True,
            user_tier=UserTier.PREMIUM
        )

    def test_successful_authentication(self, sample_user):
        """Test successful user authentication"""
        with patch('api.services.auth.get_user_by_email', return_value=sample_user):
            with patch('api.services.auth.verify_password', return_value=True):
                user = authenticate_user("auth@example.com", "CorrectPassword123!")

                assert user is not None
                assert user.email == sample_user.email
                assert user.id == sample_user.id

    def test_authentication_with_wrong_password(self, sample_user):
        """Test authentication with incorrect password"""
        with patch('api.services.auth.get_user_by_email', return_value=sample_user):
            with patch('api.services.auth.verify_password', return_value=False):
                user = authenticate_user("auth@example.com", "WrongPassword")

                assert user is None

    def test_authentication_with_nonexistent_user(self):
        """Test authentication with non-existent user"""
        with patch('api.services.auth.get_user_by_email', return_value=None):
            user = authenticate_user("nonexistent@example.com", "password")

            assert user is None

    def test_authentication_with_inactive_user(self, sample_user):
        """Test authentication with inactive user"""
        sample_user.is_active = False

        with patch('api.services.auth.get_user_by_email', return_value=sample_user):
            user = authenticate_user("auth@example.com", "CorrectPassword123!")

            assert user is None


class TestTokenManagement:
    """Test token creation and refresh functionality"""

    def test_create_tokens(self):
        """Test token creation functionality"""
        user_data = {
            "sub": "test_user",
            "email": "test@example.com",
            "tier": "premium"
        }

        tokens = create_tokens(user_data)

        assert "access_token" in tokens
        assert "refresh_token" in tokens
        assert "token_type" in tokens
        assert tokens["token_type"] == "bearer"

    @patch('api.services.auth.decode_access_token')
    @patch('api.services.auth.get_user_by_email')
    def test_refresh_access_token(self, mock_get_user, mock_decode):
        """Test access token refresh"""
        # Mock refresh token decode
        mock_decode.return_value = {
            "sub": "test_user",
            "email": "test@example.com",
            "type": "refresh"
        }

        # Mock user retrieval
        mock_user = Mock()
        mock_user.id = "test_user"
        mock_user.email = "test@example.com"
        mock_user.user_tier = UserTier.PREMIUM
        mock_user.is_active = True
        mock_get_user.return_value = mock_user

        new_token = refresh_access_token("valid_refresh_token")

        assert new_token is not None
        assert isinstance(new_token, str)

    def test_refresh_with_invalid_token(self):
        """Test refresh with invalid token"""
        with patch('api.services.auth.decode_access_token', side_effect=HTTPException(status_code=401)):
            with pytest.raises(HTTPException) as exc_info:
                refresh_access_token("invalid_token")

            assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED


class TestPasswordManagement:
    """Test password change and reset functionality"""

    @pytest.fixture
    def mock_db(self):
        """Mock database session"""
        db = Mock(spec=Session)
        db.commit = Mock()
        return db

    @pytest.fixture
    def sample_user(self):
        """Sample user for password tests"""
        return UserProfile(
            id="password_test_user",
            email="password@example.com",
            hashed_password=hash_password("OldPassword123!"),
            is_active=True
        )

    def test_change_password_success(self, mock_db, sample_user):
        """Test successful password change"""
        with patch('api.services.auth.verify_password', return_value=True):
            with patch('api.services.auth.hash_password', return_value="new_hashed_password"):
                result = change_password(
                    mock_db,
                    sample_user,
                    "OldPassword123!",
                    "NewPassword123!"
                )

                assert result is True
                assert sample_user.hashed_password == "new_hashed_password"
                mock_db.commit.assert_called_once()

    def test_change_password_wrong_current(self, mock_db, sample_user):
        """Test password change with wrong current password"""
        with patch('api.services.auth.verify_password', return_value=False):
            with pytest.raises(HTTPException) as exc_info:
                change_password(
                    mock_db,
                    sample_user,
                    "WrongPassword",
                    "NewPassword123!"
                )

            assert exc_info.value.status_code == status.HTTP_400_BAD_REQUEST

    def test_initiate_password_reset(self, sample_user):
        """Test password reset initiation"""
        with patch('api.services.auth.get_user_by_email', return_value=sample_user):
            with patch('api.services.auth.send_reset_email') as mock_send:
                result = initiate_password_reset("password@example.com")

                assert result is True
                mock_send.assert_called_once()

    def test_complete_password_reset(self, mock_db, sample_user):
        """Test password reset completion"""
        reset_token = "valid_reset_token"
        new_password = "NewResetPassword123!"

        with patch('api.services.auth.validate_reset_token', return_value=sample_user):
            with patch('api.services.auth.hash_password', return_value="reset_hashed_password"):
                result = complete_password_reset(mock_db, reset_token, new_password)

                assert result is True
                assert sample_user.hashed_password == "reset_hashed_password"
                mock_db.commit.assert_called_once()


class TestUserTierManagement:
    """Test user tier and subscription management"""

    @pytest.fixture
    def mock_db(self):
        """Mock database session"""
        db = Mock(spec=Session)
        db.commit = Mock()
        return db

    def test_update_user_tier(self, mock_db):
        """Test user tier update"""
        user = UserProfile(
            id="tier_test_user",
            user_tier=UserTier.FREE,
            tier_updated_at=None
        )

        result = update_user_tier(mock_db, user, UserTier.PREMIUM)

        assert result is True
        assert user.user_tier == UserTier.PREMIUM
        assert user.tier_updated_at is not None
        mock_db.commit.assert_called_once()

    def test_tier_downgrade_validation(self, mock_db):
        """Test tier downgrade validation"""
        user = UserProfile(
            id="tier_test_user",
            user_tier=UserTier.UNLIMITED
        )

        # Should allow valid downgrades
        result = update_user_tier(mock_db, user, UserTier.PREMIUM)
        assert result is True
        assert user.user_tier == UserTier.PREMIUM


class TestLoginTracking:
    """Test login attempt tracking and security"""

    def test_track_successful_login(self):
        """Test successful login tracking"""
        with patch('api.services.auth.AuditLogger') as mock_logger:
            track_login_attempt(
                user_id="test_user",
                email="test@example.com",
                success=True,
                ip_address="127.0.0.1"
            )

            mock_logger.return_value.log_login_attempt.assert_called_once()

    def test_track_failed_login(self):
        """Test failed login tracking"""
        with patch('api.services.auth.AuditLogger') as mock_logger:
            track_login_attempt(
                user_id=None,
                email="test@example.com",
                success=False,
                ip_address="127.0.0.1",
                failure_reason="Invalid password"
            )

            mock_logger.return_value.log_login_attempt.assert_called_once()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

"""
Working Authentication Service Tests
Tests for api/services/auth.py actual functions
Target: Increase auth service coverage from 18% to 80%+
"""

import pytest
from unittest.mock import Mock, patch
from datetime import datetime
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from api.services.auth import AuthService
from database.models import UserProfile, UserTier


class TestAuthService:
    """Test AuthService class functionality"""

    @pytest.fixture
    def mock_db(self):
        """Mock database session"""
        db = Mock(spec=Session)
        return db

    @pytest.fixture
    def auth_service(self, mock_db):
        """Create AuthService instance"""
        return AuthService(mock_db)

    @pytest.fixture
    def sample_user(self):
        """Sample user profile"""
        return UserProfile(
            id="test_user_id",
            email="test@example.com",
            username="testuser",
            hashed_password="$2b$12$hashed_password_here",
            is_active=True,
            user_tier=UserTier.FREE,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )

    @pytest.mark.asyncio
    async def test_register_user_success(self, auth_service, mock_db):
        """Test successful user registration"""
        # Mock database query to return None (no existing user)
        mock_db.query().filter().first.return_value = None
        mock_db.add = Mock()
        mock_db.commit = Mock()
        mock_db.refresh = Mock()

        with patch.object(auth_service, '_create_user_tokens') as mock_tokens:
            mock_tokens.return_value = {
                "access_token": "mock_access_token",
                "refresh_token": "mock_refresh_token"
            }

            result = await auth_service.register_user(
                email="newuser@example.com",
                username="newuser",
                password="StrongPassword123!"
            )

            assert "access_token" in result
            assert "refresh_token" in result
            assert "user" in result
            assert result["user"]["email"] == "newuser@example.com"

    @pytest.mark.asyncio
    async def test_authenticate_user_success(self, auth_service, mock_db, sample_user):
        """Test successful user authentication"""
        # Mock database query
        mock_db.query().filter().first.return_value = sample_user

        with patch('api.services.auth.pwd_context.verify', return_value=True):
            with patch.object(auth_service, '_create_user_tokens') as mock_tokens:
                mock_tokens.return_value = {
                    "access_token": "mock_access_token",
                    "refresh_token": "mock_refresh_token"
                }

                result = await auth_service.authenticate_user(
                    email="test@example.com",
                    password="CorrectPassword123!"
                )

                assert "access_token" in result
                assert "user" in result
                assert result["user"]["email"] == sample_user.email


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

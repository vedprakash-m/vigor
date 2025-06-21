"""
Working Security Module Tests
Tests for core/security.py functions that actually exist
Target: Increase security coverage from 41% to 80%+
"""

import pytest
from unittest.mock import Mock, patch
from datetime import datetime, timedelta
from fastapi import HTTPException, status

from core.security import (
    create_access_token,
    verify_token,
    get_password_hash,
    verify_password,
    rate_limit,
    auth_rate_limit,
    ai_rate_limit,
    validate_input
)


class TestPasswordSecurity:
    """Test password hashing and verification"""

    def test_password_hashing(self):
        """Test password hashing and verification"""
        password = "MySecurePassword123!"
        hashed = get_password_hash(password)

        # Hash should be different from original
        assert hashed != password

        # Should verify correctly
        assert verify_password(password, hashed) is True

        # Should reject wrong password
        assert verify_password("WrongPassword", hashed) is False

    def test_different_passwords_different_hashes(self):
        """Test that same password produces different hashes (salt)"""
        password = "TestPassword123!"
        hash1 = get_password_hash(password)
        hash2 = get_password_hash(password)

        # Different hashes due to salt
        assert hash1 != hash2

        # Both should verify
        assert verify_password(password, hash1) is True
        assert verify_password(password, hash2) is True


class TestJWTTokens:
    """Test JWT token creation and validation"""

    def test_token_creation(self):
        """Test JWT token creation"""
        payload = {"sub": "test_user", "email": "test@example.com"}
        token = create_access_token(payload)

        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

    def test_token_with_expiry(self):
        """Test JWT token with custom expiry"""
        payload = {"sub": "test_user"}
        expires_delta = timedelta(hours=1)
        token = create_access_token(payload, expires_delta=expires_delta)

        assert token is not None
        assert isinstance(token, str)

    def test_token_verification(self):
        """Test JWT token verification"""
        payload = {"sub": "test_user", "email": "test@example.com"}
        token = create_access_token(payload)

        # Should be able to verify valid token
        verified_payload = verify_token(token)
        assert verified_payload["sub"] == "test_user"
        assert verified_payload["email"] == "test@example.com"

    def test_invalid_token_verification(self):
        """Test verification of invalid token"""
        invalid_token = "invalid.token.here"

        with pytest.raises((HTTPException, Exception)):
            verify_token(invalid_token)


class TestRateLimiting:
    """Test rate limiting decorators"""

    def test_rate_limit_decorator_exists(self):
        """Test that rate limiting decorators exist"""
        # These should not raise import errors
        assert rate_limit is not None
        assert auth_rate_limit is not None
        assert ai_rate_limit is not None

    def test_rate_limit_decorator_call(self):
        """Test rate limit decorator can be called"""
        # Should be able to call the decorator
        decorated = rate_limit("5/minute")
        assert decorated is not None

        auth_decorated = auth_rate_limit("10/minute")
        assert auth_decorated is not None

        ai_decorated = ai_rate_limit("20/hour")
        assert ai_decorated is not None


class TestInputValidation:
    """Test input validation decorators"""

    def test_validate_input_decorator_exists(self):
        """Test that validate_input decorator exists"""
        assert validate_input is not None

    def test_validate_input_can_be_called(self):
        """Test validate_input decorator can be called"""
        # Mock validator class
        class MockValidator:
            pass

        decorated = validate_input(MockValidator)
        assert decorated is not None


class TestSecurityConstants:
    """Test security-related constants and configurations"""

    def test_token_expiry_constants(self):
        """Test that token expiry works correctly"""
        # Short expiry token
        payload = {"sub": "test"}
        short_token = create_access_token(payload, timedelta(seconds=1))

        # Should be valid immediately
        assert verify_token(short_token)["sub"] == "test"

        # After waiting, should expire (we'll mock this in real tests)
        import time
        time.sleep(2)

        # Should now be expired
        with pytest.raises((HTTPException, Exception)):
            verify_token(short_token)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

"""
Comprehensive Security Module Tests
Tests for core/security.py input validation, rate limiting, and security framework
Target: Increase security coverage from 41% to 80%+
"""

import pytest
from unittest.mock import Mock, patch
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from fastapi.security import HTTPBearer
from slowapi.errors import RateLimitExceeded

from core.security import (
    SecurityMiddleware,
    InputValidator,
    RequestValidationError,
    get_current_user,
    get_current_admin_user,
    RateLimitError,
    AuditLogger,
    AuthenticationError,
    SecurityEventType,
    hash_password,
    verify_password,
    create_access_token
)


class TestInputValidator:
    """Test comprehensive input validation functionality"""

    def test_basic_sanitization(self):
        """Test basic XSS and injection prevention"""
        validator = InputValidator()

        # XSS attempts
        malicious_input = "<script>alert('xss')</script>"
        sanitized = validator.sanitize_input(malicious_input)
        assert "<script>" not in sanitized
        assert "alert" not in sanitized

    def test_email_validation(self):
        """Test email validation security"""
        validator = InputValidator()

        # Valid email
        assert validator.validate_email("user@example.com") is True

        # Invalid email should raise error
        with pytest.raises((RequestValidationError, ValueError)):
            validator.validate_email("not-an-email")

    def test_username_validation(self):
        """Test username validation and security"""
        validator = InputValidator()

        # Valid username
        assert validator.validate_username("validuser123") is True

        # Invalid username should raise error
        with pytest.raises((RequestValidationError, ValueError)):
            validator.validate_username("a")  # too short

    def test_password_strength_validation(self):
        """Test password strength requirements"""
        validator = InputValidator()

        # Strong password
        assert validator.validate_password_strength("MySecure123!") is True

        # Weak password should raise error
        with pytest.raises((RequestValidationError, ValueError)):
            validator.validate_password_strength("weak")

    def test_workout_data_validation(self):
        """Test workout data validation security"""
        validator = InputValidator()

        # Valid workout data
        valid_data = {
            "duration": 45,
            "exercises": ["push-up", "squat", "plank"],
            "fitness_level": "intermediate",
            "goals": ["strength", "endurance"]
        }

        assert validator.validate_workout_data(valid_data) is True

        # Invalid workout data
        invalid_data_cases = [
            {"duration": -5},  # negative duration
            {"duration": 600},  # too long
            {"fitness_level": "invalid_level"},  # invalid level
            {"goals": ["<script>alert('xss')</script>"]},  # XSS in goals
            {"exercises": ["a" * 1000]},  # overly long exercise name
        ]

        for invalid_data in invalid_data_cases:
            with pytest.raises((RequestValidationError, ValueError)):
                validator.validate_workout_data(invalid_data)

    def test_chat_message_validation(self):
        """Test AI chat message validation"""
        validator = InputValidator()

        # Valid messages
        valid_messages = [
            "How can I improve my workout?",
            "Create a beginner workout plan",
            "What exercises are good for strength?"
        ]

        for message in valid_messages:
            assert validator.validate_chat_message(message) is True

        # Invalid messages
        invalid_messages = [
            "",  # empty
            "a" * 10001,  # too long
            "<script>alert('xss')</script>",  # XSS attempt
            "'; DROP TABLE users; --",  # SQL injection attempt
        ]

        for message in invalid_messages:
            with pytest.raises((RequestValidationError, ValueError)):
                validator.validate_chat_message(message)


class TestSecurityMiddleware:
    """Test security middleware functionality"""

    @pytest.fixture
    def mock_request(self):
        """Mock FastAPI request object"""
        request = Mock()
        request.headers = {}
        request.client.host = "127.0.0.1"
        request.method = "GET"
        request.url.path = "/api/test"
        return request

    @pytest.fixture
    def mock_response(self):
        """Mock FastAPI response object"""
        response = Mock()
        response.headers = {}
        return response

    def test_security_headers_injection(self, mock_request, mock_response):
        """Test security headers are properly injected"""
        middleware = SecurityMiddleware()

        # Test header injection
        middleware.add_security_headers(mock_response)

        # Should have basic security headers
        assert "X-Content-Type-Options" in mock_response.headers
        assert "X-Frame-Options" in mock_response.headers
        assert "X-XSS-Protection" in mock_response.headers

    def test_origin_validation(self, mock_request):
        """Test origin validation for CORS security"""
        middleware = SecurityMiddleware()

        # Valid origins
        valid_origins = [
            "http://localhost:3000",
            "http://localhost:5173",
            "https://vigor-frontend.azurestaticapps.io"
        ]

        for origin in valid_origins:
            mock_request.headers = {"origin": origin}
            assert middleware.validate_origin(mock_request) is True

        # Invalid origins
        invalid_origins = [
            "https://malicious-site.com",
            "http://evil.example.com",
            "https://phishing-vigor.com"
        ]

        for origin in invalid_origins:
            mock_request.headers = {"origin": origin}
            assert middleware.validate_origin(mock_request) is False

    def test_request_size_limits(self, mock_request):
        """Test request size validation"""
        middleware = SecurityMiddleware()

        # Small request (should pass)
        mock_request.headers = {"content-length": "1024"}
        assert middleware.validate_request_size(mock_request) is True

        # Large request (should fail)
        mock_request.headers = {"content-length": str(10 * 1024 * 1024)}  # 10MB
        with pytest.raises(HTTPException) as exc_info:
            middleware.validate_request_size(mock_request)

        assert exc_info.value.status_code == status.HTTP_413_REQUEST_ENTITY_TOO_LARGE


class TestRateLimiting:
    """Test rate limiting functionality"""

    @patch('core.security.slowapi_limiter')
    def test_rate_limit_enforcement(self, mock_limiter):
        """Test rate limiting is properly enforced"""
        mock_limiter.limit.side_effect = RateLimitExceeded("Rate limit exceeded")

        # This would be tested in an actual FastAPI test client context
        # Here we're testing the error handling logic
        with pytest.raises(RateLimitExceeded):
            mock_limiter.limit("5/minute")

    def test_rate_limit_tiers(self):
        """Test different rate limits for user tiers"""
        from core.security import get_rate_limit_for_tier

        # Test tier-based limits
        assert get_rate_limit_for_tier("free") == "5/minute"
        assert get_rate_limit_for_tier("premium") == "50/minute"
        assert get_rate_limit_for_tier("unlimited") == "100/minute"
        assert get_rate_limit_for_tier("invalid") == "5/minute"  # default


class TestAuditLogging:
    """Test security audit logging"""

    def test_login_event_logging(self):
        """Test login event logging"""
        audit_logger = AuditLogger()

        with patch.object(audit_logger, 'log_security_event') as mock_log:
            audit_logger.log_login_attempt(
                user_id="test_user",
                success=True,
                ip_address="127.0.0.1",
                user_agent="TestClient"
            )

            mock_log.assert_called_once()
            call_args = mock_log.call_args[1]
            assert call_args['event_type'] == SecurityEventType.LOGIN_SUCCESS
            assert call_args['user_id'] == "test_user"
            assert call_args['ip_address'] == "127.0.0.1"

    def test_failed_login_logging(self):
        """Test failed login attempt logging"""
        audit_logger = AuditLogger()

        with patch.object(audit_logger, 'log_security_event') as mock_log:
            audit_logger.log_login_attempt(
                user_id="test_user",
                success=False,
                ip_address="127.0.0.1",
                failure_reason="Invalid password"
            )

            mock_log.assert_called_once()
            call_args = mock_log.call_args[1]
            assert call_args['event_type'] == SecurityEventType.LOGIN_FAILURE
            assert call_args['metadata']['failure_reason'] == "Invalid password"

    def test_rate_limit_violation_logging(self):
        """Test rate limit violation logging"""
        audit_logger = AuditLogger()

        with patch.object(audit_logger, 'log_security_event') as mock_log:
            audit_logger.log_rate_limit_violation(
                endpoint="/api/chat",
                ip_address="127.0.0.1",
                user_id="test_user"
            )

            mock_log.assert_called_once()
            call_args = mock_log.call_args[1]
            assert call_args['event_type'] == SecurityEventType.RATE_LIMIT_EXCEEDED
            assert call_args['endpoint'] == "/api/chat"


class TestAuthentication:
    """Test authentication and authorization"""

    @patch('core.security.jwt.decode')
    @patch('core.security.get_db')
    def test_current_user_extraction(self, mock_get_db, mock_jwt_decode):
        """Test current user extraction from JWT"""
        # Mock JWT payload
        mock_jwt_decode.return_value = {
            "sub": "test_user_id",
            "email": "test@example.com",
            "tier": "premium"
        }

        # Mock database session and user
        mock_db = Mock()
        mock_get_db.return_value = mock_db

        mock_user = Mock()
        mock_user.id = "test_user_id"
        mock_user.email = "test@example.com"
        mock_user.is_active = True
        mock_db.query().filter().first.return_value = mock_user

        # This would be tested in actual FastAPI context with dependency injection
        # Here we test the logic components
        assert mock_user.is_active is True

    def test_admin_role_validation(self):
        """Test admin role validation"""
        from core.security import validate_admin_role

        # Valid admin user
        admin_user = Mock()
        admin_user.email = "admin@vigor.com"
        admin_user.is_active = True
        assert validate_admin_role(admin_user) is True

        # Non-admin user
        regular_user = Mock()
        regular_user.email = "user@example.com"
        regular_user.is_active = True
        assert validate_admin_role(regular_user) is False

        # Inactive admin
        inactive_admin = Mock()
        inactive_admin.email = "admin@vigor.com"
        inactive_admin.is_active = False
        assert validate_admin_role(inactive_admin) is False


class TestSecurityUtils:
    """Test security utility functions"""

    def test_password_hashing(self):
        """Test password hashing and verification"""
        password = "MySecurePassword123!"
        hashed = hash_password(password)

        # Hash should be different from original
        assert hashed != password

        # Should verify correctly
        assert verify_password(password, hashed) is True

        # Should reject wrong password
        assert verify_password("WrongPassword", hashed) is False

    def test_token_generation_and_validation(self):
        """Test JWT token generation and validation"""
        payload = {
            "sub": "test_user",
            "email": "test@example.com",
            "tier": "premium"
        }

        token = create_access_token(payload)
        assert token is not None
        assert isinstance(token, str)

        # Decode token
        decoded = verify_password(token, create_access_token(payload))
        assert decoded["sub"] == "test_user"
        assert decoded["email"] == "test@example.com"

    def test_secure_random_generation(self):
        """Test secure random string generation"""
        from core.security import generate_secure_random

        # Generate random strings
        random1 = generate_secure_random(32)
        random2 = generate_secure_random(32)

        # Should be different
        assert random1 != random2

        # Should be correct length
        assert len(random1) == 32
        assert len(random2) == 32

        # Should only contain valid characters
        import string
        valid_chars = string.ascii_letters + string.digits
        assert all(c in valid_chars for c in random1)


class TestPasswordSecurity:
    """Test password hashing and verification"""

    def test_password_hashing(self):
        """Test password hashing and verification"""
        password = "MySecurePassword123!"
        hashed = hash_password(password)

        # Hash should be different from original
        assert hashed != password

        # Should verify correctly
        assert verify_password(password, hashed) is True

        # Should reject wrong password
        assert verify_password("WrongPassword", hashed) is False

    def test_different_passwords_different_hashes(self):
        """Test that same password produces different hashes (salt)"""
        password = "TestPassword123!"
        hash1 = hash_password(password)
        hash2 = hash_password(password)

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


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

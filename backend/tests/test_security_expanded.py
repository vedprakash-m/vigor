"""
Expanded Security Module Tests
Comprehensive coverage for security features including input validation,
security middleware, audit logging, and health checks
"""

import json
from datetime import datetime
from unittest.mock import AsyncMock, Mock, patch

import pytest
from fastapi import HTTPException, Request, Response
from fastapi.testclient import TestClient

from core.security import (
    SECURITY_HEADERS,
    AIInputValidator,
    InputValidationError,
    SecurityAuditLogger,
    SecurityMiddleware,
    UserInputValidator,
    WorkoutInputValidator,
    ai_rate_limit,
    auth_rate_limit,
    check_request_origin,
    rate_limit,
    rate_limit_handler,
    secure_health_check,
    validate_input,
    validate_request_size,
)


class TestSecurityMiddleware:
    """Test security middleware functionality"""

    def test_security_middleware_initialization(self):
        """Test middleware can be initialized"""
        app = Mock()
        middleware = SecurityMiddleware(app)
        assert middleware.app == app

    @pytest.mark.asyncio
    async def test_security_headers_injection(self):
        """Test security headers are properly injected"""
        app = Mock()
        middleware = SecurityMiddleware(app)

        # Mock scope, receive, send
        scope = {"type": "http"}
        receive = AsyncMock()

        sent_messages = []

        async def mock_send(message):
            sent_messages.append(message)

        # Mock the app call to send a response
        async def mock_app(scope, receive, send):
            await send({"type": "http.response.start", "status": 200, "headers": []})
            await send({"type": "http.response.body", "body": b"test response"})

        middleware.app = mock_app

        await middleware(scope, receive, mock_send)

        # Check that headers were added
        start_message = sent_messages[0]
        assert start_message["type"] == "http.response.start"

        headers_dict = {k.decode(): v.decode() for k, v in start_message["headers"]}

        # Verify key security headers are present
        assert "X-Content-Type-Options" in headers_dict
        assert "X-Frame-Options" in headers_dict
        assert "Strict-Transport-Security" in headers_dict
        assert headers_dict["X-Content-Type-Options"] == "nosniff"
        assert headers_dict["X-Frame-Options"] == "DENY"

    @pytest.mark.asyncio
    async def test_non_http_requests_passthrough(self):
        """Test non-HTTP requests pass through unchanged"""
        app = Mock()
        middleware = SecurityMiddleware(app)

        scope = {"type": "websocket"}
        receive = AsyncMock()
        send = AsyncMock()

        middleware.app = AsyncMock()

        await middleware(scope, receive, send)

        # Should call the app directly without modification
        middleware.app.assert_called_once_with(scope, receive, send)


class TestInputValidators:
    """Test input validation classes"""

    def test_user_input_validator_valid_data(self):
        """Test user input validator with valid data"""
        valid_data = {
            "email": "test@example.com",
            "username": "validuser123",
            "password": "StrongPassword123!",
        }

        validator = UserInputValidator(**valid_data)

        assert validator.email == "test@example.com"
        assert validator.username == "validuser123"
        assert validator.password == "StrongPassword123!"

    def test_user_input_validator_invalid_email(self):
        """Test user input validator rejects invalid email"""
        invalid_data = {
            "email": "invalid-email",
            "username": "validuser",
            "password": "StrongPassword123!",
        }

        with pytest.raises(ValueError, match="Invalid email format"):
            UserInputValidator(**invalid_data)

    def test_user_input_validator_weak_password(self):
        """Test user input validator rejects weak password"""
        invalid_data = {
            "email": "test@example.com",
            "username": "validuser",
            "password": "weak",
        }

        with pytest.raises(ValueError, match="Password must be at least 8 characters"):
            UserInputValidator(**invalid_data)

    def test_user_input_validator_invalid_username(self):
        """Test user input validator rejects invalid username"""
        invalid_data = {
            "email": "test@example.com",
            "username": "ab",  # Too short
            "password": "StrongPassword123!",
        }

        with pytest.raises(ValueError, match="Username must be 3-30 characters"):
            UserInputValidator(**invalid_data)

    def test_workout_input_validator_valid_data(self):
        """Test workout input validator with valid data"""
        valid_data = {
            "duration": 60,
            "fitness_level": "intermediate",
            "goals": ["strength", "muscle_gain"],
        }

        validator = WorkoutInputValidator(**valid_data)

        assert validator.duration == 60
        assert validator.fitness_level == "intermediate"
        assert validator.goals == ["strength", "muscle_gain"]

    def test_workout_input_validator_invalid_duration(self):
        """Test workout input validator rejects invalid duration"""
        invalid_data = {"duration": 500, "fitness_level": "beginner"}  # Too long

        with pytest.raises(
            ValueError, match="Duration must be between 5 and 300 minutes"
        ):
            WorkoutInputValidator(**invalid_data)

    def test_workout_input_validator_invalid_fitness_level(self):
        """Test workout input validator rejects invalid fitness level"""
        invalid_data = {"duration": 60, "fitness_level": "superhuman"}  # Not allowed

        with pytest.raises(ValueError, match="Fitness level must be one of"):
            WorkoutInputValidator(**invalid_data)

    def test_ai_input_validator_valid_data(self):
        """Test AI input validator with valid data"""
        valid_data = {"message": "Generate a workout plan", "max_tokens": 500}

        validator = AIInputValidator(**valid_data)

        assert validator.message == "Generate a workout plan"
        assert validator.max_tokens == 500

    def test_ai_input_validator_message_too_long(self):
        """Test AI input validator rejects overly long messages"""
        invalid_data = {"message": "x" * 2001, "max_tokens": 100}  # Too long

        with pytest.raises(ValueError, match="Message too long"):
            AIInputValidator(**invalid_data)

    def test_xss_prevention(self):
        """Test XSS prevention in input validation"""
        malicious_inputs = [
            "<script>alert('xss')</script>",
            "javascript:alert('xss')",
            "<img src=x onerror=alert('xss')>",
            "expression(alert('xss'))",
        ]

        for malicious_input in malicious_inputs:
            with pytest.raises(
                ValueError, match="Potentially dangerous input detected"
            ):
                UserInputValidator(
                    email="test@example.com",
                    username=malicious_input,
                    password="StrongPassword123!",
                )

    def test_sql_injection_prevention(self):
        """Test SQL injection prevention in input validation"""
        # Test SQL injection patterns in email field which has less restrictive validation
        malicious_emails = [
            "test'; DROP TABLE users; --@example.com",
            "test@example.com'; UNION SELECT * FROM users; --",
        ]

        for malicious_email in malicious_emails:
            with pytest.raises(
                ValueError, match="Potentially dangerous SQL pattern detected"
            ):
                UserInputValidator(
                    email=malicious_email,
                    username="validuser",
                    password="StrongPassword123!",
                )


class TestSecurityAuditLogger:
    """Test security audit logging functionality"""

    @pytest.mark.asyncio
    async def test_log_auth_attempt_success(self):
        """Test logging successful authentication attempt"""
        request = Mock(spec=Request)
        request.client.host = "127.0.0.1"
        request.url.path = "/auth/login"
        request.headers = {}

        with patch("core.security.logger") as mock_logger:
            await SecurityAuditLogger.log_auth_attempt(
                request=request, user_id="test_user", success=True
            )

            mock_logger.info.assert_called_once()
            call_args = mock_logger.info.call_args[0][0]
            assert "Authentication attempt" in call_args
            assert "SUCCESS" in call_args
            assert "test_user" in call_args

    @pytest.mark.asyncio
    async def test_log_auth_attempt_failure(self):
        """Test logging failed authentication attempt"""
        request = Mock(spec=Request)
        request.client.host = "192.168.1.100"
        request.url.path = "/auth/login"
        request.headers = {}

        with patch("core.security.logger") as mock_logger:
            await SecurityAuditLogger.log_auth_attempt(
                request=request, user_id=None, success=False, reason="Invalid password"
            )

            mock_logger.warning.assert_called_once()
            call_args = mock_logger.warning.call_args[0][0]
            assert "Authentication attempt" in call_args
            assert "FAILED" in call_args
            assert "Invalid password" in call_args

    @pytest.mark.asyncio
    async def test_log_suspicious_activity(self):
        """Test logging suspicious activity"""
        request = Mock(spec=Request)
        request.client.host = "10.0.0.1"
        request.url.path = "/admin/users"
        request.headers = {}

        details = {
            "action": "unauthorized_access_attempt",
            "resource": "admin_panel",
            "user_agent": "suspicious_bot",
        }

        with patch("core.security.logger") as mock_logger:
            await SecurityAuditLogger.log_suspicious_activity(
                request=request, activity_type="UNAUTHORIZED_ACCESS", details=details
            )

            mock_logger.error.assert_called_once()
            call_args = mock_logger.error.call_args[0][0]
            assert "Suspicious activity" in call_args
            assert "UNAUTHORIZED_ACCESS" in call_args

    @pytest.mark.asyncio
    async def test_log_rate_limit_exceeded(self):
        """Test logging rate limit exceeded"""
        request = Mock(spec=Request)
        request.client.host = "1.2.3.4"
        request.url.path = "/api/generate"
        request.headers = {}

        with patch("core.security.logger") as mock_logger:
            await SecurityAuditLogger.log_rate_limit_exceeded(
                request=request, limit="10/minute"
            )

            mock_logger.warning.assert_called_once()
            call_args = mock_logger.warning.call_args[0][0]
            assert "Rate limit exceeded" in call_args
            assert "10/minute" in call_args


class TestHealthChecks:
    """Test security health check functionality"""

    @pytest.mark.asyncio
    async def test_secure_health_check_basic(self):
        """Test basic health check functionality"""
        with patch("core.security._check_database_health", return_value="healthy"):
            with patch("core.security._check_redis_health", return_value="healthy"):
                with patch(
                    "core.security._check_ai_providers_health", return_value="healthy"
                ):

                    result = await secure_health_check()

                    assert result["status"] == "healthy"
                    assert result["timestamp"] is not None
                    assert "checks" in result
                    assert result["checks"]["database"] == "healthy"
                    assert result["checks"]["redis"] == "healthy"
                    assert result["checks"]["ai_providers"] == "healthy"

    @pytest.mark.asyncio
    async def test_secure_health_check_with_failures(self):
        """Test health check with some failures"""
        with patch("core.security._check_database_health", return_value="healthy"):
            with patch("core.security._check_redis_health", return_value="error"):
                with patch(
                    "core.security._check_ai_providers_health", return_value="healthy"
                ):

                    result = await secure_health_check()

                    assert result["status"] == "degraded"
                    assert result["checks"]["redis"] == "error"


class TestRateLimitingDecorators:
    """Test rate limiting decorator functionality"""

    def test_rate_limit_decorator_application(self):
        """Test rate limit decorator can be applied to functions"""

        @rate_limit("10/minute")
        async def test_function():
            return "success"

        # Should be able to create the decorated function
        assert callable(test_function)

    def test_auth_rate_limit_decorator(self):
        """Test auth rate limit decorator"""

        @auth_rate_limit("5/minute")
        async def auth_function():
            return "authenticated"

        assert callable(auth_function)

    def test_ai_rate_limit_decorator(self):
        """Test AI rate limit decorator"""

        @ai_rate_limit("20/hour")
        async def ai_function():
            return "ai_response"

        assert callable(ai_function)


class TestRequestValidation:
    """Test request validation utilities"""

    @pytest.mark.asyncio
    async def test_validate_request_size_within_limit(self):
        """Test request size validation within limits"""
        request = Mock(spec=Request)
        request.headers = {"content-length": "1000"}

        # Should not raise an exception
        await validate_request_size(request, max_size=2000)

    @pytest.mark.asyncio
    async def test_validate_request_size_exceeds_limit(self):
        """Test request size validation exceeding limits"""
        request = Mock(spec=Request)
        request.headers = {"content-length": "2000"}

        with pytest.raises(HTTPException) as exc_info:
            await validate_request_size(request, max_size=1000)

        assert exc_info.value.status_code == 413
        assert "Request too large" in str(exc_info.value.detail)

    @pytest.mark.asyncio
    async def test_check_request_origin_allowed(self):
        """Test request origin checking for allowed origins"""
        request = Mock(spec=Request)
        request.headers = {"origin": "https://vigor-fitness.com"}

        with patch("core.config.get_settings") as mock_settings:
            mock_settings.return_value.ALLOWED_ORIGINS = [
                "https://vigor-fitness.com",
                "https://app.vigor.com",
            ]

            # Should not raise an exception
            await check_request_origin(request)

    @pytest.mark.asyncio
    async def test_check_request_origin_blocked(self):
        """Test request origin checking for blocked origins"""
        request = Mock(spec=Request)
        request.headers = {"origin": "https://malicious-site.com"}

        with patch("core.config.get_settings") as mock_settings:
            mock_settings.return_value.ALLOWED_ORIGINS = ["https://vigor-fitness.com"]

            with pytest.raises(HTTPException) as exc_info:
                await check_request_origin(request)

            assert exc_info.value.status_code == 403
            assert "Origin not allowed" in str(exc_info.value.detail)


class TestInputValidationDecorator:
    """Test input validation decorator functionality"""

    def test_validate_input_decorator_creation(self):
        """Test input validation decorator can be created"""
        decorator = validate_input(UserInputValidator)
        assert callable(decorator)

    @pytest.mark.asyncio
    async def test_validate_input_decorator_application(self):
        """Test input validation decorator application"""

        @validate_input(UserInputValidator)
        async def test_endpoint(data: dict):
            return {"message": "success", "data": data}

        # Valid data should pass
        valid_data = {
            "email": "test@example.com",
            "username": "validuser",
            "password": "StrongPassword123!",
        }

        result = await test_endpoint(valid_data)
        assert result["message"] == "success"

    def test_input_validation_error_creation(self):
        """Test InputValidationError creation"""
        error = InputValidationError("Invalid input", field="email")

        assert error.status_code == 400
        assert error.detail["message"] == "Invalid input"
        assert error.detail["field"] == "email"
        assert hasattr(error, "field")


class TestSecurityConstants:
    """Test security constants and configuration"""

    def test_security_headers_completeness(self):
        """Test that all required security headers are defined"""
        required_headers = [
            "X-Content-Type-Options",
            "X-Frame-Options",
            "X-XSS-Protection",
            "Strict-Transport-Security",
            "Content-Security-Policy",
            "Referrer-Policy",
            "Permissions-Policy",
        ]

        for header in required_headers:
            assert header in SECURITY_HEADERS
            assert isinstance(SECURITY_HEADERS[header], str)
            assert len(SECURITY_HEADERS[header]) > 0

    def test_csp_header_restrictive(self):
        """Test Content Security Policy is restrictive"""
        csp = SECURITY_HEADERS["Content-Security-Policy"]

        # Should have restrictive default-src
        assert "default-src 'self'" in csp
        # Should not allow unsafe-eval
        assert "unsafe-eval" not in csp
        # Should restrict script sources
        assert "script-src 'self'" in csp

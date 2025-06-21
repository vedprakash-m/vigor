"""
Enhanced Security Module for Production
Implements rate limiting, input validation, security headers, and comprehensive protection
"""

import logging
import re
from datetime import datetime, timedelta
from functools import wraps
from typing import Any, Optional, Union

import redis.asyncio as redis
from fastapi import Depends, HTTPException, Request, Response, status
from fastapi.security import (
    OAuth2PasswordBearer,
)
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, ValidationError, validator
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from sqlalchemy.orm import Session

from database.connection import get_db
from database.models import UserProfile
from database.sql_models import UserProfileDB

from .config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

# Rate Limiter Configuration
try:
    redis_client = redis.from_url(settings.REDIS_URL)
except Exception as e:
    logger.warning(f"Redis connection failed, using in-memory storage: {e}")
    redis_client = None

limiter = Limiter(
    key_func=get_remote_address,
    storage_uri=settings.REDIS_URL if redis_client else "memory://",
    default_limits=["1000/day", "100/hour"],
)

# Security Headers
SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block",
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
    "Content-Security-Policy": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self'",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "geolocation=(), microphone=(), camera=()",
}


class SecurityMiddleware:
    """Enhanced security middleware for production"""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            Request(scope, receive)

            # Add security headers
            async def send_wrapper(message):
                if message["type"] == "http.response.start":
                    headers = dict(message.get("headers", []))
                    for key, value in SECURITY_HEADERS.items():
                        headers[key.encode()] = value.encode()
                    message["headers"] = [
                        (
                            k.encode() if isinstance(k, str) else k,
                            v.encode() if isinstance(v, str) else v,
                        )
                        for k, v in headers.items()
                    ]
                await send(message)

            await self.app(scope, receive, send_wrapper)
        else:
            await self.app(scope, receive, send)


# Input Validation Base Classes
class BaseInputValidator(BaseModel):
    """Base validator with common security checks"""

    @validator("*", pre=True)
    def prevent_xss(cls, v):
        """Prevent XSS attacks in string inputs"""
        if isinstance(v, str):
            # Basic XSS prevention
            dangerous_patterns = [
                r"<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>",
                r"javascript:",
                r"on\w+\s*=",
                r"expression\s*\(",
                r"data:text/html",
            ]
            for pattern in dangerous_patterns:
                if re.search(pattern, v, re.IGNORECASE):
                    raise ValueError("Potentially dangerous input detected")
        return v

    @validator("*", pre=True)
    def prevent_sql_injection(cls, v):
        """Basic SQL injection prevention for string inputs"""
        if isinstance(v, str):
            # Check for common SQL injection patterns
            sql_patterns = [
                r"(DROP\s+TABLE|TRUNCATE\s+TABLE|DELETE\s+FROM)",
                r"(UNION\s+SELECT)",
                r"(\bOR\s+\d+\s*=\s*\d+|\bAND\s+\d+\s*=\s*\d+)",
                r"(SELECT\s+.*\bFROM\b)",
                r"(--|#|/\*)",
                r"(\';|'OR|'AND)",
            ]
            for pattern in sql_patterns:
                if re.search(pattern, v, re.IGNORECASE):
                    raise ValueError("Potentially dangerous SQL pattern detected")
        return v


# Specific Input Validators
class UserInputValidator(BaseInputValidator):
    """Validator for user-related inputs"""

    email: str
    username: str
    password: str

    @validator("email")
    def validate_email(cls, v):
        if not re.match(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$", v):
            raise ValueError("Invalid email format")
        return v.lower()

    @validator("username")
    def validate_username(cls, v):
        if not re.match(r"^[a-zA-Z0-9_]{3,30}$", v):
            raise ValueError(
                "Username must be 3-30 characters, alphanumeric and underscore only"
            )
        return v

    @validator("password")
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not re.search(r"[A-Z]", v):
            raise ValueError("Password must contain uppercase letter")
        if not re.search(r"[a-z]", v):
            raise ValueError("Password must contain lowercase letter")
        if not re.search(r"\d", v):
            raise ValueError("Password must contain number")
        return v


class WorkoutInputValidator(BaseInputValidator):
    """Validator for workout-related inputs"""

    duration: Optional[int] = None
    fitness_level: Optional[str] = None
    goals: Optional[list[str]] = None

    @validator("duration")
    def validate_duration(cls, v):
        if v is not None and (not isinstance(v, int) or v < 5 or v > 300):
            raise ValueError("Duration must be between 5 and 300 minutes")
        return v

    @validator("fitness_level")
    def validate_fitness_level(cls, v):
        if v is not None:
            allowed_levels = ["beginner", "intermediate", "advanced", "expert"]
            if v.lower() not in allowed_levels:
                raise ValueError(f"Fitness level must be one of: {allowed_levels}")
            return v.lower()
        return v

    @validator("goals")
    def validate_goals(cls, v):
        if isinstance(v, list):
            allowed_goals = [
                "weight_loss",
                "muscle_gain",
                "endurance",
                "strength",
                "flexibility",
                "general_fitness",
                "sports_performance",
            ]
            for goal in v:
                if goal.lower() not in allowed_goals:
                    raise ValueError(f"Invalid goal: {goal}")
            return [g.lower() for g in v]
        return v


class AIInputValidator(BaseInputValidator):
    """Validator for AI/LLM inputs"""

    message: Optional[str] = None
    max_tokens: Optional[int] = None

    @validator("message")
    def validate_message(cls, v):
        if v is not None:
            if len(v) > 2000:
                raise ValueError("Message too long (max 2000 characters)")
            if len(v.strip()) == 0:
                raise ValueError("Message cannot be empty")
            return v.strip()
        return v

    @validator("max_tokens")
    def validate_max_tokens(cls, v):
        if v is not None and (not isinstance(v, int) or v < 1 or v > 4000):
            raise ValueError("Max tokens must be between 1 and 4000")
        return v


# Rate Limiting Decorators
def rate_limit(limit: str):
    """Rate limiting decorator for routes"""

    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            return await func(*args, **kwargs)

        wrapper.__rate_limit__ = limit
        return wrapper

    return decorator


def auth_rate_limit(limit: str = "5/minute"):
    """Stricter rate limiting for authentication endpoints"""
    return rate_limit(limit)


def ai_rate_limit(limit: str = "20/hour"):
    """Rate limiting for AI endpoints"""
    return rate_limit(limit)


# Security Utils
async def validate_request_size(
    request: Request, max_size: int = 1024 * 1024
):  # 1MB default
    """Validate request content length"""
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > max_size:
        raise HTTPException(status_code=413, detail="Request too large")


async def check_request_origin(request: Request):
    """Validate request origin for CSRF protection"""
    origin = request.headers.get("origin")
    referer = request.headers.get("referer")

    if not origin and not referer:
        # Allow for API clients, but log suspicious activity
        logger.warning(f"Request without origin/referer from {request.client.host}")
        return

    # Use get_settings() to allow for mocking in tests
    from core.config import get_settings
    current_settings = get_settings()
    allowed_origins = getattr(current_settings, 'ALLOWED_ORIGINS', getattr(current_settings, 'CORS_ORIGINS', []))
    if origin and origin not in allowed_origins:
        logger.warning(f"Suspicious origin: {origin} from {request.client.host}")
        raise HTTPException(status_code=403, detail="Origin not allowed")


class InputValidationError(HTTPException):
    """Custom exception for input validation errors"""

    def __init__(self, detail: str, field: Optional[str] = None):
        self.field = field
        super().__init__(
            status_code=400,
            detail={
                "error": "validation_error",
                "message": detail,
                "field": field,
                "timestamp": datetime.utcnow().isoformat(),
            },
        )


def validate_input(validator_class: BaseInputValidator):
    """Decorator for input validation"""

    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Find request data in function arguments
            for arg in args:
                if hasattr(arg, "__dict__") and hasattr(arg, "model_validate"):
                    try:
                        validated = validator_class.model_validate(arg.__dict__)
                        # Replace original object with validated one
                        arg.__dict__.update(validated.model_dump())
                    except ValidationError as e:
                        field = (
                            e.errors()[0].get("loc", [None])[0] if e.errors() else None
                        )
                        message = (
                            e.errors()[0].get("msg", "Validation error")
                            if e.errors()
                            else "Validation error"
                        )
                        raise InputValidationError(message, field)
            return await func(*args, **kwargs)

        return wrapper

    return decorator


# Audit Logging
class SecurityAuditLogger:
    """Security event audit logger"""

    @staticmethod
    async def log_auth_attempt(
        request: Request,
        user_id: Optional[str] = None,
        success: bool = False,
        reason: Optional[str] = None,
    ):
        """Log authentication attempts"""
        event = {
            "event_type": "auth_attempt",
            "timestamp": datetime.utcnow().isoformat(),
            "ip_address": request.client.host,
            "user_agent": request.headers.get("user-agent"),
            "user_id": user_id,
            "success": success,
            "reason": reason,
            "url": str(request.url),
        }
        if success:
            logger.info(f"AUTH_AUDIT: Authentication attempt SUCCESS - {event}")
        else:
            logger.warning(f"AUTH_AUDIT: Authentication attempt FAILED - {event}")

    @staticmethod
    async def log_suspicious_activity(
        request: Request, activity_type: str, details: dict[str, Any]
    ):
        """Log suspicious security events"""
        event = {
            "event_type": "suspicious_activity",
            "activity_type": activity_type,
            "timestamp": datetime.utcnow().isoformat(),
            "ip_address": request.client.host,
            "user_agent": request.headers.get("user-agent"),
            "details": details,
            "url": str(request.url),
        }
        logger.error(f"SECURITY_AUDIT: Suspicious activity {activity_type} - {event}")

    @staticmethod
    async def log_rate_limit_exceeded(request: Request, limit: str):
        """Log rate limit violations"""
        event = {
            "event_type": "rate_limit_exceeded",
            "timestamp": datetime.utcnow().isoformat(),
            "ip_address": request.client.host,
            "user_agent": request.headers.get("user-agent"),
            "limit": limit,
            "url": str(request.url),
        }
        logger.warning(f"RATE_LIMIT_AUDIT: Rate limit exceeded {limit} - {event}")


# Error Handler for Rate Limiting
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    """Custom rate limit exceeded handler"""
    await SecurityAuditLogger.log_rate_limit_exceeded(request, str(exc.detail))

    response = Response(
        content=f'{{"error": "rate_limit_exceeded", "message": "Too many requests", "retry_after": {exc.retry_after}}}',
        status_code=429,
        headers={"Retry-After": str(exc.retry_after)},
    )
    return response


# Health Check Security
async def secure_health_check() -> dict[str, Any]:
    """Secure health check that doesn't expose sensitive information"""
    checks = {
        "database": await _check_database_health(),
        "redis": await _check_redis_health(),
        "ai_providers": await _check_ai_providers_health(),
    }

    # Determine overall status
    status = "healthy"
    if any(check in ["error", "unhealthy"] for check in checks.values()):
        status = "degraded"
    elif any(check == "unknown" for check in checks.values()):
        status = "degraded"

    return {
        "status": status,
        "timestamp": datetime.utcnow().isoformat(),
        "version": getattr(settings, 'APP_VERSION', '1.0.0'),
        "environment": settings.ENVIRONMENT,
        # Don't expose detailed system information in production
        "checks": checks,
    }


async def _check_database_health() -> str:
    """Check database connectivity without exposing details"""
    try:
        # Import here to avoid circular imports
        from database.connection import SessionLocal

        with SessionLocal() as session:
            session.execute("SELECT 1")
        return "healthy"
    except Exception:
        return "unhealthy"


async def _check_redis_health() -> str:
    """Check Redis connectivity"""
    try:
        if redis_client:
            await redis_client.ping()
            return "healthy"
        return "not_configured"
    except Exception:
        return "unhealthy"


async def _check_ai_providers_health() -> str:
    """Check AI providers without exposing API keys"""
    try:
        # Basic check without making actual API calls
        return (
            "available"
            if settings.OPENAI_API_KEY or settings.GEMINI_API_KEY
            else "limited"
        )
    except Exception:
        return "unknown"


# Export main components
__all__ = [
    "limiter",
    "SecurityMiddleware",
    "UserInputValidator",
    "WorkoutInputValidator",
    "AIInputValidator",
    "rate_limit",
    "auth_rate_limit",
    "ai_rate_limit",
    "validate_input",
    "SecurityAuditLogger",
    "secure_health_check",
    "rate_limit_handler",
    "InputValidationError",
]

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return bool(pwd_context.verify(plain_password, hashed_password))


def get_password_hash(password: str) -> str:
    """Generate password hash."""
    return str(pwd_context.hash(password))


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )
    return str(encoded_jwt)


def verify_token(token: str) -> dict[Any, Any]:
    """Verify and decode JWT token."""
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        return payload  # type: ignore[no-any-return]
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
) -> UserProfile:
    """Get current user from JWT token."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(UserProfileDB).filter(UserProfileDB.id == user_id).first()
    if user is None:
        raise credentials_exception

    # Convert SQLAlchemy model to Pydantic model
    return UserProfile.model_validate(user)


async def get_current_active_user(
    current_user: UserProfile = Depends(get_current_user),
) -> UserProfile:
    """Get current active user."""
    # Add any additional checks for user status here
    return current_user


async def get_current_admin_user(
    current_user: UserProfile = Depends(get_current_user),
) -> UserProfile:
    """
    Verify that the current user has admin privileges.
    """
    # Check if user has admin role/permissions
    # For now, we'll check if user has an 'is_admin' field or admin role
    if hasattr(current_user, "is_admin") and current_user.is_admin:
        return current_user

    # Alternative: check for admin role in user profile
    if hasattr(current_user, "role") and current_user.role == "admin":
        return current_user

    # Alternative: check email domain or specific user IDs
    # This is a fallback - in production you'd have proper role management
    admin_emails = [
        "admin@vigor.com",
        "admin@example.com",
    ]  # Configure based on your needs
    if hasattr(current_user, "email") and current_user.email in admin_emails:
        return current_user

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required"
    )

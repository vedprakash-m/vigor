"""
Rate limiting module for Vigor Functions
Provides rate limiting functionality for Azure Functions endpoints

DESIGN NOTE (Phase 10.7):
This rate limiter uses an in-memory dictionary, which means:
  • Limits are per-instance: each Azure Functions worker has its own counters.
    Under the Consumption plan a single warm instance usually handles most
    traffic, so this is an acceptable "best-effort" throttle.
  • Counters are lost on cold starts and scale-out events.
  • For strict global rate limiting, switch to a Redis or Cosmos DB–backed
    store (e.g. Azure Cache for Redis with sliding-window counters).
    This is documented but deferred — the current approach is sufficient for
    the projected user base (single-tenant iOS app, <100 daily active users
    at launch).
"""

import json
import logging
from datetime import datetime, timezone
from typing import Dict, List, Optional

import azure.functions as func

logger = logging.getLogger(__name__)


class RateLimitExceeded(Exception):
    """Rate limit exceeded exception"""

    pass


class RateLimiter:
    """Simple in-memory rate limiter for Azure Functions"""

    def __init__(self):
        self._cache: Dict[str, List[float]] = {}

    def is_allowed(self, key: str, limit: int, window_seconds: int) -> bool:
        """Check if request is allowed based on rate limit"""
        try:
            now = datetime.now(timezone.utc).timestamp()

            if key not in self._cache:
                self._cache[key] = []

            # Clean old entries outside the window
            self._cache[key] = [
                timestamp
                for timestamp in self._cache[key]
                if now - timestamp < window_seconds
            ]

            # Check if limit is exceeded
            if len(self._cache[key]) >= limit:
                logger.warning(f"Rate limit exceeded for key: {key}")
                return False

            # Add current request timestamp
            self._cache[key].append(now)
            return True

        except Exception as e:
            logger.error(f"Error in rate limiting for key {key}: {str(e)}")
            # Allow request if rate limiting fails
            return True

    def get_remaining(self, key: str, limit: int, window_seconds: int) -> int:
        """Get remaining requests for a key"""
        try:
            now = datetime.now(timezone.utc).timestamp()

            if key not in self._cache:
                return limit

            # Clean old entries
            self._cache[key] = [
                timestamp
                for timestamp in self._cache[key]
                if now - timestamp < window_seconds
            ]

            return max(0, limit - len(self._cache[key]))

        except Exception as e:
            logger.error(f"Error getting remaining for key {key}: {str(e)}")
            return limit

    def reset(self, key: str):
        """Reset rate limit for a key"""
        try:
            if key in self._cache:
                del self._cache[key]
        except Exception as e:
            logger.error(f"Error resetting rate limit for key {key}: {str(e)}")

    async def check_rate_limit(self, key: str, limit: int, window: int) -> bool:
        """Async check if request is allowed based on rate limit

        This is an async wrapper around is_allowed for compatibility with
        function_app.py async functions.

        Args:
            key: Unique identifier for rate limiting (e.g., "workout_gen:user@email.com")
            limit: Maximum number of requests allowed in the window
            window: Time window in seconds

        Returns:
            True if request is allowed, False if rate limit exceeded
        """
        return self.is_allowed(key, limit, window)


# Global rate limiter instance
_rate_limiter = RateLimiter()


def get_client_identifier(req: func.HttpRequest, user_id: Optional[str] = None) -> str:
    """Get client identifier for rate limiting"""
    try:
        # Use user ID if available (authenticated requests)
        if user_id:
            return f"user:{user_id}"

        # Use IP address for anonymous requests
        client_ip = req.headers.get("X-Forwarded-For")
        if client_ip:
            # Take first IP if multiple (X-Forwarded-For can be comma-separated)
            client_ip = client_ip.split(",")[0].strip()
        else:
            client_ip = req.headers.get("X-Real-IP", "unknown")

        return f"ip:{client_ip}"

    except Exception as e:
        logger.error(f"Error getting client identifier: {str(e)}")
        return "unknown"


async def check_rate_limit(
    req: func.HttpRequest,
    limit: int,
    window_seconds: int,
    user_id: Optional[str] = None,
) -> bool:
    """Check if request passes rate limit"""
    try:
        client_id = get_client_identifier(req, user_id)
        return _rate_limiter.is_allowed(client_id, limit, window_seconds)

    except Exception as e:
        logger.error(f"Error checking rate limit: {str(e)}")
        return True  # Allow request if check fails


async def apply_rate_limit(
    req: func.HttpRequest,
    limit: int,
    window_seconds: int,
    user_id: Optional[str] = None,
) -> Optional[func.HttpResponse]:
    """Apply rate limiting and return error response if exceeded"""
    try:
        if not await check_rate_limit(req, limit, window_seconds, user_id):
            client_id = get_client_identifier(req, user_id)
            remaining = _rate_limiter.get_remaining(client_id, limit, window_seconds)

            return func.HttpResponse(
                json.dumps(
                    {
                        "error": "Rate limit exceeded",
                        "message": f"Too many requests. Limit: {limit} per {window_seconds} seconds",
                        "remaining": remaining,
                        "reset_after": window_seconds,
                    }
                ),
                status_code=429,
                headers={"Content-Type": "application/json"},
            )

        return None  # Rate limit passed

    except Exception as e:
        logger.error(f"Error applying rate limit: {str(e)}")
        return None  # Allow request if rate limiting fails


# Rate limit decorators for different tiers
async def apply_free_tier_limit(
    req: func.HttpRequest, user_id: Optional[str] = None
) -> Optional[func.HttpResponse]:
    """Apply free tier rate limits"""
    return await apply_rate_limit(
        req, limit=100, window_seconds=3600, user_id=user_id
    )  # 100 per hour


async def apply_premium_tier_limit(
    req: func.HttpRequest, user_id: Optional[str] = None
) -> Optional[func.HttpResponse]:
    """Apply premium tier rate limits"""
    return await apply_rate_limit(
        req, limit=1000, window_seconds=3600, user_id=user_id
    )  # 1000 per hour


async def apply_admin_tier_limit(
    req: func.HttpRequest, user_id: Optional[str] = None
) -> Optional[func.HttpResponse]:
    """Apply admin tier rate limits"""
    return await apply_rate_limit(
        req, limit=10000, window_seconds=3600, user_id=user_id
    )  # 10000 per hour


async def apply_auth_rate_limit(req: func.HttpRequest) -> Optional[func.HttpResponse]:
    """Apply authentication endpoint rate limits"""
    return await apply_rate_limit(req, limit=10, window_seconds=300)  # 10 per 5 minutes


async def apply_ai_generation_limit(
    req: func.HttpRequest, user_id: Optional[str] = None
) -> Optional[func.HttpResponse]:
    """Apply AI generation rate limits"""
    return await apply_rate_limit(
        req, limit=20, window_seconds=3600, user_id=user_id
    )  # 20 per hour


async def apply_tier_based_rate_limit(
    req: func.HttpRequest, user_tier: str, user_id: Optional[str] = None
) -> Optional[func.HttpResponse]:
    """Apply rate limit based on user tier"""
    try:
        if user_tier == "admin":
            return await apply_admin_tier_limit(req, user_id)
        elif user_tier == "premium":
            return await apply_premium_tier_limit(req, user_id)
        else:  # free tier
            return await apply_free_tier_limit(req, user_id)

    except Exception as e:
        logger.error(f"Error applying tier-based rate limit: {str(e)}")
        return None


def get_rate_limit_headers(
    client_id: str, limit: int, window_seconds: int
) -> Dict[str, str]:
    """Get rate limit headers for response"""
    try:
        remaining = _rate_limiter.get_remaining(client_id, limit, window_seconds)
        reset_time = int(datetime.now(timezone.utc).timestamp() + window_seconds)

        return {
            "X-RateLimit-Limit": str(limit),
            "X-RateLimit-Remaining": str(remaining),
            "X-RateLimit-Reset": str(reset_time),
        }

    except Exception as e:
        logger.error(f"Error getting rate limit headers: {str(e)}")
        return {}


async def add_rate_limit_headers(
    response: func.HttpResponse,
    req: func.HttpRequest,
    limit: int,
    window_seconds: int,
    user_id: Optional[str] = None,
) -> func.HttpResponse:
    """Add rate limit headers to response"""
    try:
        client_id = get_client_identifier(req, user_id)
        headers = get_rate_limit_headers(client_id, limit, window_seconds)

        # Add headers to existing response
        if hasattr(response, "headers") and response.headers:
            response.headers.update(headers)
        else:
            response.headers = headers

        return response

    except Exception as e:
        logger.error(f"Error adding rate limit headers: {str(e)}")
        return response

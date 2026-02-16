"""
Authentication module for Vigor Functions
Microsoft Entra ID default tenant authentication with email-based user identification

Phase 7.0 hardening:
  - Task 7.0.10: JWKS key caching with 24-hour TTL
  - Task 7.0.11: JWT issuer claim validation
  - Task 7.0.12: Fully async user provisioning (no sync Cosmos client)
"""

import json
import logging
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import azure.functions as func
import jwt
import aiohttp
import requests

from .config import get_settings
from .helpers import bind_request_context, get_correlation_id

logger = logging.getLogger(__name__)

# ============================================================================
# JWKS Key Cache (Task 7.0.10)
# Keys are cached for 24 hours to avoid 50-200ms latency per request.
# ============================================================================
_jwks_cache: Optional[List[Dict[str, Any]]] = None
_jwks_cache_expiry: float = 0.0
_JWKS_CACHE_TTL_SECONDS = 86400  # 24 hours


class AuthenticationError(Exception):
    """Custom authentication error"""

    pass


def _get_jwks_keys() -> List[Dict[str, Any]]:
    """Get Microsoft JWKS keys with caching (Task 7.0.10) — synchronous fallback"""
    global _jwks_cache, _jwks_cache_expiry

    now = time.time()
    if _jwks_cache is not None and now < _jwks_cache_expiry:
        return _jwks_cache

    jwks_url = "https://login.microsoftonline.com/common/discovery/v2.0/keys"
    jwks_response = requests.get(jwks_url, timeout=10)
    jwks_response.raise_for_status()
    keys = jwks_response.json().get("keys", [])

    _jwks_cache = keys
    _jwks_cache_expiry = now + _JWKS_CACHE_TTL_SECONDS
    logger.info("JWKS keys cached (TTL: 24h)")
    return keys


async def _get_jwks_keys_async() -> List[Dict[str, Any]]:
    """Get Microsoft JWKS keys with caching — async version to avoid blocking the event loop."""
    global _jwks_cache, _jwks_cache_expiry

    now = time.time()
    if _jwks_cache is not None and now < _jwks_cache_expiry:
        return _jwks_cache

    jwks_url = "https://login.microsoftonline.com/common/discovery/v2.0/keys"
    async with aiohttp.ClientSession() as session:
        async with session.get(jwks_url, timeout=aiohttp.ClientTimeout(total=10)) as resp:
            resp.raise_for_status()
            data = await resp.json()
            keys = data.get("keys", [])

    _jwks_cache = keys
    _jwks_cache_expiry = now + _JWKS_CACHE_TTL_SECONDS
    logger.info("JWKS keys cached via async fetch (TTL: 24h)")
    return keys


async def get_current_user_from_token(
    req: func.HttpRequest,
) -> Optional[Dict[str, Any]]:
    """Extract and validate user from Microsoft Entra ID JWT token"""
    try:
        bind_request_context(req)

        # Get token from Authorization header
        auth_header = req.headers.get("Authorization")
        if not auth_header:
            return None

        # Extract token (format: "Bearer <token>")
        if not auth_header.startswith("Bearer "):
            return None

        token = auth_header[7:]  # Remove "Bearer " prefix

        # Validate Microsoft Entra ID token
        user_data = await validate_azure_entra_token(token)
        if not user_data:
            return None

        # Ensure user exists in database (auto-create if needed)
        # Task 7.0.12: This is now fully async — no sync Cosmos fallback
        await ensure_user_exists_async(user_data)

        return user_data

    except Exception as e:
        logger.error(
            "[corr=%s] Error in get_current_user_from_token: %s",
            get_correlation_id(req),
            str(e),
        )
        return None


async def validate_azure_entra_token(token: str) -> Optional[Dict[str, Any]]:
    """Validate Microsoft Entra ID token using default tenant.

    Task 7.0.10: JWKS keys are cached with 24-hour TTL.
    Task 7.0.11: Issuer claim is validated against expected tenant.
    """
    try:
        settings = get_settings()

        # Decode token without verification first to get header info
        unverified_header = jwt.get_unverified_header(token)

        # Get Microsoft's public keys for token validation (cached, async)
        keys = await _get_jwks_keys_async()

        # Find the key used to sign this token
        key_id = unverified_header.get("kid")
        public_key = None

        for key in keys:
            if key["kid"] == key_id:
                public_key = jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
                break

        if not public_key:
            # Key not found in cache — force refresh in case keys were rotated
            global _jwks_cache_expiry
            _jwks_cache_expiry = 0.0
            keys = await _get_jwks_keys_async()
            for key in keys:
                if key["kid"] == key_id:
                    public_key = jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
                    break

        if not public_key:
            logger.warning("Could not find public key for token validation")
            return None

        # Build issuer allowlist (Task 7.0.11)
        # Accept tokens from the configured tenant, or the common endpoint
        tenant_id = settings.AZURE_TENANT_ID
        valid_issuers = [
            f"https://login.microsoftonline.com/{tenant_id}/v2.0",
            f"https://sts.windows.net/{tenant_id}/",
        ]
        # If tenant is 'common', accept any Microsoft-issued token
        if tenant_id == "common":
            issuer_opts = {"verify_iss": False}
        else:
            issuer_opts = {"verify_iss": True}

        # Decode and validate the token
        decode_options = {"verify_exp": True, **issuer_opts}
        decode_kwargs: Dict[str, Any] = {
            "algorithms": ["RS256"],
            "audience": settings.AZURE_CLIENT_ID,
            "options": decode_options,
        }
        if tenant_id != "common":
            decode_kwargs["issuer"] = valid_issuers

        payload = jwt.decode(token, public_key, **decode_kwargs)

        # Extract user information from Microsoft Entra ID token
        user_data = {
            "user_id": payload.get("sub") or payload.get("oid"),
            "email": payload.get("email") or payload.get("preferred_username"),
            "username": payload.get("name") or payload.get("email", "").split("@")[0],
            "tier": "free",  # Default tier for new users
            "tenant_id": payload.get("tid"),
            "exp": payload.get("exp"),
        }

        # Validate required fields
        if not user_data["email"]:
            logger.warning("Token missing required email")
            return None

        return user_data

    except jwt.ExpiredSignatureError:
        logger.warning("JWT token has expired")
        return None
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid JWT token: {str(e)}")
        return None
    except Exception as e:
        logger.error(f"Error validating Azure Entra token: {str(e)}")
        return None


async def ensure_user_exists_async(user_data: Dict[str, Any]) -> None:
    """Ensure user exists in database, create if not.

    Task 7.0.12: Fully async implementation using the async CosmosDBClient.
    Replaces the old sync `ensure_user_exists` that blocked the event loop.
    """
    try:
        # Import here to avoid circular imports at module level
        from .cosmos_db import get_global_client

        client = await get_global_client()
        container = client.containers.get("users")
        if not container:
            logger.error("Users container not initialized")
            return

        email = user_data["email"]

        # Try to get existing user by email
        try:
            query = "SELECT * FROM c WHERE c.email = @email"
            parameters = [{"name": "@email", "value": email}]
            items = []
            async for item in container.query_items(
                query=query,
                parameters=parameters,
            ):
                items.append(item)
                break  # Only need first result

            if items:
                return  # User exists

        except Exception as e:
            logger.warning(f"Error checking existing user: {str(e)}")

        # Create new user record
        new_user = {
            "id": email,
            "email": email,
            "username": user_data.get("username", email.split("@")[0]),
            "tier": "free",
            "fitness_level": "beginner",
            "fitness_goals": ["general_fitness"],
            "available_equipment": ["none"],
            "injury_history": [],
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }

        await container.create_item(body=new_user)
        logger.info(f"Created new user: {email}")

    except Exception as e:
        logger.error(f"Error ensuring user exists: {str(e)}")
        # Don't raise exception - authentication can still proceed


async def require_admin_user(req: func.HttpRequest) -> Optional[Dict[str, Any]]:
    """Require admin user authentication via email whitelist"""
    import os

    # Admin email whitelist — loaded from environment, falls back to default.
    admin_csv = os.environ.get("ADMIN_WHITELIST", "vedprakash.m@outlook.com")
    admin_emails = [e.strip().lower() for e in admin_csv.split(",") if e.strip()]

    try:
        bind_request_context(req)
        user = await get_current_user_from_token(req)
        if not user:
            return None

        email = user.get("email", "").lower()

        # Check if user email is in admin whitelist
        if email not in admin_emails:
            logger.warning(
                "[corr=%s] Non-admin user attempted admin access: %s",
                get_correlation_id(req),
                email,
            )
            return None

        return user

    except Exception as e:
        logger.error(
            "[corr=%s] Error in require_admin_user: %s",
            get_correlation_id(req),
            str(e),
        )
        return None


def extract_user_from_request(req: func.HttpRequest) -> Optional[Dict[str, Any]]:
    """Extract user info from request headers or body for registration/login"""
    try:
        # Try to get from request body first
        try:
            body = req.get_json()
            if body and isinstance(body, dict):
                return body
        except Exception:
            pass

        # Try to get from form data
        try:
            form_data = {}
            for key, value in req.form.items():
                form_data[key] = value
            if form_data:
                return form_data
        except Exception:
            pass

        return None

    except Exception as e:
        logger.error(f"Error extracting user from request: {str(e)}")
        return None


# Note: Rate limiting is handled by shared/rate_limiter.py
# Use apply_rate_limit() / apply_ai_generation_limit() from there.


def create_jwt_response_token(user_data: Dict[str, Any]) -> str:
    """Create a simple JWT token for API responses (optional)"""
    try:
        settings = get_settings()

        # Set expiration (24 hours)
        exp = datetime.now(timezone.utc).timestamp() + (24 * 60 * 60)

        # Create payload
        payload = {
            "sub": user_data["email"],
            "email": user_data["email"],
            "username": user_data.get("username"),
            "tier": user_data.get("tier", "free"),
            "iat": datetime.now(timezone.utc).timestamp(),
            "exp": exp,
        }

        # Encode token (simple JWT for internal use)
        if settings.SECRET_KEY:
            token = jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")
            return token

        return ""

    except Exception as e:
        logger.error(f"Error creating JWT response token: {str(e)}")
        return ""

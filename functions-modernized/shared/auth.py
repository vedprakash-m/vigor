"""
Authentication module for Vigor Functions
Microsoft Entra ID default tenant authentication with email-based user identification
"""

import jwt
import json
import logging
import requests
from datetime import datetime, timezone
from typing import Optional, Dict, Any
import azure.functions as func

from .config import get_settings
from .models import User
from .cosmos_db import get_cosmos_container

logger = logging.getLogger(__name__)


class AuthenticationError(Exception):
    """Custom authentication error"""
    pass


async def get_current_user_from_token(req: func.HttpRequest) -> Optional[Dict[str, Any]]:
    """Extract and validate user from Microsoft Entra ID JWT token"""
    try:
        settings = get_settings()

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
        await ensure_user_exists(user_data)

        return user_data

    except Exception as e:
        logger.error(f"Error in get_current_user_from_token: {str(e)}")
        return None


async def validate_azure_entra_token(token: str) -> Optional[Dict[str, Any]]:
    """Validate Microsoft Entra ID token using default tenant"""
    try:
        settings = get_settings()

        # Decode token without verification first to get header info
        unverified_header = jwt.get_unverified_header(token)

        # Get Microsoft's public keys for token validation
        jwks_url = "https://login.microsoftonline.com/common/discovery/v2.0/keys"
        jwks_response = requests.get(jwks_url, timeout=10)
        jwks_response.raise_for_status()
        jwks = jwks_response.json()

        # Find the key used to sign this token
        key_id = unverified_header.get("kid")
        public_key = None

        for key in jwks["keys"]:
            if key["kid"] == key_id:
                public_key = jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
                break

        if not public_key:
            logger.warning("Could not find public key for token validation")
            return None

        # Decode and validate the token
        payload = jwt.decode(
            token,
            public_key,
            algorithms=["RS256"],
            audience=settings.AZURE_CLIENT_ID,  # App registration client ID
            options={"verify_exp": True}
        )

        # Extract user information from Microsoft Entra ID token
        user_data = {
            "user_id": payload.get("sub") or payload.get("oid"),
            "email": payload.get("email") or payload.get("preferred_username"),
            "username": payload.get("name") or payload.get("email", "").split("@")[0],
            "tier": "free",  # Default tier for new users
            "tenant_id": payload.get("tid"),
            "exp": payload.get("exp")
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


async def ensure_user_exists(user_data: Dict[str, Any]) -> None:
    """Ensure user exists in database, create if not"""
    try:
        container = get_cosmos_container("users")
        email = user_data["email"]

        # Try to get existing user by email
        try:
            query = "SELECT * FROM c WHERE c.email = @email"
            parameters = [{"name": "@email", "value": email}]
            items = list(container.query_items(
                query=query,
                parameters=parameters,
                enable_cross_partition_query=True
            ))

            if items:
                logger.info(f"User already exists: {email}")
                return

        except Exception as e:
            logger.warning(f"Error checking existing user: {str(e)}")

        # Create new user record
        new_user = User(
            id=email,  # Use email as primary key
            email=email,
            username=user_data.get("username", email.split("@")[0]),
            tier="free",
            fitness_level="beginner",
            fitness_goals=["general_fitness"],
            available_equipment=["none"],
            injury_history=[],
            created_at=datetime.now(timezone.utc).isoformat(),
            updated_at=datetime.now(timezone.utc).isoformat()
        )

        container.create_item(body=new_user.dict())
        logger.info(f"Created new user: {email}")

    except Exception as e:
        logger.error(f"Error ensuring user exists: {str(e)}")
        # Don't raise exception - authentication can still proceed


async def require_admin_user(req: func.HttpRequest) -> Optional[Dict[str, Any]]:
    """Require admin user authentication"""
    try:
        user = await get_current_user_from_token(req)
        if not user:
            return None

        # Check if user has admin privileges
        if user.get("tier") != "admin":
            logger.warning(f"Non-admin user attempted admin access: {user.get('email')}")
            return None

        return user

    except Exception as e:
        logger.error(f"Error in require_admin_user: {str(e)}")
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


# Rate limiting helpers
_rate_limit_cache = {}

def check_rate_limit(key: str, limit: int, window: int) -> bool:
    """Simple in-memory rate limiting"""
    try:
        now = datetime.now(timezone.utc).timestamp()

        if key not in _rate_limit_cache:
            _rate_limit_cache[key] = []

        # Clean old entries
        _rate_limit_cache[key] = [
            timestamp for timestamp in _rate_limit_cache[key]
            if now - timestamp < window
        ]

        # Check limit
        if len(_rate_limit_cache[key]) >= limit:
            return False

        # Add current request
        _rate_limit_cache[key].append(now)
        return True

    except Exception as e:
        logger.error(f"Error in rate limiting: {str(e)}")
        return True  # Allow request if rate limiting fails


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
            "exp": exp
        }

        # Encode token (simple JWT for internal use)
        if settings.SECRET_KEY:
            token = jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")
            return token

        return ""

    except Exception as e:
        logger.error(f"Error creating JWT response token: {str(e)}")
        return ""

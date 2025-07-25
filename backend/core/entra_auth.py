"""
Microsoft Entra ID Authentication Service
Compliant with Apps_Auth_Requirement.md for Vedprakash Domain Integration
"""

import json
import logging
import time
from datetime import datetime, timedelta
from typing import Any, Dict, Optional
from urllib.parse import urljoin

import httpx
import jwt
from fastapi import HTTPException, status
from jwt import PyJWKClient
from sqlalchemy.orm import Session

from core.config import get_settings
from database.models import UserProfile
from database.sql_models import UserProfileDB

settings = get_settings()
logger = logging.getLogger(__name__)


class VedUser:
    """
    Standardized User object for Vedprakash domain compliance
    Implements VedUser interface from Apps_Auth_Requirement.md
    """

    def __init__(
        self,
        id: str,
        email: str,
        name: str,
        given_name: str = "",
        family_name: str = "",
        permissions: list[str] = None,
        ved_profile: Dict[str, Any] = None,
    ):
        self.id = id
        self.email = email
        self.name = name
        self.given_name = given_name
        self.family_name = family_name
        self.permissions = permissions or []
        self.ved_profile = ved_profile or {
            "profile_id": id,
            "subscription_tier": "free",
            "apps_enrolled": ["vigor"],
            "preferences": {},
        }

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "email": self.email,
            "name": self.name,
            "given_name": self.given_name,
            "family_name": self.family_name,
            "permissions": self.permissions,
            "ved_profile": self.ved_profile,
        }


class MicrosoftEntraAuth:
    """
    Microsoft Entra ID Authentication Service
    Implements JWKS validation, SSO, and VedUser standardization
    """

    def __init__(self):
        self.tenant_id = settings.AZURE_AD_TENANT_ID or "vedid.onmicrosoft.com"
        self.client_id = settings.AZURE_AD_CLIENT_ID
        self.authority = f"https://login.microsoftonline.com/{self.tenant_id}"
        self.jwks_uri = f"{self.authority}/discovery/v2.0/keys"
        self.issuer = f"https://login.microsoftonline.com/{self.tenant_id}/v2.0"

        # JWKS client with caching (required per Apps_Auth_Requirement.md)
        self.jwks_client = PyJWKClient(
            self.jwks_uri,
            cache_keys=True,
            max_cached_keys=16,
            cache_timeout=3600,  # 1 hour cache
        )

        # Token cache for performance
        self._token_cache = {}
        self._cache_expiry = {}

    async def validate_token(self, token: str) -> VedUser:
        """
        Validate Microsoft Entra ID JWT token and extract VedUser

        Args:
            token: JWT token from Microsoft Entra ID

        Returns:
            VedUser: Standardized user object

        Raises:
            HTTPException: If token validation fails
        """
        try:
            # Check cache first
            if token in self._token_cache and time.time() < self._cache_expiry.get(
                token, 0
            ):
                return self._token_cache[token]

            # Get signing key from JWKS
            signing_key = self.jwks_client.get_signing_key_from_jwt(token)

            # Validate token
            payload = jwt.decode(
                token,
                signing_key.key,
                algorithms=["RS256"],
                audience=self.client_id,
                issuer=self.issuer,
                options={
                    "verify_signature": True,
                    "verify_exp": True,
                    "verify_nbf": True,
                    "verify_iat": True,
                    "verify_aud": True,
                    "verify_iss": True,
                },
            )

            # Extract VedUser from token claims
            ved_user = self._extract_ved_user(payload)

            # Cache the result (cache for token lifetime or max 1 hour)
            exp_time = payload.get("exp", time.time() + 3600)
            cache_time = min(exp_time, time.time() + 3600)
            self._token_cache[token] = ved_user
            self._cache_expiry[token] = cache_time

            return ved_user

        except jwt.ExpiredSignatureError:
            logger.warning("Token has expired")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has expired"
            )
        except jwt.InvalidTokenError as e:
            logger.warning(f"Invalid token: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
            )
        except Exception as e:
            logger.error(f"Token validation failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication failed"
            )

    def _extract_ved_user(self, payload: Dict[str, Any]) -> VedUser:
        """
        Extract VedUser from Microsoft Entra ID token payload
        Maps Microsoft claims to VedUser interface
        """
        user_id = payload.get("sub") or payload.get("oid")
        email = payload.get("email") or payload.get("preferred_username")
        name = payload.get("name", "")
        given_name = payload.get("given_name", "")
        family_name = payload.get("family_name", "")

        # Extract roles/permissions
        permissions = []
        if "roles" in payload:
            permissions.extend(payload["roles"])
        if "groups" in payload:
            permissions.extend([f"group:{group}" for group in payload["groups"]])

        # Build VedProfile
        ved_profile = {
            "profile_id": user_id,
            "subscription_tier": payload.get("ved_subscription_tier", "free"),
            "apps_enrolled": payload.get("ved_apps_enrolled", ["vigor"]),
            "preferences": self._parse_preferences(payload.get("ved_preferences", {})),
        }

        return VedUser(
            id=user_id,
            email=email,
            name=name,
            given_name=given_name,
            family_name=family_name,
            permissions=permissions,
            ved_profile=ved_profile,
        )

    def _parse_preferences(self, preferences: Any) -> Dict[str, Any]:
        """Parse preferences from token claims"""
        if isinstance(preferences, str):
            try:
                return json.loads(preferences)
            except json.JSONDecodeError:
                return {}
        elif isinstance(preferences, dict):
            return preferences
        else:
            return {}

    async def get_or_create_user_profile(
        self, ved_user: VedUser, db: Session
    ) -> UserProfileDB:
        """
        Get or create user profile in database
        Maps VedUser to database model
        """
        try:
            # Check if user exists
            user_profile = (
                db.query(UserProfileDB)
                .filter(UserProfileDB.entra_id == ved_user.id)
                .first()
            )

            if not user_profile:
                # Create new user profile
                user_profile = UserProfileDB(
                    entra_id=ved_user.id,
                    email=ved_user.email,
                    name=ved_user.name,
                    given_name=ved_user.given_name,
                    family_name=ved_user.family_name,
                    subscription_tier=ved_user.ved_profile.get(
                        "subscription_tier", "free"
                    ),
                    permissions=ved_user.permissions,
                    ved_profile=ved_user.ved_profile,
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow(),
                )
                db.add(user_profile)
                db.commit()
                db.refresh(user_profile)
                logger.info(f"Created new user profile for {ved_user.email}")
            else:
                # Update existing user profile
                user_profile.email = ved_user.email
                user_profile.name = ved_user.name
                user_profile.given_name = ved_user.given_name
                user_profile.family_name = ved_user.family_name
                user_profile.permissions = ved_user.permissions
                user_profile.ved_profile = ved_user.ved_profile
                user_profile.updated_at = datetime.utcnow()
                db.commit()
                logger.info(f"Updated user profile for {ved_user.email}")

            return user_profile

        except Exception as e:
            db.rollback()
            logger.error(f"Failed to get/create user profile: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to process user profile",
            )

    def cleanup_cache(self):
        """Clean up expired tokens from cache"""
        current_time = time.time()
        expired_tokens = [
            token
            for token, expiry in self._cache_expiry.items()
            if current_time >= expiry
        ]

        for token in expired_tokens:
            self._token_cache.pop(token, None)
            self._cache_expiry.pop(token, None)


# Global instance
entra_auth = MicrosoftEntraAuth()

"""
Microsoft Entra External ID and OAuth2 Service
Handles OAuth2 flows with PKCE, social login providers, and Microsoft Entra integration
"""

import base64
import hashlib
import json
import logging
import secrets
import urllib.parse
from datetime import datetime, timedelta
from typing import Any, Dict, Optional, Tuple

import httpx
from fastapi import HTTPException, status
from jose import jwt
from sqlalchemy.orm import Session

from core.config import get_settings
from database.models import UserProfile
from database.sql_models import UserProfileDB

settings = get_settings()
logger = logging.getLogger(__name__)


class OAuth2Provider:
    """Base class for OAuth2 providers"""

    def __init__(self, client_id: str, client_secret: str, redirect_uri: str):
        self.client_id = client_id
        self.client_secret = client_secret
        self.redirect_uri = redirect_uri

    def get_authorization_url(self, state: str, code_challenge: str) -> str:
        """Get authorization URL for the provider"""
        raise NotImplementedError

    async def exchange_code_for_token(
        self, code: str, code_verifier: str
    ) -> Dict[str, Any]:
        """Exchange authorization code for access token"""
        raise NotImplementedError

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """Get user information from the provider"""
        raise NotImplementedError


class MicrosoftEntraProvider(OAuth2Provider):
    """Microsoft Entra External ID OAuth2 provider"""

    def __init__(
        self, client_id: str, client_secret: str, redirect_uri: str, tenant_id: str
    ):
        super().__init__(client_id, client_secret, redirect_uri)
        self.tenant_id = tenant_id
        self.authority_url = f"https://login.microsoftonline.com/{tenant_id}"
        self.graph_url = "https://graph.microsoft.com/v1.0"

    def get_authorization_url(self, state: str, code_challenge: str) -> str:
        """Get Microsoft authorization URL with PKCE"""
        params = {
            "client_id": self.client_id,
            "response_type": "code",
            "redirect_uri": self.redirect_uri,
            "scope": "openid profile email User.Read",
            "state": state,
            "code_challenge": code_challenge,
            "code_challenge_method": settings.OAUTH_PKCE_CHALLENGE_METHOD,
            "prompt": "select_account",
        }
        return f"{self.authority_url}/oauth2/v2.0/authorize?" + urllib.parse.urlencode(
            params
        )

    async def exchange_code_for_token(
        self, code: str, code_verifier: str
    ) -> Dict[str, Any]:
        """Exchange authorization code for access token"""
        token_url = f"{self.authority_url}/oauth2/v2.0/token"

        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "code": code,
            "redirect_uri": self.redirect_uri,
            "grant_type": "authorization_code",
            "code_verifier": code_verifier,
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(token_url, data=data)
            response.raise_for_status()
            return response.json()

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """Get user information from Microsoft Graph"""
        headers = {"Authorization": f"Bearer {access_token}"}

        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.graph_url}/me", headers=headers)
            response.raise_for_status()
            return response.json()


class GoogleOAuthProvider(OAuth2Provider):
    """Google OAuth2 provider"""

    def get_authorization_url(self, state: str, code_challenge: str) -> str:
        """Get Google authorization URL with PKCE"""
        params = {
            "client_id": self.client_id,
            "response_type": "code",
            "redirect_uri": self.redirect_uri,
            "scope": "openid profile email",
            "state": state,
            "code_challenge": code_challenge,
            "code_challenge_method": settings.OAUTH_PKCE_CHALLENGE_METHOD,
            "access_type": "offline",
        }
        return "https://accounts.google.com/o/oauth2/auth?" + urllib.parse.urlencode(
            params
        )

    async def exchange_code_for_token(
        self, code: str, code_verifier: str
    ) -> Dict[str, Any]:
        """Exchange authorization code for access token"""
        token_url = "https://oauth2.googleapis.com/token"

        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "code": code,
            "redirect_uri": self.redirect_uri,
            "grant_type": "authorization_code",
            "code_verifier": code_verifier,
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(token_url, data=data)
            response.raise_for_status()
            return response.json()

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """Get user information from Google"""
        headers = {"Authorization": f"Bearer {access_token}"}

        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://www.googleapis.com/oauth2/v2/userinfo", headers=headers
            )
            response.raise_for_status()
            return response.json()


class GitHubOAuthProvider(OAuth2Provider):
    """GitHub OAuth2 provider"""

    def get_authorization_url(self, state: str, code_challenge: str) -> str:
        """Get GitHub authorization URL with PKCE"""
        params = {
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "scope": "user:email",
            "state": state,
            "code_challenge": code_challenge,
            "code_challenge_method": settings.OAUTH_PKCE_CHALLENGE_METHOD,
        }
        return "https://github.com/login/oauth/authorize?" + urllib.parse.urlencode(
            params
        )

    async def exchange_code_for_token(
        self, code: str, code_verifier: str
    ) -> Dict[str, Any]:
        """Exchange authorization code for access token"""
        token_url = "https://github.com/login/oauth/access_token"

        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "code": code,
            "redirect_uri": self.redirect_uri,
            "code_verifier": code_verifier,
        }

        headers = {"Accept": "application/json"}

        async with httpx.AsyncClient() as client:
            response = await client.post(token_url, data=data, headers=headers)
            response.raise_for_status()
            return response.json()

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """Get user information from GitHub"""
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Accept": "application/vnd.github.v3+json",
        }

        async with httpx.AsyncClient() as client:
            # Get user info
            user_response = await client.get(
                "https://api.github.com/user", headers=headers
            )
            user_response.raise_for_status()
            user_data = user_response.json()

            # Get user email (might be private)
            email_response = await client.get(
                "https://api.github.com/user/emails", headers=headers
            )
            email_response.raise_for_status()
            emails = email_response.json()

            # Find primary email
            primary_email = next(
                (email["email"] for email in emails if email["primary"]), None
            )
            user_data["email"] = primary_email

            return user_data


class OAuth2Service:
    """OAuth2 service for handling authentication flows"""

    def __init__(self, db: Session):
        self.db = db
        self.providers = self._initialize_providers()

    def _initialize_providers(self) -> Dict[str, OAuth2Provider]:
        """Initialize OAuth2 providers"""
        providers = {}

        # Microsoft Entra External ID
        if (
            settings.MICROSOFT_CLIENT_ID
            and settings.MICROSOFT_CLIENT_SECRET
            and settings.MICROSOFT_TENANT_ID
        ):
            providers["microsoft"] = MicrosoftEntraProvider(
                client_id=settings.MICROSOFT_CLIENT_ID,
                client_secret=settings.MICROSOFT_CLIENT_SECRET,
                redirect_uri=settings.MICROSOFT_REDIRECT_URI,
                tenant_id=settings.MICROSOFT_TENANT_ID,
            )

        # Google OAuth
        if settings.GOOGLE_CLIENT_ID and settings.GOOGLE_CLIENT_SECRET:
            providers["google"] = GoogleOAuthProvider(
                client_id=settings.GOOGLE_CLIENT_ID,
                client_secret=settings.GOOGLE_CLIENT_SECRET,
                redirect_uri=settings.GOOGLE_REDIRECT_URI,
            )

        # GitHub OAuth
        if settings.GITHUB_CLIENT_ID and settings.GITHUB_CLIENT_SECRET:
            providers["github"] = GitHubOAuthProvider(
                client_id=settings.GITHUB_CLIENT_ID,
                client_secret=settings.GITHUB_CLIENT_SECRET,
                redirect_uri=settings.GITHUB_REDIRECT_URI,
            )

        return providers

    def generate_pkce_pair(self) -> Tuple[str, str]:
        """Generate PKCE code verifier and challenge"""
        code_verifier = (
            base64.urlsafe_b64encode(secrets.token_bytes(32))
            .decode("utf-8")
            .rstrip("=")
        )
        code_challenge = (
            base64.urlsafe_b64encode(
                hashlib.sha256(code_verifier.encode("utf-8")).digest()
            )
            .decode("utf-8")
            .rstrip("=")
        )
        return code_verifier, code_challenge

    def generate_state_token(self, provider: str, code_verifier: str) -> str:
        """Generate secure state token for OAuth flow"""
        payload = {
            "provider": provider,
            "code_verifier": code_verifier,
            "timestamp": datetime.utcnow().isoformat(),
            "nonce": secrets.token_urlsafe(16),
        }
        return jwt.encode(
            payload, settings.OAUTH_STATE_SECRET, algorithm=settings.ALGORITHM
        )

    def verify_state_token(self, state_token: str) -> Dict[str, Any]:
        """Verify and decode state token"""
        try:
            payload = jwt.decode(
                state_token,
                settings.OAUTH_STATE_SECRET,
                algorithms=[settings.ALGORITHM],
            )

            # Check if token is not too old (30 minutes max)
            timestamp = datetime.fromisoformat(payload["timestamp"])
            if datetime.utcnow() - timestamp > timedelta(minutes=30):
                raise HTTPException(status_code=400, detail="OAuth state token expired")

            return payload
        except jwt.JWTError:
            raise HTTPException(status_code=400, detail="Invalid OAuth state token")

    def get_authorization_url(self, provider_name: str) -> Dict[str, str]:
        """Get authorization URL for OAuth provider"""
        if provider_name not in self.providers:
            raise HTTPException(
                status_code=400,
                detail=f"OAuth provider '{provider_name}' not configured",
            )

        provider = self.providers[provider_name]
        code_verifier, code_challenge = self.generate_pkce_pair()
        state_token = self.generate_state_token(provider_name, code_verifier)

        authorization_url = provider.get_authorization_url(state_token, code_challenge)

        return {"authorization_url": authorization_url, "state": state_token}

    async def handle_oauth_callback(
        self, provider_name: str, code: str, state: str
    ) -> Dict[str, Any]:
        """Handle OAuth callback and authenticate user"""
        if provider_name not in self.providers:
            raise HTTPException(
                status_code=400,
                detail=f"OAuth provider '{provider_name}' not configured",
            )

        # Verify state token
        state_payload = self.verify_state_token(state)
        if state_payload["provider"] != provider_name:
            raise HTTPException(status_code=400, detail="Invalid OAuth state")

        provider = self.providers[provider_name]
        code_verifier = state_payload["code_verifier"]

        try:
            # Exchange code for access token
            token_response = await provider.exchange_code_for_token(code, code_verifier)
            access_token = token_response.get("access_token")

            if not access_token:
                raise HTTPException(
                    status_code=400, detail="Failed to obtain access token"
                )

            # Get user information
            user_info = await provider.get_user_info(access_token)

            # Find or create user
            user = await self._find_or_create_oauth_user(provider_name, user_info)

            # Generate application tokens
            from api.services.auth import AuthService

            auth_service = AuthService(self.db)
            tokens = await auth_service._create_user_tokens(user)

            logger.info(f"OAuth login successful: {user.email} via {provider_name}")

            return {
                "access_token": tokens["access_token"],
                "refresh_token": tokens["refresh_token"],
                "token_type": "bearer",
                "expires_in": 30 * 60,  # 30 minutes
                "user": {
                    "id": user.id,
                    "email": user.email,
                    "username": user.username,
                    "tier": user.user_tier.upper(),
                    "oauth_provider": provider_name,
                },
            }

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"OAuth callback error for {provider_name}: {e}")
            raise HTTPException(status_code=500, detail="OAuth authentication failed")

    async def _find_or_create_oauth_user(
        self, provider: str, user_info: Dict[str, Any]
    ) -> UserProfileDB:
        """Find existing user or create new OAuth user"""
        # Extract email from provider-specific user info
        email = self._extract_email(provider, user_info)
        if not email:
            raise HTTPException(
                status_code=400, detail="Email not provided by OAuth provider"
            )

        # Check if user exists
        existing_user = (
            self.db.query(UserProfileDB).filter(UserProfileDB.email == email).first()
        )

        if existing_user:
            # Update OAuth provider info if needed
            if not existing_user.oauth_provider:
                existing_user.oauth_provider = provider
                existing_user.oauth_provider_id = self._extract_provider_id(
                    provider, user_info
                )
                existing_user.last_login = datetime.utcnow()
                self.db.commit()
            return existing_user

        # Create new user
        username = self._generate_username(provider, user_info, email)

        new_user = UserProfileDB(
            email=email,
            username=username,
            user_tier="free",
            is_active=True,
            oauth_provider=provider,
            oauth_provider_id=self._extract_provider_id(provider, user_info),
            created_at=datetime.utcnow(),
            last_login=datetime.utcnow(),
        )

        self.db.add(new_user)
        self.db.commit()
        self.db.refresh(new_user)

        return new_user

    def _extract_email(self, provider: str, user_info: Dict[str, Any]) -> Optional[str]:
        """Extract email from provider-specific user info"""
        if provider == "microsoft":
            return user_info.get("mail") or user_info.get("userPrincipalName")
        elif provider == "google":
            return user_info.get("email")
        elif provider == "github":
            return user_info.get("email")
        return None

    def _extract_provider_id(
        self, provider: str, user_info: Dict[str, Any]
    ) -> Optional[str]:
        """Extract provider-specific user ID"""
        if provider == "microsoft":
            return user_info.get("id")
        elif provider == "google":
            return user_info.get("id")
        elif provider == "github":
            return str(user_info.get("id"))
        return None

    def _generate_username(
        self, provider: str, user_info: Dict[str, Any], email: str
    ) -> str:
        """Generate username from provider info"""
        # Try to get name from provider
        name = None
        if provider == "microsoft":
            name = user_info.get("displayName")
        elif provider == "google":
            name = user_info.get("name")
        elif provider == "github":
            name = user_info.get("login")

        if name:
            # Clean the name to create a valid username
            username = "".join(c.lower() for c in name if c.isalnum() or c in "-_")
        else:
            # Fall back to email prefix
            username = email.split("@")[0].lower()

        # Ensure username is unique
        base_username = username
        counter = 1
        while (
            self.db.query(UserProfileDB)
            .filter(UserProfileDB.username == username)
            .first()
        ):
            username = f"{base_username}{counter}"
            counter += 1

        return username

    def get_available_providers(self) -> Dict[str, str]:
        """Get list of available OAuth providers"""
        return {
            provider_name: provider.__class__.__name__
            for provider_name, provider in self.providers.items()
        }

"""
Enhanced Authentication Service with Production Security
Handles user registration, login, token management with comprehensive security measures
"""

import logging
from datetime import datetime, timedelta
from typing import Any, Dict, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from core.config import get_settings
from core.security import (
    create_access_token,
    get_password_hash,
    verify_password,
    verify_token,
)
from database.connection import get_db
from database.models import UserProfile, UserTier
from database.sql_models import UserProfileDB

settings = get_settings()
security = HTTPBearer()
logger = logging.getLogger(__name__)

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Token constants
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7
RESET_TOKEN_EXPIRE_MINUTES = 15


class AuthService:
    """Enhanced authentication service with production security features"""

    def __init__(self, db: Session):
        self.db = db

    async def register_user(
        self, email: str, username: str, password: str
    ) -> Dict[str, Any]:
        """
        Register a new user with comprehensive validation and security

        Args:
            email: User's email address (validated)
            username: User's username (validated)
            password: User's password (validated)

        Returns:
            Dict containing user info and tokens

        Raises:
            HTTPException: On validation or creation errors
        """
        try:
            # Check if user already exists
            existing_user = (
                self.db.query(UserProfile)
                .filter(
                    (UserProfile.email == email) | (UserProfile.username == username)
                )
                .first()
            )

            if existing_user:
                if existing_user.email == email:
                    raise HTTPException(
                        status_code=409, detail="Email already registered"
                    )
                else:
                    raise HTTPException(
                        status_code=409, detail="Username already taken"
                    )

            # Hash password securely
            hashed_password = pwd_context.hash(password)

            # Create new user
            new_user = UserProfile(
                email=email,
                username=username,
                hashed_password=hashed_password,
                is_active=True,
                created_at=datetime.utcnow(),
                user_tier=UserTier.FREE,  # Default tier
            )

            self.db.add(new_user)
            self.db.commit()
            self.db.refresh(new_user)

            # Generate tokens
            tokens = await self._create_user_tokens(new_user)

            logger.info(f"User registered successfully: {email}")

            return {
                "access_token": tokens["access_token"],
                "refresh_token": tokens["refresh_token"],
                "token_type": "bearer",
                "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
                "user": {
                    "id": new_user.id,
                    "email": new_user.email,
                    "username": new_user.username,
                    "tier": new_user.user_tier.value.upper(),
                    "is_active": new_user.is_active,
                },
            }

        except HTTPException:
            self.db.rollback()
            raise
        except IntegrityError as e:
            self.db.rollback()
            logger.error(f"Database integrity error during registration: {e}")
            raise HTTPException(
                status_code=409,
                detail="User with this email or username already exists",
            )
        except Exception as e:
            self.db.rollback()
            logger.error(f"Unexpected error during user registration: {e}")
            raise HTTPException(
                status_code=500, detail="Registration failed due to server error"
            )

    async def authenticate_user(self, email: str, password: str) -> Dict[str, Any]:
        """
        Authenticate user with email and password

        Args:
            email: User's email address
            password: User's password

        Returns:
            Dict containing user info and tokens

        Raises:
            HTTPException: On authentication failure
        """
        try:
            # Find user by email
            user = self.db.query(UserProfile).filter(UserProfile.email == email).first()

            if not user:
                # Don't reveal whether email exists or not
                raise HTTPException(status_code=401, detail="Invalid email or password")

            # Check if user is active
            if not user.is_active:
                raise HTTPException(status_code=401, detail="Account is disabled")

            # Verify password
            if not pwd_context.verify(password, user.hashed_password):
                raise HTTPException(status_code=401, detail="Invalid email or password")

            # Update last login
            user.last_login = datetime.utcnow()
            self.db.commit()

            # Generate tokens
            tokens = await self._create_user_tokens(user)

            logger.info(f"User authenticated successfully: {email}")

            return {
                "access_token": tokens["access_token"],
                "refresh_token": tokens["refresh_token"],
                "token_type": "bearer",
                "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
                "user": {
                    "id": user.id,
                    "email": user.email,
                    "username": user.username,
                    "tier": user.user_tier.value.upper(),
                    "is_active": user.is_active,
                    "last_login": (
                        user.last_login.isoformat() if user.last_login else None
                    ),
                },
            }

        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Unexpected error during authentication: {e}")
            raise HTTPException(
                status_code=500, detail="Authentication failed due to server error"
            )

    async def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """
        Refresh access token using refresh token

        Args:
            refresh_token: Valid refresh token

        Returns:
            Dict containing new tokens

        Raises:
            HTTPException: On token validation failure
        """
        try:
            # Decode refresh token
            payload = jwt.decode(
                refresh_token, settings.SECRET_KEY, algorithms=["HS256"]
            )

            user_id = payload.get("sub")
            token_type = payload.get("type")

            if token_type != "refresh":
                raise HTTPException(status_code=401, detail="Invalid token type")

            # Find user
            user = self.db.query(UserProfile).filter(UserProfile.id == user_id).first()

            if not user:
                raise HTTPException(status_code=401, detail="User not found")

            if not user.is_active:
                raise HTTPException(status_code=401, detail="Account is disabled")

            # Generate new tokens
            tokens = await self._create_user_tokens(user)

            logger.info(f"Token refreshed successfully for user: {user.email}")

            return {
                "access_token": tokens["access_token"],
                "refresh_token": tokens["refresh_token"],
                "token_type": "bearer",
                "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
                "user": {
                    "id": user.id,
                    "email": user.email,
                    "username": user.username,
                    "tier": user.user_tier.value.upper(),
                    "is_active": user.is_active,
                },
            }

        except JWTError as e:
            logger.warning(f"JWT error during token refresh: {e}")
            raise HTTPException(
                status_code=401, detail="Invalid or expired refresh token"
            )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Unexpected error during token refresh: {e}")
            raise HTTPException(
                status_code=500, detail="Token refresh failed due to server error"
            )

    async def request_password_reset(self, email: str) -> Dict[str, Any]:
        """
        Request password reset for user

        Args:
            email: User's email address

        Returns:
            Dict with success message (same regardless of user existence)
        """
        try:
            user = self.db.query(UserProfile).filter(UserProfile.email == email).first()

            if user and user.is_active:
                # Generate reset token
                reset_token = jwt.encode(
                    {
                        "sub": user.id,
                        "email": user.email,
                        "type": "password_reset",
                        "exp": datetime.utcnow()
                        + timedelta(minutes=RESET_TOKEN_EXPIRE_MINUTES),
                    },
                    settings.SECRET_KEY,
                    algorithm="HS256",
                )

                # TODO: Send email with reset link
                # For now, log the reset token (remove in production)
                reset_link = f"https://vigor.com/reset-password?token={reset_token}"
                logger.info(f"Password reset requested for {email}: {reset_link}")

                # In production, you would:
                # await send_password_reset_email(user.email, reset_link)

            # Always return the same message to prevent email enumeration
            return {
                "message": "If the email exists, a reset link has been sent",
                "success": True,
            }

        except Exception as e:
            logger.error(f"Error during password reset request: {e}")
            # Still return success to prevent information disclosure
            return {
                "message": "If the email exists, a reset link has been sent",
                "success": True,
            }

    async def reset_password(
        self, reset_token: str, new_password: str
    ) -> Dict[str, Any]:
        """
        Reset user password using reset token

        Args:
            reset_token: Valid password reset token
            new_password: New password (already validated)

        Returns:
            Dict with success message and user_id

        Raises:
            HTTPException: On token validation or reset failure
        """
        try:
            # Decode reset token
            payload = jwt.decode(reset_token, settings.SECRET_KEY, algorithms=["HS256"])

            user_id = payload.get("sub")
            token_type = payload.get("type")

            if token_type != "password_reset":
                raise HTTPException(status_code=400, detail="Invalid token type")

            # Find user
            user = self.db.query(UserProfile).filter(UserProfile.id == user_id).first()

            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            if not user.is_active:
                raise HTTPException(status_code=400, detail="Account is disabled")

            # Hash new password
            hashed_password = pwd_context.hash(new_password)

            # Update password
            user.hashed_password = hashed_password
            user.updated_at = datetime.utcnow()

            self.db.commit()

            logger.info(f"Password reset successfully for user: {user.email}")

            return {
                "message": "Password reset successfully",
                "user_id": user.id,
                "success": True,
            }

        except JWTError as e:
            logger.warning(f"JWT error during password reset: {e}")
            raise HTTPException(
                status_code=400, detail="Invalid or expired reset token"
            )
        except HTTPException:
            self.db.rollback()
            raise
        except Exception as e:
            self.db.rollback()
            logger.error(f"Unexpected error during password reset: {e}")
            raise HTTPException(
                status_code=500, detail="Password reset failed due to server error"
            )

    async def verify_token(self, token: str) -> Dict[str, Any]:
        """
        Verify if an access token is valid

        Args:
            token: Access token to verify

        Returns:
            Dict with token validity and user info

        Raises:
            HTTPException: On token validation failure
        """
        try:
            # Decode token
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])

            user_id = payload.get("sub")
            token_type = payload.get("type", "access")  # Default to access token

            if token_type != "access":
                raise HTTPException(status_code=401, detail="Invalid token type")

            # Find user
            user = self.db.query(UserProfile).filter(UserProfile.id == user_id).first()

            if not user:
                raise HTTPException(status_code=401, detail="User not found")

            if not user.is_active:
                raise HTTPException(status_code=401, detail="Account is disabled")

            return {
                "valid": True,
                "user": {
                    "id": user.id,
                    "email": user.email,
                    "username": user.username,
                    "tier": user.user_tier.value.upper(),
                    "is_active": user.is_active,
                },
                "expires_at": datetime.fromtimestamp(payload.get("exp")).isoformat(),
            }

        except JWTError as e:
            logger.warning(f"JWT error during token verification: {e}")
            raise HTTPException(status_code=401, detail="Invalid or expired token")
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Unexpected error during token verification: {e}")
            raise HTTPException(status_code=500, detail="Token verification failed")

    async def _create_user_tokens(self, user: UserProfile) -> Dict[str, str]:
        """
        Create access and refresh tokens for user

        Args:
            user: User profile object

        Returns:
            Dict containing access_token and refresh_token
        """
        # Access token payload
        access_payload = {
            "sub": user.id,
            "email": user.email,
            "username": user.username,
            "tier": user.user_tier.value,
            "type": "access",
            "iat": datetime.utcnow(),
            "exp": datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
        }

        # Refresh token payload (fewer claims for security)
        refresh_payload = {
            "sub": user.id,
            "type": "refresh",
            "iat": datetime.utcnow(),
            "exp": datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS),
        }

        # Generate tokens
        access_token = jwt.encode(
            access_payload, settings.SECRET_KEY, algorithm="HS256"
        )
        refresh_token = jwt.encode(
            refresh_payload, settings.SECRET_KEY, algorithm="HS256"
        )

        return {"access_token": access_token, "refresh_token": refresh_token}


# Legacy functions for backwards compatibility (will be deprecated)
async def register_user(db: Session, user_data: dict) -> UserProfile:
    """Legacy function - use AuthService.register_user instead"""
    auth_service = AuthService(db)
    result = await auth_service.register_user(
        email=user_data["email"],
        username=user_data["username"],
        password=user_data["password"],
    )
    # Return user object for compatibility
    return db.query(UserProfile).filter(UserProfile.id == result["user"]["id"]).first()


async def authenticate_user(
    db: Session, email: str, password: str
) -> Optional[UserProfile]:
    """Legacy function - use AuthService.authenticate_user instead"""
    try:
        auth_service = AuthService(db)
        result = await auth_service.authenticate_user(email, password)
        return (
            db.query(UserProfile).filter(UserProfile.id == result["user"]["id"]).first()
        )
    except HTTPException:
        return None


async def create_user_token(user: UserProfile) -> Dict[str, str]:
    """Legacy function - use AuthService._create_user_tokens instead"""
    # This is a simplified version for compatibility
    access_payload = {
        "sub": user.id,
        "email": user.email,
        "tier": user.user_tier.value,
        "exp": datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    }

    access_token = jwt.encode(access_payload, settings.SECRET_KEY, algorithm="HS256")

    return {"access_token": access_token, "token_type": "bearer"}


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> UserProfile:
    """Get current user from JWT token."""
    try:
        token = credentials.credentials
        payload = verify_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.query(UserProfileDB).filter(UserProfileDB.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return UserProfile.model_validate(user)

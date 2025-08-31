"""
FastAPI Dependencies for Microsoft Entra ID Authentication
Implements standardized authentication for Vedprakash domain compliance
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from core.entra_auth import VedUser, entra_auth
from database.connection import get_db
from database.sql_models import UserProfileDB

# HTTP Bearer token extractor
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> VedUser:
    """
    Extract and validate Microsoft Entra ID token
    Returns standardized VedUser object

    Required for all protected endpoints
    """
    try:
        token = credentials.credentials
        ved_user = await entra_auth.validate_token(token)

        # Ensure user profile exists in database
        await entra_auth.get_or_create_user_profile(ved_user, db)

        return ved_user

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication failed"
        )


async def get_current_user_profile(
    ved_user: VedUser = Depends(get_current_user), db: Session = Depends(get_db)
) -> UserProfileDB:
    """
    Get user profile from database
    Returns database model for the authenticated user
    """
    try:
        user_profile = (
            db.query(UserProfileDB)
            .filter(UserProfileDB.entra_id == ved_user.id)
            .first()
        )

        if not user_profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User profile not found"
            )

        return user_profile

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve user profile",
        )


def require_permissions(required_permissions: list[str]):
    """
    Dependency factory for permission-based access control

    Args:
        required_permissions: List of required permissions

    Returns:
        Dependency function that validates user permissions
    """

    async def permission_checker(
        ved_user: VedUser = Depends(get_current_user),
    ) -> VedUser:
        """Check if user has required permissions"""
        user_permissions = set(ved_user.permissions)
        required_perms = set(required_permissions)

        if not required_perms.issubset(user_permissions):
            missing_perms = required_perms - user_permissions
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Missing: {', '.join(missing_perms)}",
            )

        return ved_user

    return permission_checker


def require_subscription_tier(required_tier: str):
    """
    Dependency factory for subscription tier-based access control

    Args:
        required_tier: Required subscription tier (free, premium, enterprise)

    Returns:
        Dependency function that validates user subscription tier
    """
    tier_hierarchy = {"free": 0, "premium": 1, "enterprise": 2}

    async def tier_checker(ved_user: VedUser = Depends(get_current_user)) -> VedUser:
        """Check if user has required subscription tier"""
        user_tier = ved_user.ved_profile.get("subscription_tier", "free")

        if tier_hierarchy.get(user_tier, 0) < tier_hierarchy.get(required_tier, 0):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Requires {required_tier} subscription tier or higher",
            )

        return ved_user

    return tier_checker


# Admin permission check
require_admin = require_permissions(["admin"])

# Premium tier requirement
require_premium = require_subscription_tier("premium")

# Enterprise tier requirement
require_enterprise = require_subscription_tier("enterprise")

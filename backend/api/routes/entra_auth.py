"""
Microsoft Entra ID Authentication API Routes
Implements Vedprakash domain authentication standard
"""

from typing import Any, Dict

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from core.auth_dependencies import get_current_user, get_current_user_profile
from core.entra_auth import VedUser
from database.connection import get_db
from database.sql_models import UserProfileDB

router = APIRouter(prefix="/api/v1/entra-auth", tags=["Microsoft Entra ID"])


@router.get("/me", response_model=Dict[str, Any])
async def get_current_user_info(
    ved_user: VedUser = Depends(get_current_user),
) -> Dict[str, Any]:
    """
    Get current authenticated user information
    Returns standardized VedUser object
    """
    return {
        "user": ved_user.to_dict(),
        "authenticated": True,
        "provider": "microsoft_entra_id",
    }


@router.get("/profile", response_model=Dict[str, Any])
async def get_user_profile(
    user_profile: UserProfileDB = Depends(get_current_user_profile),
    ved_user: VedUser = Depends(get_current_user),
) -> Dict[str, Any]:
    """
    Get user profile with fitness data
    Combines VedUser standardization with app-specific profile
    """
    return {
        "user": ved_user.to_dict(),
        "profile": {
            "id": user_profile.id,
            "fitness_level": user_profile.fitness_level,
            "goals": user_profile.goals,
            "equipment": user_profile.equipment,
            "injuries": user_profile.injuries,
            "preferences": user_profile.preferences,
            "subscription_tier": user_profile.subscription_tier,
            "monthly_budget": user_profile.monthly_budget,
            "current_month_usage": user_profile.current_month_usage,
            "created_at": (
                user_profile.created_at.isoformat() if user_profile.created_at else None
            ),
            "updated_at": (
                user_profile.updated_at.isoformat() if user_profile.updated_at else None
            ),
        },
    }


@router.post("/validate-token")
async def validate_token(
    ved_user: VedUser = Depends(get_current_user),
) -> Dict[str, Any]:
    """
    Validate Microsoft Entra ID token
    Returns validation status and user info
    """
    return {"valid": True, "user": ved_user.to_dict(), "message": "Token is valid"}


@router.get("/health")
async def health_check() -> Dict[str, str]:
    """
    Health check endpoint for Microsoft Entra ID authentication service
    """
    return {
        "status": "healthy",
        "service": "microsoft_entra_auth",
        "provider": "vedid.onmicrosoft.com",
    }

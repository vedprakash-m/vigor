"""
User tier management API routes
"""

from typing import Any, Dict

from api.schemas.auth import UserResponse
from api.services.auth import get_current_user
from api.services.usage_tracking import UsageTrackingService
from database.connection import get_db
from database.models import UserTier
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/tiers", tags=["user-tiers"])


@router.get("/current", response_model=Dict[str, Any])
async def get_current_tier_info(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current user's tier and usage information"""

    usage_service = UsageTrackingService(db)

    # Get usage limits and remaining quotas
    limits_check = await usage_service.check_user_limits(current_user.id)

    return {
        "user_tier": current_user.user_tier,
        "monthly_budget": current_user.monthly_budget,
        "current_month_usage": current_user.current_month_usage,
        "limits_check": limits_check,
        "tier_features": {
            "free": {
                "daily_limit": 10,
                "weekly_limit": 50,
                "monthly_limit": 200,
                "monthly_budget": 5.0,
                "features": ["Basic AI coaching", "Simple workouts", "Basic analytics"],
            },
            "premium": {
                "daily_limit": 50,
                "weekly_limit": 300,
                "monthly_limit": 1000,
                "monthly_budget": 25.0,
                "features": [
                    "Advanced AI coaching",
                    "Custom workouts",
                    "Progress tracking",
                    "Nutrition advice",
                ],
            },
            "unlimited": {
                "daily_limit": 1000,
                "weekly_limit": 5000,
                "monthly_limit": 20000,
                "monthly_budget": 100.0,
                "features": [
                    "Unlimited AI coaching",
                    "Premium workouts",
                    "Advanced analytics",
                    "Personal trainer mode",
                ],
            },
        },
    }


@router.post("/upgrade")
async def upgrade_tier(
    new_tier: str,
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Upgrade user's tier (in production this would integrate with payment processing)"""

    # Validate tier
    valid_tiers = ["free", "premium", "unlimited"]
    if new_tier not in valid_tiers:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid tier. Must be one of: {valid_tiers}",
        )

    # Check if it's actually an upgrade
    tier_hierarchy = {"free": 0, "premium": 1, "unlimited": 2}
    current_tier_level = tier_hierarchy.get(current_user.user_tier, 0)
    new_tier_level = tier_hierarchy.get(new_tier, 0)

    if new_tier_level <= current_tier_level:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only upgrade to higher tiers",
        )

    # In production, you would:
    # 1. Process payment through Stripe/similar
    # 2. Verify payment success
    # 3. Then upgrade the tier

    usage_service = UsageTrackingService(db)
    success = await usage_service.upgrade_user_tier(current_user.id, UserTier(new_tier))

    if success:
        return {
            "message": f"Successfully upgraded to {new_tier} tier",
            "new_tier": new_tier,
            "upgrade_date": "2025-06-02T10:00:00Z",  # In production, use actual datetime
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to upgrade tier",
        )


@router.get("/usage-analytics")
async def get_usage_analytics(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get detailed usage analytics for the current user"""

    usage_service = UsageTrackingService(db)
    limits_check = await usage_service.check_user_limits(current_user.id)

    # Calculate usage percentages
    if limits_check.get("allowed"):
        remaining = limits_check.get("remaining", {})
        usage_percentages = {
            "daily": (
                max(0, 100 - (remaining.get("daily", 0) / 10 * 100))
                if current_user.user_tier == "free"
                else 0
            ),
            "weekly": (
                max(0, 100 - (remaining.get("weekly", 0) / 50 * 100))
                if current_user.user_tier == "free"
                else 0
            ),
            "monthly": (
                max(0, 100 - (remaining.get("monthly", 0) / 200 * 100))
                if current_user.user_tier == "free"
                else 0
            ),
            "budget": max(
                0,
                100 - (remaining.get("budget", 0) / current_user.monthly_budget * 100),
            ),
        }
    else:
        usage_percentages = {"daily": 100, "weekly": 100, "monthly": 100, "budget": 100}

    return {
        "current_usage": {
            "monthly_cost": current_user.current_month_usage,
            "monthly_budget": current_user.monthly_budget,
            "budget_remaining": current_user.monthly_budget
            - current_user.current_month_usage,
        },
        "usage_percentages": usage_percentages,
        "limits_status": limits_check,
        "recommendations": {
            "should_upgrade": usage_percentages.get("monthly", 0) > 80,
            "next_tier": (
                "premium"
                if current_user.user_tier == "free"
                else "unlimited" if current_user.user_tier == "premium" else None
            ),
        },
    }

"""
User tier and usage tracking service
"""

from datetime import date, datetime
from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from database.models import UserTier
from database.sql_models import (UserProfileDB, UserTierLimitsDB,
                                 UserUsageLimitsDB)


class UsageTrackingService:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def check_user_limits(self, user_id: str) -> dict:
        """Check if user has exceeded their tier limits"""

        # Get user's current tier
        user_result = await self.db.execute(
            select(
                UserProfileDB.user_tier,
                UserProfileDB.monthly_budget,
                UserProfileDB.current_month_usage,
            ).where(UserProfileDB.id == user_id)
        )
        user_data = user_result.first()

        if not user_data:
            return {"allowed": False, "reason": "User not found"}

        user_tier, monthly_budget, current_usage = user_data

        # Get tier limits
        tier_result = await self.db.execute(
            select(UserTierLimitsDB).where(UserTierLimitsDB.tier_name == user_tier)
        )
        tier_limits = tier_result.scalar_one_or_none()

        if not tier_limits:
            return {"allowed": False, "reason": "Tier limits not found"}

        # Get current usage
        usage_result = await self.db.execute(
            select(UserUsageLimitsDB).where(UserUsageLimitsDB.user_id == user_id)
        )
        usage_data = usage_result.scalar_one_or_none()

        if not usage_data:
            # Create usage record if it doesn't exist
            usage_data = UserUsageLimitsDB(
                user_id=user_id,
                daily_requests_used=0,
                weekly_requests_used=0,
                monthly_requests_used=0,
                last_reset_date=date.today(),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            self.db.add(usage_data)
            await self.db.commit()

        # Check limits
        checks = {
            "daily": usage_data.daily_requests_used < tier_limits.daily_limit,
            "weekly": usage_data.weekly_requests_used < tier_limits.weekly_limit,
            "monthly": usage_data.monthly_requests_used < tier_limits.monthly_limit,
            "budget": current_usage < monthly_budget,
        }

        if all(checks.values()):
            return {
                "allowed": True,
                "remaining": {
                    "daily": tier_limits.daily_limit - usage_data.daily_requests_used,
                    "weekly": tier_limits.weekly_limit
                    - usage_data.weekly_requests_used,
                    "monthly": tier_limits.monthly_limit
                    - usage_data.monthly_requests_used,
                    "budget": monthly_budget - current_usage,
                },
            }
        else:
            failed_checks = [check for check, passed in checks.items() if not passed]
            return {
                "allowed": False,
                "reason": f"Exceeded limits: {', '.join(failed_checks)}",
                "limits_exceeded": failed_checks,
            }

    async def track_usage(self, user_id: str, cost: float = 0.01) -> bool:
        """Track a user's API usage and cost"""

        # Update usage counters
        await self.db.execute(
            update(UserUsageLimitsDB)
            .where(UserUsageLimitsDB.user_id == user_id)
            .values(
                daily_requests_used=UserUsageLimitsDB.daily_requests_used + 1,
                weekly_requests_used=UserUsageLimitsDB.weekly_requests_used + 1,
                monthly_requests_used=UserUsageLimitsDB.monthly_requests_used + 1,
                updated_at=datetime.utcnow(),
            )
        )

        # Update monthly cost
        await self.db.execute(
            update(UserProfileDB)
            .where(UserProfileDB.id == user_id)
            .values(
                current_month_usage=UserProfileDB.current_month_usage + cost,
                updated_at=datetime.utcnow(),
            )
        )

        await self.db.commit()
        return True

    async def upgrade_user_tier(self, user_id: str, new_tier: UserTier) -> bool:
        """Upgrade a user's tier"""

        await self.db.execute(
            update(UserProfileDB)
            .where(UserProfileDB.id == user_id)
            .values(
                user_tier=new_tier.value,
                tier_updated_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
        )

        await self.db.commit()
        return True

    async def reset_monthly_usage(self, user_id: str) -> bool:
        """Reset monthly usage counters (run monthly)"""

        await self.db.execute(
            update(UserProfileDB)
            .where(UserProfileDB.id == user_id)
            .values(current_month_usage=0.0, updated_at=datetime.utcnow())
        )

        await self.db.execute(
            update(UserUsageLimitsDB)
            .where(UserUsageLimitsDB.user_id == user_id)
            .values(monthly_requests_used=0, updated_at=datetime.utcnow())
        )

        await self.db.commit()
        return True

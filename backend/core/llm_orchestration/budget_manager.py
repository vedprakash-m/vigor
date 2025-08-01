"""
Budget Manager
Handles budget enforcement, tracking, and cost management for LLM usage
"""

import logging
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Dict, List, Optional, Union

from ..azure_cost_management import AzureCostManagementService

logger = logging.getLogger(__name__)


class BudgetStatus(Enum):
    """Budget status enumeration"""

    ACTIVE = "active"
    AVAILABLE = "available"  # Alias for ACTIVE
    WARNING = "warning"
    EXCEEDED = "exceeded"
    BLOCKED = "blocked"  # Alias for EXCEEDED
    SUSPENDED = "suspended"


@dataclass
class BudgetUsage:
    """Budget usage tracking"""

    budget_id: str
    user_id: Optional[str]
    user_groups: List[str]
    current_usage: float
    budget_limit: float
    reset_period_start: datetime
    reset_period_end: datetime
    status: BudgetStatus
    last_updated: datetime


class BudgetManager:
    """
    Enterprise budget management for LLM usage
    Tracks usage, enforces limits, and provides cost analytics
    """

    def __init__(
        self,
        db_session=None,
        azure_cost_service: Optional[AzureCostManagementService] = None,
    ):
        self.db = db_session
        self.azure_cost_service = azure_cost_service
        self._usage_cache: Dict[str, BudgetUsage] = {}
        self._global_usage = 0.0
        self._global_limit = 10000.0  # Default global limit

    async def initialize(self):
        """Initialize budget manager"""
        try:
            # Load existing usage data from database
            await self._load_usage_data()
            logger.info("Budget manager initialized")
        except Exception as e:
            logger.error(f"Failed to initialize budget manager: {e}")
            raise

    async def can_proceed(
        self, user_id: str, user_groups: List[str], estimated_cost: float = 0.0
    ) -> bool:
        """
        Check if a request can proceed based on budget constraints

        Args:
            user_id: User identifier
            user_groups: User's group memberships
            estimated_cost: Estimated cost of the request

        Returns:
            True if request can proceed, False otherwise
        """
        try:
            # Check global budget first
            if not await self._check_global_budget(estimated_cost):
                logger.warning("Global budget exceeded")
                return False

            # Check user/group specific budgets
            budget_usage = await self._get_budget_usage(user_id, user_groups)

            if not budget_usage:
                # No specific budget = use global budget
                return True

            # Check if budget allows the request
            projected_usage = budget_usage.current_usage + estimated_cost

            if projected_usage > budget_usage.budget_limit:
                logger.warning(
                    f"Budget limit would be exceeded for {user_id}: "
                    f"{projected_usage:.4f} > {budget_usage.budget_limit:.4f}"
                )
                return False

            return True

        except Exception as e:
            logger.error(f"Budget check failed for {user_id}: {e}")
            # Fail safe - allow request if budget check fails
            return True

    async def record_usage(
        self, user_id: str, user_groups: List[str], actual_cost: float
    ):
        """
        Record actual usage and update budget tracking

        Args:
            user_id: User identifier
            user_groups: User's group memberships
            actual_cost: Actual cost incurred
        """
        try:
            # Update global usage
            self._global_usage += actual_cost

            # Update user/group specific usage
            budget_usage = await self._get_budget_usage(user_id, user_groups)

            if budget_usage:
                budget_usage.current_usage += actual_cost
                budget_usage.last_updated = datetime.utcnow()

                # Update status based on usage
                usage_percentage = (
                    budget_usage.current_usage / budget_usage.budget_limit
                )

                if usage_percentage >= 1.0:
                    budget_usage.status = BudgetStatus.EXCEEDED
                elif usage_percentage >= 0.9:
                    budget_usage.status = BudgetStatus.WARNING
                else:
                    budget_usage.status = BudgetStatus.ACTIVE

                # Cache and persist the update
                cache_key = f"{user_id}:{':'.join(sorted(user_groups))}"
                self._usage_cache[cache_key] = budget_usage

                await self._persist_usage_data(budget_usage)

            logger.debug(f"Recorded usage for {user_id}: ${actual_cost:.6f}")

        except Exception as e:
            logger.error(f"Failed to record usage for {user_id}: {e}")

    async def get_usage_summary(
        self, user_id: Optional[str] = None, user_groups: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Get usage summary for a user or globally

        Args:
            user_id: User identifier (optional)
            user_groups: User groups (optional)

        Returns:
            Usage summary dictionary
        """
        try:
            if user_id:
                budget_usage = await self._get_budget_usage(user_id, user_groups or [])

                if budget_usage:
                    return {
                        "user_id": user_id,
                        "current_usage": budget_usage.current_usage,
                        "budget_limit": budget_usage.budget_limit,
                        "usage_percentage": (
                            budget_usage.current_usage / budget_usage.budget_limit
                        )
                        * 100,
                        "status": budget_usage.status.value,
                        "reset_period_start": budget_usage.reset_period_start.isoformat(),
                        "reset_period_end": budget_usage.reset_period_end.isoformat(),
                        "days_remaining": (
                            budget_usage.reset_period_end - datetime.utcnow()
                        ).days,
                    }

            # Return global summary
            return {
                "global_usage": self._global_usage,
                "global_limit": self._global_limit,
                "usage_percentage": (self._global_usage / self._global_limit) * 100,
                "total_users_tracked": len(self._usage_cache),
            }

        except Exception as e:
            logger.error(f"Failed to get usage summary: {e}")
            return {"error": str(e)}

    async def get_global_status(self) -> Dict[str, Any]:
        """Get global budget status"""
        try:
            return {
                "total_usage": self._global_usage,
                "global_limit": self._global_limit,
                "usage_percentage": (self._global_usage / self._global_limit) * 100,
                "status": (
                    "active" if self._global_usage < self._global_limit else "exceeded"
                ),
                "tracked_users": len(self._usage_cache),
            }
        except Exception as e:
            logger.error(f"Failed to get global status: {e}")
            return {"error": str(e)}

    async def reset_budgets(self):
        """Reset budgets for new period (typically called by scheduler)"""
        try:
            current_time = datetime.utcnow()
            reset_count = 0

            for _cache_key, budget_usage in self._usage_cache.items():
                if current_time >= budget_usage.reset_period_end:
                    # Reset the budget
                    budget_usage.current_usage = 0.0
                    budget_usage.status = BudgetStatus.ACTIVE
                    budget_usage.reset_period_start = current_time

                    # Calculate new reset period end based on budget config
                    # This would need budget configuration to determine period
                    budget_usage.reset_period_end = current_time + timedelta(
                        days=30
                    )  # Default monthly

                    await self._persist_usage_data(budget_usage)
                    reset_count += 1

            logger.info(f"Reset {reset_count} budgets")

        except Exception as e:
            logger.error(f"Failed to reset budgets: {e}")

    async def set_budget_alert_thresholds(
        self, user_id: str, user_groups: List[str], thresholds: List[float]
    ):
        """Set alert thresholds for budget monitoring"""
        try:
            # Implementation would store alert thresholds
            # and trigger notifications when reached
            pass
        except Exception as e:
            logger.error(f"Failed to set alert thresholds: {e}")

    async def sync_with_azure_costs(self) -> Dict[str, Any]:
        """
        Synchronize budget usage with Azure Cost Management

        Returns:
            Dictionary with sync results and current cost data
        """
        if not self.azure_cost_service:
            logger.warning("Azure Cost Management service not configured")
            return {"status": "skipped", "reason": "service_not_configured"}

        try:
            # Get current costs from Azure
            current_costs = await self.azure_cost_service.get_current_costs()

            # Update global usage with actual Azure costs
            if current_costs and "total_cost" in current_costs:
                self._global_usage = current_costs["total_cost"]
                logger.info(
                    f"Updated global usage from Azure: ${self._global_usage:.4f}"
                )

            # Check for budget alerts
            if current_costs and "budget_alerts" in current_costs:
                await self._process_azure_budget_alerts(current_costs["budget_alerts"])

            return {
                "status": "success",
                "global_usage": self._global_usage,
                "azure_costs": current_costs,
                "last_sync": datetime.utcnow().isoformat(),
            }

        except Exception as e:
            logger.error(f"Failed to sync with Azure costs: {e}")
            return {"status": "error", "error": str(e)}

    async def validate_budget_with_azure(self, estimated_cost: float) -> bool:
        """
        Validate budget against Azure Cost Management quotas

        Args:
            estimated_cost: Estimated cost for the operation

        Returns:
            True if within budget, False otherwise
        """
        if not self.azure_cost_service:
            return True  # Allow if Azure service not configured

        try:
            # Get current Azure budget status
            budget_status = await self.azure_cost_service.validate_budget(
                estimated_cost
            )

            if not budget_status.get("within_budget", True):
                logger.warning(
                    f"Azure budget validation failed: {budget_status.get('reason', 'Unknown')}"
                )
                return False

            return True

        except Exception as e:
            logger.error(f"Azure budget validation failed: {e}")
            # Allow on validation failure to prevent blocking
            return True

    async def get_real_time_cost_analytics(self) -> Dict[str, Any]:
        """
        Get real-time cost analytics from Azure Cost Management

        Returns:
            Dictionary with current cost analytics
        """
        analytics = {
            "global_usage": self._global_usage,
            "global_limit": self._global_limit,
            "usage_percentage": (self._global_usage / self._global_limit) * 100,
            "cached_budgets": len(self._usage_cache),
            "last_updated": datetime.utcnow().isoformat(),
        }

        if self.azure_cost_service:
            try:
                azure_analytics = await self.azure_cost_service.get_cost_analytics()
                analytics.update(
                    {
                        "azure_costs": azure_analytics,
                        "data_source": "azure_real_time",
                    }
                )
            except Exception as e:
                logger.error(f"Failed to get Azure analytics: {e}")
                analytics["azure_error"] = str(e)
        else:
            analytics["data_source"] = "local_cache"

        return analytics

    async def _process_azure_budget_alerts(self, alerts: List[Dict[str, Any]]):
        """Process budget alerts from Azure Cost Management"""
        try:
            for alert in alerts:
                alert_level = alert.get("alert_level", "info")
                message = alert.get("message", "Budget alert")

                logger.warning(f"Azure budget alert [{alert_level}]: {message}")

                # Update local budget status if critical
                if alert_level in ["critical", "warning"]:
                    await self._update_budget_status_from_alert(alert)

        except Exception as e:
            logger.error(f"Failed to process Azure budget alerts: {e}")

    async def _update_budget_status_from_alert(self, alert: Dict[str, Any]):
        """Update local budget status based on Azure alert"""
        try:
            alert_level = alert.get("alert_level", "info")

            if alert_level == "critical":
                # Update global status to blocked
                self._global_usage = self._global_limit  # Force limit
                logger.critical("Global budget blocked due to Azure critical alert")

        except Exception as e:
            logger.error(f"Failed to update budget status from alert: {e}")

    # Private helper methods

    async def _check_global_budget(self, estimated_cost: float) -> bool:
        """Check if global budget allows the request"""
        projected_global = self._global_usage + estimated_cost
        return projected_global <= self._global_limit

    async def _get_budget_usage(
        self, user_id: str, user_groups: List[str]
    ) -> Optional[BudgetUsage]:
        """Get budget usage for user/groups"""
        try:
            # Create cache key
            cache_key = f"{user_id}:{':'.join(sorted(user_groups))}"

            # Check cache first
            if cache_key in self._usage_cache:
                return self._usage_cache[cache_key]

            # Load from database or create new
            budget_usage = await self._load_user_budget_usage(user_id, user_groups)

            if budget_usage:
                self._usage_cache[cache_key] = budget_usage

            return budget_usage

        except Exception as e:
            logger.error(f"Failed to get budget usage for {user_id}: {e}")
            return None

    async def _load_user_budget_usage(
        self, user_id: str, user_groups: List[str]
    ) -> Optional[BudgetUsage]:
        """Load user budget usage from database"""
        try:
            # Implementation would query database for existing budget usage
            # For now, create a default budget if none exists

            current_time = datetime.utcnow()

            return BudgetUsage(
                budget_id=f"budget_{user_id}",
                user_id=user_id,
                user_groups=user_groups,
                current_usage=0.0,
                budget_limit=100.0,  # Default $100 monthly limit
                reset_period_start=current_time,
                reset_period_end=current_time + timedelta(days=30),
                status=BudgetStatus.ACTIVE,
                last_updated=current_time,
            )

        except Exception as e:
            logger.error(f"Failed to load budget usage for {user_id}: {e}")
            return None

    async def _load_usage_data(self):
        """Load all usage data from database"""
        try:
            # Implementation would load from database
            # For now, initialize with empty cache
            self._usage_cache = {}
            self._global_usage = 0.0

        except Exception as e:
            logger.error(f"Failed to load usage data: {e}")

    async def _persist_usage_data(self, budget_usage: BudgetUsage):
        """Persist budget usage to database"""
        try:
            # Implementation would save to database
            # For now, just log the update
            logger.debug(f"Persisting budget usage for {budget_usage.user_id}")

        except Exception as e:
            logger.error(f"Failed to persist usage data: {e}")


class CostEstimator:
    """
    Cost estimation utilities for different LLM providers
    """

    # Cost per 1K tokens for different models (example pricing)
    MODEL_COSTS = {
        "gpt-4": {"input": 0.03, "output": 0.06},
        "gpt-3.5-turbo": {"input": 0.001, "output": 0.002},
        "claude-3-opus": {"input": 0.015, "output": 0.075},
        "claude-3-sonnet": {"input": 0.003, "output": 0.015},
        "gemini-pro": {"input": 0.0005, "output": 0.0015},
        "perplexity": {"input": 0.001, "output": 0.002},
    }

    @classmethod
    def estimate_cost(
        cls, model_name: str, input_tokens: int, output_tokens: int
    ) -> float:
        """
        Estimate cost for a request

        Args:
            model_name: Name of the model
            input_tokens: Number of input tokens
            output_tokens: Number of output tokens

        Returns:
            Estimated cost in USD
        """
        try:
            # Find matching cost configuration
            costs = None
            for model_key, model_costs in cls.MODEL_COSTS.items():
                if model_key.lower() in model_name.lower():
                    costs = model_costs
                    break

            if not costs:
                # Default cost if model not found
                costs = {"input": 0.001, "output": 0.002}

            # Calculate cost
            input_cost = (input_tokens / 1000) * costs["input"]
            output_cost = (output_tokens / 1000) * costs["output"]

            return input_cost + output_cost

        except Exception as e:
            logger.warning(f"Cost estimation failed for {model_name}: {e}")
            return 0.001  # Default small cost

    @classmethod
    def estimate_tokens(cls, text: str) -> int:
        """
        Rough estimation of token count from text

        Args:
            text: Input text

        Returns:
            Estimated token count
        """
        # Rough approximation: 1 token ≈ 0.75 words
        word_count = len(text.split())
        return int(word_count / 0.75)


class BudgetAlert:
    """Budget alert management"""

    def __init__(self):
        self.alert_callbacks = []

    def add_alert_callback(self, callback):
        """Add callback for budget alerts"""
        self.alert_callbacks.append(callback)

    async def check_and_send_alerts(self, budget_usage: BudgetUsage):
        """Check if alerts should be sent"""
        try:
            usage_percentage = budget_usage.current_usage / budget_usage.budget_limit

            # Send alert at 80%, 90%, and 100%
            alert_thresholds = [0.8, 0.9, 1.0]

            for threshold in alert_thresholds:
                if usage_percentage >= threshold:
                    await self._send_alert(budget_usage, threshold)

        except Exception as e:
            logger.error(f"Failed to check/send alerts: {e}")

    async def _send_alert(self, budget_usage: BudgetUsage, threshold: float):
        """Send budget alert"""
        try:
            alert_data = {
                "user_id": budget_usage.user_id,
                "threshold": threshold,
                "current_usage": budget_usage.current_usage,
                "budget_limit": budget_usage.budget_limit,
                "status": budget_usage.status.value,
            }

            for callback in self.alert_callbacks:
                try:
                    await callback(alert_data)
                except Exception as e:
                    logger.error(f"Alert callback failed: {e}")

        except Exception as e:
            logger.error(f"Failed to send alert: {e}")

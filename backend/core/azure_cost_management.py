"""
Azure Cost Management Integration Service
Integrates with Azure Cost Management API for real-time cost tracking and automated alerts
"""

import logging
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from typing import Any

from azure.identity import DefaultAzureCredential
from azure.mgmt.consumption import ConsumptionManagementClient

from core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)


@dataclass
class CostAlert:
    """Cost alert configuration"""

    alert_id: str
    threshold_percentage: float
    budget_amount: float
    current_spend: float
    alert_type: str  # 'warning', 'critical', 'exceeded'
    created_at: datetime
    last_triggered: datetime | None = None


@dataclass
class RealTimeCostMetrics:
    """Real-time cost metrics"""

    current_month_spend: float
    budget_limit: float
    utilization_percentage: float
    daily_spend_trend: list[float]
    projected_monthly_spend: float
    cost_per_user: dict[str, float]
    cost_per_model: dict[str, float]
    alert_status: str
    last_updated: datetime


class BudgetStatus(Enum):
    """Budget status enumeration"""

    ACTIVE = "active"
    AVAILABLE = "available"  # Alias for ACTIVE
    WARNING = "warning"
    EXCEEDED = "exceeded"
    BLOCKED = "blocked"  # Alias for EXCEEDED
    SUSPENDED = "suspended"


class AzureCostManagementService:
    """
    Azure Cost Management API integration for real-time cost tracking
    Provides automated budget monitoring, alerts, and cost optimization
    """

    def __init__(self, db_session=None):
        self.db = db_session
        self.subscription_id = (
            settings.AZURE_SUBSCRIPTION_ID
            if hasattr(settings, "AZURE_SUBSCRIPTION_ID")
            else None
        )
        self.resource_group = (
            settings.AZURE_RESOURCE_GROUP
            if hasattr(settings, "AZURE_RESOURCE_GROUP")
            else "vigor-rg"
        )
        self.monthly_budget = getattr(settings, "AZURE_MONTHLY_BUDGET", 100.0)
        self.cost_threshold = getattr(settings, "AI_COST_THRESHOLD", 85.0)

        # Initialize Azure clients
        self.credential = None
        self.consumption_client = None
        self._initialize_azure_clients()

        # Cost tracking state
        self._cost_cache: dict[str, RealTimeCostMetrics] = {}
        self._alerts: dict[str, CostAlert] = {}
        self._last_cost_update = datetime.utcnow() - timedelta(hours=1)

    def _initialize_azure_clients(self):
        """Initialize Azure management clients"""
        try:
            if self.subscription_id:
                self.credential = DefaultAzureCredential()
                self.consumption_client = ConsumptionManagementClient(
                    credential=self.credential, subscription_id=self.subscription_id
                )
                logger.info("Azure Cost Management client initialized")
            else:
                logger.warning(
                    "Azure subscription ID not configured - using local cost tracking only"
                )
        except Exception as e:
            logger.error(f"Failed to initialize Azure clients: {e}")

    async def get_real_time_costs(
        self, force_refresh: bool = False
    ) -> RealTimeCostMetrics:
        """
        Get real-time cost metrics with Azure API integration

        Args:
            force_refresh: Force refresh from Azure API

        Returns:
            Real-time cost metrics
        """
        try:
            # Check cache first (refresh every 5 minutes)
            cache_key = "current_costs"
            if not force_refresh and cache_key in self._cost_cache:
                cached_metrics = self._cost_cache[cache_key]
                if (datetime.utcnow() - cached_metrics.last_updated).seconds < 300:
                    return cached_metrics

            # Get costs from Azure API if available
            current_spend = 0.0
            daily_trend = []

            if self.consumption_client:
                try:
                    current_spend = await self._get_azure_current_spend()
                    daily_trend = await self._get_azure_daily_trend()
                    await self._get_azure_cost_by_resource()
                except Exception as e:
                    logger.warning(f"Azure API call failed, using local tracking: {e}")
                    current_spend = await self._get_local_current_spend()
                    daily_trend = await self._get_local_daily_trend()
            else:
                # Fall back to local cost tracking
                current_spend = await self._get_local_current_spend()
                daily_trend = await self._get_local_daily_trend()

            # Calculate metrics
            utilization = (current_spend / self.monthly_budget) * 100
            projected_spend = self._calculate_projected_spend(
                current_spend, daily_trend
            )
            alert_status = self._determine_alert_status(utilization)

            # Get per-user and per-model costs
            cost_per_user = await self._get_cost_per_user()
            cost_per_model = await self._get_cost_per_model()

            metrics = RealTimeCostMetrics(
                current_month_spend=current_spend,
                budget_limit=self.monthly_budget,
                utilization_percentage=utilization,
                daily_spend_trend=daily_trend,
                projected_monthly_spend=projected_spend,
                cost_per_user=cost_per_user,
                cost_per_model=cost_per_model,
                alert_status=alert_status,
                last_updated=datetime.utcnow(),
            )

            # Cache the results
            self._cost_cache[cache_key] = metrics

            # Check for alerts
            await self._check_and_trigger_alerts(metrics)

            return metrics

        except Exception as e:
            logger.error(f"Failed to get real-time costs: {e}")
            # Return fallback metrics
            return RealTimeCostMetrics(
                current_month_spend=0.0,
                budget_limit=self.monthly_budget,
                utilization_percentage=0.0,
                daily_spend_trend=[],
                projected_monthly_spend=0.0,
                cost_per_user={},
                cost_per_model={},
                alert_status="unknown",
                last_updated=datetime.utcnow(),
            )

    async def validate_budget_before_operation(
        self, user_id: str, estimated_cost: float, operation_type: str = "ai_request"
    ) -> dict[str, Any]:
        """
        Validate budget before expensive AI operation

        Args:
            user_id: User identifier
            estimated_cost: Estimated cost of operation
            operation_type: Type of operation

        Returns:
            Validation result with approval/denial and reasons
        """
        try:
            # Get current cost metrics
            current_metrics = await self.get_real_time_costs()

            # Check global budget
            projected_total = current_metrics.current_month_spend + estimated_cost
            global_utilization = (projected_total / self.monthly_budget) * 100

            # Check user-specific budget
            user_current_cost = current_metrics.cost_per_user.get(user_id, 0.0)
            user_budget_limit = await self._get_user_budget_limit(user_id)
            user_projected = user_current_cost + estimated_cost
            user_utilization = (
                (user_projected / user_budget_limit) * 100
                if user_budget_limit > 0
                else 0
            )

            # Determine approval
            approved = True
            reasons = []

            if global_utilization > 95:
                approved = False
                reasons.append(
                    f"Global budget exceeded: {global_utilization:.1f}% utilization"
                )
            elif global_utilization > self.cost_threshold:
                reasons.append(
                    f"Warning: High global utilization ({global_utilization:.1f}%)"
                )

            if user_utilization > 100:
                approved = False
                reasons.append(
                    f"User budget exceeded: {user_utilization:.1f}% utilization"
                )
            elif user_utilization > 80:
                reasons.append(
                    f"Warning: High user utilization ({user_utilization:.1f}%)"
                )

            # Model switching recommendation
            recommended_model = None
            if not approved or global_utilization > 70:
                recommended_model = await self._get_cost_optimized_model(operation_type)

            return {
                "approved": approved,
                "estimated_cost": estimated_cost,
                "global_utilization": global_utilization,
                "user_utilization": user_utilization,
                "reasons": reasons,
                "recommended_model": recommended_model,
                "cost_metrics": {
                    "current_spend": current_metrics.current_month_spend,
                    "budget_limit": current_metrics.budget_limit,
                    "projected_spend": current_metrics.projected_monthly_spend,
                },
            }

        except Exception as e:
            logger.error(f"Budget validation failed: {e}")
            return {
                "approved": True,  # Fail open to avoid blocking users
                "estimated_cost": estimated_cost,
                "global_utilization": 0.0,
                "user_utilization": 0.0,
                "reasons": [f"Budget validation error: {str(e)}"],
                "recommended_model": None,
                "cost_metrics": {},
            }

    async def configure_automated_alerts(
        self, alert_configs: list[dict[str, Any]]
    ) -> dict[str, str]:
        """
        Configure automated cost alerts

        Args:
            alert_configs: List of alert configurations

        Returns:
            Configuration results
        """
        try:
            results = {}

            for config in alert_configs:
                alert_id = config.get("alert_id", f"alert_{len(self._alerts)}")
                threshold = config.get("threshold_percentage", 80.0)
                alert_type = config.get("alert_type", "warning")

                alert = CostAlert(
                    alert_id=alert_id,
                    threshold_percentage=threshold,
                    budget_amount=self.monthly_budget,
                    current_spend=0.0,
                    alert_type=alert_type,
                    created_at=datetime.utcnow(),
                )

                self._alerts[alert_id] = alert
                results[alert_id] = "configured"

                # Set up Azure alert if possible
                if self.consumption_client:
                    azure_result = await self._create_azure_alert(alert)
                    results[f"{alert_id}_azure"] = azure_result

            logger.info(f"Configured {len(alert_configs)} cost alerts")
            return results

        except Exception as e:
            logger.error(f"Failed to configure alerts: {e}")
            return {"error": str(e)}

    async def get_cost_analytics(
        self, time_range: str = "30d", include_forecast: bool = True
    ) -> dict[str, Any]:
        """
        Get detailed cost analytics and forecasting

        Args:
            time_range: Time range for analytics (7d, 30d, 90d)
            include_forecast: Include cost forecasting

        Returns:
            Detailed cost analytics
        """
        try:
            # Parse time range
            days = int(time_range.replace("d", ""))
            start_date = datetime.utcnow() - timedelta(days=days)
            end_date = datetime.utcnow()

            # Get historical data
            historical_costs = await self._get_historical_costs(start_date, end_date)

            # Calculate trends
            cost_trend = self._calculate_cost_trend(historical_costs)

            # Generate forecast if requested
            forecast = {}
            if include_forecast:
                forecast = await self._generate_cost_forecast(historical_costs)

            # Get breakdown by service/model
            cost_breakdown = await self._get_cost_breakdown(start_date, end_date)

            # Calculate optimization opportunities
            optimization_tips = await self._get_optimization_recommendations()

            return {
                "time_range": time_range,
                "period": {
                    "start": start_date.isoformat(),
                    "end": end_date.isoformat(),
                },
                "total_cost": sum(historical_costs),
                "average_daily_cost": (
                    sum(historical_costs) / len(historical_costs)
                    if historical_costs
                    else 0
                ),
                "cost_trend": cost_trend,
                "forecast": forecast,
                "breakdown": cost_breakdown,
                "optimization_recommendations": optimization_tips,
                "alert_summary": await self._get_alert_summary(),
            }

        except Exception as e:
            logger.error(f"Failed to generate cost analytics: {e}")
            return {"error": str(e)}

    async def get_budget_status(self) -> dict[str, Any]:
        """
        Get current budget status

        Returns:
            Dictionary with budget status information
        """
        try:
            metrics = await self.get_current_costs()

            return {
                "budget_name": "Vigor-AI-Budget",
                "current_spend": metrics.get("total_cost", 0.0),
                "budget_limit": self.monthly_budget,
                "percentage_used": metrics.get("utilization_percentage", 0.0),
                "status": (
                    "active"
                    if metrics.get("utilization_percentage", 0) < 80
                    else "warning"
                ),
                "alerts_enabled": True,
            }

        except Exception as e:
            logger.error(f"Failed to get budget status: {e}")
            return {
                "budget_name": "Vigor-AI-Budget",
                "current_spend": 0.0,
                "budget_limit": self.monthly_budget,
                "percentage_used": 0.0,
                "status": "active",
                "alerts_enabled": True,
                "error": str(e),
            }

    async def get_cost_breakdown(self) -> list[dict[str, Any]]:
        """
        Get cost breakdown by service/resource

        Returns:
            List of cost breakdown items
        """
        try:
            breakdown = []

            if self.consumption_client:
                try:
                    cost_by_resource = await self._get_azure_cost_by_resource()
                    total_cost = sum(cost_by_resource.values())

                    for resource, cost in cost_by_resource.items():
                        percentage = (cost / total_cost * 100) if total_cost > 0 else 0
                        breakdown.append(
                            {
                                "service_name": resource,
                                "cost": cost,
                                "percentage": percentage,
                                "trend": "stable",  # Could be enhanced with historical data
                            }
                        )

                except Exception as e:
                    logger.warning(f"Azure cost breakdown failed: {e}")

            # If no Azure data or error, provide fallback data
            if not breakdown:
                # Get local cost data
                local_costs = await self._get_cost_per_model()
                total_local = sum(local_costs.values())

                for model, cost in local_costs.items():
                    percentage = (cost / total_local * 100) if total_local > 0 else 0
                    breakdown.append(
                        {
                            "service_name": f"LLM-{model}",
                            "cost": cost,
                            "percentage": percentage,
                            "trend": "stable",
                        }
                    )

            return breakdown

        except Exception as e:
            logger.error(f"Failed to get cost breakdown: {e}")
            return []

    async def get_budget_alerts(self) -> list[dict[str, Any]]:
        """
        Get active budget alerts

        Returns:
            List of budget alerts
        """
        try:
            alerts = []
            metrics = await self.get_current_costs()
            utilization = metrics.get("utilization_percentage", 0.0)

            # Generate alerts based on utilization thresholds
            if utilization >= 100:
                alerts.append(
                    {
                        "alert_id": "budget-exceeded",
                        "alert_level": "critical",
                        "message": f"Budget exceeded! Current usage: {utilization:.1f}%",
                        "threshold_percentage": 100,
                        "triggered_at": datetime.utcnow().isoformat(),
                    }
                )
            elif utilization >= 90:
                alerts.append(
                    {
                        "alert_id": "budget-critical",
                        "alert_level": "warning",
                        "message": f"Budget usage critical: {utilization:.1f}%",
                        "threshold_percentage": 90,
                        "triggered_at": datetime.utcnow().isoformat(),
                    }
                )
            elif utilization >= 80:
                alerts.append(
                    {
                        "alert_id": "budget-warning",
                        "alert_level": "info",
                        "message": f"Budget usage high: {utilization:.1f}%",
                        "threshold_percentage": 80,
                        "triggered_at": datetime.utcnow().isoformat(),
                    }
                )

            return alerts

        except Exception as e:
            logger.error(f"Failed to get budget alerts: {e}")
            return []

    async def create_budget_alert(
        self, budget_name: str, threshold_percentage: float, email_contacts: list[str]
    ) -> dict[str, Any]:
        """
        Create or update a budget alert

        Args:
            budget_name: Name of the budget
            threshold_percentage: Alert threshold percentage
            email_contacts: List of email addresses for notifications

        Returns:
            Dictionary with alert creation result
        """
        try:
            # In a real implementation, this would create alerts in Azure
            # For now, we'll simulate the creation and store locally

            alert_id = f"alert-{budget_name}-{threshold_percentage}".lower().replace(
                " ", "-"
            )

            # Store alert configuration (could be in database)
            alert_config = {
                "alert_id": alert_id,
                "budget_name": budget_name,
                "threshold_percentage": threshold_percentage,
                "email_contacts": email_contacts,
                "created_at": datetime.utcnow().isoformat(),
                "enabled": True,
            }

            # In production, save to database
            logger.info(f"Created budget alert: {alert_config}")

            return {
                "alert_id": alert_id,
                "status": "created",
                "message": f"Budget alert created for {threshold_percentage}% threshold",
            }

        except Exception as e:
            logger.error(f"Failed to create budget alert: {e}")
            raise Exception(f"Failed to create budget alert: {str(e)}")

    async def delete_budget_alert(self, alert_id: str) -> dict[str, Any]:
        """
        Delete a budget alert

        Args:
            alert_id: ID of the alert to delete

        Returns:
            Dictionary with deletion result
        """
        try:
            # In a real implementation, this would delete from Azure
            # For now, simulate deletion

            logger.info(f"Deleted budget alert: {alert_id}")

            return {
                "status": "deleted",
                "message": f"Budget alert {alert_id} deleted successfully",
            }

        except Exception as e:
            logger.error(f"Failed to delete budget alert: {e}")
            raise Exception(f"Failed to delete budget alert: {str(e)}")

    async def get_cost_optimization_recommendations(self) -> list[dict[str, Any]]:
        """
        Get AI-powered cost optimization recommendations

        Returns:
            List of optimization recommendations
        """
        try:
            recommendations = []
            metrics = await self.get_current_costs()
            cost_breakdown = await self.get_cost_breakdown()

            # Analyze current usage patterns
            current_spend = metrics.get("total_cost", 0.0)
            utilization = metrics.get("utilization_percentage", 0.0)

            # Generate recommendations based on usage patterns

            # 1. Budget optimization
            if utilization > 80:
                recommendations.append(
                    {
                        "title": "Increase Budget Monitoring",
                        "description": "Your current usage is approaching budget limits. Consider implementing more granular cost controls or increasing budget allocation.",
                        "potential_savings": 0,
                        "impact": "High",
                        "effort": "Low",
                        "category": "budget",
                    }
                )

            # 2. Model optimization
            if cost_breakdown:
                expensive_models = [
                    item for item in cost_breakdown if item["percentage"] > 50
                ]
                if expensive_models:
                    recommendations.append(
                        {
                            "title": "Optimize Model Usage",
                            "description": f"Consider using more cost-effective models for some tasks. {expensive_models[0]['service_name']} accounts for {expensive_models[0]['percentage']:.1f}% of costs.",
                            "potential_savings": current_spend
                            * 0.3,  # Estimate 30% savings
                            "impact": "Medium",
                            "effort": "Medium",
                            "category": "model",
                        }
                    )

            # 3. Caching recommendations
            if current_spend > 10:  # If spending more than $10
                recommendations.append(
                    {
                        "title": "Implement Response Caching",
                        "description": "Enable response caching for similar queries to reduce redundant API calls and save costs.",
                        "potential_savings": current_spend
                        * 0.2,  # Estimate 20% savings
                        "impact": "Medium",
                        "effort": "Low",
                        "category": "caching",
                    }
                )

            # 4. Batch processing
            recommendations.append(
                {
                    "title": "Batch Similar Requests",
                    "description": "Group similar requests together to optimize token usage and reduce per-request overhead.",
                    "potential_savings": current_spend * 0.15,  # Estimate 15% savings
                    "impact": "Low",
                    "effort": "Medium",
                    "category": "batching",
                }
            )

            # 5. Usage patterns
            if utilization < 30:
                recommendations.append(
                    {
                        "title": "Consider Reducing Budget",
                        "description": "Your current usage is low compared to allocated budget. You could reduce budget allocation and reallocate resources.",
                        "potential_savings": (self.monthly_budget - current_spend)
                        * 0.5,
                        "impact": "Low",
                        "effort": "Low",
                        "category": "budget",
                    }
                )

            return recommendations

        except Exception as e:
            logger.error(f"Failed to get optimization recommendations: {e}")
            return [
                {
                    "title": "Enable Azure Cost Management",
                    "description": "Configure Azure Cost Management API to get detailed cost optimization recommendations.",
                    "potential_savings": 0,
                    "impact": "High",
                    "effort": "Medium",
                    "category": "setup",
                }
            ]

    # Private helper methods

    async def _get_azure_current_spend(self) -> float:
        """Get current month spend from Azure API"""
        try:
            # Use Azure Consumption API to get current costs
            # This is a simplified implementation - real implementation would use proper Azure SDK
            end_date = datetime.utcnow()
            end_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

            # Mock implementation - replace with actual Azure API call
            return 45.50  # Example current spend

        except Exception as e:
            logger.error(f"Azure current spend query failed: {e}")
            return 0.0

    async def _get_local_current_spend(self) -> float:
        """Get current spend from local LLM usage tracking"""
        try:
            if not self.db:
                return 0.0

            # Query local AI usage logs for current month
            from sqlalchemy import extract, func

            from database.sql_models import AIUsageLogDB

            current_month = datetime.utcnow().month
            current_year = datetime.utcnow().year

            result = (
                self.db.query(func.sum(AIUsageLogDB.cost))
                .filter(
                    extract("month", AIUsageLogDB.created_at) == current_month,
                    extract("year", AIUsageLogDB.created_at) == current_year,
                )
                .scalar()
            )

            return float(result or 0.0)

        except Exception as e:
            logger.error(f"Local cost query failed: {e}")
            return 0.0

    async def _get_user_budget_limit(self, user_id: str) -> float:
        """Get user-specific budget limit"""
        try:
            if not self.db:
                return 5.0  # Default user budget

            from database.sql_models import UserProfileDB

            user = (
                self.db.query(UserProfileDB).filter(UserProfileDB.id == user_id).first()
            )
            if user:
                return float(user.monthly_budget or 5.0)

            return 5.0

        except Exception as e:
            logger.error(f"Failed to get user budget: {e}")
            return 5.0

    async def _get_cost_optimized_model(self, operation_type: str) -> str | None:
        """Get cost-optimized model recommendation"""
        try:
            # Model cost efficiency mapping
            cost_efficient_models = {
                "chat": "gemini-pro",  # Lower cost than GPT-4
                "generation": "claude-3-haiku",  # Fastest and cheapest
                "analysis": "gpt-3.5-turbo",  # Good balance
                "default": "gemini-pro",
            }

            return cost_efficient_models.get(
                operation_type, cost_efficient_models["default"]
            )

        except Exception as e:
            logger.error(f"Failed to get model recommendation: {e}")
            return None

    async def _check_and_trigger_alerts(self, metrics: RealTimeCostMetrics):
        """Check cost thresholds and trigger alerts"""
        try:
            for _alert_id, alert in self._alerts.items():
                if metrics.utilization_percentage >= alert.threshold_percentage:
                    # Check if alert was recently triggered (avoid spam)
                    if alert.last_triggered:
                        time_since_last = datetime.utcnow() - alert.last_triggered
                        if time_since_last.seconds < 3600:  # 1 hour cooldown
                            continue

                    # Trigger alert
                    await self._send_cost_alert(alert, metrics)
                    alert.last_triggered = datetime.utcnow()

        except Exception as e:
            logger.error(f"Alert checking failed: {e}")

    async def _send_cost_alert(self, alert: CostAlert, metrics: RealTimeCostMetrics):
        """Send cost alert notification"""
        try:
            logger.warning(
                f"COST ALERT [{alert.alert_type.upper()}]: "
                f"Budget utilization {metrics.utilization_percentage:.1f}% "
                f"exceeds threshold {alert.threshold_percentage}%"
            )

            # Here you would integrate with notification systems:
            # - Email alerts
            # - Slack notifications
            # - SMS alerts
            # - Dashboard notifications

        except Exception as e:
            logger.error(f"Failed to send alert: {e}")

    async def _get_cost_per_user(self) -> dict[str, float]:
        """Get cost breakdown by user"""
        try:
            if not self.db:
                return {}

            from sqlalchemy import extract, func

            from database.sql_models import AIUsageLogDB

            current_month = datetime.utcnow().month
            current_year = datetime.utcnow().year

            results = (
                self.db.query(
                    AIUsageLogDB.user_id,
                    func.sum(AIUsageLogDB.cost).label("total_cost"),
                )
                .filter(
                    extract("month", AIUsageLogDB.created_at) == current_month,
                    extract("year", AIUsageLogDB.created_at) == current_year,
                )
                .group_by(AIUsageLogDB.user_id)
                .all()
            )

            return {result.user_id: float(result.total_cost) for result in results}

        except Exception as e:
            logger.error(f"Failed to get per-user costs: {e}")
            return {}

    async def _get_cost_per_model(self) -> dict[str, float]:
        """Get cost breakdown by model"""
        try:
            if not self.db:
                return {}

            from sqlalchemy import extract, func

            from database.sql_models import AIUsageLogDB

            current_month = datetime.utcnow().month
            current_year = datetime.utcnow().year

            results = (
                self.db.query(
                    AIUsageLogDB.model_name,
                    func.sum(AIUsageLogDB.cost).label("total_cost"),
                )
                .filter(
                    extract("month", AIUsageLogDB.created_at) == current_month,
                    extract("year", AIUsageLogDB.created_at) == current_year,
                )
                .group_by(AIUsageLogDB.model_name)
                .all()
            )

            return {result.model_name: float(result.total_cost) for result in results}

        except Exception as e:
            logger.error(f"Failed to get per-model costs: {e}")
            return {}

    async def _get_azure_daily_trend(self) -> list[float]:
        """Get daily cost trend from Azure"""
        # Mock implementation - replace with actual Azure API calls
        return [1.2, 1.5, 1.8, 1.6, 2.1, 1.9, 2.3]

    async def _get_local_daily_trend(self) -> list[float]:
        """Get daily cost trend from local data"""
        try:
            if not self.db:
                return []

            from sqlalchemy import func

            from database.sql_models import AIUsageLogDB

            # Get last 7 days of costs
            trends = []
            for i in range(7):
                day = datetime.utcnow() - timedelta(days=i)
                day_start = day.replace(hour=0, minute=0, second=0, microsecond=0)
                day_end = day_start + timedelta(days=1)

                result = (
                    self.db.query(func.sum(AIUsageLogDB.cost))
                    .filter(
                        AIUsageLogDB.created_at >= day_start,
                        AIUsageLogDB.created_at < day_end,
                    )
                    .scalar()
                )

                trends.append(float(result or 0.0))

            return list(reversed(trends))  # Return in chronological order

        except Exception as e:
            logger.error(f"Failed to get daily trend: {e}")
            return []

    def _calculate_projected_spend(
        self, current_spend: float, daily_trend: list[float]
    ) -> float:
        """Calculate projected monthly spend based on trends"""
        try:
            if not daily_trend:
                # Simple projection: current spend * days remaining
                days_elapsed = datetime.utcnow().day
                days_in_month = 30  # Approximate
                return current_spend * (days_in_month / days_elapsed)

            # Use trend analysis for projection
            avg_daily = sum(daily_trend) / len(daily_trend)
            days_remaining = 30 - datetime.utcnow().day
            projected = current_spend + (avg_daily * days_remaining)

            return max(projected, current_spend)  # Never project less than current

        except Exception as e:
            logger.error(f"Projection calculation failed: {e}")
            return current_spend * 1.5  # Conservative estimate

    def _determine_alert_status(self, utilization: float) -> str:
        """Determine alert status based on utilization"""
        if utilization >= 100:
            return "exceeded"
        elif utilization >= self.cost_threshold:
            return "critical"
        elif utilization >= 70:
            return "warning"
        else:
            return "healthy"

    async def _create_azure_alert(self, alert: CostAlert) -> str:
        """Create Azure budget alert"""
        try:
            # This would create actual Azure budget alerts
            # For now, return success
            return "azure_alert_created"
        except Exception as e:
            logger.error(f"Azure alert creation failed: {e}")
            return "azure_alert_failed"

    async def _get_historical_costs(
        self, start_date: datetime, end_date: datetime
    ) -> list[float]:
        """Get historical cost data"""
        # Mock implementation - replace with actual data queries
        return [1.2, 1.5, 1.8, 1.6, 2.1, 1.9, 2.3, 2.0, 1.8, 2.2]

    def _calculate_cost_trend(self, historical_costs: list[float]) -> str:
        """Calculate cost trend direction"""
        if len(historical_costs) < 2:
            return "insufficient_data"

        recent_avg = (
            sum(historical_costs[-3:]) / 3
            if len(historical_costs) >= 3
            else historical_costs[-1]
        )
        older_avg = (
            sum(historical_costs[:3]) / 3
            if len(historical_costs) >= 6
            else historical_costs[0]
        )

        if recent_avg > older_avg * 1.1:
            return "increasing"
        elif recent_avg < older_avg * 0.9:
            return "decreasing"
        else:
            return "stable"

    async def _generate_cost_forecast(
        self, historical_costs: list[float]
    ) -> dict[str, Any]:
        """Generate cost forecast"""
        if not historical_costs:
            return {"error": "insufficient_data"}

        # Simple linear projection
        avg_cost = sum(historical_costs) / len(historical_costs)

        return {
            "next_7_days": avg_cost * 7,
            "next_30_days": avg_cost * 30,
            "confidence": "medium",
            "method": "linear_projection",
        }

    async def _get_cost_breakdown(
        self, start_date: datetime, end_date: datetime
    ) -> dict[str, Any]:
        """Get detailed cost breakdown"""
        return {
            "by_service": {
                "openai": 45.20,
                "google_ai": 12.30,
                "azure_functions": 8.50,
            },
            "by_model": {"gpt-4": 35.00, "gemini-pro": 15.50, "claude-3": 10.00},
        }

    async def _get_optimization_recommendations(self) -> list[dict[str, str]]:
        """Get cost optimization recommendations"""
        return [
            {
                "type": "model_optimization",
                "recommendation": "Consider using Gemini Pro for chat requests to reduce costs by 30%",
                "potential_savings": "15.00",
            },
            {
                "type": "caching",
                "recommendation": "Enable response caching to reduce duplicate requests",
                "potential_savings": "8.50",
            },
            {
                "type": "batch_processing",
                "recommendation": "Batch similar requests to improve efficiency",
                "potential_savings": "5.20",
            },
        ]

    async def _get_alert_summary(self) -> dict[str, Any]:
        """Get summary of configured alerts"""
        return {
            "total_alerts": len(self._alerts),
            "active_alerts": len(
                [a for a in self._alerts.values() if a.last_triggered]
            ),
            "alert_types": list({a.alert_type for a in self._alerts.values()}),
        }

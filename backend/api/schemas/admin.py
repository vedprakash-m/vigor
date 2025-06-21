"""
Admin-related schemas and data models
"""

from datetime import datetime
from typing import Any, Optional, Union

from pydantic import BaseModel, Field


# AI Provider Priority Schemas
class AIProviderPriorityBase(BaseModel):
    model_config = {"protected_namespaces": ()}  # Allow model_ fields

    provider_name: str = Field(
        ..., description="Name of the AI provider (openai, gemini, perplexity)"
    )
    model_name: str = Field(..., description="Specific model name")
    priority: int = Field(..., ge=1, le=10, description="Priority order (1 = highest)")
    is_enabled: bool = Field(
        default=True, description="Whether this provider is enabled"
    )
    max_daily_cost: Optional[float] = Field(
        None, ge=0, description="Maximum daily cost limit"
    )
    max_weekly_cost: Optional[float] = Field(
        None, ge=0, description="Maximum weekly cost limit"
    )
    max_monthly_cost: Optional[float] = Field(
        None, ge=0, description="Maximum monthly cost limit"
    )


class AIProviderPriorityCreate(AIProviderPriorityBase):
    pass


class AIProviderPriorityResponse(AIProviderPriorityBase):
    model_config = {"protected_namespaces": (), "from_attributes": True}

    id: str
    created_at: datetime
    updated_at: datetime


# Budget Settings Schemas
class BudgetSettingsBase(BaseModel):
    total_weekly_budget: float = Field(
        ..., ge=0, description="Total weekly budget in USD"
    )
    total_monthly_budget: float = Field(
        ..., ge=0, description="Total monthly budget in USD"
    )
    alert_threshold_percentage: float = Field(
        default=80.0, ge=0, le=100, description="Alert when this % of budget is used"
    )
    auto_disable_on_budget_exceeded: bool = Field(
        default=True, description="Automatically disable AI when budget exceeded"
    )


class BudgetSettingsUpdate(BudgetSettingsBase):
    pass


class BudgetSettingsResponse(BudgetSettingsBase):
    model_config = {"from_attributes": True}

    id: str
    created_at: datetime
    updated_at: datetime


# AI Usage Log Schemas
class AIUsageLogResponse(BaseModel):
    model_config = {"protected_namespaces": (), "from_attributes": True}

    id: str
    user_id: Optional[str]
    provider_name: str
    model_name: str
    endpoint: str
    request_tokens: Optional[int]
    response_tokens: Optional[int]
    cost: float
    success: bool
    error_message: Optional[str]
    response_time_ms: Optional[int]
    created_at: datetime


# Admin Settings Schemas
class AdminSettingsBase(BaseModel):
    key: str = Field(..., description="Setting key/name")
    value: str = Field(..., description="Setting value (JSON for complex data)")
    description: Optional[str] = Field(None, description="Description of this setting")


class AdminSettingsCreate(AdminSettingsBase):
    pass


class AdminSettingsUpdate(BaseModel):
    value: str = Field(..., description="New setting value")
    description: Optional[str] = Field(None, description="Updated description")


class AdminSettingsResponse(AdminSettingsBase):
    model_config = {"from_attributes": True}

    id: str
    created_at: datetime
    updated_at: datetime


# Dashboard & Analytics Schemas
class UsageStatsResponse(BaseModel):
    weekly_spending: float
    monthly_spending: float
    daily_spending: float
    total_requests_today: int
    total_requests_week: int
    avg_cost_per_request: float
    top_providers: list[dict]
    recent_usage: list[dict]


class ProviderStatsResponse(BaseModel):
    model_config = {"protected_namespaces": ()}  # Allow model_ fields

    provider_name: str
    model_name: str
    total_requests: int
    total_cost: float
    avg_cost_per_request: float
    success_rate: float
    avg_response_time_ms: float
    last_used: Optional[datetime]


class CostBreakdownResponse(BaseModel):
    by_provider: list[dict[str, float]]
    by_day: list[dict[str, float]]
    by_user: list[dict[str, float]]
    total_cost: float
    budget_remaining: float
    budget_usage_percentage: float


# System Health Schemas
class SystemHealthResponse(BaseModel):
    status: str  # "healthy", "warning", "critical"
    ai_providers_status: dict[str, bool]
    database_status: bool
    budget_status: str  # "ok", "warning", "exceeded"
    recent_errors: list[str]
    uptime_hours: float
    last_check: datetime


# Alert & Notification Schemas
class AlertResponse(BaseModel):
    id: str
    type: str  # "budget", "error", "performance"
    severity: str  # "info", "warning", "critical"
    message: str
    data: Optional[dict]
    acknowledged: bool
    created_at: datetime
    acknowledged_at: Optional[datetime]


class ModelConfiguration(BaseModel):
    """Model configuration for admin management"""

    model_id: str
    model_name: str
    provider: str
    priority: int = Field(..., ge=1, le=10)
    is_active: bool = True
    cost_per_token: Optional[float] = None
    max_tokens: Optional[int] = None
    context_window: Optional[int] = None


class LLMProviderConfiguration(BaseModel):
    """LLM provider configuration"""

    provider_id: str
    provider_name: str
    api_endpoint: Optional[str] = None
    is_active: bool = True
    supported_models: list[str] = []
    default_model: Optional[str] = None


class BudgetConfiguration(BaseModel):
    """Budget configuration"""

    daily_limit: float = Field(..., gt=0)
    weekly_limit: float = Field(..., gt=0)
    monthly_limit: float = Field(..., gt=0)
    alert_threshold: float = Field(..., ge=0, le=100)  # Percentage
    auto_disable_on_exceed: bool = False


class SystemHealth(BaseModel):
    """System health status"""

    status: str
    timestamp: datetime
    services: dict[str, str]
    performance_metrics: dict[str, Any]


class UserManagement(BaseModel):
    """User management operations"""

    user_id: str = Field(..., description="User ID to modify")
    action: str = Field(..., pattern="^(activate|deactivate|upgrade|downgrade)$")
    new_tier: Optional[str] = Field(None, description="New tier for upgrade/downgrade")
    reason: Optional[str] = Field(None, description="Reason for the action")


class UsageAnalytics(BaseModel):
    """Usage analytics data"""

    user_id: Optional[str]
    provider: str
    model_used: str
    tokens_consumed: int
    cost: float
    timestamp: datetime
    success: bool
    error_message: Optional[str]

from datetime import datetime
from typing import Dict, List, Optional

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
    top_providers: List[Dict]
    recent_usage: List[Dict]


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
    by_provider: List[Dict[str, float]]
    by_day: List[Dict[str, float]]
    by_user: List[Dict[str, float]]
    total_cost: float
    budget_remaining: float
    budget_usage_percentage: float


# System Health Schemas
class SystemHealthResponse(BaseModel):
    status: str  # "healthy", "warning", "critical"
    ai_providers_status: Dict[str, bool]
    database_status: bool
    budget_status: str  # "ok", "warning", "exceeded"
    recent_errors: List[str]
    uptime_hours: float
    last_check: datetime


# Alert & Notification Schemas
class AlertResponse(BaseModel):
    id: str
    type: str  # "budget", "error", "performance"
    severity: str  # "info", "warning", "critical"
    message: str
    data: Optional[Dict]
    acknowledged: bool
    created_at: datetime
    acknowledged_at: Optional[datetime]

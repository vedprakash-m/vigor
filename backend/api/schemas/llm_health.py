"""
Pydantic schemas for LLM Health Monitoring
"""

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class ModelStatus(str, Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    OFFLINE = "offline"


class AlertSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


class LLMConfiguration(BaseModel):
    temperature: float | None = Field(None, ge=0.0, le=2.0)
    max_tokens: int | None = Field(None, gt=0)
    top_p: float | None = Field(None, ge=0.0, le=1.0)
    enabled: bool | None = None


class LLMModelHealth(BaseModel):
    id: str
    name: str
    provider: str
    status: ModelStatus
    response_time: int  # in milliseconds
    request_count: int
    error_rate: float  # as decimal (0.02 = 2%)
    cost: float  # daily cost in USD
    last_health_check: datetime
    configuration: LLMConfiguration


class SystemMetrics(BaseModel):
    total_requests: int
    average_response_time: int
    overall_error_rate: float
    daily_cost: float
    active_users: int
    system_load: float  # as decimal (0.68 = 68%)


class HealthCheckResponse(BaseModel):
    model_id: str
    status: ModelStatus
    response_time: int
    timestamp: datetime
    details: dict[str, Any]


class ModelSwitchRequest(BaseModel):
    from_model: str
    to_model: str
    reason: str | None = None


class Alert(BaseModel):
    id: str
    model_id: str
    severity: AlertSeverity
    type: str
    message: str
    timestamp: datetime
    acknowledged: bool
    acknowledged_by: str | None = None
    acknowledged_at: datetime | None = None


class HistoricalDataPoint(BaseModel):
    timestamp: datetime
    response_time: int
    request_count: int
    error_rate: float
    cost: float


class HistoricalMetrics(BaseModel):
    model_id: str | None
    time_range: str
    data_points: list[HistoricalDataPoint]


class LLMHealthOverview(BaseModel):
    system_metrics: SystemMetrics
    models: list[LLMModelHealth]
    time_range: str
    last_updated: datetime

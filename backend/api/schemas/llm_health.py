"""
Pydantic schemas for LLM Health Monitoring
"""

from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

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
    temperature: Optional[float] = Field(None, ge=0.0, le=2.0)
    max_tokens: Optional[int] = Field(None, gt=0)
    top_p: Optional[float] = Field(None, ge=0.0, le=1.0)
    enabled: Optional[bool] = None


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
    details: Dict[str, Any]


class ModelSwitchRequest(BaseModel):
    from_model: str
    to_model: str
    reason: Optional[str] = None


class Alert(BaseModel):
    id: str
    model_id: str
    severity: AlertSeverity
    type: str
    message: str
    timestamp: datetime
    acknowledged: bool
    acknowledged_by: Optional[str] = None
    acknowledged_at: Optional[datetime] = None


class HistoricalDataPoint(BaseModel):
    timestamp: datetime
    response_time: int
    request_count: int
    error_rate: float
    cost: float


class HistoricalMetrics(BaseModel):
    model_id: Optional[str]
    time_range: str
    data_points: List[HistoricalDataPoint]


class LLMHealthOverview(BaseModel):
    system_metrics: SystemMetrics
    models: List[LLMModelHealth]
    time_range: str
    last_updated: datetime

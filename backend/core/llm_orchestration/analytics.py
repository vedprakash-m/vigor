"""
Analytics Collector
Comprehensive analytics and monitoring for LLM orchestration
"""

import logging
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Optional

logger = logging.getLogger(__name__)


@dataclass
class RequestMetrics:
    """Request-level metrics"""

    timestamp: datetime
    user_id: str
    model_used: str
    provider: str
    latency_ms: int
    tokens_used: int
    cost: float
    success: bool
    cached: bool
    task_type: Optional[str]


class AnalyticsCollector:
    """
    Comprehensive analytics collection and reporting
    Provides insights for optimization and monitoring
    """

    def __init__(self, db_session=None):
        self.db = db_session
        self._metrics_buffer: list[RequestMetrics] = []
        self._buffer_size = 1000

    async def record_request(
        self,
        request: Any,  # GatewayRequest
        response: Any,  # LLMResponse
        request_id: str,
    ):
        """Record request metrics"""
        try:
            metrics = RequestMetrics(
                timestamp=datetime.utcnow(),
                user_id=request.user_id,
                model_used=response.model_used,
                provider=response.provider,
                latency_ms=response.latency_ms,
                tokens_used=response.tokens_used,
                cost=response.cost_estimate,
                success=True,
                cached=response.cached,
                task_type=request.task_type,
            )

            self._metrics_buffer.append(metrics)

            # Flush buffer if full
            if len(self._metrics_buffer) >= self._buffer_size:
                await self._flush_metrics()

        except Exception as e:
            logger.error(f"Failed to record analytics: {e}")

    async def get_usage_report(
        self, start_date: datetime, end_date: datetime, user_id: Optional[str] = None
    ) -> dict[str, Any]:
        """Generate usage report"""
        try:
            # Implementation would query database for metrics
            # For now, return mock data
            return {
                "period": f"{start_date.date()} to {end_date.date()}",
                "total_requests": 1500,
                "total_tokens": 2500000,
                "total_cost": 125.50,
                "avg_latency_ms": 850,
                "cache_hit_rate": 35.2,
                "top_models": [
                    {"model": "gpt-4", "requests": 600, "cost": 85.20},
                    {"model": "gemini-pro", "requests": 500, "cost": 25.10},
                    {"model": "claude-3-sonnet", "requests": 400, "cost": 15.20},
                ],
            }
        except Exception as e:
            logger.error(f"Failed to generate usage report: {e}")
            return {"error": str(e)}

    async def _flush_metrics(self):
        """Flush metrics buffer to database"""
        try:
            if not self._metrics_buffer:
                return

            # Implementation would batch insert to database
            logger.debug(f"Flushing {len(self._metrics_buffer)} metrics records")
            self._metrics_buffer.clear()

        except Exception as e:
            logger.error(f"Failed to flush metrics: {e}")

    async def shutdown(self):
        """Shutdown and flush remaining metrics"""
        await self._flush_metrics()

from __future__ import annotations

"""Responsible for persisting analytics, usage logs, and caching after a request."""

from core.llm_orchestration.adapters import LLMRequest, LLMResponse
from core.llm_orchestration.analytics import AnalyticsCollector
from core.llm_orchestration.budget_manager import BudgetManager
from core.llm_orchestration.cache_manager import CacheManager
from core.llm_orchestration.usage_logger import UsageLogger


class ResponseRecorder:
    def __init__(
        self,
        usage_logger: UsageLogger,
        budget_manager: BudgetManager,
        analytics: AnalyticsCollector,
        cache_manager: CacheManager,
    ):
        self._usage_logger = usage_logger
        self._budget_manager = budget_manager
        self._analytics = analytics
        self._cache_manager = cache_manager

    async def record(
        self,
        gateway_request_id: str,
        original_request: "GatewayRequest",
        llm_request: LLMRequest,
        llm_response: LLMResponse,
    ) -> None:
        """Persist logs, budgets, analytics and cache response."""
        # Cache first
        try:
            await self._cache_manager.set(llm_request, llm_response)
        except Exception:
            pass

        # Usage log & budget
        await self._usage_logger.log_request(
            request_id=gateway_request_id,
            user_id=original_request.user_id,
            model_used=llm_response.model_used,
            provider=llm_response.provider,
            tokens_used=llm_response.tokens_used,
            cost_estimate=llm_response.cost_estimate,
            latency_ms=llm_response.latency_ms,
            cached=False,
            task_type=original_request.task_type,
            session_id=original_request.session_id,
        )

        await self._budget_manager.record_usage(
            original_request.user_id,
            [original_request.user_tier] if original_request.user_tier else [],
            llm_response.cost_estimate,
        )

        # Analytics
        await self._analytics.record_request(
            original_request, llm_response, gateway_request_id
        )

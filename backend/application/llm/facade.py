from __future__ import annotations

"""Facade that orchestrates the new application-layer components while delegating
legacy operations to the existing infrastructure until full migration is complete.
"""

import time
import uuid
from typing import Optional

from core.llm_orchestration.adapters import (
    AdapterFactory,
    LLMResponse,
    LLMServiceAdapter,
    create_adapters_from_configs,
)
from core.llm_orchestration.analytics import AnalyticsCollector
from core.llm_orchestration.budget_manager import BudgetManager
from core.llm_orchestration.cache_manager import CacheManager
from core.llm_orchestration.circuit_breaker import CircuitBreakerManager
from core.llm_orchestration.config_manager import AdminConfigManager, ModelConfiguration
from core.llm_orchestration.gateway import GatewayRequest, GatewayResponse
from core.llm_orchestration.key_vault import KeyVaultClientService, KeyVaultProvider, SecretReference
from core.llm_orchestration.usage_logger import UsageLogger

from .budget_enforcer import BudgetEnforcer
from .request_validator import RequestValidator
from .response_recorder import ResponseRecorder
from .routing_engine import RoutingEngine


class LLMGatewayFacade:
    """Lightweight orchestrator constructed from smaller application-layer policies."""

    def __init__(
        self,
        config_manager: AdminConfigManager,
        key_vault_service: KeyVaultClientService,
        db_session=None,
    ) -> None:
        # Dependencies
        self._config_manager = config_manager
        self._key_vault_service = key_vault_service
        self._db = db_session

        # Instantiate cross-cutting services from legacy infra (to be replaced later)
        self._budget_manager = BudgetManager(db_session)
        self._cache_manager = CacheManager()
        self._analytics = AnalyticsCollector(db_session)
        self._usage_logger = UsageLogger(db_session)
        self._circuit_breaker = CircuitBreakerManager()

        # Application-layer components
        self._request_validator = RequestValidator()
        self._routing_engine = RoutingEngine(config_manager)
        self._budget_enforcer = BudgetEnforcer(self._budget_manager)
        self._response_recorder = ResponseRecorder(
            self._usage_logger,
            self._budget_manager,
            self._analytics,
            self._cache_manager,
        )

        self._adapters: dict[str, LLMServiceAdapter] = {}
        self._initialized = False

    async def initialize(self) -> None:
        await self._config_manager.load_configurations()
        active_models = self._config_manager.get_active_models() or []
        if not active_models:
            # Build fallback configuration (reuse legacy helper)
            fallback_secret = SecretReference(
                provider=KeyVaultProvider.LOCAL_ENV,
                secret_identifier="fallback-secret"
            )
            fallback_config = ModelConfiguration(
                model_id="fallback",
                provider="fallback",
                model_name="fallback",
                api_key_secret_ref=fallback_secret,
            )
            active_models = [fallback_config]

        self._adapters = await create_adapters_from_configs(
            active_models, self._key_vault_service
        )
        await self._circuit_breaker.initialize(list(self._adapters.keys()))
        await self._budget_manager.initialize()
        await self._cache_manager.initialize()
        self._initialized = True

    # ------------------------------------------------------------
    # Public API (mirrors legacy gateway signature for drop-in use)
    # ------------------------------------------------------------

    async def process_request(self, request: GatewayRequest) -> GatewayResponse:
        if not self._initialized:
            raise RuntimeError("LLMGatewayFacade not initialized")

        request_id = str(uuid.uuid4())
        start = time.time()

        # Validate & enrich
        enriched = self._request_validator(request, request_id)

        # Cache hit fast-path
        cached_resp = await self._cache_manager.get(enriched)
        if cached_resp:
            return self._to_gateway_response(
                cached_resp, request, request_id, start, cached=True
            )

        # Budget enforcement
        await self._budget_enforcer.ensure_within_budget(
            request.user_id, [request.user_tier] if request.user_tier else []
        )

        # Routing
        adapter = await self._select_adapter(enriched)

        # Execute
        llm_resp = await adapter.generate_response(enriched)

        # Record side-effects (async but we await for consistency for now)
        await self._response_recorder.record(request_id, request, enriched, llm_resp)

        return self._to_gateway_response(llm_resp, request, request_id, start)

    # ------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------

    async def _select_adapter(self, llm_request):
        context = {
            "user_id": llm_request.user_id,
            "task_type": llm_request.task_type,
            "user_tier": (
                llm_request.context.get("user_tier") if llm_request.context else None
            ),
            "priority": (
                llm_request.context.get("priority") if llm_request.context else None
            ),
        }
        selected_id = await self._routing_engine.select_model(
            context, list(self._adapters.keys())
        )
        adapter = self._adapters.get(selected_id)
        if not adapter:
            raise Exception(f"Selected model {selected_id} not available")
        return adapter

    def _to_gateway_response(
        self,
        llm_resp: LLMResponse,
        original: GatewayRequest,
        req_id: str,
        start: float,
        cached: bool = False,
    ) -> GatewayResponse:
        return GatewayResponse(
            content=llm_resp.content,
            model_used=llm_resp.model_used,
            provider=llm_resp.provider,
            request_id=req_id,
            tokens_used=llm_resp.tokens_used,
            cost_estimate=llm_resp.cost_estimate,
            latency_ms=int((time.time() - start) * 1000),
            cached=cached,
            user_id=original.user_id,
            session_id=original.session_id,
            metadata=original.metadata,
        )

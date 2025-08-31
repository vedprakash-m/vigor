"""
LLM Gateway - Central orchestration layer for enterprise LLM management
Provides unified interface with security, cost optimization, and high availability
"""

import logging
import time
import uuid
from collections.abc import AsyncGenerator
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from .adapters import (
    AdapterFactory,
    LLMRequest,
    LLMResponse,
    LLMServiceAdapter,
    create_adapters_from_configs,
    health_check_all_adapters,
)
from .analytics import AnalyticsCollector
from .budget_manager import BudgetManager
from .cache_manager import CacheManager
from .circuit_breaker import CircuitBreakerManager
from .config_manager import (
    AdminConfigManager,
    ModelConfiguration,
)
from .cost_estimator import CostEstimator
from .key_vault import KeyVaultClientService
from .routing import RoutingStrategyEngine
from .usage_logger import UsageLogger

logger = logging.getLogger(__name__)


@dataclass
class GatewayRequest:
    """Enhanced request structure for the gateway"""

    prompt: str
    user_id: str
    task_type: str | None = None
    user_tier: str | None = None
    session_id: str | None = None
    max_tokens: int | None = None
    temperature: float | None = None
    stream: bool = False
    priority: int = 0  # Higher = more priority
    metadata: dict[str, Any] | None = None


@dataclass
class GatewayResponse:
    """Enhanced response structure from the gateway"""

    content: str
    model_used: str
    provider: str
    request_id: str
    tokens_used: int
    cost_estimate: float
    latency_ms: int
    cached: bool = False
    user_id: str | None = None
    session_id: str | None = None
    metadata: dict[str, Any] | None = None


class LLMGateway:
    """
    Central LLM orchestration gateway
    Provides enterprise-grade LLM management with security, cost optimization, and high availability
    """

    def __init__(
        self,
        config_manager: AdminConfigManager,
        key_vault_service: KeyVaultClientService,
        db_session=None,
        azure_cost_service=None,
    ):
        self.config_manager = config_manager
        self.key_vault_service = key_vault_service
        self.db = db_session

        # Core components
        self.routing_engine = RoutingStrategyEngine(config_manager)
        self.budget_manager = BudgetManager(db_session, azure_cost_service)
        self.usage_logger = UsageLogger(db_session)
        self.cost_estimator = CostEstimator()
        self.cache_manager = CacheManager()
        self.circuit_breaker = CircuitBreakerManager()
        self.analytics = AnalyticsCollector(db_session)

        # Runtime state
        self.adapters: dict[str, LLMServiceAdapter] = {}
        self.is_initialized = False
        self._health_check_interval = 60  # seconds
        self._last_health_check = 0.0

    async def initialize(self):
        """Initialize the gateway and all components"""
        try:
            logger.info("Initializing LLM Gateway...")

            # Load configurations
            await self.config_manager.load_configurations()

            # Create adapters for active models
            active_models = self.config_manager.get_active_models()
            if not active_models:
                logger.warning("No active models configured. Adding fallback adapter.")
                # Create fallback configuration
                from .key_vault import KeyVaultProvider, SecretReference

                fallback_ref = SecretReference(
                    provider=KeyVaultProvider.LOCAL_ENV,
                    secret_identifier="FALLBACK_KEY",  # nosec B106
                )
                fallback_config = ModelConfiguration(
                    model_id="fallback",
                    provider="fallback",
                    model_name="fallback",
                    api_key_secret_ref=fallback_ref,
                )
                active_models = [fallback_config]

            self.adapters = await create_adapters_from_configs(
                active_models, self.key_vault_service
            )

            # Initialize components
            await self.budget_manager.initialize()
            await self.cache_manager.initialize()
            await self.circuit_breaker.initialize(list(self.adapters.keys()))

            # Perform initial health check
            await self._perform_health_check()

            self.is_initialized = True
            logger.info(f"LLM Gateway initialized with {len(self.adapters)} adapters")

        except Exception as e:
            logger.error(f"Failed to initialize LLM Gateway: {e}")
            raise

    async def process_request(self, request: GatewayRequest) -> GatewayResponse:
        """
        Process an LLM request through the complete orchestration pipeline
        """
        if not self.is_initialized:
            raise RuntimeError("Gateway not initialized. Call initialize() first.")

        request_id = str(uuid.uuid4())
        start_time = time.time()

        try:
            logger.info(f"Processing request {request_id} for user {request.user_id}")

            # 1. Validate and enrich request
            enriched_request = await self._enrich_request(request, request_id)

            # 2. Check cache first
            cached_response = await self._check_cache(enriched_request)
            if cached_response:
                logger.info(f"Cache hit for request {request_id}")
                return await self._create_gateway_response(
                    cached_response, request, request_id, start_time, cached=True
                )

            # 3. Budget enforcement
            await self._enforce_budget(request)

            # 4. Rate limiting
            await self._check_rate_limits(request)

            # 5. Model selection and routing
            selected_adapter = await self._select_model(enriched_request)

            # 6. Circuit breaker check
            if not self.circuit_breaker.can_proceed(selected_adapter.model_id):
                logger.warning(f"Circuit breaker open for {selected_adapter.model_id}")
                # Try fallback routing
                selected_adapter = await self._select_fallback_model(enriched_request)

            # 7. Execute LLM request
            llm_response = await self._execute_llm_request(
                selected_adapter, enriched_request
            )

            # 8. Post-process response
            gateway_response = await self._create_gateway_response(
                llm_response, request, request_id, start_time
            )

            # 9. Cache response
            await self._cache_response(enriched_request, llm_response)

            # 10. Log usage and update analytics
            await self._log_usage(request, llm_response, request_id)

            # 11. Update circuit breaker
            self.circuit_breaker.record_success(selected_adapter.model_id)

            logger.info(f"Successfully processed request {request_id}")
            return gateway_response

        except Exception as e:
            logger.error(f"Error processing request {request_id}: {e}")

            # Record failure for circuit breaker
            if "selected_adapter" in locals():
                self.circuit_breaker.record_failure(selected_adapter.model_id)

            # Try fallback if available
            fallback_response = await self._handle_error_fallback(
                request, request_id, str(e)
            )
            if fallback_response:
                return fallback_response

            raise

    async def process_stream(
        self, request: GatewayRequest
    ) -> AsyncGenerator[str, None]:
        """
        Process a streaming LLM request
        """
        if not self.is_initialized:
            raise RuntimeError("Gateway not initialized. Call initialize() first.")

        request_id = str(uuid.uuid4())

        try:
            logger.info(
                f"Processing streaming request {request_id} for user {request.user_id}"
            )

            # Similar validation pipeline but for streaming
            enriched_request = await self._enrich_request(request, request_id)
            enriched_request.stream = True

            await self._enforce_budget(request)
            await self._check_rate_limits(request)

            selected_adapter = await self._select_model(enriched_request)

            if not self.circuit_breaker.can_proceed(selected_adapter.model_id):
                selected_adapter = await self._select_fallback_model(enriched_request)

            # Stream response
            full_response = ""
            async for chunk in selected_adapter.generate_stream(enriched_request):
                full_response += chunk
                yield chunk

            # Log the complete response
            mock_response = LLMResponse(
                content=full_response,
                model_used=selected_adapter.model_config.model_name,
                provider=selected_adapter.provider.value,
                tokens_used=len(full_response.split()),
                cost_estimate=selected_adapter.estimate_cost(
                    request.prompt, len(full_response.split())
                ),
                latency_ms=0,
                request_id=request_id,
            )

            await self._log_usage(request, mock_response, request_id)
            self.circuit_breaker.record_success(selected_adapter.model_id)

        except Exception as e:
            logger.error(f"Error processing streaming request {request_id}: {e}")
            if "selected_adapter" in locals():
                self.circuit_breaker.record_failure(selected_adapter.model_id)
            raise

    async def get_provider_status(self) -> dict[str, Any]:
        """Get current status of all providers"""
        if not self.is_initialized:
            return {"error": "Gateway not initialized"}

        # Perform health check if needed
        current_time = time.time()
        if current_time - self._last_health_check > self._health_check_interval:
            await self._perform_health_check()

        status: dict[str, Any] = {
            "active_models": len([a for a in self.adapters.values() if a.is_healthy()]),
            "total_models": len(self.adapters),
            "circuit_breakers": self.circuit_breaker.get_status(),
            "cache_stats": self.cache_manager.get_stats(),
            "budget_status": await self.budget_manager.get_global_status(),
            "providers": {},
        }

        for model_id, adapter in self.adapters.items():
            health_status = adapter.get_health_status()
            status["providers"][model_id] = {
                "provider": adapter.provider.value,
                "model_name": adapter.model_config.model_name,
                "is_healthy": health_status.is_healthy,
                "latency_ms": health_status.latency_ms,
                "last_check": health_status.last_check,
                "error_message": health_status.error_message,
            }

        return status

    async def admin_add_model(
        self,
        model_id: str,
        provider: str,
        model_name: str,
        api_key_secret_ref: Any,  # SecretReference
        **kwargs,
    ) -> bool:
        """Admin interface to add a new model"""
        try:
            # Add to configuration
            config = await self.config_manager.add_model_configuration(
                model_id=model_id,
                provider=provider,
                model_name=model_name,
                api_key_secret_ref=api_key_secret_ref,
                **kwargs,
            )

            # Create and add adapter
            adapter = AdapterFactory.create_adapter(config, self.key_vault_service)
            self.adapters[model_id] = adapter

            # Initialize circuit breaker
            self.circuit_breaker.add_model(model_id)

            logger.info(f"Successfully added model {model_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to add model {model_id}: {e}")
            return False

    async def admin_toggle_model(self, model_id: str, is_active: bool) -> bool:
        """Admin interface to enable/disable a model"""
        try:
            success = await self.config_manager.toggle_model_activation(
                model_id, is_active
            )

            if success and not is_active and model_id in self.adapters:
                # Remove from active adapters if deactivated
                del self.adapters[model_id]
                self.circuit_breaker.remove_model(model_id)
            elif success and is_active:
                # Re-add if activated and not already present
                config = self.config_manager.models.get(model_id)
                if config and model_id not in self.adapters:
                    adapter = AdapterFactory.create_adapter(
                        config, self.key_vault_service
                    )
                    self.adapters[model_id] = adapter
                    self.circuit_breaker.add_model(model_id)

            return success

        except Exception as e:
            logger.error(f"Failed to toggle model {model_id}: {e}")
            return False

    # Private helper methods

    async def _enrich_request(
        self, request: GatewayRequest, request_id: str
    ) -> LLMRequest:
        """Enrich the request with additional context"""
        return LLMRequest(
            prompt=request.prompt,
            user_id=request.user_id,
            session_id=request.session_id,
            task_type=request.task_type,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            stream=request.stream,
            context={
                "request_id": request_id,
                "user_tier": request.user_tier,
                "priority": request.priority,
                "timestamp": datetime.utcnow().isoformat(),
            },
            metadata=request.metadata,
        )

    async def _check_cache(self, request: LLMRequest) -> LLMResponse | None:
        """Check if response is cached"""
        try:
            return await self.cache_manager.get(request)
        except Exception as e:
            logger.warning(f"Cache check failed: {e}")
            return None

    async def _enforce_budget(self, request: GatewayRequest):
        """Enforce budget limits with Azure Cost Management integration"""
        user_groups = [request.user_tier] if request.user_tier else []

        # Estimate cost for this request
        estimated_cost = await self.cost_estimator.estimate_cost(
            request.prompt, request.max_tokens or 1000
        )

        # Check local budget
        if not await self.budget_manager.can_proceed(
            request.user_id, user_groups, estimated_cost
        ):
            raise Exception("Budget limit exceeded")

        # Validate with Azure Cost Management
        if not await self.budget_manager.validate_budget_with_azure(estimated_cost):
            raise Exception("Azure budget limit exceeded")

    async def _check_rate_limits(self, request: GatewayRequest):
        """Check rate limiting"""
        # Implementation would check against configured rate limits
        pass

    async def _select_model(self, request: LLMRequest) -> LLMServiceAdapter:
        """Select the best model for the request"""
        context = {
            "user_id": request.user_id,
            "task_type": request.task_type,
            "user_tier": request.context.get("user_tier") if request.context else None,
            "priority": request.context.get("priority") if request.context else None,
        }

        selected_model_id = await self.routing_engine.select_model(
            context, list(self.adapters.keys())
        )

        if selected_model_id not in self.adapters:
            raise Exception(f"Selected model {selected_model_id} not available")

        return self.adapters[selected_model_id]

    async def _select_fallback_model(self, request: LLMRequest) -> LLMServiceAdapter:
        """Select a fallback model"""
        # Try to find a healthy fallback
        for adapter in self.adapters.values():
            if adapter.is_healthy() and self.circuit_breaker.can_proceed(
                adapter.model_id
            ):
                return adapter

        # If no healthy models, try fallback adapter
        if "fallback" in self.adapters:
            return self.adapters["fallback"]

        raise Exception("No healthy models available")

    async def _execute_llm_request(
        self, adapter: LLMServiceAdapter, request: LLMRequest
    ) -> LLMResponse:
        """Execute the LLM request"""
        try:
            return await adapter.generate_response(request)
        except Exception as e:
            logger.error(f"LLM execution failed for {adapter.model_id}: {e}")
            raise

    async def _create_gateway_response(
        self,
        llm_response: LLMResponse,
        original_request: GatewayRequest,
        request_id: str,
        start_time: float,
        cached: bool = False,
    ) -> GatewayResponse:
        """Create gateway response from LLM response"""
        total_latency = int((time.time() - start_time) * 1000)

        return GatewayResponse(
            content=llm_response.content,
            model_used=llm_response.model_used,
            provider=llm_response.provider,
            request_id=request_id,
            tokens_used=llm_response.tokens_used,
            cost_estimate=llm_response.cost_estimate,
            latency_ms=total_latency if not cached else llm_response.latency_ms,
            cached=cached,
            user_id=original_request.user_id,
            session_id=original_request.session_id,
            metadata=original_request.metadata,
        )

    async def _cache_response(self, request: LLMRequest, response: LLMResponse):
        """Cache the response"""
        try:
            await self.cache_manager.set(request, response)
        except Exception as e:
            logger.warning(f"Failed to cache response: {e}")

    async def _log_usage(
        self, request: GatewayRequest, response: LLMResponse, request_id: str
    ):
        """Log usage for analytics and billing"""
        try:
            await self.usage_logger.log_request(
                request_id=request_id,
                user_id=request.user_id,
                model_used=response.model_used,
                provider=response.provider,
                tokens_used=response.tokens_used,
                cost_estimate=response.cost_estimate,
                latency_ms=response.latency_ms,
                cached=response.cached,
                task_type=request.task_type,
                session_id=request.session_id,
            )

            # Update budget tracking
            await self.budget_manager.record_usage(
                request.user_id,
                [request.user_tier] if request.user_tier else [],
                response.cost_estimate,
            )

            # Update analytics
            await self.analytics.record_request(request, response, request_id)

        except Exception as e:
            logger.error(f"Failed to log usage: {e}")

    async def _handle_error_fallback(
        self, request: GatewayRequest, request_id: str, error_message: str
    ) -> GatewayResponse | None:
        """Handle error with fallback response"""
        try:
            if "fallback" in self.adapters:
                fallback_adapter = self.adapters["fallback"]
                llm_request = await self._enrich_request(request, request_id)

                fallback_response = await fallback_adapter.generate_response(
                    llm_request
                )

                return GatewayResponse(
                    content=f"Service temporarily unavailable. {fallback_response.content}",
                    model_used="fallback",
                    provider="fallback",
                    request_id=request_id,
                    tokens_used=fallback_response.tokens_used,
                    cost_estimate=0.0,
                    latency_ms=fallback_response.latency_ms,
                    user_id=request.user_id,
                    session_id=request.session_id,
                    metadata={"error": error_message, "fallback": True},
                )
        except Exception as e:
            logger.error(f"Fallback also failed: {e}")

        return None

    async def _perform_health_check(self):
        """Perform health check on all adapters"""
        try:
            health_results = await health_check_all_adapters(self.adapters)

            for model_id, result in health_results.items():
                if not result.is_healthy:
                    logger.warning(
                        f"Model {model_id} health check failed: {result.error_message}"
                    )
                    # Circuit breaker will handle this
                    self.circuit_breaker.record_failure(model_id)
                else:
                    self.circuit_breaker.record_success(model_id)

            self._last_health_check = time.time()

        except Exception as e:
            logger.error(f"Health check failed: {e}")

    async def shutdown(self):
        """Gracefully shutdown the gateway"""
        try:
            logger.info("Shutting down LLM Gateway...")

            # Clean up components
            await self.cache_manager.shutdown()
            await self.usage_logger.shutdown()
            await self.analytics.shutdown()

            # Clear adapters
            self.adapters.clear()
            self.is_initialized = False

            logger.info("LLM Gateway shutdown complete")

        except Exception as e:
            logger.error(f"Error during shutdown: {e}")


# Global gateway instance
gateway: LLMGateway | None = None


async def initialize_gateway(
    config_manager: AdminConfigManager,
    key_vault_service: KeyVaultClientService,
    db_session=None,
    azure_cost_service=None,
) -> LLMGateway:
    """Initialize the global gateway instance"""
    global gateway

    try:
        gateway = LLMGateway(
            config_manager, key_vault_service, db_session, azure_cost_service
        )
        await gateway.initialize()
        logger.info("Global LLM Gateway initialized with Azure Cost Management")
        return gateway

    except Exception as e:
        logger.error(f"Failed to initialize global gateway: {e}")
        raise


def get_gateway() -> LLMGateway:
    """Get the global gateway instance"""
    if gateway is None:
        raise RuntimeError("Gateway not initialized. Call initialize_gateway() first.")
    return gateway

"""
Comprehensive tests for LLM Gateway - High Impact Coverage Boost
Target: core/llm_orchestration/gateway.py (30% → 80%+ coverage)
Impact: 189 missing lines - HIGHEST PRIORITY
"""

import json
import time
import uuid
from unittest.mock import AsyncMock, Mock, patch

import pytest

from core.llm_orchestration.adapters import (
    HealthCheckResult,
    LLMProvider,
    LLMRequest,
    LLMResponse,
    LLMServiceAdapter,
)
from core.llm_orchestration.config_manager import AdminConfigManager, ModelConfiguration
from core.llm_orchestration.gateway import (
    GatewayRequest,
    GatewayResponse,
    LLMGateway,
    get_gateway,
    initialize_gateway,
)
from core.llm_orchestration.key_vault import (
    KeyVaultClientService,
    KeyVaultProvider,
    SecretReference,
)


# Module-level fixtures that can be used by all test classes
@pytest.fixture
def mock_config_manager():
    """Mock AdminConfigManager"""
    config_manager = Mock(spec=AdminConfigManager)
    config_manager.load_configurations = AsyncMock()
    config_manager.get_active_models = Mock(return_value=[])
    return config_manager


@pytest.fixture
def mock_key_vault():
    """Mock KeyVaultClientService"""
    key_vault = Mock(spec=KeyVaultClientService)
    return key_vault


@pytest.fixture
def mock_db_session():
    """Mock database session"""
    return Mock()


@pytest.fixture
def gateway(mock_config_manager, mock_key_vault, mock_db_session):
    """Create LLMGateway instance with mocked dependencies"""
    with (
        patch("core.llm_orchestration.gateway.RoutingStrategyEngine") as mock_routing,
        patch("core.llm_orchestration.gateway.BudgetManager") as mock_budget,
        patch("core.llm_orchestration.gateway.UsageLogger") as mock_usage,
        patch("core.llm_orchestration.gateway.CostEstimator"),
        patch("core.llm_orchestration.gateway.CacheManager") as mock_cache,
        patch("core.llm_orchestration.gateway.CircuitBreakerManager") as mock_circuit,
        patch("core.llm_orchestration.gateway.AnalyticsCollector") as mock_analytics,
    ):

        # Set up AsyncMock for all async methods
        mock_budget_instance = mock_budget.return_value
        mock_budget_instance.initialize = AsyncMock()
        mock_budget_instance.check_budget = AsyncMock(return_value=True)
        mock_budget_instance.can_proceed = AsyncMock(return_value=True)
        mock_budget_instance.get_global_status = AsyncMock(
            return_value={"budget": "ok"}
        )
        mock_budget_instance.get_status = AsyncMock(return_value={"budget": "ok"})
        mock_budget_instance.record_usage = AsyncMock()
        mock_budget_instance.shutdown = AsyncMock()

        mock_cache_instance = mock_cache.return_value
        mock_cache_instance.initialize = AsyncMock()
        mock_cache_instance.get = AsyncMock(return_value=None)
        mock_cache_instance.set = AsyncMock()
        mock_cache_instance.get_status = AsyncMock(return_value={"cache": "ok"})
        mock_cache_instance.get_stats = Mock(return_value={"hits": 0, "misses": 0})
        mock_cache_instance.shutdown = AsyncMock()

        mock_circuit_instance = mock_circuit.return_value
        mock_circuit_instance.initialize = AsyncMock()
        mock_circuit_instance.can_proceed = Mock(return_value=True)
        mock_circuit_instance.get_status = Mock(return_value={"status": "ok"})
        mock_circuit_instance.add_model = Mock()
        mock_circuit_instance.remove_model = Mock()

        mock_routing_instance = mock_routing.return_value
        mock_routing_instance.select_adapter = AsyncMock()
        mock_routing_instance.select_fallback_adapter = AsyncMock()
        mock_routing_instance.select_model = AsyncMock(return_value="test-model")

        mock_usage_instance = mock_usage.return_value
        mock_usage_instance.log_request = AsyncMock()
        mock_usage_instance.shutdown = AsyncMock()

        mock_analytics_instance = mock_analytics.return_value
        mock_analytics_instance.record_request = AsyncMock()
        mock_analytics_instance.shutdown = AsyncMock()

        gateway = LLMGateway(mock_config_manager, mock_key_vault, mock_db_session)
        return gateway


class TestGatewayRequest:
    """Test GatewayRequest data structure"""

    def test_gateway_request_creation(self):
        """Test basic GatewayRequest creation"""
        request = GatewayRequest(
            prompt="Test prompt",
            user_id="user123",
            task_type="chat",
            user_tier="premium",
            max_tokens=100,
            temperature=0.7,
            stream=True,
            priority=5,
            metadata={"source": "test"},
        )

        assert request.prompt == "Test prompt"
        assert request.user_id == "user123"
        assert request.task_type == "chat"
        assert request.user_tier == "premium"
        assert request.max_tokens == 100
        assert request.temperature == 0.7
        assert request.stream is True
        assert request.priority == 5
        assert request.metadata == {"source": "test"}

    def test_gateway_request_defaults(self):
        """Test GatewayRequest with minimal parameters"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        assert request.task_type is None
        assert request.user_tier is None
        assert request.session_id is None
        assert request.max_tokens is None
        assert request.temperature is None
        assert request.stream is False
        assert request.priority == 0
        assert request.metadata is None


class TestGatewayResponse:
    """Test GatewayResponse data structure"""

    def test_gateway_response_creation(self):
        """Test GatewayResponse creation"""
        response = GatewayResponse(
            content="Test response",
            model_used="gpt-4",
            provider="openai",
            request_id="req123",
            tokens_used=50,
            cost_estimate=0.001,
            latency_ms=200,
            cached=True,
            user_id="user123",
            session_id="session123",
            metadata={"quality": "high"},
        )

        assert response.content == "Test response"
        assert response.model_used == "gpt-4"
        assert response.provider == "openai"
        assert response.request_id == "req123"
        assert response.tokens_used == 50
        assert response.cost_estimate == 0.001
        assert response.latency_ms == 200
        assert response.cached is True
        assert response.user_id == "user123"
        assert response.session_id == "session123"
        assert response.metadata == {"quality": "high"}


class TestLLMGateway:
    """Comprehensive tests for LLMGateway class"""

    def test_gateway_initialization(self, gateway):
        """Test gateway constructor"""
        assert gateway.config_manager is not None
        assert gateway.key_vault_service is not None
        assert gateway.db is not None
        assert gateway.is_initialized is False
        assert gateway._health_check_interval == 60
        assert gateway._last_health_check == 0.0
        assert isinstance(gateway.adapters, dict)

    @pytest.mark.asyncio
    async def test_initialize_with_active_models(self, gateway, mock_config_manager):
        """Test gateway initialization with active models"""
        # Setup mock active models
        secret_ref = SecretReference(
            provider=KeyVaultProvider.LOCAL_ENV, secret_identifier="TEST_KEY"
        )
        model_config = ModelConfiguration(
            model_id="test-model",
            provider="test-provider",
            model_name="test",
            api_key_secret_ref=secret_ref,
        )
        mock_config_manager.get_active_models.return_value = [model_config]

        # Mock adapters creation
        mock_adapter = Mock(spec=LLMServiceAdapter)
        mock_adapter.model_id = "test-model"

        with patch(
            "core.llm_orchestration.gateway.create_adapters_from_configs"
        ) as mock_create:
            mock_create.return_value = {"test-model": mock_adapter}

            # Mock component initialization
            gateway.budget_manager.initialize = AsyncMock()
            gateway.cache_manager.initialize = AsyncMock()
            gateway.circuit_breaker.initialize = AsyncMock()
            gateway._perform_health_check = AsyncMock()

            await gateway.initialize()

            assert gateway.is_initialized is True
            assert "test-model" in gateway.adapters
            mock_create.assert_called_once()
            gateway.budget_manager.initialize.assert_called_once()
            gateway.cache_manager.initialize.assert_called_once()
            gateway.circuit_breaker.initialize.assert_called_once()
            gateway._perform_health_check.assert_called_once()

    @pytest.mark.asyncio
    async def test_initialize_no_active_models_fallback(
        self, gateway, mock_config_manager
    ):
        """Test gateway initialization creates fallback when no active models"""
        mock_config_manager.get_active_models.return_value = []

        mock_adapter = Mock(spec=LLMServiceAdapter)
        mock_adapter.model_id = "fallback"

        with patch(
            "core.llm_orchestration.gateway.create_adapters_from_configs"
        ) as mock_create:
            mock_create.return_value = {"fallback": mock_adapter}

            # Mock component initialization
            gateway.budget_manager.initialize = AsyncMock()
            gateway.cache_manager.initialize = AsyncMock()
            gateway.circuit_breaker.initialize = AsyncMock()
            gateway._perform_health_check = AsyncMock()

            await gateway.initialize()

            assert gateway.is_initialized is True
            # Should create fallback configuration
            call_args = mock_create.call_args[0][0]
            assert len(call_args) == 1
            assert call_args[0].model_id == "fallback"

    @pytest.mark.asyncio
    async def test_initialize_failure_handling(self, gateway):
        """Test gateway initialization failure handling"""
        gateway.config_manager.load_configurations = AsyncMock(
            side_effect=Exception("Config error")
        )

        with pytest.raises(Exception, match="Config error"):
            await gateway.initialize()

        assert gateway.is_initialized is False

    @pytest.mark.asyncio
    async def test_process_request_not_initialized(self, gateway):
        """Test process_request fails when not initialized"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        with pytest.raises(RuntimeError, match="Gateway not initialized"):
            await gateway.process_request(request)

    @pytest.mark.asyncio
    async def test_process_request_with_cache_hit(self, gateway):
        """Test process_request with cache hit"""
        gateway.is_initialized = True
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Create cached response
        cached_response = LLMResponse(
            content="Cached response",
            model_used="test-model",
            provider="test-provider",
            tokens_used=20,
            cost_estimate=0.01,
            latency_ms=5,
        )

        # Mock cache hit
        gateway.cache_manager.get = AsyncMock(return_value=cached_response)

        # Process request
        result = await gateway.process_request(request)

        assert isinstance(result, GatewayResponse)
        assert result.content == "Cached response"
        assert result.cached is True
        gateway.cache_manager.get.assert_called_once()

    @pytest.mark.asyncio
    async def test_process_request_full_pipeline(self, gateway):
        """Test complete process_request pipeline without cache"""
        gateway.is_initialized = True
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Mock all pipeline steps
        enriched_request = Mock()
        selected_adapter = Mock(spec=LLMServiceAdapter)
        selected_adapter.model_id = "test-model"

        # Create expected response with all required parameters
        llm_response = LLMResponse(
            content="Generated response",
            model_used="test-model",
            provider="test-provider",
            tokens_used=50,
            cost_estimate=0.001,
            latency_ms=200,
        )

        gateway._enrich_request = AsyncMock(return_value=enriched_request)
        gateway._check_cache = AsyncMock(return_value=None)
        gateway._enforce_budget = AsyncMock()
        gateway._check_rate_limits = AsyncMock()
        gateway._select_model = AsyncMock(return_value=selected_adapter)
        gateway.circuit_breaker.can_proceed = Mock(return_value=True)
        gateway._execute_llm_request = AsyncMock(return_value=llm_response)
        gateway._create_gateway_response = AsyncMock(
            return_value=GatewayResponse(
                content="Generated response",
                model_used="test-model",
                provider="test",
                request_id="req123",
                tokens_used=50,
                cost_estimate=0.001,
                latency_ms=200,
            )
        )
        gateway._cache_response = AsyncMock()
        gateway._log_usage = AsyncMock()
        gateway.analytics.record_request = AsyncMock()

        result = await gateway.process_request(request)

        assert result.content == "Generated response"
        assert result.cached is False

        # Verify pipeline calls
        gateway._enrich_request.assert_called_once()
        gateway._check_cache.assert_called_once()
        gateway._enforce_budget.assert_called_once()
        gateway._check_rate_limits.assert_called_once()
        gateway._select_model.assert_called_once()
        gateway._execute_llm_request.assert_called_once()
        gateway._cache_response.assert_called_once()

    @pytest.mark.asyncio
    async def test_process_request_circuit_breaker_fallback(self, gateway):
        """Test process_request with circuit breaker triggering fallback"""
        gateway.is_initialized = True
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Mock components
        enriched_request = Mock()
        primary_adapter = Mock(spec=LLMServiceAdapter)
        primary_adapter.model_id = "primary-model"
        fallback_adapter = Mock(spec=LLMServiceAdapter)
        fallback_adapter.model_id = "fallback-model"

        gateway._enrich_request = AsyncMock(return_value=enriched_request)
        gateway._check_cache = AsyncMock(return_value=None)
        gateway._enforce_budget = AsyncMock()
        gateway._check_rate_limits = AsyncMock()
        gateway._select_model = AsyncMock(return_value=primary_adapter)
        gateway.circuit_breaker.can_proceed = Mock(
            return_value=False
        )  # Circuit breaker open
        gateway._select_fallback_model = AsyncMock(return_value=fallback_adapter)
        gateway._execute_llm_request = AsyncMock(return_value=Mock())
        gateway._create_gateway_response = AsyncMock(return_value=Mock())
        gateway._cache_response = AsyncMock()
        gateway._log_usage = AsyncMock()
        gateway.analytics.record_request = AsyncMock()

        await gateway.process_request(request)

        # Should try fallback when circuit breaker is open
        gateway._select_fallback_model.assert_called_once()

    @pytest.mark.asyncio
    async def test_process_stream(self, gateway):
        """Test streaming request processing"""
        gateway.is_initialized = True
        request = GatewayRequest(prompt="Test", user_id="user123", stream=True)

        # Create async iterator for streaming
        async def mock_stream():
            yield "chunk1"
            yield "chunk2"
            yield "chunk3"

        mock_adapter = Mock()
        mock_adapter.model_id = "test-model"
        mock_adapter.generate_stream = lambda request: mock_stream()

        gateway._enrich_request = AsyncMock(return_value=Mock())
        gateway._enforce_budget = AsyncMock()
        gateway._check_rate_limits = AsyncMock()
        gateway._select_model = AsyncMock(return_value=mock_adapter)
        gateway.circuit_breaker.can_proceed = Mock(return_value=True)
        gateway._log_usage = AsyncMock()
        gateway.analytics.record_request = AsyncMock()

        # Collect streamed chunks
        chunks = []
        async for chunk in gateway.process_stream(request):
            chunks.append(chunk)

        assert chunks == ["chunk1", "chunk2", "chunk3"]

    @pytest.mark.asyncio
    async def test_get_provider_status(self, gateway):
        """Test provider status retrieval"""
        gateway.is_initialized = True

        # Mock health check
        gateway._perform_health_check = AsyncMock()

        # Create proper mock health status using HealthCheckResult
        mock_health_status1 = HealthCheckResult(
            is_healthy=True, latency_ms=100, last_check=time.time(), error_message=None
        )

        mock_health_status2 = HealthCheckResult(
            is_healthy=False,
            latency_ms=500,
            last_check=time.time(),
            error_message="Connection timeout",
        )

        # Create proper mock model config
        mock_model_config1 = Mock()
        mock_model_config1.model_name = "gpt-4"

        mock_model_config2 = Mock()
        mock_model_config2.model_name = "gpt-3.5"

        # Mock adapter statuses with all required attributes
        mock_adapter1 = Mock()
        mock_adapter1.model_id = "model1"
        mock_adapter1.provider = LLMProvider.OPENAI  # Use enum, not string
        mock_adapter1.model_config = mock_model_config1
        mock_adapter1.get_status = AsyncMock(return_value={"status": "healthy"})
        mock_adapter1.is_healthy = Mock(return_value=True)
        mock_adapter1.get_health_status = Mock(return_value=mock_health_status1)

        mock_adapter2 = Mock()
        mock_adapter2.model_id = "model2"
        mock_adapter2.provider = LLMProvider.ANTHROPIC  # Use enum, not string
        mock_adapter2.model_config = mock_model_config2
        mock_adapter2.get_status = AsyncMock(return_value={"status": "degraded"})
        mock_adapter2.is_healthy = Mock(return_value=False)
        mock_adapter2.get_health_status = Mock(return_value=mock_health_status2)

        gateway.adapters = {"model1": mock_adapter1, "model2": mock_adapter2}

        status = await gateway.get_provider_status()

        assert status["active_models"] == 1  # Only adapter1 is healthy
        assert status["total_models"] == 2
        assert "circuit_breakers" in status
        assert "cache_stats" in status
        assert "budget_status" in status
        assert "providers" in status

        # Check provider details
        assert "model1" in status["providers"]
        assert "model2" in status["providers"]
        assert status["providers"]["model1"]["provider"] == "openai"  # Enum value
        assert status["providers"]["model1"]["is_healthy"] is True
        assert status["providers"]["model2"]["provider"] == "anthropic"  # Enum value
        assert status["providers"]["model2"]["is_healthy"] is False

    @pytest.mark.asyncio
    async def test_admin_add_model(self, gateway):
        """Test admin model addition"""
        secret_ref = SecretReference(
            provider=KeyVaultProvider.LOCAL_ENV, secret_identifier="NEW_KEY"
        )

        # Mock successful addition - use correct method name
        gateway.config_manager.add_model_configuration = AsyncMock(return_value=True)
        mock_adapter = Mock(spec=LLMServiceAdapter)

        # Mock circuit breaker add_model method
        gateway.circuit_breaker.add_model = Mock()

        with patch("core.llm_orchestration.gateway.AdapterFactory") as mock_factory:
            mock_factory.create_adapter = Mock(return_value=mock_adapter)  # Not async

            result = await gateway.admin_add_model(
                model_id="new-model",
                provider="new-provider",
                model_name="new-model-name",
                api_key_secret_ref=secret_ref,
            )

            assert result is True
            assert "new-model" in gateway.adapters
            gateway.config_manager.add_model_configuration.assert_called_once()
            gateway.circuit_breaker.add_model.assert_called_once_with("new-model")

    @pytest.mark.asyncio
    async def test_admin_add_model_failure(self, gateway):
        """Test admin model addition failure"""
        secret_ref = SecretReference(
            provider=KeyVaultProvider.LOCAL_ENV, secret_identifier="INVALID_KEY"
        )

        # Mock config addition failure
        gateway.config_manager.add_model_configuration = AsyncMock(return_value=False)

        result = await gateway.admin_add_model(
            model_id="invalid-model",
            provider="provider",
            model_name="model",
            api_key_secret_ref=secret_ref,
        )

        assert result is False
        assert "invalid-model" not in gateway.adapters

    @pytest.mark.asyncio
    async def test_admin_toggle_model(self, gateway):
        """Test admin model toggle"""
        # Mock existing adapter
        mock_adapter = Mock(spec=LLMServiceAdapter)
        gateway.adapters = {"test-model": mock_adapter}

        # Mock successful toggle - use correct method name
        gateway.config_manager.toggle_model_activation = AsyncMock(return_value=True)

        # Mock circuit breaker methods
        gateway.circuit_breaker.remove_model = Mock()

        result = await gateway.admin_toggle_model("test-model", False)

        assert result is True
        assert (
            "test-model" not in gateway.adapters
        )  # Should be removed when deactivated
        gateway.config_manager.toggle_model_activation.assert_called_once_with(
            "test-model", False
        )
        gateway.circuit_breaker.remove_model.assert_called_once_with("test-model")

    @pytest.mark.asyncio
    async def test_admin_toggle_nonexistent_model(self, gateway):
        """Test admin toggle for non-existent model"""
        gateway.adapters = {}

        result = await gateway.admin_toggle_model("nonexistent", True)

        assert result is False

    @pytest.mark.asyncio
    async def test_enrich_request(self, gateway):
        """Test request enrichment"""
        request = GatewayRequest(
            prompt="Test prompt",
            user_id="user123",
            task_type="chat",
            max_tokens=100,
            temperature=0.7,
        )

        enriched = await gateway._enrich_request(request, "req123")

        assert isinstance(enriched, LLMRequest)
        assert enriched.prompt == "Test prompt"
        assert enriched.user_id == "user123"
        assert enriched.max_tokens == 100
        assert enriched.temperature == 0.7
        assert (
            enriched.context["request_id"] == "req123"
        )  # request_id is in context, not direct attribute

    @pytest.mark.asyncio
    async def test_check_cache(self, gateway):
        """Test cache checking"""
        request = Mock()

        # Mock cache hit
        gateway.cache_manager.get = AsyncMock(return_value={"content": "cached"})

        await gateway._check_cache(request)

        gateway.cache_manager.get.assert_called_once()

    @pytest.mark.asyncio
    async def test_enforce_budget(self, gateway):
        """Test budget enforcement"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Mock the correct method that's actually called
        gateway.budget_manager.can_proceed = AsyncMock(return_value=True)

        await gateway._enforce_budget(request)

        # Assert the correct method was called
        gateway.budget_manager.can_proceed.assert_called_once_with("user123", [])

    @pytest.mark.asyncio
    async def test_check_rate_limits(self, gateway):
        """Test rate limiting"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Should complete without error (no rate limiting logic to test)
        await gateway._check_rate_limits(request)

    @pytest.mark.asyncio
    async def test_select_model(self, gateway):
        """Test model selection"""
        # Create proper LLMRequest object
        request = LLMRequest(
            prompt="Test prompt",
            user_id="user123",
            context={"user_tier": "premium", "priority": 5},
        )

        # Set up adapters dictionary
        mock_adapter = Mock(spec=LLMServiceAdapter)
        mock_adapter.model_id = "test-model"
        gateway.adapters = {"test-model": mock_adapter}

        # Mock routing engine to return a model ID that exists in adapters
        gateway.routing_engine.select_model = AsyncMock(return_value="test-model")

        result = await gateway._select_model(request)

        assert result == mock_adapter
        gateway.routing_engine.select_model.assert_called_once()

    @pytest.mark.asyncio
    async def test_select_fallback_model(self, gateway):
        """Test fallback model selection"""
        request = Mock()

        # Set up a fallback adapter in the gateway
        fallback_adapter = Mock(spec=LLMServiceAdapter)
        fallback_adapter.is_healthy.return_value = True
        gateway.adapters = {"fallback": fallback_adapter}
        gateway.circuit_breaker.can_proceed.return_value = True

        result = await gateway._select_fallback_model(request)

        assert result == fallback_adapter

    @pytest.mark.asyncio
    async def test_execute_llm_request(self, gateway):
        """Test LLM request execution"""
        adapter = Mock(spec=LLMServiceAdapter)
        request = Mock()
        response = Mock()

        adapter.generate_response = AsyncMock(return_value=response)

        result = await gateway._execute_llm_request(adapter, request)

        assert result == response
        adapter.generate_response.assert_called_once_with(request)

    @pytest.mark.asyncio
    async def test_create_gateway_response(self, gateway):
        """Test gateway response creation"""
        llm_response = LLMResponse(
            content="Test response",
            model_used="test-model",
            provider="test-provider",
            tokens_used=50,
            cost_estimate=0.02,
            latency_ms=200,
        )

        original_request = GatewayRequest(
            prompt="Test", user_id="user123", session_id="session123"
        )

        start_time = time.time() - 0.2  # 200ms ago

        result = await gateway._create_gateway_response(
            llm_response, original_request, "req123", start_time
        )

        assert isinstance(result, GatewayResponse)
        assert result.content == "Test response"
        assert result.model_used == "test-model"
        assert result.request_id == "req123"
        assert result.tokens_used == 50
        assert result.cost_estimate == 0.02
        assert result.user_id == "user123"
        assert result.session_id == "session123"
        assert result.cached is False
        assert result.latency_ms > 0

    @pytest.mark.asyncio
    async def test_cache_response(self, gateway):
        """Test response caching"""
        request = Mock()
        response = Mock()

        gateway.cache_manager.set = AsyncMock()

        await gateway._cache_response(request, response)

        gateway.cache_manager.set.assert_called_once()

    @pytest.mark.asyncio
    async def test_log_usage(self, gateway):
        """Test usage logging"""
        request = GatewayRequest(prompt="Test", user_id="user123")
        response = Mock()

        gateway.usage_logger.log_request = AsyncMock()

        await gateway._log_usage(request, response, "req123")

        gateway.usage_logger.log_request.assert_called_once()

    @pytest.mark.asyncio
    async def test_handle_error_fallback(self, gateway):
        """Test error fallback handling"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Set up fallback adapter
        fallback_adapter = Mock()
        fallback_response = Mock()
        fallback_response.content = "Fallback response"
        fallback_response.tokens_used = 10
        fallback_response.latency_ms = 100
        fallback_adapter.generate_response = AsyncMock(return_value=fallback_response)

        gateway.adapters = {"fallback": fallback_adapter}
        gateway._enrich_request = AsyncMock(return_value=Mock())

        result = await gateway._handle_error_fallback(request, "req123", "Test error")

        assert result is not None
        assert "Service temporarily unavailable" in result.content
        assert result.model_used == "fallback"
        assert result.provider == "fallback"

    @pytest.mark.asyncio
    async def test_perform_health_check(self, gateway):
        """Test health check performance"""
        gateway.adapters = {"model1": Mock(), "model2": Mock()}

        with patch(
            "core.llm_orchestration.gateway.health_check_all_adapters"
        ) as mock_health:
            # Return proper HealthCheckResult objects instead of booleans
            mock_health.return_value = {
                "model1": HealthCheckResult(
                    is_healthy=True,
                    latency_ms=100,
                    last_check=time.time(),
                    error_message=None,
                ),
                "model2": HealthCheckResult(
                    is_healthy=False,
                    latency_ms=500,
                    last_check=time.time(),
                    error_message="Error",
                ),
            }

            await gateway._perform_health_check()

            mock_health.assert_called_once()
            assert gateway._last_health_check > 0

    @pytest.mark.asyncio
    async def test_shutdown(self, gateway):
        """Test gateway shutdown"""
        # Mock adapters (shutdown method not called in actual implementation)
        adapter1 = Mock()
        adapter2 = Mock()

        gateway.adapters = {"model1": adapter1, "model2": adapter2}

        # Ensure cache_manager, usage_logger, and analytics have async shutdown methods
        gateway.cache_manager.shutdown = AsyncMock()
        gateway.usage_logger.shutdown = AsyncMock()
        gateway.analytics.shutdown = AsyncMock()

        await gateway.shutdown()

        # Check that the service shutdowns were called
        gateway.cache_manager.shutdown.assert_called_once()
        gateway.usage_logger.shutdown.assert_called_once()
        gateway.analytics.shutdown.assert_called_once()

        # Check that adapters were cleared and gateway is no longer initialized
        assert len(gateway.adapters) == 0
        assert gateway.is_initialized is False


class TestGatewayFunctions:
    """Test module-level gateway functions"""

    @pytest.mark.asyncio
    async def test_initialize_gateway(self):
        """Test gateway initialization function"""
        config_manager = Mock()
        key_vault = Mock()
        db_session = Mock()

        with patch("core.llm_orchestration.gateway.LLMGateway") as mock_gateway_class:
            mock_gateway = Mock()
            mock_gateway.initialize = AsyncMock()
            mock_gateway_class.return_value = mock_gateway

            result = await initialize_gateway(config_manager, key_vault, db_session)

            assert result == mock_gateway
            mock_gateway.initialize.assert_called_once()

    def test_get_gateway(self):
        """Test get_gateway function"""
        with patch("core.llm_orchestration.gateway.gateway", None):
            with pytest.raises(RuntimeError, match="Gateway not initialized"):
                get_gateway()


class TestErrorHandling:
    """Test error handling scenarios"""

    @pytest.fixture
    def gateway_with_error(self, mock_config_manager, mock_key_vault, mock_db_session):
        """Gateway configured to trigger errors"""
        with (
            patch("core.llm_orchestration.gateway.RoutingStrategyEngine"),
            patch("core.llm_orchestration.gateway.BudgetManager"),
            patch("core.llm_orchestration.gateway.UsageLogger"),
            patch("core.llm_orchestration.gateway.CostEstimator"),
            patch("core.llm_orchestration.gateway.CacheManager"),
            patch("core.llm_orchestration.gateway.CircuitBreakerManager"),
            patch("core.llm_orchestration.gateway.AnalyticsCollector"),
        ):

            return LLMGateway(mock_config_manager, mock_key_vault, mock_db_session)

    @pytest.mark.asyncio
    async def test_process_request_error_fallback(self, gateway_with_error):
        """Test process_request with error triggering fallback"""
        gateway_with_error.is_initialized = True
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Mock error in main pipeline
        gateway_with_error._enrich_request = AsyncMock(return_value=Mock())
        gateway_with_error._check_cache = AsyncMock(return_value=None)
        gateway_with_error._enforce_budget = AsyncMock(
            side_effect=Exception("Budget error")
        )
        gateway_with_error._handle_error_fallback = AsyncMock(return_value=Mock())

        await gateway_with_error.process_request(request)

        # Should call error fallback
        gateway_with_error._handle_error_fallback.assert_called_once()

    @pytest.mark.asyncio
    async def test_admin_add_model_exception(self, gateway_with_error):
        """Test admin_add_model with exception"""
        secret_ref = Mock()

        gateway_with_error.config_manager.add_model_configuration = AsyncMock(
            side_effect=Exception("Config error")
        )

        result = await gateway_with_error.admin_add_model(
            "model", "provider", "name", secret_ref
        )

        assert result is False

    @pytest.mark.asyncio
    async def test_admin_toggle_model_exception(self, gateway_with_error):
        """Test admin_toggle_model with exception"""
        gateway_with_error.adapters = {"test-model": Mock()}
        gateway_with_error.config_manager.toggle_model = AsyncMock(
            side_effect=Exception("Toggle error")
        )

        result = await gateway_with_error.admin_toggle_model("test-model", True)

        assert result is False

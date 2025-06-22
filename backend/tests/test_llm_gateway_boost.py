"""
High-Impact Coverage Boost: LLM Gateway Tests
Target: core/llm_orchestration/gateway.py (30% → 80%+ coverage)
189 missing lines - HIGHEST PRIORITY for Phase 3
"""

import time
from unittest.mock import AsyncMock, Mock, patch

import pytest

from core.llm_orchestration.adapters import LLMRequest, LLMResponse
from core.llm_orchestration.gateway import GatewayRequest, GatewayResponse, LLMGateway
from core.llm_orchestration.key_vault import KeyVaultProvider, SecretReference


class TestGatewayDataStructures:
    """Test gateway data structures - easy coverage wins"""

    def test_gateway_request_creation(self):
        """Test GatewayRequest creation with all fields"""
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
        """Test GatewayRequest defaults"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        assert request.task_type is None
        assert request.user_tier is None
        assert request.session_id is None
        assert request.max_tokens is None
        assert request.temperature is None
        assert request.stream is False
        assert request.priority == 0
        assert request.metadata is None

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


class TestLLMGatewayCore:
    """Test core LLMGateway functionality"""

    @pytest.fixture
    def mock_components(self):
        """Mock all gateway dependencies"""
        with (
            patch("core.llm_orchestration.gateway.RoutingStrategyEngine") as routing,
            patch("core.llm_orchestration.gateway.BudgetManager") as budget,
            patch("core.llm_orchestration.gateway.UsageLogger") as usage,
            patch("core.llm_orchestration.gateway.CostEstimator") as cost,
            patch("core.llm_orchestration.gateway.CacheManager") as cache,
            patch("core.llm_orchestration.gateway.CircuitBreakerManager") as circuit,
            patch("core.llm_orchestration.gateway.AnalyticsCollector") as analytics,
        ):

            yield {
                "routing": routing,
                "budget": budget,
                "usage": usage,
                "cost": cost,
                "cache": cache,
                "circuit": circuit,
                "analytics": analytics,
            }

    @pytest.fixture
    def gateway(self, mock_components):
        """Create LLMGateway with mocked dependencies"""
        config_manager = Mock()
        key_vault = Mock()
        db_session = Mock()

        gateway = LLMGateway(config_manager, key_vault, db_session)
        return gateway

    def test_gateway_initialization(self, gateway):
        """Test gateway constructor - covers init method"""
        assert gateway.config_manager is not None
        assert gateway.key_vault_service is not None
        assert gateway.db is not None
        assert gateway.is_initialized is False
        assert gateway._health_check_interval == 60
        assert gateway._last_health_check == 0.0
        assert isinstance(gateway.adapters, dict)
        assert len(gateway.adapters) == 0

    @pytest.mark.asyncio
    async def test_initialize_no_models_fallback(self, gateway):
        """Test initialization with no active models creates fallback"""
        # Mock no active models
        gateway.config_manager.load_configurations = AsyncMock()
        gateway.config_manager.get_active_models = Mock(return_value=[])

        # Mock adapter creation
        mock_adapter = Mock()
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
            assert "fallback" in gateway.adapters

            # Verify fallback config was created
            call_args = mock_create.call_args[0][0]
            assert len(call_args) == 1
            assert call_args[0].model_id == "fallback"
            assert call_args[0].provider == "fallback"

    @pytest.mark.asyncio
    async def test_initialize_failure_handling(self, gateway):
        """Test initialization failure handling"""
        gateway.config_manager.load_configurations = AsyncMock(
            side_effect=Exception("Config load failed")
        )

        with pytest.raises(Exception, match="Config load failed"):
            await gateway.initialize()

        assert gateway.is_initialized is False

    @pytest.mark.asyncio
    async def test_process_request_not_initialized(self, gateway):
        """Test process_request fails when gateway not initialized"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        with pytest.raises(RuntimeError, match="Gateway not initialized"):
            await gateway.process_request(request)

    @pytest.mark.asyncio
    async def test_process_request_cache_hit(self, gateway):
        """Test process_request with cache hit path"""
        gateway.is_initialized = True
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Mock cache hit - FIX: Add provider parameter
        cached_response = LLMResponse(
            content="Cached response",
            model_used="test-model",
            provider="test-provider",  # Added missing provider
            tokens_used=20,
            cost_estimate=0.0005,
            latency_ms=5,
        )

        gateway._enrich_request = AsyncMock(return_value=Mock())
        gateway._check_cache = AsyncMock(return_value=cached_response)
        gateway._create_gateway_response = AsyncMock(
            return_value=GatewayResponse(
                content="Cached response",
                model_used="test-model",
                provider="test",
                request_id="req123",
                tokens_used=20,
                cost_estimate=0.0005,
                latency_ms=5,
                cached=True,
            )
        )

        result = await gateway.process_request(request)

        assert result.cached is True
        assert result.content == "Cached response"
        gateway._check_cache.assert_called_once()

    @pytest.mark.asyncio
    async def test_enrich_request(self, gateway):
        """Test request enrichment method - covers _enrich_request"""
        request = GatewayRequest(
            prompt="Test prompt",
            user_id="user123",
            task_type="chat",
            max_tokens=100,
            temperature=0.7,
            metadata={"source": "test"},
        )

        enriched = await gateway._enrich_request(request, "req123")

        assert isinstance(enriched, LLMRequest)
        assert enriched.prompt == "Test prompt"
        assert enriched.user_id == "user123"
        assert enriched.max_tokens == 100
        assert enriched.temperature == 0.7
        # Note: LLMRequest doesn't have request_id attribute, it's added during processing
        assert enriched.metadata == {"source": "test"}

    @pytest.mark.asyncio
    async def test_check_cache(self, gateway):
        """Test cache checking method - covers _check_cache"""
        request = Mock()

        # Mock cache miss
        gateway.cache_manager.get = AsyncMock(return_value=None)
        result = await gateway._check_cache(request)
        assert result is None

        # Mock cache hit
        cached_data = {"content": "cached response", "model_used": "test"}
        gateway.cache_manager.get = AsyncMock(return_value=cached_data)
        result = await gateway._check_cache(request)
        assert result == cached_data

    @pytest.mark.asyncio
    async def test_enforce_budget(self, gateway):
        """Test budget enforcement method - covers _enforce_budget"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        # FIX: Mock budget check as AsyncMock returning True
        gateway.budget_manager.can_proceed = AsyncMock(return_value=True)

        # Should complete without error
        await gateway._enforce_budget(request)

        gateway.budget_manager.can_proceed.assert_called_once()

    @pytest.mark.asyncio
    async def test_check_rate_limits(self, gateway):
        """Test rate limiting method - covers _check_rate_limits"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Basic method that should complete without error
        await gateway._check_rate_limits(request)

        # Test with user tier
        request.user_tier = "premium"
        await gateway._check_rate_limits(request)

    @pytest.mark.asyncio
    async def test_select_model(self, gateway):
        """Test model selection method - covers _select_model"""
        request = Mock()
        mock_adapter = Mock()
        mock_adapter.model_id = "selected-model"

        # FIX: Mock select_model as AsyncMock
        gateway.routing_engine.select_model = AsyncMock(return_value="selected-model")
        gateway.adapters = {"selected-model": mock_adapter}

        result = await gateway._select_model(request)

        assert result == mock_adapter
        gateway.routing_engine.select_model.assert_called_once()

    @pytest.mark.asyncio
    async def test_select_fallback_model(self, gateway):
        """Test fallback model selection - covers _select_fallback_model"""
        request = Mock()
        fallback_adapter = Mock()
        fallback_adapter.model_id = "fallback-model"

        # FIX: Add fallback adapter to gateway.adapters to prevent "No healthy models" error
        gateway.adapters = {"fallback-model": fallback_adapter}

        result = await gateway._select_fallback_model(request)

        assert result == fallback_adapter

    @pytest.mark.asyncio
    async def test_execute_llm_request(self, gateway):
        """Test LLM request execution - covers _execute_llm_request"""
        adapter = Mock()
        request = Mock()

        # FIX: Add provider parameter to LLMResponse
        mock_response = LLMResponse(
            content="Generated response",
            model_used="test-model",
            provider="test-provider",  # Added missing provider
            tokens_used=50,
            cost_estimate=0.001,
            latency_ms=200,
        )

        # FIX: Use generate_response method and AsyncMock
        adapter.generate_response = AsyncMock(return_value=mock_response)

        result = await gateway._execute_llm_request(adapter, request)

        assert result == mock_response
        adapter.generate_response.assert_called_once_with(request)

    @pytest.mark.asyncio
    async def test_create_gateway_response(self, gateway):
        """Test gateway response creation - covers _create_gateway_response"""
        # FIX: Add provider parameter to LLMResponse
        llm_response = LLMResponse(
            content="Test response",
            model_used="test-model",
            provider="test-provider",  # Added missing provider
            tokens_used=50,
            cost_estimate=0.001,
            latency_ms=100,
        )

        original_request = GatewayRequest(
            prompt="Test", user_id="user123", session_id="session123"
        )

        start_time = time.time() - 0.2  # 200ms ago

        result = await gateway._create_gateway_response(
            llm_response, original_request, "req123", start_time, cached=False
        )

        assert isinstance(result, GatewayResponse)
        assert result.content == "Test response"
        assert result.model_used == "test-model"
        assert result.request_id == "req123"
        assert result.tokens_used == 50
        assert result.cost_estimate == 0.001
        assert result.user_id == "user123"
        assert result.session_id == "session123"
        assert result.cached is False
        assert result.latency_ms >= 180  # Should be around 200ms

    @pytest.mark.asyncio
    async def test_cache_response(self, gateway):
        """Test response caching - covers _cache_response"""
        request = Mock()
        response = Mock()

        gateway.cache_manager.set = AsyncMock()

        await gateway._cache_response(request, response)

        gateway.cache_manager.set.assert_called_once()

    @pytest.mark.asyncio
    async def test_log_usage(self, gateway):
        """Test usage logging - covers _log_usage"""
        request = GatewayRequest(prompt="Test", user_id="user123")
        response = Mock()

        gateway.usage_logger.log_request = AsyncMock()

        await gateway._log_usage(request, response, "req123")

        gateway.usage_logger.log_request.assert_called_once()

    @pytest.mark.asyncio
    async def test_perform_health_check(self, gateway):
        """Test health check performance - covers _perform_health_check"""
        gateway.adapters = {"model1": Mock(), "model2": Mock()}

        with patch(
            "core.llm_orchestration.gateway.health_check_all_adapters"
        ) as mock_health:
            # FIX: Return HealthCheckResult objects instead of booleans
            from core.llm_orchestration.adapters import HealthCheckResult

            mock_health.return_value = {
                "model1": HealthCheckResult(is_healthy=True, latency_ms=100),
                "model2": HealthCheckResult(
                    is_healthy=False, error_message="API error"
                ),
            }

            initial_time = gateway._last_health_check
            await gateway._perform_health_check()

            mock_health.assert_called_once_with(gateway.adapters)
            assert gateway._last_health_check > initial_time

    @pytest.mark.asyncio
    async def test_shutdown(self, gateway):
        """Test gateway shutdown - covers shutdown method"""
        # Mock adapters (no shutdown method expected based on actual implementation)
        adapter1 = Mock()
        adapter2 = Mock()

        gateway.adapters = {"model1": adapter1, "model2": adapter2}

        # FIX: Only mock the components that actually get shutdown called
        gateway.cache_manager.shutdown = AsyncMock()
        gateway.usage_logger.shutdown = AsyncMock()
        gateway.analytics.shutdown = AsyncMock()

        await gateway.shutdown()

        # Verify only the expected shutdowns called (based on actual implementation)
        gateway.cache_manager.shutdown.assert_called_once()
        gateway.usage_logger.shutdown.assert_called_once()
        gateway.analytics.shutdown.assert_called_once()

        # Verify adapters cleared and gateway marked as not initialized
        assert len(gateway.adapters) == 0
        assert gateway.is_initialized is False


class TestGatewayAdvanced:
    """Test advanced gateway functionality"""

    @pytest.fixture
    def initialized_gateway(self):
        """Gateway that's already initialized"""
        with (
            patch("core.llm_orchestration.gateway.RoutingStrategyEngine"),
            patch("core.llm_orchestration.gateway.BudgetManager"),
            patch("core.llm_orchestration.gateway.UsageLogger"),
            patch("core.llm_orchestration.gateway.CostEstimator"),
            patch("core.llm_orchestration.gateway.CacheManager"),
            patch("core.llm_orchestration.gateway.CircuitBreakerManager"),
            patch("core.llm_orchestration.gateway.AnalyticsCollector"),
        ):

            gateway = LLMGateway(Mock(), Mock(), Mock())
            gateway.is_initialized = True
            return gateway

    @pytest.mark.asyncio
    async def test_get_provider_status(self, initialized_gateway):
        """Test provider status retrieval - covers get_provider_status"""
        gateway = initialized_gateway

        # Mock health check
        gateway._perform_health_check = AsyncMock()

        # Mock adapter statuses
        from core.llm_orchestration.adapters import HealthCheckResult, LLMProvider

        mock_adapter1 = Mock()
        mock_adapter1.model_id = "model1"
        mock_adapter1.provider = LLMProvider.OPENAI  # FIX: Use LLMProvider enum
        mock_adapter1.model_config = Mock()
        mock_adapter1.model_config.model_name = "gpt-4"
        mock_adapter1.get_health_status = Mock(
            return_value=HealthCheckResult(
                is_healthy=True, latency_ms=100, last_check=1234567890.0
            )
        )
        mock_adapter1.is_healthy = Mock(return_value=True)

        mock_adapter2 = Mock()
        mock_adapter2.model_id = "model2"
        mock_adapter2.provider = LLMProvider.GEMINI  # FIX: Use LLMProvider enum
        mock_adapter2.model_config = Mock()
        mock_adapter2.model_config.model_name = "gemini-pro"
        mock_adapter2.get_health_status = Mock(
            return_value=HealthCheckResult(
                is_healthy=False,
                latency_ms=500,
                error_message="API error",
                last_check=1234567890.0,
            )
        )
        mock_adapter2.is_healthy = Mock(return_value=False)

        gateway.adapters = {"model1": mock_adapter1, "model2": mock_adapter2}

        # FIX: Mock get_global_status as AsyncMock and match actual implementation
        gateway.budget_manager.get_global_status = AsyncMock(
            return_value={"remaining_budget": 50.0}
        )
        gateway.cache_manager.get_stats = Mock(return_value={"hit_rate": 0.85})
        gateway.circuit_breaker.get_status = Mock(return_value={"status": "healthy"})

        status = await gateway.get_provider_status()

        # Verify status structure (match actual implementation keys)
        assert "providers" in status
        assert "budget_status" in status
        assert (
            "cache_stats" in status
        )  # Note: actual key is cache_stats not cache_status
        assert "circuit_breakers" in status
        assert "active_models" in status
        assert "total_models" in status

        # Check provider statuses (match actual implementation structure)
        providers = status["providers"]
        assert len(providers) == 2
        assert providers["model1"]["is_healthy"] is True
        assert providers["model1"]["provider"] == "openai"
        assert providers["model1"]["model_name"] == "gpt-4"
        assert providers["model2"]["is_healthy"] is False
        assert providers["model2"]["provider"] == "gemini"
        assert providers["model2"]["error_message"] == "API error"

        gateway._perform_health_check.assert_called_once()

    @pytest.mark.asyncio
    async def test_process_stream(self, initialized_gateway):
        """Test streaming request processing - covers process_stream"""
        gateway = initialized_gateway
        request = GatewayRequest(prompt="Test stream", user_id="user123", stream=True)

        # FIX: Create a proper async generator mock
        class MockAsyncGenerator:
            def __init__(self, items):
                self.items = items
                self.index = 0

            def __aiter__(self):
                return self

            async def __anext__(self):
                if self.index >= len(self.items):
                    raise StopAsyncIteration
                item = self.items[self.index]
                self.index += 1
                return item

        enriched_request = Mock()
        selected_adapter = Mock()
        selected_adapter.model_id = "stream-model"
        selected_adapter.generate_stream = Mock(
            return_value=MockAsyncGenerator(["chunk1", "chunk2", "chunk3"])
        )

        gateway._enrich_request = AsyncMock(return_value=enriched_request)
        gateway._enforce_budget = AsyncMock()
        gateway._check_rate_limits = AsyncMock()
        gateway._select_model = AsyncMock(return_value=selected_adapter)
        gateway.circuit_breaker.can_proceed = Mock(return_value=True)
        gateway._log_usage = AsyncMock()
        gateway.analytics.record_request = AsyncMock()

        # Collect streamed chunks
        chunks = []
        async for chunk in gateway.process_stream(request):
            chunks.append(chunk)

        assert chunks == ["chunk1", "chunk2", "chunk3"]

        # Verify streaming pipeline
        gateway._enrich_request.assert_called_once()
        gateway._enforce_budget.assert_called_once()
        gateway._select_model.assert_called_once()


class TestModuleFunctions:
    """Test module-level gateway functions"""

    @pytest.mark.asyncio
    async def test_initialize_gateway_function(self):
        """Test initialize_gateway module function"""
        config_manager = Mock()
        key_vault = Mock()
        db_session = Mock()

        with patch("core.llm_orchestration.gateway.LLMGateway") as mock_gateway_class:
            mock_gateway = Mock()
            mock_gateway.initialize = AsyncMock()
            mock_gateway_class.return_value = mock_gateway

            from core.llm_orchestration.gateway import initialize_gateway

            result = await initialize_gateway(config_manager, key_vault, db_session)

            assert result == mock_gateway
            mock_gateway_class.assert_called_once_with(
                config_manager, key_vault, db_session
            )
            mock_gateway.initialize.assert_called_once()

    def test_get_gateway_not_initialized(self):
        """Test get_gateway when not initialized"""
        # FIX: Patch the global gateway variable correctly
        with patch("core.llm_orchestration.gateway.gateway", None):
            from core.llm_orchestration.gateway import get_gateway

            with pytest.raises(RuntimeError, match="Gateway not initialized"):
                get_gateway()


class TestErrorScenarios:
    """Test error handling scenarios for better coverage"""

    @pytest.fixture
    def error_gateway(self):
        """Gateway configured for error testing"""
        with (
            patch("core.llm_orchestration.gateway.RoutingStrategyEngine"),
            patch("core.llm_orchestration.gateway.BudgetManager"),
            patch("core.llm_orchestration.gateway.UsageLogger"),
            patch("core.llm_orchestration.gateway.CostEstimator"),
            patch("core.llm_orchestration.gateway.CacheManager"),
            patch("core.llm_orchestration.gateway.CircuitBreakerManager"),
            patch("core.llm_orchestration.gateway.AnalyticsCollector"),
        ):

            gateway = LLMGateway(Mock(), Mock(), Mock())
            gateway.is_initialized = True
            return gateway

    @pytest.mark.asyncio
    async def test_handle_error_fallback(self, error_gateway):
        """Test error fallback handling - covers _handle_error_fallback"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Mock fallback response - FIX: Add provider parameter
        fallback_adapter = Mock()
        fallback_response = LLMResponse(
            content="Fallback response",
            model_used="fallback-model",
            provider="fallback-provider",  # Added missing provider
            tokens_used=30,
            cost_estimate=0.0005,
            latency_ms=150,
        )

        # FIX: Mock the fallback adapter and add it to adapters
        error_gateway.adapters = {"fallback": fallback_adapter}
        fallback_adapter.generate_response = AsyncMock(return_value=fallback_response)
        error_gateway._enrich_request = AsyncMock(return_value=Mock())

        result = await error_gateway._handle_error_fallback(
            request, "req123", "Original error"
        )

        assert result is not None
        assert "Service temporarily unavailable" in result.content
        assert result.provider == "fallback"
        fallback_adapter.generate_response.assert_called_once()

    @pytest.mark.asyncio
    async def test_handle_error_fallback_failure(self, error_gateway):
        """Test error fallback when fallback also fails"""
        request = GatewayRequest(prompt="Test", user_id="user123")

        # Mock fallback failure
        error_gateway._select_fallback_model = AsyncMock(
            side_effect=Exception("Fallback failed")
        )

        result = await error_gateway._handle_error_fallback(
            request, "req123", "Original error"
        )

        assert result is None  # Should return None when fallback fails

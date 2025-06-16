"""
Test suite for LLM Orchestration Gateway - Critical coverage improvement
"""

import json
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import HTTPException

from core.llm_orchestration.gateway import (
    GatewayRequest,
    GatewayResponse,
    LLMGateway,
)
from core.llm_orchestration.config_manager import (
    ModelConfiguration,
    ModelPriority,
)


class TestLLMGateway:
    """Test suite for LLM Gateway functionality - addressing 25% coverage gap"""

    @pytest.fixture
    def mock_gateway(self):
        """Create LLM Gateway instance with mocked dependencies"""
        with patch('core.llm_orchestration.gateway.BudgetManager') as mock_budget, \
             patch('core.llm_orchestration.gateway.CircuitBreaker') as mock_breaker, \
             patch('core.llm_orchestration.gateway.AnalyticsCollector') as mock_analytics:

            mock_budget.return_value.check_budget.return_value = True
            mock_budget.return_value.update_usage = AsyncMock()
            mock_breaker.return_value.is_available.return_value = True
            mock_analytics.return_value.record_request = AsyncMock()

            gateway = LLMGateway()
            return gateway

    @pytest.fixture
    def sample_request(self):
        """Sample gateway request"""
        return GatewayRequest(
            prompt="What is the best workout for beginners?",
            user_id="test-user-123",
            model_preference="gpt-3.5-turbo",
            max_tokens=150,
            temperature=0.7,
            context="fitness_coaching"
        )

    @pytest.fixture
    def sample_model_config(self):
        """Sample model configuration"""
        return ModelConfiguration(
            model_name="gpt-3.5-turbo",
            provider="openai",
            priority=ModelPriority.HIGH,
            max_tokens=4000,
            cost_per_token=0.000002,
            rate_limit_rpm=3000,
            enabled=True
        )

    @pytest.mark.asyncio
    async def test_successful_request_processing(self, mock_gateway, sample_request, sample_model_config):
        """Test successful request processing through gateway"""
        # Mock adapter response
        mock_response = GatewayResponse(
            content="Here's a beginner workout plan...",
            model_used="gpt-3.5-turbo",
            provider="openai",
            tokens_used=75,
            cost_estimate=0.00015,
            latency_ms=250,
            cached=False,
            user_id="test-user-123",
            metadata={"context": "fitness_coaching"}
        )

        with patch.object(mock_gateway, '_select_provider', return_value="openai"), \
             patch.object(mock_gateway, '_get_adapter') as mock_adapter_method:

            mock_adapter = MagicMock()
            mock_adapter.process_request = AsyncMock(return_value=mock_response)
            mock_adapter_method.return_value = mock_adapter

            result = await mock_gateway.process_request(sample_request)

            assert result.content == "Here's a beginner workout plan..."
            assert result.model_used == "gpt-3.5-turbo"
            assert result.user_id == "test-user-123"
            assert result.tokens_used == 75

    @pytest.mark.asyncio
    async def test_budget_exceeded_handling(self, mock_gateway, sample_request):
        """Test handling when user budget is exceeded"""
        with patch.object(mock_gateway, 'budget_manager') as mock_budget:
            mock_budget.check_budget.return_value = False
            mock_budget.get_remaining_budget.return_value = 0.0

            with pytest.raises(HTTPException) as exc_info:
                await mock_gateway.process_request(sample_request)

            assert exc_info.value.status_code == 429
            assert "budget exceeded" in str(exc_info.value.detail).lower()

    @pytest.mark.asyncio
    async def test_circuit_breaker_open(self, mock_gateway, sample_request):
        """Test handling when circuit breaker is open"""
        with patch.object(mock_gateway, 'circuit_breaker') as mock_breaker:
            mock_breaker.is_available.return_value = False

            with pytest.raises(HTTPException) as exc_info:
                await mock_gateway.process_request(sample_request)

            assert exc_info.value.status_code == 503
            assert "service unavailable" in str(exc_info.value.detail).lower()

    @pytest.mark.asyncio
    async def test_provider_failover(self, mock_gateway, sample_request):
        """Test provider failover when primary provider fails"""
        with patch.object(mock_gateway, '_select_provider', return_value="openai"), \
             patch.object(mock_gateway, '_get_adapter') as mock_adapter_method:

            # First adapter fails
            failing_adapter = MagicMock()
            failing_adapter.process_request = AsyncMock(side_effect=Exception("OpenAI API Error"))

            # Backup adapter succeeds
            backup_adapter = MagicMock()
            backup_response = GatewayResponse(
                content="Backup response",
                model_used="gemini-pro",
                provider="gemini",
                tokens_used=50,
                cost_estimate=0.0001,
                latency_ms=300,
                cached=False,
                user_id="test-user-123"
            )
            backup_adapter.process_request = AsyncMock(return_value=backup_response)

            # Mock adapter selection to return failing then backup
            mock_adapter_method.side_effect = [failing_adapter, backup_adapter]

            with patch.object(mock_gateway, '_get_fallback_providers', return_value=["gemini"]):
                result = await mock_gateway.process_request(sample_request)

                assert result.content == "Backup response"
                assert result.provider == "gemini"

    def test_model_configuration_validation(self, sample_model_config):
        """Test model configuration validation"""
        # Valid config
        assert sample_model_config.model_name == "gpt-3.5-turbo"
        assert sample_model_config.enabled is True
        assert sample_model_config.priority == ModelPriority.HIGH

        # Test invalid config
        with pytest.raises(ValueError):
            ModelConfiguration(
                model_name="",  # Empty model name
                provider="openai",
                priority=ModelPriority.HIGH,
                max_tokens=4000,
                cost_per_token=0.000002,
                rate_limit_rpm=3000,
                enabled=True
            )

    @pytest.mark.asyncio
    async def test_rate_limiting(self, mock_gateway, sample_request):
        """Test rate limiting functionality"""
        with patch.object(mock_gateway, '_check_rate_limit', return_value=False):
            with pytest.raises(HTTPException) as exc_info:
                await mock_gateway.process_request(sample_request)

            assert exc_info.value.status_code == 429
            assert "rate limit" in str(exc_info.value.detail).lower()

    @pytest.mark.asyncio
    async def test_cache_hit(self, mock_gateway, sample_request):
        """Test cache hit scenario"""
        cached_response = GatewayResponse(
            content="Cached workout response",
            model_used="gpt-3.5-turbo",
            provider="openai",
            tokens_used=0,  # No tokens used for cached response
            cost_estimate=0.0,
            latency_ms=5,
            cached=True,
            user_id="test-user-123"
        )

        with patch.object(mock_gateway, 'cache_manager') as mock_cache:
            mock_cache.get.return_value = cached_response

            result = await mock_gateway.process_request(sample_request)

            assert result.cached is True
            assert result.tokens_used == 0
            assert result.latency_ms < 50  # Cache should be fast

    def test_request_validation(self):
        """Test request validation"""
        # Valid request
        valid_request = GatewayRequest(
            prompt="Test prompt",
            user_id="user123",
            model_preference="gpt-3.5-turbo"
        )
        assert valid_request.prompt == "Test prompt"

        # Invalid request - empty prompt
        with pytest.raises(ValueError):
            GatewayRequest(
                prompt="",
                user_id="user123",
                model_preference="gpt-3.5-turbo"
            )

        # Invalid request - missing user_id
        with pytest.raises(ValueError):
            GatewayRequest(
                prompt="Test prompt",
                user_id="",
                model_preference="gpt-3.5-turbo"
            )

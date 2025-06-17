"""
Test fixtures and utilities for LLM orchestration testing
"""

from datetime import datetime
from typing import Any, Dict
from unittest.mock import AsyncMock, MagicMock

import pytest

from core.llm_orchestration.adapters import LLMProvider, LLMRequest, LLMResponse
from core.llm_orchestration.config_manager import AdminConfigManager, ModelConfiguration
from core.llm_orchestration.gateway import GatewayRequest, GatewayResponse
from core.llm_orchestration.key_vault import (
    KeyVaultClientService,
    KeyVaultProvider,
    SecretReference,
)


@pytest.fixture
def sample_gateway_request():
    """Standard gateway request for testing"""
    return GatewayRequest(
        prompt="What is the capital of France?",
        user_id="test-user-123",
        task_type="question_answering",
        user_tier="standard",
        max_tokens=100,
        temperature=0.7,
        stream=False,
        metadata={"test": True},
    )


@pytest.fixture
def sample_llm_request():
    """Standard LLM request for testing"""
    return LLMRequest(
        prompt="What is the capital of France?",
        user_id="test-user-123",
        task_type="question_answering",
        max_tokens=100,
        temperature=0.7,
        stream=False,
        context={"user_tier": "standard"},
        metadata={"test": True},
    )


@pytest.fixture
def sample_llm_response():
    """Standard LLM response for testing"""
    return LLMResponse(
        content="Paris is the capital of France.",
        model_used="gpt-3.5-turbo",
        provider="openai",
        tokens_used=12,
        cost_estimate=0.00024,
        latency_ms=150,
        request_id="req-123",
        user_id="test-user-123",
        cached=False,
    )


@pytest.fixture
def sample_gateway_response():
    """Standard gateway response for testing"""
    return GatewayResponse(
        content="Paris is the capital of France.",
        model_used="gpt-3.5-turbo",
        provider="openai",
        request_id="req-123",
        tokens_used=12,
        cost_estimate=0.00024,
        latency_ms=150,
        cached=False,
        user_id="test-user-123",
        metadata={"test": True},
    )


@pytest.fixture
def mock_config_manager():
    """Mock AdminConfigManager for testing"""
    config_manager = MagicMock(spec=AdminConfigManager)

    # Sample model configuration
    model_config = ModelConfiguration(
        model_id="gpt-3.5-turbo",
        provider="openai",
        model_name="gpt-3.5-turbo",
        api_key_secret_ref=SecretReference(
            provider=KeyVaultProvider.LOCAL_ENV, secret_identifier="OPENAI_API_KEY"
        ),
        priority=1,
        is_active=True,
    )

    config_manager.get_active_models.return_value = [model_config]
    config_manager.load_configurations = AsyncMock()
    config_manager.get_matching_routing_rules.return_value = []

    return config_manager


@pytest.fixture
def mock_key_vault_service():
    """Mock KeyVaultClientService for testing"""
    key_vault = MagicMock(spec=KeyVaultClientService)
    key_vault.get_secret = AsyncMock(return_value="mock-api-key")
    return key_vault


@pytest.fixture
def mock_llm_adapter():
    """Mock LLM adapter for testing"""
    adapter = AsyncMock()
    adapter.model_id = "gpt-3.5-turbo"
    adapter.provider = LLMProvider.OPENAI
    adapter.is_healthy.return_value = True
    adapter.generate_response = AsyncMock(
        return_value=LLMResponse(
            content="Paris is the capital of France.",
            model_used="gpt-3.5-turbo",
            provider="openai",
            tokens_used=12,
            cost_estimate=0.00024,
            latency_ms=150,
            request_id="req-123",
        )
    )
    adapter.health_check = AsyncMock(return_value=True)
    adapter.estimate_cost.return_value = 0.00024
    return adapter


@pytest.fixture
def test_user():
    """Test user profile"""
    return {
        "id": 1,
        "username": "testuser",
        "email": "test@example.com",
        "tier": "standard",
        "is_admin": False,
    }


@pytest.fixture
def test_admin_user():
    """Test admin user profile"""
    return {
        "id": 2,
        "username": "admin",
        "email": "admin@example.com",
        "tier": "admin",
        "is_admin": True,
    }


@pytest.fixture
def mock_database_session():
    """Mock database session for testing"""
    session = MagicMock()
    session.commit = MagicMock()
    session.rollback = MagicMock()
    session.close = MagicMock()
    return session


@pytest.fixture
def mock_budget_manager():
    """Mock budget manager for testing"""
    budget_manager = AsyncMock()
    budget_manager.initialize = AsyncMock()
    budget_manager.check_budget = AsyncMock(return_value=True)
    budget_manager.record_usage = AsyncMock()
    budget_manager.get_remaining_budget = AsyncMock(return_value=100.0)
    return budget_manager


@pytest.fixture
def mock_cache_manager():
    """Mock cache manager for testing"""
    cache_manager = AsyncMock()
    cache_manager.initialize = AsyncMock()
    cache_manager.get = AsyncMock(return_value=None)  # No cache hit by default
    cache_manager.set = AsyncMock()
    return cache_manager


@pytest.fixture
def mock_circuit_breaker():
    """Mock circuit breaker for testing"""
    circuit_breaker = AsyncMock()
    circuit_breaker.initialize = AsyncMock()
    circuit_breaker.can_proceed.return_value = True
    circuit_breaker.record_success = MagicMock()
    circuit_breaker.record_failure = MagicMock()
    circuit_breaker.add_model = MagicMock()
    return circuit_breaker


@pytest.fixture
def mock_routing_engine():
    """Mock routing engine for testing"""
    routing_engine = AsyncMock()
    routing_engine.select_model = AsyncMock(return_value="gpt-3.5-turbo")
    return routing_engine


@pytest.fixture
def mock_usage_logger():
    """Mock usage logger for testing"""
    usage_logger = AsyncMock()
    usage_logger.log_request = AsyncMock()
    usage_logger.log_response = AsyncMock()
    return usage_logger


@pytest.fixture
def mock_analytics():
    """Mock analytics collector for testing"""
    analytics = AsyncMock()
    analytics.record_request = AsyncMock()
    analytics.record_response = AsyncMock()
    analytics.record_error = AsyncMock()
    return analytics


class MockLLMGateway:
    """Mock LLM Gateway for integration testing"""

    def __init__(self):
        self.is_initialized = True
        self.adapters = {"gpt-3.5-turbo": AsyncMock()}

    async def process_request(self, request: GatewayRequest) -> GatewayResponse:
        """Mock process request"""
        return GatewayResponse(
            content="Mocked response",
            model_used="gpt-3.5-turbo",
            provider="openai",
            request_id="mock-req-123",
            tokens_used=10,
            cost_estimate=0.0002,
            latency_ms=100,
            cached=False,
            user_id=request.user_id,
            metadata=request.metadata,
        )

    async def get_provider_status(self) -> Dict[str, Any]:
        """Mock provider status"""
        return {
            "total_models": 1,
            "healthy_models": 1,
            "adapters": {
                "gpt-3.5-turbo": {
                    "status": "healthy",
                    "last_check": datetime.utcnow().isoformat(),
                }
            },
        }


@pytest.fixture
def mock_gateway():
    """Mock LLM Gateway fixture"""
    return MockLLMGateway()

"""
Comprehensive test suite for LLM Gateway functionality
"""

import json
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from core.llm_orchestration.adapters import LLMProvider, LLMRequest, LLMResponse
from core.llm_orchestration.config_manager import ModelConfiguration
from core.llm_orchestration.gateway import GatewayRequest, GatewayResponse, LLMGateway
from core.llm_orchestration.key_vault import KeyVaultProvider, SecretReference


class TestLLMGateway:
    """Test suite for LLM Gateway core functionality"""

    @pytest.fixture
    def gateway(self, mock_config_manager, mock_key_vault_service):
        """Create LLM Gateway instance with mocked dependencies"""
        gateway = LLMGateway(
            config_manager=mock_config_manager, key_vault_service=mock_key_vault_service
        )
        return gateway

    @pytest.fixture
    def sample_request(self):
        """Sample gateway request for testing"""
        return GatewayRequest(
            user_id="test-user-123",
            prompt="What is the capital of France?",
            task_type="question_answering",
            user_tier="standard",
            max_tokens=100,
            temperature=0.7,
            stream=False,
            metadata={"test": True},
        )

    @pytest.mark.asyncio
    async def test_gateway_initialization(self, gateway):
        """Test gateway initializes properly"""
        assert gateway is not None
        assert hasattr(gateway, "_config_manager")
        assert hasattr(gateway, "_key_vault_service")

    @pytest.mark.asyncio
    async def test_gateway_initialization_with_adapters(
        self, gateway, mock_config_manager
    ):
        """Test gateway initialization loads adapters"""
        # Setup mock configuration
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
        mock_config_manager.get_active_models.return_value = [model_config]

        await gateway.initialize()

        # Verify initialization was called
        mock_config_manager.load_configurations.assert_called_once()
        assert gateway._is_initialized

    @pytest.mark.asyncio
    async def test_process_request_success(
        self, gateway, sample_request, mock_llm_adapter
    ):
        """Test successful request processing"""
        # Setup gateway with adapter
        gateway._adapters = {"gpt-3.5-turbo": mock_llm_adapter}
        gateway._routing_engine = MagicMock()
        gateway._routing_engine.select_model.return_value = "gpt-3.5-turbo"
        gateway._budget_enforcer = MagicMock()
        gateway._budget_enforcer.check_budget.return_value = True
        gateway._request_validator = MagicMock()
        gateway._request_validator.validate.return_value = True
        gateway._response_recorder = MagicMock()
        gateway._is_initialized = True

        # Mock adapter response
        expected_response = LLMResponse(
            content="Paris is the capital of France.",
            model_used="gpt-3.5-turbo",
            provider="openai",
            tokens_used=12,
            cost_estimate=0.00024,
            latency_ms=150,
            request_id="req-123",
        )
        mock_llm_adapter.generate_response.return_value = expected_response

        # Process request
        response = await gateway.process_request(sample_request)

        # Verify response
        assert isinstance(response, GatewayResponse)
        assert response.content == "Paris is the capital of France."
        assert response.model_used == "gpt-3.5-turbo"
        assert response.user_id == sample_request.user_id
        assert response.tokens_used == 12

        # Verify methods were called
        gateway._routing_engine.select_model.assert_called_once()
        gateway._budget_enforcer.check_budget.assert_called_once()
        mock_llm_adapter.generate_response.assert_called_once()

    @pytest.mark.asyncio
    async def test_process_request_budget_exceeded(self, gateway, sample_request):
        """Test request processing when budget is exceeded"""
        gateway._routing_engine = MagicMock()
        gateway._budget_enforcer = MagicMock()
        gateway._budget_enforcer.check_budget.return_value = False
        gateway._request_validator = MagicMock()
        gateway._request_validator.validate.return_value = True
        gateway._is_initialized = True

        with pytest.raises(Exception) as exc_info:
            await gateway.process_request(sample_request)

        assert "budget" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_process_request_validation_failure(self, gateway, sample_request):
        """Test request processing when validation fails"""
        gateway._request_validator = MagicMock()
        gateway._request_validator.validate.side_effect = ValueError("Invalid request")
        gateway._is_initialized = True

        with pytest.raises(ValueError) as exc_info:
            await gateway.process_request(sample_request)

        assert "Invalid request" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_process_request_no_available_models(self, gateway, sample_request):
        """Test request processing when no models are available"""
        gateway._routing_engine = MagicMock()
        gateway._routing_engine.select_model.return_value = None
        gateway._budget_enforcer = MagicMock()
        gateway._budget_enforcer.check_budget.return_value = True
        gateway._request_validator = MagicMock()
        gateway._request_validator.validate.return_value = True
        gateway._is_initialized = True

        with pytest.raises(Exception) as exc_info:
            await gateway.process_request(sample_request)

        assert "model" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_get_provider_status(self, gateway, mock_llm_adapter):
        """Test provider status retrieval"""
        gateway._adapters = {
            "gpt-3.5-turbo": mock_llm_adapter,
            "gpt-4": mock_llm_adapter,
        }
        mock_llm_adapter.is_healthy.return_value = True
        gateway._is_initialized = True

        status = await gateway.get_provider_status()

        assert "total_models" in status
        assert "healthy_models" in status
        assert "adapters" in status
        assert status["total_models"] == 2
        assert status["healthy_models"] == 2

    @pytest.mark.asyncio
    async def test_get_provider_status_unhealthy_adapter(self, gateway):
        """Test provider status with unhealthy adapter"""
        unhealthy_adapter = AsyncMock()
        unhealthy_adapter.is_healthy.return_value = False
        unhealthy_adapter.model_id = "broken-model"

        gateway._adapters = {"broken-model": unhealthy_adapter}
        gateway._is_initialized = True

        status = await gateway.get_provider_status()

        assert status["total_models"] == 1
        assert status["healthy_models"] == 0

    @pytest.mark.asyncio
    async def test_gateway_not_initialized_error(self, gateway, sample_request):
        """Test that uninitialized gateway raises appropriate error"""
        gateway._is_initialized = False

        with pytest.raises(Exception) as exc_info:
            await gateway.process_request(sample_request)

        assert "initialize" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_stream_request_processing(self, gateway, mock_llm_adapter):
        """Test streaming request processing"""
        # Create streaming request
        stream_request = GatewayRequest(
            user_id="test-user-123",
            prompt="Tell me a story",
            task_type="text_generation",
            user_tier="premium",
            max_tokens=500,
            temperature=0.8,
            stream=True,
            metadata={"stream": True},
        )

        # Setup gateway
        gateway._adapters = {"gpt-3.5-turbo": mock_llm_adapter}
        gateway._routing_engine = MagicMock()
        gateway._routing_engine.select_model.return_value = "gpt-3.5-turbo"
        gateway._budget_enforcer = MagicMock()
        gateway._budget_enforcer.check_budget.return_value = True
        gateway._request_validator = MagicMock()
        gateway._request_validator.validate.return_value = True
        gateway._response_recorder = MagicMock()
        gateway._is_initialized = True

        # Mock streaming response
        async def mock_stream():
            yield {"content": "Once upon a time", "done": False}
            yield {"content": " there was a brave knight", "done": False}
            yield {"content": ".", "done": True}

        mock_llm_adapter.generate_response.return_value = mock_stream()

        # Test streaming (this would be implementation specific)
        # For now, we test that the adapter is called correctly
        response = await gateway.process_request(stream_request)

        # Verify response is returned and adapter was called with streaming enabled
        assert response is not None
        mock_llm_adapter.generate_response.assert_called_once()
        call_args = mock_llm_adapter.generate_response.call_args[0][0]
        assert call_args.stream is True

    @pytest.mark.asyncio
    async def test_error_handling_and_recovery(
        self, gateway, sample_request, mock_llm_adapter
    ):
        """Test error handling and recovery mechanisms"""
        # Setup gateway
        gateway._adapters = {"gpt-3.5-turbo": mock_llm_adapter}
        gateway._routing_engine = MagicMock()
        gateway._routing_engine.select_model.return_value = "gpt-3.5-turbo"
        gateway._budget_enforcer = MagicMock()
        gateway._budget_enforcer.check_budget.return_value = True
        gateway._request_validator = MagicMock()
        gateway._request_validator.validate.return_value = True
        gateway._response_recorder = MagicMock()
        gateway._is_initialized = True

        # Mock adapter to raise an exception
        mock_llm_adapter.generate_response.side_effect = Exception("API Error")

        with pytest.raises(Exception) as exc_info:
            await gateway.process_request(sample_request)

        assert "API Error" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_request_metadata_preservation(self, gateway, mock_llm_adapter):
        """Test that request metadata is preserved through processing"""
        request_with_metadata = GatewayRequest(
            user_id="test-user-123",
            prompt="Test prompt",
            task_type="question_answering",
            user_tier="premium",
            max_tokens=50,
            temperature=0.5,
            stream=False,
            metadata={
                "session_id": "sess-456",
                "custom_field": "custom_value",
                "timestamp": datetime.utcnow().isoformat(),
            },
        )

        # Setup gateway
        gateway._adapters = {"gpt-3.5-turbo": mock_llm_adapter}
        gateway._routing_engine = MagicMock()
        gateway._routing_engine.select_model.return_value = "gpt-3.5-turbo"
        gateway._budget_enforcer = MagicMock()
        gateway._budget_enforcer.check_budget.return_value = True
        gateway._request_validator = MagicMock()
        gateway._request_validator.validate.return_value = True
        gateway._response_recorder = MagicMock()
        gateway._is_initialized = True

        # Mock response
        mock_llm_adapter.generate_response.return_value = LLMResponse(
            content="Test response",
            model_used="gpt-3.5-turbo",
            provider="openai",
            tokens_used=5,
            cost_estimate=0.0001,
            latency_ms=100,
            request_id="req-789",
        )

        response = await gateway.process_request(request_with_metadata)

        # Verify metadata is preserved
        assert response.metadata is not None
        assert response.metadata["session_id"] == "sess-456"
        assert response.metadata["custom_field"] == "custom_value"

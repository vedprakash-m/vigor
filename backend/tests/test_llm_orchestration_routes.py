"""
Comprehensive test suite for LLM Orchestration API routes
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock, patch
import json
from datetime import datetime

from main import app
from api.schemas.admin import ModelConfigRequest, ABTestRequest
from core.llm_orchestration.gateway import GatewayResponse
from core.llm_orchestration.config_manager import ModelConfiguration
from core.llm_orchestration.key_vault import SecretReference, KeyVaultProvider


class TestLLMOrchestrationRoutes:
    """Test suite for LLM orchestration API endpoints"""

    @pytest.fixture
    def client(self):
        """FastAPI test client"""
        return TestClient(app)

    @pytest.fixture
    def auth_headers(self):
        """Mock authentication headers"""
        return {"Authorization": "Bearer test-token"}

    @pytest.fixture
    def admin_headers(self):
        """Mock admin authentication headers"""
        return {"Authorization": "Bearer admin-token"}

    @pytest.fixture
    def mock_gateway_response(self):
        """Mock gateway response"""
        return GatewayResponse(
            content="This is a test response from the LLM.",
            model_used="gpt-3.5-turbo",
            provider="openai",
            tokens_used=15,
            cost_estimate=0.0003,
            latency_ms=250,
            cached=False,
            user_id="test-user-123",
            metadata={"test": True}
        )

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.llm_gateway')
    def test_chat_completion_success(self, mock_gateway, mock_get_user, client, auth_headers, mock_gateway_response):
        """Test successful chat completion request"""
        # Setup mocks
        mock_get_user.return_value = {"id": "test-user-123", "tier": "standard"}
        mock_gateway.process_request = AsyncMock(return_value=mock_gateway_response)

        # Test request
        response = client.post(
            "/api/llm/chat/completions",
            json={
                "prompt": "What is artificial intelligence?",
                "max_tokens": 100,
                "temperature": 0.7,
                "task_type": "question_answering"
            },
            headers=auth_headers
        )

        # Verify response
        assert response.status_code == 200
        data = response.json()
        assert data["content"] == "This is a test response from the LLM."
        assert data["model_used"] == "gpt-3.5-turbo"
        assert data["tokens_used"] == 15
        assert "cost_estimate" in data
        assert "latency_ms" in data

    @patch('api.routes.llm_orchestration.get_current_user')
    def test_chat_completion_unauthorized(self, mock_get_user, client):
        """Test chat completion without authentication"""
        response = client.post(
            "/api/llm/chat/completions",
            json={
                "prompt": "Test prompt",
                "max_tokens": 50
            }
        )

        assert response.status_code == 401

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.llm_gateway')
    def test_chat_completion_invalid_request(self, mock_gateway, mock_get_user, client, auth_headers):
        """Test chat completion with invalid request data"""
        mock_get_user.return_value = {"id": "test-user-123", "tier": "standard"}

        # Missing required prompt field
        response = client.post(
            "/api/llm/chat/completions",
            json={
                "max_tokens": 100
            },
            headers=auth_headers
        )

        assert response.status_code == 422  # Validation error

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.llm_gateway')
    def test_chat_completion_gateway_error(self, mock_gateway, mock_get_user, client, auth_headers):
        """Test chat completion when gateway raises an error"""
        mock_get_user.return_value = {"id": "test-user-123", "tier": "standard"}
        mock_gateway.process_request = AsyncMock(side_effect=Exception("Gateway error"))

        response = client.post(
            "/api/llm/chat/completions",
            json={
                "prompt": "Test prompt",
                "max_tokens": 50
            },
            headers=auth_headers
        )

        assert response.status_code == 500

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.llm_gateway')
    def test_streaming_chat_completion(self, mock_gateway, mock_get_user, client, auth_headers):
        """Test streaming chat completion"""
        mock_get_user.return_value = {"id": "test-user-123", "tier": "premium"}

        # Mock streaming response
        async def mock_stream():
            yield {"content": "Hello", "done": False}
            yield {"content": " world", "done": False}
            yield {"content": "!", "done": True}

        mock_gateway.process_request = AsyncMock(return_value=mock_stream())

        response = client.post(
            "/api/llm/chat/completions",
            json={
                "prompt": "Say hello world",
                "max_tokens": 10,
                "stream": True
            },
            headers=auth_headers
        )

        # For streaming, we might get a different status code or response format
        assert response.status_code in [200, 202]

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.llm_gateway')
    def test_provider_status_admin(self, mock_gateway, mock_get_user, client, admin_headers):
        """Test provider status endpoint for admin users"""
        mock_get_user.return_value = {"id": "admin-123", "tier": "admin", "is_admin": True}
        mock_gateway.get_provider_status = AsyncMock(return_value={
            "total_models": 3,
            "healthy_models": 2,
            "adapters": {
                "gpt-3.5-turbo": {"status": "healthy", "last_check": datetime.utcnow().isoformat()},
                "gpt-4": {"status": "healthy", "last_check": datetime.utcnow().isoformat()},
                "claude": {"status": "unhealthy", "last_check": datetime.utcnow().isoformat()}
            }
        })

        response = client.get(
            "/api/llm/providers/status",
            headers=admin_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert data["total_models"] == 3
        assert data["healthy_models"] == 2
        assert "adapters" in data

    @patch('api.routes.llm_orchestration.get_current_user')
    def test_provider_status_non_admin(self, mock_get_user, client, auth_headers):
        """Test provider status endpoint for non-admin users"""
        mock_get_user.return_value = {"id": "user-123", "tier": "standard", "is_admin": False}

        response = client.get(
            "/api/llm/providers/status",
            headers=auth_headers
        )

        assert response.status_code == 403  # Forbidden

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.admin_config_manager')
    def test_model_configuration_create(self, mock_config_manager, mock_get_user, client, admin_headers):
        """Test creating a new model configuration"""
        mock_get_user.return_value = {"id": "admin-123", "tier": "admin", "is_admin": True}
        mock_config_manager.add_model_configuration = AsyncMock(return_value=True)

        config_data = {
            "model_id": "new-model",
            "provider": "openai",
            "model_name": "gpt-4-turbo",
            "api_key_secret_ref": {
                "provider": "LOCAL_ENV",
                "secret_identifier": "OPENAI_API_KEY"
            },
            "priority": 2,
            "is_active": True,
            "cost_per_token": 0.00001
        }

        response = client.post(
            "/api/llm/models/configure",
            json=config_data,
            headers=admin_headers
        )

        assert response.status_code == 201
        mock_config_manager.add_model_configuration.assert_called_once()

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.admin_config_manager')
    def test_model_configuration_list(self, mock_config_manager, mock_get_user, client, admin_headers):
        """Test listing model configurations"""
        mock_get_user.return_value = {"id": "admin-123", "tier": "admin", "is_admin": True}

        mock_configs = [
            ModelConfiguration(
                model_id="gpt-3.5-turbo",
                provider="openai",
                model_name="gpt-3.5-turbo",
                api_key_secret_ref=SecretReference(
                    provider=KeyVaultProvider.LOCAL_ENV,
                    secret_identifier="OPENAI_API_KEY"
                ),
                priority=1,
                is_active=True
            ),
            ModelConfiguration(
                model_id="gpt-4",
                provider="openai",
                model_name="gpt-4",
                api_key_secret_ref=SecretReference(
                    provider=KeyVaultProvider.LOCAL_ENV,
                    secret_identifier="OPENAI_API_KEY"
                ),
                priority=2,
                is_active=False
            )
        ]

        mock_config_manager.get_active_models = AsyncMock(return_value=mock_configs)

        response = client.get(
            "/api/llm/models",
            headers=admin_headers
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["model_id"] == "gpt-3.5-turbo"
        assert data[1]["model_id"] == "gpt-4"

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.admin_config_manager')
    def test_model_configuration_update(self, mock_config_manager, mock_get_user, client, admin_headers):
        """Test updating a model configuration"""
        mock_get_user.return_value = {"id": "admin-123", "tier": "admin", "is_admin": True}
        mock_config_manager.update_model_configuration = AsyncMock(return_value=True)

        update_data = {
            "priority": 3,
            "is_active": False
        }

        response = client.put(
            "/api/llm/models/gpt-3.5-turbo",
            json=update_data,
            headers=admin_headers
        )

        assert response.status_code == 200
        mock_config_manager.update_model_configuration.assert_called_once()

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.admin_config_manager')
    def test_model_configuration_delete(self, mock_config_manager, mock_get_user, client, admin_headers):
        """Test deleting a model configuration"""
        mock_get_user.return_value = {"id": "admin-123", "tier": "admin", "is_admin": True}
        mock_config_manager.remove_model_configuration = AsyncMock(return_value=True)

        response = client.delete(
            "/api/llm/models/old-model",
            headers=admin_headers
        )

        assert response.status_code == 204
        mock_config_manager.remove_model_configuration.assert_called_once_with("old-model")

    @patch('api.routes.llm_orchestration.get_current_user')
    def test_usage_analytics_admin(self, mock_get_user, client, admin_headers):
        """Test usage analytics endpoint for admin users"""
        mock_get_user.return_value = {"id": "admin-123", "tier": "admin", "is_admin": True}

        with patch('api.routes.llm_orchestration.usage_analytics') as mock_analytics:
            mock_analytics.get_usage_summary = AsyncMock(return_value={
                "total_requests": 1500,
                "total_tokens": 50000,
                "total_cost": 12.50,
                "average_latency": 180,
                "success_rate": 0.95
            })

            response = client.get(
                "/api/llm/analytics/usage",
                headers=admin_headers
            )

            assert response.status_code == 200
            data = response.json()
            assert data["total_requests"] == 1500
            assert data["success_rate"] == 0.95

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.llm_gateway')
    def test_ab_test_configuration(self, mock_gateway, mock_get_user, client, admin_headers):
        """Test A/B test configuration endpoint"""
        mock_get_user.return_value = {"id": "admin-123", "tier": "admin", "is_admin": True}

        ab_test_data = {
            "test_name": "model_comparison",
            "model_variants": ["gpt-3.5-turbo", "gpt-4"],
            "traffic_split": [0.7, 0.3],
            "success_metrics": ["latency", "user_satisfaction"],
            "duration_days": 7
        }

        with patch('api.routes.llm_orchestration.ab_test_manager') as mock_ab_manager:
            mock_ab_manager.create_test = AsyncMock(return_value={"test_id": "test-123"})

            response = client.post(
                "/api/llm/ab-tests",
                json=ab_test_data,
                headers=admin_headers
            )

            assert response.status_code == 201
            data = response.json()
            assert "test_id" in data

    @patch('api.routes.llm_orchestration.get_current_user')
    def test_rate_limiting(self, mock_get_user, client, auth_headers):
        """Test rate limiting for standard users"""
        mock_get_user.return_value = {"id": "user-123", "tier": "standard"}

        # This would depend on your rate limiting implementation
        # For now, we test that the endpoint is accessible
        response = client.post(
            "/api/llm/chat/completions",
            json={
                "prompt": "Test rate limiting",
                "max_tokens": 10
            },
            headers=auth_headers
        )

        # The actual response depends on rate limiting implementation
        # This is more of a placeholder for future rate limiting tests
        assert response.status_code in [200, 429]  # 429 = Too Many Requests

    @patch('api.routes.llm_orchestration.get_current_user')
    @patch('api.routes.llm_orchestration.llm_gateway')
    def test_request_validation_edge_cases(self, mock_gateway, mock_get_user, client, auth_headers):
        """Test request validation with edge cases"""
        mock_get_user.return_value = {"id": "user-123", "tier": "standard"}

        # Test with extremely long prompt
        long_prompt = "A" * 10000
        response = client.post(
            "/api/llm/chat/completions",
            json={
                "prompt": long_prompt,
                "max_tokens": 100
            },
            headers=auth_headers
        )

        # Should handle validation appropriately
        assert response.status_code in [400, 422]

        # Test with negative max_tokens
        response = client.post(
            "/api/llm/chat/completions",
            json={
                "prompt": "Test prompt",
                "max_tokens": -1
            },
            headers=auth_headers
        )

        assert response.status_code == 422

        # Test with invalid temperature
        response = client.post(
            "/api/llm/chat/completions",
            json={
                "prompt": "Test prompt",
                "max_tokens": 50,
                "temperature": 5.0  # Should be 0-2
            },
            headers=auth_headers
        )

        assert response.status_code == 422

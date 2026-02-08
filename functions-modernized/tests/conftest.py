"""
Shared test fixtures for the functions-modernized test suite.
"""

import json
import os
from unittest.mock import AsyncMock, MagicMock, patch

import azure.functions as func
import pytest


# ============================================================================
# Environment setup — prevent real Azure connections during tests
# ============================================================================


@pytest.fixture(autouse=True)
def mock_env_vars(monkeypatch):
    """Set minimal environment variables so Settings/config don't fail."""
    monkeypatch.setenv("COSMOS_DB_ENDPOINT", "https://test-cosmos.documents.azure.com:443/")
    monkeypatch.setenv("COSMOS_DB_KEY", "dGVzdC1rZXk=")  # base64 "test-key"
    monkeypatch.setenv("COSMOS_DB_DATABASE", "vigor-test")
    monkeypatch.setenv("AZURE_OPENAI_ENDPOINT", "https://test-openai.openai.azure.com/")
    monkeypatch.setenv("AZURE_OPENAI_API_KEY", "test-openai-key")
    monkeypatch.setenv("AZURE_AD_TENANT_ID", "test-tenant-id")
    monkeypatch.setenv("AZURE_AD_CLIENT_ID", "test-client-id")
    monkeypatch.setenv("JWT_SECRET_KEY", "test-jwt-secret-key-for-testing-only")
    monkeypatch.setenv("ENVIRONMENT", "test")


# ============================================================================
# HTTP request helpers
# ============================================================================


def make_http_request(
    method: str = "GET",
    url: str = "https://vigor-functions.azurewebsites.net/api/test",
    body: dict | None = None,
    headers: dict | None = None,
    params: dict | None = None,
    route_params: dict | None = None,
) -> func.HttpRequest:
    """Create a mock Azure Functions HttpRequest."""
    return func.HttpRequest(
        method=method,
        url=url,
        headers=headers or {},
        params=params or {},
        route_params=route_params or {},
        body=json.dumps(body).encode("utf-8") if body else b"",
    )


@pytest.fixture
def http_request_factory():
    """Fixture that returns the make_http_request helper."""
    return make_http_request


# ============================================================================
# Mock Cosmos DB client
# ============================================================================


@pytest.fixture
def mock_cosmos_client():
    """Create a mock CosmosDBClient for testing endpoints without real DB."""
    client = AsyncMock()
    client.get_user = AsyncMock(return_value=None)
    client.upsert_user = AsyncMock()
    client.get_workouts = AsyncMock(return_value=[])
    client.get_workout = AsyncMock(return_value=None)
    client.upsert_workout = AsyncMock()
    client.query_items = AsyncMock(return_value=[])
    return client


# ============================================================================
# Mock auth decorator
# ============================================================================


@pytest.fixture
def mock_user_claims():
    """Standard user claims from a decoded JWT."""
    return {
        "oid": "test-user-id-12345",
        "preferred_username": "testuser@example.com",
        "name": "Test User",
        "tid": "test-tenant-id",
        "sub": "test-subject",
    }

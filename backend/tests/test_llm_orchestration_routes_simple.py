"""
Simplified test suite for LLM Orchestration API routes
"""

import json
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from api.schemas.admin import BudgetSettingsUpdate, AdminSettingsUpdate
from main import app


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

    def test_budget_settings_schema(self):
        """Test budget settings schema"""
        budget_data = {
            "total_weekly_budget": 100.0,
            "total_monthly_budget": 400.0,
            "alert_threshold_percentage": 80.0
        }

        budget_settings = BudgetSettingsUpdate(**budget_data)
        assert budget_settings.total_weekly_budget == budget_data["total_weekly_budget"]

    def test_admin_settings_schema(self):
        """Test admin settings schema"""
        admin_data = {
            "enabled": True
        }

        admin_settings = AdminSettingsUpdate(**admin_data)
        assert admin_settings.enabled == admin_data["enabled"]

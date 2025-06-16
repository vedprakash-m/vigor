"""
Test suite for Budget Manager - Critical coverage improvement
"""

from datetime import datetime, timedelta
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from core.llm_orchestration.budget_manager import (
    BudgetManager,
    BudgetExceededException,
    UserBudget,
    UsageRecord,
)


class TestBudgetManager:
    """Test suite for Budget Manager functionality - addressing 25% coverage gap"""

    @pytest.fixture
    def mock_budget_manager(self):
        """Create Budget Manager with mocked dependencies"""
        with patch('core.llm_orchestration.budget_manager.get_db') as mock_db:
            mock_session = MagicMock()
            mock_db.return_value.__enter__.return_value = mock_session

            budget_manager = BudgetManager()
            return budget_manager, mock_session

    @pytest.fixture
    def sample_user_budget(self):
        """Sample user budget configuration"""
        return UserBudget(
            user_id="test-user-123",
            monthly_limit=Decimal("50.00"),
            weekly_limit=Decimal("15.00"),
            daily_limit=Decimal("5.00"),
            current_month_usage=Decimal("25.00"),
            current_week_usage=Decimal("8.00"),
            current_day_usage=Decimal("2.50"),
            last_reset_date=datetime.utcnow().date()
        )

    @pytest.fixture
    def sample_usage_record(self):
        """Sample usage record"""
        return UsageRecord(
            user_id="test-user-123",
            cost=Decimal("0.15"),
            tokens_used=75,
            model_used="gpt-3.5-turbo",
            provider="openai",
            timestamp=datetime.utcnow(),
            request_type="chat_completion"
        )

    def test_check_budget_within_limits(self, mock_budget_manager, sample_user_budget):
        """Test budget check when user is within all limits"""
        budget_manager, mock_session = mock_budget_manager

        # Mock database query to return user budget
        mock_session.query.return_value.filter.return_value.first.return_value = sample_user_budget

        # Test with small cost that should be allowed
        result = budget_manager.check_budget("test-user-123", Decimal("1.00"))

        assert result is True

    def test_check_budget_exceeds_daily_limit(self, mock_budget_manager, sample_user_budget):
        """Test budget check when daily limit would be exceeded"""
        budget_manager, mock_session = mock_budget_manager

        # Set high daily usage
        sample_user_budget.current_day_usage = Decimal("4.50")
        sample_user_budget.daily_limit = Decimal("5.00")

        mock_session.query.return_value.filter.return_value.first.return_value = sample_user_budget

        # Test with cost that would exceed daily limit
        result = budget_manager.check_budget("test-user-123", Decimal("1.00"))

        assert result is False

    def test_check_budget_exceeds_monthly_limit(self, mock_budget_manager, sample_user_budget):
        """Test budget check when monthly limit would be exceeded"""
        budget_manager, mock_session = mock_budget_manager

        # Set high monthly usage
        sample_user_budget.current_month_usage = Decimal("49.50")
        sample_user_budget.monthly_limit = Decimal("50.00")

        mock_session.query.return_value.filter.return_value.first.return_value = sample_user_budget

        # Test with cost that would exceed monthly limit
        result = budget_manager.check_budget("test-user-123", Decimal("1.00"))

        assert result is False

    def test_update_usage_success(self, mock_budget_manager, sample_user_budget, sample_usage_record):
        """Test successful usage update"""
        budget_manager, mock_session = mock_budget_manager

        mock_session.query.return_value.filter.return_value.first.return_value = sample_user_budget

        # Update usage
        budget_manager.update_usage(sample_usage_record)

        # Verify session commit was called
        mock_session.commit.assert_called_once()

    def test_get_remaining_budget(self, mock_budget_manager, sample_user_budget):
        """Test getting remaining budget for user"""
        budget_manager, mock_session = mock_budget_manager

        mock_session.query.return_value.filter.return_value.first.return_value = sample_user_budget

        remaining = budget_manager.get_remaining_budget("test-user-123")

        # Monthly limit (50) - current usage (25) = 25
        assert remaining == Decimal("25.00")

    def test_get_remaining_budget_new_user(self, mock_budget_manager):
        """Test getting remaining budget for new user (no existing budget)"""
        budget_manager, mock_session = mock_budget_manager

        # Mock no existing budget found
        mock_session.query.return_value.filter.return_value.first.return_value = None

        with patch.object(budget_manager, '_create_default_budget') as mock_create:
            mock_create.return_value = UserBudget(
                user_id="new-user",
                monthly_limit=Decimal("50.00"),
                weekly_limit=Decimal("15.00"),
                daily_limit=Decimal("5.00"),
                current_month_usage=Decimal("0.00"),
                current_week_usage=Decimal("0.00"),
                current_day_usage=Decimal("0.00"),
                last_reset_date=datetime.utcnow().date()
            )

            remaining = budget_manager.get_remaining_budget("new-user")
            assert remaining == Decimal("50.00")

    def test_budget_reset_daily(self, mock_budget_manager, sample_user_budget):
        """Test daily budget reset functionality"""
        budget_manager, mock_session = mock_budget_manager

        # Set last reset to yesterday
        sample_user_budget.last_reset_date = (datetime.utcnow() - timedelta(days=1)).date()
        sample_user_budget.current_day_usage = Decimal("5.00")

        mock_session.query.return_value.filter.return_value.first.return_value = sample_user_budget

        with patch.object(budget_manager, '_reset_daily_usage') as mock_reset:
            budget_manager.check_budget("test-user-123", Decimal("1.00"))
            mock_reset.assert_called_once()

    def test_budget_reset_weekly(self, mock_budget_manager, sample_user_budget):
        """Test weekly budget reset functionality"""
        budget_manager, mock_session = mock_budget_manager

        # Set last reset to last week
        sample_user_budget.last_reset_date = (datetime.utcnow() - timedelta(days=8)).date()
        sample_user_budget.current_week_usage = Decimal("15.00")

        mock_session.query.return_value.filter.return_value.first.return_value = sample_user_budget

        with patch.object(budget_manager, '_reset_weekly_usage') as mock_reset:
            budget_manager.check_budget("test-user-123", Decimal("1.00"))
            mock_reset.assert_called_once()

    def test_budget_reset_monthly(self, mock_budget_manager, sample_user_budget):
        """Test monthly budget reset functionality"""
        budget_manager, mock_session = mock_budget_manager

        # Set last reset to last month
        sample_user_budget.last_reset_date = (datetime.utcnow() - timedelta(days=32)).date()
        sample_user_budget.current_month_usage = Decimal("50.00")

        mock_session.query.return_value.filter.return_value.first.return_value = sample_user_budget

        with patch.object(budget_manager, '_reset_monthly_usage') as mock_reset:
            budget_manager.check_budget("test-user-123", Decimal("1.00"))
            mock_reset.assert_called_once()

    def test_budget_enforcement_exception(self, mock_budget_manager, sample_user_budget):
        """Test budget enforcement raises exception when configured"""
        budget_manager, mock_session = mock_budget_manager

        # Configure strict enforcement
        budget_manager.strict_enforcement = True

        # Set usage to exceed limit
        sample_user_budget.current_day_usage = Decimal("5.00")
        sample_user_budget.daily_limit = Decimal("5.00")

        mock_session.query.return_value.filter.return_value.first.return_value = sample_user_budget

        with pytest.raises(BudgetExceededException) as exc_info:
            budget_manager.enforce_budget("test-user-123", Decimal("1.00"))

        assert "daily budget" in str(exc_info.value).lower()

    def test_usage_analytics_tracking(self, mock_budget_manager, sample_usage_record):
        """Test that usage is properly tracked for analytics"""
        budget_manager, mock_session = mock_budget_manager

        with patch.object(budget_manager, 'analytics_collector') as mock_analytics:
            budget_manager.record_usage_analytics(sample_usage_record)

            mock_analytics.record_usage.assert_called_once_with(sample_usage_record)

    def test_cost_calculation_accuracy(self, mock_budget_manager):
        """Test accurate cost calculation for different models"""
        budget_manager, mock_session = mock_budget_manager

        # Test GPT-3.5 cost calculation
        gpt35_cost = budget_manager.calculate_cost("gpt-3.5-turbo", 1000)
        assert gpt35_cost > 0

        # Test GPT-4 cost calculation (should be higher)
        gpt4_cost = budget_manager.calculate_cost("gpt-4", 1000)
        assert gpt4_cost > gpt35_cost

    def test_tier_based_limits(self, mock_budget_manager):
        """Test different budget limits based on user tier"""
        budget_manager, mock_session = mock_budget_manager

        # Test free tier limits
        free_budget = budget_manager.get_tier_budget_limits("free")
        assert free_budget.monthly_limit <= Decimal("10.00")

        # Test premium tier limits
        premium_budget = budget_manager.get_tier_budget_limits("premium")
        assert premium_budget.monthly_limit > free_budget.monthly_limit

import logging
import time
from datetime import datetime, timedelta

from sqlalchemy import func
from sqlalchemy.orm import Session

from database.connection import get_db
from database.sql_models import AIProviderPriorityDB, AIUsageLogDB, BudgetSettingsDB

from typing import Optional

from .config import get_settings
from .llm_providers import (
    FallbackProvider,
    GeminiProvider,
    OpenAIProvider,
    PerplexityProvider,
)

logger = logging.getLogger(__name__)
settings = get_settings()


# Custom Exceptions
class BudgetExceededException(Exception):
    """Raised when budget limits are exceeded."""

    pass


class ProviderUnavailableException(Exception):
    """Raised when no providers are available."""

    pass


class CostCalculator:
    """Calculate costs for different LLM providers."""

    COST_PER_1M_TOKENS = {
        "openai": {
            "gpt-3.5-turbo": {"input": 0.50, "output": 1.50},
            "gpt-4o": {"input": 2.50, "output": 10.00},
            "gpt-4o-mini": {"input": 0.15, "output": 0.60},
            "gpt-4": {"input": 10.00, "output": 30.00},
            "gpt-4-turbo": {"input": 10.00, "output": 30.00},
        },
        "gemini": {
            "gemini-2.5-flash": {"input": 0.075, "output": 0.30},
            "gemini-2.5-pro": {"input": 1.25, "output": 5.00},
        },
        "perplexity": {
            "llama-3.1-sonar-small-128k-online": {"input": 0.20, "output": 0.20},
            "llama-3.1-sonar-large-128k-online": {"input": 1.00, "output": 1.00},
        },
    }

    @classmethod
    def calculate_cost(
        cls, provider: str, model: str, input_tokens: int, output_tokens: int
    ) -> float:
        """Calculate cost in USD for a request."""
        try:
            rates = cls.COST_PER_1M_TOKENS.get(provider, {}).get(
                model, {"input": 0, "output": 0}
            )
            input_cost = (input_tokens / 1_000_000) * rates["input"]
            output_cost = (output_tokens / 1_000_000) * rates["output"]
            return round(input_cost + output_cost, 6)
        except Exception:
            return 0.0


class BudgetMonitor:
    """Monitor and enforce budget limits."""

    def __init__(self, db: Session):
        self.db = db

    def get_current_budget(self) -> Optional[BudgetSettingsDB]:
        """Get current budget settings."""
        return self.db.query(BudgetSettingsDB).first()

    def get_weekly_spending(self) -> float:
        """Get total spending for current week."""
        week_start = datetime.now() - timedelta(days=7)
        result = (
            self.db.query(func.sum(AIUsageLogDB.cost))
            .filter(
                AIUsageLogDB.created_at >= week_start, AIUsageLogDB.success.is_(True)
            )
            .scalar()
        )
        return result or 0.0

    def get_monthly_spending(self) -> float:
        """Get total spending for current month."""
        month_start = datetime.now() - timedelta(days=30)
        result = (
            self.db.query(func.sum(AIUsageLogDB.cost))
            .filter(
                AIUsageLogDB.created_at >= month_start, AIUsageLogDB.success.is_(True)
            )
            .scalar()
        )
        return result or 0.0

    def get_provider_daily_spending(self, provider: str) -> float:
        """Get daily spending for specific provider."""
        day_start = datetime.now() - timedelta(days=1)
        result = (
            self.db.query(func.sum(AIUsageLogDB.cost))
            .filter(
                AIUsageLogDB.provider_name == provider,
                AIUsageLogDB.created_at >= day_start,
                AIUsageLogDB.success.is_(True),
            )
            .scalar()
        )
        return result or 0.0

    def check_budget_limits(
        self, provider: str, estimated_cost: float
    ) -> tuple[bool, str]:
        """Check if request would exceed budget limits."""
        budget = self.get_current_budget()
        if not budget:
            return True, ""

        # Check weekly budget
        weekly_spending = self.get_weekly_spending()
        if weekly_spending + estimated_cost > budget.total_weekly_budget:
            return (
                False,
                f"Weekly budget exceeded: ${weekly_spending:.4f} + ${estimated_cost:.4f} > ${budget.total_weekly_budget:.2f}",
            )

        # Check monthly budget
        monthly_spending = self.get_monthly_spending()
        if monthly_spending + estimated_cost > budget.total_monthly_budget:
            return (
                False,
                f"Monthly budget exceeded: ${monthly_spending:.4f} + ${estimated_cost:.4f} > ${budget.total_monthly_budget:.2f}",
            )

        # Check provider-specific daily limits
        provider_priorities = (
            self.db.query(AIProviderPriorityDB)
            .filter(
                AIProviderPriorityDB.provider_name == provider,
                AIProviderPriorityDB.is_enabled.is_(True),
            )
            .first()
        )

        if provider_priorities and provider_priorities.max_daily_cost:
            daily_spending = self.get_provider_daily_spending(provider)
            if daily_spending + estimated_cost > provider_priorities.max_daily_cost:
                return (
                    False,
                    f"Provider daily budget exceeded: ${daily_spending:.4f} + ${estimated_cost:.4f} > ${provider_priorities.max_daily_cost:.2f}",
                )

        return True, ""


class AdminLLMManager:
    """Admin-managed LLM system with priority-based selection and budget monitoring."""

    def __init__(self, db: Session):
        self.db = db
        self.budget_monitor = BudgetMonitor(db)
        self.providers = {
            "openai": OpenAIProvider(),
            "gemini": GeminiProvider(),
            "perplexity": PerplexityProvider(),
            "fallback": FallbackProvider(),
        }

    def get_provider_priorities(self) -> list[AIProviderPriorityDB]:
        """Get enabled providers ordered by priority."""
        return (
            self.db.query(AIProviderPriorityDB)
            .filter(AIProviderPriorityDB.is_enabled.is_(True))
            .order_by(AIProviderPriorityDB.priority)
            .all()
        )

    def estimate_tokens(self, text: str) -> int:
        """Rough estimate of tokens (1 token ≈ 4 characters)."""
        return max(1, len(text) // 4)

    def estimate_cost(
        self,
        provider_name: str,
        model_name: str,
        input_text: str,
        estimated_output_tokens: int = 500,
    ) -> float:
        """Estimate cost for a request."""
        input_tokens = self.estimate_tokens(input_text)
        return CostCalculator.calculate_cost(
            provider_name, model_name, input_tokens, estimated_output_tokens
        )

    def log_usage(
        self,
        provider_name: str,
        model_name: str,
        user_id: Optional[str],
        endpoint: str,
        input_tokens: int,
        output_tokens: int,
        cost: float,
        response_time_ms: int,
        success: bool,
        error_message: Optional[str] = None,
    ):
        """Log AI usage for analytics and billing."""
        log_entry = AIUsageLogDB(
            provider_name=provider_name,
            model_name=model_name,
            user_id=user_id,
            endpoint=endpoint,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            cost=cost,
            response_time_ms=response_time_ms,
            success=success,
            error_message=error_message,
        )

        self.db.add(log_entry)
        try:
            self.db.commit()
        except Exception as e:
            logger.error(f"Failed to log usage: {e}")
            self.db.rollback()

    async def chat_completion(
        self,
        messages: list[dict[str, str]],
        system_prompt: Optional[str] = None,
        max_tokens: int = 500,
        temperature: float = 0.7,
        json_response: bool = False,
        user_id: Optional[str] = None,
        endpoint: str = "chat",
    ) -> tuple[str, float, str]:
        """
        Get chat completion with automatic provider fallback and budget monitoring.

        Returns (response, cost, provider_used)
        """
        priorities = self.get_provider_priorities()
        if not priorities:
            # Fallback to default provider
            provider = self.providers.get("fallback")
            if provider:
                response = await provider.chat_completion(
                    messages=messages,
                    system_prompt=system_prompt,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    json_response=json_response,
                )
                return response, 0.0, "fallback"
            raise ProviderUnavailableException("No providers available")

        # Prepare input text for cost estimation
        input_text = ""
        if system_prompt:
            input_text += system_prompt + " "
        for msg in messages:
            input_text += msg.get("content", "") + " "

        for priority_setting in priorities:
            provider_name = str(priority_setting.provider_name)  # Convert Column to str
            model_name = str(priority_setting.model_name)  # Convert Column to str

            # Check if provider is available
            provider = self.providers.get(provider_name)
            if not provider or not provider.is_available():
                continue

            # Estimate cost
            estimated_cost = self.estimate_cost(
                provider_name, model_name, input_text, max_tokens
            )

            # Check budget limits
            can_afford, budget_error = self.budget_monitor.check_budget_limits(
                provider_name, estimated_cost
            )
            if not can_afford:
                logger.warning(
                    f"Budget limit reached for {provider_name}: {budget_error}"
                )
                continue

            # Try to get response
            try:
                start_time = time.time()
                response = await provider.chat_completion(
                    messages=messages,
                    system_prompt=system_prompt,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    json_response=json_response,
                )
                end_time = time.time()

                # Calculate actual metrics
                input_tokens = self.estimate_tokens(input_text)
                output_tokens = self.estimate_tokens(response)
                actual_cost = CostCalculator.calculate_cost(
                    provider_name, model_name, input_tokens, output_tokens
                )
                response_time_ms = int((end_time - start_time) * 1000)

                # Log successful usage
                self.log_usage(
                    provider_name=provider_name,
                    model_name=model_name,
                    user_id=user_id,
                    endpoint=endpoint,
                    input_tokens=input_tokens,
                    output_tokens=output_tokens,
                    cost=actual_cost,
                    response_time_ms=response_time_ms,
                    success=True,
                )

                return response, actual_cost, f"{provider_name}:{model_name}"

            except Exception as e:
                # Log failed attempt
                self.log_usage(
                    provider_name=provider_name,
                    model_name=model_name,
                    user_id=user_id,
                    endpoint=endpoint,
                    input_tokens=0,
                    output_tokens=0,
                    cost=0,
                    response_time_ms=0,
                    success=False,
                    error_message=str(e),
                )
                logger.error(f"Provider {provider_name} failed: {e}")
                continue

        # If all providers failed, raise exception
        raise ProviderUnavailableException(
            "All configured providers failed or exceeded budget"
        )


def get_admin_llm_manager(db: Optional[Session] = None) -> AdminLLMManager:
    """Get admin LLM manager instance."""
    if db is None:
        db = next(get_db())
    return AdminLLMManager(db)

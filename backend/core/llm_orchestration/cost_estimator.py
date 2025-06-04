"""
Cost Estimator
Advanced cost estimation and optimization for LLM usage
"""

import logging
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


@dataclass
class CostBreakdown:
    """Detailed cost breakdown"""

    input_tokens: int
    output_tokens: int
    input_cost: float
    output_cost: float
    total_cost: float
    model_name: str
    provider: str


class CostEstimator:
    """
    Advanced cost estimation for LLM usage
    Provides detailed cost breakdowns and optimization recommendations
    """

    # Updated pricing data (as of 2025)
    MODEL_PRICING = {
        "gpt-4": {"input": 0.03, "output": 0.06, "provider": "openai"},
        "gpt-3.5-turbo": {"input": 0.001, "output": 0.002, "provider": "openai"},
        "claude-3-opus": {"input": 0.015, "output": 0.075, "provider": "anthropic"},
        "claude-3-sonnet": {"input": 0.003, "output": 0.015, "provider": "anthropic"},
        "claude-3-haiku": {
            "input": 0.00025,
            "output": 0.00125,
            "provider": "anthropic",
        },
        "gemini-pro": {"input": 0.0005, "output": 0.0015, "provider": "google"},
        "gemini-ultra": {"input": 0.001, "output": 0.002, "provider": "google"},
        "perplexity-sonar": {"input": 0.001, "output": 0.002, "provider": "perplexity"},
    }

    def estimate_detailed_cost(
        self, model_name: str, input_tokens: int, output_tokens: int
    ) -> CostBreakdown:
        """
        Get detailed cost breakdown for a request

        Args:
            model_name: Name of the model
            input_tokens: Number of input tokens
            output_tokens: Number of output tokens

        Returns:
            Detailed cost breakdown
        """
        try:
            # Find pricing for model
            pricing = self._get_model_pricing(model_name)

            # Calculate costs
            input_cost = (input_tokens / 1000) * pricing["input"]
            output_cost = (output_tokens / 1000) * pricing["output"]
            total_cost = input_cost + output_cost

            return CostBreakdown(
                input_tokens=input_tokens,
                output_tokens=output_tokens,
                input_cost=input_cost,
                output_cost=output_cost,
                total_cost=total_cost,
                model_name=model_name,
                provider=pricing["provider"],
            )

        except Exception as e:
            logger.warning(f"Cost estimation failed for {model_name}: {e}")
            return self._default_cost_breakdown(model_name, input_tokens, output_tokens)

    def _get_model_pricing(self, model_name: str) -> Dict[str, Any]:
        """Get pricing for a model"""
        # Try exact match first
        if model_name in self.MODEL_PRICING:
            return self.MODEL_PRICING[model_name]

        # Try partial match
        for model_key, pricing in self.MODEL_PRICING.items():
            if model_key.lower() in model_name.lower():
                return pricing

        # Default pricing
        return {"input": 0.001, "output": 0.002, "provider": "unknown"}

    def _default_cost_breakdown(
        self, model_name: str, input_tokens: int, output_tokens: int
    ) -> CostBreakdown:
        """Default cost breakdown when estimation fails"""
        default_input_cost = 0.001
        default_output_cost = 0.002

        input_cost = (input_tokens / 1000) * default_input_cost
        output_cost = (output_tokens / 1000) * default_output_cost

        return CostBreakdown(
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            input_cost=input_cost,
            output_cost=output_cost,
            total_cost=input_cost + output_cost,
            model_name=model_name,
            provider="unknown",
        )

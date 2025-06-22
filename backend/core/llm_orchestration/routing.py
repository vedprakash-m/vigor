"""
Routing Strategy Engine
Implements intelligent model selection based on various strategies
"""

import hashlib
import logging
import secrets
from typing import Any

from .config_manager import AdminConfigManager

logger = logging.getLogger(__name__)


class RoutingStrategyEngine:
    """
    Intelligent routing engine for model selection
    Supports priority-based routing, A/B testing, and context-aware selection
    """

    def __init__(self, config_manager: AdminConfigManager):
        self.config_manager = config_manager

    async def select_model(
        self, context: dict[str, Any], available_models: list[str]
    ) -> str:
        """
        Select the best model based on context and available models

        Args:
            context: Request context (user_tier, task_type, etc.)
            available_models: List of available model IDs

        Returns:
            Selected model ID
        """
        try:
            # 1. Check for A/B test assignment
            ab_test_model = await self._check_ab_tests(context, available_models)
            if ab_test_model:
                logger.debug(f"A/B test selected model: {ab_test_model}")
                return ab_test_model

            # 2. Apply custom routing rules
            rule_based_model = await self._apply_routing_rules(
                context, available_models
            )
            if rule_based_model:
                logger.debug(f"Routing rule selected model: {rule_based_model}")
                return rule_based_model

            # 3. Priority-based selection with user tier consideration
            priority_model = await self._priority_based_selection(
                context, available_models
            )
            if priority_model:
                logger.debug(f"Priority-based selected model: {priority_model}")
                return priority_model

            # 4. Fallback to first available model
            if available_models:
                logger.debug(f"Fallback selected model: {available_models[0]}")
                return available_models[0]

            raise Exception("No models available for selection")

        except Exception as e:
            logger.error(f"Model selection failed: {e}")
            raise

    async def _check_ab_tests(
        self, context: dict[str, Any], available_models: list[str]
    ) -> str | None:
        """Check if user should be assigned to an A/B test variant"""
        try:
            active_tests = self.config_manager.get_active_ab_tests()

            for test in active_tests:
                # Check if any test model variants are available
                test_models = []
                for variant_models in test.model_variants.values():
                    test_models.extend(variant_models)

                if not any(model in available_models for model in test_models):
                    continue

                # Determine user's variant assignment
                variant = self._get_ab_test_variant(
                    context.get("user_id", "anonymous"),
                    test.test_id,
                    test.traffic_split,
                )

                if variant and variant in test.model_variants:
                    variant_models = test.model_variants[variant]
                    # Return first available model from variant
                    for model in variant_models:
                        if model in available_models:
                            return model

            return None

        except Exception as e:
            logger.warning(f"A/B test check failed: {e}")
            return None

    def _get_ab_test_variant(
        self, user_id: str, test_id: str, traffic_split: dict[str, float]
    ) -> str | None:
        """Determine which A/B test variant a user should see"""
        try:
            # Create consistent hash for user+test combination
            hash_input = f"{user_id}:{test_id}"
            hash_value = int(
                hashlib.md5(hash_input.encode(), usedforsecurity=False).hexdigest(), 16
            )
            user_percentage = (hash_value % 100) / 100.0

            # Assign to variant based on traffic split
            cumulative_split = 0.0
            for variant, split_percentage in traffic_split.items():
                cumulative_split += split_percentage
                if user_percentage <= cumulative_split:
                    return variant

            return None

        except Exception as e:
            logger.warning(f"A/B test variant assignment failed: {e}")
            return None

    async def _apply_routing_rules(
        self, context: dict[str, Any], available_models: list[str]
    ) -> str | None:
        """Apply custom routing rules"""
        try:
            matching_rules = self.config_manager.get_matching_routing_rules(context)

            for rule in matching_rules:
                # Check if any target models are available
                for model_id in rule.target_models:
                    if model_id in available_models:
                        logger.info(f"Applied routing rule '{rule.name}' -> {model_id}")
                        return model_id

            return None

        except Exception as e:
            logger.warning(f"Routing rules application failed: {e}")
            return None

    async def _priority_based_selection(
        self, context: dict[str, Any], available_models: list[str]
    ) -> str | None:
        """Select model based on priority and user tier"""
        try:
            # Get user tier configuration
            user_tier = context.get("user_tier")
            tier_config = None
            if user_tier:
                tier_config = self.config_manager.get_user_tier(user_tier)

            # Filter models based on user access
            accessible_models = available_models
            if tier_config and tier_config.model_access:
                accessible_models = [
                    model
                    for model in available_models
                    if model in tier_config.model_access
                ]

            if not accessible_models:
                return None

            # Get model configurations and sort by priority
            model_configs = []
            for model_id in accessible_models:
                config = self.config_manager.models.get(model_id)
                if config and config.is_active:
                    effective_priority = config.priority.value

                    # Apply tier priority boost
                    if tier_config and tier_config.priority_boost:
                        effective_priority -= tier_config.priority_boost

                    model_configs.append((model_id, effective_priority, config))

            if not model_configs:
                return None

            # Sort by effective priority (lower value = higher priority)
            model_configs.sort(key=lambda x: x[1])

            # Return highest priority model
            return model_configs[0][0]

        except Exception as e:
            logger.warning(f"Priority-based selection failed: {e}")
            return None


class LoadBalancingStrategy:
    """Load balancing strategies for model selection"""

    @staticmethod
    def round_robin(models: list[str], request_count: int) -> str:
        """Round-robin selection"""
        if not models:
            raise ValueError("No models available")
        return models[request_count % len(models)]

    @staticmethod
    def weighted_random(model_weights: dict[str, float]) -> str:
        """Weighted random selection"""
        if not model_weights:
            raise ValueError("No models with weights")

        total_weight = sum(model_weights.values())
        random_value = secrets.SystemRandom().uniform(0, total_weight)

        cumulative_weight = 0.0
        for model, weight in model_weights.items():
            cumulative_weight += weight
            if random_value <= cumulative_weight:
                return model

        # Fallback to first model
        return list(model_weights.keys())[0]

    @staticmethod
    def least_latency(model_latencies: dict[str, float]) -> str:
        """Select model with lowest latency"""
        if not model_latencies:
            raise ValueError("No models with latency data")

        return min(model_latencies.items(), key=lambda x: x[1])[0]

    @staticmethod
    def cost_optimized(model_costs: dict[str, float]) -> str:
        """Select model with lowest cost"""
        if not model_costs:
            raise ValueError("No models with cost data")

        return min(model_costs.items(), key=lambda x: x[1])[0]


class ContextAwareRouter:
    """Context-aware routing for specific use cases"""

    def __init__(self, config_manager: AdminConfigManager):
        self.config_manager = config_manager

    def route_by_task_type(
        self, task_type: str, available_models: list[str]
    ) -> str | None:
        """Route based on task type (coding, chat, analysis, etc.)"""

        # Task-specific model preferences
        task_preferences = {
            "coding": ["gpt-4", "claude-3-sonnet", "gemini-pro"],
            "chat": ["gpt-3.5-turbo", "gemini-pro", "perplexity"],
            "analysis": ["gpt-4", "claude-3-opus", "gemini-pro"],
            "creative": ["gpt-4", "claude-3-sonnet", "gemini-pro"],
            "factual": ["perplexity", "gemini-pro", "gpt-4"],
        }

        preferred_models = task_preferences.get(task_type, [])

        # Find first available preferred model
        for model in preferred_models:
            if model in available_models:
                return model

        return None

    def route_by_complexity(
        self, prompt_length: int, available_models: list[str]
    ) -> str | None:
        """Route based on prompt complexity/length"""

        if prompt_length < 100:
            # Simple queries - use efficient models
            preferred = ["gpt-3.5-turbo", "gemini-pro"]
        elif prompt_length < 1000:
            # Medium complexity
            preferred = ["gpt-4", "claude-3-sonnet", "gemini-pro"]
        else:
            # Complex queries - use most capable models
            preferred = ["gpt-4", "claude-3-opus", "gemini-ultra"]

        for model in preferred:
            if model in available_models:
                return model

        return None

    def route_by_user_preference(
        self, user_id: str, available_models: list[str]
    ) -> str | None:
        """Route based on user's historical preferences"""

        # In a real implementation, this would query user preference data
        # For now, return None to use default routing
        return None


# Factory for creating routing strategies
class RoutingStrategyFactory:
    """Factory for creating different routing strategies"""

    @staticmethod
    def create_strategy(strategy_type: str, config_manager: AdminConfigManager):
        """Create a routing strategy instance"""

        if strategy_type == "priority_based":
            return RoutingStrategyEngine(config_manager)
        elif strategy_type == "context_aware":
            return ContextAwareRouter(config_manager)
        else:
            raise ValueError(f"Unknown routing strategy: {strategy_type}")


# Utility functions for routing
def calculate_model_score(
    model_config: Any,  # ModelConfiguration
    context: dict[str, Any],
    current_metrics: dict[str, float],
) -> float:
    """
    Calculate a score for model selection based on multiple factors

    Args:
        model_config: Model configuration
        context: Request context
        current_metrics: Current performance metrics

    Returns:
        Model score (higher is better)
    """
    try:
        score = 0.0

        # Priority score (higher priority = higher score)
        priority_value = getattr(model_config.priority, "value", 3)  # default priority
        priority_score = (6 - priority_value) * 20.0  # 20-100 range
        score += priority_score

        # Cost efficiency score (lower cost = higher score)
        cost_per_token = getattr(model_config, "cost_per_token", 0.001)
        if cost_per_token > 0:
            cost_score = max(0.0, 50.0 - (cost_per_token * 100000))
            score += cost_score

        # Performance score based on current metrics
        model_id = getattr(model_config, "model_id", "unknown")
        latency = current_metrics.get(f"{model_id}_latency", 1000.0)
        latency_score = max(
            0.0, 50.0 - (latency / 20.0)
        )  # Lower latency = higher score
        score += latency_score

        # Availability score
        error_rate = current_metrics.get(f"{model_id}_error_rate", 0.0)
        availability_score = max(0.0, 50.0 - (error_rate * 500.0))
        score += availability_score

        return score

    except Exception as e:
        logger.warning(f"Error calculating model score: {e}")
        return 0.0

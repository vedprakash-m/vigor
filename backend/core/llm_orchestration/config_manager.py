"""
Admin Configuration Manager
Handles enterprise-grade configuration management for LLM orchestration
"""

import logging
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

from .key_vault import SecretReference

logger = logging.getLogger(__name__)


class ModelPriority(Enum):
    """Model selection priority levels"""

    HIGHEST = 1
    HIGH = 2
    MEDIUM = 3
    LOW = 4
    FALLBACK = 5


class BudgetResetPeriod(Enum):
    """Budget reset period options"""

    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    QUARTERLY = "quarterly"


@dataclass
class ModelConfiguration:
    """Configuration for individual LLM models"""

    model_id: str
    provider: str
    model_name: str
    api_key_secret_ref: SecretReference  # Reference to Key Vault secret
    is_active: bool = True
    priority: ModelPriority = ModelPriority.MEDIUM
    cost_per_token: float = 0.0001  # Default cost estimate
    max_tokens: int = 4096
    temperature: float = 0.7
    context_window: int = 8192
    supports_streaming: bool = True
    rate_limit_rpm: int = 60  # Requests per minute
    circuit_breaker_threshold: int = 5
    circuit_breaker_timeout: int = 60
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class RoutingRule:
    """Dynamic routing rule configuration"""

    rule_id: str
    name: str
    conditions: Dict[str, Any]  # e.g., {"task_type": "coding", "user_tier": "premium"}
    target_models: List[str]  # Model IDs in priority order
    weight: float = 1.0
    is_active: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)


@dataclass
class ABTestConfiguration:
    """A/B testing configuration"""

    test_id: str
    name: str
    description: str
    is_active: bool
    start_date: datetime
    end_date: datetime
    traffic_split: Dict[str, float]  # {"variant_a": 0.5, "variant_b": 0.5}
    model_variants: Dict[
        str, List[str]
    ]  # {"variant_a": ["gpt-4"], "variant_b": ["gemini-pro"]}
    success_metrics: List[str]
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class BudgetConfiguration:
    """Budget management configuration"""

    budget_id: str
    name: str
    total_budget: float
    reset_period: BudgetResetPeriod
    alert_thresholds: List[float]  # [0.5, 0.8, 0.95] for 50%, 80%, 95% alerts
    auto_disable_at_limit: bool = True
    rollover_unused: bool = False
    user_groups: List[str] = field(default_factory=list)  # Empty = global budget
    created_at: datetime = field(default_factory=datetime.utcnow)


@dataclass
class CachingConfiguration:
    """Response caching configuration"""

    enabled: bool = True
    default_ttl: int = 3600  # 1 hour
    max_cache_size: int = 10000
    cache_strategies: Dict[str, Dict[str, Any]] = field(default_factory=dict)
    # e.g., {"task_type": {"coding": {"ttl": 7200}, "chat": {"ttl": 1800}}}


@dataclass
class RateLimitConfiguration:
    """Rate limiting configuration"""

    global_rate_limit: int = 1000  # Requests per minute globally
    per_user_rate_limit: int = 60  # Requests per minute per user
    per_model_rate_limit: Dict[str, int] = field(default_factory=dict)
    burst_allowance: int = 10
    rate_limit_window: int = 60  # seconds


@dataclass
class UserTierConfiguration:
    """User/tenant tier configuration"""

    tier_id: str
    name: str
    model_access: List[str]  # Model IDs accessible to this tier
    priority_boost: int = 0  # Priority modifier
    budget_allocation: Optional[float] = None
    rate_limit_multiplier: float = 1.0
    custom_routing_rules: List[str] = field(default_factory=list)
    api_key_overrides: Dict[str, SecretReference] = field(default_factory=dict)
    features: List[str] = field(default_factory=list)


class AdminConfigManager:
    """
    Enterprise configuration manager for LLM orchestration
    Manages all admin-configurable aspects of the system
    """

    def __init__(self, db_session=None):
        self.db = db_session
        self._config_cache: Dict[str, Any] = {}
        self._cache_ttl = 300  # 5 minutes
        self._last_cache_update = datetime.utcnow()

        # Configuration storage
        self.models: Dict[str, ModelConfiguration] = {}
        self.routing_rules: Dict[str, RoutingRule] = {}
        self.ab_tests: Dict[str, ABTestConfiguration] = {}
        self.budgets: Dict[str, BudgetConfiguration] = {}
        self.user_tiers: Dict[str, UserTierConfiguration] = {}
        self.caching_config = CachingConfiguration()
        self.rate_limit_config = RateLimitConfiguration()

    # Model Configuration Management

    async def add_model_configuration(
        self,
        model_id: str,
        provider: str,
        model_name: str,
        api_key_secret_ref: SecretReference,
        **kwargs,
    ) -> ModelConfiguration:
        """Add a new model configuration"""
        try:
            config = ModelConfiguration(
                model_id=model_id,
                provider=provider,
                model_name=model_name,
                api_key_secret_ref=api_key_secret_ref,
                **kwargs,
            )

            self.models[model_id] = config
            await self._persist_model_config(config)

            logger.info(f"Added model configuration: {model_id}")
            return config

        except Exception as e:
            logger.error(f"Failed to add model configuration {model_id}: {e}")
            raise

    async def update_model_configuration(
        self, model_id: str, **updates
    ) -> ModelConfiguration:
        """Update an existing model configuration"""
        try:
            if model_id not in self.models:
                raise ValueError(f"Model {model_id} not found")

            config = self.models[model_id]

            # Update fields
            for field_name, value in updates.items():
                if hasattr(config, field_name):
                    setattr(config, field_name, value)

            await self._persist_model_config(config)

            logger.info(f"Updated model configuration: {model_id}")
            return config

        except Exception as e:
            logger.error(f"Failed to update model configuration {model_id}: {e}")
            raise

    async def toggle_model_activation(self, model_id: str, is_active: bool) -> bool:
        """Enable or disable a model"""
        try:
            if model_id not in self.models:
                raise ValueError(f"Model {model_id} not found")

            self.models[model_id].is_active = is_active
            await self._persist_model_config(self.models[model_id])

            status = "activated" if is_active else "deactivated"
            logger.info(f"Model {model_id} {status}")
            return True

        except Exception as e:
            logger.error(f"Failed to toggle model {model_id}: {e}")
            return False

    def get_active_models(self) -> List[ModelConfiguration]:
        """Get all active model configurations"""
        return [config for config in self.models.values() if config.is_active]

    def get_models_by_priority(
        self, priority: Optional[ModelPriority] = None
    ) -> List[ModelConfiguration]:
        """Get models filtered by priority"""
        models = self.get_active_models()
        if priority:
            models = [m for m in models if m.priority == priority]
        return sorted(models, key=lambda m: m.priority.value)

    # Routing Rules Management

    async def add_routing_rule(self, rule: RoutingRule) -> bool:
        """Add a new routing rule"""
        try:
            self.routing_rules[rule.rule_id] = rule
            await self._persist_routing_rule(rule)

            logger.info(f"Added routing rule: {rule.rule_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to add routing rule {rule.rule_id}: {e}")
            return False

    async def update_routing_rule(self, rule_id: str, **updates) -> bool:
        """Update an existing routing rule"""
        try:
            if rule_id not in self.routing_rules:
                raise ValueError(f"Routing rule {rule_id} not found")

            rule = self.routing_rules[rule_id]
            for field_name, value in updates.items():
                if hasattr(rule, field_name):
                    setattr(rule, field_name, value)

            await self._persist_routing_rule(rule)

            logger.info(f"Updated routing rule: {rule_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to update routing rule {rule_id}: {e}")
            return False

    def get_matching_routing_rules(self, context: Dict[str, Any]) -> List[RoutingRule]:
        """Get routing rules that match the given context"""
        matching_rules = []

        for rule in self.routing_rules.values():
            if not rule.is_active:
                continue

            # Check if all conditions match
            matches = True
            for condition_key, condition_value in rule.conditions.items():
                if (
                    condition_key not in context
                    or context[condition_key] != condition_value
                ):
                    matches = False
                    break

            if matches:
                matching_rules.append(rule)

        # Sort by weight (higher weight = higher priority)
        return sorted(matching_rules, key=lambda r: r.weight, reverse=True)

    # A/B Testing Management

    async def create_ab_test(self, test_config: ABTestConfiguration) -> bool:
        """Create a new A/B test"""
        try:
            self.ab_tests[test_config.test_id] = test_config
            await self._persist_ab_test(test_config)

            logger.info(f"Created A/B test: {test_config.test_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to create A/B test {test_config.test_id}: {e}")
            return False

    def get_active_ab_tests(self) -> List[ABTestConfiguration]:
        """Get all active A/B tests"""
        now = datetime.utcnow()
        return [
            test
            for test in self.ab_tests.values()
            if test.is_active and test.start_date <= now <= test.end_date
        ]

    # Budget Management

    async def create_budget(self, budget_config: BudgetConfiguration) -> bool:
        """Create a new budget configuration"""
        try:
            self.budgets[budget_config.budget_id] = budget_config
            await self._persist_budget_config(budget_config)

            logger.info(f"Created budget: {budget_config.budget_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to create budget {budget_config.budget_id}: {e}")
            return False

    def get_budget_for_user_group(
        self, user_groups: List[str]
    ) -> Optional[BudgetConfiguration]:
        """Get budget configuration for specific user groups"""
        # Find most specific budget (smallest user_groups list that matches)
        matching_budgets = []

        for budget in self.budgets.values():
            if not budget.user_groups:  # Global budget
                matching_budgets.append((budget, 999))  # Lowest priority
            elif any(group in budget.user_groups for group in user_groups):
                matching_budgets.append((budget, len(budget.user_groups)))

        if matching_budgets:
            # Return budget with smallest user_groups list (most specific)
            return min(matching_budgets, key=lambda x: x[1])[0]

        return None

    # User Tier Management

    async def create_user_tier(self, tier_config: UserTierConfiguration) -> bool:
        """Create a new user tier configuration"""
        try:
            self.user_tiers[tier_config.tier_id] = tier_config
            await self._persist_user_tier(tier_config)

            logger.info(f"Created user tier: {tier_config.tier_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to create user tier {tier_config.tier_id}: {e}")
            return False

    def get_user_tier(self, tier_id: str) -> Optional[UserTierConfiguration]:
        """Get user tier configuration"""
        return self.user_tiers.get(tier_id)

    # Configuration Persistence (Database operations)

    async def _persist_model_config(self, config: ModelConfiguration):
        """Persist model configuration to database"""
        # Implementation would save to database
        pass

    async def _persist_routing_rule(self, rule: RoutingRule):
        """Persist routing rule to database"""
        # Implementation would save to database
        pass

    async def _persist_ab_test(self, test: ABTestConfiguration):
        """Persist A/B test configuration to database"""
        # Implementation would save to database
        pass

    async def _persist_budget_config(self, budget: BudgetConfiguration):
        """Persist budget configuration to database"""
        # Implementation would save to database
        pass

    async def _persist_user_tier(self, tier: UserTierConfiguration):
        """Persist user tier configuration to database"""
        # Implementation would save to database
        pass

    # Configuration Loading

    async def load_configurations(self):
        """Load all configurations from database"""
        try:
            # Implementation would load from database
            logger.info("Loaded configurations from database")
        except Exception as e:
            logger.error(f"Failed to load configurations: {e}")
            raise

    # Utility Methods

    def export_configuration(self) -> Dict[str, Any]:
        """Export current configuration for backup/migration"""
        return {
            "models": {
                k: self._serialize_model_config(v) for k, v in self.models.items()
            },
            "routing_rules": {
                k: self._serialize_routing_rule(v)
                for k, v in self.routing_rules.items()
            },
            "ab_tests": {
                k: self._serialize_ab_test(v) for k, v in self.ab_tests.items()
            },
            "budgets": {
                k: self._serialize_budget_config(v) for k, v in self.budgets.items()
            },
            "user_tiers": {
                k: self._serialize_user_tier(v) for k, v in self.user_tiers.items()
            },
            "caching_config": self._serialize_caching_config(self.caching_config),
            "rate_limit_config": self._serialize_rate_limit_config(
                self.rate_limit_config
            ),
        }

    def _serialize_model_config(self, config: ModelConfiguration) -> Dict[str, Any]:
        """Serialize model configuration for export"""
        return {
            "model_id": config.model_id,
            "provider": config.provider,
            "model_name": config.model_name,
            "api_key_secret_ref": {
                "provider": config.api_key_secret_ref.provider.value,
                "secret_identifier": config.api_key_secret_ref.secret_identifier,
                "version": config.api_key_secret_ref.version,
                "metadata": config.api_key_secret_ref.metadata,
            },
            "is_active": config.is_active,
            "priority": config.priority.value,
            "cost_per_token": config.cost_per_token,
            "max_tokens": config.max_tokens,
            "temperature": config.temperature,
            "context_window": config.context_window,
            "supports_streaming": config.supports_streaming,
            "rate_limit_rpm": config.rate_limit_rpm,
            "circuit_breaker_threshold": config.circuit_breaker_threshold,
            "circuit_breaker_timeout": config.circuit_breaker_timeout,
            "metadata": config.metadata,
        }

    def _serialize_routing_rule(self, rule: RoutingRule) -> Dict[str, Any]:
        """Serialize routing rule for export"""
        return {
            "rule_id": rule.rule_id,
            "name": rule.name,
            "conditions": rule.conditions,
            "target_models": rule.target_models,
            "weight": rule.weight,
            "is_active": rule.is_active,
            "created_at": rule.created_at.isoformat(),
        }

    def _serialize_ab_test(self, test: ABTestConfiguration) -> Dict[str, Any]:
        """Serialize A/B test for export"""
        return {
            "test_id": test.test_id,
            "name": test.name,
            "description": test.description,
            "is_active": test.is_active,
            "start_date": test.start_date.isoformat(),
            "end_date": test.end_date.isoformat(),
            "traffic_split": test.traffic_split,
            "model_variants": test.model_variants,
            "success_metrics": test.success_metrics,
            "metadata": test.metadata,
        }

    def _serialize_budget_config(self, budget: BudgetConfiguration) -> Dict[str, Any]:
        """Serialize budget configuration for export"""
        return {
            "budget_id": budget.budget_id,
            "name": budget.name,
            "total_budget": budget.total_budget,
            "reset_period": budget.reset_period.value,
            "alert_thresholds": budget.alert_thresholds,
            "auto_disable_at_limit": budget.auto_disable_at_limit,
            "rollover_unused": budget.rollover_unused,
            "user_groups": budget.user_groups,
            "created_at": budget.created_at.isoformat(),
        }

    def _serialize_user_tier(self, tier: UserTierConfiguration) -> Dict[str, Any]:
        """Serialize user tier for export"""
        return {
            "tier_id": tier.tier_id,
            "name": tier.name,
            "model_access": tier.model_access,
            "priority_boost": tier.priority_boost,
            "budget_allocation": tier.budget_allocation,
            "rate_limit_multiplier": tier.rate_limit_multiplier,
            "custom_routing_rules": tier.custom_routing_rules,
            "api_key_overrides": {
                k: {
                    "provider": v.provider.value,
                    "secret_identifier": v.secret_identifier,
                    "version": v.version,
                    "metadata": v.metadata,
                }
                for k, v in tier.api_key_overrides.items()
            },
            "features": tier.features,
        }

    def _serialize_caching_config(self, config: CachingConfiguration) -> Dict[str, Any]:
        """Serialize caching configuration for export"""
        return {
            "enabled": config.enabled,
            "default_ttl": config.default_ttl,
            "max_cache_size": config.max_cache_size,
            "cache_strategies": config.cache_strategies,
        }

    def _serialize_rate_limit_config(
        self, config: RateLimitConfiguration
    ) -> Dict[str, Any]:
        """Serialize rate limit configuration for export"""
        return {
            "global_rate_limit": config.global_rate_limit,
            "per_user_rate_limit": config.per_user_rate_limit,
            "per_model_rate_limit": config.per_model_rate_limit,
            "burst_allowance": config.burst_allowance,
            "rate_limit_window": config.rate_limit_window,
        }

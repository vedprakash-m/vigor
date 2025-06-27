"""
LLM Orchestration Layer Initialization
Sets up the enterprise LLM gateway with all required components
"""

from typing import Dict, List, Optional
import logging
import os

# New facade
from application.llm.facade import LLMGatewayFacade

# Legacy gateway fallback
from core.llm_orchestration import (
    AdminConfigManager,
    KeyVaultClientService,
    LLMGateway,  # type: ignore
)
from core.llm_orchestration.config_manager import ModelPriority
from core.llm_orchestration.key_vault import (
    KeyVaultProvider,
    SecretReference,
    initialize_key_vault_service,
)
from database.connection import SessionLocal
from core.azure_cost_management import AzureCostManagementService

logger = logging.getLogger(__name__)

# Global gateway instance
_gateway: Optional[LLMGateway] = None


async def initialize_llm_orchestration():
    """
    Initialize the complete LLM orchestration layer
    """
    global _gateway

    try:
        logger.info("Initializing LLM Orchestration Layer...")

        # 1. Initialize Key Vault service
        await initialize_key_vault_service()
        key_vault_service = KeyVaultClientService()

        # Register local client for development (if no other provider configured)
        provider = os.getenv("KEY_VAULT_PROVIDER", "local").lower()
        if provider == "local":
            from core.llm_orchestration.key_vault import (
                KeyVaultProvider,
                LocalEnvClient,
            )

            client = LocalEnvClient()
            key_vault_service.register_client(KeyVaultProvider.LOCAL_ENV, client)

        # 2. Initialize admin configuration manager
        config_manager = AdminConfigManager()

        # 3. Initialize Azure Cost Management service
        azure_cost_service = None
        try:
            azure_cost_service = AzureCostManagementService()
            logger.info("✅ Azure Cost Management service initialized")
        except Exception as e:
            logger.warning(f"Azure Cost Management service not available: {e}")

        # 4. Set up default model configurations if none exist
        await setup_default_configurations(config_manager, key_vault_service)

        # 5. Initialize gateway with all components
        db_session = SessionLocal()

        # Prefer new facade; fall back to legacy if instantiation fails
        try:
            facade = LLMGatewayFacade(
                config_manager=config_manager,
                key_vault_service=key_vault_service,
                db_session=db_session,
                azure_cost_service=azure_cost_service,
            )
            await facade.initialize()
            _gateway = facade  # type: ignore
        except Exception as e:
            logger.warning(
                f"Failed to initialize new LLMGatewayFacade, falling back to legacy. Reason: {e}"
            )
            from core.llm_orchestration import (  # local import to avoid cycle
                initialize_gateway,
            )

            _gateway = await initialize_gateway(
                config_manager=config_manager,
                key_vault_service=key_vault_service,
                db_session=db_session,
                azure_cost_service=azure_cost_service,
            )

        logger.info("✅ LLM Orchestration Layer initialized successfully")
        return _gateway

    except Exception as e:
        logger.error(f"❌ Failed to initialize LLM Orchestration Layer: {e}")
        raise


async def setup_default_configurations(
    config_manager: AdminConfigManager, key_vault_service: KeyVaultClientService
):
    """
    Set up default model configurations based on environment
    """
    try:
        logger.info("Setting up default model configurations...")

        # Determine LLM provider from environment
        llm_provider = os.getenv("LLM_PROVIDER", "fallback").lower()

        if llm_provider == "openai":
            await setup_openai_config(config_manager)
        elif llm_provider == "gemini":
            await setup_gemini_config(config_manager)
        elif llm_provider == "perplexity":
            await setup_perplexity_config(config_manager)
        else:
            # Always set up fallback
            await setup_fallback_config(config_manager)

        # Set up additional models if API keys are available
        await setup_additional_models(config_manager)

    except Exception as e:
        logger.warning(f"Failed to set up default configurations: {e}")
        # Ensure fallback is available
        await setup_fallback_config(config_manager)


async def setup_openai_config(config_manager: AdminConfigManager):
    """Set up OpenAI model configuration"""
    try:
        secret_ref = SecretReference(
            provider=KeyVaultProvider.LOCAL_ENV,
            secret_identifier="OPENAI_API_KEY",  # nosec B106
        )

        # GPT-4 (primary)
        await config_manager.add_model_configuration(
            model_id="gpt-4",
            provider="openai",
            model_name="gpt-4",
            api_key_secret_ref=secret_ref,
            priority=ModelPriority.HIGH,
            cost_per_token=0.00003,  # $0.03 per 1K tokens
            max_tokens=8192,
            temperature=0.7,
            is_active=True,
        )

        # GPT-3.5 Turbo (efficient)
        await config_manager.add_model_configuration(
            model_id="gpt-3.5-turbo",
            provider="openai",
            model_name="gpt-3.5-turbo",
            api_key_secret_ref=secret_ref,
            priority=ModelPriority.MEDIUM,
            cost_per_token=0.000001,  # $0.001 per 1K tokens
            max_tokens=4096,
            temperature=0.7,
            is_active=True,
        )

        logger.info("✅ OpenAI models configured")

    except Exception as e:
        logger.warning(f"Failed to set up OpenAI config: {e}")


async def setup_gemini_config(config_manager: AdminConfigManager):
    """Set up Google Gemini model configuration"""
    try:
        secret_ref = SecretReference(
            provider=KeyVaultProvider.LOCAL_ENV,
            secret_identifier="GEMINI_API_KEY",  # nosec B106
        )

        await config_manager.add_model_configuration(
            model_id="gemini-pro",
            provider="gemini",
            model_name="gemini-pro",
            api_key_secret_ref=secret_ref,
            priority=ModelPriority.HIGH,
            cost_per_token=0.0000005,  # $0.0005 per 1K tokens
            max_tokens=8192,
            temperature=0.7,
            is_active=True,
        )

        logger.info("✅ Gemini models configured")

    except Exception as e:
        logger.warning(f"Failed to set up Gemini config: {e}")


async def setup_perplexity_config(config_manager: AdminConfigManager):
    """Set up Perplexity model configuration"""
    try:
        secret_ref = SecretReference(
            provider=KeyVaultProvider.LOCAL_ENV,
            secret_identifier="PERPLEXITY_API_KEY",  # nosec B106
        )

        await config_manager.add_model_configuration(
            model_id="perplexity-sonar",
            provider="perplexity",
            model_name="llama-3.1-sonar-large-128k-online",
            api_key_secret_ref=secret_ref,
            priority=ModelPriority.HIGH,
            cost_per_token=0.000001,  # $0.001 per 1K tokens
            max_tokens=4096,
            temperature=0.7,
            is_active=True,
        )

        logger.info("✅ Perplexity models configured")

    except Exception as e:
        logger.warning(f"Failed to set up Perplexity config: {e}")


async def setup_fallback_config(config_manager: AdminConfigManager):
    """Set up fallback model configuration"""
    try:
        secret_ref = SecretReference(
            provider=KeyVaultProvider.LOCAL_ENV,
            secret_identifier="FALLBACK_KEY",  # nosec B106
        )

        await config_manager.add_model_configuration(
            model_id="fallback",
            provider="fallback",
            model_name="fallback",
            api_key_secret_ref=secret_ref,
            priority=ModelPriority.FALLBACK,
            cost_per_token=0.0,  # No cost for fallback
            max_tokens=1000,
            temperature=0.7,
            is_active=True,
        )

        logger.info("✅ Fallback model configured")

    except Exception as e:
        logger.error(f"Failed to set up fallback config: {e}")


async def setup_additional_models(config_manager: AdminConfigManager):
    """Set up additional models if API keys are available"""
    try:
        # Check for additional API keys and set up models
        additional_providers = {
            "OPENAI_API_KEY": ("openai", setup_openai_config),
            "GEMINI_API_KEY": ("gemini", setup_gemini_config),
            "PERPLEXITY_API_KEY": ("perplexity", setup_perplexity_config),
        }

        for env_var, (provider, setup_func) in additional_providers.items():
            if os.getenv(env_var) and os.getenv(env_var) not in [
                "sk-placeholder",
                "your-api-key-here",
            ]:
                current_provider = os.getenv("LLM_PROVIDER", "").lower()
                if provider != current_provider:  # Don't duplicate primary provider
                    await setup_func(config_manager)

    except Exception as e:
        logger.warning(f"Failed to set up additional models: {e}")


def get_llm_gateway() -> LLMGateway:
    """
    Get the initialized LLM gateway instance
    """
    if _gateway is None:
        raise RuntimeError(
            "LLM Orchestration Layer not initialized. Call initialize_llm_orchestration() first."
        )
    return _gateway


async def shutdown_llm_orchestration():
    """
    Gracefully shutdown the LLM orchestration layer
    """
    global _gateway

    if _gateway:
        await _gateway.shutdown()
        _gateway = None
        logger.info("🔽 LLM Orchestration Layer shutdown complete")

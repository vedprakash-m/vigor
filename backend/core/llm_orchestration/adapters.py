"""
LLM Service Adapters
Provides standardized interface for different LLM providers with secure API key management
"""

import asyncio
import logging
import time
from abc import ABC, abstractmethod
from collections.abc import AsyncIterator
from dataclasses import dataclass
from enum import Enum
from typing import Any, Optional

from .config_manager import ModelConfiguration
from .key_vault import KeyVaultClientService

logger = logging.getLogger(__name__)


class LLMProvider(Enum):
    """Supported LLM providers"""

    OPENAI = "openai"
    GEMINI = "gemini"
    PERPLEXITY = "perplexity"
    ANTHROPIC = "anthropic"
    FALLBACK = "fallback"


@dataclass
class LLMRequest:
    """Standardized LLM request structure"""

    prompt: str
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    task_type: Optional[str] = None
    max_tokens: Optional[int] = None
    temperature: Optional[float] = None
    stream: bool = False
    context: Optional[dict[str, Any]] = None
    metadata: Optional[dict[str, Any]] = None


@dataclass
class LLMResponse:
    """Standardized LLM response structure"""

    content: str
    model_used: str
    provider: str
    tokens_used: int
    cost_estimate: float
    latency_ms: int
    cached: bool = False
    request_id: Optional[str] = None
    metadata: Optional[dict[str, Any]] = None


@dataclass
class HealthCheckResult:
    """Health check result for LLM providers"""

    is_healthy: bool
    latency_ms: Optional[int] = None
    error_message: Optional[str] = None
    last_check: Optional[float] = None


class LLMServiceAdapter(ABC):
    """
    Abstract base class for LLM service adapters
    Provides standardized interface and secure API key management
    """

    def __init__(
        self, model_config: ModelConfiguration, key_vault_service: KeyVaultClientService
    ):
        self.model_config = model_config
        self.key_vault_service = key_vault_service
        self._api_key: Optional[str] = None
        self._key_cache_time: Optional[float] = None
        self._key_cache_ttl = 3600  # 1 hour
        self._health_status = HealthCheckResult(is_healthy=False)

    @property
    def provider(self) -> LLMProvider:
        """Get the provider type"""
        return LLMProvider(self.model_config.provider)

    @property
    def model_id(self) -> str:
        """Get the model ID"""
        return self.model_config.model_id

    async def get_api_key(self) -> str:
        """
        Securely retrieve API key from Key Vault
        Implements caching to reduce Key Vault calls
        """
        try:
            current_time = time.time()

            # Check if cached key is still valid
            if (
                self._api_key
                and self._key_cache_time
                and current_time - self._key_cache_time < self._key_cache_ttl
            ):
                return self._api_key

            # Retrieve fresh key from Key Vault
            self._api_key = await self.key_vault_service.get_secret(
                self.model_config.api_key_secret_ref
            )
            self._key_cache_time = current_time

            logger.debug(f"Retrieved API key for {self.model_id}")
            return self._api_key

        except Exception as e:
            logger.error(f"Failed to retrieve API key for {self.model_id}: {e}")
            raise

    @abstractmethod
    async def generate_response(self, request: LLMRequest) -> LLMResponse:
        """Generate a response for the given request"""
        pass

    @abstractmethod
    def generate_stream(self, request: LLMRequest) -> AsyncIterator[str]:
        """Generate a streaming response for the given request"""
        pass

    @abstractmethod
    async def health_check(self) -> HealthCheckResult:
        """Perform health check for this provider"""
        pass

    @abstractmethod
    def estimate_cost(self, prompt: str, max_tokens: int) -> float:
        """Estimate the cost for a request"""
        pass

    def is_healthy(self) -> bool:
        """Check if the provider is currently healthy"""
        return self._health_status.is_healthy

    def get_health_status(self) -> HealthCheckResult:
        """Get the current health status"""
        return self._health_status


class OpenAIAdapter(LLMServiceAdapter):
    """OpenAI API adapter with secure key management"""

    def __init__(
        self, model_config: ModelConfiguration, key_vault_service: KeyVaultClientService
    ):
        super().__init__(model_config, key_vault_service)
        self._client = None

    async def _get_client(self):
        """Get OpenAI client with fresh API key"""
        if self._client is None:
            # In production: from openai import AsyncOpenAI
            _api_key = await self.get_api_key()  # noqa: F841
            # self._client = AsyncOpenAI(api_key=_api_key)
        return self._client

    async def generate_response(self, request: LLMRequest) -> LLMResponse:
        """Generate response using OpenAI API"""
        try:
            start_time = time.time()
            _api_key = await self.get_api_key()  # noqa: F841

            # Production implementation would use:
            # client = await self._get_client()
            # response = await client.chat.completions.create(
            #     model=self.model_config.model_name,
            #     messages=[{"role": "user", "content": request.prompt}],
            #     max_tokens=request.max_tokens or self.model_config.max_tokens,
            #     temperature=request.temperature or self.model_config.temperature
            # )

            # Mock response for demonstration
            await asyncio.sleep(0.5)  # Simulate API call
            response_content = f"OpenAI {self.model_config.model_name} response to: {request.prompt[:50]}..."
            tokens_used = len(request.prompt.split()) + len(response_content.split())

            latency_ms = int((time.time() - start_time) * 1000)
            cost_estimate = self.estimate_cost(request.prompt, tokens_used)

            return LLMResponse(
                content=response_content,
                model_used=self.model_config.model_name,
                provider=self.provider.value,
                tokens_used=tokens_used,
                cost_estimate=cost_estimate,
                latency_ms=latency_ms,
                request_id=f"openai_{int(time.time())}",
            )

        except Exception as e:
            logger.error(f"OpenAI API error for {self.model_id}: {e}")
            raise

    async def generate_stream(self, request: LLMRequest) -> AsyncIterator[str]:
        """Generate streaming response"""
        try:
            _api_key = await self.get_api_key()  # noqa: F841

            # Production implementation would stream from OpenAI API
            # Mock streaming response
            response_parts = [
                "OpenAI",
                " streaming",
                " response",
                " to:",
                f" {request.prompt[:20]}...",
            ]

            for part in response_parts:
                await asyncio.sleep(0.1)
                yield part

        except Exception as e:
            logger.error(f"OpenAI streaming error for {self.model_id}: {e}")
            raise

    async def health_check(self) -> HealthCheckResult:
        """Check OpenAI API health"""
        try:
            start_time = time.time()
            _api_key = await self.get_api_key()  # noqa: F841

            # Production: Make a simple API call to check health
            # For now, just check if we can get the API key

            latency_ms = int((time.time() - start_time) * 1000)

            self._health_status = HealthCheckResult(
                is_healthy=True, latency_ms=latency_ms, last_check=time.time()
            )

        except Exception as e:
            self._health_status = HealthCheckResult(
                is_healthy=False, error_message=str(e), last_check=time.time()
            )

        return self._health_status

    def estimate_cost(self, prompt: str, max_tokens: int) -> float:
        """Estimate cost based on OpenAI pricing"""
        input_tokens = len(prompt.split()) * 1.3  # Rough token estimation
        total_tokens = input_tokens + max_tokens
        return total_tokens * self.model_config.cost_per_token


class GeminiAdapter(LLMServiceAdapter):
    """Google Gemini API adapter with secure key management"""

    def __init__(
        self, model_config: ModelConfiguration, key_vault_service: KeyVaultClientService
    ):
        super().__init__(model_config, key_vault_service)
        self._client = None

    async def _get_client(self):
        """Get Gemini client with fresh API key"""
        if self._client is None:
            # In production: import google.generativeai as genai
            _api_key = await self.get_api_key()  # noqa: F841
            # genai.configure(api_key=_api_key)
            # self._client = genai.GenerativeModel(self.model_config.model_name)
        return self._client

    async def generate_response(self, request: LLMRequest) -> LLMResponse:
        """Generate response using Gemini API"""
        try:
            start_time = time.time()
            _api_key = await self.get_api_key()  # noqa: F841

            # Production implementation would use Gemini API
            # Mock response for demonstration
            await asyncio.sleep(0.3)  # Simulate API call
            response_content = f"Gemini {self.model_config.model_name} response to: {request.prompt[:50]}..."
            tokens_used = len(request.prompt.split()) + len(response_content.split())

            latency_ms = int((time.time() - start_time) * 1000)
            cost_estimate = self.estimate_cost(request.prompt, tokens_used)

            return LLMResponse(
                content=response_content,
                model_used=self.model_config.model_name,
                provider=self.provider.value,
                tokens_used=tokens_used,
                cost_estimate=cost_estimate,
                latency_ms=latency_ms,
                request_id=f"gemini_{int(time.time())}",
            )

        except Exception as e:
            logger.error(f"Gemini API error for {self.model_id}: {e}")
            raise

    async def generate_stream(self, request: LLMRequest) -> AsyncIterator[str]:
        """Generate streaming response"""
        try:
            _api_key = await self.get_api_key()  # noqa: F841

            # Production implementation would stream from Gemini API
            # Mock streaming response
            response_parts = [
                "Gemini",
                " streaming",
                " response",
                " to:",
                f" {request.prompt[:20]}...",
            ]

            for part in response_parts:
                await asyncio.sleep(0.1)
                yield part

        except Exception as e:
            logger.error(f"Gemini streaming error for {self.model_id}: {e}")
            raise

    async def health_check(self) -> HealthCheckResult:
        """Check Gemini API health"""
        try:
            start_time = time.time()
            _api_key = await self.get_api_key()  # noqa: F841

            latency_ms = int((time.time() - start_time) * 1000)

            self._health_status = HealthCheckResult(
                is_healthy=True, latency_ms=latency_ms, last_check=time.time()
            )

        except Exception as e:
            self._health_status = HealthCheckResult(
                is_healthy=False, error_message=str(e), last_check=time.time()
            )

        return self._health_status

    def estimate_cost(self, prompt: str, max_tokens: int) -> float:
        """Estimate cost based on Gemini pricing"""
        input_tokens = len(prompt.split()) * 1.3  # Rough token estimation
        total_tokens = input_tokens + max_tokens
        return total_tokens * self.model_config.cost_per_token


class PerplexityAdapter(LLMServiceAdapter):
    """Perplexity API adapter with secure key management"""

    def __init__(
        self, model_config: ModelConfiguration, key_vault_service: KeyVaultClientService
    ):
        super().__init__(model_config, key_vault_service)
        self._client = None

    async def generate_response(self, request: LLMRequest) -> LLMResponse:
        """Generate response using Perplexity API"""
        try:
            start_time = time.time()
            _api_key = await self.get_api_key()  # noqa: F841

            # Production implementation would use Perplexity API
            # Mock response for demonstration
            await asyncio.sleep(0.4)  # Simulate API call
            response_content = f"Perplexity {self.model_config.model_name} response to: {request.prompt[:50]}..."
            tokens_used = len(request.prompt.split()) + len(response_content.split())

            latency_ms = int((time.time() - start_time) * 1000)
            cost_estimate = self.estimate_cost(request.prompt, tokens_used)

            return LLMResponse(
                content=response_content,
                model_used=self.model_config.model_name,
                provider=self.provider.value,
                tokens_used=tokens_used,
                cost_estimate=cost_estimate,
                latency_ms=latency_ms,
                request_id=f"perplexity_{int(time.time())}",
            )

        except Exception as e:
            logger.error(f"Perplexity API error for {self.model_id}: {e}")
            raise

    async def generate_stream(self, request: LLMRequest) -> AsyncIterator[str]:
        """Generate streaming response"""
        try:
            _api_key = await self.get_api_key()  # noqa: F841

            # Mock streaming response
            response_parts = [
                "Perplexity",
                " streaming",
                " response",
                " to:",
                f" {request.prompt[:20]}...",
            ]

            for part in response_parts:
                await asyncio.sleep(0.1)
                yield part

        except Exception as e:
            logger.error(f"Perplexity streaming error for {self.model_id}: {e}")
            raise

    async def health_check(self) -> HealthCheckResult:
        """Check Perplexity API health"""
        try:
            start_time = time.time()
            _api_key = await self.get_api_key()  # noqa: F841

            latency_ms = int((time.time() - start_time) * 1000)

            self._health_status = HealthCheckResult(
                is_healthy=True, latency_ms=latency_ms, last_check=time.time()
            )

        except Exception as e:
            self._health_status = HealthCheckResult(
                is_healthy=False, error_message=str(e), last_check=time.time()
            )

        return self._health_status

    def estimate_cost(self, prompt: str, max_tokens: int) -> float:
        """Estimate cost based on Perplexity pricing"""
        input_tokens = len(prompt.split()) * 1.3  # Rough token estimation
        total_tokens = input_tokens + max_tokens
        return total_tokens * self.model_config.cost_per_token


class FallbackAdapter(LLMServiceAdapter):
    """Fallback adapter for when no other providers are available"""

    def __init__(
        self, model_config: ModelConfiguration, key_vault_service: KeyVaultClientService
    ):
        super().__init__(model_config, key_vault_service)

    async def get_api_key(self) -> str:
        """Fallback doesn't need API key"""
        return "fallback_key"

    async def generate_response(self, request: LLMRequest) -> LLMResponse:
        """Generate fallback response"""
        try:
            start_time = time.time()

            # Simple fallback responses
            fallback_responses = [
                "I'm currently running in fallback mode. Please configure an LLM provider for full functionality.",
                "Thank you for your question. The AI service is temporarily unavailable, but I can provide basic assistance.",
                "I'm here to help! Currently operating in limited mode - please check back soon for full AI capabilities.",
            ]

            response_content = fallback_responses[
                hash(request.prompt) % len(fallback_responses)
            ]
            tokens_used = len(request.prompt.split()) + len(response_content.split())

            latency_ms = int((time.time() - start_time) * 1000)

            return LLMResponse(
                content=response_content,
                model_used="fallback",
                provider=self.provider.value,
                tokens_used=tokens_used,
                cost_estimate=0.0,  # No cost for fallback
                latency_ms=latency_ms,
                request_id=f"fallback_{int(time.time())}",
            )

        except Exception as e:
            logger.error(f"Fallback adapter error: {e}")
            raise

    async def generate_stream(self, request: LLMRequest) -> AsyncIterator[str]:
        """Generate fallback streaming response"""
        response = await self.generate_response(request)
        words = response.content.split()

        for word in words:
            yield word + " "
            await asyncio.sleep(0.05)

    async def health_check(self) -> HealthCheckResult:
        """Fallback is always healthy"""
        self._health_status = HealthCheckResult(
            is_healthy=True, latency_ms=1, last_check=time.time()
        )
        return self._health_status

    def estimate_cost(self, prompt: str, max_tokens: int) -> float:
        """Fallback has no cost"""
        return 0.0


class AdapterFactory:
    """Factory for creating LLM service adapters"""

    _adapter_classes = {
        LLMProvider.OPENAI: OpenAIAdapter,
        LLMProvider.GEMINI: GeminiAdapter,
        LLMProvider.PERPLEXITY: PerplexityAdapter,
        LLMProvider.FALLBACK: FallbackAdapter,
    }

    @classmethod
    def create_adapter(
        cls, model_config: ModelConfiguration, key_vault_service: KeyVaultClientService
    ) -> LLMServiceAdapter:
        """Create an adapter for the given model configuration"""
        try:
            provider = LLMProvider(model_config.provider)
            adapter_class = cls._adapter_classes.get(provider)

            if adapter_class is None:
                raise ValueError(f"Unsupported provider: {model_config.provider}")

            return adapter_class(model_config, key_vault_service)  # type: ignore[abstract]

        except Exception as e:
            logger.error(f"Failed to create adapter for {model_config.model_id}: {e}")
            raise

    @classmethod
    def get_supported_providers(cls) -> list[LLMProvider]:
        """Get list of supported providers"""
        return list(cls._adapter_classes.keys())


# Utility functions for adapter management


async def create_adapters_from_configs(
    model_configs: list[ModelConfiguration], key_vault_service: KeyVaultClientService
) -> dict[str, LLMServiceAdapter]:
    """Create adapters for a list of model configurations"""
    adapters = {}

    for config in model_configs:
        try:
            adapter = AdapterFactory.create_adapter(config, key_vault_service)
            adapters[config.model_id] = adapter
            logger.info(f"Created adapter for {config.model_id}")
        except Exception as e:
            logger.error(f"Failed to create adapter for {config.model_id}: {e}")

    return adapters


async def health_check_all_adapters(
    adapters: dict[str, LLMServiceAdapter],
) -> dict[str, HealthCheckResult]:
    """Perform health check on all adapters"""
    results = {}

    tasks = []
    for _model_id, adapter in adapters.items():
        tasks.append(adapter.health_check())

    health_results = await asyncio.gather(*tasks, return_exceptions=True)

    for (model_id, _adapter), result in zip(
        adapters.items(), health_results, strict=False
    ):
        if isinstance(result, Exception):
            results[model_id] = HealthCheckResult(
                is_healthy=False, error_message=str(result), last_check=time.time()
            )
        else:
            # result is guaranteed to be HealthCheckResult here
            results[model_id] = result  # type: ignore[assignment]

    return results

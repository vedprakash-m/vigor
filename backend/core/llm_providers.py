"""
LLM Provider implementations with Python 3.9+ compatibility.
Uses Optional instead of union syntax for better compatibility.
"""

import logging
from abc import ABC, abstractmethod
from typing import Dict, List, Optional

from .config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)


class LLMProvider(ABC):
    """Abstract base class for LLM providers."""

    @abstractmethod
    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        max_tokens: int = 500,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None,
    ) -> tuple[str, int, int]:
        """Generate chat completion. Returns (response, input_tokens, output_tokens)."""
        pass

    @abstractmethod
    def is_available(self) -> bool:
        """Check if provider is available."""
        pass


class OpenAIProvider(LLMProvider):
    """OpenAI API provider."""

    def __init__(self):
        self.client = None
        if settings.OPENAI_API_KEY:
            try:
                import openai

                self.client = openai.OpenAI(api_key=settings.OPENAI_API_KEY)
            except ImportError:
                logger.warning("OpenAI library not installed")

    def is_available(self) -> bool:
        """Check if OpenAI provider is available."""
        return self.client is not None

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        max_tokens: int = 500,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None,
    ) -> tuple[str, int, int]:
        """Generate OpenAI chat completion."""
        if self.client is None:
            raise RuntimeError("OpenAI client not available")

        try:
            formatted_messages = []
            if system_prompt:
                formatted_messages.append({"role": "system", "content": system_prompt})

            for msg in messages:
                formatted_messages.append(msg)

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=formatted_messages,
                max_tokens=max_tokens,
                temperature=temperature,
            )

            content = response.choices[0].message.content
            input_tokens = response.usage.prompt_tokens
            output_tokens = response.usage.completion_tokens

            return content, input_tokens, output_tokens

        except Exception as e:
            logger.error(f"OpenAI API error: {e}")
            raise


class GeminiProvider(LLMProvider):
    """Google Gemini API provider."""

    def __init__(self):
        self.client = None
        if settings.GEMINI_API_KEY:
            try:
                import google.generativeai as genai

                genai.configure(api_key=settings.GEMINI_API_KEY)
                self.client = genai.GenerativeModel("gemini-2.5-flash")
            except ImportError:
                logger.warning("Google Generative AI library not installed")

    def is_available(self) -> bool:
        """Check if Gemini provider is available."""
        return self.client is not None

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        max_tokens: int = 500,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None,
    ) -> tuple[str, int, int]:
        """Generate Gemini chat completion."""
        if self.client is None:
            raise RuntimeError("Gemini client not available")

        try:
            # Format messages for Gemini
            prompt_parts = []
            if system_prompt:
                prompt_parts.append(system_prompt)

            for msg in messages:
                role = msg.get("role", "user")
                content = msg.get("content", "")
                prompt_parts.append(f"{role}: {content}")

            prompt = "\n".join(prompt_parts)

            response = self.client.generate_content(
                prompt,
                generation_config={
                    "max_output_tokens": max_tokens,
                    "temperature": temperature,
                },
            )

            content = response.text
            # Gemini doesn't provide token counts in the same way
            # Estimate tokens: ~4 characters per token
            input_tokens = len(prompt) // 4
            output_tokens = len(content) // 4

            return content, input_tokens, output_tokens

        except Exception as e:
            logger.error(f"Gemini API error: {e}")
            raise


class PerplexityProvider(LLMProvider):
    """Perplexity AI API provider."""

    def __init__(self):
        self.client = None
        if settings.PERPLEXITY_API_KEY:
            try:
                import openai

                # Perplexity uses OpenAI-compatible API
                self.client = openai.OpenAI(
                    api_key=settings.PERPLEXITY_API_KEY,
                    base_url="https://api.perplexity.ai",
                )
            except ImportError:
                logger.warning("OpenAI library not installed for Perplexity")

    def is_available(self) -> bool:
        """Check if Perplexity provider is available."""
        return self.client is not None

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        max_tokens: int = 500,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None,
    ) -> tuple[str, int, int]:
        """Generate Perplexity chat completion."""
        if self.client is None:
            raise RuntimeError("Perplexity client not available")

        try:
            formatted_messages = []
            if system_prompt:
                formatted_messages.append({"role": "system", "content": system_prompt})

            for msg in messages:
                formatted_messages.append(msg)

            response = self.client.chat.completions.create(
                model="llama-3.1-sonar-small-128k-online",
                messages=formatted_messages,
                max_tokens=max_tokens,
                temperature=temperature,
            )

            content = response.choices[0].message.content
            input_tokens = response.usage.prompt_tokens if response.usage else 0
            output_tokens = response.usage.completion_tokens if response.usage else 0

            return content, input_tokens, output_tokens

        except Exception as e:
            logger.error(f"Perplexity API error: {e}")
            raise


class FallbackProvider(LLMProvider):
    """Fallback provider for when no AI services are available."""

    def is_available(self) -> bool:
        """Fallback is always available."""
        return True

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        max_tokens: int = 500,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None,
    ) -> tuple[str, int, int]:
        """Generate fallback response."""
        # Basic fallback responses based on message content
        last_message = messages[-1].get("content", "").lower() if messages else ""

        fallback_responses = {
            "workout": "I'd recommend starting with 3 sets of bodyweight exercises: push-ups, squats, and planks. Adjust reps based on your fitness level.",
            "exercise": "For a balanced workout, combine cardio (20-30 min) with strength training (2-3 exercises per muscle group).",
            "nutrition": "Focus on whole foods: lean proteins, complex carbs, healthy fats, and plenty of vegetables. Stay hydrated!",
            "rest": "Rest days are crucial for recovery. Consider light activities like walking or gentle stretching.",
            "motivation": "Remember, consistency is key. Every workout, no matter how small, is progress toward your goals!",
        }

        # Find matching response
        response = "I'm here to help with your fitness journey! However, AI services are currently unavailable. Please try again later or consult with a fitness professional."

        for keyword, fallback_response in fallback_responses.items():
            if keyword in last_message:
                response = fallback_response
                break

        # Simulate token usage (rough estimate)
        input_tokens = sum(len(msg.get("content", "")) for msg in messages) // 4
        output_tokens = len(response) // 4

        return response, input_tokens, output_tokens


def get_llm_provider() -> LLMProvider:
    """Get the configured LLM provider based on settings."""
    provider_name = settings.LLM_PROVIDER.lower()

    if provider_name == "openai":
        openai_provider = OpenAIProvider()
        if openai_provider.is_available():
            return openai_provider
    elif provider_name == "gemini":
        gemini_provider: LLMProvider = GeminiProvider()
        if gemini_provider.is_available():
            return gemini_provider
    elif provider_name == "perplexity":
        perplexity_provider: LLMProvider = PerplexityProvider()
        if perplexity_provider.is_available():
            return perplexity_provider

    # Try providers in order of preference if the specified one isn't available
    for ProviderClass in [OpenAIProvider, GeminiProvider, PerplexityProvider]:
        provider = ProviderClass()  # type: ignore[abstract]
        if provider.is_available():
            return provider

    # Return fallback if no providers are configured
    return FallbackProvider()

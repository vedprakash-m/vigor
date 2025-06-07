import json
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional

import httpx
from openai import AsyncOpenAI

from .config import get_settings

settings = get_settings()


class LLMProvider(ABC):
    """Abstract base class for LLM providers."""

    @abstractmethod
    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
        max_tokens: int = 500,
        temperature: float = 0.7,
        json_response: bool = False,
    ) -> str:
        """Generate a chat completion response."""
        pass

    @abstractmethod
    def is_available(self) -> bool:
        """Check if the provider is properly configured."""
        pass


class OpenAIProvider(LLMProvider):
    """OpenAI LLM provider."""

    def __init__(self):
        self.client = None
        if settings.OPENAI_API_KEY and settings.OPENAI_API_KEY not in [
            "your-openai-api-key-here",
            "sk-placeholder",
        ]:
            self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

    def is_available(self) -> bool:
        return self.client is not None

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
        max_tokens: int = 500,
        temperature: float = 0.7,
        json_response: bool = False,
    ) -> str:
        if not self.is_available():
            raise ValueError("OpenAI provider not properly configured")

        # Prepare messages
        formatted_messages = []
        if system_prompt:
            formatted_messages.append({"role": "system", "content": system_prompt})
        formatted_messages.extend(messages)

        # Prepare request parameters
        request_params = {
            "model": settings.OPENAI_MODEL,
            "messages": formatted_messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }

        if json_response:
            request_params["response_format"] = {"type": "json_object"}

        if self.client is None:
            raise RuntimeError("OpenAI client is not initialized")

        # Type ignore for OpenAI API overload complexity
        response = await self.client.chat.completions.create(**request_params)  # type: ignore[call-overload]
        return response.choices[0].message.content or ""


class GeminiProvider(LLMProvider):
    """Google Gemini LLM provider."""

    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model = settings.GEMINI_MODEL or "gemini-2.5-flash"
        self.base_url = "https://generativelanguage.googleapis.com/v1beta/models"

    def is_available(self) -> bool:
        return bool(self.api_key and self.api_key != "your-gemini-api-key-here")

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
        max_tokens: int = 500,
        temperature: float = 0.7,
        json_response: bool = False,
    ) -> str:
        if not self.is_available():
            raise ValueError("Gemini provider not properly configured")

        # Format messages for Gemini API
        contents = []

        if system_prompt:
            contents.append(
                {"role": "user", "parts": [{"text": f"System: {system_prompt}"}]}
            )

        for message in messages:
            role = "model" if message["role"] == "assistant" else "user"
            contents.append({"role": role, "parts": [{"text": message["content"]}]})

        # Add JSON format instruction if needed
        if json_response and contents:
            # Get the last message content
            last_message = contents[-1]
            if isinstance(last_message, dict) and "parts" in last_message:
                parts = last_message["parts"]
                if parts and isinstance(parts[0], dict) and "text" in parts[0]:
                    last_content = str(parts[0]["text"])
                    # Create new parts list to avoid Collection indexing issues
                    last_message["parts"] = [
                        {
                            "text": f"{last_content}\n\nPlease respond in valid JSON format."
                        }
                    ]

        payload = {
            "contents": contents,
            "generationConfig": {
                "temperature": temperature,
                "maxOutputTokens": max_tokens,
            },
        }

        url = f"{self.base_url}/{self.model}:generateContent?key={self.api_key}"

        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()

            result = response.json()
            if "candidates" in result and result["candidates"]:
                return str(
                    result["candidates"][0]["content"]["parts"][0]["text"]
                )  # Explicit str conversion
            else:
                raise ValueError("No response generated by Gemini")


class PerplexityProvider(LLMProvider):
    """Perplexity LLM provider."""

    def __init__(self):
        self.api_key = settings.PERPLEXITY_API_KEY
        self.model = settings.PERPLEXITY_MODEL or "llama-3.1-sonar-small-128k-online"
        self.base_url = "https://api.perplexity.ai/chat/completions"

    def is_available(self) -> bool:
        return bool(self.api_key and self.api_key != "your-perplexity-api-key-here")

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
        max_tokens: int = 500,
        temperature: float = 0.7,
        json_response: bool = False,
    ) -> str:
        if not self.is_available():
            raise ValueError("Perplexity provider not properly configured")

        # Prepare messages
        formatted_messages = []
        if system_prompt:
            formatted_messages.append({"role": "system", "content": system_prompt})

        # Add JSON format instruction if needed
        for message in messages:
            content = message["content"]
            if json_response and message["role"] == "user":
                content = f"{content}\n\nPlease respond in valid JSON format."
            formatted_messages.append({"role": message["role"], "content": content})

        payload = {
            "model": self.model,
            "messages": formatted_messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(self.base_url, json=payload, headers=headers)
            response.raise_for_status()

            result = response.json()
            return str(
                result["choices"][0]["message"]["content"]
            )  # Explicit str conversion


class FallbackProvider(LLMProvider):
    """Fallback provider for when no LLM is configured."""

    def is_available(self) -> bool:
        return True

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
        max_tokens: int = 500,
        temperature: float = 0.7,
        json_response: bool = False,
    ) -> str:
        # Extract user message for context
        user_message = ""
        for message in messages:
            if message["role"] == "user":
                user_message = message["content"]
                break

        if json_response:
            return json.dumps(
                {
                    "name": "Sample Bodyweight Workout",
                    "description": "A basic workout plan (LLM not configured - this is a sample)",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 3,
                            "reps": "8-12",
                            "rest": "60 seconds",
                            "notes": "Keep your core tight",
                        },
                        {
                            "name": "Squats",
                            "sets": 3,
                            "reps": "12-15",
                            "rest": "60 seconds",
                            "notes": "Keep your chest up",
                        },
                    ],
                    "difficulty": "beginner",
                    "equipment_needed": ["none"],
                    "duration_minutes": 30,
                    "notes": "Configure an LLM provider for personalized AI-generated workouts.",
                }
            )
        else:
            return f"Hello! I'm your AI fitness coach (demo mode - no LLM configured). You said: '{user_message}'. For personalized responses, please configure an LLM provider (OpenAI, Gemini, or Perplexity). In the meantime, I recommend staying consistent with your workouts!"


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

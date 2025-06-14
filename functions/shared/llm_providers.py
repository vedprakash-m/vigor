"""
LLM Providers for Azure Functions
This is a simplified version of the backend LLM providers for use in Azure Functions
"""

import json
import os
from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional

import httpx
from openai import AsyncOpenAI


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
        self.api_key = os.environ.get("OPENAI_API_KEY")
        self.model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")

        if self.api_key and self.api_key not in ["your-openai-api-key-here", "sk-placeholder"]:
            self.client = AsyncOpenAI(api_key=self.api_key)

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
            raise ValueError("OpenAI provider is not configured")

        if system_prompt:
            messages.insert(0, {"role": "system", "content": system_prompt})

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=messages,  # type: ignore
            max_tokens=max_tokens,
            temperature=temperature,
            response_format={"type": "json_object"} if json_response else None,
        )

        return response.choices[0].message.content or ""


class GeminiProvider(LLMProvider):
    """Google Gemini AI provider."""

    def __init__(self):
        self.client = None
        self.api_key = os.environ.get("GEMINI_API_KEY")
        self.model = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash")

        if self.api_key and self.api_key not in ["your-gemini-api-key-here"]:
            # Import here to avoid dependency issues if the provider isn't used
            import google.generativeai as genai

            genai.configure(api_key=self.api_key)
            self.client = genai
            self.model_client = genai.GenerativeModel(self.model)

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
            raise ValueError("Gemini provider is not configured")

        try:
            # Format conversation history for Gemini
            gemini_messages = []

            # Add system prompt if provided
            if system_prompt:
                gemini_messages.append({"role": "user", "parts": [system_prompt]})
                gemini_messages.append({"role": "model", "parts": ["I understand. I'll follow those instructions."]})

            # Add the rest of the messages
            for msg in messages:
                role = "user" if msg["role"] in ["user", "human"] else "model"
                gemini_messages.append({"role": role, "parts": [msg["content"]]})

            if json_response:
                # Make sure the last message instructs to respond in JSON
                last_message = gemini_messages[-1]["parts"][0]
                if not "JSON" in last_message and not "json" in last_message:
                    gemini_messages[-1]["parts"][0] = last_message + "\n\nPlease respond in valid JSON format only."

            # Create a chat session
            chat = self.model_client.start_chat(history=gemini_messages[:-1])

            # Get the response for the last message
            response = await chat.send_message_async(
                gemini_messages[-1]["parts"][0],
                generation_config={
                    "max_output_tokens": max_tokens,
                    "temperature": temperature,
                }
            )

            return response.text
        except Exception as e:
            raise RuntimeError(f"Gemini API error: {str(e)}")


class PerplexityProvider(LLMProvider):
    """Perplexity AI provider."""

    def __init__(self):
        self.api_key = os.environ.get("PERPLEXITY_API_KEY")
        self.model = os.environ.get("PERPLEXITY_MODEL", "llama-3-sonar-large-32k-online")
        self.api_url = "https://api.perplexity.ai/chat/completions"

    def is_available(self) -> bool:
        return bool(self.api_key and self.api_key not in ["your-perplexity-api-key-here"])

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
        max_tokens: int = 500,
        temperature: float = 0.7,
        json_response: bool = False,
    ) -> str:
        if not self.is_available():
            raise ValueError("Perplexity provider is not configured")

        if system_prompt:
            messages.insert(0, {"role": "system", "content": system_prompt})

        headers = {
            "Accept": "application/json",
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": self.model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "response_format": {"type": "json_object"} if json_response else {"type": "text"},
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                self.api_url, headers=headers, json=payload
            )
            response.raise_for_status()
            data = response.json()
            return data["choices"][0]["message"]["content"]


class FallbackProvider(LLMProvider):
    """Fallback provider that tries multiple providers in order."""

    def __init__(self):
        # Priority order: Gemini (cheapest), OpenAI, Perplexity
        self.providers = [
            GeminiProvider(),
            OpenAIProvider(),
            PerplexityProvider(),
        ]

        # Filter to only available providers
        self.available_providers = [p for p in self.providers if p.is_available()]

    def is_available(self) -> bool:
        return len(self.available_providers) > 0

    async def chat_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
        max_tokens: int = 500,
        temperature: float = 0.7,
        json_response: bool = False,
    ) -> str:
        if not self.is_available():
            raise ValueError("No LLM providers are available")

        # Try each provider in order
        last_error = None
        for provider in self.available_providers:
            try:
                return await provider.chat_completion(
                    messages=messages,
                    system_prompt=system_prompt,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    json_response=json_response,
                )
            except Exception as e:
                last_error = e
                continue

        # If we get here, all providers failed
        raise RuntimeError(f"All providers failed. Last error: {str(last_error)}")


def get_llm_provider() -> LLMProvider:
    """
    Get the appropriate LLM provider based on environment settings.
    """
    provider_name = os.environ.get("LLM_PROVIDER", "fallback").lower()

    if provider_name == "openai":
        return OpenAIProvider()
    elif provider_name == "gemini":
        return GeminiProvider()
    elif provider_name == "perplexity":
        return PerplexityProvider()
    else:  # Default to fallback
        return FallbackProvider()

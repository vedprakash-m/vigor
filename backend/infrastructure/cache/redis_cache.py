from __future__ import annotations

import json
from typing import Any

import aioredis

from core.llm_orchestration.adapters import LLMRequest, LLMResponse


class RedisCacheAdapter:
    """Distributed cache using Redis JSON serialization."""

    def __init__(self, redis_url: str):
        self._redis_url = redis_url
        self._client: aioredis.Redis | None = None

    async def initialize(self):
        if self._client is None:
            self._client = await aioredis.from_url(
                self._redis_url, encoding="utf-8", decode_responses=True
            )

    async def _key(self, request: LLMRequest) -> str:  # noqa: D401
        return f"llm:{hash((request.prompt, request.user_id, request.task_type))}"

    async def get(self, request: LLMRequest) -> LLMResponse | None:  # noqa: D401
        await self.initialize()
        assert self._client is not None  # Initialized in initialize()
        data = await self._client.get(await self._key(request))
        if data:
            return LLMResponse(**json.loads(data))
        return None

    async def set(self, request: LLMRequest, response: LLMResponse, ttl: int = 300):
        await self.initialize()
        assert self._client is not None  # Initialized in initialize()
        await self._client.set(await self._key(request), json.dumps(response.__dict__), ex=ttl)

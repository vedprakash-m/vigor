"""
Cache Manager
High-performance caching system for LLM responses
"""

import hashlib
import logging
import time
from dataclasses import dataclass
from typing import Any

from .adapters import LLMRequest, LLMResponse

logger = logging.getLogger(__name__)


@dataclass
class CacheEntry:
    """Cache entry structure"""

    response: LLMResponse
    timestamp: float
    access_count: int
    ttl: int


class CacheManager:
    """
    Intelligent caching system for LLM responses
    Supports TTL, LRU eviction, and smart cache keys
    """

    def __init__(self):
        self._cache: dict[str, CacheEntry] = {}
        self._max_size = 10000
        self._default_ttl = 3600  # 1 hour
        self._hits = 0
        self._misses = 0

    async def initialize(self):
        """Initialize cache manager"""
        logger.info("Cache manager initialized")

    async def get(self, request: LLMRequest) -> LLMResponse] = None:
        """Get cached response if available"""
        try:
            cache_key = self._generate_cache_key(request)

            if cache_key in self._cache:
                entry = self._cache[cache_key]

                # Check if expired
                if time.time() - entry.timestamp > entry.ttl:
                    del self._cache[cache_key]
                    self._misses += 1
                    return None

                # Update access count and return
                entry.access_count += 1
                self._hits += 1

                # Mark as cached
                response = entry.response
                response.cached = True
                return response

            self._misses += 1
            return None

        except Exception as e:
            logger.warning(f"Cache get failed: {e}")
            self._misses += 1
            return None

    async def set(
        self, request: LLMRequest, response: LLMResponse, ttl: int] = None = None
    ):
        """Cache a response"""
        try:
            cache_key = self._generate_cache_key(request)

            # Check cache size and evict if necessary
            if len(self._cache) >= self._max_size:
                self._evict_lru()

            entry = CacheEntry(
                response=response,
                timestamp=time.time(),
                access_count=1,
                ttl=ttl or self._default_ttl,
            )

            self._cache[cache_key] = entry

        except Exception as e:
            logger.warning(f"Cache set failed: {e}")

    def _generate_cache_key(self, request: LLMRequest) -> str:
        """Generate cache key from request"""
        # Create hash from prompt and key parameters
        key_data = f"{request.prompt}:{request.max_tokens}:{request.temperature}"
        return hashlib.sha256(key_data.encode()).hexdigest()[:16]

    def _evict_lru(self):
        """Evict least recently used entries"""
        if not self._cache:
            return

        # Sort by access count and timestamp
        sorted_entries = sorted(
            self._cache.items(), key=lambda x: (x[1].access_count, x[1].timestamp)
        )

        # Remove oldest 10% of entries
        evict_count = max(1, len(self._cache) // 10)
        for i in range(evict_count):
            key_to_remove = sorted_entries[i][0]
            del self._cache[key_to_remove]

    def get_stats(self) -> dict[str, Any]:
        """Get cache statistics"""
        total_requests = self._hits + self._misses
        hit_rate = (self._hits / total_requests * 100) if total_requests > 0 else 0

        return {
            "size": len(self._cache),
            "max_size": self._max_size,
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": hit_rate,
        }

    async def shutdown(self):
        """Shutdown cache manager"""
        self._cache.clear()
        logger.info("Cache manager shutdown")

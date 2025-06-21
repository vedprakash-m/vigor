from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Generic, List, Optional, TypeVar

from pydantic import BaseModel

T = TypeVar("T", bound=BaseModel)


class BaseRepository(ABC, Generic[T]):
    """Base repository interface."""

    @abstractmethod
    async def get(self, entity_id: str) -> Optional[T]:  # noqa: D401
        """Get entity by ID."""
        pass

    @abstractmethod
    async def create(self, entity: T) -> T:  # noqa: D401
        """Create new entity."""
        pass

    @abstractmethod
    async def update(self, entity: T) -> T:  # noqa: D401
        """Update existing entity."""
        pass

    @abstractmethod
    async def delete(self, entity_id: str) -> bool:  # noqa: D401
        """Delete entity by ID."""
        pass

    @abstractmethod
    async def list(self, limit: int = 100, offset: int = 0) -> List[T]:  # noqa: D401
        """List entities with pagination."""
        pass

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Generic, TypeVar

T = TypeVar("T")


class Repository(ABC, Generic[T]):
    """Abstract base repository defining CRUD operations."""

    @abstractmethod
    async def get(self, entity_id: str) -> T | None:  # noqa: D401
        pass

    @abstractmethod
    async def add(self, entity: T) -> T:  # noqa: D401
        pass

    @abstractmethod
    async def update(self, entity_id: str, update_data: dict) -> T:  # noqa: D401
        pass

    @abstractmethod
    async def list(self, **filters) -> list[T]:  # noqa: D401
        pass

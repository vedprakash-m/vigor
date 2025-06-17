from __future__ import annotations

from typing import Dict, List

from core.llm_orchestration.config_manager import AdminConfigManager
from core.llm_orchestration.routing import RoutingStrategyEngine  # Bridge import

"""Application-level wrapper around legacy RoutingStrategyEngine.

Goal: Decouple high-level orchestration use-cases from the concrete implementation
living in `core.llm_orchestration.routing` until the latter is ported.
"""


class RoutingEngine:
    """Thin adapter that exposes only the operations required by the application layer."""

    def __init__(self, config_manager: AdminConfigManager):
        self._delegate = RoutingStrategyEngine(config_manager)

    async def select_model(self, context: Dict[str, str], candidates: List[str]) -> str:
        """Return the chosen model ID from *candidates* for the given *context*."""
        return await self._delegate.select_model(context, candidates)

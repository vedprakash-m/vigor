from __future__ import annotations

from core.llm_orchestration.budget_manager import BudgetManager

"""Budget enforcement logic extracted from legacy gateway."""


class BudgetEnforcer:
    """Encapsulate budget checks to keep orchestration layer clean."""

    def __init__(self, budget_manager: BudgetManager):
        self._budget_manager = budget_manager

    async def ensure_within_budget(self, user_id: str, user_groups: list[str]):
        """Raise ``Exception`` if user exceeds budget constraints."""
        can_proceed = await self._budget_manager.can_proceed(user_id, user_groups)
        if not can_proceed:
            raise Exception("Budget limit exceeded")

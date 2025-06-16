from __future__ import annotations

"""Request validation and enrichment for LLM gateway logic.

This module belongs to the *Application* layer. It should avoid
references to concrete infrastructure (DB, key-vault, HTTP frameworks).
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, Optional

from core.llm_orchestration.adapters import LLMRequest  # noqa: E402 – same rationale

# NOTE: We deliberately import only *interfaces* from the legacy core until we can
# fully migrate them into the application layer.
from core.llm_orchestration.gateway import (  # noqa: E402 – cyclic edge acceptable short-term
    GatewayRequest,
)


@dataclass
class RequestValidator:
    """Validate user-supplied GatewayRequest and enrich with contextual metadata."""

    def __call__(
        self, request: GatewayRequest, request_id: str
    ) -> LLMRequest:  # noqa: D401
        """Return an enriched :class:`LLMRequest` ready for downstream processing."""

        if not request.prompt:
            raise ValueError("Prompt cannot be empty")

        return LLMRequest(
            prompt=request.prompt,
            user_id=request.user_id,
            session_id=request.session_id,
            task_type=request.task_type,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            stream=request.stream,
            context={
                "request_id": request_id,
                "user_tier": request.user_tier,
                "priority": request.priority,
                "timestamp": datetime.utcnow().isoformat(),
            },
            metadata=request.metadata,
        )

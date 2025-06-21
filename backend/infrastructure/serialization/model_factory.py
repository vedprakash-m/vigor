from __future__ import annotations

from typing import Any

"""Utility to generate Pydantic models directly from SQLAlchemy models.

This removes duplication between `database.models` and ORM entities.
Increments will gradually replace legacy manual Pydantic classes.
"""


def pydantic_model(sqlalchemy_model: type[Any], **kwargs):  # noqa: D401
    """Return a Pydantic model for *sqlalchemy_model* (placeholder implementation)."""
    # TODO: Implement once pydantic-sqlalchemy compatibility is resolved
    raise NotImplementedError("pydantic-sqlalchemy integration temporarily disabled")

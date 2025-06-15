from __future__ import annotations

"""Utility to generate Pydantic models directly from SQLAlchemy models.

This removes duplication between `database.models` and ORM entities.
Increments will gradually replace legacy manual Pydantic classes.
"""

from typing import Type, Any

from pydantic_sqlalchemy import sqlalchemy_to_pydantic
from database.connection import Base  # Ensure models registered


def pydantic_model(sqlalchemy_model: Type[Any], **kwargs):  # noqa: D401
    """Return a dynamic Pydantic model generated for *sqlalchemy_model*."""
    return sqlalchemy_to_pydantic(sqlalchemy_model, **kwargs)

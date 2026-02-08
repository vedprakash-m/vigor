"""
Shared helpers for Vigor Azure Functions
Phase 7.1: Input validation, structured errors, pagination bounds

Task 7.1.2: parse_request_body — validates JSON body against Pydantic models
Task 7.1.3: error_response — uniform JSON error responses with correct HTTP status
Task 7.1.4: parse_pagination — bounds-clamped limit/offset extraction
"""

import json
import logging
from typing import Any, Dict, Optional, Type, TypeVar

import azure.functions as func
from pydantic import BaseModel, ValidationError

logger = logging.getLogger(__name__)

T = TypeVar("T", bound=BaseModel)


# =============================================================================
# Task 7.1.3: Structured Error Responses
# =============================================================================


def error_response(
    message: str,
    status_code: int = 400,
    *,
    details: Optional[Any] = None,
    code: Optional[str] = None,
) -> func.HttpResponse:
    """Return a uniform JSON error response.

    Args:
        message: Human-readable error description.
        status_code: HTTP status code (default 400).
        details: Optional extra payload (validation errors, etc.).
        code: Optional machine-readable error code.

    Returns:
        func.HttpResponse with JSON body {"error": ..., "code": ..., "details": ...}
    """
    body: Dict[str, Any] = {"error": message}
    if code:
        body["code"] = code
    if details is not None:
        body["details"] = details

    return func.HttpResponse(
        json.dumps(body),
        status_code=status_code,
        mimetype="application/json",
    )


def success_response(
    data: Any,
    status_code: int = 200,
) -> func.HttpResponse:
    """Return a uniform JSON success response."""
    return func.HttpResponse(
        json.dumps(data),
        status_code=status_code,
        mimetype="application/json",
    )


# =============================================================================
# Task 7.1.2: Request Body Parsing with Pydantic Validation
# =============================================================================

def parse_request_body(
    req: func.HttpRequest,
    model_class: Type[T],
) -> tuple[Optional[T], Optional[func.HttpResponse]]:
    """Parse and validate a JSON request body using a Pydantic model.

    Returns:
        (parsed_model, None) on success
        (None, error_response) on failure — caller should return the error response
    """
    try:
        raw = req.get_json()
    except ValueError:
        return None, error_response(
            "Invalid JSON in request body",
            status_code=400,
            code="INVALID_JSON",
        )

    if not isinstance(raw, dict):
        return None, error_response(
            "Request body must be a JSON object",
            status_code=400,
            code="INVALID_BODY",
        )

    try:
        parsed = model_class(**raw)
        return parsed, None
    except ValidationError as e:
        return None, error_response(
            "Validation error",
            status_code=422,
            code="VALIDATION_ERROR",
            details=e.errors(),
        )


# =============================================================================
# Task 7.1.4: Pagination with Bounds Clamping
# =============================================================================

# Sensible maximums to prevent abuse
MAX_LIMIT = 100
DEFAULT_LIMIT = 20
DEFAULT_OFFSET = 0


def parse_pagination(
    req: func.HttpRequest,
    *,
    max_limit: int = MAX_LIMIT,
    default_limit: int = DEFAULT_LIMIT,
) -> tuple[int, int]:
    """Extract and clamp pagination parameters from query string.

    Args:
        req: The HTTP request.
        max_limit: Maximum allowed limit (default 100).
        default_limit: Default limit when not specified (default 20).

    Returns:
        (limit, offset) — both guaranteed non-negative, limit ≤ max_limit.
    """
    try:
        limit = int(req.params.get("limit", default_limit))
    except (ValueError, TypeError):
        limit = default_limit

    try:
        offset = int(req.params.get("offset", DEFAULT_OFFSET))
    except (ValueError, TypeError):
        offset = DEFAULT_OFFSET

    # Clamp to valid range
    limit = max(1, min(limit, max_limit))
    offset = max(0, offset)

    return limit, offset

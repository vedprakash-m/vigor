"""
Tests for shared/helpers.py — error_response, success_response, parse_request_body, parse_pagination
"""

import json
from unittest.mock import MagicMock

import azure.functions as func
import pytest
from pydantic import BaseModel

from shared.helpers import (
    error_response,
    parse_pagination,
    parse_request_body,
    success_response,
)


# ============================================================================
# Test fixtures / models
# ============================================================================


class SampleModel(BaseModel):
    name: str
    age: int
    optional_field: str = "default"


def _make_request(
    body: dict | None = None,
    params: dict | None = None,
    method: str = "POST",
) -> func.HttpRequest:
    """Create a mock HttpRequest."""
    req = func.HttpRequest(
        method=method,
        url="https://example.com/test",
        headers={},
        params=params or {},
        body=json.dumps(body).encode() if body else b"",
    )
    return req


# ============================================================================
# error_response
# ============================================================================


class TestErrorResponse:
    def test_basic(self):
        resp = error_response("bad input")
        assert resp.status_code == 400
        body = json.loads(resp.get_body())
        assert body["error"] == "bad input"

    def test_custom_status(self):
        resp = error_response("not found", status_code=404)
        assert resp.status_code == 404

    def test_with_code_and_details(self):
        resp = error_response(
            "validation failed",
            status_code=422,
            code="VALIDATION_ERROR",
            details=[{"field": "name"}],
        )
        body = json.loads(resp.get_body())
        assert body["code"] == "VALIDATION_ERROR"
        assert body["details"] == [{"field": "name"}]

    def test_content_type(self):
        resp = error_response("err")
        assert resp.mimetype == "application/json"


# ============================================================================
# success_response
# ============================================================================


class TestSuccessResponse:
    def test_default_200(self):
        resp = success_response({"ok": True})
        assert resp.status_code == 200
        body = json.loads(resp.get_body())
        assert body["ok"] is True

    def test_custom_status(self):
        resp = success_response({"id": "123"}, status_code=201)
        assert resp.status_code == 201

    def test_list_body(self):
        resp = success_response([1, 2, 3])
        body = json.loads(resp.get_body())
        assert body == [1, 2, 3]


# ============================================================================
# parse_request_body
# ============================================================================


class TestParseRequestBody:
    def test_valid_body(self):
        req = _make_request(body={"name": "Alice", "age": 30})
        result, err = parse_request_body(req, SampleModel)
        assert err is None
        assert result is not None
        assert result.name == "Alice"
        assert result.age == 30
        assert result.optional_field == "default"

    def test_invalid_json(self):
        req = func.HttpRequest(
            method="POST",
            url="https://example.com/test",
            headers={},
            params={},
            body=b"not-json",
        )
        result, err = parse_request_body(req, SampleModel)
        assert result is None
        assert err is not None
        assert err.status_code == 400

    def test_missing_required_field(self):
        req = _make_request(body={"name": "Alice"})  # missing 'age'
        result, err = parse_request_body(req, SampleModel)
        assert result is None
        assert err is not None
        assert err.status_code == 422

    def test_wrong_type(self):
        req = _make_request(body={"name": "Alice", "age": "not-a-number"})
        result, err = parse_request_body(req, SampleModel)
        assert result is None
        assert err is not None
        assert err.status_code == 422

    def test_array_body_rejected(self):
        req = func.HttpRequest(
            method="POST",
            url="https://example.com/test",
            headers={},
            params={},
            body=json.dumps([1, 2, 3]).encode(),
        )
        result, err = parse_request_body(req, SampleModel)
        assert result is None
        assert err is not None
        assert err.status_code == 400


# ============================================================================
# parse_pagination
# ============================================================================


class TestParsePagination:
    def test_defaults(self):
        req = _make_request(params={}, method="GET")
        limit, offset = parse_pagination(req)
        assert limit == 20
        assert offset == 0

    def test_custom_values(self):
        req = _make_request(params={"limit": "10", "offset": "5"}, method="GET")
        limit, offset = parse_pagination(req)
        assert limit == 10
        assert offset == 5

    def test_clamp_high_limit(self):
        req = _make_request(params={"limit": "999"}, method="GET")
        limit, _ = parse_pagination(req)
        assert limit == 100  # MAX_LIMIT

    def test_clamp_negative_offset(self):
        req = _make_request(params={"offset": "-5"}, method="GET")
        _, offset = parse_pagination(req)
        assert offset == 0

    def test_clamp_zero_limit(self):
        req = _make_request(params={"limit": "0"}, method="GET")
        limit, _ = parse_pagination(req)
        assert limit == 1  # min is 1

    def test_non_numeric_defaults(self):
        req = _make_request(params={"limit": "abc", "offset": "xyz"}, method="GET")
        limit, offset = parse_pagination(req)
        assert limit == 20
        assert offset == 0

    def test_custom_max_limit(self):
        req = _make_request(params={"limit": "50"}, method="GET")
        limit, _ = parse_pagination(req, max_limit=30)
        assert limit == 30

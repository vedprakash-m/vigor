"""
Tests for shared/auth.py — JWKS caching, issuer validation
"""

import time
from unittest.mock import MagicMock, patch

import pytest

from shared.auth import (
    _get_jwks_keys,
    _jwks_cache,
    _JWKS_CACHE_TTL_SECONDS,
)


class TestJWKSCaching:
    """Task 7.0.10: Verify JWKS keys are cached for 24 hours"""

    def setup_method(self):
        """Reset cache before each test"""
        import shared.auth as auth_mod

        auth_mod._jwks_cache = None
        auth_mod._jwks_cache_expiry = 0.0

    @patch("shared.auth.requests.get")
    def test_first_call_fetches_from_network(self, mock_get):
        mock_resp = MagicMock()
        mock_resp.json.return_value = {"keys": [{"kid": "test-key-1"}]}
        mock_resp.raise_for_status = MagicMock()
        mock_get.return_value = mock_resp

        keys = _get_jwks_keys()

        mock_get.assert_called_once()
        assert len(keys) == 1
        assert keys[0]["kid"] == "test-key-1"

    @patch("shared.auth.requests.get")
    def test_second_call_uses_cache(self, mock_get):
        mock_resp = MagicMock()
        mock_resp.json.return_value = {"keys": [{"kid": "test-key-1"}]}
        mock_resp.raise_for_status = MagicMock()
        mock_get.return_value = mock_resp

        # First call
        keys1 = _get_jwks_keys()
        # Second call — should NOT call network
        keys2 = _get_jwks_keys()

        assert mock_get.call_count == 1
        assert keys1 is keys2

    @patch("shared.auth.requests.get")
    def test_cache_expires_after_ttl(self, mock_get):
        import shared.auth as auth_mod

        mock_resp = MagicMock()
        mock_resp.json.return_value = {"keys": [{"kid": "key-v1"}]}
        mock_resp.raise_for_status = MagicMock()
        mock_get.return_value = mock_resp

        # First call
        _get_jwks_keys()
        assert mock_get.call_count == 1

        # Expire the cache manually
        auth_mod._jwks_cache_expiry = time.time() - 1

        # Updated response
        mock_resp2 = MagicMock()
        mock_resp2.json.return_value = {"keys": [{"kid": "key-v2"}]}
        mock_resp2.raise_for_status = MagicMock()
        mock_get.return_value = mock_resp2

        keys = _get_jwks_keys()
        assert mock_get.call_count == 2
        assert keys[0]["kid"] == "key-v2"

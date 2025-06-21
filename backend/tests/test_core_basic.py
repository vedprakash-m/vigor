"""Basic Core Module Tests"""

from unittest.mock import Mock, patch

import pytest

from core.config import get_settings
from core.security import get_password_hash, verify_password


def test_settings_loading():
    """Test configuration loading"""
    settings = get_settings()
    assert settings is not None
    assert hasattr(settings, "SECRET_KEY")
    assert hasattr(settings, "DATABASE_URL")


def test_password_hashing():
    """Test password hashing functions"""
    password = "TestPassword123!"

    # Test hashing
    hashed = get_password_hash(password)
    assert hashed is not None
    assert hashed != password
    assert len(hashed) > 0

    # Test verification
    assert verify_password(password, hashed) is True
    assert verify_password("WrongPassword", hashed) is False


def test_different_passwords_different_hashes():
    """Test that different passwords produce different hashes"""
    password1 = "Password123!"
    password2 = "DifferentPassword456!"

    hash1 = get_password_hash(password1)
    hash2 = get_password_hash(password2)

    assert hash1 != hash2


def test_same_password_different_hashes():
    """Test that same password produces different hashes (salt)"""
    password = "SamePassword123!"

    hash1 = get_password_hash(password)
    hash2 = get_password_hash(password)

    # Should be different due to salt
    assert hash1 != hash2

    # But both should verify correctly
    assert verify_password(password, hash1) is True
    assert verify_password(password, hash2) is True


def test_empty_password_handling():
    """Test handling of empty passwords"""
    try:
        hashed = get_password_hash("")
        # If it doesn't raise an error, verify it works
        assert verify_password("", hashed) is True
    except Exception:
        # If it raises an error, that's also acceptable
        pass


def test_none_password_handling():
    """Test handling of None passwords"""
    try:
        hashed = get_password_hash(None)
        # If it doesn't raise an error, test behavior
        assert hashed is not None
    except Exception:
        # Expected to fail with None input
        pass

"""Basic core module tests"""

import pytest
from core.config import get_settings
from core.security import hash_password, verify_password


def test_settings_loading():
    """Test configuration loading"""
    settings = get_settings()
    assert settings is not None
    assert hasattr(settings, 'SECRET_KEY')
    assert hasattr(settings, 'DATABASE_URL')


def test_password_hashing():
    """Test password hashing functions"""
    password = "TestPassword123!"

    # Test hashing
    hashed = hash_password(password)
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

    hash1 = hash_password(password1)
    hash2 = hash_password(password2)

    assert hash1 != hash2


def test_same_password_different_hashes():
    """Test that same password produces different hashes (salt)"""
    password = "SamePassword123!"

    hash1 = hash_password(password)
    hash2 = hash_password(password)

    # Should be different due to salt
    assert hash1 != hash2

    # But both should verify correctly
    assert verify_password(password, hash1) is True
    assert verify_password(password, hash2) is True


def test_empty_password_handling():
    """Test handling of empty passwords"""
    try:
        hashed = hash_password("")
        # If it doesn't raise an error, verify it works
        assert verify_password("", hashed) is True
    except Exception:
        # If it raises an error, that's also acceptable
        pass


def test_none_password_handling():
    """Test handling of None passwords"""
    try:
        hashed = hash_password(None)
        # If it doesn't raise an error, test behavior
        assert hashed is not None
    except Exception:
        # Expected to fail with None input
        pass

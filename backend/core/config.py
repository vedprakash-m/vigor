"""
Application configuration with environment variable support.
Compatible with Python 3.9+ using Optional instead of Union syntax.
"""

import os
from functools import lru_cache
from typing import ClassVar, List, Optional

from dotenv import load_dotenv
from pydantic_settings import BaseSettings

load_dotenv()


class Settings(BaseSettings):
    """Application settings with validation."""

    # Core application settings
    APP_NAME: str = "Vigor"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")

    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", "sqlite:///./vigor.db"
    )  # Fallback for dev

    # Authentication
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
    ALGORITHM: str = "HS256"  # JWT algorithm
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Microsoft Entra External ID (OAuth2)
    MICROSOFT_CLIENT_ID: Optional[str] = os.getenv("MICROSOFT_CLIENT_ID")
    MICROSOFT_CLIENT_SECRET: Optional[str] = os.getenv("MICROSOFT_CLIENT_SECRET")
    MICROSOFT_TENANT_ID: Optional[str] = os.getenv("MICROSOFT_TENANT_ID")
    MICROSOFT_REDIRECT_URI: str = os.getenv(
        "MICROSOFT_REDIRECT_URI", "http://localhost:5173/auth/callback/microsoft"
    )

    # Social Login Providers
    GOOGLE_CLIENT_ID: Optional[str] = os.getenv("GOOGLE_CLIENT_ID")
    GOOGLE_CLIENT_SECRET: Optional[str] = os.getenv("GOOGLE_CLIENT_SECRET")
    GOOGLE_REDIRECT_URI: str = os.getenv(
        "GOOGLE_REDIRECT_URI", "http://localhost:5173/auth/callback/google"
    )

    GITHUB_CLIENT_ID: Optional[str] = os.getenv("GITHUB_CLIENT_ID")
    GITHUB_CLIENT_SECRET: Optional[str] = os.getenv("GITHUB_CLIENT_SECRET")
    GITHUB_REDIRECT_URI: str = os.getenv(
        "GITHUB_REDIRECT_URI", "http://localhost:5173/auth/callback/github"
    )

    # OAuth2 Configuration
    OAUTH_STATE_SECRET: str = os.getenv(
        "OAUTH_STATE_SECRET", "your-oauth-state-secret-change-in-production"
    )
    OAUTH_PKCE_CHALLENGE_METHOD: str = "S256"

    # Frontend URLs for OAuth flows
    FRONTEND_URL: str = os.getenv("FRONTEND_URL", "http://localhost:5173")
    LOGIN_SUCCESS_REDIRECT: str = os.getenv(
        "LOGIN_SUCCESS_REDIRECT", "http://localhost:5173/dashboard"
    )
    LOGIN_ERROR_REDIRECT: str = os.getenv(
        "LOGIN_ERROR_REDIRECT", "http://localhost:5173/login?error=oauth_error"
    )

    # AI Provider APIs - all optional, fallback gracefully
    OPENAI_API_KEY: Optional[str] = os.getenv("OPENAI_API_KEY")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
    LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "fallback")

    # Alternative AI providers
    GEMINI_API_KEY: Optional[str] = os.getenv("GEMINI_API_KEY")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
    ANTHROPIC_API_KEY: str = os.getenv("ANTHROPIC_API_KEY", "")

    # Perplexity AI
    PERPLEXITY_API_KEY: Optional[str] = os.getenv("PERPLEXITY_API_KEY")
    PERPLEXITY_MODEL: str = os.getenv(
        "PERPLEXITY_MODEL", "llama-3-sonar-large-32k-online"
    )

    # Azure Functions
    AZURE_FUNCTIONS_BASE_URL: str = os.getenv(
        "AZURE_FUNCTIONS_BASE_URL", "http://localhost:7071"
    )

    # Redis Configuration (optional - will use in-memory if not available)
    REDIS_URL: str = os.getenv("REDIS_URL", "memory://")

    # Azure Key Vault
    AZURE_KEY_VAULT_URL: str = os.getenv("AZURE_KEY_VAULT_URL", "")

    # Microsoft Entra ID Authentication (Vedprakash Domain Standard)
    AZURE_AD_CLIENT_ID: Optional[str] = os.getenv("AZURE_AD_CLIENT_ID")
    AZURE_AD_TENANT_ID: str = os.getenv("AZURE_AD_TENANT_ID", "vedid.onmicrosoft.com")
    AZURE_AD_AUTHORITY: str = (
        f"https://login.microsoftonline.com/{os.getenv('AZURE_AD_TENANT_ID', 'vedid.onmicrosoft.com')}"
    )

    # CORS settings
    _cors_origins_env: ClassVar[Optional[str]] = os.getenv("CORS_ORIGINS")
    CORS_ORIGINS: List[str] = (
        _cors_origins_env.split(",") if _cors_origins_env else ["http://localhost:5173"]
    )

    class Config:
        """Pydantic configuration."""

        env_file = ".env"
        extra = "ignore"  # Ignore extra fields from .env


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()

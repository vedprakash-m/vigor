"""
Application configuration with environment variable support.
Compatible with Python 3.9+ using Optional instead of Union syntax.
"""

import os
from functools import lru_cache
from typing import ClassVar, Optional

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
    PERPLEXITY_MODEL: str = os.getenv("PERPLEXITY_MODEL", "llama-3-sonar-large-32k-online")

    # Azure Functions
    AZURE_FUNCTIONS_BASE_URL: str = os.getenv(
        "AZURE_FUNCTIONS_BASE_URL", "http://localhost:7071"
    )

    # Redis Configuration (optional - will use in-memory if not available)
    REDIS_URL: str = os.getenv("REDIS_URL", "memory://")

    # Azure Key Vault
    AZURE_KEY_VAULT_URL: str = os.getenv("AZURE_KEY_VAULT_URL", "")

    # CORS settings
    _cors_origins_env: ClassVar[Optional[str]] = os.getenv("CORS_ORIGINS")
    CORS_ORIGINS: list[str] = (
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

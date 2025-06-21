import os
from functools import lru_cache
from typing import ClassVar

from dotenv import load_dotenv
from pydantic_settings import BaseSettings

load_dotenv()


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "Vigor"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")

    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-here")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    ALGORITHM: str = "HS256"

    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./vigor.db")

    # LLM Provider Configuration
    LLM_PROVIDER: str = os.getenv(
        "LLM_PROVIDER", "openai"
    )  # openai, gemini, perplexity

    # OpenAI
    OPENAI_API_KEY: str | None = os.getenv("OPENAI_API_KEY")
    OPENAI_MODEL: str = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")

    # Google Gemini
    GEMINI_API_KEY: str | None = os.getenv("GEMINI_API_KEY")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

    # Perplexity
    PERPLEXITY_API_KEY: str | None = os.getenv("PERPLEXITY_API_KEY")
    PERPLEXITY_MODEL: str = os.getenv(
        "PERPLEXITY_MODEL", "llama-3.1-sonar-small-128k-online"
    )

    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")

    # CORS
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",  # Frontend development server
        "http://localhost:8000",  # Backend development server
    ]

    # Add any additional CORS origins from environment.
    # Use a leading underscore and ClassVar to signal this should not be treated
    # as a Pydantic model field.
    _cors_origins_env: ClassVar[str | None] = os.getenv("CORS_ORIGINS")

    if _cors_origins_env:
        CORS_ORIGINS.extend(_cors_origins_env.split(","))

    class Config:
        case_sensitive = True


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()

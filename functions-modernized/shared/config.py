"""
Configuration management for Vigor Functions
Centralized settings using Pydantic Settings
"""

from typing import Optional

from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Cosmos DB Configuration - support both naming conventions
    COSMOS_DB_ENDPOINT: str = Field(default="", description="Cosmos DB endpoint URL")
    COSMOS_ENDPOINT: str = Field(
        default="", description="Cosmos DB endpoint URL (alias)"
    )
    COSMOS_DB_KEY: str = Field(default="", description="Cosmos DB primary key")
    COSMOS_KEY: str = Field(default="", description="Cosmos DB primary key (alias)")
    COSMOS_DB_CONNECTION_STRING: str = Field(
        default="", description="Cosmos DB connection string"
    )
    COSMOS_DB_DATABASE: str = Field(default="vigor_db", description="Database name")
    COSMOS_DATABASE: str = Field(
        default="vigor_db", description="Database name (alias)"
    )
    COSMOS_DB_DATABASE_NAME: str = Field(
        default="vigor_db", description="Database name (alias)"
    )

    @property
    def cosmos_endpoint(self) -> str:
        """Get Cosmos DB endpoint from either setting name"""
        return self.COSMOS_DB_ENDPOINT or self.COSMOS_ENDPOINT or ""

    @property
    def cosmos_key(self) -> str:
        """Get Cosmos DB key from either setting name"""
        return self.COSMOS_DB_KEY or self.COSMOS_KEY or ""

    @property
    def cosmos_database(self) -> str:
        """Get Cosmos DB database from any setting name"""
        return (
            self.COSMOS_DB_DATABASE
            or self.COSMOS_DATABASE
            or self.COSMOS_DB_DATABASE_NAME
            or "vigor_db"
        )

    # Admin Configuration
    ADMIN_EMAIL: str = Field(
        default="admin@vigor.com", description="Default admin email"
    )
    ADMIN_PASSWORD: str = Field(
        default="ChangeMe123!", description="Default admin password"
    )

    # Azure OpenAI Configuration (gpt-5-mini via Azure AI Foundry)
    AZURE_OPENAI_ENDPOINT: str = Field(
        default="", description="Azure OpenAI endpoint URL"
    )
    AZURE_OPENAI_API_KEY: str = Field(default="", description="Azure OpenAI API key")
    AZURE_OPENAI_DEPLOYMENT: str = Field(
        default="gpt-5-mini", description="Azure OpenAI deployment name"
    )
    AZURE_OPENAI_API_VERSION: str = Field(
        default="2024-12-01-preview", description="Azure OpenAI API version (use preview versions for Azure AI Foundry)"
    )
    AI_MONTHLY_BUDGET: str = Field(default="50", description="Monthly AI budget in USD")
    AI_COST_THRESHOLD: str = Field(
        default="40", description="Cost alert threshold in USD"
    )

    # Legacy OpenAI settings (for backward compatibility during migration)
    OPENAI_API_KEY: str = Field(
        default="", description="OpenAI API key (deprecated, use Azure OpenAI)"
    )
    OPENAI_MODEL: str = Field(
        default="gpt-5-mini", description="OpenAI model name (deprecated)"
    )
    AI_PROVIDER: str = Field(
        default="azure-openai-gpt-5-mini", description="AI provider identifier"
    )

    # Authentication
    JWT_SECRET_KEY: str = Field(default="", description="JWT secret key")
    AZURE_TENANT_ID: str = Field(
        default="common", description="Azure tenant ID for default tenant"
    )
    AZURE_CLIENT_ID: str = Field(
        default="", description="Azure AD app registration client ID"
    )
    SECRET_KEY: str = Field(default="", description="Application secret key")

    # Application Settings
    ENVIRONMENT: str = Field(default="development", description="Environment")
    LOG_LEVEL: str = Field(default="INFO", description="Logging level")

    # Rate Limiting
    RATE_LIMIT_STORAGE_TYPE: str = Field(
        default="memory", description="Rate limit storage"
    )

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


# Global settings instance
_settings: Optional[Settings] = None


def get_settings() -> Settings:
    """Get application settings (singleton pattern)"""
    global _settings
    if _settings is None:
        _settings = Settings()

        # Parse Cosmos DB connection string if provided
        if _settings.COSMOS_DB_CONNECTION_STRING and not _settings.COSMOS_DB_ENDPOINT:
            _parse_cosmos_connection_string(_settings)
    return _settings


def _parse_cosmos_connection_string(settings: Settings):
    """Parse Cosmos DB connection string into endpoint and key"""
    try:
        conn_str = settings.COSMOS_DB_CONNECTION_STRING
        if "AccountEndpoint=" in conn_str and "AccountKey=" in conn_str:
            # Extract endpoint
            endpoint_start = conn_str.find("AccountEndpoint=") + len("AccountEndpoint=")
            endpoint_end = conn_str.find(";", endpoint_start)
            if endpoint_end == -1:
                endpoint_end = len(conn_str)
            settings.COSMOS_DB_ENDPOINT = conn_str[endpoint_start:endpoint_end]

            # Extract key
            key_start = conn_str.find("AccountKey=") + len("AccountKey=")
            key_end = conn_str.find(";", key_start)
            if key_end == -1:
                key_end = len(conn_str)
            settings.COSMOS_DB_KEY = conn_str[key_start:key_end]

    except Exception as e:
        # Log error but don't fail - use provided endpoint/key if available
        print(f"Warning: Could not parse Cosmos DB connection string: {e}")


def reload_settings() -> Settings:
    """Force reload settings from environment"""
    global _settings
    _settings = Settings()
    return _settings

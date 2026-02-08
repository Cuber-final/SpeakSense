"""Application settings and environment loading."""

from __future__ import annotations

from functools import lru_cache

from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=(".env", "backend/.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = Field(default="dev", alias="APP_ENV")
    api_host: str = Field(default="0.0.0.0", alias="API_HOST")
    api_port: int = Field(default=8000, alias="API_PORT")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")
    database_url: str = Field(
        default="postgresql+psycopg://user:pass@localhost:5432/speakcoach",
        alias="DATABASE_URL",
    )
    redis_url: str = Field(default="redis://localhost:6379/0", alias="REDIS_URL")
    cors_allow_origins: list[str] = Field(
        default_factory=lambda: ["*"],
        alias="CORS_ALLOW_ORIGINS",
    )
    llm_provider: str = Field(
        default="openai_compatible",
        validation_alias=AliasChoices("LLM_PROVIDER", "MODEL_PROVIDER"),
    )
    llm_base_url: str = Field(
        default="https://api.openai.com/v1",
        validation_alias=AliasChoices("LLM_BASE_URL", "MODEL_API_BASE"),
    )
    llm_api_key: str = Field(default="", alias="LLM_API_KEY")
    llm_default_model: str = Field(
        default="gpt-4o-mini",
        validation_alias=AliasChoices("LLM_DEFAULT_MODEL", "MODEL_NAME"),
    )
    llm_mock_response_text: str = Field(
        default="This is a mock model response.",
        alias="LLM_MOCK_RESPONSE_TEXT",
    )
    llm_timeout_ms: int = Field(default=30000, alias="LLM_TIMEOUT_MS")
    llm_max_retries: int = Field(default=1, alias="LLM_MAX_RETRIES")
    enable_async_jobs: bool = Field(default=False, alias="ENABLE_ASYNC_JOBS")
    job_queue_name: str = Field(default="default", alias="JOB_QUEUE_NAME")
    job_timeout_seconds: int = Field(default=300, alias="JOB_TIMEOUT_SECONDS")
    job_inline_fallback: bool = Field(default=True, alias="JOB_INLINE_FALLBACK")
    rate_limit_requests: int = Field(default=60, alias="RATE_LIMIT_REQUESTS")
    rate_limit_window_seconds: int = Field(
        default=60,
        alias="RATE_LIMIT_WINDOW_SECONDS",
    )
    idempotency_ttl_seconds: int = Field(
        default=86400,
        alias="IDEMPOTENCY_TTL_SECONDS",
    )
    asr_provider: str = Field(default="mock", alias="ASR_PROVIDER")
    asr_delete_audio_after: bool = Field(
        default=True,
        alias="ASR_DELETE_AUDIO_AFTER",
    )
    asr_max_duration_seconds: int = Field(default=90, alias="ASR_MAX_DURATION_SECONDS")
    asr_mock_transcript: str = Field(
        default="This is a mock ASR transcript preview.",
        alias="ASR_MOCK_TRANSCRIPT",
    )
    asr_whisper_model_size: str = Field(
        default="base",
        alias="ASR_WHISPER_MODEL_SIZE",
    )
    asr_whisper_compute_type: str = Field(
        default="int8",
        alias="ASR_WHISPER_COMPUTE_TYPE",
    )
    jwt_secret: str = Field(
        default="dev-insecure-change-me",
        alias="JWT_SECRET",
    )
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    jwt_expires_minutes: int = Field(default=120, alias="JWT_EXPIRES_MINUTES")
    dev_admin_username: str = Field(
        default="dev_admin",
        alias="DEV_ADMIN_USERNAME",
    )
    dev_admin_password: str = Field(
        default="dev_admin_123456",
        alias="DEV_ADMIN_PASSWORD",
    )
    dev_admin_role: str = Field(default="admin", alias="DEV_ADMIN_ROLE")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Return cached runtime settings."""
    return Settings()

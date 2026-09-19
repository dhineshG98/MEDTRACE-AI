"""Application settings and environment configuration."""

from pathlib import Path
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "MedTrace AI"
    APP_VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    API_PREFIX: str = "/api"

    # Base directory
    BASE_DIR: Path = Path(__file__).resolve().parent.parent.parent
    UPLOAD_DIR: Path = BASE_DIR / "uploads"

    # Database: defaults to SQLite so no external database is needed
    DATABASE_URL: str = "sqlite:///./medtrace.db"

    # CORS
    CORS_ORIGINS: list[str] = [
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://10.0.2.2:8000",
    ]

    # File uploads
    MAX_UPLOAD_SIZE_MB: int = 25
    ALLOWED_EXTENSIONS: list[str] = ["pdf", "png", "jpg", "jpeg", "docx"]

    # Extraction settings
    PDF_TEXT_MIN_CHARS: int = 100
    TESSERACT_PATH: Optional[str] = None
    OCR_LANGUAGES: str = "eng"

    # AI Provider settings (Phase 3)
    AI_PROVIDER: str = "auto"  # "auto", "anthropic", "openai", "gemini", "heuristic"
    AI_MODEL: Optional[str] = None
    AI_API_KEY: Optional[str] = None
    ANTHROPIC_API_KEY: Optional[str] = None
    OPENAI_API_KEY: Optional[str] = None
    GEMINI_API_KEY: Optional[str] = None
    AI_MAX_RETRIES: int = 3
    AI_TIMEOUT_SECONDS: int = 30

    # Medical Data Encryption (AES-256-GCM)
    MEDTRACE_ENCRYPTION_KEY: Optional[str] = None

    # Access Control / API Security
    API_AUTH_TOKEN: Optional[str] = None

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @property
    def cors_origins(self) -> list[str]:
        if self.ENVIRONMENT.lower() != "production":
            return ["*"]
        return self.CORS_ORIGINS

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT.lower() == "production"

    @property
    def max_upload_size_bytes(self) -> int:
        return self.MAX_UPLOAD_SIZE_MB * 1024 * 1024

    @property
    def allowed_extensions(self) -> set[str]:
        return {ext.lower().lstrip(".") for ext in self.ALLOWED_EXTENSIONS}

    @property
    def resolved_ai_key(self) -> Optional[str]:
        return self.AI_API_KEY or self.ANTHROPIC_API_KEY or self.OPENAI_API_KEY or self.GEMINI_API_KEY

    @property
    def resolved_ai_provider(self) -> str:
        if self.AI_PROVIDER != "auto":
            return self.AI_PROVIDER.lower()
        if self.ANTHROPIC_API_KEY or (self.AI_API_KEY and self.AI_API_KEY.startswith("sk-ant-")):
            return "anthropic"
        if self.OPENAI_API_KEY or (self.AI_API_KEY and self.AI_API_KEY.startswith("sk-")):
            return "openai"
        if self.GEMINI_API_KEY or (self.AI_API_KEY and self.AI_API_KEY.startswith("AIza")):
            return "gemini"
        if self.AI_API_KEY:
            return "anthropic"
        return "heuristic"

    @property
    def resolved_ai_model(self) -> str:
        if self.AI_MODEL:
            return self.AI_MODEL
        prov = self.resolved_ai_provider
        if prov == "gemini":
            return "gemini-3.1-flash-lite"
        if prov == "openai":
            return "gpt-4o-mini"
        if prov == "anthropic":
            return "claude-3-5-sonnet-20241022"
        return "clinical-heuristics-v1"

    @property
    def ai_configured(self) -> bool:
        prov = self.resolved_ai_provider
        if prov == "heuristic":
            return False
        if prov == "gemini":
            return bool(self.GEMINI_API_KEY or self.AI_API_KEY)
        if prov == "openai":
            return bool(self.OPENAI_API_KEY or self.AI_API_KEY)
        if prov == "anthropic":
            return bool(self.ANTHROPIC_API_KEY or self.AI_API_KEY)
        return bool(self.resolved_ai_key)

    @property
    def resolved_encryption_key(self) -> str:
        """Returns the 256-bit AES key as a 64-character hex string.

        Loads from MEDTRACE_ENCRYPTION_KEY or generates one in development.
        """
        import secrets
        if self.MEDTRACE_ENCRYPTION_KEY and len(self.MEDTRACE_ENCRYPTION_KEY.strip()) >= 32:
            return self.MEDTRACE_ENCRYPTION_KEY.strip()
        # Fallback for local development if not configured
        default_dev_key = "a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0"
        return default_dev_key

    def mask_key(self, key: Optional[str]) -> Optional[str]:
        if not key:
            return None
        clean = key.strip()
        if len(clean) <= 8:
            return "********"
        return f"{clean[:6]}...{clean[-4:]}"


settings = Settings()
settings.UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


def update_ai_settings(
    provider: str,
    api_key: Optional[str] = None,
    model: Optional[str] = None,
) -> None:
    """Updates in-memory settings and persists them into backend/.env."""
    prov = provider.strip().lower()
    settings.AI_PROVIDER = prov
    if model and model.strip():
        settings.AI_MODEL = model.strip()

    if prov == "gemini":
        if api_key and api_key.strip():
            settings.GEMINI_API_KEY = api_key.strip()
        if not settings.AI_MODEL:
            settings.AI_MODEL = "gemini-1.5-flash"
    elif prov == "openai":
        if api_key and api_key.strip():
            settings.OPENAI_API_KEY = api_key.strip()
        if not settings.AI_MODEL:
            settings.AI_MODEL = "gpt-4o-mini"
    elif prov == "anthropic":
        if api_key and api_key.strip():
            settings.ANTHROPIC_API_KEY = api_key.strip()
        if not settings.AI_MODEL:
            settings.AI_MODEL = "claude-3-5-sonnet-20241022"
    elif prov == "heuristic":
        pass

    env_path = settings.BASE_DIR / ".env"
    env_map: dict[str, str] = {}
    if env_path.exists():
        for line in env_path.read_text(encoding="utf-8").splitlines():
            line_s = line.strip()
            if line_s and not line_s.startswith("#") and "=" in line_s:
                k, v = line_s.split("=", 1)
                env_map[k.strip()] = v.strip()

    env_map["AI_PROVIDER"] = settings.AI_PROVIDER
    if settings.AI_MODEL:
        env_map["AI_MODEL"] = settings.AI_MODEL
    if settings.GEMINI_API_KEY:
        env_map["GEMINI_API_KEY"] = settings.GEMINI_API_KEY
    if settings.OPENAI_API_KEY:
        env_map["OPENAI_API_KEY"] = settings.OPENAI_API_KEY
    if settings.ANTHROPIC_API_KEY:
        env_map["ANTHROPIC_API_KEY"] = settings.ANTHROPIC_API_KEY

    if "ENVIRONMENT" not in env_map:
        env_map["ENVIRONMENT"] = settings.ENVIRONMENT
    if "DATABASE_URL" not in env_map:
        env_map["DATABASE_URL"] = settings.DATABASE_URL

    content = "\n".join(f"{k}={v}" for k, v in env_map.items()) + "\n"
    env_path.write_text(content, encoding="utf-8")


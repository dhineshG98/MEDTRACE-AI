"""AI settings request and response schemas."""

from typing import Optional
from pydantic import BaseModel


class AiConfigResponse(BaseModel):
    configured: bool
    provider: str
    model: str
    has_gemini_key: bool
    has_openai_key: bool
    has_anthropic_key: bool
    masked_key: Optional[str] = None
    status_message: str


class AiConfigUpdateRequest(BaseModel):
    provider: str  # "gemini", "openai", "anthropic", "heuristic", or "auto"
    api_key: Optional[str] = None
    model: Optional[str] = None


class AiTestRequest(BaseModel):
    provider: Optional[str] = None
    api_key: Optional[str] = None
    model: Optional[str] = None


class AiTestResponse(BaseModel):
    success: bool
    provider: str
    model: str
    message: str
    latency_ms: int

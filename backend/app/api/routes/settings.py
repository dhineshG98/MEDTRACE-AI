"""AI settings management and diagnostic endpoints."""

from fastapi import APIRouter, HTTPException
from app.config.settings import settings, update_ai_settings
from app.schemas.settings import (
    AiConfigResponse,
    AiConfigUpdateRequest,
    AiTestRequest,
    AiTestResponse,
)
from app.services.ai_service import test_ai_connection

router = APIRouter(prefix="/settings", tags=["settings"])


def _build_config_response() -> AiConfigResponse:
    prov = settings.resolved_ai_provider
    is_cloud = settings.ai_configured
    status_msg = (
        f"Active: {prov.title()} ({settings.resolved_ai_model})"
        if is_cloud
        else "Active: Offline Heuristic Clinical Engine"
    )
    return AiConfigResponse(
        configured=is_cloud,
        provider=prov,
        model=settings.resolved_ai_model,
        has_gemini_key=bool(settings.GEMINI_API_KEY),
        has_openai_key=bool(settings.OPENAI_API_KEY),
        has_anthropic_key=bool(settings.ANTHROPIC_API_KEY),
        masked_key=settings.mask_key(settings.resolved_ai_key),
        status_message=status_msg,
    )


@router.get("/ai-config", response_model=AiConfigResponse, summary="Get AI provider configuration")
async def get_ai_config() -> AiConfigResponse:
    """Returns current AI provider configuration and masked credentials status."""
    return _build_config_response()


@router.post("/ai-config", response_model=AiConfigResponse, summary="Update AI provider configuration")
async def update_ai_config(req: AiConfigUpdateRequest) -> AiConfigResponse:
    """Updates AI provider credentials in memory and persists to backend/.env."""
    try:
        update_ai_settings(
            provider=req.provider,
            api_key=req.api_key,
            model=req.model,
        )
        return _build_config_response()
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to persist AI configuration: {str(exc)}",
        ) from exc


@router.post("/ai-test", response_model=AiTestResponse, summary="Test AI provider connection")
async def test_ai_endpoint(req: AiTestRequest) -> AiTestResponse:
    """Sends a lightweight probe to the specified AI provider and measures latency."""
    prov = req.provider or settings.resolved_ai_provider
    key = req.api_key or settings.resolved_ai_key
    model = req.model or settings.resolved_ai_model

    success, msg, latency = test_ai_connection(
        provider=prov,
        api_key=key,
        model=model,
    )

    return AiTestResponse(
        success=success,
        provider=prov,
        model=model,
        message=msg,
        latency_ms=latency,
    )

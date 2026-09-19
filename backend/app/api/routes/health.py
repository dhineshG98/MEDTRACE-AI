"""Health endpoints."""

from fastapi import APIRouter

from app.config.settings import settings
from app.database.database import check_connection
from app.services import document_service
from app.schemas.response import ComponentStatus, DetailedHealthResponse, HealthResponse

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse, summary="Liveness check")
async def health() -> HealthResponse:
    """Cheap liveness probe. The Flutter client calls this on startup."""
    return HealthResponse(status="ok", service="MedTrace AI Backend")


@router.get(
    "/health/detailed",
    response_model=DetailedHealthResponse,
    summary="Readiness check with component status",
)
async def health_detailed() -> DetailedHealthResponse:
    """Reports which subsystems are actually usable.

    Never fails the request -- a degraded component is reported, not raised,
    so the dashboard can show what is missing.
    """
    components: list[ComponentStatus] = []

    db_ok, dialect = check_connection()
    components.append(
        ComponentStatus(
            name="database",
            available=db_ok,
            detail=f"{dialect} reachable" if db_ok else f"{dialect} unreachable",
        )
    )

    ai_prov = settings.resolved_ai_provider
    components.append(
        ComponentStatus(
            name="ai_provider",
            available=True,
            detail=(
                f"{ai_prov} (cloud active)"
                if settings.ai_configured
                else f"{ai_prov} (clinical fallback active)"
            ),
        )
    )

    components.append(
        ComponentStatus(
            name="upload_dir",
            available=settings.UPLOAD_DIR.is_dir(),
            detail=str(settings.UPLOAD_DIR),
        )
    )

    for name, (ok, detail) in document_service.capabilities().items():
        components.append(ComponentStatus(name=f"extractor_{name}", available=ok, detail=detail))

    overall = "ok" if db_ok else "degraded"
    return DetailedHealthResponse(
        status=overall,
        service=settings.APP_NAME,
        version=settings.APP_VERSION,
        environment=settings.ENVIRONMENT,
        components=components,
    )

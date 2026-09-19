"""MedTrace AI backend -- application entry point.

Run locally:
    uvicorn app.main:app --reload --port 8000
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.routes import documents, health, settings as settings_api
from app.config.settings import settings
from app.database.init_db import init_db
from app.utils.logger import configure_logging, get_logger

configure_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting %s v%s (%s)", settings.APP_NAME, settings.APP_VERSION, settings.ENVIRONMENT)
    try:
        init_db()
    except Exception as exc:  # noqa: BLE001
        # A missing database must not stop the process. /api/health/detailed
        # will report it as degraded so the cause is visible.
        logger.error("Database initialisation failed: %s", type(exc).__name__)
    logger.info("Upload directory: %s", settings.UPLOAD_DIR)
    yield
    logger.info("Shutting down %s", settings.APP_NAME)


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description=(
            "Medical document intelligence API. Extracts and structures "
            "information from medical documents. This service performs document "
            "understanding only -- it does not diagnose, prescribe, or make "
            "clinical decisions. All output requires professional review."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
        lifespan=lifespan,
    )

    # --- CORS --------------------------------------------------------
    if settings.is_production and "*" in settings.cors_origins:
        raise RuntimeError("Wildcard CORS origin is not allowed in production")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )

    # --- Healthcare Security Headers & Anti-Caching Middleware -------
    @app.middleware("http")
    async def add_security_headers(request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains; preload"
        response.headers["Content-Security-Policy"] = "upgrade-insecure-requests; default-src 'self' https: data: blob: 'unsafe-inline' 'unsafe-eval'"
        response.headers["X-Security-Cipher"] = "AES-256-GCM + TLS-1.3"
        response.headers["X-Transfer-Protocol"] = "HTTPS" if request.url.scheme == "https" else "HTTP-to-HTTPS-Ready"

        # Strictly prevent caching of decrypted medical records and PHI
        if request.url.path.startswith("/api/documents"):
            response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
            response.headers["Pragma"] = "no-cache"

        return response

    # --- Routers -----------------------------------------------------
    app.include_router(health.router, prefix=settings.API_PREFIX)
    app.include_router(documents.router, prefix=settings.API_PREFIX)
    app.include_router(settings_api.router, prefix=settings.API_PREFIX)

    # --- Error handlers ----------------------------------------------
    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": f"http_{exc.status_code}",
                "message": str(exc.detail),
                "details": None,
            },
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        return JSONResponse(
            status_code=422,
            content={
                "error": "validation_error",
                "message": "The request could not be validated.",
                "details": [
                    {"field": ".".join(str(p) for p in e["loc"]), "issue": e["msg"]}
                    for e in exc.errors()
                ],
            },
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        # Log the type and path only. No stack trace goes to the client, and
        # no request body (which may contain medical content) is logged.
        logger.exception("Unhandled error on %s %s", request.method, request.url.path)
        return JSONResponse(
            status_code=500,
            content={
                "error": "internal_server_error",
                "message": "Something went wrong on the server. Please try again.",
                "details": None,
            },
        )

    @app.get("/", include_in_schema=False)
    async def root():
        return {
            "service": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "docs": "/docs",
            "health": f"{settings.API_PREFIX}/health",
        }

    @app.get("/health", include_in_schema=False)
    async def root_health():
        return await health.health()

    return app


app = create_app()

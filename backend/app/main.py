"""
AI Crop Disease Diagnosis System - FastAPI Backend

Main application entry point with all routers and middleware.
"""
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.config import get_settings
from app.database import init_db, close_db, init_data
from app.utils.logger import logger

# Import all models to ensure they are registered with Base before create_all
from app.models import (
    User, Diagnosis, Question, Answer, SystemLog, SystemMetric,
    MarketPrice, CommunityPost, CommunityComment, PostLike,
    FarmCrop, FarmTask, CropInfo, DiseaseInfo, PestInfo
)

from app.auth.routes import router as auth_router
from app.routes.farmer import router as farmer_router, questions_router
from app.routes.expert import router as expert_router
from app.routes.admin import router as admin_router
from app.routes.market import router as market_router
from app.routes.community import router as community_router
from app.routes.farm import router as farm_router
from app.routes.encyclopedia import router as encyclopedia_router
from app.middleware.logging import SystemLoggingMiddleware

settings = get_settings()
cloudinary_enabled = all([
    settings.cloudinary_cloud_name,
    settings.cloudinary_api_key,
    settings.cloudinary_api_secret,
])

# ── Rate Limiter ──────────────────────────────────────────────────────────────
limiter = Limiter(key_func=get_remote_address, default_limits=["60/minute"])


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan handler.
    Initializes database on startup, closes on shutdown.
    """
    logger.info("Starting up AI Crop Disease Diagnosis System...")

    # Create local upload directories only when Cloudinary is not configured
    if not cloudinary_enabled:
        upload_dir = Path(settings.upload_dir)
        upload_dir.mkdir(parents=True, exist_ok=True)
        (upload_dir / "images").mkdir(exist_ok=True)
        (upload_dir / "videos").mkdir(exist_ok=True)
        (upload_dir / "questions").mkdir(exist_ok=True)

    # Initialize database
    await init_db()
    logger.info("Database initialized")

    # Initialize default data
    await init_data()

    # ── Render keep-alive: self-ping every 10 min to prevent spin-down ────────
    import asyncio
    import httpx

    keep_alive_task = None
    ping_url = (settings.render_external_url or "").rstrip("/")
    if ping_url:
        async def _keep_alive():
            # Wait a bit after startup before first ping
            await asyncio.sleep(60)
            while True:
                try:
                    async with httpx.AsyncClient(timeout=10) as client:
                        resp = await client.get(f"{ping_url}/health")
                        logger.info(f"Keep-alive ping → {resp.status_code}")
                except Exception as exc:
                    logger.warning(f"Keep-alive ping failed: {exc}")
                await asyncio.sleep(10 * 60)  # 10 minutes

        keep_alive_task = asyncio.create_task(_keep_alive())
        logger.info(f"Keep-alive task started → pinging {ping_url}/health every 14 min")
    else:
        logger.info("Keep-alive disabled (RENDER_EXTERNAL_URL not set)")

    yield

    # Shutdown
    if keep_alive_task:
        keep_alive_task.cancel()
    logger.info("Shutting down...")
    await close_db()


# Create FastAPI application
app = FastAPI(
    title=settings.app_name,
    description="""
    ## AI-Powered Crop Disease Diagnosis System
    
    This API provides:
    - **Farmers**: Upload crop images for disease diagnosis, get treatment recommendations
    - **Experts**: Answer farmer questions, provide agricultural guidance
    - **Admins**: Manage users, approve experts, monitor system health
    
    ### Authentication
    All endpoints (except health check) require JWT Bearer token authentication.
    
    ### Roles
    - `FARMER`: Can diagnose crops and ask questions
    - `EXPERT`: Can answer questions (after approval)
    - `ADMIN`: Full system access
    """,
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── Middleware (order matters: outermost first) ───────────────────────────────

# Rate limiting middleware — 60 req/min per IP by default
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# Admin dashboard DB logging middleware (unchanged — writes to SystemLog table)
app.add_middleware(SystemLoggingMiddleware)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Exception Handlers ────────────────────────────────────────────────────────

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle uncaught exceptions — logs to file via loguru (NOT to admin DB)."""
    logger.exception(
        f"Unhandled exception on {request.method} {request.url.path}: {exc}"
    )
    settings = get_settings()
    detail = str(exc) if settings.debug else "An unexpected error occurred. Please try again later."
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": detail}
    )


# ── Health Check ──────────────────────────────────────────────────────────────

@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint."""
    from app.services.ml_service import get_ml_service
    ml = get_ml_service()
    if ml.interpreter is not None:
        model_used = f"TFLite-v{ml._model_version} (Disease_Classification_v2_compressed.tflite)"
    elif ml.keras_model is not None:
        model_used = f"Keras-v{ml._model_version}"
    else:
        model_used = "none (load failed)"
    return {
        "status": "healthy",
        "service": settings.app_name,
        "version": "1.0.0",
        "model_used": model_used,
    }


# ── Routers ───────────────────────────────────────────────────────────────────

app.include_router(auth_router)
app.include_router(farmer_router)
app.include_router(questions_router)
app.include_router(expert_router)
app.include_router(admin_router)
app.include_router(market_router)
app.include_router(community_router)
app.include_router(farm_router)
app.include_router(encyclopedia_router)

# Agronomy Router
from app.agronomy.routes import router as agronomy_router
app.include_router(agronomy_router)

# Mount static files for uploads
uploads_path = Path(settings.upload_dir)
if not cloudinary_enabled and uploads_path.exists():
    app.mount("/uploads", StaticFiles(directory=str(uploads_path)), name="uploads")


# ── Root ──────────────────────────────────────────────────────────────────────

@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Welcome to AI Crop Disease Diagnosis System API",
        "docs": "/docs",
        "health": "/health",
        "version": "1.0.0"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
    )

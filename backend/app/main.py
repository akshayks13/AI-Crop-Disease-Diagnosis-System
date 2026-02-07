"""
AI Crop Disease Diagnosis System - FastAPI Backend

Main application entry point with all routers and middleware.
"""
import logging
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.config import get_settings
from app.database import init_db, close_db, init_data

# Import all models to ensure they are registered with Base before create_all
from app.models import (
    User, Diagnosis, Question, Answer, SystemLog, SystemMetric,
    MarketPrice, CommunityPost, CommunityComment, PostLike,
    FarmCrop, FarmTask, CropInfo, DiseaseInfo
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

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan handler.
    Initializes database on startup, closes on shutdown.
    """
    logger.info("Starting up AI Crop Disease Diagnosis System...")
    
    # Create upload directories
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
    
    yield
    
    # Shutdown
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

# Add System Logging Middleware
app.add_middleware(SystemLoggingMiddleware)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle uncaught exceptions."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected error occurred. Please try again later."}
    )


# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint.
    Returns OK if the service is running.
    """
    return {
        "status": "healthy",
        "service": settings.app_name,
        "version": "1.0.0"
    }


# Include routers
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

# Mount static files for uploads (if needed for direct access)
# In production, use CDN or S3
uploads_path = Path(settings.upload_dir)
if uploads_path.exists():
    app.mount("/uploads", StaticFiles(directory=str(uploads_path)), name="uploads")


# Root endpoint
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

"""
Menu Intelligence System - FastAPI Application
"""
from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path

from app.core.config import settings
from app.api.v1.api import api_router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Pre-warm ML model and DB connection so the first request is fast."""
    logger.info("[startup] Loading embedding model and warming up services...")
    try:
        from app.services.nlp.embedding_service import get_embedding_service
        from app.services.nlp.rag_service import get_rag_service
        get_embedding_service()   # loads SentenceTransformer into memory
        get_rag_service()         # initialises QueryParser + caches Groq client
        logger.info("[startup] Services ready ✓")
    except Exception as e:
        logger.warning(f"[startup] Pre-warm failed (non-fatal): {e}")
    yield
    # Shutdown: nothing to teardown for now

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI-powered menu digitization and intelligent food discovery system",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # Public API — wildcard is fine without credentials
    allow_credentials=False,   # MUST be False when using "*" wildcard (browser rule)
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create upload directory if it doesn't exist
upload_dir = Path(settings.UPLOAD_DIR)
upload_dir.mkdir(parents=True, exist_ok=True)

# Mount static files for uploaded images
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

# Include API router
app.include_router(api_router, prefix="/api/v1")


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Menu Intelligence System API",
        "version": settings.APP_VERSION,
        "docs": "/api/docs"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "version": settings.APP_VERSION
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )

import asyncio
import logging
import os
from contextlib import asynccontextmanager
from datetime import datetime

import uvicorn
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded

from api.routes.admin import router as admin_router
from api.routes.ai import router as ai_router
from api.routes.auth import router as auth_router
from api.routes.llm_orchestration import router as llm_router
from api.routes.tiers import router as tiers_router
from api.routes.users import router as users_router
from api.routes.workouts import router as workouts_router
from core.config import get_settings
from core.function_client import FunctionsClient
from core.function_performance import perf_monitor
from core.llm_orchestration_init import (
    initialize_llm_orchestration,
    shutdown_llm_orchestration,
)
from core.security import (
    InputValidationError,
    SecurityAuditLogger,
    SecurityMiddleware,
    limiter,
    rate_limit_handler,
    secure_health_check,
)
from database.connection import init_db
from infrastructure.observability.otel_middleware import OTelMiddleware

settings = get_settings()
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    try:
        print("✅ Database tables initialized successfully")
        init_db()

        # Initialize LLM Orchestration Layer
        print("🔧 Initializing enterprise LLM orchestration layer...")
        await initialize_llm_orchestration()
        print("✅ LLM Orchestration Layer initialized successfully")

        # Initialize Azure Functions warmup tasks if enabled
        if os.environ.get("USE_FUNCTIONS", "true").lower() == "true":
            print("🔥 Starting Azure Functions warmup tasks...")
            function_client = FunctionsClient()

            # Create background tasks attribute for keeping functions warm
            if not hasattr(app, "warmup_tasks"):
                app.warmup_tasks = []  # type: ignore

            # Warmup task for GenerateWorkout function
            warmup_generate = asyncio.create_task(
                perf_monitor.keep_warm(
                    warmup_func=lambda: function_client.generate_workout_plan(
                        fitness_level="beginner",
                        goals=["General fitness"],
                        duration_minutes=30,
                    ),
                    function_name="generate-workout",
                    interval=4 * 60,  # 4 minutes to prevent cold starts
                )
            )
            app.warmup_tasks.append(warmup_generate)

            # Warmup task for CoachChat function
            warmup_chat = asyncio.create_task(
                perf_monitor.keep_warm(
                    warmup_func=lambda: function_client.coach_chat(
                        message="Hello",
                        fitness_level="beginner",
                        goals=["General fitness"],
                    ),
                    function_name="coach-chat",
                    interval=4 * 60,  # 4 minutes to prevent cold starts
                )
            )
            app.warmup_tasks.append(warmup_chat)

            print("✅ Azure Functions warmup tasks started")

        print(f"🚀 {settings.APP_NAME} v{settings.APP_VERSION} starting up...")
        print(f"📊 Environment: {settings.ENVIRONMENT}")
        print(f"🤖 LLM Provider: {settings.LLM_PROVIDER}")
        print(f"🔧 Debug mode: {settings.DEBUG}")
        print("🔒 Security features: Rate limiting, Input validation, Audit logging")

        logger.info("Environment: %s", settings.ENVIRONMENT)
        logger.info("Debug mode: %s", settings.DEBUG)
        logger.info("Database URL configured: %s", bool(settings.DATABASE_URL))
        logger.info("Application startup completed")

    except Exception as e:
        print(f"❌ Startup failed: {e}")
        raise

    yield

    # Shutdown
    try:
        print("👋 Vigor shutting down...")
        await shutdown_llm_orchestration()
    except Exception as e:
        print(f"❌ Shutdown error: {e}")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI-Powered Fitness Coaching Platform with Enterprise LLM Orchestration and Production Security",
    lifespan=lifespan,
)

# Add security middleware (FIRST - order matters!)
app.add_middleware(SecurityMiddleware)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OpenTelemetry middleware
app.add_middleware(OTelMiddleware)

# Add rate limiting state
app.state.limiter = limiter


# Enhanced Error Handlers
@app.exception_handler(RateLimitExceeded)
async def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded):
    """Handle rate limit exceeded with proper logging"""
    return await rate_limit_handler(request, exc)


@app.exception_handler(InputValidationError)
async def input_validation_error_handler(request: Request, exc: InputValidationError):
    """Handle input validation errors"""
    await SecurityAuditLogger.log_suspicious_activity(
        request, "input_validation_failed", {"error": exc.detail}
    )
    return JSONResponse(status_code=exc.status_code, content=exc.detail)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle Pydantic validation errors"""

    # Clean error details to ensure JSON serialization
    def make_serializable(obj):
        """Convert objects to JSON-serializable format"""
        if isinstance(obj, bytes):
            return f"<bytes: {len(obj)} bytes>"
        elif isinstance(obj, dict):
            return {k: make_serializable(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [make_serializable(item) for item in obj]
        elif hasattr(obj, "__dict__"):
            return str(obj)
        else:
            return obj

    # Process error details to make them serializable
    cleaned_errors = []
    for error in exc.errors():
        cleaned_error = make_serializable(error)
        cleaned_errors.append(cleaned_error)

    await SecurityAuditLogger.log_suspicious_activity(
        request, "request_validation_failed", {"errors": cleaned_errors}
    )

    return JSONResponse(
        status_code=422,
        content={
            "error": "validation_error",
            "message": "Invalid request data",
            "details": cleaned_errors,
            "timestamp": datetime.utcnow().isoformat(),
        },
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for production safety"""
    import traceback

    # Log the full error for debugging
    logger.error(f"Unhandled exception: {exc}")
    logger.error(f"Traceback: {traceback.format_exc()}")

    # Log security event
    await SecurityAuditLogger.log_suspicious_activity(
        request,
        "unhandled_exception",
        {
            "exception_type": type(exc).__name__,
            "exception_message": str(exc)[:500],  # Limit message length
        },
    )

    # Return safe error response (don't expose internal details)
    if settings.DEBUG:
        return JSONResponse(
            status_code=500,
            content={
                "error": "internal_server_error",
                "message": str(exc),
                "timestamp": datetime.utcnow().isoformat(),
                "type": type(exc).__name__,
            },
        )
    else:
        return JSONResponse(
            status_code=500,
            content={
                "error": "internal_server_error",
                "message": "An unexpected error occurred",
                "timestamp": datetime.utcnow().isoformat(),
            },
        )


# Enhanced Health Check Endpoint
@app.get("/health", summary="Health Check", tags=["System"])
@limiter.limit("10/minute")  # Protect health endpoint from abuse
async def health_check(request: Request):
    """
    Enhanced health check endpoint with security monitoring
    Returns system health without exposing sensitive information
    """
    try:
        health_data = await secure_health_check()
        return health_data
    except Exception as e:
        # Log health check failures
        await SecurityAuditLogger.log_suspicious_activity(
            request, "health_check_failed", {"error": str(e)}
        )
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "timestamp": datetime.utcnow().isoformat(),
                "error": "Health check failed",
            },
        )


# Root endpoint with security awareness
@app.get("/", summary="API Information", tags=["System"])
@limiter.limit("100/minute")
async def root(request: Request):
    """API root endpoint with feature overview"""
    return {
        "message": f"Welcome to {settings.APP_NAME} API",
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "features": [
            "🤖 Enterprise LLM Orchestration",
            "🔐 Advanced Security & Rate Limiting",
            "🔑 Secure Key Vault Integration",
            "💰 Intelligent Budget Management",
            "⚡ High-Performance Caching",
            "🛡️ Circuit Breaker Protection",
            "📊 Comprehensive Analytics & Monitoring",
            "🔍 Security Audit Logging",
        ],
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "llm_status": "/llm/status",
            "admin_models": "/llm/admin/models",
        },
        "security": {
            "rate_limiting": "enabled",
            "input_validation": "enabled",
            "audit_logging": "enabled",
            "cors_protection": "enabled",
        },
        "timestamp": datetime.utcnow().isoformat(),
    }


# Include routers with rate limiting applied
app.include_router(auth_router, prefix="/auth", tags=["Authentication"])
app.include_router(users_router, prefix="/users", tags=["Users"])
app.include_router(workouts_router, prefix="/workouts", tags=["Workouts"])
app.include_router(ai_router, prefix="/ai", tags=["AI"])
app.include_router(admin_router, prefix="/admin", tags=["Administration"])
app.include_router(llm_router, prefix="/llm", tags=["LLM Orchestration"])
app.include_router(tiers_router, prefix="/tiers", tags=["User Tiers"])

if __name__ == "__main__":
    # Binding to 0.0.0.0 is required for containerized applications
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        access_log=True,
        use_colors=True,
    )

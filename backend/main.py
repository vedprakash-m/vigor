import asyncio
import os
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Optional

import uvicorn
from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

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
from database.connection import init_db
from infrastructure.observability.otel_middleware import OTelMiddleware

settings = get_settings()


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
    description="AI-Powered Fitness Coaching Platform with Enterprise LLM Orchestration",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(OTelMiddleware)


# Error handling
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    return JSONResponse(
        status_code=422,
        content={"detail": str(exc)},
    )


# Health check
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
    }


@app.get("/health/database")
async def health_check_database():
    """Check database connectivity"""
    try:
        from database.connection import get_db

        db = next(get_db())
        # Simple query to test database connection
        db.execute("SELECT 1")
        return {
            "status": "healthy",
            "service": "database",
            "timestamp": datetime.utcnow().isoformat(),
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "service": "database",
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat(),
        }


@app.get("/health/llm")
async def health_check_llm():
    """Check LLM orchestration system health"""
    try:
        from core.llm_orchestration_init import get_llm_gateway

        gateway = get_llm_gateway()
        provider_status = await gateway.get_provider_status()
        return {
            "status": (
                "healthy" if provider_status.get("is_healthy", False) else "degraded"
            ),
            "service": "llm",
            "providers": provider_status,
            "timestamp": datetime.utcnow().isoformat(),
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "service": "llm",
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat(),
        }


# Models
class UserBase(BaseModel):
    email: str
    username: str


class UserCreate(UserBase):
    password: str


class User(UserBase):
    id: str
    is_active: bool = True


# Routes will be added here
# - Auth routes
# - User routes
# - Workout routes
# - AI coaching routes
# - Admin routes

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(workouts_router)
app.include_router(ai_router)
app.include_router(admin_router)
app.include_router(llm_router)
app.include_router(tiers_router)


@app.get("/")
async def root():
    return {
        "message": f"Welcome to {settings.APP_NAME} API",
        "version": settings.APP_VERSION,
        "features": [
            "🤖 Enterprise LLM Orchestration",
            "🔐 Secure Key Vault Integration",
            "💰 Intelligent Budget Management",
            "⚡ High-Performance Caching",
            "🛡️ Circuit Breaker Protection",
            "📊 Comprehensive Analytics",
        ],
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "llm_status": "/llm/status",
            "admin_models": "/llm/admin/models",
        },
    }


if __name__ == "__main__":
    # Binding to 0.0.0.0 is required for containerized applications
    uvicorn.run(
        "main:app", host="0.0.0.0", port=8000, reload=settings.DEBUG  # nosec B104
    )

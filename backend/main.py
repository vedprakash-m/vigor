from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import BaseModel
from typing import Optional
import uvicorn
from api.routes.auth import router as auth_router
from api.routes.users import router as users_router
from api.routes.workouts import router as workouts_router
from api.routes.ai import router as ai_router
from api.routes.admin import router as admin_router
from contextlib import asynccontextmanager

from core.config import get_settings
from database.connection import init_db

settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    init_db()
    print(f"🚀 {settings.APP_NAME} v{settings.APP_VERSION} starting up...")
    print(f"📊 Environment: {settings.ENVIRONMENT}")
    print(f"🤖 LLM Provider: {settings.LLM_PROVIDER}")
    print(f"🔧 Debug mode: {settings.DEBUG}")
    
    yield
    
    # Shutdown
    print("👋 Vigor shutting down...")

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI-Powered Fitness Coaching Platform with Cost-Optimized Multi-LLM Support",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
        "environment": settings.ENVIRONMENT
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

@app.get("/")
async def root():
    return {
        "message": f"Welcome to {settings.APP_NAME} API",
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "health": "/health"
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    ) 
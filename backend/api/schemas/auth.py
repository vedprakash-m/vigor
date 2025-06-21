from datetime import datetime

from pydantic import BaseModel, EmailStr, Field
from typing import Optional, Union, List


class UserRegister(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)
    fitness_level: str = Field(..., pattern="^(beginner|intermediate|advanced)$")
    goals: List[str]
    equipment: str = Field(..., pattern="^(none|minimal|moderate|full)$")


class UserRegistration(BaseModel):
    """Alias for UserRegister for backward compatibility"""
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)
    fitness_level: str = Field(..., pattern="^(beginner|intermediate|advanced)$")
    goals: List[str]
    equipment: str = Field(..., pattern="^(none|minimal|moderate|full)$")


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime


class TokenData(BaseModel):
    user_id: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    email: EmailStr
    username: str
    fitness_level: str
    goals: List[str]
    equipment: str
    user_tier: str = "free"
    monthly_budget: float = 5.0
    current_month_usage: float = 0.0
    created_at: datetime
    updated_at: datetime

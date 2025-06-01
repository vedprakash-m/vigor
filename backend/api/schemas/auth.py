from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserRegister(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)
    fitness_level: str = Field(..., pattern="^(beginner|intermediate|advanced)$")
    goals: list[str]
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
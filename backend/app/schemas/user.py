"""
User Schemas - Pydantic models for user operations
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    """Schema for creating a new user."""
    email: EmailStr
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., min_length=1, max_length=255)
    phone: Optional[str] = None
    location: Optional[str] = None


class UserUpdate(BaseModel):
    """Schema for updating user profile."""
    full_name: Optional[str] = None
    phone: Optional[str] = None
    location: Optional[str] = None
    expertise_domain: Optional[str] = None
    qualification: Optional[str] = None
    experience_years: Optional[int] = None


class UserResponse(BaseModel):
    """Schema for user response."""
    id: str
    email: str
    full_name: str
    phone: Optional[str]
    role: str
    status: str
    expertise_domain: Optional[str]
    qualification: Optional[str]
    experience_years: Optional[int]
    location: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class UserListResponse(BaseModel):
    """Schema for paginated user list."""
    users: List[UserResponse]
    total: int
    page: int
    page_size: int

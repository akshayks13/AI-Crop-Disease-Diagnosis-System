"""
Authentication Routes - Login, Register, and Token Refresh
"""
import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field, validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.auth.jwt_handler import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.config import get_settings
from app.database import get_db
from app.models.user import User, UserRole, UserStatus

# Setup router and logger
router = APIRouter(prefix="/auth", tags=["Authentication"])
from app.auth.utils import generate_and_send_otp



# ============== Schemas ==============

class UserRegisterRequest(BaseModel):
    """User registration request schema."""
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)
    full_name: str = Field(..., min_length=1, max_length=255)
    phone: Optional[str] = Field(None, max_length=20)
    role: UserRole = Field(default=UserRole.FARMER)
    
    # Expert-specific fields
    expertise_domain: Optional[str] = None
    qualification: Optional[str] = None
    experience_years: Optional[int] = None
    location: Optional[str] = None
    
    @validator("role")
    def validate_role(cls, v):
        """Users cannot register as admin."""
        if v == UserRole.ADMIN:
            raise ValueError("Cannot register as admin")
        return v


class UserLoginRequest(BaseModel):
    """User login request schema."""
    email: EmailStr
    password: str


class VerifyOtpRequest(BaseModel):
    """OTP verification request."""
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6)


class RefreshTokenRequest(BaseModel):
    """Refresh token request schema."""
    refresh_token: str


class UserUpdateRequest(BaseModel):
    """User profile update request."""
    full_name: Optional[str] = Field(None, min_length=1, max_length=255)
    phone: Optional[str] = Field(None, max_length=20)
    location: Optional[str] = None
    expertise_domain: Optional[str] = None
    qualification: Optional[str] = None
    experience_years: Optional[int] = None


class UserResponse(BaseModel):
    """User response schema."""
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


class TokenResponse(BaseModel):
    """Token response schema."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: dict


class ForgotPasswordRequest(BaseModel):
    """Forgot password request schema."""
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    """Reset password request schema."""
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=6, max_length=128)


# ============== Routes ==============

@router.post("/forgot-password", status_code=status.HTTP_200_OK)
async def forgot_password(
    request: ForgotPasswordRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Request password reset OTP.
    """
    # Check if user exists
    result = await db.execute(
        select(User).where(User.email == request.email)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        # Don't reveal if user exists or not for security
        # But for this project, we'll return success anyway
        return {"message": "If email exists, OTP sent."}
    
    # Generate OTP
    otp = generate_and_send_otp(user.email)
    
    user.otp_code = otp
    user.otp_created_at = datetime.utcnow()
    
    await db.commit()
    
    return {"message": "OTP sent successfully."}


@router.post("/reset-password", status_code=status.HTTP_200_OK)
async def reset_password(
    request: ResetPasswordRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Reset password using OTP.
    """
    # Find user
    result = await db.execute(
        select(User).where(User.email == request.email)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
        
    if not user.otp_code or user.otp_code != request.otp:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP"
        )
    
    # Update password
    user.password_hash = hash_password(request.new_password)
    user.otp_code = None
    user.otp_created_at = None
    # Also verify user if not already, since they proved ownership of email
    if not user.is_verified:
        user.is_verified = True
        
    await db.commit()
    
    return {"message": "Password reset successfully. You can now login."}


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register_user(
    request: UserRegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new user (Farmer or Expert).
    
    - Farmers get immediate access
    - Experts are set to PENDING status until admin approval
    """
    # Check if email already exists
    existing = await db.execute(
        select(User).where(User.email == request.email)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )
    
    # Determine initial status
    initial_status = UserStatus.ACTIVE
    if request.role == UserRole.EXPERT:
        initial_status = UserStatus.PENDING
    
    # Generate OTP
    otp = generate_and_send_otp(request.email)
    
    # Create user
    user = User(
        email=request.email,
        password_hash=hash_password(request.password),
        full_name=request.full_name,
        phone=request.phone,
        role=request.role,
        status=initial_status,
        expertise_domain=request.expertise_domain,
        qualification=request.qualification,
        experience_years=request.experience_years,
        location=request.location,
        is_verified=False,
        otp_code=otp,
        otp_created_at=datetime.utcnow(),
    )
    
    db.add(user)
    await db.flush()
    await db.refresh(user)
    
    return {
        "message": "OTP sent successfully. Please verify your email.",
        "email": user.email
    }


@router.post("/verify", response_model=TokenResponse)
async def verify_otp(
    request: VerifyOtpRequest,
    db: AsyncSession = Depends(get_db)
):
    """Verify OTP and return tokens."""
    # Find user
    result = await db.execute(
        select(User).where(User.email == request.email)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.is_verified:
        # If already verified, ensure we return tokens
        pass 
        
    if user.otp_code and user.otp_code != request.otp:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP"
        )
        
    # Verify user
    user.is_verified = True
    user.otp_code = None
    user.otp_created_at = None
    await db.commit()
    await db.refresh(user)
    
    # Generate tokens
    token_data = {"sub": str(user.id), "role": user.role.value}
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    settings = get_settings()
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.access_token_expire_minutes * 60,
        user={
            "id": str(user.id),
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role.value,
            "status": user.status.value,
        }
    )


@router.post("/login", response_model=TokenResponse)
async def login_user(
    request: UserLoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Login with email and password.
    
    Returns JWT access and refresh tokens.
    """
    # Find user by email
    result = await db.execute(
        select(User).where(User.email == request.email)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Verify password
    if not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
        
    # Check verification status
    if not user.is_verified and user.email != "admin@cropdiagnosis.com": # Skip for default admin
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account not verified. Please verify your email."
        )
    
    # Check if suspended
    if user.status == UserStatus.SUSPENDED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account has been suspended"
        )
    
    # Generate tokens
    token_data = {"sub": str(user.id), "role": user.role.value}
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    settings = get_settings()
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.access_token_expire_minutes * 60,
        user={
            "id": str(user.id),
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role.value,
            "status": user.status.value,
        }
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh access token using a valid refresh token.
    """
    payload = decode_token(request.refresh_token)
    
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    
    # Verify token type
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type"
        )
    
    user_id_str = payload.get("sub")
    if not user_id_str:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )
    
    try:
        user_id = uuid.UUID(user_id_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user ID in token"
        )
    
    # Fetch user
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    if user.status == UserStatus.SUSPENDED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account has been suspended"
        )
    
    # Generate new tokens
    token_data = {"sub": str(user.id), "role": user.role.value}
    new_access_token = create_access_token(token_data)
    new_refresh_token = create_refresh_token(token_data)
    
    settings = get_settings()
    
    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        expires_in=settings.access_token_expire_minutes * 60,
        user={
            "id": str(user.id),
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role.value,
            "status": user.status.value,
        }
    )


@router.put("/profile", response_model=UserResponse)
async def update_profile(
    request: UserUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update current user's profile."""
    # Update fields if provided
    if request.full_name is not None:
        current_user.full_name = request.full_name
    if request.phone is not None:
        current_user.phone = request.phone
    if request.location is not None:
        current_user.location = request.location
    if request.expertise_domain is not None:
        current_user.expertise_domain = request.expertise_domain
    if request.qualification is not None:
        current_user.qualification = request.qualification
    if request.experience_years is not None:
        current_user.experience_years = request.experience_years
        
    await db.commit()
    await db.refresh(current_user)
    
    return UserResponse(
        id=str(current_user.id),
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        role=current_user.role.value,
        status=current_user.status.value,
        expertise_domain=current_user.expertise_domain,
        qualification=current_user.qualification,
        experience_years=current_user.experience_years,
        location=current_user.location,
        created_at=current_user.created_at,
    )


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get current authenticated user's profile."""
    return UserResponse(
        id=str(current_user.id),
        email=current_user.email,
        full_name=current_user.full_name,
        phone=current_user.phone,
        role=current_user.role.value,
        status=current_user.status.value,
        expertise_domain=current_user.expertise_domain,
        qualification=current_user.qualification,
        experience_years=current_user.experience_years,
        location=current_user.location,
        created_at=current_user.created_at,
    )

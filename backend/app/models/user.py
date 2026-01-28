"""
User Model - Farmers, Experts, and Admins
"""
import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, TYPE_CHECKING

from sqlalchemy import String, Text, DateTime, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base

if TYPE_CHECKING:
    from app.models.diagnosis import Diagnosis
    from app.models.question import Question, Answer


class UserRole(str, Enum):
    """User role enumeration for RBAC."""
    FARMER = "FARMER"
    EXPERT = "EXPERT"
    ADMIN = "ADMIN"


class UserStatus(str, Enum):
    """User account status."""
    ACTIVE = "ACTIVE"
    PENDING = "PENDING"  # For experts awaiting approval
    SUSPENDED = "SUSPENDED"


class User(Base):
    """
    User model representing farmers, experts, and admins.
    
    Attributes:
        id: Unique identifier (UUID)
        email: User's email address (unique)
        password_hash: Hashed password
        full_name: User's full name
        phone: Phone number
        role: User's role (FARMER, EXPERT, ADMIN)
        status: Account status
        expertise_domain: Expert's area of expertise
        qualification: Expert's qualifications
        experience_years: Years of experience (for experts)
        location: User's location
        created_at: Account creation timestamp
        updated_at: Last update timestamp
    """
    __tablename__ = "users"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )
    password_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )
    full_name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )
    phone: Mapped[Optional[str]] = mapped_column(
        String(20),
        nullable=True,
    )
    role: Mapped[UserRole] = mapped_column(
        SQLEnum(UserRole, native_enum=False),
        nullable=False,
        default=UserRole.FARMER,
    )
    status: Mapped[UserStatus] = mapped_column(
        SQLEnum(UserStatus, native_enum=False),
        nullable=False,
        default=UserStatus.ACTIVE,
    )
    
    # Verification
    is_verified: Mapped[bool] = mapped_column(
        default=False,
        nullable=False,
    )
    otp_code: Mapped[Optional[str]] = mapped_column(
        String(6),
        nullable=True,
    )
    otp_created_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime,
        nullable=True,
    )
    
    # Expert-specific fields
    expertise_domain: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
    )
    qualification: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )
    experience_years: Mapped[Optional[int]] = mapped_column(
        nullable=True,
    )
    
    # Common fields
    location: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )
    
    # Relationships
    diagnoses: Mapped[List["Diagnosis"]] = relationship(
        "Diagnosis",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    questions: Mapped[List["Question"]] = relationship(
        "Question",
        back_populates="farmer",
        foreign_keys="Question.farmer_id",
        cascade="all, delete-orphan",
    )
    answers: Mapped[List["Answer"]] = relationship(
        "Answer",
        back_populates="expert",
        cascade="all, delete-orphan",
    )
    
    def __repr__(self) -> str:
        return f"<User {self.email} ({self.role})>"
    
    @property
    def is_expert_approved(self) -> bool:
        """Check if expert is approved to answer questions."""
        return self.role == UserRole.EXPERT and self.status == UserStatus.ACTIVE
    
    @property
    def is_admin(self) -> bool:
        """Check if user is an admin."""
        return self.role == UserRole.ADMIN

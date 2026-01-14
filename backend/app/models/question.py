"""
Question and Answer Models - Expert Consultation System
"""
import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, TYPE_CHECKING

from sqlalchemy import String, Text, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base

if TYPE_CHECKING:
    from app.models.user import User


class QuestionStatus(str, Enum):
    """Question status enumeration."""
    OPEN = "OPEN"
    RESOLVED = "RESOLVED"
    CLOSED = "CLOSED"


class Question(Base):
    """
    Question model for farmer-expert consultation.
    
    Attributes:
        id: Unique identifier
        farmer_id: Reference to farmer who asked
        media_path: Optional image reference
        question_text: The question content
        status: Current status (OPEN, RESOLVED, CLOSED)
        created_at: Question timestamp
    """
    __tablename__ = "questions"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    farmer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    # Question content
    media_path: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True,
    )
    question_text: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )
    
    # Related diagnosis (optional)
    diagnosis_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("diagnoses.id", ondelete="SET NULL"),
        nullable=True,
    )
    
    status: Mapped[QuestionStatus] = mapped_column(
        SQLEnum(QuestionStatus, native_enum=False),
        nullable=False,
        default=QuestionStatus.OPEN,
    )
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        index=True,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )
    
    # Relationships
    farmer: Mapped["User"] = relationship(
        "User",
        back_populates="questions",
        foreign_keys=[farmer_id],
    )
    answers: Mapped[List["Answer"]] = relationship(
        "Answer",
        back_populates="question",
        cascade="all, delete-orphan",
    )
    
    def __repr__(self) -> str:
        return f"<Question {self.id} ({self.status})>"


class Answer(Base):
    """
    Answer model for expert responses.
    
    Attributes:
        id: Unique identifier
        question_id: Reference to the question
        expert_id: Reference to the expert who answered
        answer_text: The answer content
        created_at: Answer timestamp
    """
    __tablename__ = "answers"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    question_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("questions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    expert_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    answer_text: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )
    
    # Rating from farmer (optional)
    rating: Mapped[Optional[int]] = mapped_column(
        nullable=True,
    )
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
    )
    
    # Relationships
    question: Mapped["Question"] = relationship(
        "Question",
        back_populates="answers",
    )
    expert: Mapped["User"] = relationship(
        "User",
        back_populates="answers",
    )
    
    def __repr__(self) -> str:
        return f"<Answer {self.id} by Expert {self.expert_id}>"

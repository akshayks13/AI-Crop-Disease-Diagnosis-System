"""
Diagnosis Model - Crop Disease Diagnosis Records
"""
import uuid
from datetime import datetime
from typing import Optional, Dict, Any, TYPE_CHECKING

from sqlalchemy import String, Text, Float, DateTime, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base

if TYPE_CHECKING:
    from app.models.user import User


class Diagnosis(Base):
    """
    Diagnosis model storing crop disease detection results.
    
    Attributes:
        id: Unique identifier (UUID)
        user_id: Reference to the farmer who requested diagnosis
        media_path: Path to uploaded image/video
        media_type: Type of media (image/video)
        crop_type: Type of crop being diagnosed
        location: Location where diagnosis was requested
        disease: Detected disease name
        severity: Severity level (mild, moderate, severe)
        confidence: ML model confidence score (0-1)
        treatment: JSON containing treatment recommendations
        prevention: Prevention tips
        warnings: Safety warnings
        created_at: Diagnosis timestamp
    """
    __tablename__ = "diagnoses"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    
    # Media information
    media_path: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
    )
    media_type: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="image",
    )
    
    # Crop information
    crop_type: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True,
    )
    location: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
    )
    
    # Diagnosis results
    disease: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )
    severity: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="moderate",
    )
    confidence: Mapped[float] = mapped_column(
        Float,
        nullable=False,
    )
    
    # Treatment information (JSON)
    treatment: Mapped[Dict[str, Any]] = mapped_column(
        JSON,
        nullable=False,
        default=dict,
    )
    prevention: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )
    warnings: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )
    
    # Additional ML outputs
    additional_diseases: Mapped[Optional[Dict[str, Any]]] = mapped_column(
        JSON,
        nullable=True,
    )
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        index=True,
    )
    
    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="diagnoses",
    )
    
    def __repr__(self) -> str:
        return f"<Diagnosis {self.disease} ({self.severity}) for User {self.user_id}>"
    
    def to_response_dict(self) -> Dict[str, Any]:
        """Convert to API response format."""
        return {
            "id": str(self.id),
            "disease": self.disease,
            "severity": self.severity,
            "confidence": self.confidence,
            "crop_type": self.crop_type,
            "treatment_steps": self.treatment.get("steps", []),
            "chemical_options": self.treatment.get("chemical", []),
            "organic_options": self.treatment.get("organic", []),
            "warnings": self.warnings,
            "prevention": self.prevention,
            "created_at": self.created_at.isoformat(),
        }

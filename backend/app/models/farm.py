"""
Farm Models - SQLAlchemy ORM models for farm management
"""
import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, Text, DateTime, Date, Float, Boolean, Integer, ForeignKey, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import enum

from app.database import Base


class GrowthStage(str, enum.Enum):
    GERMINATION = "germination"
    SEEDLING = "seedling"
    VEGETATIVE = "vegetative"
    FLOWERING = "flowering"
    FRUITING = "fruiting"
    RIPENING = "ripening"
    HARVEST = "harvest"


class TaskPriority(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class FarmCrop(Base):
    """User's farm crop with growth tracking."""
    __tablename__ = "farm_crops"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)  # e.g., "Field 1 - Tomatoes"
    crop_type = Column(String(100), nullable=False)  # e.g., "Tomato"
    field_name = Column(String(100), nullable=True)  # e.g., "Field 1", "Backyard"
    area_size = Column(Float, nullable=True)  # In acres or hectares
    area_unit = Column(String(20), default="acres")
    sow_date = Column(Date, nullable=False)
    expected_harvest_date = Column(Date, nullable=True)
    growth_stage = Column(SQLEnum(GrowthStage), default=GrowthStage.GERMINATION)
    progress = Column(Float, default=0.0)  # 0.0 to 1.0
    notes = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    owner = relationship("User", backref="farm_crops")
    tasks = relationship("FarmTask", back_populates="crop", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<FarmCrop {self.name} - {self.crop_type}>"


class FarmTask(Base):
    """Farming task associated with a crop or general farm work."""
    __tablename__ = "farm_tasks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    crop_id = Column(UUID(as_uuid=True), ForeignKey("farm_crops.id", ondelete="SET NULL"), nullable=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    due_date = Column(DateTime, nullable=True)
    priority = Column(SQLEnum(TaskPriority), default=TaskPriority.MEDIUM)
    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime, nullable=True)
    is_recurring = Column(Boolean, default=False)
    recurrence_days = Column(Integer, nullable=True)  # Repeat every N days
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    owner = relationship("User", backref="farm_tasks")
    crop = relationship("FarmCrop", back_populates="tasks")

    def __repr__(self):
        return f"<FarmTask {self.title}>"

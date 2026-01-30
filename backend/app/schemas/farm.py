"""
Farm Schemas - Pydantic models for farm management API
"""
from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field
from enum import Enum


class GrowthStageSchema(str, Enum):
    GERMINATION = "germination"
    SEEDLING = "seedling"
    VEGETATIVE = "vegetative"
    FLOWERING = "flowering"
    FRUITING = "fruiting"
    RIPENING = "ripening"
    HARVEST = "harvest"


class TaskPrioritySchema(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


# ============== Farm Crop Schemas ==============

class FarmCropCreate(BaseModel):
    """Schema for creating a new crop."""
    name: str = Field(..., min_length=1, max_length=100)
    crop_type: str = Field(..., min_length=1, max_length=100)
    field_name: Optional[str] = Field(None, max_length=100)
    area_size: Optional[float] = Field(None, gt=0)
    area_unit: str = Field(default="acres", max_length=20)
    sow_date: date
    expected_harvest_date: Optional[date] = None
    notes: Optional[str] = None


class FarmCropUpdate(BaseModel):
    """Schema for updating a crop."""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    field_name: Optional[str] = Field(None, max_length=100)
    area_size: Optional[float] = Field(None, gt=0)
    growth_stage: Optional[GrowthStageSchema] = None
    progress: Optional[float] = Field(None, ge=0, le=1)
    expected_harvest_date: Optional[date] = None
    notes: Optional[str] = None
    is_active: Optional[bool] = None


class FarmCropResponse(BaseModel):
    """Response schema for a farm crop."""
    id: str
    name: str
    crop_type: str
    field_name: Optional[str]
    area_size: Optional[float]
    area_unit: str
    sow_date: date
    expected_harvest_date: Optional[date]
    growth_stage: GrowthStageSchema
    progress: float
    notes: Optional[str]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class FarmCropListResponse(BaseModel):
    """List of user's crops."""
    crops: List[FarmCropResponse]
    total: int


# ============== Farm Task Schemas ==============

class FarmTaskCreate(BaseModel):
    """Schema for creating a task."""
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    crop_id: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: TaskPrioritySchema = TaskPrioritySchema.MEDIUM
    is_recurring: bool = False
    recurrence_days: Optional[int] = Field(None, gt=0)


class FarmTaskUpdate(BaseModel):
    """Schema for updating a task."""
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    priority: Optional[TaskPrioritySchema] = None


class FarmTaskResponse(BaseModel):
    """Response schema for a task."""
    id: str
    title: str
    description: Optional[str]
    crop_id: Optional[str]
    crop_name: Optional[str] = None
    due_date: Optional[datetime]
    priority: TaskPrioritySchema
    is_completed: bool
    completed_at: Optional[datetime]
    is_recurring: bool
    recurrence_days: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True


class FarmTaskListResponse(BaseModel):
    """List of tasks."""
    tasks: List[FarmTaskResponse]
    total: int
    completed_count: int
    pending_count: int

"""
Diagnosis Schemas - Pydantic models for diagnosis operations
"""
from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class DiagnosisRequest(BaseModel):
    """Schema for diagnosis request (metadata only, file sent separately)."""
    crop_type: Optional[str] = None
    location: Optional[str] = None


class TreatmentStep(BaseModel):
    """Individual treatment step."""
    step_number: int
    description: str
    timing: Optional[str] = None


class TreatmentOption(BaseModel):
    """Treatment option (chemical or organic)."""
    name: str
    dosage: Optional[str] = None
    application_method: Optional[str] = None
    frequency: Optional[str] = None


class DiagnosisResponse(BaseModel):
    """Schema for diagnosis response."""
    id: str
    disease: str
    severity: str
    confidence: float
    crop_type: Optional[str]
    treatment_steps: List[TreatmentStep]
    chemical_options: List[TreatmentOption]
    organic_options: List[TreatmentOption]
    warnings: Optional[str]
    prevention: Optional[str]
    media_path: str
    created_at: datetime

    class Config:
        from_attributes = True


class DiagnosisListResponse(BaseModel):
    """Schema for paginated diagnosis list."""
    diagnoses: List[DiagnosisResponse]
    total: int
    page: int
    page_size: int


class DiagnosisSummary(BaseModel):
    """Simplified diagnosis for history list."""
    id: str
    disease: str
    severity: str
    confidence: float
    crop_type: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

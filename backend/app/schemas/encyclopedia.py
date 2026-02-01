"""
Encyclopedia Schemas - Pydantic models for crop/disease encyclopedia API
"""
from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


# ============== Crop Info Schemas ==============

class CropInfoCreate(BaseModel):
    """Schema for creating a crop encyclopedia entry (admin only)."""
    name: str = Field(..., min_length=1, max_length=100)
    scientific_name: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = None
    season: Optional[str] = Field(None, max_length=100)
    temp_min: Optional[float] = None
    temp_max: Optional[float] = None
    water_requirement: Optional[str] = Field(None, max_length=50)
    soil_type: Optional[str] = Field(None, max_length=200)
    growing_tips: List[str] = []
    common_varieties: List[str] = []
    common_diseases: List[str] = []
    image_url: Optional[str] = None


class CropInfoResponse(BaseModel):
    """Response schema for a crop encyclopedia entry."""
    id: str
    name: str
    scientific_name: Optional[str]
    description: Optional[str]
    season: Optional[str]
    temp_min: Optional[float]
    temp_max: Optional[float]
    water_requirement: Optional[str]
    soil_type: Optional[str]
    growing_tips: List[str]
    nutritional_info: Dict[str, Any]
    common_varieties: List[str]
    common_diseases: List[str]
    image_url: Optional[str]

    class Config:
        from_attributes = True


class CropInfoListResponse(BaseModel):
    """List of crop encyclopedia entries."""
    crops: List[CropInfoResponse]
    total: int


class CropInfoSummary(BaseModel):
    """Summary view of crop info for listing."""
    id: str
    name: str
    season: Optional[str]
    image_url: Optional[str]

    class Config:
        from_attributes = True


# ============== Disease Info Schemas ==============

class DiseaseInfoCreate(BaseModel):
    """Schema for creating a disease encyclopedia entry (admin only)."""
    name: str = Field(..., min_length=1, max_length=200)
    scientific_name: Optional[str] = Field(None, max_length=200)
    affected_crops: List[str] = []
    description: Optional[str] = None
    symptoms: List[str] = []
    causes: Optional[str] = None
    chemical_treatment: List[str] = []
    organic_treatment: List[str] = []
    prevention: List[str] = []
    severity_level: Optional[str] = None
    spread_method: Optional[str] = None
    safety_warnings: List[str] = []
    environmental_warnings: List[str] = []
    image_url: Optional[str] = None


class DiseaseInfoResponse(BaseModel):
    """Response schema for a disease encyclopedia entry."""
    id: str
    name: str
    scientific_name: Optional[str]
    affected_crops: List[str]
    description: Optional[str]
    symptoms: List[str]
    causes: Optional[str]
    chemical_treatment: List[str]
    organic_treatment: List[str]
    prevention: List[str]
    severity_level: Optional[str]
    spread_method: Optional[str]
    safety_warnings: List[str]
    environmental_warnings: List[str]
    image_url: Optional[str]

    class Config:
        from_attributes = True


class DiseaseInfoListResponse(BaseModel):
    """List of disease encyclopedia entries."""
    diseases: List[DiseaseInfoResponse]
    total: int

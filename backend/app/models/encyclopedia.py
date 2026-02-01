"""
Encyclopedia Models - SQLAlchemy ORM models for crop and disease encyclopedia
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, Float
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.database import Base


class CropInfo(Base):
    """Encyclopedia entry for a crop type."""
    __tablename__ = "crop_encyclopedia"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, unique=True, index=True)
    scientific_name = Column(String(200), nullable=True)
    description = Column(Text, nullable=True)
    season = Column(String(100), nullable=True)  # e.g., "Rabi", "Kharif", "Rabi & Kharif"
    
    # Growing conditions
    temp_min = Column(Float, nullable=True)  # Celsius
    temp_max = Column(Float, nullable=True)
    water_requirement = Column(String(50), nullable=True)  # Low, Medium, High
    soil_type = Column(String(200), nullable=True)
    
    # Additional info stored as JSON for flexibility
    growing_tips = Column(JSONB, default=list)
    nutritional_info = Column(JSONB, default=dict)
    common_varieties = Column(JSONB, default=list)
    
    # Common diseases (list of disease IDs or names)
    common_diseases = Column(JSONB, default=list)
    
    image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<CropInfo {self.name}>"


class DiseaseInfo(Base):
    """Encyclopedia entry for a crop disease."""
    __tablename__ = "disease_encyclopedia"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(200), nullable=False, index=True)
    scientific_name = Column(String(200), nullable=True)
    affected_crops = Column(JSONB, default=list)  # List of crop names
    description = Column(Text, nullable=True)
    
    # Symptoms and causes
    symptoms = Column(JSONB, default=list)
    causes = Column(Text, nullable=True)
    
    # Treatment
    chemical_treatment = Column(JSONB, default=list)
    organic_treatment = Column(JSONB, default=list)
    prevention = Column(JSONB, default=list)
    
    # Severity and spread
    severity_level = Column(String(50), nullable=True)  # mild, moderate, severe
    spread_method = Column(String(200), nullable=True)
    
    # Warnings
    safety_warnings = Column(JSONB, default=list)
    environmental_warnings = Column(JSONB, default=list)
    
    image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<DiseaseInfo {self.name}>"

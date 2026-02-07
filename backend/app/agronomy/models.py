"""
Agronomy Knowledge Models - Rules and Constraints
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, Float, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.database import Base

class DiagnosticRule(Base):
    """
    Rules for adjusting disease diagnosis confidence based on environmental context.
    """
    __tablename__ = "agronomy_diagnostic_rules"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    disease_id = Column(UUID(as_uuid=True), ForeignKey("disease_encyclopedia.id"), nullable=False)
    
    # Rule definition
    rule_name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    
    # conditions: {"temp_min": 20, "temp_max": 30, "humidity_min": 80, "season": "Kharif"}
    conditions = Column(JSONB, nullable=False, default=dict)
    
    # impact: {"confidence_adjustment": 0.2, "is_mandatory": false}
    impact = Column(JSONB, nullable=False, default=dict)
    
    priority = Column(Float, default=1.0)
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    disease = relationship("DiseaseInfo", backref="diagnostic_rules")

    def __repr__(self):
        return f"<DiagnosticRule {self.rule_name} for {self.disease_id}>"


class TreatmentConstraint(Base):
    """
    Safety constraints for treatments (chemical/organic).
    """
    __tablename__ = "agronomy_treatment_constraints"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Target treatment mechanism
    treatment_name = Column(String(200), nullable=False, index=True)
    treatment_type = Column(String(50), nullable=False) # 'chemical', 'organic'
    
    # Constraints
    constraint_description = Column(Text, nullable=False)
    
    # conditions: {"stage": "flowering", "weather": "rainy", "soil_moisture": "high"}
    restricted_conditions = Column(JSONB, nullable=False, default=dict)
    
    # action: "block", "warn", "requires_approval"
    enforcement_level = Column(String(50), default="warn")
    
    risk_level = Column(String(50), default="medium") # low, medium, high, critical
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<TreatmentConstraint {self.treatment_name} ({self.enforcement_level})>"


class SeasonalPattern(Base):
    """
    Disease prevalence patterns based on season and region.
    """
    __tablename__ = "agronomy_seasonal_patterns"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    disease_id = Column(UUID(as_uuid=True), ForeignKey("disease_encyclopedia.id"), nullable=False)
    crop_id = Column(UUID(as_uuid=True), ForeignKey("crop_encyclopedia.id"), nullable=False)
    
    region = Column(String(100), nullable=True) # Optional, null means general
    season = Column(String(50), nullable=False) # Kharif, Rabi, Zaid, All Year
    
    likelihood_score = Column(Float, default=0.5) # 0.0 to 1.0 probability baseline
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    disease = relationship("DiseaseInfo")
    crop = relationship("CropInfo")

    def __repr__(self):
        return f"<SeasonalPattern {self.season} - {self.region}>"

"""
Pest Model - SQLAlchemy ORM model for pest encyclopedia
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.database import Base


class PestInfo(Base):
    """Encyclopedia entry for an agricultural pest."""
    __tablename__ = "pest_encyclopedia"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(200), nullable=False, index=True)
    scientific_name = Column(String(200), nullable=True)
    
    # Affected crops (list of crop names)
    affected_crops = Column(JSONB, default=list)
    
    description = Column(Text, nullable=True)
    
    # Identification
    symptoms = Column(JSONB, default=list)       # Damage symptoms on plant
    appearance = Column(Text, nullable=True)      # What the pest looks like
    damage_type = Column(String(100), nullable=True)  # e.g., "Sucking", "Chewing", "Boring"
    
    # Life cycle
    life_cycle = Column(Text, nullable=True)
    
    # Control methods
    control_methods = Column(JSONB, default=list)   # General IPM methods
    organic_control = Column(JSONB, default=list)   # Biological/organic
    chemical_control = Column(JSONB, default=list)  # Pesticide recommendations
    prevention = Column(JSONB, default=list)
    
    # Risk
    severity_level = Column(String(50), nullable=True)  # mild, moderate, severe
    
    image_url = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<PestInfo {self.name}>"

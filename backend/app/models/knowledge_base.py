"""
Knowledge Base Model - Expert-created treatment guides
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.orm import relationship

from app.database import Base


class KnowledgeGuide(Base):
    """
    Expert-created disease treatment guides and tips.
    """
    __tablename__ = "knowledge_guides"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    expert_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    disease_id = Column(UUID(as_uuid=True), ForeignKey("disease_encyclopedia.id"), nullable=True)
    
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)  # Markdown content
    tags = Column(ARRAY(String), default=[])
    
    views = Column(Integer, default=0)
    is_published = Column(String(20), default='draft')  # 'draft', 'published'
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    expert = relationship("User", backref="knowledge_guides")
    disease = relationship("DiseaseInfo", backref="knowledge_guides")

    def __repr__(self):
        return f"<KnowledgeGuide {self.title}>"

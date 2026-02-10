from typing import List, Optional, Any
from uuid import UUID
from pydantic import BaseModel

class KnowledgeGuideCreate(BaseModel):
    expert_id: UUID
    disease_id: Optional[UUID] = None
    title: str
    content: str
    tags: List[str] = []
    is_published: str = "draft"

class KnowledgeGuideUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None
    is_published: Optional[str] = None

class KnowledgeGuideResponse(BaseModel):
    id: UUID
    expert_id: UUID
    expert_name: Optional[str] = None
    disease_id: Optional[UUID] = None
    disease_name: Optional[str] = None
    title: str
    content: str
    tags: List[str]
    views: int
    is_published: str
    created_at: Any
    updated_at: Any
    
    class Config:
        from_attributes = True

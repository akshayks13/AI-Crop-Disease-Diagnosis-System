from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from uuid import UUID

from app.database import get_db
from app.auth.dependencies import get_current_user
from app.models.user import User, UserRole
from app.agronomy_intelligence.services import AgronomyIntelligenceService
from app.agronomy_intelligence.schemas import (
    KnowledgeGuideResponse, 
    KnowledgeGuideCreate, 
    KnowledgeGuideUpdate
)

router = APIRouter(prefix="/agronomy-intelligence", tags=["Module 3: Agronomy Knowledge"])

def get_service(db: AsyncSession = Depends(get_db)) -> AgronomyIntelligenceService:
    return AgronomyIntelligenceService(db)

def require_admin_or_expert(current_user: User = Depends(get_current_user)) -> User:
    """Dependency to ensure user is an admin or approved expert."""
    # Assuming UserStatus is available on User object or needs checking
    # Simplified check based on roles
    if current_user.role == UserRole.ADMIN or current_user.role == UserRole.EXPERT:
        return current_user
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Admin or Expert access required"
    )

@router.get("/guides/disease/{disease_id}", response_model=List[KnowledgeGuideResponse])
async def get_guides_by_disease(
    disease_id: UUID,
    service: AgronomyIntelligenceService = Depends(get_service),
    current_user: User = Depends(get_current_user)
):
    """
    Get all published knowledge guides for a specific disease.
    """
    guides = await service.get_guides_for_disease(disease_id)
    
    return [
        {
            "id": str(g.id),
            "expert_id": str(g.expert_id),
            "expert_name": g.expert.full_name if g.expert else "Unknown Expert",
            "disease_id": str(g.disease_id) if g.disease_id else None,
            "disease_name": g.disease.name if g.disease else None,
            "title": g.title,
            "content": g.content,
            "tags": g.tags,
            "views": g.views,
            "is_published": g.is_published,
            "created_at": g.created_at,
            "updated_at": g.updated_at
        }
        for g in guides
    ]

@router.post("/guides", response_model=KnowledgeGuideResponse, status_code=status.HTTP_201_CREATED)
async def create_knowledge_guide(
    guide: KnowledgeGuideCreate,
    user: User = Depends(require_admin_or_expert),
    service: AgronomyIntelligenceService = Depends(get_service)
):
    """
    Create a new knowledge guide.
    Expert or Admin only.
    """
    if user.role == UserRole.EXPERT and str(guide.expert_id) != str(user.id):
        raise HTTPException(status_code=403, detail="Experts can only create guides for themselves")

    created = await service.create_knowledge_guide(guide.model_dump())
    
    return {
            "id": str(created.id),
            "expert_id": str(created.expert_id),
            "expert_name": user.full_name,
            "disease_id": str(created.disease_id) if created.disease_id else None,
            "disease_name": None, 
            "title": created.title,
            "content": created.content,
            "tags": created.tags,
            "views": created.views,
            "is_published": created.is_published,
            "created_at": created.created_at,
            "updated_at": created.updated_at
    }

@router.put("/guides/{guide_id}", response_model=KnowledgeGuideResponse)
async def update_knowledge_guide(
    guide_id: UUID,
    guide_update: KnowledgeGuideUpdate,
    user: User = Depends(require_admin_or_expert),
    service: AgronomyIntelligenceService = Depends(get_service)
):
    """
    Update a knowledge guide.
    Expert (owner) or Admin only.
    """
    guide = await service.get_knowledge_guide(guide_id)
    if not guide:
        raise HTTPException(status_code=404, detail="Guide not found")
        
    if user.role != UserRole.ADMIN and str(guide.expert_id) != str(user.id):
        raise HTTPException(status_code=403, detail="Not authorized to update this guide")
        
    updated = await service.update_knowledge_guide(guide_id, guide_update.model_dump(exclude_unset=True))
    
    return {
            "id": str(updated.id),
            "expert_id": str(updated.expert_id),
            "expert_name": updated.expert.full_name if updated.expert else None,
            "disease_id": str(updated.disease_id) if updated.disease_id else None,
            "disease_name": updated.disease.name if updated.disease else None,
            "title": updated.title,
            "content": updated.content,
            "tags": updated.tags,
            "views": updated.views,
            "is_published": updated.is_published,
            "created_at": updated.created_at,
            "updated_at": updated.updated_at
    }

@router.delete("/guides/{guide_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_knowledge_guide(
    guide_id: UUID,
    user: User = Depends(require_admin_or_expert),
    service: AgronomyIntelligenceService = Depends(get_service)
):
    """
    Delete a knowledge guide.
    Expert (owner) or Admin only.
    """
    guide = await service.get_knowledge_guide(guide_id)
    if not guide:
        raise HTTPException(status_code=404, detail="Guide not found")
        
    if user.role != UserRole.ADMIN and str(guide.expert_id) != str(user.id):
        raise HTTPException(status_code=403, detail="Not authorized to delete this guide")
        
    await service.delete_knowledge_guide(guide_id)

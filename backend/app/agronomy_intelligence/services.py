from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID
from typing import List, Any

from app.agronomy_intelligence.models import KnowledgeGuide

class AgronomyIntelligenceService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_knowledge_guide(self, guide_id: UUID) -> Any:
        """Get a single knowledge guide."""
        from sqlalchemy.orm import selectinload
        
        query = select(KnowledgeGuide).options(
            selectinload(KnowledgeGuide.expert),
            selectinload(KnowledgeGuide.disease)
        ).where(KnowledgeGuide.id == guide_id)
        
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def get_guides_for_disease(self, disease_id: UUID) -> List[Any]:
        """Get published guides for a specific disease."""
        from sqlalchemy.orm import selectinload

        query = select(KnowledgeGuide).options(
            selectinload(KnowledgeGuide.expert),
            selectinload(KnowledgeGuide.disease)
        ).where(
            KnowledgeGuide.disease_id == disease_id,
            KnowledgeGuide.is_published == 'published'
        )
        result = await self.db.execute(query)
        guides = result.scalars().all()
        
        # Increment views (simplified, side effect)
        for guide in guides:
            guide.views += 1
        if guides:
             await self.db.commit()

        return guides

    async def create_knowledge_guide(self, guide_data: dict) -> Any:
        """Create a new knowledge guide."""
        guide = KnowledgeGuide(**guide_data)
        self.db.add(guide)
        await self.db.commit()
        await self.db.refresh(guide)
        return guide

    async def update_knowledge_guide(self, guide_id: UUID, guide_data: dict) -> Any:
        """Update a knowledge guide."""
        guide = await self.get_knowledge_guide(guide_id)
        if not guide:
            return None
            
        for key, value in guide_data.items():
            if value is not None:
                setattr(guide, key, value)
        
        await self.db.commit()
        await self.db.refresh(guide)
        return guide
    
    async def delete_knowledge_guide(self, guide_id: UUID) -> bool:
        """Delete a knowledge guide."""
        guide = await self.get_knowledge_guide(guide_id)
        if not guide:
            return False
            
        await self.db.delete(guide)
        await self.db.commit()
        return True

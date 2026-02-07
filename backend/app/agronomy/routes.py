from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from uuid import UUID

from app.database import get_db
from app.auth.dependencies import get_current_user
from app.models.user import User, UserRole
from app.agronomy.services import AgronomyService
from app.agronomy.schemas import (
    ContextValidationRequest, ValidationResult,
    SafetyCheckRequest, SafetyCheckResult
)
# Note: SeasonalPattern model is SQLAlchemy, we should use a Pydantic schema for response.
# For now, let's use a generic dict or create a schema if needed. 
# Re-checking schemas.py: I didn't create a SeasonalPattern response schema. 
# I'll output the model directly (FastAPI handles ORM objects if configured) or simple dicts.

router = APIRouter(prefix="/agronomy", tags=["Agronomy Intelligence"])

def get_agronomy_service(db: AsyncSession = Depends(get_db)) -> AgronomyService:
    return AgronomyService(db)

@router.post("/validate-diagnosis", response_model=ValidationResult)
async def validate_diagnosis(
    request: ContextValidationRequest,
    current_user: User = Depends(get_current_user),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Validate a disease diagnosis against environmental context.
    """
    result = await service.validate_diagnosis_context(
        disease_id=request.disease_id,
        context=request.context
    )
    return result

@router.post("/check-safety", response_model=SafetyCheckResult)
async def check_treatment_safety(
    request: SafetyCheckRequest,
    current_user: User = Depends(get_current_user),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Check if treatments are safe given the current context.
    """
    result = await service.check_treatment_safety(
        treatments=[request.treatment_name], # simplified for single treatment check
        context=request.context,
        treatment_type=request.treatment_type
    )
    return result

@router.get("/seasonal-diseases", response_model=List[dict]) 
async def get_seasonal_diseases(
    crop_id: UUID,
    season: str,
    region: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Get diseases prevalent in a specific season and region.
    """
    patterns = await service.get_seasonal_diseases(crop_id, season, region)
    
    # Simple manual serialization to avoid circular dependencies or schema overhead for now
    return [
        {
            "disease_id": str(p.disease_id),
            "disease_name": p.disease.name if p.disease else "Unknown",
            "season": p.season,
            "region": p.region,
            "likelihood_score": p.likelihood_score
        }
        for p in patterns
    ]

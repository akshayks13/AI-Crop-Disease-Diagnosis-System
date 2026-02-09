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
    SafetyCheckRequest, SafetyCheckResult,
    DiagnosticRuleCreate, DiagnosticRuleUpdate, DiagnosticRuleResponse,
    TreatmentConstraintCreate, TreatmentConstraintUpdate, TreatmentConstraintResponse,
    SeasonalPatternCreate, SeasonalPatternUpdate, SeasonalPatternResponse
)

router = APIRouter(prefix="/agronomy", tags=["Agronomy Intelligence"])

def get_agronomy_service(db: AsyncSession = Depends(get_db)) -> AgronomyService:
    return AgronomyService(db)

def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Dependency to ensure user is an admin."""
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user

# Farmer/Expert Endpoints (existing)

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

# Admin CRUD Endpoints - Diagnostic Rules

@router.get("/admin/rules", response_model=List[DiagnosticRuleResponse], tags=["Agronomy Admin"])
async def list_diagnostic_rules(
    disease_id: Optional[UUID] = None,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    List all diagnostic rules, optionally filtered by disease.
    Admin only.
    """
    rules = await service.get_diagnostic_rules(disease_id)
    # Manually add disease_name from relationship
    return [
        {
            "id": str(r.id),
            "disease_id": str(r.disease_id),
            "disease_name": r.disease.name if r.disease else None,
            "rule_name": r.rule_name,
            "description": r.description,
            "conditions": r.conditions,
            "impact": r.impact,
            "priority": r.priority,
            "is_active": r.is_active,
        }
        for r in rules
    ]

@router.post("/admin/rules", response_model=DiagnosticRuleResponse, status_code=status.HTTP_201_CREATED, tags=["Agronomy Admin"])
async def create_diagnostic_rule(
    rule: DiagnosticRuleCreate,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Create a new diagnostic rule.
    Admin only.
    """
    return await service.create_diagnostic_rule(rule.model_dump())

@router.get("/admin/rules/{rule_id}", response_model=DiagnosticRuleResponse, tags=["Agronomy Admin"])
async def get_diagnostic_rule(
    rule_id: UUID,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Get a specific diagnostic rule.
    Admin only.
    """
    rule = await service.get_diagnostic_rule(rule_id)
    if not rule:
        raise HTTPException(status_code=404, detail="Diagnostic rule not found")
    return rule

@router.put("/admin/rules/{rule_id}", response_model=DiagnosticRuleResponse, tags=["Agronomy Admin"])
async def update_diagnostic_rule(
    rule_id: UUID,
    rule_update: DiagnosticRuleUpdate,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Update a diagnostic rule.
    Admin only.
    """
    rule = await service.update_diagnostic_rule(rule_id, rule_update.model_dump(exclude_unset=True))
    if not rule:
        raise HTTPException(status_code=404, detail="Diagnostic rule not found")
    return rule

@router.delete("/admin/rules/{rule_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Agronomy Admin"])
async def delete_diagnostic_rule(
    rule_id: UUID,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Delete a diagnostic rule.
    Admin only.
    """
    deleted = await service.delete_diagnostic_rule(rule_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Diagnostic rule not found")

# Admin CRUD Endpoints - Treatment Constraints

@router.get("/admin/constraints", response_model=List[TreatmentConstraintResponse], tags=["Agronomy Admin"])
async def list_treatment_constraints(
    treatment_type: Optional[str] = None,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    List all treatment constraints, optionally filtered by type.
    Admin only.
    """
    constraints = await service.get_treatment_constraints(treatment_type)
    return constraints

@router.post("/admin/constraints", response_model=TreatmentConstraintResponse, status_code=status.HTTP_201_CREATED, tags=["Agronomy Admin"])
async def create_treatment_constraint(
    constraint: TreatmentConstraintCreate,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Create a new treatment constraint.
    Admin only.
    """
    return await service.create_treatment_constraint(constraint.model_dump())

@router.get("/admin/constraints/{constraint_id}", response_model=TreatmentConstraintResponse, tags=["Agronomy Admin"])
async def get_treatment_constraint(
    constraint_id: UUID,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Get a specific treatment constraint.
    Admin only.
    """
    constraint = await service.get_treatment_constraint(constraint_id)
    if not constraint:
        raise HTTPException(status_code=404, detail="Treatment constraint not found")
    return constraint

@router.put("/admin/constraints/{constraint_id}", response_model=TreatmentConstraintResponse, tags=["Agronomy Admin"])
async def update_treatment_constraint(
    constraint_id: UUID,
    constraint_update: TreatmentConstraintUpdate,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Update a treatment constraint.
    Admin only.
    """
    constraint = await service.update_treatment_constraint(constraint_id, constraint_update.model_dump(exclude_unset=True))
    if not constraint:
        raise HTTPException(status_code=404, detail="Treatment constraint not found")
    return constraint

@router.delete("/admin/constraints/{constraint_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Agronomy Admin"])
async def delete_treatment_constraint(
    constraint_id: UUID,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Delete a treatment constraint.
    Admin only.
    """
    deleted = await service.delete_treatment_constraint(constraint_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Treatment constraint not found")

# Admin CRUD Endpoints - Seasonal Patterns

@router.get("/admin/patterns", response_model=List[SeasonalPatternResponse], tags=["Agronomy Admin"])
async def list_seasonal_patterns(
    crop_id: Optional[UUID] = None,
    disease_id: Optional[UUID] = None,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    List all seasonal patterns, optionally filtered by crop or disease.
    Admin only.
    """
    patterns = await service.get_seasonal_patterns(crop_id, disease_id)
    return patterns

@router.post("/admin/patterns", response_model=SeasonalPatternResponse, status_code=status.HTTP_201_CREATED, tags=["Agronomy Admin"])
async def create_seasonal_pattern(
    pattern: SeasonalPatternCreate,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Create a new seasonal pattern.
    Admin only.
    """
    return await service.create_seasonal_pattern(pattern.model_dump())

@router.get("/admin/patterns/{pattern_id}", response_model=SeasonalPatternResponse, tags=["Agronomy Admin"])
async def get_seasonal_pattern(
    pattern_id: UUID,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Get a specific seasonal pattern.
    Admin only.
    """
    pattern = await service.get_seasonal_pattern(pattern_id)
    if not pattern:
        raise HTTPException(status_code=404, detail="Seasonal pattern not found")
    return pattern

@router.put("/admin/patterns/{pattern_id}", response_model=SeasonalPatternResponse, tags=["Agronomy Admin"])
async def update_seasonal_pattern(
    pattern_id: UUID,
    pattern_update: SeasonalPatternUpdate,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Update a seasonal pattern.
    Admin only.
    """
    pattern = await service.update_seasonal_pattern(pattern_id, pattern_update.model_dump(exclude_unset=True))
    if not pattern:
        raise HTTPException(status_code=404, detail="Seasonal pattern not found")
    return pattern

@router.delete("/admin/patterns/{pattern_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Agronomy Admin"])
async def delete_seasonal_pattern(
    pattern_id: UUID,
    admin: User = Depends(require_admin),
    service: AgronomyService = Depends(get_agronomy_service)
):
    """
    Delete a seasonal pattern.
    Admin only.
    """
    deleted = await service.delete_seasonal_pattern(pattern_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Seasonal pattern not found")

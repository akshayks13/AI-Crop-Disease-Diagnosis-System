from typing import List, Optional, Dict, Any
from uuid import UUID
from pydantic import BaseModel

# Input Schemas
class EnvironmentalContext(BaseModel):
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    rainfall: Optional[float] = None
    soil_type: Optional[str] = None
    season: Optional[str] = None
    region: Optional[str] = None

class ContextValidationRequest(BaseModel):
    disease_id: UUID
    crop_id: Optional[UUID] = None
    context: EnvironmentalContext

class SafetyCheckRequest(BaseModel):
    treatment_name: str
    treatment_type: str # 'chemical', 'organic'
    context: EnvironmentalContext
    crop_stage: Optional[str] = None

# Output Schemas
class RuleMatch(BaseModel):
    rule_name: str
    adjustment: float
    reason: str

class ValidationResult(BaseModel):
    disease_id: UUID
    original_confidence: float = 0.0
    adjusted_confidence: float
    is_valid: bool
    warnings: List[str]
    applied_rules: List[RuleMatch]

class SafetyWarning(BaseModel):
    treatment_name: str
    risk_level: str
    warning_message: str
    action_required: str # 'none', 'acknowledge', 'block'

class SafetyCheckResult(BaseModel):
    is_safe: bool
    warnings: List[SafetyWarning]
    approved_treatments: List[str]
    blocked_treatments: List[str]

# Admin CRUD Schemas

class DiagnosticRuleCreate(BaseModel):
    disease_id: UUID
    rule_name: str
    description: Optional[str] = None
    conditions: Dict[str, Any]
    impact: Dict[str, Any]
    priority: float = 1.0
    is_active: bool = True

class DiagnosticRuleUpdate(BaseModel):
    rule_name: Optional[str] = None
    description: Optional[str] = None
    conditions: Optional[Dict[str, Any]] = None
    impact: Optional[Dict[str, Any]] = None
    priority: Optional[float] = None
    is_active: Optional[bool] = None

class DiagnosticRuleResponse(BaseModel):
    id: UUID
    disease_id: UUID
    rule_name: str
    description: Optional[str]
    conditions: Dict[str, Any]
    impact: Dict[str, Any]
    priority: float
    is_active: bool
    
    class Config:
        from_attributes = True

class TreatmentConstraintCreate(BaseModel):
    treatment_name: str
    treatment_type: str
    constraint_description: str
    restricted_conditions: Dict[str, Any]
    enforcement_level: str = "warn"
    risk_level: str = "medium"

class TreatmentConstraintUpdate(BaseModel):
    treatment_name: Optional[str] = None
    treatment_type: Optional[str] = None
    constraint_description: Optional[str] = None
    restricted_conditions: Optional[Dict[str, Any]] = None
    enforcement_level: Optional[str] = None
    risk_level: Optional[str] = None

class TreatmentConstraintResponse(BaseModel):
    id: UUID
    treatment_name: str
    treatment_type: str
    constraint_description: str
    restricted_conditions: Dict[str, Any]
    enforcement_level: str
    risk_level: str
    
    class Config:
        from_attributes = True

class SeasonalPatternCreate(BaseModel):
    disease_id: UUID
    crop_id: UUID
    region: Optional[str] = None
    season: str
    likelihood_score: float = 0.5

class SeasonalPatternUpdate(BaseModel):
    region: Optional[str] = None
    season: Optional[str] = None
    likelihood_score: Optional[float] = None

class SeasonalPatternResponse(BaseModel):
    id: UUID
    disease_id: UUID
    crop_id: UUID
    region: Optional[str]
    season: str
    likelihood_score: float
    
    class Config:
        from_attributes = True

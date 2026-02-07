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

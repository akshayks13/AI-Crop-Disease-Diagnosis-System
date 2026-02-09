from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
from uuid import UUID
from typing import List, Dict, Any

from app.agronomy.models import DiagnosticRule, TreatmentConstraint, SeasonalPattern
from app.agronomy.schemas import (
    EnvironmentalContext, ValidationResult, SafetyCheckResult, 
    SafetyWarning, RuleMatch
)

class AgronomyService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def validate_diagnosis_context(
        self, 
        disease_id: str,  # Can be UUID or disease label like "healthy_lemon"
        context: EnvironmentalContext, 
        initial_confidence: float = 0.8
    ) -> ValidationResult:
        """
        Validates a disease diagnosis against environmental context rules.
        """
        from uuid import UUID as UUIDType
        from app.models.encyclopedia import DiseaseInfo
        
        # Try to convert to UUID, if fails look up by name
        actual_disease_id = None
        try:
            actual_disease_id = UUIDType(disease_id)
        except (ValueError, AttributeError):
            # Not a valid UUID, try to find disease by name
            disease_query = select(DiseaseInfo).where(
                DiseaseInfo.name.ilike(f"%{disease_id.replace('_', ' ')}%")
            )
            result = await self.db.execute(disease_query)
            disease = result.scalar_one_or_none()
            if disease:
                actual_disease_id = disease.id
        
        # If no disease found, return empty validation result
        if actual_disease_id is None:
            return ValidationResult(
                disease_id=UUIDType('00000000-0000-0000-0000-000000000000'),
                original_confidence=initial_confidence,
                adjusted_confidence=initial_confidence,
                is_valid=True,
                warnings=["Disease not found in database, skipping validation"],
                applied_rules=[]
            )
        
        # Fetch rules for the disease
        query = select(DiagnosticRule).where(
            DiagnosticRule.disease_id == actual_disease_id,
            DiagnosticRule.is_active
        )
        result = await self.db.execute(query)
        rules = result.scalars().all()
        
        adjusted_confidence = initial_confidence
        applied_rules = []
        is_valid = True
        warnings = []

        for rule in rules:
            match = True
            # Simple rule evaluation logic
            # Conditions: {"temp_min": 20, "temp_max": 30}
            if context.temperature is not None:
                if "temp_min" in rule.conditions and context.temperature < rule.conditions["temp_min"]:
                    match = False
                if "temp_max" in rule.conditions and context.temperature > rule.conditions["temp_max"]:
                    match = False
            
            if context.humidity is not None:
                 if "humidity_min" in rule.conditions and context.humidity < rule.conditions["humidity_min"]:
                    match = False
                 if "humidity_max" in rule.conditions and context.humidity > rule.conditions["humidity_max"]:
                    match = False
            
            if context.season is not None and "season" in rule.conditions:
                if context.season.lower() != rule.conditions["season"].lower():
                    match = False

            # If rule DOES match positive conditions, we might boost confidence
            # Or if it fails negative conditions, we reduce confidence
            
            # Implementation Strategy: 
            # If a rule defines REQUIRED conditions (e.g. "Needs high humidity")
            # and they are NOT met, we reduce confidence.
            # If they ARE met, we might increase or keep stable.
            
            # For this MVP, let's assume rules define "favorable conditions".
            # If not met, reduce confidence.
            if not match:
                adjustment = rule.impact.get("confidence_penalty", -0.1)
                adjusted_confidence += adjustment
                applied_rules.append(RuleMatch(
                    rule_name=rule.rule_name,
                    adjustment=adjustment,
                    reason=f"Conditions not met: {rule.description}"
                ))
            else:
                adjustment = rule.impact.get("confidence_boost", 0.05)
                # Cap confidence boost
                if adjusted_confidence < 0.95:
                    adjusted_confidence += adjustment
                    applied_rules.append(RuleMatch(
                        rule_name=rule.rule_name,
                        adjustment=adjustment,
                        reason=f"Favorable conditions: {rule.description}"
                    ))

        # Clamp confidence
        adjusted_confidence = max(0.0, min(1.0, adjusted_confidence))
        
        if adjusted_confidence < 0.3:
            is_valid = False
            warnings.append("Environmental conditions strongly disagree with this diagnosis.")

        return ValidationResult(
            disease_id=disease_id,
            original_confidence=initial_confidence,
            adjusted_confidence=adjusted_confidence,
            is_valid=is_valid,
            warnings=warnings,
            applied_rules=applied_rules
        )

    async def check_treatment_safety(
        self, 
        treatments: List[str], 
        context: EnvironmentalContext,
        treatment_type: str = "chemical"
    ) -> SafetyCheckResult:
        """
        Checks safety of treatments against constraints.
        """
        # Fetch constraints for these treatments
        # Note: In a real system, we'd have a Treatment entity. 
        # Here we match by name string substring or exact match.
        
        query = select(TreatmentConstraint).where(
            TreatmentConstraint.treatment_type == treatment_type,
            # In real app, use ANY(treatments) or similar. 
            # Simplified: fetch all active constraints and filter in code for MVP
        )
        result = await self.db.execute(query)
        all_constraints = result.scalars().all()
        
        approved = []
        blocked = []
        warnings = []
        is_safe = True

        for treatment in treatments:
            treatment_safe = True
            
            # Find constraints relevant to this treatment
            relevant_constraints = [
                c for c in all_constraints 
                if c.treatment_name.lower() in treatment.lower()
            ]
            
            for constraint in relevant_constraints:
                # Check conditions
                # e.g. "Do not use if rainy"
                risk = False
                if "weather" in constraint.restricted_conditions:
                    if constraint.restricted_conditions["weather"] == "rainy" and context.rainfall and context.rainfall > 0:
                        risk = True
                
                # Check soil type
                if "soil_type" in constraint.restricted_conditions:
                     if context.soil_type and context.soil_type.lower() == constraint.restricted_conditions["soil_type"].lower():
                         risk = True

                if risk:
                    if constraint.enforcement_level == "block":
                        treatment_safe = False
                        is_safe = False
                        blocked.append(treatment)
                        warnings.append(SafetyWarning(
                            treatment_name=treatment,
                            risk_level="CRITICAL",
                            warning_message=constraint.constraint_description,
                            action_required="block"
                        ))
                        break # Stop checking this treatment, it's blocked
                    else:
                        warnings.append(SafetyWarning(
                            treatment_name=treatment,
                            risk_level=constraint.risk_level,
                            warning_message=constraint.constraint_description,
                            action_required="acknowledge"
                        ))

            if treatment_safe:
                approved.append(treatment)

        # Remove duplicates
        approved = list(set(approved))
        blocked = list(set(blocked))

        return SafetyCheckResult(
            is_safe=is_safe,
            warnings=warnings,
            approved_treatments=approved,
            blocked_treatments=blocked
        )

    async def get_seasonal_diseases(
        self, 
        crop_id: UUID, 
        season: str, 
        region: str = None
    ) -> List[SeasonalPattern]:
        """
        Get diseases prevalent in the given season/region.
        """
        query = select(SeasonalPattern).where(
            SeasonalPattern.crop_id == crop_id,
            SeasonalPattern.season == season
        )
        if region:
             query = query.where(or_(SeasonalPattern.region == region, SeasonalPattern.region.is_(None)))
        
        result = await self.db.execute(query)
        return result.scalars().all()

    # Admin CRUD Methods

    async def create_diagnostic_rule(self, rule_data: dict) -> DiagnosticRule:
        """Create a new diagnostic rule."""
        rule = DiagnosticRule(**rule_data)
        self.db.add(rule)
        await self.db.commit()
        await self.db.refresh(rule)
        return rule

    async def get_diagnostic_rules(self, disease_id: UUID = None) -> List[DiagnosticRule]:
        """Get all diagnostic rules, optionally filtered by disease."""
        from sqlalchemy.orm import selectinload
        query = select(DiagnosticRule).options(selectinload(DiagnosticRule.disease))
        if disease_id:
            query = query.where(DiagnosticRule.disease_id == disease_id)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def get_diagnostic_rule(self, rule_id: UUID) -> DiagnosticRule:
        """Get a single diagnostic rule by ID."""
        query = select(DiagnosticRule).where(DiagnosticRule.id == rule_id)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def update_diagnostic_rule(self, rule_id: UUID, rule_data: dict) -> DiagnosticRule:
        """Update a diagnostic rule."""
        rule = await self.get_diagnostic_rule(rule_id)
        if not rule:
            return None
        
        for key, value in rule_data.items():
            if value is not None:
                setattr(rule, key, value)
        
        await self.db.commit()
        await self.db.refresh(rule)
        return rule

    async def delete_diagnostic_rule(self, rule_id: UUID) -> bool:
        """Delete a diagnostic rule."""
        rule = await self.get_diagnostic_rule(rule_id)
        if not rule:
            return False
        
        await self.db.delete(rule)
        await self.db.commit()
        return True

    async def create_treatment_constraint(self, constraint_data: dict) -> TreatmentConstraint:
        """Create a new treatment constraint."""
        constraint = TreatmentConstraint(**constraint_data)
        self.db.add(constraint)
        await self.db.commit()
        await self.db.refresh(constraint)
        return constraint

    async def get_treatment_constraints(self, treatment_type: str = None) -> List[TreatmentConstraint]:
        """Get all treatment constraints, optionally filtered by type."""
        query = select(TreatmentConstraint)
        if treatment_type:
            query = query.where(TreatmentConstraint.treatment_type == treatment_type)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def get_treatment_constraint(self, constraint_id: UUID) -> TreatmentConstraint:
        """Get a single treatment constraint by ID."""
        query = select(TreatmentConstraint).where(TreatmentConstraint.id == constraint_id)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def update_treatment_constraint(self, constraint_id: UUID, constraint_data: dict) -> TreatmentConstraint:
        """Update a treatment constraint."""
        constraint = await self.get_treatment_constraint(constraint_id)
        if not constraint:
            return None
        
        for key, value in constraint_data.items():
            if value is not None:
                setattr(constraint, key, value)
        
        await self.db.commit()
        await self.db.refresh(constraint)
        return constraint

    async def delete_treatment_constraint(self, constraint_id: UUID) -> bool:
        """Delete a treatment constraint."""
        constraint = await self.get_treatment_constraint(constraint_id)
        if not constraint:
            return False
        
        await self.db.delete(constraint)
        await self.db.commit()
        return True

    async def create_seasonal_pattern(self, pattern_data: dict) -> SeasonalPattern:
        """Create a new seasonal pattern."""
        pattern = SeasonalPattern(**pattern_data)
        self.db.add(pattern)
        await self.db.commit()
        await self.db.refresh(pattern)
        return pattern

    async def get_seasonal_patterns(self, crop_id: UUID = None, disease_id: UUID = None) -> List[SeasonalPattern]:
        """Get all seasonal patterns, optionally filtered by crop or disease."""
        from sqlalchemy.orm import selectinload
        query = select(SeasonalPattern).options(
            selectinload(SeasonalPattern.disease),
            selectinload(SeasonalPattern.crop)
        )
        if crop_id:
            query = query.where(SeasonalPattern.crop_id == crop_id)
        if disease_id:
            query = query.where(SeasonalPattern.disease_id == disease_id)
        result = await self.db.execute(query)
        return result.scalars().all()

    async def get_seasonal_pattern(self, pattern_id: UUID) -> SeasonalPattern:
        """Get a single seasonal pattern by ID."""
        query = select(SeasonalPattern).where(SeasonalPattern.id == pattern_id)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def update_seasonal_pattern(self, pattern_id: UUID, pattern_data: dict) -> SeasonalPattern:
        """Update a seasonal pattern."""
        pattern = await self.get_seasonal_pattern(pattern_id)
        if not pattern:
            return None
        
        for key, value in pattern_data.items():
            if value is not None:
                setattr(pattern, key, value)
        
        await self.db.commit()
        await self.db.refresh(pattern)
        return pattern

    async def delete_seasonal_pattern(self, pattern_id: UUID) -> bool:
        """Delete a seasonal pattern."""
        pattern = await self.get_seasonal_pattern(pattern_id)
        if not pattern:
            return False
        
        await self.db.delete(pattern)
        await self.db.commit()
        return True

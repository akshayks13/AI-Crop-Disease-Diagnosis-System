import pytest
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4
from sqlalchemy.ext.asyncio import AsyncSession

from app.agronomy.services import AgronomyService
from app.agronomy.models import DiagnosticRule, TreatmentConstraint, SeasonalPattern
from app.agronomy.schemas import EnvironmentalContext

@pytest.fixture
def mock_db_session():
    session = AsyncMock(spec=AsyncSession)
    # Mock execute result
    session.execute = AsyncMock()
    return session

@pytest.mark.asyncio
async def test_validate_diagnosis_context(mock_db_session):
    service = AgronomyService(mock_db_session)
    disease_id = uuid4()
    
    # Setup Mock Rule
    rule = DiagnosticRule(
        rule_name="High Humidity Required",
        description="This disease thrives in high humidity.",
        conditions={"humidity_min": 80},
        impact={"confidence_penalty": -0.2},
        is_active=True
    )
    
    # Mock database return
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = [rule]
    mock_db_session.execute.return_value = mock_result
    
    # Test Case 1: Conditions Not Met (Humidity 60 < 80)
    context_bad = EnvironmentalContext(humidity=60, temperature=25)
    result_bad = await service.validate_diagnosis_context(disease_id, context_bad)
    
    # Expect confidence penalty
    assert result_bad.adjusted_confidence < result_bad.original_confidence
    assert len(result_bad.applied_rules) == 1
    assert "Conditions not met" in result_bad.applied_rules[0].reason

    # Test Case 2: Conditions Met (Humidity 90 > 80)
    context_good = EnvironmentalContext(humidity=90, temperature=25)
    result_good = await service.validate_diagnosis_context(disease_id, context_good)
    
    # Expect confidence boost (or neutral if logic dependent)
    # Service logic: adjustment = rule.impact.get("confidence_boost", 0.05) if met
    assert result_good.adjusted_confidence > result_good.original_confidence

@pytest.mark.asyncio
async def test_check_treatment_safety(mock_db_session):
    service = AgronomyService(mock_db_session)
    
    # Setup Mock Constraint
    constraint = TreatmentConstraint(
        treatment_name="Copper Fungicide",
        treatment_type="chemical",
        constraint_description="Do not use in rain.",
        restricted_conditions={"weather": "rainy"},
        enforcement_level="block",
        risk_level="high"
    )
    
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = [constraint]
    mock_db_session.execute.return_value = mock_result
    
    # Test Case: Rainy weather
    context_rainy = EnvironmentalContext(rainfall=10.0) # implies raining if logic uses rainfall > 0
    # Service logic: check if "rainy" in conditions matches context. 
    # Current service impl: checks if constraint.restricted_conditions["weather"] == "rainy" 
    # and context.rainfall > 0.
    
    result = await service.check_treatment_safety(
        treatments=["Apply Copper Fungicide"],
        context=context_rainy
    )
    
    assert result.is_safe is False
    assert "Apply Copper Fungicide" in result.blocked_treatments
    assert len(result.warnings) > 0
    assert result.warnings[0].action_required == "block"

@pytest.mark.asyncio
async def test_get_seasonal_diseases(mock_db_session):
    service = AgronomyService(mock_db_session)
    crop_id = uuid4()
    
    pattern = SeasonalPattern(
        disease_id=uuid4(),
        crop_id=crop_id,
        season="Kharif",
        likelihood_score=0.8
    )
    
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = [pattern]
    mock_db_session.execute.return_value = mock_result
    
    results = await service.get_seasonal_diseases(crop_id, "Kharif")
    
    assert len(results) == 1
    assert results[0].season == "Kharif"

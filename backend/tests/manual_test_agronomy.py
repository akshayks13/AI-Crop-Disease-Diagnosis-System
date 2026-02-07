import unittest
import sys
import os
import asyncio
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4

# Add backend to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.agronomy.services import AgronomyService
from app.agronomy.models import DiagnosticRule, TreatmentConstraint, SeasonalPattern
from app.models.encyclopedia import CropInfo, DiseaseInfo # Import to register models
from app.agronomy.schemas import EnvironmentalContext, SafetyWarning

class TestAgronomyService(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.mock_db_session = AsyncMock()
        self.mock_db_session.execute = AsyncMock()
        self.service = AgronomyService(self.mock_db_session)

    async def test_validate_diagnosis_context(self):
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
        self.mock_db_session.execute.return_value = mock_result
        
        # Test Case 1: Conditions Not Met (Humidity 60 < 80)
        context_bad = EnvironmentalContext(humidity=60, temperature=25)
        result_bad = await self.service.validate_diagnosis_context(disease_id, context_bad)
        
        # Expect confidence penalty
        self.assertLess(result_bad.adjusted_confidence, result_bad.original_confidence)
        self.assertEqual(len(result_bad.applied_rules), 1)
        self.assertIn("Conditions not met", result_bad.applied_rules[0].reason)

    async def test_check_treatment_safety(self):
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
        self.mock_db_session.execute.return_value = mock_result
        
        context_rainy = EnvironmentalContext(rainfall=10.0)
        
        # Mock weather check logic: assume service checks context rainfall
        # The service implementation: 
        # if "weather" in constraint.restricted_conditions:
        #    if constraint.restricted_conditions["weather"] == "rainy" and context.rainfall and context.rainfall > 0:
        #        risk = True

        result = await self.service.check_treatment_safety(
            treatments=["Apply Copper Fungicide"],
            context=context_rainy
        )
        
        self.assertFalse(result.is_safe)
        self.assertIn("Apply Copper Fungicide", result.blocked_treatments)

if __name__ == '__main__':
    unittest.main()

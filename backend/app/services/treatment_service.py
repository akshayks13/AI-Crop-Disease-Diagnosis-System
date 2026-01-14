"""
Treatment Service - Treatment Recommendation Engine
"""
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)

# Treatment knowledge base
TREATMENT_KB = {
    # Tomato diseases
    "Early Blight": {
        "description": "Fungal disease causing dark spots with concentric rings on leaves",
        "chemical": [
            {
                "name": "Chlorothalonil",
                "dosage": "2-3 g/L water",
                "application": "Foliar spray",
                "frequency": "Every 7-10 days",
            },
            {
                "name": "Mancozeb",
                "dosage": "2.5 g/L water",
                "application": "Foliar spray",
                "frequency": "Every 7 days during infection",
            },
        ],
        "organic": [
            {
                "name": "Neem Oil",
                "dosage": "5 ml/L water",
                "application": "Foliar spray in evening",
                "frequency": "Weekly",
            },
            {
                "name": "Copper Fungicide",
                "dosage": "3 g/L water",
                "application": "Foliar spray",
                "frequency": "Every 7-14 days",
            },
        ],
        "steps": [
            "Remove and destroy infected leaves immediately",
            "Apply fungicide to remaining foliage",
            "Improve air circulation around plants",
            "Water at soil level, avoid wetting leaves",
            "Apply mulch to prevent soil splash",
        ],
        "prevention": "Use disease-resistant varieties, practice crop rotation, maintain proper spacing",
        "warnings": "Wear protective gear when applying fungicides. Do not apply during flowering if bees are active.",
    },
    "Late Blight": {
        "description": "Severe fungal disease causing water-soaked lesions that turn brown",
        "chemical": [
            {
                "name": "Metalaxyl + Mancozeb",
                "dosage": "2.5 g/L water",
                "application": "Foliar spray",
                "frequency": "Every 5-7 days",
            },
            {
                "name": "Cymoxanil + Mancozeb",
                "dosage": "3 g/L water",
                "application": "Foliar spray",
                "frequency": "Every 7 days",
            },
        ],
        "organic": [
            {
                "name": "Copper Hydroxide",
                "dosage": "3-4 g/L water",
                "application": "Foliar spray",
                "frequency": "Every 5-7 days",
            },
        ],
        "steps": [
            "Act immediately - late blight spreads rapidly",
            "Remove and destroy all infected plant parts",
            "Apply systemic fungicide immediately",
            "Reduce humidity and improve ventilation",
            "Monitor daily for new infections",
        ],
        "prevention": "Plant resistant varieties, avoid overhead irrigation, destroy potato cull piles nearby",
        "warnings": "URGENT: Late blight can destroy entire crop in days. Seek expert help if spreading rapidly.",
    },
    "Leaf Mold": {
        "description": "Fungal disease causing yellow spots on upper leaf surface",
        "chemical": [
            {
                "name": "Azoxystrobin",
                "dosage": "1 ml/L water",
                "application": "Foliar spray",
                "frequency": "Every 7-14 days",
            },
        ],
        "organic": [
            {
                "name": "Potassium Bicarbonate",
                "dosage": "3 g/L water",
                "application": "Foliar spray",
                "frequency": "Weekly",
            },
        ],
        "steps": [
            "Improve greenhouse ventilation",
            "Reduce humidity below 85%",
            "Remove infected leaves",
            "Apply fungicide to remaining foliage",
        ],
        "prevention": "Maintain low humidity, good air circulation, use resistant varieties",
        "warnings": "Common in greenhouses and high humidity areas",
    },
    # Generic treatments for unmapped diseases
    "Fungal Infection": {
        "description": "General fungal disease affecting plant tissues",
        "chemical": [
            {
                "name": "Carbendazim",
                "dosage": "1 g/L water",
                "application": "Foliar spray",
                "frequency": "Every 10-14 days",
            },
        ],
        "organic": [
            {
                "name": "Trichoderma viride",
                "dosage": "5 g/L water",
                "application": "Soil drench and foliar",
                "frequency": "Every 15 days",
            },
        ],
        "steps": [
            "Identify and remove infected parts",
            "Apply appropriate fungicide",
            "Improve drainage and air circulation",
            "Avoid overhead watering",
        ],
        "prevention": "Crop rotation, proper spacing, balanced nutrition",
        "warnings": "Consult local agricultural expert for specific identification",
    },
    "Bacterial Infection": {
        "description": "Bacterial disease causing spots, wilting, or rot",
        "chemical": [
            {
                "name": "Streptomycin Sulphate",
                "dosage": "0.5 g/L water",
                "application": "Foliar spray",
                "frequency": "Every 7-10 days",
            },
        ],
        "organic": [
            {
                "name": "Copper Oxychloride",
                "dosage": "3 g/L water",
                "application": "Foliar spray",
                "frequency": "Weekly",
            },
        ],
        "steps": [
            "Remove and destroy infected plants",
            "Disinfect tools after use",
            "Apply copper-based bactericide",
            "Avoid working with plants when wet",
        ],
        "prevention": "Use disease-free seeds, practice sanitation, avoid plant injuries",
        "warnings": "Bacterial diseases spread easily through water and tools",
    },
    "Healthy": {
        "description": "No disease detected - plant appears healthy",
        "chemical": [],
        "organic": [],
        "steps": [
            "Continue regular maintenance",
            "Monitor for any changes",
            "Maintain proper nutrition",
            "Ensure adequate watering",
        ],
        "prevention": "Regular monitoring, balanced fertilization, proper irrigation",
        "warnings": None,
    },
}


@dataclass
class TreatmentPlan:
    """Complete treatment recommendation."""
    disease: str
    severity: str
    description: str
    chemical_options: List[Dict[str, Any]]
    organic_options: List[Dict[str, Any]]
    treatment_steps: List[Dict[str, Any]]
    prevention: str
    warnings: Optional[str]


class TreatmentService:
    """Service for generating treatment recommendations."""
    
    def __init__(self):
        """Initialize treatment service with knowledge base."""
        self.kb = TREATMENT_KB
    
    def get_treatment(
        self,
        disease: str,
        severity: str,
        crop_type: Optional[str] = None
    ) -> TreatmentPlan:
        """
        Get treatment recommendation for a disease.
        
        Args:
            disease: Disease name
            severity: Severity level (mild, moderate, severe)
            crop_type: Optional crop type for specific recommendations
            
        Returns:
            TreatmentPlan with complete recommendations
        """
        # Look up disease in knowledge base
        treatment_data = self.kb.get(disease) or self.kb.get("Fungal Infection")
        
        # Adjust recommendations based on severity
        steps = treatment_data.get("steps", [])
        numbered_steps = [
            {"step_number": i + 1, "description": step, "timing": self._get_timing(severity, i)}
            for i, step in enumerate(steps)
        ]
        
        # Add urgency for severe cases
        warnings = treatment_data.get("warnings")
        if severity == "severe" and warnings:
            warnings = f"⚠️ URGENT: {warnings}"
        
        return TreatmentPlan(
            disease=disease,
            severity=severity,
            description=treatment_data.get("description", ""),
            chemical_options=treatment_data.get("chemical", []),
            organic_options=treatment_data.get("organic", []),
            treatment_steps=numbered_steps,
            prevention=treatment_data.get("prevention", ""),
            warnings=warnings,
        )
    
    def _get_timing(self, severity: str, step_index: int) -> str:
        """Get recommended timing based on severity."""
        if severity == "severe":
            return "Immediately" if step_index == 0 else "Within 24 hours"
        elif severity == "moderate":
            return "As soon as possible" if step_index == 0 else "Within 2-3 days"
        else:
            return "When convenient" if step_index == 0 else "Within a week"
    
    def to_json_response(self, plan: TreatmentPlan) -> Dict[str, Any]:
        """Convert treatment plan to JSON response format."""
        return {
            "steps": plan.treatment_steps,
            "chemical": plan.chemical_options,
            "organic": plan.organic_options,
            "description": plan.description,
            "prevention": plan.prevention,
        }


# Singleton instance
_treatment_service: Optional[TreatmentService] = None


def get_treatment_service() -> TreatmentService:
    """Get or create treatment service instance."""
    global _treatment_service
    if _treatment_service is None:
        _treatment_service = TreatmentService()
    return _treatment_service

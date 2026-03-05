"""
ML Service - Disease Detection Model Integration
"""
import os
import random
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)

# Simulated crop diseases database
CROP_DISEASES = {
    "tomato": [
        {"name": "Early Blight", "severity_range": (0.3, 0.9)},
        {"name": "Late Blight", "severity_range": (0.5, 1.0)},
        {"name": "Leaf Mold", "severity_range": (0.2, 0.7)},
        {"name": "Septoria Leaf Spot", "severity_range": (0.3, 0.8)},
        {"name": "Spider Mites", "severity_range": (0.2, 0.6)},
        {"name": "Target Spot", "severity_range": (0.3, 0.7)},
        {"name": "Bacterial Spot", "severity_range": (0.4, 0.8)},
        {"name": "Healthy", "severity_range": (0.0, 0.0)},
    ],
    "potato": [
        {"name": "Early Blight", "severity_range": (0.3, 0.8)},
        {"name": "Late Blight", "severity_range": (0.5, 1.0)},
        {"name": "Black Leg", "severity_range": (0.4, 0.9)},
        {"name": "Healthy", "severity_range": (0.0, 0.0)},
    ],
    "corn": [
        {"name": "Northern Leaf Blight", "severity_range": (0.3, 0.8)},
        {"name": "Gray Leaf Spot", "severity_range": (0.3, 0.7)},
        {"name": "Common Rust", "severity_range": (0.2, 0.6)},
        {"name": "Healthy", "severity_range": (0.0, 0.0)},
    ],
    "wheat": [
        {"name": "Leaf Rust", "severity_range": (0.3, 0.8)},
        {"name": "Powdery Mildew", "severity_range": (0.2, 0.7)},
        {"name": "Septoria", "severity_range": (0.3, 0.8)},
        {"name": "Healthy", "severity_range": (0.0, 0.0)},
    ],
    "rice": [
        {"name": "Bacterial Blight", "severity_range": (0.4, 0.9)},
        {"name": "Brown Spot", "severity_range": (0.3, 0.7)},
        {"name": "Leaf Blast", "severity_range": (0.4, 0.9)},
        {"name": "Healthy", "severity_range": (0.0, 0.0)},
    ],
    "default": [
        {"name": "Fungal Infection", "severity_range": (0.3, 0.8)},
        {"name": "Bacterial Infection", "severity_range": (0.4, 0.9)},
        {"name": "Viral Infection", "severity_range": (0.3, 0.7)},
        {"name": "Nutrient Deficiency", "severity_range": (0.2, 0.6)},
        {"name": "Pest Damage", "severity_range": (0.3, 0.7)},
        {"name": "Healthy", "severity_range": (0.0, 0.0)},
    ],
}


@dataclass
class MLPrediction:
    """ML model prediction result."""
    disease: str
    disease_id: str
    confidence: float
    severity: str
    severity_score: float
    additional_predictions: List[Dict[str, Any]]


class MLService:
    """
    Machine Learning service for crop disease detection.
    
    Currently uses simulated predictions. Replace with actual
    PyTorch model integration for production.
    """
    
    def __init__(self):
        """Initialize ML service."""
        self.model = None
        self._load_model()
    
    def _load_model(self) -> None:
        """
        Load the ML model.
        
        TODO: Replace with actual PyTorch model loading:
        ```python
        import torch
        self.model = torch.load('path/to/model.pth')
        self.model.eval()
        ```
        """
        logger.info("ML Service initialized (simulation mode)")
    
    def _preprocess_image(self, image_path: str) -> Any:
        """
        Preprocess image for model inference.
        
        TODO: Implement actual preprocessing:
        ```python
        import cv2
        import numpy as np
        
        img = cv2.imread(image_path)
        img = cv2.resize(img, (224, 224))
        img = img / 255.0
        img = np.transpose(img, (2, 0, 1))
        return torch.tensor(img).unsqueeze(0).float()
        ```
        """
        return image_path
    
    def _get_severity_label(self, score: float) -> str:
        """Convert severity score to label."""
        if score < 0.3:
            return "mild"
        elif score < 0.6:
            return "moderate"
        else:
            return "severe"
    
    def predict(
        self,
        image_path: str,
        crop_type: Optional[str] = None
    ) -> MLPrediction:
        """
        Predict disease from crop image.
        
        Args:
            image_path: Path to the image file
            crop_type: Optional crop type for targeted detection
            
        Returns:
            MLPrediction with disease, confidence, and severity
        """
        # Get disease list for crop type
        crop_key = (crop_type or "default").lower()
        if crop_key not in CROP_DISEASES:
            crop_key = "default"
        
        diseases = CROP_DISEASES[crop_key]
        
        # Simulate model prediction
        # In production, replace with actual inference:
        # preprocessed = self._preprocess_image(image_path)
        # with torch.no_grad():
        #     output = self.model(preprocessed)
        #     probabilities = torch.softmax(output, dim=1)
        
        # Simulate prediction (weighted towards diseases, not healthy)
        weights = [0.9 if d["name"] != "Healthy" else 0.1 for d in diseases]
        total_weight = sum(weights)
        weights = [w / total_weight for w in weights]
        
        primary_disease = random.choices(diseases, weights=weights, k=1)[0]
        
        # Generate confidence score
        confidence = random.uniform(0.75, 0.98)
        
        # Generate severity
        if primary_disease["name"] == "Healthy":
            severity_score = 0.0
        else:
            severity_score = random.uniform(*primary_disease["severity_range"])
        
        severity_label = self._get_severity_label(severity_score)
        
        # Generate additional predictions (top 3)
        other_diseases = [d for d in diseases if d["name"] != primary_disease["name"]]
        additional = []
        remaining_conf = 1.0 - confidence
        
        for i, disease in enumerate(random.sample(other_diseases, min(2, len(other_diseases)))):
            add_conf = remaining_conf * (0.6 if i == 0 else 0.4)
            additional.append({
                "disease": disease["name"],
                "confidence": round(add_conf, 3),
            })
        
        logger.info(
            f"ML Prediction: {primary_disease['name']} "
            f"(confidence: {confidence:.2f}, severity: {severity_label})"
        )
        
        disease_id = f"{crop_key}_{primary_disease['name']}".lower().replace(" ", "_").replace("-", "_")
        
        return MLPrediction(
            disease=primary_disease["name"],
            disease_id=disease_id,
            confidence=round(confidence, 3),
            severity=severity_label,
            severity_score=round(severity_score, 3),
            additional_predictions=additional,
        )
    
    def validate_prediction(
        self,
        prediction: MLPrediction,
        crop_type: Optional[str] = None
    ) -> Tuple[bool, Optional[str]]:
        """
        Validate prediction with agronomy rules.
        
        Args:
            prediction: ML prediction to validate
            crop_type: Optional crop type for validation
            
        Returns:
            Tuple of (is_valid, warning_message)
        """
        # Basic validation rules
        if prediction.confidence < 0.5:
            return False, "Low confidence prediction - manual verification recommended"
        
        if prediction.disease == "Healthy" and prediction.severity != "mild":
            return False, "Invalid: Healthy plant cannot have severity"
        
        return True, None


# Singleton instance
_ml_service: Optional[MLService] = None


def get_ml_service() -> MLService:
    """Get or create ML service instance."""
    global _ml_service
    if _ml_service is None:
        _ml_service = MLService()
    return _ml_service

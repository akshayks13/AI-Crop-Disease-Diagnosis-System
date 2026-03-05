"""
ML Service - Disease Detection Model Integration
"""
import os
import random
import logging
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass

try:
    import numpy as np
    from PIL import Image
    import tensorflow as tf
except ImportError:
    pass

logger = logging.getLogger(__name__)


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
        self.interpreter = None
        self.input_details = None
        self.output_details = None
        self.keras_model = None
        self.labels = []
        self._load_model()

    def _resolve_model_assets(
        self,
        candidate_dirs: List[str],
        model_filename: str,
        labels_filename: str = "labels.txt",
    ) -> Tuple[str, str, str]:
        """
        Return (models_dir, model_path, labels_path) for the first directory
        that contains the required files.
        """
        for d in candidate_dirs:
            if not os.path.isdir(d):
                continue
            model_path = os.path.join(d, model_filename)
            labels_path = os.path.join(d, labels_filename)
            if os.path.exists(model_path) and os.path.exists(labels_path):
                return d, model_path, labels_path

        raise FileNotFoundError(
            f"Required model assets not found. Tried dirs: {candidate_dirs}, "
            f"model: {model_filename}, labels: {labels_filename}"
        )
    
    def _load_model(self) -> None:
        """Load the TFLite model and labels."""
        try:
            import tensorflow as tf
            
            # Resolve ml_models directory from known project layouts.
            # Typical repo layout:
            #   <repo>/backend/app/services/ml_service.py
            #   <repo>/ml_models/*
            current_file = os.path.abspath(__file__)
            services_dir = os.path.dirname(current_file)
            app_dir = os.path.dirname(services_dir)
            backend_dir = os.path.dirname(app_dir)
            repo_root = os.path.dirname(backend_dir)

            candidate_dirs = [
                os.path.join(app_dir, "ml_models"),      # legacy: backend/app/ml_models
                os.path.join(backend_dir, "ml_models"),  # backend/ml_models
                os.path.join(repo_root, "ml_models"),    # repo-root/ml_models
            ]

            _, model_path, labels_path = self._resolve_model_assets(
                candidate_dirs=candidate_dirs,
                model_filename="Disease_Classification_v2_compressed.tflite",
                labels_filename="labels.txt",
            )
            
            logger.info(f"Attempting to load TFLite model from: {model_path}")
            
            if not os.path.exists(model_path):
                raise FileNotFoundError(f"Model file not found at {model_path}")
            if not os.path.exists(labels_path):
                raise FileNotFoundError(f"Labels file not found at {labels_path}")

            # Load labels
            with open(labels_path, "r") as f:
                self.labels = [line.strip() for line in f.readlines() if line.strip()]
            
            # Load TFLite model
            self.interpreter = tf.lite.Interpreter(model_path=model_path)
            self.interpreter.allocate_tensors()
            self.input_details = self.interpreter.get_input_details()
            self.output_details = self.interpreter.get_output_details()
            
            logger.info(f"SUCCESS: Loaded TFLite model. Labels count: {len(self.labels)}")
        except Exception as e:
            logger.error(f"CRITICAL: Failed to load TFLite model: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            self._load_keras_fallback()

    def _load_keras_fallback(self) -> None:
        """Fallback to Keras model if TFLite cannot initialize (e.g., Flex ops)."""
        try:
            import tensorflow as tf

            current_file = os.path.abspath(__file__)
            services_dir = os.path.dirname(current_file)
            app_dir = os.path.dirname(services_dir)
            backend_dir = os.path.dirname(app_dir)
            repo_root = os.path.dirname(backend_dir)

            candidate_dirs = [
                os.path.join(app_dir, "ml_models"),
                os.path.join(backend_dir, "ml_models"),
                os.path.join(repo_root, "ml_models"),
            ]

            _, keras_path, labels_path = self._resolve_model_assets(
                candidate_dirs=candidate_dirs,
                model_filename="Disease_Classification_v2.keras",
                labels_filename="labels.txt",
            )

            # Ensure labels are available even if TFLite failed before loading them.
            if not self.labels:
                with open(labels_path, "r") as f:
                    self.labels = [line.strip() for line in f.readlines() if line.strip()]

            self.keras_model = tf.keras.models.load_model(keras_path, compile=False)
            logger.info("SUCCESS: Loaded Keras fallback model")
        except Exception as e:
            logger.error(f"CRITICAL: Failed to load Keras fallback model: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
    
    def _preprocess_image(self, image_path: str) -> Any:
        """Preprocess image for model inference."""
        from PIL import Image
        import numpy as np
        import os
        from app.config import get_settings
        
        # Convert /uploads/ URL path to local filesystem path
        if image_path.startswith('/uploads/'):
            settings = get_settings()
            # Remove /uploads/ prefix and normalize slashes for Windows
            rel_path = image_path[len('/uploads/'):].replace('\\', '/')
            local_path = os.path.join(settings.upload_dir, rel_path)
        else:
            local_path = image_path
            
        img = Image.open(local_path).convert('RGB')
        img = img.resize((224, 224))
        
        # Convert to numpy and normalize to [-1, 1]
        # Insight from user's FaceAuth code: maps 0-255 to -1.0-1.0
        img_array = np.array(img, dtype=np.float32)
        img_array = (img_array / 127.5) - 1.0
        
        # Add batch dimension
        img_array = np.expand_dims(img_array, axis=0)
        return img_array
    
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
        """Predict disease from crop image using TFLite model."""
        import numpy as np
        
        if self.interpreter is None or self.input_details is None:
            # Try reloading once if it failed at startup
            logger.info("TFLite interpreter not initialized. Attempting reload...")
            self._load_model()

        preprocessed = self._preprocess_image(image_path)

        if self.interpreter is not None and self.input_details is not None:
            self.interpreter.set_tensor(self.input_details[0]['index'], preprocessed)
            self.interpreter.invoke()
            output_data = self.interpreter.get_tensor(self.output_details[0]['index'])
            preds = np.squeeze(output_data)
        elif self.keras_model is not None:
            output_data = self.keras_model.predict(preprocessed, verbose=0)
            preds = np.squeeze(output_data)
            logger.info("Prediction served by Keras fallback model")
        else:
            raise RuntimeError(
                "ML model is not initialized (TFLite and Keras fallback unavailable). "
                "Check server logs for load errors."
            )
        
        # Optionally apply softmax if outputs are raw logits
        if np.max(preds) > 1.0 or np.min(preds) < 0.0:
            exp_preds = np.exp(preds - np.max(preds))
            preds = exp_preds / np.sum(exp_preds)
            
        # Get top indices
        top_indices = np.argsort(preds)[::-1][:3]
        
        primary_idx = top_indices[0]
        disease_id = self.labels[primary_idx] if primary_idx < len(self.labels) else "unknown"
        confidence = float(preds[primary_idx])
        
        disease_display = " ".join(disease_id.split('_')).title()
        
        if "healthy" in disease_id.lower():
            severity_score = 0.0
            severity_label = "mild"
        else:
            severity_score = min(max(confidence - 0.2, 0.3), 0.9)
            severity_label = self._get_severity_label(severity_score)
            
        additional = []
        for idx in top_indices[1:]:
            label = self.labels[idx] if idx < len(self.labels) else "unknown"
            conf = float(preds[idx])
            additional.append({
                "disease": " ".join(label.split('_')).title(),
                "confidence": round(conf, 3)
            })
            
        logger.info(
            f"TFLite Prediction: {disease_display} "
            f"(confidence: {confidence:.2f}, severity: {severity_label})"
        )
        
        return MLPrediction(
            disease=disease_display,
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

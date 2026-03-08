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
    
    def _candidate_dirs(self) -> List[str]:
        """Return candidate ml_models directories in search order."""
        current_file = os.path.abspath(__file__)
        app_dir = os.path.dirname(os.path.dirname(current_file))
        backend_dir = os.path.dirname(app_dir)
        repo_root = os.path.dirname(backend_dir)
        return [
            os.path.join(app_dir, "ml_models"),      # backend/app/ml_models  ← committed
            os.path.join(backend_dir, "ml_models"),  # backend/ml_models
            os.path.join(repo_root, "ml_models"),    # repo-root/ml_models
        ]

    def _load_model(self) -> None:
        """
        Load the ML model for disease inference.

        Strategy (server has full TensorFlow installed):
          1. Keras v2  — most accurate, large file (only present if committed/LFS)
          2. Keras v1  — smaller (2.9 MB), committed to backend/app/ml_models
          3. TFLite    — last resort; may fail on Flex ops (SELECT_TF_OPS models)
        """
        import traceback
        candidate_dirs = self._candidate_dirs()

        # ── 1. Try Keras models (preferred on server with full TF) ──────────
        for keras_filename in (
            "Disease_Classification_v2.keras",
            "Disease_Classification_v1.keras",
        ):
            try:
                import tensorflow as tf
                _, keras_path, labels_path = self._resolve_model_assets(
                    candidate_dirs=candidate_dirs,
                    model_filename=keras_filename,
                    labels_filename="labels.txt",
                )
                with open(labels_path, "r") as f:
                    self.labels = [line.strip() for line in f if line.strip()]
                self.keras_model = tf.keras.models.load_model(keras_path, compile=False)
                logger.info(f"SUCCESS: Loaded Keras model '{keras_filename}'. Labels: {len(self.labels)}")
                return
            except FileNotFoundError:
                continue  # not available in any candidate dir, try next
            except Exception as e:
                logger.warning(f"Keras load failed for '{keras_filename}': {e}")
                logger.debug(traceback.format_exc())
                continue

        # ── 2. Fallback: TFLite (may fail on Flex/SELECT_TF_OPS models) ─────
        try:
            import tensorflow as tf
            _, model_path, labels_path = self._resolve_model_assets(
                candidate_dirs=candidate_dirs,
                model_filename="Disease_Classification_v2_compressed.tflite",
                labels_filename="labels.txt",
            )
            with open(labels_path, "r") as f:
                self.labels = [line.strip() for line in f if line.strip()]
            logger.info(f"Attempting TFLite load from: {model_path}")
            self.interpreter = tf.lite.Interpreter(model_path=model_path)
            self.interpreter.allocate_tensors()
            self.input_details = self.interpreter.get_input_details()
            self.output_details = self.interpreter.get_output_details()
            logger.info(f"SUCCESS: Loaded TFLite model. Labels: {len(self.labels)}")
        except Exception as e:
            logger.error(f"CRITICAL: All model loading strategies failed. Last error: {e}")
            logger.error(traceback.format_exc())

    def _load_keras_fallback(self) -> None:
        """Kept for compatibility — logic now lives in _load_model."""
        self._load_model()
    
    def _preprocess_image(self, image_path: str) -> Any:
        """Preprocess image for model inference."""
        import io
        import os
        import urllib.request

        import numpy as np
        from PIL import Image
        from app.config import get_settings

        # Remote URL (Cloudinary or any https/http) — download into memory
        if image_path.startswith("https://") or image_path.startswith("http://"):
            logger.info(f"Downloading image for inference: {image_path}")
            try:
                with urllib.request.urlopen(image_path, timeout=30) as resp:
                    img_bytes = resp.read()
            except Exception as exc:
                raise FileNotFoundError(
                    f"Failed to download image from {image_path}: {exc}"
                ) from exc
            img = Image.open(io.BytesIO(img_bytes)).convert("RGB")

        else:
            # Convert /uploads/ URL path to local filesystem path
            if image_path.startswith("/uploads/"):
                settings = get_settings()
                rel_path = image_path[len("/uploads/"):].replace("\\", "/")
                local_path = os.path.abspath(
                    os.path.join(settings.upload_dir, rel_path)
                )
            else:
                local_path = os.path.abspath(image_path)

            logger.info(f"Preprocessing image from: {local_path}")
            if not os.path.exists(local_path):
                raise FileNotFoundError(f"Image not found at {local_path}")
            img = Image.open(local_path).convert("RGB")

        img = img.resize((224, 224))
        # Convert to numpy and apply ResNet50 preprocessing
        # RGB to BGR then subtract ImageNet mean
        img_array = np.array(img, dtype=np.float32)
        img_array = img_array[..., ::-1]
        img_array[..., 0] -= 103.939  # B
        img_array[..., 1] -= 116.779  # G
        img_array[..., 2] -= 123.68   # R
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
        
        if self.interpreter is None and self.keras_model is None:
            # Try reloading once if startup load failed entirely
            logger.info("No model loaded. Attempting reload...")
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

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
        # 'v1' = simple CNN trained on raw [0,255] RGB pixels
        # 'v2' = ResNet50 backbone trained with resnet50.preprocess_input
        self._model_version: str = "v2"  # default; updated in _load_model
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

        Priority order:
          1. Keras v2            — 322 MB, only on paid/LFS deployments
          2. TFLite v2 compressed — 46 MB, works locally (full TF); fails on Render (FlexPad)
          3. TFLite v2 noflex    — 23 MB, works everywhere (no Flex ops)
          4. Keras v1            — 2.9 MB, last resort; simpler CNN, lower accuracy
        """
        import traceback
        candidate_dirs = self._candidate_dirs()

        # ── 1. Try Keras v2 (best quality, large – only on paid/LFS deployments) ──
        try:
            import tensorflow as tf
            _, keras_path, labels_path = self._resolve_model_assets(
                candidate_dirs=candidate_dirs,
                model_filename="Disease_Classification_v2.keras",
                labels_filename="labels.txt",
            )
            with open(labels_path, "r") as f:
                self.labels = [line.strip() for line in f if line.strip()]
            self.keras_model = tf.keras.models.load_model(keras_path, compile=False)
            self._model_version = "v2"
            logger.info(f"SUCCESS: Loaded Keras v2 model (version=v2). Labels: {len(self.labels)}")
            return
        except FileNotFoundError:
            logger.info("Keras v2 not found in candidate dirs, trying TFLite v2...")
        except Exception as e:
            logger.warning(f"Keras v2 load failed: {e}")
            logger.debug(traceback.format_exc())

        # ── 2. TFLite v2 compressed — 46 MB (loads locally with full TF; fails on Render due to FlexPad) ──
        try:
            import tensorflow as tf
            _, model_path, labels_path = self._resolve_model_assets(
                candidate_dirs=candidate_dirs,
                model_filename="Disease_Classification_v2_compressed.tflite",
                labels_filename="labels.txt",
            )
            with open(labels_path, "r") as f:
                self.labels = [line.strip() for line in f if line.strip()]
            logger.info(f"Attempting TFLite v2 compressed load from: {model_path}")
            self.interpreter = tf.lite.Interpreter(model_path=model_path)
            self.interpreter.allocate_tensors()
            self.input_details = self.interpreter.get_input_details()
            self.output_details = self.interpreter.get_output_details()
            self._model_version = "v2"
            logger.info(f"SUCCESS: Loaded TFLite v2 compressed model. Labels: {len(self.labels)}")
            return
        except FileNotFoundError:
            logger.warning("TFLite v2 compressed not found, trying noflex...")
        except Exception as e:
            logger.warning(f"TFLite v2 compressed load failed: {e}")
            logger.debug(traceback.format_exc())

        # ── 3. TFLite v2 noflex — 23 MB (no Flex ops, works everywhere) ──
        try:
            import tensorflow as tf
            _, model_path, labels_path = self._resolve_model_assets(
                candidate_dirs=candidate_dirs,
                model_filename="Disease_Classification_v2_noflex.tflite",
                labels_filename="labels.txt",
            )
            with open(labels_path, "r") as f:
                self.labels = [line.strip() for line in f if line.strip()]
            logger.info(f"Attempting TFLite v2 (noflex) load from: {model_path}")
            self.interpreter = tf.lite.Interpreter(model_path=model_path)
            self.interpreter.allocate_tensors()
            self.input_details = self.interpreter.get_input_details()
            self.output_details = self.interpreter.get_output_details()
            self._model_version = "v2"
            logger.info(f"SUCCESS: Loaded TFLite v2 noflex model. Labels: {len(self.labels)}")
            return
        except FileNotFoundError:
            logger.warning("TFLite v2 noflex not found, falling back to Keras v1...")
        except Exception as e:
            logger.warning(f"TFLite v2 noflex load failed: {e}")
            logger.debug(traceback.format_exc())

        # ── 3. Keras v1 — 2.9 MB last resort, lower accuracy ────────────────
        try:
            import tensorflow as tf
            _, keras_path, labels_path = self._resolve_model_assets(
                candidate_dirs=candidate_dirs,
                model_filename="Disease_Classification_v1.keras",
                labels_filename="labels.txt",
            )
            with open(labels_path, "r") as f:
                self.labels = [line.strip() for line in f if line.strip()]
            self.keras_model = tf.keras.models.load_model(keras_path, compile=False)
            self._model_version = "v1"
            logger.info(f"SUCCESS: Loaded Keras v1 model (version=v1). Labels: {len(self.labels)}")
            return
        except FileNotFoundError:
            pass
        except Exception as e:
            logger.warning(f"Keras v1 load failed: {e}")
            logger.debug(traceback.format_exc())

        logger.error("CRITICAL: All model loading strategies failed. Check model files in backend/app/ml_models/")

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
        img_array = np.array(img, dtype=np.float32)

        if self._model_version == "v1":
            # V1 is a simple custom CNN trained on raw [0, 255] RGB pixels
            # (tf.keras.utils.image_dataset_from_directory default, no Rescaling layer)
            pass  # img_array already in [0, 255] RGB — correct for v1
        else:
            # V2 / TFLite use ResNet50 backbone: apply resnet50.preprocess_input
            # (RGB → BGR, subtract ImageNet channel means)
            img_array = img_array[..., ::-1]   # RGB to BGR
            img_array[..., 0] -= 103.939       # B
            img_array[..., 1] -= 116.779       # G
            img_array[..., 2] -= 123.68        # R

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

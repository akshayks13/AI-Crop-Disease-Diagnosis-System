# Machine Learning (ML) Documentation

## Overview

The Machine Learning (ML) component of the AI Crop Disease Diagnosis System is responsible for analyzing crop images to detect diseases, assess severity, and provide confidence scores. It is designed as a standalone service (`MLService`) within the backend application, ensuring modularity and easy replacement of the underlying inference engine.

## Architecture

The ML logic is encapsulated in the `MLService` class located in `backend/app/services/ml_service.py`. It interacts with the rest of the system primarily through the `DiagnosisService`.

### Key Components

1.  **MLService**: The core class handling model loading, image preprocessing, prediction, and validation.
2.  **MLPrediction**: A data class defining the standardized output format for predictions.
3.  **DiagnosisService**: Investigates the ML prediction and combines it with treatment recommendations.

## Current Implementation (Simulation Mode)

Currently, the system runs in a **simulation mode**. This allows for frontend and backend development to proceed without requiring a fully trained heavy deep learning model to be loaded in memory.

### Features of Simulation Mode

*   **Simulated Knowledge Base**: A predefined dictionary `CROP_DISEASES` contains common diseases and their severity ranges for supported crops:
    *   **Tomato**: Early Blight, Late Blight, Leaf Mold, etc.
    *   **Potato**: Early Blight, Late Blight, Black Leg, etc.
    *   **Corn**: Northern Leaf Blight, Gray Leaf Spot, etc.
    *   **Wheat**: Leaf Rust, Powdery Mildew, etc.
    *   **Rice**: Bacterial Blight, Brown Spot, etc.

*   **Randomized Inference**:
    *   The `predict` method selects a disease based on weighted probabilities (skewed towards finding a disease vs. healthy for testing purposes).
    *   **Confidence Scores**: Generated randomly between 0.75 and 0.98.
    *   **Severity Assessment**: A random severity score is generated within the specific range defined for the chosen disease. This score is then mapped to a label:
        *   `< 0.3`: **Mild**
        *   `< 0.6`: **Moderate**
        *   `>= 0.6`: **Severe**

*   **Additional Predictions**: The system simulates top-3 predictions by selecting other random diseases and assigning them lower confidence scores.

## Future Implementation (Production ML)

The `MLService` is structured to easily swap the simulation logic with actual Deep Learning inference.

### Planned Integration Steps

1.  **Model Loading (`_load_model`)**:
    *   Will utilize frameworks like **PyTorch** or **TensorFlow/Keras**.
    *   The model (e.g., a `.pth` or `.h5` file) will be loaded into memory upon service initialization.
    *   GPU support will be enabled if available.

    ```python
    # Example Future Implementation
    import torch
    self.model = torch.load('path/to/model.pth')
    self.model.eval()
    ```

2.  **Preprocessing (`_preprocess_image`)**:
    *   Input images will be processed to match the training data requirements.
    *   Steps will likely include:
        *   Resizing (e.g., to 224x224 pixels).
        *   Normalization (scaling pixel values).
        *   Tensor conversion.

    ```python
    # Example Future Implementation
    import cv2
    img = cv2.imread(image_path)
    img = cv2.resize(img, (224, 224))
    img = img / 255.0
    # ... tensor conversion
    ```

3.  **Inference (`predict`)**:
    *   The preprocessed image will be passed through the neural network.
    *   Softmax will be applied to the output logits to get probabilities.
    *   The class with the highest probability will be the result.

## Data Models

### MLPrediction

The standard output format for the ML service:

| Field | Type | Description |
| :--- | :--- | :--- |
| `disease` | `str` | Name of the detected disease |
| `confidence` | `float` | Probability score (0.0 - 1.0) |
| `severity` | `str` | Textual label (mild, moderate, severe) |
| `severity_score` | `float` | Numerical severity indicator |
| `additional_predictions` | `List[Dict]` | List of runner-up predictions |

## Validation Logic

The ML Service includes a `validate_prediction` method to enforce **Agronomy Rules**, ensuring that model outputs make biological sense before being returned to the user.

**Current Rules:**
*   **Confidence Check**: Warnings are issued if the confidence score is below 0.5 (50%).
*   **Logical Consistency**: A "Healthy" classification cannot have a severity level other than "mild" (or 0).

## Usage Example

```python
from app.services.ml_service import get_ml_service

# Get instance
ml_service = get_ml_service()

# Make prediction
prediction = ml_service.predict("path/to/leaf_image.jpg", crop_type="tomato")

print(f"Detected: {prediction.disease}")
print(f"Confidence: {prediction.confidence}")
```
---

## End-to-End Flow

The ML pipeline is triggered after a farmer uploads a crop image from the mobile application.

1. Image is sent from Flutter app to Backend API.
2. Backend stores the image.
3. DiagnosisService calls MLService.
4. MLService generates prediction (simulated or real model).
5. Validation rules are applied.
6. Diagnosis + recommendations are returned to the farmer.

---

## API Integration

The ML predictions are exposed through backend REST endpoints.

Frontend sends:
- image file
- crop type (optional)

Backend returns:
- detected disease
- confidence
- severity
- recommendations

This ensures clear communication between mobile application and ML system.
 ---

## Error Handling Strategy

The ML service is designed to fail safely.

- If the model is not loaded → fallback to simulation.
- If image preprocessing fails → return controlled error response.
- If prediction confidence is low → warning is included in output.

This prevents system crashes and ensures a response is always available.

---

## Scalability Considerations

The MLService is modular and can be replaced with:

- Cloud inference APIs
- Containerized GPU services
- Batch prediction systems

without changing the frontend or business logic.

---

## Why Simulation Mode is Important

Simulation mode allows:

- Frontend testing without waiting for model training
- API contract verification
- UI/UX validation
- Faster development cycles

This ensures parallel development across teams.

---

## Testing Support

Because the system currently uses simulation mode:

- predictable response formats are guaranteed
- UI testing can validate all severity levels
- integration tests can run without GPU or large model files

This significantly improves development and debugging speed.
 ---
## Future Enhancements

- Real-time disease localization (bounding boxes)
- Multi-disease detection in one leaf
- Auto crop-type detection
- Model confidence calibration
- Integration with agricultural advisory databases


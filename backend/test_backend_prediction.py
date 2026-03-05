
import os
import sys
import asyncio

# Ensure we can import app
sys.path.append(os.getcwd())

from app.services.ml_service import get_ml_service

async def test_predict():
    ml_service = get_ml_service()
    # Path as stored in DB
    image_path = "/uploads/images/1bf2b9a0-f43b-495c-a5eb-cccac15aa0c4_20260305_171952_b7286914.jpg"
    
    print(f"Testing prediction for: {image_path}")
    try:
        prediction = ml_service.predict(image_path)
        print("\n--- PREDICTION RESULT ---")
        print(f"Disease: {prediction.disease}")
        print(f"Disease ID: {prediction.disease_id}")
        print(f"Confidence: {prediction.confidence}")
        print(f"Severity: {prediction.severity}")
        print(f"Additional: {prediction.additional_predictions}")
        print("-------------------------\n")
    except Exception as e:
        print(f"Error during prediction: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_predict())


import os
import sys

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), "backend"))

from app.services.ml_service import get_ml_service
import asyncio

async def test_predict():
    ml_service = get_ml_service()
    # Path to the tomato image we saw
    image_path = "/uploads/images/1bf2b9a0-f43b-495c-a5eb-cccac15aa0c4_20260305_171952_b7286914.jpg"
    
    print(f"Testing prediction for: {image_path}")
    try:
        prediction = ml_service.predict(image_path)
        print(f"Result: {prediction.disease}")
        print(f"Disease ID: {prediction.disease_id}")
        print(f"Confidence: {prediction.confidence}")
        print(f"Additional: {prediction.additional_predictions}")
    except Exception as e:
        print(f"Error during prediction: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_predict())

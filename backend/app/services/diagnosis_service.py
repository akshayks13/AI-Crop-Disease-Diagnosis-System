"""
Diagnosis Service - Orchestrates ML prediction and treatment recommendation
"""
import uuid
from typing import Dict, Any, Optional
from dataclasses import asdict
import logging

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.diagnosis import Diagnosis
from app.services.ml_service import get_ml_service, MLPrediction
from app.services.treatment_service import get_treatment_service, TreatmentPlan
from app.services.storage_service import get_storage_service

logger = logging.getLogger(__name__)


class DiagnosisService:
    """
    Service for processing crop disease diagnoses.
    
    Orchestrates:
    1. Image upload and storage
    2. ML model prediction
    3. Agronomy validation
    4. Treatment recommendation
    5. Database storage
    """
    
    def __init__(self):
        """Initialize diagnosis service with dependencies."""
        self.ml_service = get_ml_service()
        self.treatment_service = get_treatment_service()
        self.storage_service = get_storage_service()
    
    async def process_diagnosis(
        self,
        image_path: str,
        media_type: str,
        user_id: uuid.UUID,
        crop_type: Optional[str] = None,
        location: Optional[str] = None,
        db: Optional[AsyncSession] = None,
    ) -> Dict[str, Any]:
        """
        Process a crop disease diagnosis.
        
        Args:
            image_path: Path to the uploaded image
            media_type: Type of media (image/video)
            user_id: User requesting diagnosis
            crop_type: Optional crop type
            location: Optional location
            db: Optional database session
            
        Returns:
            Complete diagnosis result with treatment
        """
        logger.info(f"Processing diagnosis for user {user_id}")
        
        # Step 1: Run ML prediction
        prediction = self.ml_service.predict(image_path, crop_type)
        
        # Step 2: Validate prediction
        is_valid, warning = self.ml_service.validate_prediction(
            prediction, crop_type
        )
        
        # Step 3: Get treatment recommendation
        treatment_plan = self.treatment_service.get_treatment(
            prediction.disease,
            prediction.severity,
            crop_type
        )
        
        # Step 4: Build response
        treatment_json = self.treatment_service.to_json_response(treatment_plan)
        
        # Step 5: Create database record if session provided
        diagnosis_id = None
        if db:
            diagnosis = Diagnosis(
                user_id=user_id,
                media_path=image_path,
                media_type=media_type,
                crop_type=crop_type,
                location=location,
                disease=prediction.disease,
                severity=prediction.severity,
                confidence=prediction.confidence,
                treatment=treatment_json,
                prevention=treatment_plan.prevention,
                warnings=treatment_plan.warnings,
                additional_diseases={
                    "predictions": prediction.additional_predictions
                } if prediction.additional_predictions else None,
            )
            db.add(diagnosis)
            await db.flush()
            await db.refresh(diagnosis)
            diagnosis_id = str(diagnosis.id)
        
        # Build final response
        response = {
            "id": diagnosis_id,
            "disease": prediction.disease,
            "severity": prediction.severity,
            "confidence": prediction.confidence,
            "crop_type": crop_type,
            "treatment_steps": treatment_plan.treatment_steps,
            "chemical_options": treatment_plan.chemical_options,
            "organic_options": treatment_plan.organic_options,
            "warnings": treatment_plan.warnings,
            "prevention": treatment_plan.prevention,
            "additional_predictions": prediction.additional_predictions,
            "media_path": image_path,
        }
        
        # Add validation warning if applicable
        if not is_valid and warning:
            response["validation_warning"] = warning
        
        logger.info(
            f"Diagnosis complete: {prediction.disease} "
            f"({prediction.severity}, {prediction.confidence:.2f})"
        )
        
        return response
    
    async def get_diagnosis_history(
        self,
        user_id: uuid.UUID,
        db: AsyncSession,
        page: int = 1,
        page_size: int = 20,
    ) -> Dict[str, Any]:
        """
        Get user's diagnosis history.
        
        Args:
            user_id: User ID
            db: Database session
            page: Page number
            page_size: Items per page
            
        Returns:
            Paginated diagnosis history
        """
        from sqlalchemy import select, func
        
        # Get total count
        count_query = select(func.count(Diagnosis.id)).where(
            Diagnosis.user_id == user_id
        )
        total = (await db.execute(count_query)).scalar()
        
        # Get paginated results
        offset = (page - 1) * page_size
        query = (
            select(Diagnosis)
            .where(Diagnosis.user_id == user_id)
            .order_by(Diagnosis.created_at.desc())
            .offset(offset)
            .limit(page_size)
        )
        
        result = await db.execute(query)
        diagnoses = result.scalars().all()
        
        return {
            "diagnoses": [d.to_response_dict() for d in diagnoses],
            "total": total,
            "page": page,
            "page_size": page_size,
        }


# Singleton instance
_diagnosis_service: Optional[DiagnosisService] = None


def get_diagnosis_service() -> DiagnosisService:
    """Get or create diagnosis service instance."""
    global _diagnosis_service
    if _diagnosis_service is None:
        _diagnosis_service = DiagnosisService()
    return _diagnosis_service

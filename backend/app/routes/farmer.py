"""
Farmer Routes - Diagnosis and Question Endpoints
"""
import uuid
from typing import Optional, List
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models.user import User
from app.models.diagnosis import Diagnosis
from app.models.question import Question, QuestionStatus, Answer
from app.auth.dependencies import get_current_user
from app.services.diagnosis_service import get_diagnosis_service
from app.services.storage_service import get_storage_service
from app.schemas.diagnosis import DiagnosisResponse, DiagnosisSummary
from app.schemas.question import QuestionCreate, QuestionResponse, AnswerResponse

router = APIRouter(prefix="/diagnosis", tags=["Farmer - Diagnosis"])


# ============== Diagnosis Endpoints ==============

@router.post("/predict", response_model=dict)
async def predict_disease(
    file: UploadFile = File(..., description="Crop image or video"),
    crop_type: Optional[str] = Form(None),
    location: Optional[str] = Form(None),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Upload a crop image and get disease diagnosis.
    
    - Accepts JPEG, PNG, WebP images
    - Returns disease name, severity, confidence, and treatment plan
    - Stores diagnosis in history
    - Optionally accepts GPS coordinates for the outbreak map
    """
    storage = get_storage_service()
    diagnosis_service = get_diagnosis_service()
    
    # Save uploaded file
    media_path, media_type = await storage.save_upload(
        file=file,
        user_id=current_user.id,
        category="diagnosis"
    )
    
    # Process diagnosis
    result = await diagnosis_service.process_diagnosis(
        image_path=media_path,
        media_type=media_type,
        user_id=current_user.id,
        crop_type=crop_type,
        location=location,
        db=db,
    )
    
    # Attach GPS coordinates if provided (for disease outbreak map)
    if latitude is not None and longitude is not None and "id" in result:
        try:
            from sqlalchemy import update
            stmt = (
                update(Diagnosis)
                .where(Diagnosis.id == uuid.UUID(result["id"]))
                .values(latitude=latitude, longitude=longitude)
            )
            await db.execute(stmt)
            await db.commit()
        except Exception:
            pass  # Non-critical — don't fail the diagnosis over geo tagging
    
    return result


@router.post("/{diagnosis_id}/save-advisory", response_model=dict)
async def save_diagnosis_advisory(
    diagnosis_id: str,
    body: dict = Body(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Save DSS advisory and disease_id for an existing diagnosis.
    Called by the Flutter app after on-device TFLite prediction + DSS call.
    """
    from sqlalchemy import select, update
    
    # Verify the diagnosis belongs to the user
    query = select(Diagnosis).where(
        Diagnosis.id == diagnosis_id,
        Diagnosis.user_id == current_user.id,
    )
    result = await db.execute(query)
    diagnosis = result.scalar_one_or_none()
    
    if not diagnosis:
        raise HTTPException(status_code=404, detail="Diagnosis not found")
    
    # Update fields
    update_data = {}
    if "disease_id" in body:
        update_data["disease_id"] = body["disease_id"]
    if "dss_advisory" in body:
        update_data["dss_advisory"] = body["dss_advisory"]
    if "disease" in body:
        update_data["disease"] = body["disease"]
    if "plant" in body:
        update_data["crop_type"] = body["plant"]
    if "confidence" in body:
        update_data["confidence"] = body["confidence"]
    if "severity" in body:
        update_data["severity"] = body["severity"]
    if "latitude" in body and body["latitude"] is not None:
        update_data["latitude"] = body["latitude"]
    if "longitude" in body and body["longitude"] is not None:
        update_data["longitude"] = body["longitude"]
    
    if update_data:
        stmt = (
            update(Diagnosis)
            .where(Diagnosis.id == diagnosis_id)
            .values(**update_data)
        )
        await db.execute(stmt)
    
    return {"status": "ok", "updated_fields": list(update_data.keys())}


@router.get("/history", response_model=dict)
async def get_diagnosis_history(
    page: int = 1,
    page_size: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get user's diagnosis history.
    
    - Paginated results
    - Ordered by most recent first
    """
    diagnosis_service = get_diagnosis_service()
    
    result = await diagnosis_service.get_diagnosis_history(
        user_id=current_user.id,
        db=db,
        page=page,
        page_size=page_size,
    )
    
    return result


# ============== Disease Outbreak Map ==============
# NOTE: This MUST be defined BEFORE /{diagnosis_id} routes,
# otherwise FastAPI treats "disease-map" as a diagnosis_id UUID and returns 400.


@router.get("/disease-map", response_model=dict)
async def get_disease_map(
    days: int = 30,
    disease: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    """
    Get geo-tagged diagnoses for the disease outbreak map.

    Returns diagnoses from the last `days` days that have GPS coordinates.
    Optionally filters by disease name.
    No auth required — public data for awareness.
    """
    cutoff = datetime.utcnow() - timedelta(days=days)

    query = (
        select(
            Diagnosis.disease,
            Diagnosis.severity,
            Diagnosis.latitude,
            Diagnosis.longitude,
            Diagnosis.crop_type,
            Diagnosis.created_at,
        )
        .where(
            Diagnosis.latitude.isnot(None),
            Diagnosis.longitude.isnot(None),
            Diagnosis.created_at >= cutoff,
        )
        .order_by(Diagnosis.created_at.desc())
        .limit(500)
    )

    if disease:
        query = query.where(Diagnosis.disease.ilike(f"%{disease}%"))

    result = await db.execute(query)
    rows = result.all()

    outbreaks = [
        {
            "disease": r.disease,
            "severity": r.severity,
            "latitude": r.latitude,
            "longitude": r.longitude,
            "crop_type": r.crop_type,
            "date": r.created_at.isoformat(),
        }
        for r in rows
    ]

    # Collect distinct diseases for filter chips
    disease_names = sorted({r.disease for r in rows})

    return {
        "outbreaks": outbreaks,
        "total": len(outbreaks),
        "diseases": disease_names,
        "days": days,
    }


@router.get("/{diagnosis_id}", response_model=dict)
async def get_diagnosis_detail(
    diagnosis_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get detailed diagnosis by ID."""
    try:
        diag_uuid = uuid.UUID(diagnosis_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid diagnosis ID format"
        )
    
    # Fetch diagnosis
    result = await db.execute(
        select(Diagnosis).where(
            Diagnosis.id == diag_uuid,
            Diagnosis.user_id == current_user.id
        )
    )
    diagnosis = result.scalar_one_or_none()
    
    if not diagnosis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diagnosis not found"
        )
    
    return diagnosis.to_response_dict()


@router.post("/{diagnosis_id}/rate", response_model=dict)
async def rate_diagnosis(
    diagnosis_id: str,
    rating: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Rate a diagnosis result (1-5 stars)."""
    if not 1 <= rating <= 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5"
        )
    
    try:
        diag_uuid = uuid.UUID(diagnosis_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid diagnosis ID format"
        )
    
    # Fetch diagnosis
    result = await db.execute(
        select(Diagnosis).where(
            Diagnosis.id == diag_uuid,
            Diagnosis.user_id == current_user.id
        )
    )
    diagnosis = result.scalar_one_or_none()
    
    if not diagnosis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diagnosis not found"
        )
    
    diagnosis.rating = rating
    await db.commit()
    
    return {"message": "Rating submitted", "rating": rating}



# ============== DSS Advisory Endpoint ==============

@router.post("/dss-advisory", response_model=dict)
async def get_dss_advisory(
    request_body: dict,
    current_user: User = Depends(get_current_user),
):
    """
    Get DSS (Decision Support System) advisory for a diagnosed disease.

    Accepts the TFLite disease label and optional weather/farmer inputs,
    returns risk-scored treatment recommendations.

    Request body:
    {
        "disease_label": "apple_apple_scab",
        "temperature": 28,
        "humidity": 75,
        "irrigation": "Moderate",
        "waterlogged": false,
        "fertilizer_recent": false,
        "first_cycle": false
    }
    """
    from app.services.dss_service import get_dss_service

    disease_label = request_body.get("disease_label")
    if not disease_label:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="disease_label is required"
        )

    weather = {
        "temperature": request_body.get("temperature", 25),
        "humidity": request_body.get("humidity", 60),
    }

    farmer_answers = {
        "irrigation": request_body.get("irrigation", "Moderate"),
        "waterlogged": request_body.get("waterlogged", False),
        "fertilizer_recent": request_body.get("fertilizer_recent", False),
        "first_cycle": request_body.get("first_cycle", False),
    }

    try:
        dss = get_dss_service()
        result = dss.generate_recommendation(
            disease_label=disease_label,
            weather=weather,
            farmer_answers=farmer_answers,
        )
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"DSS advisory generation failed: {str(e)}"
        )


# ============== Question Endpoints ==============

questions_router = APIRouter(prefix="/questions", tags=["Farmer - Questions"])


@questions_router.post("", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_question(
    question_data: QuestionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Submit a question to agricultural experts (JSON body, no file).
    """
    # Parse diagnosis ID if provided
    diag_uuid = None
    media_path = None
    if question_data.diagnosis_id:
        try:
            diag_uuid = uuid.UUID(question_data.diagnosis_id)
            # If diagnosis ID provided, check for existing image to reuse
            diag_result = await db.execute(select(Diagnosis).where(Diagnosis.id == diag_uuid))
            diagnosis = diag_result.scalar_one_or_none()
            if diagnosis and diagnosis.media_path:
                media_path = diagnosis.media_path
        except ValueError:
            pass
    
    # Create question
    question = Question(
        farmer_id=current_user.id,
        question_text=question_data.question_text,
        media_path=media_path,
        diagnosis_id=diag_uuid,
        status=QuestionStatus.OPEN,
    )
    
    db.add(question)
    await db.flush()
    await db.refresh(question)
    
    return {
        "id": str(question.id),
        "question_text": question.question_text,
        "status": question.status.value,
        "created_at": question.created_at.isoformat(),
        "message": "Question submitted successfully. An expert will respond soon."
    }


@questions_router.post("/with-file", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_question_with_file(
    question_text: str = Form(..., min_length=10),
    file: Optional[UploadFile] = File(None),
    diagnosis_id: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Submit a question to agricultural experts with optional file attachment.
    """
    media_path = None
    
    # Handle optional file upload
    if file:
        storage = get_storage_service()
        media_path, _ = await storage.save_upload(
            file=file,
            user_id=current_user.id,
            category="question"
        )
    
    # Parse diagnosis ID if provided
    diag_uuid = None
    if diagnosis_id:
        try:
            diag_uuid = uuid.UUID(diagnosis_id)
            # If no new file uploaded but diagnosis ID provided, check for existing image to reuse
            if not media_path:
                diag_result = await db.execute(select(Diagnosis).where(Diagnosis.id == diag_uuid))
                diagnosis = diag_result.scalar_one_or_none()
                if diagnosis and diagnosis.media_path:
                    media_path = diagnosis.media_path
        except ValueError:
            pass
    
    # Create question
    question = Question(
        farmer_id=current_user.id,
        question_text=question_text,
        media_path=media_path,
        diagnosis_id=diag_uuid,
        status=QuestionStatus.OPEN,
    )
    
    db.add(question)
    await db.flush()
    await db.refresh(question)
    
    return {
        "id": str(question.id),
        "question_text": question.question_text,
        "status": question.status.value,
        "created_at": question.created_at.isoformat(),
        "message": "Question submitted successfully. An expert will respond soon."
    }


@questions_router.get("", response_model=dict)
async def get_my_questions(
    page: int = 1,
    page_size: int = 20,
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's submitted questions."""
    # Build query
    query = select(Question).where(Question.farmer_id == current_user.id)
    count_query = select(func.count(Question.id)).where(
        Question.farmer_id == current_user.id
    )
    
    if status_filter:
        try:
            status_enum = QuestionStatus(status_filter.upper())
            query = query.where(Question.status == status_enum)
            count_query = count_query.where(Question.status == status_enum)
        except ValueError:
            pass
    
    # Get total
    total = (await db.execute(count_query)).scalar()
    
    # Get paginated results
    offset = (page - 1) * page_size
    query = query.order_by(Question.created_at.desc()).offset(offset).limit(page_size)
    
    result = await db.execute(query)
    questions = result.scalars().all()
    
    # Build response
    questions_data = []
    for q in questions:
        # Get answers for this question
        answers_result = await db.execute(
            select(Answer, User)
            .join(User, Answer.expert_id == User.id)
            .where(Answer.question_id == q.id)
            .order_by(Answer.created_at.asc())
        )
        answers = answers_result.all()
        
        questions_data.append({
            "id": str(q.id),
            "question_text": q.question_text,
            "status": q.status.value,
            "media_path": q.media_path,
            "created_at": q.created_at.isoformat(),
            "answer_count": len(answers),
            "answers": [
                {
                    "id": str(a.id),
                    "expert_name": u.full_name,
                    "answer_text": a.answer_text,
                    "rating": a.rating,
                    "created_at": a.created_at.isoformat(),
                }
                for a, u in answers
            ]
        })
    
    return {
        "questions": questions_data,
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@questions_router.get("/{question_id}", response_model=dict)
async def get_question_detail(
    question_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get detailed question with answers."""
    try:
        q_uuid = uuid.UUID(question_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid question ID format"
        )
    
    result = await db.execute(
        select(Question).where(
            Question.id == q_uuid,
            Question.farmer_id == current_user.id
        )
    )
    question = result.scalar_one_or_none()
    
    if not question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Question not found"
        )
    
    # Get answers
    answers_result = await db.execute(
        select(Answer, User)
        .join(User, Answer.expert_id == User.id)
        .where(Answer.question_id == question.id)
        .order_by(Answer.created_at.asc())
    )
    answers = answers_result.all()
    
    return {
        "id": str(question.id),
        "question_text": question.question_text,
        "status": question.status.value,
        "media_path": question.media_path,
        "created_at": question.created_at.isoformat(),
        "answers": [
            {
                "id": str(a.id),
                "expert_id": str(a.expert_id),
                "expert_name": u.full_name,
                "answer_text": a.answer_text,
                "rating": a.rating,
                "created_at": a.created_at.isoformat(),
            }
            for a, u in answers
        ]
    }


@questions_router.post("/{question_id}/rate", response_model=dict)
async def rate_answer(
    question_id: str,
    answer_id: str,
    rating: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Rate an expert's answer (1-5 stars)."""
    if not 1 <= rating <= 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5"
        )
    
    try:
        q_uuid = uuid.UUID(question_id)
        a_uuid = uuid.UUID(answer_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid ID format"
        )
    
    # Verify question belongs to user
    q_result = await db.execute(
        select(Question).where(
            Question.id == q_uuid,
            Question.farmer_id == current_user.id
        )
    )
    if not q_result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Question not found"
        )
    
    # Update answer rating
    a_result = await db.execute(
        select(Answer).where(
            Answer.id == a_uuid,
            Answer.question_id == q_uuid
        )
    )
    answer = a_result.scalar_one_or_none()
    
    if not answer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Answer not found"
        )
    
    answer.rating = rating
    
    return {"message": "Rating submitted", "rating": rating}


@questions_router.put("/{question_id}/close", response_model=dict)
async def close_question(
    question_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Close a question (farmer only). No more answers will be expected."""
    try:
        q_uuid = uuid.UUID(question_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid question ID format"
        )

    result = await db.execute(
        select(Question).where(
            Question.id == q_uuid,
            Question.farmer_id == current_user.id
        )
    )
    question = result.scalar_one_or_none()

    if not question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Question not found"
        )

    question.status = QuestionStatus.CLOSED
    question.updated_at = datetime.utcnow()

    return {"message": "Question closed", "status": "CLOSED"}

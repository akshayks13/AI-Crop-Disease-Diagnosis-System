"""
Farmer Routes - Diagnosis and Question Endpoints
"""
import uuid
from typing import Optional, List
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
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
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Upload a crop image and get disease diagnosis.
    
    - Accepts JPEG, PNG, WebP images
    - Returns disease name, severity, confidence, and treatment plan
    - Stores diagnosis in history
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
    
    return result


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

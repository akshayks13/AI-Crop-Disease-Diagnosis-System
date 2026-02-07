"""
Expert Routes - Question Management and Profile
"""
import uuid
from typing import Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models.user import User, UserRole, UserStatus
from app.models.question import Question, QuestionStatus, Answer
from app.auth.dependencies import get_current_user, require_approved_expert, require_expert

router = APIRouter(prefix="/expert", tags=["Expert"])


# ============== Expert Status ==============

@router.get("/status", response_model=dict)
async def get_expert_status(
    current_user: User = Depends(require_expert),
):
    """
    Get expert approval status.
    
    Returns whether expert is approved to answer questions.
    """
    return {
        "id": str(current_user.id),
        "email": current_user.email,
        "full_name": current_user.full_name,
        "role": current_user.role.value,
        "status": current_user.status.value,
        "is_approved": current_user.is_expert_approved,
        "expertise_domain": current_user.expertise_domain,
        "qualification": current_user.qualification,
        "experience_years": current_user.experience_years,
    }


@router.put("/profile", response_model=dict)
async def update_expert_profile(
    profile_data: dict,
    current_user: User = Depends(require_expert),
    db: AsyncSession = Depends(get_db),
):
    """Update expert profile information."""
    if profile_data.get("full_name"):
        current_user.full_name = profile_data["full_name"]
    if profile_data.get("phone"):
        current_user.phone = profile_data["phone"]
    if profile_data.get("expertise_domain"):
        current_user.expertise_domain = profile_data["expertise_domain"]
    if profile_data.get("qualification"):
        current_user.qualification = profile_data["qualification"]
    if profile_data.get("experience_years") is not None:
        current_user.experience_years = profile_data["experience_years"]
    if profile_data.get("location"):
        current_user.location = profile_data["location"]
    
    current_user.updated_at = datetime.utcnow()
    
    return {
        "message": "Profile updated successfully",
        "profile": {
            "full_name": current_user.full_name,
            "phone": current_user.phone,
            "expertise_domain": current_user.expertise_domain,
            "qualification": current_user.qualification,
            "experience_years": current_user.experience_years,
            "location": current_user.location,
        }
    }


# ============== Questions Management ==============

@router.get("/questions", response_model=dict)
async def get_open_questions(
    page: int = 1,
    page_size: int = 20,
    status_filter: str = "OPEN",
    current_user: User = Depends(require_approved_expert),
    db: AsyncSession = Depends(get_db),
):
    """
    Get open questions for expert to answer.
    
    Only accessible to approved experts.
    """
    # Build query
    query = select(Question, User).join(User, Question.farmer_id == User.id)
    count_query = select(func.count(Question.id))
    
    # Apply status filter
    try:
        status_enum = QuestionStatus(status_filter.upper())
        query = query.where(Question.status == status_enum)
        count_query = count_query.where(Question.status == status_enum)
    except ValueError:
        query = query.where(Question.status == QuestionStatus.OPEN)
        count_query = count_query.where(Question.status == QuestionStatus.OPEN)
    
    # Get total
    total = (await db.execute(count_query)).scalar()
    
    # Paginate
    offset = (page - 1) * page_size
    query = query.order_by(Question.created_at.desc()).offset(offset).limit(page_size)
    
    result = await db.execute(query)
    rows = result.all()
    
    # Build response
    questions_data = []
    for question, farmer in rows:
        # Check if current expert already answered
        answer_check = await db.execute(
            select(func.count(Answer.id)).where(
                Answer.question_id == question.id,
                Answer.expert_id == current_user.id
            )
        )
        already_answered = answer_check.scalar() > 0
        
        questions_data.append({
            "id": str(question.id),
            "farmer_name": farmer.full_name,
            "question_text": question.question_text,
            "media_path": question.media_path,
            "status": question.status.value,
            "created_at": question.created_at.isoformat(),
            "already_answered": already_answered,
        })
    
    return {
        "questions": questions_data,
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.get("/my-answers", response_model=dict)
async def get_my_answers(
    page: int = 1,
    page_size: int = 20,
    current_user: User = Depends(require_approved_expert),
    db: AsyncSession = Depends(get_db),
):
    """Get questions answered by the current expert."""
    # Count total
    count_query = select(func.count(Answer.id)).where(Answer.expert_id == current_user.id)
    total = (await db.execute(count_query)).scalar()
    
    # Get answers with questions
    query = (
        select(Answer, Question, User)
        .join(Question, Answer.question_id == Question.id)
        .join(User, Question.farmer_id == User.id)
        .where(Answer.expert_id == current_user.id)
        .order_by(Answer.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    
    result = await db.execute(query)
    rows = result.all()
    
    answers_data = []
    for answer, question, farmer in rows:
        answers_data.append({
            "id": str(answer.id),
            "question_id": str(question.id),
            "question_text": question.question_text,
            "media_path": question.media_path,
            "farmer_name": farmer.full_name,
            "answer_text": answer.answer_text,
            "rating": answer.rating,
            "answered_at": answer.created_at.isoformat(),
        })
    
    return {
        "answers": answers_data,
        "total": total,
        "page": page,
        "page_size": page_size,
    }
@router.get("/questions/{question_id}", response_model=dict)
async def get_question_detail(
    question_id: str,
    current_user: User = Depends(require_approved_expert),
    db: AsyncSession = Depends(get_db),
):
    """Get detailed question for answering."""
    try:
        q_uuid = uuid.UUID(question_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid question ID"
        )
    
    result = await db.execute(
        select(Question, User)
        .join(User, Question.farmer_id == User.id)
        .where(Question.id == q_uuid)
    )
    row = result.one_or_none()
    
    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Question not found"
        )
    
    question, farmer = row
    
    # Get all answers
    answers_result = await db.execute(
        select(Answer, User)
        .join(User, Answer.expert_id == User.id)
        .where(Answer.question_id == question.id)
        .order_by(Answer.created_at.asc())
    )
    answers = answers_result.all()
    
    return {
        "id": str(question.id),
        "farmer_name": farmer.full_name,
        "farmer_location": farmer.location,
        "question_text": question.question_text,
        "media_path": question.media_path,
        "status": question.status.value,
        "created_at": question.created_at.isoformat(),
        "answers": [
            {
                "id": str(a.id),
                "expert_id": str(a.expert_id),
                "expert_name": u.full_name,
                "answer_text": a.answer_text,
                "rating": a.rating,
                "is_mine": a.expert_id == current_user.id,
                "created_at": a.created_at.isoformat(),
            }
            for a, u in answers
        ]
    }


@router.post("/answer", response_model=dict, status_code=status.HTTP_201_CREATED)
async def submit_answer(
    answer_data: dict,
    current_user: User = Depends(require_approved_expert),
    db: AsyncSession = Depends(get_db),
):
    """
    Submit an answer to a farmer's question.
    
    - Marks question as RESOLVED after first answer
    - Multiple experts can answer the same question
    """
    question_id = answer_data.get("question_id")
    answer_text = answer_data.get("answer_text", "")
    
    if not question_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="question_id is required"
        )
    
    if len(answer_text) < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="answer_text must be at least 10 characters"
        )
    
    try:
        q_uuid = uuid.UUID(question_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid question ID"
        )
    
    # Fetch question
    result = await db.execute(
        select(Question).where(Question.id == q_uuid)
    )
    question = result.scalar_one_or_none()
    
    if not question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Question not found"
        )
    
    # Check if already answered by this expert
    existing = await db.execute(
        select(Answer).where(
            Answer.question_id == q_uuid,
            Answer.expert_id == current_user.id
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You have already answered this question"
        )
    
    # Create answer
    answer = Answer(
        question_id=q_uuid,
        expert_id=current_user.id,
        answer_text=answer_text,
    )
    db.add(answer)
    
    # Mark question as resolved
    question.status = QuestionStatus.RESOLVED
    question.updated_at = datetime.utcnow()
    
    await db.flush()
    await db.refresh(answer)
    
    return {
        "id": str(answer.id),
        "question_id": str(question.id),
        "answer_text": answer.answer_text,
        "created_at": answer.created_at.isoformat(),
        "message": "Answer submitted successfully"
    }


# ============== Expert Statistics ==============

@router.get("/stats", response_model=dict)
async def get_expert_stats(
    current_user: User = Depends(require_expert),
    db: AsyncSession = Depends(get_db),
):
    """Get expert's activity statistics."""
    # Total answers
    answers_count = (await db.execute(
        select(func.count(Answer.id)).where(Answer.expert_id == current_user.id)
    )).scalar()
    
    # Average rating
    avg_rating = (await db.execute(
        select(func.avg(Answer.rating)).where(
            Answer.expert_id == current_user.id,
            Answer.rating.isnot(None)
        )
    )).scalar()
    
    # Ratings breakdown
    ratings = {}
    for i in range(1, 6):
        count = (await db.execute(
            select(func.count(Answer.id)).where(
                Answer.expert_id == current_user.id,
                Answer.rating == i
            )
        )).scalar()
        ratings[str(i)] = count
    
    return {
        "total_answers": answers_count,
        "average_rating": float(round(avg_rating, 2)) if avg_rating else None,
        "ratings_breakdown": ratings,
        "status": current_user.status.value,
        "is_approved": current_user.is_expert_approved,
    }

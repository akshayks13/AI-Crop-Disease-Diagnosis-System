"""
Admin Routes - Expert Approval, Metrics, and User Management
"""
import uuid
from typing import Optional
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.database import get_db
from app.models.user import User, UserRole, UserStatus
from app.models.diagnosis import Diagnosis
from app.models.question import Question, QuestionStatus, Answer
from app.models.system import SystemLog, DailyStats
from app.auth.dependencies import require_admin
from app.services.storage_service import get_storage_service

router = APIRouter(prefix="/admin", tags=["Admin"])


# ============== Dashboard & Metrics ==============

@router.get("/dashboard", response_model=dict)
async def get_dashboard(
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get admin dashboard overview."""
    today = datetime.utcnow().date()
    week_ago = today - timedelta(days=7)
    
    # User counts (excluding admins)
    total_users = (await db.execute(
        select(func.count(User.id)).where(User.role != UserRole.ADMIN)
    )).scalar()
    total_farmers = (await db.execute(
        select(func.count(User.id)).where(User.role == UserRole.FARMER)
    )).scalar()
    total_experts = (await db.execute(
        select(func.count(User.id)).where(User.role == UserRole.EXPERT)
    )).scalar()
    pending_experts = (await db.execute(
        select(func.count(User.id)).where(
            User.role == UserRole.EXPERT,
            User.status == UserStatus.PENDING
        )
    )).scalar()
    
    # Diagnosis counts
    total_diagnoses = (await db.execute(
        select(func.count(Diagnosis.id))
    )).scalar()
    diagnoses_today = (await db.execute(
        select(func.count(Diagnosis.id)).where(
            func.date(Diagnosis.created_at) == today
        )
    )).scalar()
    diagnoses_week = (await db.execute(
        select(func.count(Diagnosis.id)).where(
            func.date(Diagnosis.created_at) >= week_ago
        )
    )).scalar()
    
    # Question counts
    total_questions = (await db.execute(
        select(func.count(Question.id))
    )).scalar()
    open_questions = (await db.execute(
        select(func.count(Question.id)).where(Question.status == QuestionStatus.OPEN)
    )).scalar()
    answered_questions = (await db.execute(
        select(func.count(Question.id)).where(Question.status == QuestionStatus.ANSWERED)
    )).scalar()
    
    # Storage stats
    storage = get_storage_service()
    storage_stats = storage.get_storage_stats()
    
    # Recent signups (last 7 days)
    recent_signups = (await db.execute(
        select(func.count(User.id)).where(
            and_(
                func.date(User.created_at) >= week_ago,
                User.role != UserRole.ADMIN
            )
        )
    )).scalar()
    
    return {
        "metrics": {
            "total_users": total_users,
            "total_farmers": total_farmers,
            "total_experts": total_experts,
            "pending_experts": pending_experts,
            "total_diagnoses": total_diagnoses,
            "total_questions": total_questions,
            "answered_questions": answered_questions,
            "diagnoses_today": diagnoses_today,
            "questions_today": open_questions,
            "storage_used_mb": storage_stats["total_size_mb"],
        },
        "trends": {
            "diagnoses_this_week": diagnoses_week,
            "recent_signups": recent_signups,
            "open_questions": open_questions,
        },
        "system_health": "healthy",  # Could be enhanced with actual health checks
    }


@router.get("/metrics/daily", response_model=dict)
async def get_daily_metrics(
    days: int = Query(default=7, ge=1, le=90),
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get daily metrics for charts."""
    today = datetime.utcnow().date()
    metrics = []
    
    for i in range(days):
        date = today - timedelta(days=i)
        
        diagnoses = (await db.execute(
            select(func.count(Diagnosis.id)).where(
                func.date(Diagnosis.created_at) == date
            )
        )).scalar()
        
        questions = (await db.execute(
            select(func.count(Question.id)).where(
                func.date(Question.created_at) == date
            )
        )).scalar()
        
        signups = (await db.execute(
            select(func.count(User.id)).where(
                func.date(User.created_at) == date
            )
        )).scalar()
        
        metrics.append({
            "date": date.isoformat(),
            "diagnoses": diagnoses,
            "questions": questions,
            "signups": signups,
        })
    
    return {"metrics": list(reversed(metrics))}


# ============== Questions Management ==============

@router.get("/questions", response_model=dict)
async def get_all_questions(
    page: int = 1,
    page_size: int = 20,
    status_filter: Optional[str] = None,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get all farmer questions for admin review (includes media attachments)."""
    query = select(Question)
    count_query = select(func.count(Question.id))
    
    if status_filter:
        try:
            status_enum = QuestionStatus(status_filter.upper())
            query = query.where(Question.status == status_enum)
            count_query = count_query.where(Question.status == status_enum)
        except ValueError:
            pass
    
    total = (await db.execute(count_query)).scalar()
    
    offset = (page - 1) * page_size
    query = query.order_by(Question.created_at.desc()).offset(offset).limit(page_size)
    
    result = await db.execute(query)
    questions = result.scalars().all()
    
    questions_data = []
    for q in questions:
        # Get farmer info
        farmer_result = await db.execute(select(User).where(User.id == q.farmer_id))
        farmer = farmer_result.scalar_one_or_none()
        
        # Get answers
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
            "farmer": {
                "id": str(farmer.id) if farmer else None,
                "name": farmer.full_name if farmer else "Unknown",
                "email": farmer.email if farmer else None,
            },
            "answers": [
                {
                    "id": str(a.id),
                    "expert_name": u.full_name,
                    "answer_text": a.answer_text,
                    "rating": a.rating,
                    "created_at": a.created_at.isoformat(),
                }
                for a, u in answers
            ],
            "answer_count": len(answers),
        })
    
    return {
        "questions": questions_data,
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.put("/questions/{question_id}/close", response_model=dict)
async def admin_close_question(
    question_id: str,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin: Close any question regardless of ownership."""
    try:
        q_uuid = uuid.UUID(question_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid question ID"
        )

    result = await db.execute(
        select(Question).where(Question.id == q_uuid)
    )
    question = result.scalar_one_or_none()

    if not question:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Question not found"
        )

    question.status = QuestionStatus.CLOSED
    question.updated_at = datetime.utcnow()

    return {"message": "Question closed by admin", "status": "CLOSED"}

# ============== Diagnosis Management ==============

@router.get("/diagnoses", response_model=dict)
async def get_all_diagnoses(
    page: int = 1,
    page_size: int = 20,
    crop_type: Optional[str] = None,
    disease: Optional[str] = None,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get all diagnoses for admin review."""
    query = select(Diagnosis)
    count_query = select(func.count(Diagnosis.id))
    
    if crop_type:
        query = query.where(Diagnosis.crop_type.ilike(f"%{crop_type}%"))
        count_query = count_query.where(Diagnosis.crop_type.ilike(f"%{crop_type}%"))
    
    if disease:
        query = query.where(Diagnosis.disease.ilike(f"%{disease}%"))
        count_query = count_query.where(Diagnosis.disease.ilike(f"%{disease}%"))
    
    total = (await db.execute(count_query)).scalar()
    
    offset = (page - 1) * page_size
    query = query.order_by(Diagnosis.created_at.desc()).offset(offset).limit(page_size)
    
    result = await db.execute(query)
    diagnoses = result.scalars().all()
    
    diagnoses_data = []
    for d in diagnoses:
        # Get user info
        user_result = await db.execute(select(User).where(User.id == d.user_id))
        user = user_result.scalar_one_or_none()
        
        diagnoses_data.append({
            "id": str(d.id),
            "created_at": d.created_at.isoformat(),
            "media_path": d.media_path,
            "crop_type": d.crop_type,
            "disease": d.disease,
            "severity": d.severity,
            "confidence": d.confidence,
            "user": {
                "id": str(user.id) if user else None,
                "name": user.full_name if user else "Unknown",
                "email": user.email if user else None,
            },
            "location": d.location
        })
    
    return {
        "diagnoses": diagnoses_data,
        "total": total,
        "page": page,
        "page_size": page_size,
    }


# ============== Expert Approval ==============

@router.get("/experts/pending", response_model=dict)
async def get_pending_experts(
    page: int = 1,
    page_size: int = 20,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get list of experts pending approval."""
    count = (await db.execute(
        select(func.count(User.id)).where(
            User.role == UserRole.EXPERT,
            User.status == UserStatus.PENDING
        )
    )).scalar()
    
    offset = (page - 1) * page_size
    result = await db.execute(
        select(User)
        .where(
            User.role == UserRole.EXPERT,
            User.status == UserStatus.PENDING
        )
        .order_by(User.created_at.desc())
        .offset(offset)
        .limit(page_size)
    )
    experts = result.scalars().all()
    
    return {
        "experts": [
            {
                "id": str(e.id),
                "email": e.email,
                "full_name": e.full_name,
                "phone": e.phone,
                "expertise_domain": e.expertise_domain,
                "qualification": e.qualification,
                "experience_years": e.experience_years,
                "location": e.location,
                "created_at": e.created_at.isoformat(),
            }
            for e in experts
        ],
        "total": count,
        "page": page,
        "page_size": page_size,
    }


@router.post("/experts/approve/{expert_id}", response_model=dict)
async def approve_expert(
    expert_id: str,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Approve an expert application."""
    try:
        e_uuid = uuid.UUID(expert_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid expert ID"
        )
    
    result = await db.execute(
        select(User).where(
            User.id == e_uuid,
            User.role == UserRole.EXPERT
        )
    )
    expert = result.scalar_one_or_none()
    
    if not expert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expert not found"
        )
    
    if expert.status == UserStatus.ACTIVE:
        return {"message": "Expert is already approved"}
    
    expert.status = UserStatus.ACTIVE
    expert.updated_at = datetime.utcnow()
    
    # Log action
    log = SystemLog(
        level="INFO",
        message=f"Expert approved: {expert.email}",
        source="admin",
        user_id=current_user.id,
        log_metadata={"expert_id": str(expert.id)},
    )
    db.add(log)
    
    return {
        "message": "Expert approved successfully",
        "expert_id": str(expert.id),
        "email": expert.email,
    }


@router.post("/experts/reject/{expert_id}", response_model=dict)
async def reject_expert(
    expert_id: str,
    reason: Optional[str] = None,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Reject an expert application."""
    try:
        e_uuid = uuid.UUID(expert_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid expert ID"
        )
    
    result = await db.execute(
        select(User).where(
            User.id == e_uuid,
            User.role == UserRole.EXPERT
        )
    )
    expert = result.scalar_one_or_none()
    
    if not expert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Expert not found"
        )
    
    expert.status = UserStatus.SUSPENDED
    expert.updated_at = datetime.utcnow()
    
    # Log action
    log = SystemLog(
        level="INFO",
        message=f"Expert rejected: {expert.email}",
        source="admin",
        user_id=current_user.id,
        log_metadata={"expert_id": str(expert.id), "reason": reason},
    )
    db.add(log)
    
    return {
        "message": "Expert rejected",
        "expert_id": str(expert.id),
    }


# ============== User Management ==============

@router.get("/users", response_model=dict)
async def get_users(
    page: int = 1,
    page_size: int = 20,
    role: Optional[str] = None,
    status_filter: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get paginated user list with filters."""
    query = select(User)
    count_query = select(func.count(User.id))
    
    if role:
        try:
            role_enum = UserRole(role.upper())
            query = query.where(User.role == role_enum)
            count_query = count_query.where(User.role == role_enum)
        except ValueError:
            pass
    
    if status_filter:
        try:
            status_enum = UserStatus(status_filter.upper())
            query = query.where(User.status == status_enum)
            count_query = count_query.where(User.status == status_enum)
        except ValueError:
            pass
    
    if search:
        search_filter = f"%{search}%"
        query = query.where(
            (User.email.ilike(search_filter)) |
            (User.full_name.ilike(search_filter))
        )
        count_query = count_query.where(
            (User.email.ilike(search_filter)) |
            (User.full_name.ilike(search_filter))
        )
    
    total = (await db.execute(count_query)).scalar()
    
    offset = (page - 1) * page_size
    query = query.order_by(User.created_at.desc()).offset(offset).limit(page_size)
    
    result = await db.execute(query)
    users = result.scalars().all()
    
    users_data = []
    for u in users:
        # Get counts
        diagnoses_count = (await db.execute(
            select(func.count(Diagnosis.id)).where(Diagnosis.user_id == u.id)
        )).scalar()
        
        questions_count = (await db.execute(
            select(func.count(Question.id)).where(Question.farmer_id == u.id)
        )).scalar() if u.role == UserRole.FARMER else 0
        
        answers_count = (await db.execute(
            select(func.count(Answer.id)).where(Answer.expert_id == u.id)
        )).scalar() if u.role == UserRole.EXPERT else 0
        
        users_data.append({
            "id": str(u.id),
            "email": u.email,
            "full_name": u.full_name,
            "role": u.role.value,
            "status": u.status.value,
            "created_at": u.created_at.isoformat(),
            "diagnoses_count": diagnoses_count,
            "questions_count": questions_count,
            "answers_count": answers_count,
        })
    
    return {
        "users": users_data,
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.post("/users/{user_id}/suspend", response_model=dict)
async def suspend_user(
    user_id: str,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Suspend a user account."""
    try:
        u_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID"
        )
    
    if u_uuid == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot suspend yourself"
        )
    
    result = await db.execute(select(User).where(User.id == u_uuid))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.status = UserStatus.SUSPENDED
    user.updated_at = datetime.utcnow()
    
    log = SystemLog(
        level="WARNING",
        message=f"User suspended: {user.email}",
        source="admin",
        user_id=current_user.id,
        log_metadata={"target_user_id": str(user.id)},
    )
    db.add(log)
    
    return {"message": "User suspended", "user_id": str(user.id)}


@router.post("/users/{user_id}/activate", response_model=dict)
async def activate_user(
    user_id: str,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Activate a suspended user account."""
    try:
        u_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID"
        )
    
    result = await db.execute(select(User).where(User.id == u_uuid))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.status = UserStatus.ACTIVE
    user.updated_at = datetime.utcnow()
    
    return {"message": "User activated", "user_id": str(user.id)}


# ============== System Logs ==============

@router.get("/logs", response_model=dict)
async def get_system_logs(
    page: int = 1,
    page_size: int = 50,
    level: Optional[str] = None,
    source: Optional[str] = None,
    date: Optional[str] = None,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Get system logs with filters."""
    query = select(SystemLog)
    count_query = select(func.count(SystemLog.id))
    
    if level:
        query = query.where(SystemLog.level == level.upper())
        count_query = count_query.where(SystemLog.level == level.upper())
    
    if source:
        query = query.where(SystemLog.source == source)
        count_query = count_query.where(SystemLog.source == source)
        
    if date:
        try:
            filter_date = datetime.strptime(date, "%Y-%m-%d").date()
            query = query.where(func.date(SystemLog.created_at) == filter_date)
            count_query = count_query.where(func.date(SystemLog.created_at) == filter_date)
        except ValueError:
            pass # Ignore invalid date format
    
    total = (await db.execute(count_query)).scalar()
    
    offset = (page - 1) * page_size
    query = query.order_by(SystemLog.created_at.desc()).offset(offset).limit(page_size)
    
    result = await db.execute(query)
    logs = result.scalars().all()
    
    return {
        "logs": [
            {
                "id": str(log.id),
                "level": log.level,
                "message": log.message,
                "source": log.source,
                "user_id": str(log.user_id) if log.user_id else None,
                "metadata": log.log_metadata,
                "created_at": log.created_at.isoformat(),
            }
            for log in logs
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
    }

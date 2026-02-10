"""
Farm Routes - API endpoints for farm management
"""
import uuid
from typing import Optional
from datetime import datetime, date

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.auth.dependencies import get_current_user
from app.models.user import User
from app.models.farm import FarmCrop, FarmTask, GrowthStage, TaskPriority
from app.schemas.farm import (
    FarmCropCreate,
    FarmCropUpdate,
    FarmCropResponse,
    FarmCropListResponse,
    FarmTaskCreate,
    FarmTaskUpdate,
    FarmTaskResponse,
    FarmTaskListResponse,
)

router = APIRouter(prefix="/farm", tags=["Farm Management"])


# ============== Helper: Auto-calculate progress ==============

GROWTH_STAGES_ORDER = [
    GrowthStage.GERMINATION,
    GrowthStage.SEEDLING,
    GrowthStage.VEGETATIVE,
    GrowthStage.FLOWERING,
    GrowthStage.FRUITING,
    GrowthStage.RIPENING,
    GrowthStage.HARVEST,
]

def compute_crop_progress(crop: FarmCrop) -> dict:
    """
    Auto-calculate progress and growth stage based on elapsed time.
    Returns dict with computed 'progress' and 'growth_stage'.
    """
    today = date.today()
    sow = crop.sow_date
    harvest = crop.expected_harvest_date
    
    if not sow or not harvest or harvest <= sow:
        # Can't compute, return stored values
        return {
            "progress": crop.progress or 0.0,
            "growth_stage": crop.growth_stage.value if crop.growth_stage else "germination",
        }
    
    total_days = (harvest - sow).days
    elapsed_days = (today - sow).days
    
    if elapsed_days <= 0:
        return {"progress": 0.0, "growth_stage": "germination"}
    
    if elapsed_days >= total_days:
        return {"progress": 100.0, "growth_stage": "harvest"}
    
    # Progress as percentage
    progress = round((elapsed_days / total_days) * 100, 1)
    
    # Map progress to growth stage
    ratio = elapsed_days / total_days
    if ratio < 0.10:
        stage = "germination"
    elif ratio < 0.25:
        stage = "seedling"
    elif ratio < 0.45:
        stage = "vegetative"
    elif ratio < 0.60:
        stage = "flowering"
    elif ratio < 0.75:
        stage = "fruiting"
    elif ratio < 0.90:
        stage = "ripening"
    else:
        stage = "harvest"
    
    return {"progress": progress, "growth_stage": stage}


def crop_to_response(crop: FarmCrop) -> dict:
    """Convert crop model to response dict with auto-computed fields."""
    computed = compute_crop_progress(crop)
    return {
        **{k: v for k, v in crop.__dict__.items() if not k.startswith('_')},
        "id": str(crop.id),
        "progress": computed["progress"],
        "growth_stage": computed["growth_stage"],
    }


# ============== Crop Endpoints ==============

@router.get("/crops", response_model=FarmCropListResponse)
async def get_crops(
    active_only: bool = True,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get user's farm crops.
    
    - Filter by active/all crops
    - Progress and growth stage are auto-calculated from sow/harvest dates
    """
    query = select(FarmCrop).where(FarmCrop.user_id == current_user.id)
    
    if active_only:
        query = query.where(FarmCrop.is_active.is_(True))
    
    query = query.order_by(FarmCrop.created_at.desc())
    
    result = await db.execute(query)
    crops = result.scalars().all()
    
    return {
        "crops": [crop_to_response(crop) for crop in crops],
        "total": len(crops),
    }


@router.get("/crops/{crop_id}", response_model=FarmCropResponse)
async def get_crop_detail(
    crop_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get detailed crop information.
    """
    result = await db.execute(
        select(FarmCrop).where(
            and_(FarmCrop.id == crop_id, FarmCrop.user_id == current_user.id)
        )
    )
    crop = result.scalar_one_or_none()
    
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    
    return crop_to_response(crop)


@router.post("/crops", response_model=FarmCropResponse, status_code=status.HTTP_201_CREATED)
async def create_crop(
    crop_data: FarmCropCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Add a new crop to the farm.
    """
    new_crop = FarmCrop(
        user_id=current_user.id,
        name=crop_data.name,
        crop_type=crop_data.crop_type,
        field_name=crop_data.field_name,
        area_size=crop_data.area_size,
        area_unit=crop_data.area_unit,
        sow_date=crop_data.sow_date,
        expected_harvest_date=crop_data.expected_harvest_date,
        notes=crop_data.notes,
    )
    
    db.add(new_crop)
    await db.commit()
    await db.refresh(new_crop)
    
    return crop_to_response(new_crop)


@router.put("/crops/{crop_id}", response_model=FarmCropResponse)
async def update_crop(
    crop_id: str,
    crop_data: FarmCropUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Update crop information.
    """
    result = await db.execute(
        select(FarmCrop).where(
            and_(FarmCrop.id == crop_id, FarmCrop.user_id == current_user.id)
        )
    )
    crop = result.scalar_one_or_none()
    
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    
    update_data = crop_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "growth_stage" and value:
            setattr(crop, field, GrowthStage(value.value))
        else:
            setattr(crop, field, value)
    
    crop.updated_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(crop)
    
    return crop_to_response(crop)


@router.delete("/crops/{crop_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_crop(
    crop_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete a crop.
    """
    result = await db.execute(
        select(FarmCrop).where(
            and_(FarmCrop.id == crop_id, FarmCrop.user_id == current_user.id)
        )
    )
    crop = result.scalar_one_or_none()
    
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    
    await db.delete(crop)
    await db.commit()


# ============== Task Endpoints ==============

@router.get("/tasks", response_model=FarmTaskListResponse)
async def get_tasks(
    completed: Optional[bool] = None,
    crop_id: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get user's farming tasks.
    
    - Filter by completion status
    - Filter by crop
    """
    query = select(FarmTask).where(FarmTask.user_id == current_user.id)
    
    if completed is not None:
        query = query.where(FarmTask.is_completed == completed)
    
    if crop_id:
        query = query.where(FarmTask.crop_id == crop_id)
    
    # Order by: incomplete first, then by due date, then by priority
    query = query.order_by(
        FarmTask.is_completed.asc(),
        FarmTask.due_date.asc().nullslast(),
        FarmTask.created_at.desc(),
    )
    
    result = await db.execute(query)
    tasks = result.scalars().all()
    
    # Get crop names for tasks with crops
    crop_ids = [task.crop_id for task in tasks if task.crop_id]
    crop_names = {}
    if crop_ids:
        crop_result = await db.execute(
            select(FarmCrop.id, FarmCrop.name).where(FarmCrop.id.in_(crop_ids))
        )
        crop_names = {str(row[0]): row[1] for row in crop_result.fetchall()}
    
    completed_count = sum(1 for t in tasks if t.is_completed)
    pending_count = len(tasks) - completed_count
    
    return {
        "tasks": [
            {
                **{k: v for k, v in task.__dict__.items() if not k.startswith('_')},
                "id": str(task.id),
                "crop_id": str(task.crop_id) if task.crop_id else None,
                "crop_name": crop_names.get(str(task.crop_id)) if task.crop_id else None,
                "priority": task.priority.value if task.priority else "medium",
            }
            for task in tasks
        ],
        "total": len(tasks),
        "completed_count": completed_count,
        "pending_count": pending_count,
    }


@router.post("/tasks", response_model=FarmTaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_data: FarmTaskCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new farming task.
    """
    # Verify crop belongs to user if specified
    crop_name = None
    if task_data.crop_id:
        crop_result = await db.execute(
            select(FarmCrop).where(
                and_(FarmCrop.id == task_data.crop_id, FarmCrop.user_id == current_user.id)
            )
        )
        crop = crop_result.scalar_one_or_none()
        if not crop:
            raise HTTPException(status_code=400, detail="Invalid crop ID")
        crop_name = crop.name
    
    new_task = FarmTask(
        user_id=current_user.id,
        crop_id=uuid.UUID(task_data.crop_id) if task_data.crop_id else None,
        title=task_data.title,
        description=task_data.description,
        due_date=task_data.due_date,
        priority=TaskPriority(task_data.priority.value),
        is_recurring=task_data.is_recurring,
        recurrence_days=task_data.recurrence_days,
    )
    
    db.add(new_task)
    await db.commit()
    await db.refresh(new_task)
    
    return {
        **{k: v for k, v in new_task.__dict__.items() if not k.startswith('_')},
        "id": str(new_task.id),
        "crop_id": str(new_task.crop_id) if new_task.crop_id else None,
        "crop_name": crop_name,
        "priority": new_task.priority.value,
    }


@router.put("/tasks/{task_id}", response_model=FarmTaskResponse)
async def update_task(
    task_id: str,
    task_data: FarmTaskUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Update a task.
    """
    result = await db.execute(
        select(FarmTask).where(
            and_(FarmTask.id == task_id, FarmTask.user_id == current_user.id)
        )
    )
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    update_data = task_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "priority" and value:
            setattr(task, field, TaskPriority(value.value))
        else:
            setattr(task, field, value)
    
    task.updated_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(task)
    
    # Get crop name
    crop_name = None
    if task.crop_id:
        crop_result = await db.execute(
            select(FarmCrop.name).where(FarmCrop.id == task.crop_id)
        )
        crop_name = crop_result.scalar_one_or_none()
    
    return {
        **{k: v for k, v in task.__dict__.items() if not k.startswith('_')},
        "id": str(task.id),
        "crop_id": str(task.crop_id) if task.crop_id else None,
        "crop_name": crop_name,
        "priority": task.priority.value,
    }


@router.put("/tasks/{task_id}/complete", response_model=FarmTaskResponse)
async def complete_task(
    task_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Toggle task completion status.
    If incomplete → marks as completed.
    If already completed → reverts to incomplete.
    """
    result = await db.execute(
        select(FarmTask).where(
            and_(FarmTask.id == task_id, FarmTask.user_id == current_user.id)
        )
    )
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.is_completed:
        # Undo completion
        task.is_completed = False
        task.completed_at = None
    else:
        # Mark as completed
        task.is_completed = True
        task.completed_at = datetime.utcnow()
        
        # If recurring, create next task
        if task.is_recurring and task.recurrence_days:
            from datetime import timedelta
            next_due = (task.due_date or datetime.utcnow()) + timedelta(days=task.recurrence_days)
            new_task = FarmTask(
                user_id=current_user.id,
                crop_id=task.crop_id,
                title=task.title,
                description=task.description,
                due_date=next_due,
                priority=task.priority,
                is_recurring=True,
                recurrence_days=task.recurrence_days,
            )
            db.add(new_task)
    
    task.updated_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(task)
    
    # Get crop name
    crop_name = None
    if task.crop_id:
        crop_result = await db.execute(
            select(FarmCrop.name).where(FarmCrop.id == task.crop_id)
        )
        crop_name = crop_result.scalar_one_or_none()
    
    return {
        **{k: v for k, v in task.__dict__.items() if not k.startswith('_')},
        "id": str(task.id),
        "crop_id": str(task.crop_id) if task.crop_id else None,
        "crop_name": crop_name,
        "priority": task.priority.value,
    }


@router.delete("/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_task(
    task_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete a task.
    """
    result = await db.execute(
        select(FarmTask).where(
            and_(FarmTask.id == task_id, FarmTask.user_id == current_user.id)
        )
    )
    task = result.scalar_one_or_none()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    await db.delete(task)
    await db.commit()

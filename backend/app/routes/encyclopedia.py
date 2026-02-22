"""
Encyclopedia Routes - API endpoints for crop and disease encyclopedia
"""
from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_

from app.database import get_db
from app.auth.dependencies import get_current_user, require_admin
from app.models.user import User
from app.models.encyclopedia import CropInfo, DiseaseInfo
from app.models.pest import PestInfo
from app.schemas.encyclopedia import (
    CropInfoCreate,
    CropInfoResponse,
    CropInfoListResponse,
    CropInfoSummary,
    DiseaseInfoCreate,
    DiseaseInfoResponse,
    DiseaseInfoListResponse,
)

router = APIRouter(prefix="/encyclopedia", tags=["Encyclopedia"])


# ============== Crop Info Endpoints ==============

@router.get("/crops", response_model=CropInfoListResponse)
async def get_crops(
    search: Optional[str] = None,
    season: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get list of crops in the encyclopedia.
    
    - Optional search by name
    - Filter by season (Rabi/Kharif)
    """
    query = select(CropInfo)
    
    if search:
        query = query.where(
            or_(
                CropInfo.name.ilike(f"%{search}%"),
                CropInfo.scientific_name.ilike(f"%{search}%"),
            )
        )
    
    if season:
        query = query.where(CropInfo.season.ilike(f"%{season}%"))
    
    query = query.order_by(CropInfo.name.asc())
    
    result = await db.execute(query)
    crops = result.scalars().all()
    
    return {
        "crops": [
            {
                "id": str(crop.id),
                "name": crop.name,
                "scientific_name": crop.scientific_name,
                "description": crop.description,
                "season": crop.season,
                "temp_min": crop.temp_min,
                "temp_max": crop.temp_max,
                "water_requirement": crop.water_requirement,
                "soil_type": crop.soil_type,
                "growing_tips": crop.growing_tips or [],
                "nutritional_info": crop.nutritional_info or {},
                "common_varieties": crop.common_varieties or [],
                "common_diseases": crop.common_diseases or [],
                "image_url": crop.image_url,
            }
            for crop in crops
        ],
        "total": len(crops),
    }


@router.get("/crops/{crop_id}", response_model=CropInfoResponse)
async def get_crop_detail(
    crop_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get detailed crop information.
    """
    result = await db.execute(
        select(CropInfo).where(CropInfo.id == crop_id)
    )
    crop = result.scalar_one_or_none()
    
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    
    return {
        "id": str(crop.id),
        "name": crop.name,
        "scientific_name": crop.scientific_name,
        "description": crop.description,
        "season": crop.season,
        "temp_min": crop.temp_min,
        "temp_max": crop.temp_max,
        "water_requirement": crop.water_requirement,
        "soil_type": crop.soil_type,
        "growing_tips": crop.growing_tips or [],
        "nutritional_info": crop.nutritional_info or {},
        "common_varieties": crop.common_varieties or [],
        "common_diseases": crop.common_diseases or [],
        "image_url": crop.image_url,
    }


@router.get("/crops/name/{crop_name}", response_model=CropInfoResponse)
async def get_crop_by_name(
    crop_name: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get crop information by name.
    """
    result = await db.execute(
        select(CropInfo).where(CropInfo.name.ilike(crop_name))
    )
    crop = result.scalar_one_or_none()
    
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    
    return {
        "id": str(crop.id),
        "name": crop.name,
        "scientific_name": crop.scientific_name,
        "description": crop.description,
        "season": crop.season,
        "temp_min": crop.temp_min,
        "temp_max": crop.temp_max,
        "water_requirement": crop.water_requirement,
        "soil_type": crop.soil_type,
        "growing_tips": crop.growing_tips or [],
        "nutritional_info": crop.nutritional_info or {},
        "common_varieties": crop.common_varieties or [],
        "common_diseases": crop.common_diseases or [],
        "image_url": crop.image_url,
    }


@router.post("/crops", response_model=CropInfoResponse, status_code=status.HTTP_201_CREATED)
async def create_crop_info(
    crop_data: CropInfoCreate,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Add a crop to the encyclopedia (Admin only).
    """
    # Check for duplicate
    existing = await db.execute(
        select(CropInfo).where(CropInfo.name.ilike(crop_data.name))
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Crop with this name already exists")
    
    new_crop = CropInfo(
        name=crop_data.name,
        scientific_name=crop_data.scientific_name,
        description=crop_data.description,
        season=crop_data.season,
        temp_min=crop_data.temp_min,
        temp_max=crop_data.temp_max,
        water_requirement=crop_data.water_requirement,
        soil_type=crop_data.soil_type,
        growing_tips=crop_data.growing_tips,
        common_varieties=crop_data.common_varieties,
        common_diseases=crop_data.common_diseases,
        image_url=crop_data.image_url,
    )
    
    db.add(new_crop)
    await db.commit()
    await db.refresh(new_crop)
    
    return {
        "id": str(new_crop.id),
        "name": new_crop.name,
        "scientific_name": new_crop.scientific_name,
        "description": new_crop.description,
        "season": new_crop.season,
        "temp_min": new_crop.temp_min,
        "temp_max": new_crop.temp_max,
        "water_requirement": new_crop.water_requirement,
        "soil_type": new_crop.soil_type,
        "growing_tips": new_crop.growing_tips or [],
        "nutritional_info": new_crop.nutritional_info or {},
        "common_varieties": new_crop.common_varieties or [],
        "common_diseases": new_crop.common_diseases or [],
        "image_url": new_crop.image_url,
    }


# ============== Disease Info Endpoints ==============

@router.get("/diseases", response_model=DiseaseInfoListResponse)
async def get_diseases(
    search: Optional[str] = None,
    crop: Optional[str] = None,
    severity: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get list of diseases in the encyclopedia.
    
    - Optional search by name
    - Filter by affected crop
    - Filter by severity level
    """
    query = select(DiseaseInfo)
    
    if search:
        query = query.where(
            or_(
                DiseaseInfo.name.ilike(f"%{search}%"),
                DiseaseInfo.scientific_name.ilike(f"%{search}%"),
            )
        )
    
    if severity:
        query = query.where(DiseaseInfo.severity_level.ilike(severity))
    
    query = query.order_by(DiseaseInfo.name.asc())
    
    result = await db.execute(query)
    diseases = result.scalars().all()
    
    # Filter by crop if specified (JSONB contains check)
    if crop:
        diseases = [
            d for d in diseases
            if d.affected_crops and any(crop.lower() in c.lower() for c in d.affected_crops)
        ]
    
    return {
        "diseases": [
            {
                "id": str(disease.id),
                "name": disease.name,
                "scientific_name": disease.scientific_name,
                "affected_crops": disease.affected_crops or [],
                "description": disease.description,
                "symptoms": disease.symptoms or [],
                "causes": disease.causes,
                "chemical_treatment": disease.chemical_treatment or [],
                "organic_treatment": disease.organic_treatment or [],
                "prevention": disease.prevention or [],
                "severity_level": disease.severity_level,
                "spread_method": disease.spread_method,
                "safety_warnings": disease.safety_warnings or [],
                "environmental_warnings": disease.environmental_warnings or [],
                "image_url": disease.image_url,
            }
            for disease in diseases
        ],
        "total": len(diseases),
    }


@router.get("/diseases/{disease_id}", response_model=DiseaseInfoResponse)
async def get_disease_detail(
    disease_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get detailed disease information.
    """
    result = await db.execute(
        select(DiseaseInfo).where(DiseaseInfo.id == disease_id)
    )
    disease = result.scalar_one_or_none()
    
    if not disease:
        raise HTTPException(status_code=404, detail="Disease not found")
    
    return {
        "id": str(disease.id),
        "name": disease.name,
        "scientific_name": disease.scientific_name,
        "affected_crops": disease.affected_crops or [],
        "description": disease.description,
        "symptoms": disease.symptoms or [],
        "causes": disease.causes,
        "chemical_treatment": disease.chemical_treatment or [],
        "organic_treatment": disease.organic_treatment or [],
        "prevention": disease.prevention or [],
        "severity_level": disease.severity_level,
        "spread_method": disease.spread_method,
        "safety_warnings": disease.safety_warnings or [],
        "environmental_warnings": disease.environmental_warnings or [],
        "image_url": disease.image_url,
    }


@router.post("/diseases", response_model=DiseaseInfoResponse, status_code=status.HTTP_201_CREATED)
async def create_disease_info(
    disease_data: DiseaseInfoCreate,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Add a disease to the encyclopedia (Admin only).
    """
    new_disease = DiseaseInfo(
        name=disease_data.name,
        scientific_name=disease_data.scientific_name,
        affected_crops=disease_data.affected_crops,
        description=disease_data.description,
        symptoms=disease_data.symptoms,
        causes=disease_data.causes,
        chemical_treatment=disease_data.chemical_treatment,
        organic_treatment=disease_data.organic_treatment,
        prevention=disease_data.prevention,
        severity_level=disease_data.severity_level,
        spread_method=disease_data.spread_method,
        safety_warnings=disease_data.safety_warnings,
        environmental_warnings=disease_data.environmental_warnings,
        image_url=disease_data.image_url,
    )
    
    db.add(new_disease)
    await db.commit()
    await db.refresh(new_disease)
    
    return {
        "id": str(new_disease.id),
        "name": new_disease.name,
        "scientific_name": new_disease.scientific_name,
        "affected_crops": new_disease.affected_crops or [],
        "description": new_disease.description,
        "symptoms": new_disease.symptoms or [],
        "causes": new_disease.causes,
        "chemical_treatment": new_disease.chemical_treatment or [],
        "organic_treatment": new_disease.organic_treatment or [],
        "prevention": new_disease.prevention or [],
        "severity_level": new_disease.severity_level,
        "spread_method": new_disease.spread_method,
        "safety_warnings": new_disease.safety_warnings or [],
        "environmental_warnings": new_disease.environmental_warnings or [],
        "image_url": new_disease.image_url,
    }

# ============== Pest Info Endpoints ==============

@router.get("/pests")
async def get_pests(
    search: Optional[str] = None,
    severity: Optional[str] = None,
    crop: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get list of pests in the encyclopedia.
    - Optional search by name or scientific name
    - Filter by severity level
    - Filter by affected crop
    """
    query = select(PestInfo)

    if search:
        query = query.where(
            or_(
                PestInfo.name.ilike(f"%{search}%"),
                PestInfo.scientific_name.ilike(f"%{search}%"),
            )
        )

    if severity:
        query = query.where(PestInfo.severity_level.ilike(severity))

    query = query.order_by(PestInfo.name.asc())

    result = await db.execute(query)
    pests = result.scalars().all()

    # Filter by crop if specified
    if crop:
        pests = [
            p for p in pests
            if p.affected_crops and any(crop.lower() in c.lower() for c in p.affected_crops)
        ]

    return {
        "pests": [
            {
                "id": str(pest.id),
                "name": pest.name,
                "scientific_name": pest.scientific_name,
                "affected_crops": pest.affected_crops or [],
                "description": pest.description,
                "symptoms": pest.symptoms or [],
                "appearance": pest.appearance,
                "damage_type": pest.damage_type,
                "life_cycle": pest.life_cycle,
                "control_methods": pest.control_methods or [],
                "organic_control": pest.organic_control or [],
                "chemical_control": pest.chemical_control or [],
                "prevention": pest.prevention or [],
                "severity_level": pest.severity_level,
                "image_url": pest.image_url,
            }
            for pest in pests
        ],
        "total": len(pests),
    }


@router.get("/pests/{pest_id}")
async def get_pest_detail(
    pest_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get detailed pest information."""
    result = await db.execute(
        select(PestInfo).where(PestInfo.id == pest_id)
    )
    pest = result.scalar_one_or_none()

    if not pest:
        raise HTTPException(status_code=404, detail="Pest not found")

    return {
        "id": str(pest.id),
        "name": pest.name,
        "scientific_name": pest.scientific_name,
        "affected_crops": pest.affected_crops or [],
        "description": pest.description,
        "symptoms": pest.symptoms or [],
        "appearance": pest.appearance,
        "damage_type": pest.damage_type,
        "life_cycle": pest.life_cycle,
        "control_methods": pest.control_methods or [],
        "organic_control": pest.organic_control or [],
        "chemical_control": pest.chemical_control or [],
        "prevention": pest.prevention or [],
        "severity_level": pest.severity_level,
        "image_url": pest.image_url,
    }


@router.post("/pests", status_code=status.HTTP_201_CREATED)
async def create_pest_info(
    pest_data: dict,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Add a pest to the encyclopedia (Admin only)."""
    new_pest = PestInfo(
        name=pest_data.get("name"),
        scientific_name=pest_data.get("scientific_name"),
        affected_crops=pest_data.get("affected_crops", []),
        description=pest_data.get("description"),
        symptoms=pest_data.get("symptoms", []),
        appearance=pest_data.get("appearance"),
        damage_type=pest_data.get("damage_type"),
        life_cycle=pest_data.get("life_cycle"),
        control_methods=pest_data.get("control_methods", []),
        organic_control=pest_data.get("organic_control", []),
        chemical_control=pest_data.get("chemical_control", []),
        prevention=pest_data.get("prevention", []),
        severity_level=pest_data.get("severity_level"),
        image_url=pest_data.get("image_url"),
    )

    db.add(new_pest)
    await db.commit()
    await db.refresh(new_pest)

    return {"id": str(new_pest.id), "name": new_pest.name, "message": "Pest created successfully"}

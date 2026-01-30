"""
Market Routes - API endpoints for commodity market prices
"""
from typing import Optional, List
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.database import get_db
from app.auth.dependencies import get_current_user, require_admin
from app.models.user import User
from app.models.market import MarketPrice, TrendType
from app.schemas.market import (
    MarketPriceCreate,
    MarketPriceUpdate,
    MarketPriceResponse,
    MarketPriceListResponse,
)

router = APIRouter(prefix="/market", tags=["Market Prices"])


@router.get("/prices", response_model=MarketPriceListResponse)
async def get_market_prices(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    commodity: Optional[str] = None,
    location: Optional[str] = None,
    trend: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get list of market prices with optional filters.
    
    - Filter by commodity name (partial match)
    - Filter by location/mandi (partial match)
    - Filter by trend (up/down/stable)
    """
    query = select(MarketPrice)
    count_query = select(func.count(MarketPrice.id))
    
    # Apply filters
    conditions = []
    if commodity:
        conditions.append(MarketPrice.commodity.ilike(f"%{commodity}%"))
    if location:
        conditions.append(MarketPrice.location.ilike(f"%{location}%"))
    if trend:
        try:
            trend_enum = TrendType(trend)
            conditions.append(MarketPrice.trend == trend_enum)
        except ValueError:
            pass
    
    if conditions:
        query = query.where(and_(*conditions))
        count_query = count_query.where(and_(*conditions))
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Order by most recent and paginate
    query = query.order_by(MarketPrice.recorded_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    
    result = await db.execute(query)
    prices = result.scalars().all()
    
    return {
        "prices": [
            {
                **price.__dict__,
                "id": str(price.id),
                "trend": price.trend.value if price.trend else "stable",
            }
            for price in prices
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.get("/prices/{commodity}", response_model=List[MarketPriceResponse])
async def get_commodity_prices(
    commodity: str,
    days: int = Query(7, ge=1, le=30),
    location: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get price history for a specific commodity.
    
    - Returns prices for the last N days (default 7)
    - Can filter by location
    """
    from datetime import timedelta
    
    cutoff = datetime.utcnow() - timedelta(days=days)
    
    query = select(MarketPrice).where(
        and_(
            MarketPrice.commodity.ilike(f"%{commodity}%"),
            MarketPrice.recorded_at >= cutoff,
        )
    )
    
    if location:
        query = query.where(MarketPrice.location.ilike(f"%{location}%"))
    
    query = query.order_by(MarketPrice.recorded_at.desc())
    
    result = await db.execute(query)
    prices = result.scalars().all()
    
    return [
        {
            **price.__dict__,
            "id": str(price.id),
            "trend": price.trend.value if price.trend else "stable",
        }
        for price in prices
    ]


@router.post("/prices", response_model=MarketPriceResponse, status_code=status.HTTP_201_CREATED)
async def create_market_price(
    price_data: MarketPriceCreate,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new market price entry (Admin only).
    """
    new_price = MarketPrice(
        commodity=price_data.commodity,
        price=price_data.price,
        unit=price_data.unit,
        location=price_data.location,
        trend=TrendType(price_data.trend.value),
        change_percent=price_data.change_percent,
        min_price=price_data.min_price,
        max_price=price_data.max_price,
        arrival_qty=price_data.arrival_qty,
        recorded_at=datetime.utcnow(),
    )
    
    db.add(new_price)
    await db.commit()
    await db.refresh(new_price)
    
    return {
        **new_price.__dict__,
        "id": str(new_price.id),
        "trend": new_price.trend.value,
    }


@router.put("/prices/{price_id}", response_model=MarketPriceResponse)
async def update_market_price(
    price_id: str,
    price_data: MarketPriceUpdate,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Update a market price entry (Admin only).
    """
    result = await db.execute(
        select(MarketPrice).where(MarketPrice.id == price_id)
    )
    price = result.scalar_one_or_none()
    
    if not price:
        raise HTTPException(status_code=404, detail="Price entry not found")
    
    update_data = price_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if field == "trend" and value:
            setattr(price, field, TrendType(value.value))
        else:
            setattr(price, field, value)
    
    price.updated_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(price)
    
    return {
        **price.__dict__,
        "id": str(price.id),
        "trend": price.trend.value,
    }


@router.delete("/prices/{price_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_market_price(
    price_id: str,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete a market price entry (Admin only).
    """
    result = await db.execute(
        select(MarketPrice).where(MarketPrice.id == price_id)
    )
    price = result.scalar_one_or_none()
    
    if not price:
        raise HTTPException(status_code=404, detail="Price entry not found")
    
    await db.delete(price)
    await db.commit()

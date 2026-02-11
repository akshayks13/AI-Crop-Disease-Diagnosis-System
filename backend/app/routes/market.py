"""
Market Routes - API endpoints for commodity market prices
"""
import os
import httpx
from typing import Optional, List, Dict, Any
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.database import get_db
from app.config import get_settings
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


# Simple in-memory cache
# Format: {"timestamp": float, "data": dict}
_market_cache = {}
CACHE_DURATION_SECONDS = 300  # 5 minutes

async def fetch_agmarknet_data(
    api_key: str,
    limit: int = 20,
    offset: int = 0,
    filters: Dict[str, str] = None
) -> Dict[str, Any]:
    """
    Fetch data from Agmarknet API via OGD Platform.
    Includes basic caching to avoid rate limits.
    """
    settings = get_settings()
    base_url = settings.agmarknet_api_url
    
    if not base_url:
        print("AGMARKNET_API_URL not configured")
        return None
        
    # Generate cache key based on params
    cache_key = f"{limit}_{offset}_{str(filters)}"
    current_time = datetime.now().timestamp()
    
    # Check cache
    if cache_key in _market_cache:
        cached_entry = _market_cache[cache_key]
        if current_time - cached_entry["timestamp"] < CACHE_DURATION_SECONDS:
            print(f"Returning cached market data for key: {cache_key}")
            return cached_entry["data"]

    params = {
        "api-key": api_key,
        "format": "json",
        "limit": limit,
        "offset": offset,
    }
    
    # Map internal filters to API filters if possible
    if filters:
        for k, v in filters.items():
            if v:
                params[f"filters[{k}]"] = v

    async with httpx.AsyncClient() as client:
        try:
            print(f"Fetching market data from API: {base_url}")
            response = await client.get(base_url, params=params, timeout=10.0)
            
            if response.status_code == 200:
                data = response.json()
                # Cache successful response
                _market_cache[cache_key] = {
                    "timestamp": current_time,
                    "data": data
                }
                return data
            elif response.status_code == 429:
                print("Agmarknet API Rate Limit Exceeded.")
                # If we have stale cache, maybe return it? 
                # For now, just return None to fallback to DB implies consistent behavior
                return None
            else:
                print(f"Agmarknet API Error: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            print(f"Error fetching market data: {e}")
            return None


def map_api_record_to_schema(record: Dict[str, Any]) -> Dict[str, Any]:
    """
    Map a single API record to our MarketPrice schema.
    API Record example:
    {
        "state": "Kerala",
        "district": "Alappuzha",
        "market": "Alappuzha",
        "commodity": "Copra",
        "variety": "Dilpas",
        "grade": "FAQ",
        "arrival_date": "12/02/2026",
        "min_price": "14000",
        "max_price": "14500",
        "modal_price": "14200"
    }
    """
    try:
        # Determine trend (this is synthetic since API doesn't give trend)
        # We default to stable
        
        return {
            "id": f"{record.get('market')}_{record.get('commodity')}_{record.get('arrival_date')}",  # Synthetic ID
            "commodity": record.get("commodity", "Unknown"),
            "price": float(record.get("modal_price", 0)),
            "unit": "Quintal",  # Agmarknet usually reports in Rs./Quintal
            "location": f"{record.get('market')}, {record.get('district')}, {record.get('state')}",
            "trend": "stable",
            "change_percent": 0.0,
            "min_price": float(record.get("min_price", 0)),
            "max_price": float(record.get("max_price", 0)),
            "arrival_qty": 0.0, # Not provided in this resource usually
            "recorded_at": datetime.now(), # We use current time or parse arrival_date
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        }
    except Exception as e:
        print(f"Error mapping record: {e}")
        return None


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
    Get list of market prices.
    Prioritizes real-time data from Agmarknet API if configured.
    Fallbacks to database if API fails or is not configured.
    """
    settings = get_settings()
    api_key = settings.agmarknet_api_key
    
    # Try fetching from API first if we have a key
    if api_key:
        api_filters = {}
        if commodity:
            api_filters["commodity"] = commodity
        # Location in API is split into state, district, market. 
        # Partial match on 'location' param is hard to map directly to API filters without knowing which field.
        # We will skip location filter for API call strictness, or try to apply it client side?
        # For now, let's just pass commodity if present.
        
        offset = (page - 1) * page_size
        data = await fetch_agmarknet_data(api_key, limit=page_size, offset=offset, filters=api_filters)
        
        if data and "records" in data:
            records = data["records"]
            total_records = int(data.get("total", 0)) if "total" in data else len(records) # 'total' usually in response
            
            # Map records
            mapped_prices = []
            for rec in records:
                mapped = map_api_record_to_schema(rec)
                if mapped:
                    # Apply location filter in memory if provided
                    if location and location.lower() not in mapped["location"].lower():
                        continue
                    mapped_prices.append(mapped)
            
            # If we filtered in-memory, the specific page logic might be slightly off relative to total,
            # but for a basic implementation this is acceptable.
            
            return {
                "prices": mapped_prices,
                "total": total_records, # This might be inaccurate if we filtered in memory
                "page": page,
                "page_size": page_size,
            }
    else:
        print("No AGMARKNET_API_KEY found in settings. Using database.")

    # Fallback to Database
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

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
from app.services.redis_service import get_redis_service


router = APIRouter(prefix="/market", tags=["Market Prices"])

# ── Cache Configuration ──────────────────────────────────────────────────────
# Redis is the primary cache (shared, persists across restarts).
# If Redis is unavailable, we fall back to an in-memory dict per-process.
CACHE_DURATION_SECONDS = 3600  # 1 hour — stays within Agmarknet rate limits
RATE_LIMIT_BACKOFF_SECONDS = 3600  # Wait 1 hour after a 429

# Redis key prefixes
_REDIS_CACHE_PREFIX = "market_cache:"
_REDIS_RATE_LIMIT_KEY = "market_rate_limited_until"

# In-memory fallback (used only when Redis is not available)
_mem_cache: Dict[str, Dict] = {}
_mem_rate_limited_until: float = 0

async def fetch_agmarknet_data(
    api_key: str,
    limit: int = 10,
    offset: int = 0,
    filters: Dict[str, str] = None
) -> Dict[str, Any]:
    """
    Fetch data from Agmarknet API via OGD Platform.
    Uses Redis for persistent caching (1 hour TTL) to stay within API rate limits.
    Falls back to in-memory cache when Redis is unavailable.
    Rate-limit backoff state also persists in Redis across restarts.
    """
    global _mem_rate_limited_until

    redis = get_redis_service()
    settings = get_settings()
    base_url = settings.agmarknet_api_url

    if not base_url:
        return None

    current_time = datetime.now().timestamp()

    # ── Check rate-limit backoff ─────────────────────────────────────────────
    # Try Redis first; fall back to the in-memory float
    rate_limited_until: float = _mem_rate_limited_until
    redis_rl = await redis.get_raw(_REDIS_RATE_LIMIT_KEY)
    if redis_rl is not None:
        try:
            rate_limited_until = float(redis_rl)
        except ValueError:
            pass

    if current_time < rate_limited_until:
        remaining = int(rate_limited_until - current_time)
        print(f"[Agmarknet] Rate limited — skipping API call. {remaining}s remaining in backoff.")
        return None

    # ── Build cache key ──────────────────────────────────────────────────────
    cache_key_suffix = f"{limit}_{offset}_{str(filters)}"
    redis_key = f"{_REDIS_CACHE_PREFIX}{cache_key_suffix}"

    # ── Check Redis cache ────────────────────────────────────────────────────
    cached = await redis.get(redis_key)
    if cached is not None:
        print(f"[Agmarknet] Redis cache hit. Records: {len(cached.get('records', []))}")
        return cached

    # ── Check in-memory fallback cache ───────────────────────────────────────
    if cache_key_suffix in _mem_cache:
        entry = _mem_cache[cache_key_suffix]
        age = current_time - entry["timestamp"]
        if age < CACHE_DURATION_SECONDS:
            print(f"[Agmarknet] In-memory cache hit (age={int(age)}s).")
            return entry["data"]

    # ── Fetch from API ───────────────────────────────────────────────────────
    params = {
        "api-key": api_key,
        "format": "json",
        "limit": limit,
        "offset": offset,
    }
    if filters:
        for k, v in filters.items():
            if v:
                params[f"filters[{k}]"] = v

    async with httpx.AsyncClient() as client:
        try:
            print(f"[Agmarknet] Fetching from API: limit={limit} offset={offset}")
            response = await client.get(base_url, params=params, timeout=20.0)
            print(f"[Agmarknet] Response status: {response.status_code}")

            if response.status_code == 200:
                data = response.json()

                # Store in Redis (with TTL); also store in-memory as fallback
                stored = await redis.set(redis_key, data, ttl=CACHE_DURATION_SECONDS)
                if not stored:
                    # Redis unavailable — use in-memory
                    _mem_cache[cache_key_suffix] = {
                        "timestamp": current_time,
                        "data": data,
                    }
                print(f"[Agmarknet] Cached {len(data.get('records', []))} records "
                      f"({'Redis' if stored else 'in-memory'}).")
                return data

            elif response.status_code == 429:
                # Persist backoff in Redis; also update in-memory float
                backoff_until = current_time + RATE_LIMIT_BACKOFF_SECONDS
                stored = await redis.set_raw(
                    _REDIS_RATE_LIMIT_KEY,
                    str(backoff_until),
                    ttl=RATE_LIMIT_BACKOFF_SECONDS,
                )
                if not stored:
                    _mem_rate_limited_until = backoff_until
                print(f"[Agmarknet] Rate limited (429). Backed off for {RATE_LIMIT_BACKOFF_SECONDS}s "
                      f"({'Redis' if stored else 'in-memory'}).")
                return None

            else:
                print(f"[Agmarknet] Non-200 response ({response.status_code}): {response.text[:200]}")
                return None

        except Exception as e:
            print(f"[Agmarknet] Exception: {type(e).__name__}: {e}")
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
    page_size: int = Query(10, ge=1, le=100),
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
    
    print(f"[Market] API key configured: {bool(api_key and api_key.strip())}, key_preview: {api_key[:8] if api_key else 'NONE'}")
    
    # Try fetching from API first if we have a valid key (not empty)
    if api_key and api_key.strip():
        try:
            api_filters = {}
            if commodity:
                api_filters["commodity"] = commodity
            
            offset = (page - 1) * page_size
            print(f"[Market] Fetching from Agmarknet API, limit={page_size}, offset={offset}, filters={api_filters}")
            data = await fetch_agmarknet_data(api_key, limit=page_size, offset=offset, filters=api_filters)
            
            if data and "records" in data:
                records = data["records"]
                total_records = int(data.get("total", 0)) if "total" in data else len(records)
                print(f"[Market] Got {len(records)} records from API, total={total_records}")
                
                # Map records
                mapped_prices = []
                for rec in records:
                    mapped = map_api_record_to_schema(rec)
                    if mapped:
                        # Apply location filter in memory if provided
                        if location and location.lower() not in mapped["location"].lower():
                            continue
                        mapped_prices.append(mapped)
                
                print(f"[Market] Returning {len(mapped_prices)} prices from API")
                return {
                    "prices": mapped_prices,
                    "total": total_records,
                    "page": page,
                    "page_size": page_size,
                }
            else:
                print(f"[Market] API returned no records or unexpected format. data keys: {list(data.keys()) if data else 'None'}")
        except Exception as e:
            # Silently fall back to database on any API error
            print(f"[Market] API error: {type(e).__name__}: {e}")

    # Use Database (primary source when API not configured or failed)
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
    
    print(f"Found {len(prices)} prices in database (total: {total})")
    
    return {
        "prices": [
            {
                "id": str(price.id),
                "commodity": price.commodity,
                "price": price.price,
                "unit": price.unit,
                "location": price.location,
                "trend": price.trend.value if price.trend else "stable",
                "change_percent": price.change_percent,
                "min_price": price.min_price,
                "max_price": price.max_price,
                "arrival_qty": price.arrival_qty,
                "recorded_at": price.recorded_at.isoformat() if price.recorded_at else None,
                "created_at": price.created_at.isoformat() if price.created_at else None,
                "updated_at": price.updated_at.isoformat() if price.updated_at else None,
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


@router.get("/debug/status")
async def get_market_debug_status(
    current_user: User = Depends(get_current_user),
):
    """
    Debug endpoint: Check AGMarknet API key configuration and cache status.
    Shows whether the API key is loaded and how many cache entries exist.
    """
    settings = get_settings()
    api_key = settings.agmarknet_api_key
    current_time = datetime.now().timestamp()

    cache_info = []
    for key, entry in _market_cache.items():
        age_seconds = current_time - entry["timestamp"]
        cache_info.append({
            "cache_key": key,
            "age_seconds": round(age_seconds, 1),
            "expires_in_seconds": round(CACHE_DURATION_SECONDS - age_seconds, 1),
            "is_valid": age_seconds < CACHE_DURATION_SECONDS,
            "record_count": len(entry["data"].get("records", [])) if entry.get("data") else 0,
        })

    return {
        "api_key_configured": bool(api_key and api_key.strip()),
        "api_key_preview": f"{api_key[:8]}...{api_key[-4:]}" if api_key and len(api_key) > 12 else "NOT SET",
        "api_url": settings.agmarknet_api_url,
        "cache_duration_seconds": CACHE_DURATION_SECONDS,
        "cache_entries": len(_market_cache),
        "cache_details": cache_info,
    }


@router.post("/cache/clear")
async def clear_market_cache(
    current_user: User = Depends(require_admin),
):
    """
    Clear the Agmarknet API cache (Admin only).
    Clears both the Redis cache and the in-memory fallback.
    Forces a fresh fetch from the API on the next request.
    """
    redis = get_redis_service()

    # Clear Redis keys matching market_cache:*
    redis_deleted = await redis.delete_pattern(f"{_REDIS_CACHE_PREFIX}*")
    await redis.delete(_REDIS_RATE_LIMIT_KEY)  # Also clear backoff

    # Clear in-memory fallback
    mem_count = len(_mem_cache)
    _mem_cache.clear()
    global _mem_rate_limited_until
    _mem_rate_limited_until = 0

    total = redis_deleted + mem_count
    return {
        "message": f"Cache cleared. {redis_deleted} Redis key(s) + {mem_count} in-memory entry(ies) removed.",
        "redis_available": redis.is_available,
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

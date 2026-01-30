"""
Market Schemas - Pydantic models for market price API
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field
from enum import Enum


class TrendTypeSchema(str, Enum):
    UP = "up"
    DOWN = "down"
    STABLE = "stable"


class MarketPriceBase(BaseModel):
    commodity: str = Field(..., min_length=1, max_length=100)
    price: float = Field(..., gt=0)
    unit: str = Field(default="Quintal", max_length=50)
    location: str = Field(..., min_length=1, max_length=255)
    trend: TrendTypeSchema = TrendTypeSchema.STABLE
    change_percent: float = Field(default=0.0)
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    arrival_qty: Optional[float] = None


class MarketPriceCreate(MarketPriceBase):
    """Schema for creating a new market price entry."""
    pass


class MarketPriceUpdate(BaseModel):
    """Schema for updating a market price entry."""
    price: Optional[float] = Field(None, gt=0)
    trend: Optional[TrendTypeSchema] = None
    change_percent: Optional[float] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    arrival_qty: Optional[float] = None


class MarketPriceResponse(MarketPriceBase):
    """Response schema for market price."""
    id: str
    recorded_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class MarketPriceListResponse(BaseModel):
    """Paginated list of market prices."""
    prices: List[MarketPriceResponse]
    total: int
    page: int
    page_size: int

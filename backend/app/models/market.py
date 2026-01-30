"""
Market Price Model - SQLAlchemy ORM model for commodity market prices
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Float, DateTime, Text, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
import enum

from app.database import Base


class TrendType(str, enum.Enum):
    UP = "up"
    DOWN = "down"
    STABLE = "stable"


class MarketPrice(Base):
    """Market price for agricultural commodities at different mandis/locations."""
    __tablename__ = "market_prices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    commodity = Column(String(100), nullable=False, index=True)
    price = Column(Float, nullable=False)  # Price per unit
    unit = Column(String(50), default="Quintal")
    location = Column(String(255), nullable=False, index=True)  # Mandi name
    trend = Column(SQLEnum(TrendType), default=TrendType.STABLE)
    change_percent = Column(Float, default=0.0)  # e.g., +5.0 or -2.5
    min_price = Column(Float, nullable=True)
    max_price = Column(Float, nullable=True)
    arrival_qty = Column(Float, nullable=True)  # Quantity arrived at mandi
    recorded_at = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<MarketPrice {self.commodity} @ {self.location}: ₹{self.price}>"

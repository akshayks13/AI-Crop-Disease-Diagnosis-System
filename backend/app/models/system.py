"""
System Models - Logs and Metrics for Admin Dashboard
"""
import uuid
from datetime import datetime
from typing import Optional, Dict, Any

from sqlalchemy import String, Text, DateTime, Float, Integer, JSON
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class SystemLog(Base):
    """
    System log entries for admin monitoring.
    
    Attributes:
        id: Unique identifier
        level: Log level (INFO, WARNING, ERROR, CRITICAL)
        message: Log message
        source: Source of the log (e.g., 'diagnosis', 'auth')
        user_id: Optional user associated with the log
        log_metadata: Additional JSON metadata
        created_at: Log timestamp
    """
    __tablename__ = "system_logs"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    level: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        index=True,
    )
    message: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )
    source: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True,
        index=True,
    )
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        nullable=True,
        index=True,
    )
    log_metadata: Mapped[Optional[Dict[str, Any]]] = mapped_column(
        JSON,
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        index=True,
    )
    
    def __repr__(self) -> str:
        return f"<SystemLog [{self.level}] {self.message[:50]}>"


class SystemMetric(Base):
    """
    System metrics for dashboard analytics.
    
    Stores aggregated metrics like daily diagnoses, API health, etc.
    
    Attributes:
        id: Unique identifier
        metric_name: Name of the metric
        metric_value: Numeric value
        metric_type: Type (count, gauge, percentage)
        tags: JSON tags for filtering
        recorded_at: Metric timestamp
    """
    __tablename__ = "system_metrics"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    metric_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        index=True,
    )
    metric_value: Mapped[float] = mapped_column(
        Float,
        nullable=False,
    )
    metric_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="gauge",
    )
    tags: Mapped[Optional[Dict[str, Any]]] = mapped_column(
        JSON,
        nullable=True,
    )
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        index=True,
    )
    
    def __repr__(self) -> str:
        return f"<SystemMetric {self.metric_name}={self.metric_value}>"


class DailyStats(Base):
    """
    Daily aggregated statistics for dashboard.
    
    Attributes:
        id: Unique identifier
        date: The date for these stats
        total_diagnoses: Number of diagnoses made
        total_questions: Number of questions asked
        total_answers: Number of answers provided
        new_users: Number of new registrations
        active_users: Number of active users
        avg_confidence: Average ML confidence score
        error_count: Number of errors occurred
    """
    __tablename__ = "daily_stats"
    
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    date: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        unique=True,
        index=True,
    )
    total_diagnoses: Mapped[int] = mapped_column(
        Integer,
        default=0,
    )
    total_questions: Mapped[int] = mapped_column(
        Integer,
        default=0,
    )
    total_answers: Mapped[int] = mapped_column(
        Integer,
        default=0,
    )
    new_users: Mapped[int] = mapped_column(
        Integer,
        default=0,
    )
    active_users: Mapped[int] = mapped_column(
        Integer,
        default=0,
    )
    avg_confidence: Mapped[Optional[float]] = mapped_column(
        Float,
        nullable=True,
    )
    error_count: Mapped[int] = mapped_column(
        Integer,
        default=0,
    )
    
    def __repr__(self) -> str:
        return f"<DailyStats {self.date.date()} - {self.total_diagnoses} diagnoses>"

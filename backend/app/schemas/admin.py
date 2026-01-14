"""
Admin Schemas - Pydantic models for admin operations
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel


class ExpertApprovalRequest(BaseModel):
    """Schema for expert approval/rejection."""
    approved: bool
    rejection_reason: Optional[str] = None


class ExpertPendingResponse(BaseModel):
    """Schema for pending expert info."""
    id: str
    email: str
    full_name: str
    phone: Optional[str]
    expertise_domain: Optional[str]
    qualification: Optional[str]
    experience_years: Optional[int]
    location: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class SystemMetricsResponse(BaseModel):
    """Schema for system metrics."""
    total_users: int
    total_farmers: int
    total_experts: int
    pending_experts: int
    total_diagnoses: int
    total_questions: int
    resolved_questions: int
    diagnoses_today: int
    questions_today: int
    storage_used_mb: float


class DashboardResponse(BaseModel):
    """Schema for admin dashboard."""
    metrics: SystemMetricsResponse
    recent_diagnoses: int
    recent_questions: int
    recent_signups: int
    system_health: str  # healthy, degraded, critical


class SystemLogResponse(BaseModel):
    """Schema for system log entry."""
    id: str
    level: str
    message: str
    source: Optional[str]
    user_id: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class SystemLogListResponse(BaseModel):
    """Schema for paginated system logs."""
    logs: List[SystemLogResponse]
    total: int
    page: int
    page_size: int


class UserManagementResponse(BaseModel):
    """Schema for user management info."""
    id: str
    email: str
    full_name: str
    role: str
    status: str
    created_at: datetime
    diagnoses_count: int
    questions_count: int

    class Config:
        from_attributes = True

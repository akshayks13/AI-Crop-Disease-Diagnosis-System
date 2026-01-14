"""
Question Schemas - Pydantic models for Q&A operations
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


class QuestionCreate(BaseModel):
    """Schema for creating a question."""
    question_text: str = Field(..., min_length=10, max_length=2000)
    diagnosis_id: Optional[str] = None


class AnswerCreate(BaseModel):
    """Schema for creating an answer."""
    question_id: str
    answer_text: str = Field(..., min_length=10, max_length=5000)


class AnswerResponse(BaseModel):
    """Schema for answer response."""
    id: str
    expert_id: str
    expert_name: str
    answer_text: str
    rating: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True


class QuestionResponse(BaseModel):
    """Schema for question response."""
    id: str
    farmer_id: str
    farmer_name: str
    question_text: str
    media_path: Optional[str]
    diagnosis_id: Optional[str]
    status: str
    answers: List[AnswerResponse]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class QuestionListResponse(BaseModel):
    """Schema for paginated question list."""
    questions: List[QuestionResponse]
    total: int
    page: int
    page_size: int


class QuestionSummary(BaseModel):
    """Simplified question for listings."""
    id: str
    question_text: str
    status: str
    answer_count: int
    created_at: datetime

    class Config:
        from_attributes = True

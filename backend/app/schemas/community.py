"""
Community Schemas - Pydantic models for community forum API
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


class AuthorInfo(BaseModel):
    """Basic author information."""
    id: str
    full_name: str
    
    class Config:
        from_attributes = True


# ============== Comment Schemas ==============

class CommentCreate(BaseModel):
    """Schema for creating a comment."""
    content: str = Field(..., min_length=1, max_length=2000)


class CommentResponse(BaseModel):
    """Response schema for a comment."""
    id: str
    content: str
    author: AuthorInfo
    created_at: datetime

    class Config:
        from_attributes = True


# ============== Post Schemas ==============

class PostCreate(BaseModel):
    """Schema for creating a post."""
    title: str = Field(..., min_length=5, max_length=255)
    content: str = Field(..., min_length=10, max_length=5000)
    category: Optional[str] = "general"


class PostUpdate(BaseModel):
    """Schema for updating a post."""
    title: Optional[str] = Field(None, min_length=5, max_length=255)
    content: Optional[str] = Field(None, min_length=10, max_length=5000)
    category: Optional[str] = None


class PostResponse(BaseModel):
    """Response schema for a post (list view)."""
    id: str
    title: str
    content: str
    image_path: Optional[str] = None
    category: Optional[str] = "general"
    likes_count: int
    comments_count: int
    author: AuthorInfo
    is_expert_post: bool = False
    is_liked: bool = False  # Whether current user liked it
    created_at: datetime

    class Config:
        from_attributes = True


class PostDetailResponse(PostResponse):
    """Detailed response schema for a post including comments."""
    comments: List[CommentResponse] = []


class PostListResponse(BaseModel):
    """Paginated list of posts."""
    posts: List[PostResponse]
    total: int
    page: int
    page_size: int


class LikeResponse(BaseModel):
    """Response for like/unlike action."""
    liked: bool
    likes_count: int

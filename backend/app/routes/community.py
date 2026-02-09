"""
Community Routes - API endpoints for community forum
"""
import uuid
from typing import Optional
from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.auth.dependencies import get_current_user
from app.models.user import User
from app.models.community import CommunityPost, CommunityComment, PostLike
from app.schemas.community import (
    PostCreate,
    PostUpdate,
    PostResponse,
    PostDetailResponse,
    PostListResponse,
    CommentCreate,
    CommentResponse,
    LikeResponse,
)
from app.config import get_settings

router = APIRouter(prefix="/community", tags=["Community Forum"])
settings = get_settings()


@router.get("/posts", response_model=PostListResponse)
async def get_posts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=50),
    search: Optional[str] = None,
    my_posts_only: bool = False,
    expert_posts_only: bool = False,
    category: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get list of community posts with pagination and filters.
    """
    query = select(CommunityPost).options(selectinload(CommunityPost.author))
    count_query = select(func.count(CommunityPost.id))
    
    # Filters
    filters = []
    
    if search:
        filters.append(or_(
            CommunityPost.title.ilike(f"%{search}%"),
            CommunityPost.content.ilike(f"%{search}%"),
        ))
    
    if my_posts_only:
        filters.append(CommunityPost.user_id == current_user.id)
        
    if expert_posts_only:
        filters.append(CommunityPost.is_expert_post == True)
        
    if category:
        filters.append(CommunityPost.category == category)
        
    if filters:
        query = query.where(and_(*filters))
        count_query = count_query.where(and_(*filters))
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Order by pinned first, then by date
    query = query.order_by(CommunityPost.is_pinned.desc(), CommunityPost.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    
    result = await db.execute(query)
    posts = result.scalars().all()
    
    # Check if current user liked each post
    post_ids = [post.id for post in posts]
    liked_post_ids = set()
    if post_ids:
        like_query = select(PostLike.post_id).where(
            and_(PostLike.post_id.in_(post_ids), PostLike.user_id == current_user.id)
        )
        like_result = await db.execute(like_query)
        liked_post_ids = {row[0] for row in like_result.fetchall()}
    
    return {
        "posts": [
            {
                "id": str(post.id),
                "title": post.title,
                "content": post.content,
                "image_path": post.image_path,
                "category": post.category,
                "likes_count": post.likes_count,
                "comments_count": post.comments_count,
                "author": {
                    "id": str(post.author.id) if post.author else "unknown",
                    "full_name": post.author.full_name if post.author else "Unknown User",
                },
                "is_expert_post": post.is_expert_post,
                "is_liked": post.id in liked_post_ids,
                "created_at": post.created_at,
            }
            for post in posts
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.get("/posts/{post_id}", response_model=PostDetailResponse)
async def get_post_detail(
    post_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get detailed post with comments.
    """
    result = await db.execute(
        select(CommunityPost)
        .options(
            selectinload(CommunityPost.author),
            selectinload(CommunityPost.comments).selectinload(CommunityComment.author),
        )
        .where(CommunityPost.id == post_id)
    )
    post = result.scalar_one_or_none()
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # Check if liked
    like_result = await db.execute(
        select(PostLike).where(
            and_(PostLike.post_id == post.id, PostLike.user_id == current_user.id)
        )
    )
    is_liked = like_result.scalar_one_or_none() is not None
    
    return {
        "id": str(post.id),
        "title": post.title,
        "content": post.content,
        "image_path": post.image_path,
        "likes_count": post.likes_count,
        "comments_count": post.comments_count,
        "author": {
            "id": str(post.author.id),
            "full_name": post.author.full_name,
        },
        "is_liked": is_liked,
        "created_at": post.created_at,
        "comments": [
            {
                "id": str(comment.id),
                "content": comment.content,
                "author": {
                    "id": str(comment.author.id),
                    "full_name": comment.author.full_name,
                },
                "created_at": comment.created_at,
            }
            for comment in sorted(post.comments, key=lambda c: c.created_at)
        ],
    }


@router.post("/posts", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(
    post_data: PostCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new community post (JSON body, no image).
    """
    # Check if user is expert
    from app.models.user import UserRole, UserStatus
    is_expert = current_user.role == UserRole.EXPERT and current_user.status == UserStatus.ACTIVE
    
    new_post = CommunityPost(
        user_id=current_user.id,
        title=post_data.title,
        content=post_data.content,
        image_path=None,
        category=post_data.category or "general",
        is_expert_post=is_expert,
    )
    
    db.add(new_post)
    await db.commit()
    await db.refresh(new_post)
    
    return {
        "id": str(new_post.id),
        "title": new_post.title,
        "content": new_post.content,
        "image_path": new_post.image_path,
        "category": new_post.category,
        "likes_count": 0,
        "comments_count": 0,
        "author": {
            "id": str(current_user.id),
            "full_name": current_user.full_name,
        },
        "is_expert_post": is_expert,
        "is_liked": False,
        "created_at": new_post.created_at,
    }


@router.post("/posts/with-image", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
async def create_post_with_image(
    title: str = Form(..., min_length=5, max_length=255),
    content: str = Form(..., min_length=10),
    category: str = Form("general"),
    image: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new community post with optional image attachment.
    """
    image_path = None
    
    if image and image.filename:
        # Save image
        upload_dir = Path(settings.upload_dir) / "community"
        upload_dir.mkdir(parents=True, exist_ok=True)
        
        ext = Path(image.filename).suffix
        filename = f"{uuid.uuid4()}{ext}"
        filepath = upload_dir / filename
        
        content_bytes = await image.read()
        with open(filepath, "wb") as f:
            f.write(content_bytes)
        
        image_path = f"/uploads/community/{filename}"
    
    # Check if user is expert
    from app.models.user import UserRole, UserStatus
    is_expert = current_user.role == UserRole.EXPERT and current_user.status == UserStatus.ACTIVE

    new_post = CommunityPost(
        user_id=current_user.id,
        title=title,
        content=content,
        image_path=image_path,
        category=category,
        is_expert_post=is_expert,
    )
    
    db.add(new_post)
    await db.commit()
    await db.refresh(new_post)
    
    return {
        "id": str(new_post.id),
        "title": new_post.title,
        "content": new_post.content,
        "image_path": new_post.image_path,
        "category": new_post.category,
        "likes_count": 0,
        "comments_count": 0,
        "author": {
            "id": str(current_user.id),
            "full_name": current_user.full_name,
        },
        "is_expert_post": is_expert,
        "is_liked": False,
        "created_at": new_post.created_at,
    }


@router.put("/posts/{post_id}", response_model=PostResponse)
async def update_post(
    post_id: str,
    post_data: PostUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Update own post.
    """
    result = await db.execute(
        select(CommunityPost)
        .options(selectinload(CommunityPost.author))
        .where(CommunityPost.id == post_id)
    )
    post = result.scalar_one_or_none()
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    if post.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this post")
    
    update_data = post_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(post, field, value)
    
    post.updated_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(post)
    
    return {
        "id": str(post.id),
        "title": post.title,
        "content": post.content,
        "image_path": post.image_path,
        "likes_count": post.likes_count,
        "comments_count": post.comments_count,
        "author": {
            "id": str(post.author.id),
            "full_name": post.author.full_name,
        },
        "is_liked": False,
        "created_at": post.created_at,
    }


@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_post(
    post_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete own post.
    """
    result = await db.execute(
        select(CommunityPost).where(CommunityPost.id == post_id)
    )
    post = result.scalar_one_or_none()
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    if post.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")
    
    await db.delete(post)
    await db.commit()


@router.post("/posts/{post_id}/like", response_model=LikeResponse)
async def toggle_like(
    post_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Toggle like on a post.
    """
    # Get post
    post_result = await db.execute(
        select(CommunityPost).where(CommunityPost.id == post_id)
    )
    post = post_result.scalar_one_or_none()
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # Check existing like
    like_result = await db.execute(
        select(PostLike).where(
            and_(PostLike.post_id == post_id, PostLike.user_id == current_user.id)
        )
    )
    existing_like = like_result.scalar_one_or_none()
    
    if existing_like:
        # Unlike
        await db.delete(existing_like)
        post.likes_count = max(0, post.likes_count - 1)
        liked = False
    else:
        # Like
        new_like = PostLike(post_id=uuid.UUID(post_id), user_id=current_user.id)
        db.add(new_like)
        post.likes_count += 1
        liked = True
    
    await db.commit()
    await db.refresh(post)
    
    return {"liked": liked, "likes_count": post.likes_count}


@router.post("/posts/{post_id}/comments", response_model=CommentResponse, status_code=status.HTTP_201_CREATED)
async def add_comment(
    post_id: str,
    comment_data: CommentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Add a comment to a post.
    """
    # Get post
    post_result = await db.execute(
        select(CommunityPost).where(CommunityPost.id == post_id)
    )
    post = post_result.scalar_one_or_none()
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    new_comment = CommunityComment(
        post_id=uuid.UUID(post_id),
        user_id=current_user.id,
        content=comment_data.content,
    )
    
    db.add(new_comment)
    post.comments_count += 1
    
    await db.commit()
    await db.refresh(new_comment)
    
    return {
        "id": str(new_comment.id),
        "content": new_comment.content,
        "author": {
            "id": str(current_user.id),
            "full_name": current_user.full_name,
        },
        "created_at": new_comment.created_at,
    }


@router.delete("/posts/{post_id}/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_comment(
    post_id: str,
    comment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete own comment.
    """
    result = await db.execute(
        select(CommunityComment).where(
            and_(CommunityComment.id == comment_id, CommunityComment.post_id == post_id)
        )
    )
    comment = result.scalar_one_or_none()
    
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    if comment.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this comment")
    
    # Update post comment count
    post_result = await db.execute(
        select(CommunityPost).where(CommunityPost.id == post_id)
    )
    post = post_result.scalar_one_or_none()
    if post:
        post.comments_count = max(0, post.comments_count - 1)
    
    await db.delete(comment)
    await db.commit()

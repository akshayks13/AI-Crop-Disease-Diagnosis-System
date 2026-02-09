"""
Community Models - SQLAlchemy ORM models for community forum
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, Boolean, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class CommunityPost(Base):
    """Community forum post from farmers or experts."""
    __tablename__ = "community_posts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    image_path = Column(String(500), nullable=True)
    category = Column(String(50), default="general")  # general, tip, article, question
    is_expert_post = Column(Boolean, default=False)  # Expert-created post
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    is_pinned = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    author = relationship("User", backref="posts", foreign_keys=[user_id])
    comments = relationship("CommunityComment", back_populates="post", cascade="all, delete-orphan")
    likes = relationship("PostLike", back_populates="post", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<CommunityPost {self.title[:30]}>"


class CommunityComment(Base):
    """Comment on a community post."""
    __tablename__ = "community_comments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    post_id = Column(UUID(as_uuid=True), ForeignKey("community_posts.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    post = relationship("CommunityPost", back_populates="comments")
    author = relationship("User", backref="comments")

    def __repr__(self):
        return f"<CommunityComment on {self.post_id}>"


class PostLike(Base):
    """Like on a community post (unique per user)."""
    __tablename__ = "post_likes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    post_id = Column(UUID(as_uuid=True), ForeignKey("community_posts.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    post = relationship("CommunityPost", back_populates="likes")

    def __repr__(self):
        return f"<PostLike post={self.post_id} user={self.user_id}>"

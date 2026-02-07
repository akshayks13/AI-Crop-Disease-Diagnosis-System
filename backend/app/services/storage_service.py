"""
Storage Service - File Upload and Management
"""
import os
import uuid
import aiofiles
from datetime import datetime
from typing import Optional, Tuple
from pathlib import Path
import logging

from fastapi import UploadFile, HTTPException, status

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Allowed file types
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/jpg"}
ALLOWED_VIDEO_TYPES = {"video/mp4", "video/quicktime", "video/webm"}
ALLOWED_TYPES = ALLOWED_IMAGE_TYPES | ALLOWED_VIDEO_TYPES


class StorageService:
    """Service for handling file uploads and storage."""
    
    def __init__(self):
        """Initialize storage service."""
        self.upload_dir = Path(settings.upload_dir)
        self.max_size_bytes = settings.max_file_size_mb * 1024 * 1024
        self._ensure_directories()
    
    def _ensure_directories(self) -> None:
        """Ensure upload directories exist."""
        directories = [
            self.upload_dir,
            self.upload_dir / "images",
            self.upload_dir / "videos",
            self.upload_dir / "questions",
        ]
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
    
    def _validate_file(self, file: UploadFile) -> Tuple[str, str]:
        """
        Validate uploaded file.
        
        Args:
            file: Uploaded file
            
        Returns:
            Tuple of (media_type, subdirectory)
            
        Raises:
            HTTPException if validation fails
        """
        content_type = file.content_type
        
        if content_type not in ALLOWED_TYPES:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=f"File type {content_type} not supported. Allowed: JPEG, PNG, WebP, MP4"
            )
        
        if content_type in ALLOWED_IMAGE_TYPES:
            return "image", "images"
        else:
            return "video", "videos"
    
    async def save_upload(
        self,
        file: UploadFile,
        user_id: uuid.UUID,
        category: str = "diagnosis"
    ) -> Tuple[str, str]:
        """
        Save an uploaded file.
        
        Args:
            file: Uploaded file
            user_id: User who uploaded the file
            category: Category for organization (diagnosis, question)
            
        Returns:
            Tuple of (saved_path, media_type)
        """
        media_type, subdir = self._validate_file(file)
        
        # Generate unique filename
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        file_ext = Path(file.filename).suffix.lower() or ".jpg"
        unique_name = f"{user_id}_{timestamp}_{uuid.uuid4().hex[:8]}{file_ext}"
        
        # Determine save path
        if category == "question":
            save_dir = self.upload_dir / "questions"
        else:
            save_dir = self.upload_dir / subdir
        
        save_path = save_dir / unique_name
        
        # Read and validate file size
        content = await file.read()
        if len(content) > self.max_size_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File too large. Maximum size: {settings.max_file_size_mb}MB"
            )
        
        # Save file
        async with aiofiles.open(save_path, "wb") as f:
            await f.write(content)
        
        logger.info(f"Saved file: {save_path} ({len(content)} bytes)")
        
        # Return URL-friendly path for database storage
        url_path = f"/uploads/{save_path.relative_to(self.upload_dir)}"
        return url_path, media_type
    
    async def delete_file(self, file_path: str) -> bool:
        """
        Delete a file from storage.
        
        Args:
            file_path: Path to the file
            
        Returns:
            True if deleted, False if not found
        """
        path = Path(file_path)
        if path.exists():
            path.unlink()
            logger.info(f"Deleted file: {file_path}")
            return True
        return False
    
    def get_file_url(self, file_path: str) -> str:
        """
        Get URL for accessing a file.
        
        Args:
            file_path: Path to the file
            
        Returns:
            URL path for the file
        """
        # In production, return CDN or S3 URL
        path = Path(file_path)
        relative = path.relative_to(self.upload_dir)
        return f"/uploads/{relative}"
    
    def get_storage_stats(self) -> dict:
        """Get storage usage statistics."""
        total_size = 0
        file_count = 0
        
        for path in self.upload_dir.rglob("*"):
            if path.is_file():
                total_size += path.stat().st_size
                file_count += 1
        
        return {
            "total_files": file_count,
            "total_size_mb": round(total_size / (1024 * 1024), 2),
            "upload_dir": str(self.upload_dir),
        }


# Singleton instance
_storage_service: Optional[StorageService] = None


def get_storage_service() -> StorageService:
    """Get or create storage service instance."""
    global _storage_service
    if _storage_service is None:
        _storage_service = StorageService()
    return _storage_service

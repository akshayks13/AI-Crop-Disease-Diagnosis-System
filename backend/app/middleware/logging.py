"""
Middleware for capturing system activity and errors to the database.

NOTE: This middleware writes to the SystemLog database table (visible in admin dashboard).
      It does NOT interact with the loguru file logger (backend/logs/app.log).
"""
import time
import uuid
from typing import Optional

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

from app.database import async_session_maker
from app.models.system import SystemLog
from app.auth.jwt_handler import decode_token
from app.utils.logger import logger  # loguru — only used as fallback if DB write fails


class SystemLoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware that logs significant system events to the database.
    
    Logs:
    - All requests with status code >= 400 (Errors)
    - All mutation requests (POST, PUT, DELETE) (Activity)
    - Skips GET 200s to avoid DB spam (unless critical)
    """
    
    def __init__(self, app: ASGIApp):
        super().__init__(app)
        
    async def dispatch(self, request: Request, call_next) -> Response:
        start_time = time.time()
        
        # Process request
        try:
            response = await call_next(request)
            
            # Record log if significant
            if self._should_log(request, response):
                await self._log_request(request, response, time.time() - start_time)
                
            return response
            
        except Exception as e:
            # Errors will be caught by global exception handler usually, 
            # but if it bubbles up here, we log it too
            await self._log_error(request, str(e))
            raise e
            
    def _should_log(self, request: Request, response: Response) -> bool:
        """Determine if request should be logged."""
        # Don't log admin log viewing itself to avoid recursion
        if "/admin/logs" in request.url.path:
            return False
            
        # Log all errors
        if response.status_code >= 400:
            return True
            
        # Log all state-changing operations
        if request.method in ["POST", "PUT", "DELETE", "PATCH"]:
            return True
            
        return False
        
    async def _log_request(self, request: Request, response: Response, duration: float):
        """Write log entry to database."""
        try:
            # Extract user ID if available
            user_id = self._get_user_id(request)
            
            level = "INFO"
            if response.status_code >= 500:
                level = "ERROR"
            elif response.status_code >= 400:
                level = "WARNING"
                
            message = f"{request.method} {request.url.path} - {response.status_code}"
            
            async with async_session_maker() as session:
                log = SystemLog(
                    level=level,
                    message=message,
                    source="api",
                    user_id=user_id,
                    log_metadata={
                        "method": request.method,
                        "path": request.url.path,
                        "status_code": response.status_code,
                        "duration_ms": round(duration * 1000, 2),
                        "client_ip": request.client.host if request.client else None
                    }
                )
                session.add(log)
                await session.commit()
                
        except Exception as e:
            # Don't let logging fail the request
            logger.error(f"Failed to write system log: {e}")

    async def _log_error(self, request: Request, error_msg: str):
        """Log unhandled exception."""
        try:
            user_id = self._get_user_id(request)
            
            async with async_session_maker() as session:
                log = SystemLog(
                    level="CRITICAL",
                    message=f"Unhandled Exception: {error_msg[:100]}",
                    source="api",
                    user_id=user_id,
                    log_metadata={
                        "method": request.method,
                        "path": request.url.path,
                        "error": error_msg
                    }
                )
                session.add(log)
                await session.commit()
        except Exception:
            pass

    def _get_user_id(self, request: Request) -> Optional[uuid.UUID]:
        """Attempt to extract user ID from Authorization header."""
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            return None
            
        try:
            token = auth_header.split(" ")[1]
            payload = decode_token(token)
            if payload and payload.get("sub"):
                return uuid.UUID(payload["sub"])
        except Exception:
            pass
        return None

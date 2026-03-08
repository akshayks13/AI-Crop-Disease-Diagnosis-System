"""
Middleware for capturing system activity and errors to the database.

NOTE: This middleware writes to the SystemLog database table (visible in admin dashboard).
      It does NOT interact with the loguru file logger (backend/logs/app.log).
"""
import time
import uuid
from typing import Optional

from starlette.requests import Request
from starlette.types import ASGIApp, Receive, Scope, Send

from app.database import async_session_maker
from app.models.system import SystemLog
from app.auth.jwt_handler import decode_token
from app.utils.logger import logger  # loguru — only used as fallback if DB write fails


class SystemLoggingMiddleware:
    """
    Pure ASGI middleware that logs significant system events to the database.

    Avoids BaseHTTPMiddleware to prevent the known Starlette
    'RuntimeError: No response returned.' streaming issue.

    Logs:
    - All requests with status code >= 400 (Errors)
    - All mutation requests (POST, PUT, DELETE) (Activity)
    - Skips GET 200s to avoid DB spam (unless critical)
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request = Request(scope, receive)
        start_time = time.time()
        status_code: list[int] = [500]

        async def send_wrapper(message) -> None:
            if message["type"] == "http.response.start":
                status_code[0] = message["status"]
            await send(message)

        exc_caught: Optional[Exception] = None
        try:
            await self.app(scope, receive, send_wrapper)
        except Exception as e:
            exc_caught = e
            raise
        finally:
            duration = time.time() - start_time
            if exc_caught is not None:
                await self._log_error(request, str(exc_caught))
            else:
                code = status_code[0]
                if self._should_log(request, code):
                    await self._log_request(request, code, duration)
            
    def _should_log(self, request: Request, status_code: int) -> bool:
        """Determine if request should be logged."""
        # Don't log admin log viewing itself to avoid recursion
        if "/admin/logs" in request.url.path:
            return False

        # Log all errors
        if status_code >= 400:
            return True

        # Log all state-changing operations
        if request.method in ["POST", "PUT", "DELETE", "PATCH"]:
            return True

        return False

    async def _log_request(self, request: Request, status_code: int, duration: float):
        """Write log entry to database."""
        try:
            # Extract user ID if available
            user_id = self._get_user_id(request)

            level = "INFO"
            if status_code >= 500:
                level = "ERROR"
            elif status_code >= 400:
                level = "WARNING"

            message = f"{request.method} {request.url.path} - {status_code}"
            
            async with async_session_maker() as session:
                log = SystemLog(
                    level=level,
                    message=message,
                    source="api",
                    user_id=user_id,
                    log_metadata={
                        "method": request.method,
                        "path": request.url.path,
                        "status_code": status_code,
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

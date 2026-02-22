"""
Structured Logger — uses loguru for file-based error tracking.

IMPORTANT: This is completely separate from the admin dashboard's SystemLog
(which is stored in the database via SystemLoggingMiddleware). These logs
are written to disk only (backend/logs/app.log) and are NOT visible in the
admin panel — they are for developer/ops debugging only.
"""
import sys
from pathlib import Path
from loguru import logger

# Ensure logs directory exists
LOGS_DIR = Path(__file__).parent.parent.parent / "logs"
LOGS_DIR.mkdir(exist_ok=True)

# Remove default loguru handler
logger.remove()

# Console handler — human-readable, colorized
logger.add(
    sys.stderr,
    level="INFO",
    format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{line}</cyan> — <level>{message}</level>",
    colorize=True,
)

# File handler — structured JSON, rotating, 7-day retention
# Completely separate from admin DB logs
logger.add(
    LOGS_DIR / "app.log",
    level="DEBUG",
    format="{time:YYYY-MM-DD HH:mm:ss.SSS} | {level} | {name}:{line} | {message}",
    rotation="10 MB",
    retention="7 days",
    compression="zip",
    serialize=True,  # JSON format for structured parsing
    enqueue=True,    # Thread-safe async logging
)

# Error-only file for quick triage
logger.add(
    LOGS_DIR / "errors.log",
    level="ERROR",
    format="{time:YYYY-MM-DD HH:mm:ss.SSS} | {level} | {name}:{line} | {message}",
    rotation="5 MB",
    retention="30 days",
    serialize=True,
    enqueue=True,
)

__all__ = ["logger"]

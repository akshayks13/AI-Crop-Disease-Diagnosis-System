"""
Redis Service — Async caching layer for the Crop Disease Diagnosis System.

Provides a clean async interface for Redis operations with graceful fallback:
- If REDIS_URL is not configured, all operations are no-ops (returns None / False).
- If Redis is unreachable at runtime, errors are caught and logged — the app
  continues working using the in-memory fallback in the calling module.

Usage:
    from app.services.redis_service import get_redis_service

    redis = get_redis_service()
    await redis.set("my_key", "my_value", ttl=3600)
    value = await redis.get("my_key")
"""

import json
import logging
from typing import Any, Optional

logger = logging.getLogger(__name__)

# Module-level singleton
_redis_service: Optional["RedisService"] = None


class RedisService:
    """
    Async Redis client wrapper with graceful no-op fallback.

    When REDIS_URL is empty or Redis is unreachable, every method
    silently returns None / False — callers can keep working normally.
    """

    def __init__(self, redis_url: str = ""):
        self._url = redis_url
        self._client = None
        self._available = False

        if redis_url:
            self._connect()

    def _connect(self) -> None:
        """Attempt to create the Redis client (lazy; no I/O at init time)."""
        try:
            import redis.asyncio as aioredis  # type: ignore[import]
            self._client = aioredis.from_url(
                self._url,
                encoding="utf-8",
                decode_responses=True,
                socket_connect_timeout=2,
                socket_timeout=2,
            )
            self._available = True
            logger.info(f"[Redis] Client created for {self._url}")
        except Exception as exc:
            logger.warning(f"[Redis] Failed to create client: {exc}")
            self._available = False

    # ── Public API ─────────────────────────────────────────────────────────────

    async def get(self, key: str) -> Optional[Any]:
        """
        Retrieve a JSON-serialised value by key.
        Returns None if key not found, Redis unavailable, or any error.
        """
        if not self._available or not self._client:
            return None
        try:
            raw = await self._client.get(key)
            if raw is None:
                return None
            return json.loads(raw)
        except Exception as exc:
            logger.warning(f"[Redis] GET error for '{key}': {exc}")
            return None

    async def set(self, key: str, value: Any, ttl: int = 3600) -> bool:
        """
        Store a JSON-serialised value with an expiry (seconds).
        Returns True on success, False on failure / unavailable.
        """
        if not self._available or not self._client:
            return False
        try:
            await self._client.set(key, json.dumps(value), ex=ttl)
            return True
        except Exception as exc:
            logger.warning(f"[Redis] SET error for '{key}': {exc}")
            return False

    async def get_raw(self, key: str) -> Optional[str]:
        """Retrieve a raw string value (not JSON-parsed)."""
        if not self._available or not self._client:
            return None
        try:
            return await self._client.get(key)
        except Exception as exc:
            logger.warning(f"[Redis] GET_RAW error for '{key}': {exc}")
            return None

    async def set_raw(self, key: str, value: str, ttl: int = 3600) -> bool:
        """Store a raw string value with an expiry."""
        if not self._available or not self._client:
            return False
        try:
            await self._client.set(key, value, ex=ttl)
            return True
        except Exception as exc:
            logger.warning(f"[Redis] SET_RAW error for '{key}': {exc}")
            return False

    async def delete(self, key: str) -> bool:
        """Delete a key. Returns True if deleted, False otherwise."""
        if not self._available or not self._client:
            return False
        try:
            result = await self._client.delete(key)
            return result > 0
        except Exception as exc:
            logger.warning(f"[Redis] DELETE error for '{key}': {exc}")
            return False

    async def delete_pattern(self, pattern: str) -> int:
        """
        Delete all keys matching a glob pattern.
        Returns the number of deleted keys.
        """
        if not self._available or not self._client:
            return 0
        try:
            keys = await self._client.keys(pattern)
            if keys:
                return await self._client.delete(*keys)
            return 0
        except Exception as exc:
            logger.warning(f"[Redis] DELETE_PATTERN error for '{pattern}': {exc}")
            return 0

    async def exists(self, key: str) -> bool:
        """Check if a key exists."""
        if not self._available or not self._client:
            return False
        try:
            return bool(await self._client.exists(key))
        except Exception as exc:
            logger.warning(f"[Redis] EXISTS error for '{key}': {exc}")
            return False

    async def ttl(self, key: str) -> int:
        """Return remaining TTL in seconds (-2 if not found, -1 if no expiry)."""
        if not self._available or not self._client:
            return -2
        try:
            return await self._client.ttl(key)
        except Exception as exc:
            logger.warning(f"[Redis] TTL error for '{key}': {exc}")
            return -2

    async def ping(self) -> bool:
        """Check if Redis is reachable."""
        if not self._available or not self._client:
            return False
        try:
            result = await self._client.ping()
            return result is True or result == b"PONG" or result == "PONG"
        except Exception:
            return False

    async def close(self) -> None:
        """Close the Redis connection gracefully."""
        if self._client:
            try:
                await self._client.aclose()
            except Exception:
                pass

    @property
    def is_available(self) -> bool:
        """True if Redis is configured and client was created successfully."""
        return self._available


# ── Singleton factory ──────────────────────────────────────────────────────────

def get_redis_service() -> "RedisService":
    """
    Return the singleton RedisService.
    Reads REDIS_URL from settings on first call.
    """
    global _redis_service
    if _redis_service is None:
        from app.config import get_settings
        settings = get_settings()
        redis_url = getattr(settings, "redis_url", "")
        _redis_service = RedisService(redis_url=redis_url)
    return _redis_service

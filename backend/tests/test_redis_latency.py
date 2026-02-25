"""
Redis latency test — compares DB vs Redis cache response times.

Usage:
    cd backend
    source venv/bin/activate
    PYTHONPATH=. python tests/test_redis_latency.py

Requires the backend database to be running locally.
Does NOT require the FastAPI server — talks to DB and Redis directly.
"""
import asyncio
import time
from statistics import mean



async def measure_db_latency(n_runs: int = 10) -> list[float]:
    """Measure raw PostgreSQL query latency (SELECT all crops)."""
    from app.database import AsyncSessionLocal
    from app.models.encyclopedia import CropInfo
    from sqlalchemy import select

    timings = []
    async with AsyncSessionLocal() as db:
        for _ in range(n_runs):
            t0 = time.perf_counter()
            result = await db.execute(select(CropInfo))
            result.scalars().all()
            timings.append((time.perf_counter() - t0) * 1000)  # → ms
    return timings


async def measure_redis_latency(n_runs: int = 10) -> list[float]:
    """Measure Redis GET latency (after one warm-up SET)."""
    from app.services.redis_service import RedisService

    redis = RedisService(redis_url="redis://localhost:6379/0")
    payload = {"crops": [{"name": f"Crop{i}", "season": "Rabi"} for i in range(20)], "total": 20}

    # Warm up — write to Redis
    await redis.set("latency_test:crops", payload, ttl=60)

    timings = []
    for _ in range(n_runs):
        t0 = time.perf_counter()
        val = await redis.get("latency_test:crops")
        timings.append((time.perf_counter() - t0) * 1000)

    await redis.delete("latency_test:crops")
    await redis.close()
    return timings


async def main():
    RUNS = 10
    print(f"\n{'='*55}")
    print(f"  Redis vs PostgreSQL Latency Comparison ({RUNS} runs each)")
    print(f"{'='*55}\n")

    print("⏳ Measuring PostgreSQL query latency...")
    try:
        db_times = await measure_db_latency(RUNS)
        print(f"  ✅ PostgreSQL — avg: {mean(db_times):.2f}ms  "
              f"min: {min(db_times):.2f}ms  max: {max(db_times):.2f}ms")
    except Exception as e:
        db_times = []
        print(f"  ❌ PostgreSQL error: {e}")

    print("\n⏳ Measuring Redis GET latency...")
    try:
        redis_times = await measure_redis_latency(RUNS)
        print(f"  ✅ Redis        — avg: {mean(redis_times):.2f}ms  "
              f"min: {min(redis_times):.2f}ms  max: {max(redis_times):.2f}ms")
    except Exception as e:
        redis_times = []
        print(f"  ❌ Redis error: {e}")

    if db_times and redis_times:
        speedup = mean(db_times) / mean(redis_times)
        saved_ms = mean(db_times) - mean(redis_times)
        print(f"\n{'='*55}")
        print(f"  🚀 Redis is {speedup:.1f}x faster — saves ~{saved_ms:.1f}ms per request")
        print(f"{'='*55}\n")


if __name__ == "__main__":
    asyncio.run(main())

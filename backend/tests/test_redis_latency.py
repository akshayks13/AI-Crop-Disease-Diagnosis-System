"""
Redis latency benchmark — fully standalone, no `app` module imports.

Compares raw PostgreSQL query time vs Redis GET time across multiple
endpoints' cache patterns to prove caching ROI.

Usage:
    cd <project-root>/backend
    venv/bin/python tests/test_redis_latency.py

Override env vars if needed:
    DATABASE_URL=postgresql+asyncpg://... REDIS_URL=redis://... venv/bin/python tests/test_redis_latency.py
"""
from __future__ import annotations  # Python 3.9 compat for `X | Y` type hints
import asyncio
import json
import os
import time
from pathlib import Path
from statistics import mean, stdev

# ── Load .env manually (no pydantic-settings needed) ─────────────────────────
_env_path = Path(__file__).parent.parent / ".env"
if _env_path.exists():
    for line in _env_path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, _, v = line.partition("=")
            os.environ.setdefault(k.strip(), v.strip())

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@localhost:5432/crop_diagnosis",
)
REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
RUNS = 15  # number of timed iterations per benchmark


# ── Benchmark helpers ─────────────────────────────────────────────────────────

def _fmt(ms_list: list[float]) -> str:
    avg = mean(ms_list)
    sd = stdev(ms_list) if len(ms_list) > 1 else 0
    return f"avg {avg:6.2f}ms  min {min(ms_list):5.2f}ms  max {max(ms_list):5.2f}ms  σ {sd:4.2f}ms"


async def bench_postgres(label: str, sql: str, n: int = RUNS) -> list[float] | None:
    """Time a raw SQL query against Postgres using asyncpg directly."""
    try:
        import asyncpg  # type: ignore
        # Normalise URL: asyncpg expects 'postgresql://' not 'postgresql+asyncpg://'
        url = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
        conn = await asyncpg.connect(url)
        timings = []
        for _ in range(n):
            t0 = time.perf_counter()
            await conn.fetch(sql)
            timings.append((time.perf_counter() - t0) * 1000)
        await conn.close()
        return timings
    except Exception as e:
        print(f"    ❌ {label} PostgreSQL error: {e}")
        return None


async def bench_redis_get(label: str, payload: dict, n: int = RUNS) -> list[float] | None:
    """Time a Redis GET after writing a typical cache payload."""
    try:
        import redis.asyncio as aioredis  # type: ignore
        r = aioredis.from_url(REDIS_URL, decode_responses=True)
        key = f"bench:{label}"
        await r.set(key, json.dumps(payload), ex=60)
        timings = []
        for _ in range(n):
            t0 = time.perf_counter()
            val = await r.get(key)
            _ = json.loads(val)  # include JSON parse time (same as prod)
            timings.append((time.perf_counter() - t0) * 1000)
        await r.delete(key)
        await r.aclose()
        return timings
    except Exception as e:
        print(f"    ❌ {label} Redis error: {e}")
        return None


def print_comparison(label: str, db: list[float] | None, cache: list[float] | None):
    print(f"\n  📊 {label}")
    if db:
        print(f"     DB     → {_fmt(db)}")
    if cache:
        print(f"     Redis  → {_fmt(cache)}")
    if db and cache:
        speedup = mean(db) / mean(cache)
        saved = mean(db) - mean(cache)
        print(f"     🚀  {speedup:.1f}x faster  |  saves ~{saved:.1f}ms per cached hit")


# ── Benchmarks ────────────────────────────────────────────────────────────────

async def main():
    print(f"\n{'━'*62}")
    print(f"  Redis vs PostgreSQL Latency Benchmark  ({RUNS} runs each)")
    print(f"  DB:    {DATABASE_URL[:55]}...")
    print(f"  Redis: {REDIS_URL}")
    print(f"{'━'*62}")

    benchmarks = [
        (
            "encyclopedia/crops  [SELECT all crops]",
            "SELECT * FROM crop_encyclopedia",
            {"crops": [{"id": str(i), "name": f"Crop{i}", "season": "Rabi"} for i in range(20)], "total": 20},
        ),
        (
            "encyclopedia/diseases  [SELECT all diseases]",
            "SELECT * FROM disease_encyclopedia",
            {"diseases": [{"id": str(i), "name": f"Disease{i}", "severity": "moderate"} for i in range(25)], "total": 25},
        ),
        (
            "admin/dashboard  [12 COUNT queries simulated]",
            # Simulate the sequence of count queries with a single query of sub-selects (since asyncpg doesn't return multiple statement results well)
            "SELECT (SELECT COUNT(*) FROM users) as u, (SELECT COUNT(*) FROM diagnoses) as d, (SELECT COUNT(*) FROM questions) as q",
            {"metrics": {"total_users": 42, "total_diagnoses": 300, "open_questions": 5, "pending_experts": 2}},
        ),
        (
            "expert/trending-diseases  [GROUP BY diagnoses]",
            "SELECT disease, COUNT(*) as cnt FROM diagnoses GROUP BY disease ORDER BY cnt DESC LIMIT 10",
            {"period": "week", "trending": [{"disease_name": f"Disease{i}", "count": 10 - i} for i in range(10)]},
        ),
    ]

    all_results = []
    for label, sql, payload in benchmarks:
        db_t, redis_t = await asyncio.gather(
            bench_postgres(label, sql),
            bench_redis_get(label, payload),
        )
        print_comparison(label, db_t, redis_t)
        if db_t and redis_t:
            all_results.append((mean(db_t), mean(redis_t)))

    if all_results:
        overall_db = mean(r[0] for r in all_results)
        overall_redis = mean(r[1] for r in all_results)
        print(f"\n{'━'*62}")
        print(f"  OVERALL  DB avg: {overall_db:.2f}ms  │  Redis avg: {overall_redis:.2f}ms")
        print(f"  Overall speedup: {overall_db / overall_redis:.1f}x  │  avg saving: {overall_db - overall_redis:.1f}ms/req")
        print(f"{'━'*62}\n")


if __name__ == "__main__":
    asyncio.run(main())

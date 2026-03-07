import asyncio
import os
import sys

from sqlalchemy import select

# Ensure backend package imports work when run from repo root or backend dir
BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if BACKEND_ROOT not in sys.path:
    sys.path.append(BACKEND_ROOT)

from app.database import async_session_maker
from app.models.system import SystemLog


async def check_logs(limit: int = 20):
    async with async_session_maker() as session:
        query = select(SystemLog).order_by(SystemLog.created_at.desc()).limit(limit)
        result = await session.execute(query)
        logs = result.scalars().all()
        for log in logs:
            print(f"[{log.created_at}] {log.level} | {log.source} | {log.message}")
            if log.log_metadata:
                print(f"  Metadata: {log.log_metadata}")


if __name__ == "__main__":
    asyncio.run(check_logs())

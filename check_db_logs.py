
import asyncio
from sqlalchemy import select
from app.database import AsyncSessionLocal
from app.models.system import SystemLog

async def check_logs():
    async with AsyncSessionLocal() as session:
        query = select(SystemLog).order_by(SystemLog.created_at.desc()).limit(20)
        result = await session.execute(query)
        logs = result.scalars().all()
        for log in logs:
            print(f"[{log.created_at}] {log.level} | {log.source} | {log.message}")
            if log.log_metadata:
                print(f"  Metadata: {log.log_metadata}")

if __name__ == "__main__":
    import os
    import sys
    sys.path.append(os.path.join(os.getcwd(), "backend"))
    asyncio.run(check_logs())

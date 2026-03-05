import asyncio
import sqlalchemy as sa
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.database import engine

async def check_constraint():
    async with engine.connect() as conn:
        res = await conn.execute(sa.text("SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'questions_status_check';"))
        print(res.scalar())

if __name__ == "__main__":
    asyncio.run(check_constraint())

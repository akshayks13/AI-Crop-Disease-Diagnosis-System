import asyncio
import os
import sys

from sqlalchemy import text

# Ensure backend package imports work when run from repo root or backend dir
BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if BACKEND_ROOT not in sys.path:
    sys.path.append(BACKEND_ROOT)

from app.database import engine


async def inspect_constraints():
    async with engine.connect() as conn:
        result = await conn.execute(text("""
            SELECT conname, pg_get_constraintdef(c.oid)
            FROM pg_constraint c
            JOIN pg_namespace n ON n.oid = c.connamespace
            WHERE conname LIKE 'questions_status_check%';
        """))
        for row in result:
            print(f"Constraint: {row[0]}")
            print(f"Definition: {row[1]}")


if __name__ == "__main__":
    asyncio.run(inspect_constraints())

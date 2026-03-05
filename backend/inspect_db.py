
import asyncio
from sqlalchemy import text
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

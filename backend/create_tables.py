import asyncio

# IMPORTANT: import Base and engine FIRST
from app.database import engine, Base

# Force import ALL models so they register with Base.metadata
import app.models.user
import app.models.diagnosis
import app.models.question
import app.models.community
import app.models.encyclopedia
import app.models.farm
import app.models.knowledge_base
import app.models.market
import app.models.pest
import app.models.system


async def create_tables():
    print("Registered tables:", list(Base.metadata.tables.keys()))

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    print("Tables created successfully!")


if __name__ == "__main__":
    asyncio.run(create_tables())
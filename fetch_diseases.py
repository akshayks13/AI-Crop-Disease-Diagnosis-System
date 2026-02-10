import sys
import os
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text

# Database URL (adjust if running outside docker but connecting to docker's mapped port)
# Assuming accessing from host to container mapped on 5432
DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/crop_diagnosis"

async def list_diseases():
    try:
        engine = create_async_engine(DATABASE_URL, echo=False)
        async with engine.connect() as conn:
            result = await conn.execute(text("SELECT id, name FROM disease_encyclopedia;"))
            rows = result.fetchall()
            
            print("\n--- Disease List ---\n")
            if not rows:
                print("No diseases found or database not seeded yet.")
            for row in rows:
                print(f"Name: {row.name}")
                print(f"UUID: {row.id}")
                print("-" * 20)
            print("\n--------------------\n")
    except Exception as e:
        print(f"Error connecting to database: {e}")
        print("Ensure 'crop_diagnosis_db' container is running and port 5432 is exposed.")

if __name__ == "__main__":
    # Check if asyncpg is installed, if not recommend it
    try:
        import asyncpg
    except ImportError:
        print("Please run: pip install asyncpg sqlalchemy")
        
    asyncio.run(list_diseases())

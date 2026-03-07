import asyncio
import sqlalchemy as sa
import sys
import os

# Add the backend directory to sys.path to allow importing app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import engine, init_db

async def verify():
    print("Running init_db()...")
    await init_db()
    
    async with engine.connect() as conn:
        # Check diagnoses table
        print("\nChecking 'diagnoses' table columns...")
        res = await conn.execute(sa.text("SELECT column_name FROM information_schema.columns WHERE table_name = 'diagnoses'"))
        columns = [r[0] for r in res.all()]
        for col in ['latitude', 'longitude', 'disease_id', 'dss_advisory']:
            if col in columns:
                print(f"  [OK] Column '{col}' exists.")
            else:
                print(f"  [FAIL] Column '{col}' is MISSING.")

        # Check system_logs table
        print("\nChecking 'system_logs' table columns...")
        res = await conn.execute(sa.text("SELECT column_name FROM information_schema.columns WHERE table_name = 'system_logs'"))
        columns = [r[0] for r in res.all()]
        if 'log_metadata' in columns:
            print("  [OK] Column 'log_metadata' exists.")
        else:
            print("  [FAIL] Column 'log_metadata' is MISSING.")

        # Check questions table constraint
        print("\nChecking 'questions' table constraints...")
        res = await conn.execute(sa.text(
            "SELECT count(*) FROM information_schema.table_constraints "
            "WHERE table_name = 'questions' AND constraint_name = 'questions_status_check'"
        ))
        count = res.scalar()
        if count > 0:
            print("  [OK] Constraint 'questions_status_check' exists.")
        else:
            print("  [FAIL] Constraint 'questions_status_check' is MISSING.")

if __name__ == "__main__":
    asyncio.run(verify())

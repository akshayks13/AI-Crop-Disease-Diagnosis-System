import sys
import os
import asyncio

# Add the project root/backend to the python path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from app.database import Base
from app.models import KnowledgeGuide

async def verify_models():
    print("Verifying models...")
    found = False
    for table_name, table in Base.metadata.tables.items():
        if table_name == 'knowledge_guides':
            print(f"Found table: {table_name}")
            found = True
            break
    
    if found:
        print("KnowledgeGuide model is correctly registered.")
    else:
        print("ERROR: KnowledgeGuide model is NOT registered in Base.metadata.")

if __name__ == "__main__":
    asyncio.run(verify_models())

import sys
import os

# Add the project root/backend to the python path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

try:
    print("Attempting to import from app.agronomy_intelligence.models...")
    from app.agronomy_intelligence.models import KnowledgeGuide
    print("Success!")
except Exception as e:
    print(f"Failed: {e}")
    import traceback
    traceback.print_exc()

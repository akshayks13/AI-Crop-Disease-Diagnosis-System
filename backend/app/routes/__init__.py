"""
Routes Package
"""
from app.routes.farmer import router as farmer_router
from app.routes.expert import router as expert_router
from app.routes.admin import router as admin_router

__all__ = [
    "farmer_router",
    "expert_router",
    "admin_router",
]

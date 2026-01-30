"""
Database Connection and Session Management
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from typing import AsyncGenerator
from sqlalchemy import select
import logging

from app.config import get_settings

settings = get_settings()

# Create async engine
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,
    future=True,
)

# Create async session factory
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""
    pass


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency to get database session.
    Yields an async session and ensures proper cleanup.
    """
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db() -> None:
    """Initialize database tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


# Setup logger
logger = logging.getLogger(__name__)

async def init_data() -> None:
    """Initialize default data (e.g. admin user, encyclopedia, market prices)."""
    # Import inside function to avoid circular import (User -> Base -> User)
    from app.models.user import User, UserRole, UserStatus
    from app.models.market import MarketPrice, TrendType
    from app.models.encyclopedia import CropInfo, DiseaseInfo
    from app.auth.jwt_handler import hash_password
    from datetime import datetime

    async with async_session_maker() as session:
        try:
            # Check if admin exists
            result = await session.execute(
                select(User).where(User.email == "admin@cropdiagnosis.com")
            )
            admin = result.scalar_one_or_none()
            
            if not admin:
                logger.info("Creating default admin user...")
                admin_user = User(
                    email="admin@cropdiagnosis.com",
                    password_hash=hash_password("admin123"),
                    full_name="System Admin",
                    role=UserRole.ADMIN,
                    status=UserStatus.ACTIVE
                )
                session.add(admin_user)
                await session.commit()
                logger.info("Default admin user created: admin@cropdiagnosis.com / admin123")
            else:
                logger.info("Admin user already exists.")
            
            # Seed encyclopedia data if empty
            crop_result = await session.execute(select(CropInfo).limit(1))
            if not crop_result.scalar_one_or_none():
                logger.info("Seeding encyclopedia data...")
                crops = [
                    CropInfo(name="Tomato", scientific_name="Solanum lycopersicum", season="Rabi & Kharif",
                             temp_min=20, temp_max=25, water_requirement="Medium", soil_type="Loamy, well-drained",
                             common_diseases=["Early Blight", "Late Blight", "Leaf Curl"],
                             growing_tips=["Stake plants for support", "Prune suckers regularly"]),
                    CropInfo(name="Potato", scientific_name="Solanum tuberosum", season="Rabi",
                             temp_min=15, temp_max=20, water_requirement="Medium", soil_type="Sandy loam",
                             common_diseases=["Late Blight", "Black Scurf"],
                             growing_tips=["Hill soil around plants", "Avoid overwatering"]),
                    CropInfo(name="Wheat", scientific_name="Triticum aestivum", season="Rabi",
                             temp_min=10, temp_max=25, water_requirement="Medium", soil_type="Clay loam",
                             common_diseases=["Rust", "Powdery Mildew"],
                             growing_tips=["Ensure proper irrigation at flowering stage"]),
                    CropInfo(name="Rice", scientific_name="Oryza sativa", season="Kharif",
                             temp_min=20, temp_max=35, water_requirement="High", soil_type="Clay, alluvial",
                             common_diseases=["Blast", "Bacterial Leaf Blight"],
                             growing_tips=["Maintain standing water in paddy fields"]),
                    CropInfo(name="Cotton", scientific_name="Gossypium", season="Kharif",
                             temp_min=20, temp_max=30, water_requirement="Medium", soil_type="Black cotton soil",
                             common_diseases=["Boll Rot", "Leaf Curl"],
                             growing_tips=["Control bollworm early in season"]),
                    CropInfo(name="Corn", scientific_name="Zea mays", season="Kharif",
                             temp_min=18, temp_max=27, water_requirement="Medium to High", soil_type="Loamy",
                             common_diseases=["Maize Streak Virus", "Rust"],
                             growing_tips=["Plant in blocks for better pollination"]),
                ]
                session.add_all(crops)
                
                diseases = [
                    DiseaseInfo(name="Early Blight", affected_crops=["Tomato", "Potato"],
                                description="Fungal disease causing dark spots with concentric rings on leaves.",
                                symptoms=["Dark brown spots", "Yellow halos", "Lower leaf infection first"],
                                causes="Fungus Alternaria solani, spreads in warm humid conditions",
                                chemical_treatment=["Mancozeb 75% WP", "Chlorothalonil"],
                                organic_treatment=["Neem oil spray", "Copper fungicides"],
                                prevention=["Crop rotation", "Remove infected debris", "Proper spacing"],
                                severity_level="moderate"),
                    DiseaseInfo(name="Late Blight", affected_crops=["Tomato", "Potato"],
                                description="Devastating disease causing rapid plant death in wet conditions.",
                                symptoms=["Water-soaked lesions", "White fuzzy growth", "Rapid browning"],
                                causes="Oomycete Phytophthora infestans",
                                chemical_treatment=["Metalaxyl", "Cymoxanil"],
                                organic_treatment=["Bordeaux mixture"],
                                prevention=["Use resistant varieties", "Good drainage", "Avoid overhead irrigation"],
                                severity_level="severe",
                                safety_warnings=["Apply fungicide before rain expected"]),
                    DiseaseInfo(name="Powdery Mildew", affected_crops=["Wheat", "Cucumber", "Grapes"],
                                description="White powdery fungal growth on leaves and stems.",
                                symptoms=["White powder on leaves", "Yellowing", "Stunted growth"],
                                chemical_treatment=["Sulphur", "Triadimefon"],
                                organic_treatment=["Milk spray", "Baking soda solution"],
                                prevention=["Good air circulation", "Avoid overcrowding"],
                                severity_level="mild"),
                ]
                session.add_all(diseases)
                await session.commit()
                logger.info("Encyclopedia data seeded.")
            
            # Seed market prices if empty
            market_result = await session.execute(select(MarketPrice).limit(1))
            if not market_result.scalar_one_or_none():
                logger.info("Seeding market price data...")
                prices = [
                    MarketPrice(commodity="Tomato", price=2500, unit="Quintal", location="Kolar Mandi",
                                trend=TrendType.UP, change_percent=5.0),
                    MarketPrice(commodity="Potato", price=1800, unit="Quintal", location="Hassan Mandi",
                                trend=TrendType.DOWN, change_percent=-2.0),
                    MarketPrice(commodity="Onion", price=3200, unit="Quintal", location="Yeshwanthpur",
                                trend=TrendType.UP, change_percent=8.0),
                    MarketPrice(commodity="Green Chilli", price=4500, unit="Quintal", location="Chikkaballapur",
                                trend=TrendType.STABLE, change_percent=0.0),
                    MarketPrice(commodity="Wheat", price=2100, unit="Quintal", location="Belgaum",
                                trend=TrendType.UP, change_percent=1.0),
                    MarketPrice(commodity="Rice (Sona Masoori)", price=4800, unit="Quintal", location="Raichur",
                                trend=TrendType.DOWN, change_percent=-1.5),
                    MarketPrice(commodity="Cotton", price=6200, unit="Quintal", location="Haveri",
                                trend=TrendType.UP, change_percent=3.0),
                    MarketPrice(commodity="Maize", price=1950, unit="Quintal", location="Davangere",
                                trend=TrendType.STABLE, change_percent=0.0),
                    MarketPrice(commodity="Tur Dal", price=8500, unit="Quintal", location="Kalaburagi",
                                trend=TrendType.UP, change_percent=10.0),
                    MarketPrice(commodity="Groundnut", price=5600, unit="Quintal", location="Chitradurga",
                                trend=TrendType.DOWN, change_percent=-4.0),
                ]
                session.add_all(prices)
                await session.commit()
                logger.info("Market price data seeded.")
                
        except Exception as e:
            logger.error(f"Error initializing data: {e}")
            await session.rollback()

async def close_db() -> None:
    """Close database connections."""
    await engine.dispose()

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
    """Initialize default data by calling the seed module."""
    # Import seed module here to avoid circular imports
    from app.seed import seed_database
    from app.models.market import MarketPrice, TrendType
    from app.models.encyclopedia import CropInfo, DiseaseInfo
    
    async with async_session_maker() as session:
        try:
            # Run user and question seeding
            await seed_database(session)
            
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
            
            # Seed agronomy data if empty
            from app.agronomy.models import DiagnosticRule, TreatmentConstraint, SeasonalPattern
            
            rule_result = await session.execute(select(DiagnosticRule).limit(1))
            if not rule_result.scalar_one_or_none():
                logger.info("Seeding agronomy data...")
                
                # Get disease and crop IDs for references
                early_blight = await session.execute(select(DiseaseInfo).where(DiseaseInfo.name == "Early Blight"))
                early_blight = early_blight.scalar_one_or_none()
                
                late_blight = await session.execute(select(DiseaseInfo).where(DiseaseInfo.name == "Late Blight"))
                late_blight = late_blight.scalar_one_or_none()
                
                powdery_mildew = await session.execute(select(DiseaseInfo).where(DiseaseInfo.name == "Powdery Mildew"))
                powdery_mildew = powdery_mildew.scalar_one_or_none()
                
                tomato = await session.execute(select(CropInfo).where(CropInfo.name == "Tomato"))
                tomato = tomato.scalar_one_or_none()
                
                potato = await session.execute(select(CropInfo).where(CropInfo.name == "Potato"))
                potato = potato.scalar_one_or_none()
                
                wheat = await session.execute(select(CropInfo).where(CropInfo.name == "Wheat"))
                wheat = wheat.scalar_one_or_none()
                
                # Diagnostic Rules
                rules = []
                if early_blight:
                    rules.extend([
                        DiagnosticRule(
                            disease_id=early_blight.id,
                            rule_name="Warm Humid Conditions Favorable",
                            description="Early Blight thrives in warm (20-30°C) and humid (70%+) conditions",
                            conditions={"temp_min": 20, "temp_max": 30, "humidity_min": 70},
                            impact={"confidence_boost": 0.1, "confidence_penalty": -0.15},
                            priority=1.0,
                            is_active=True
                        ),
                        DiagnosticRule(
                            disease_id=early_blight.id,
                            rule_name="Kharif Season Prevalence",
                            description="More common during Kharif (monsoon) season",
                            conditions={"season": "Kharif"},
                            impact={"confidence_boost": 0.05, "confidence_penalty": -0.05},
                            priority=0.8,
                            is_active=True
                        ),
                    ])
                
                if late_blight:
                    rules.extend([
                        DiagnosticRule(
                            disease_id=late_blight.id,
                            rule_name="Cool Wet Conditions Required",
                            description="Late Blight requires cool temps (10-25°C) and high moisture",
                            conditions={"temp_min": 10, "temp_max": 25, "humidity_min": 80},
                            impact={"confidence_boost": 0.15, "confidence_penalty": -0.2},
                            priority=1.2,
                            is_active=True
                        ),
                        DiagnosticRule(
                            disease_id=late_blight.id,
                            rule_name="Rainy Weather Critical",
                            description="Spreads rapidly during rainy periods",
                            conditions={"season": "Kharif"},
                            impact={"confidence_boost": 0.1, "confidence_penalty": -0.1},
                            priority=1.0,
                            is_active=True
                        ),
                    ])
                
                if powdery_mildew:
                    rules.append(
                        DiagnosticRule(
                            disease_id=powdery_mildew.id,
                            rule_name="Warm Dry Conditions",
                            description="Powdery Mildew prefers warm (20-30°C) and dry (<60% humidity) conditions",
                            conditions={"temp_min": 20, "temp_max": 30, "humidity_max": 60},
                            impact={"confidence_boost": 0.1, "confidence_penalty": -0.1},
                            priority=0.9,
                            is_active=True
                        )
                    )
                
                session.add_all(rules)
                
                # Treatment Constraints
                constraints = [
                    TreatmentConstraint(
                        treatment_name="Mancozeb 75% WP",
                        treatment_type="chemical",
                        constraint_description="Avoid spraying during rain or within 3 hours of expected rainfall",
                        restricted_conditions={"weather": "rainy"},
                        enforcement_level="warn",
                        risk_level="medium"
                    ),
                    TreatmentConstraint(
                        treatment_name="Copper Fungicide",
                        treatment_type="chemical",
                        constraint_description="Do NOT apply during rainy weather - rain will wash away and contaminate soil",
                        restricted_conditions={"weather": "rainy"},
                        enforcement_level="block",
                        risk_level="high"
                    ),
                    TreatmentConstraint(
                        treatment_name="Metalaxyl",
                        treatment_type="chemical",
                        constraint_description="Not recommended for sandy soils due to leaching risk",
                        restricted_conditions={"soil_type": "sandy"},
                        enforcement_level="warn",
                        risk_level="medium"
                    ),
                    TreatmentConstraint(
                        treatment_name="Neem Oil",
                        treatment_type="organic",
                        constraint_description="Apply in early morning or evening to avoid leaf burn in hot sun",
                        restricted_conditions={"temperature_max": 35},
                        enforcement_level="warn",
                        risk_level="low"
                    ),
                    TreatmentConstraint(
                        treatment_name="Sulphur",
                        treatment_type="chemical",
                        constraint_description="Do not apply when temperature exceeds 32°C - risk of phytotoxicity",
                        restricted_conditions={"temperature_max": 32},
                        enforcement_level="warn",
                        risk_level="medium"
                    ),
                ]
                session.add_all(constraints)
                
                # Seasonal Patterns
                patterns = []
                if tomato and early_blight:
                    patterns.append(
                        SeasonalPattern(
                            disease_id=early_blight.id,
                            crop_id=tomato.id,
                            region="Karnataka",
                            season="Kharif",
                            likelihood_score=0.75
                        )
                    )
                
                if tomato and late_blight:
                    patterns.extend([
                        SeasonalPattern(
                            disease_id=late_blight.id,
                            crop_id=tomato.id,
                            region="Karnataka",
                            season="Kharif",
                            likelihood_score=0.85
                        ),
                        SeasonalPattern(
                            disease_id=late_blight.id,
                            crop_id=tomato.id,
                            region=None,  # General pattern
                            season="Kharif",
                            likelihood_score=0.70
                        ),
                    ])
                
                if potato and late_blight:
                    patterns.extend([
                        SeasonalPattern(
                            disease_id=late_blight.id,
                            crop_id=potato.id,
                            region=None,
                            season="Rabi",
                            likelihood_score=0.80
                        ),
                        SeasonalPattern(
                            disease_id=late_blight.id,
                            crop_id=potato.id,
                            region="Karnataka",
                            season="Rabi",
                            likelihood_score=0.75
                        ),
                    ])
                
                if wheat and powdery_mildew:
                    patterns.append(
                        SeasonalPattern(
                            disease_id=powdery_mildew.id,
                            crop_id=wheat.id,
                            region=None,
                            season="Rabi",
                            likelihood_score=0.60
                        )
                    )
                
                session.add_all(patterns)
                await session.commit()
                logger.info("Agronomy data seeded successfully.")
                
        except Exception as e:
            logger.error(f"Error initializing data: {e}")
            await session.rollback()

async def close_db() -> None:
    """Close database connections."""
    await engine.dispose()

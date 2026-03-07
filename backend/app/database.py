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


def _normalize_database_url(database_url: str) -> str:
    """Normalize database URL for SQLAlchemy async engine compatibility."""
    if database_url.startswith("postgres://"):
        return database_url.replace("postgres://", "postgresql+asyncpg://", 1)
    if database_url.startswith("postgresql://"):
        return database_url.replace("postgresql://", "postgresql+asyncpg://", 1)
    return database_url

# Create async engine
engine = create_async_engine(
    _normalize_database_url(settings.database_url),
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
    import sqlalchemy as sa
    
    # Core table creation
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Migration helper: runs a single SQL statement in its own transaction
    async def run_migration(sql_text: str, success_msg: str):
        async with engine.begin() as conn:
            try:
                await conn.execute(sa.text(sql_text))
                logger.info(success_msg)
            except Exception:
                # Column might already exist, or other non-critical error
                pass

    # Each migration step in its own transaction
    await run_migration(
        "ALTER TABLE diagnoses ADD COLUMN disease_id VARCHAR(255)",
        "Added disease_id column to diagnoses table"
    )
    await run_migration(
        "ALTER TABLE diagnoses ADD COLUMN dss_advisory JSON",
        "Added dss_advisory column to diagnoses table"
    )

    await run_migration(
        "ALTER TABLE diagnoses ADD COLUMN latitude FLOAT",
        "Added latitude column to diagnoses table"
    )

    await run_migration(
        "ALTER TABLE diagnoses ADD COLUMN longitude FLOAT",
        "Added longitude column to diagnoses table"
    )

    await run_migration(
        "ALTER TABLE system_logs ADD COLUMN log_metadata JSON",
        "Added log_metadata column to system_logs table"
    )

    # Update questions status constraint
    async with engine.begin() as conn:
        try:
            # First try to drop the existing constraint if it exists
            await conn.execute(sa.text(
                "ALTER TABLE questions DROP CONSTRAINT IF EXISTS questions_status_check"
            ))
            # Add the new constraint with all enum values
            await conn.execute(sa.text(
                "ALTER TABLE questions ADD CONSTRAINT questions_status_check "
                "CHECK (status IN ('OPEN', 'ANSWERED', 'CLOSED'))"
            ))
            logger.info("Updated questions_status_check constraint")
        except Exception as e:
            logger.warning(f"Could not update questions status constraint: {e}")


# Setup logger
logger = logging.getLogger(__name__)

async def init_data() -> None:
    """Initialize default data by calling the seed module."""
    # Import seed module here to avoid circular imports
    from app.seed import seed_database
    from app.models.market import MarketPrice, TrendType
    from app.models.encyclopedia import CropInfo, DiseaseInfo
    from app.models.pest import PestInfo
    
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

            # Seed pest data if empty
            pest_result = await session.execute(select(PestInfo).limit(1))
            if not pest_result.scalar_one_or_none():
                logger.info("Seeding pest encyclopedia data...")
                pests = [
                    PestInfo(
                        name="Aphids", scientific_name="Aphididae",
                        affected_crops=["Tomato", "Cotton", "Wheat", "Mustard", "Potato"],
                        description="Tiny soft-bodied insects that cluster on new growth and undersides of leaves, sucking plant sap and transmitting viruses.",
                        symptoms=["Curled or distorted leaves", "Sticky honeydew on leaves", "Yellowing", "Stunted growth", "Sooty mold growth"],
                        appearance="Tiny (1-3mm), pear-shaped, green/black/yellow, often in clusters",
                        damage_type="Sucking",
                        life_cycle="Reproduce rapidly; 20-30 generations per year. Wingless in summer, winged forms appear when overcrowded.",
                        control_methods=["Monitor regularly", "Use yellow sticky traps", "Encourage natural predators like ladybugs"],
                        organic_control=["Neem oil spray (5ml/L)", "Soap water spray", "Release ladybird beetles"],
                        chemical_control=["Imidacloprid 17.8 SL @ 0.5ml/L", "Dimethoate 30 EC @ 2ml/L"],
                        prevention=["Avoid excessive nitrogen fertilizer", "Intercrop with coriander or marigold", "Remove weeds"],
                        severity_level="moderate"
                    ),
                    PestInfo(
                        name="Whitefly", scientific_name="Bemisia tabaci",
                        affected_crops=["Tomato", "Cotton", "Chilli", "Brinjal", "Cucumber"],
                        description="Small white-winged insects that feed on plant sap and are major vectors of viral diseases like Tomato Yellow Leaf Curl Virus.",
                        symptoms=["Yellowing leaves", "Sticky honeydew", "Sooty mold", "Wilting", "Virus symptoms (mosaic, curl)"],
                        appearance="2mm, white wings, found on leaf undersides",
                        damage_type="Sucking",
                        life_cycle="Egg to adult in 3-4 weeks. Multiple overlapping generations.",
                        control_methods=["Yellow sticky traps", "Reflective mulch to repel", "Remove heavily infested leaves"],
                        organic_control=["Neem oil 2%", "Verticillium lecanii fungal spray", "Soap solution"],
                        chemical_control=["Thiamethoxam 25 WG @ 0.3g/L", "Spiromesifen 22.9 SC @ 1ml/L"],
                        prevention=["Use virus-resistant varieties", "Install insect-proof nets in nursery", "Avoid planting near infected fields"],
                        severity_level="severe"
                    ),
                    PestInfo(
                        name="Stem Borer", scientific_name="Chilo partellus",
                        affected_crops=["Rice", "Corn", "Sorghum", "Sugarcane"],
                        description="Caterpillar that bores into stems causing 'dead heart' in young plants and 'white ear' in flowering stage.",
                        symptoms=["Dead heart (central shoot dies)", "White ear (empty panicle)", "Bore holes in stem", "Frass (excreta) in stem"],
                        appearance="Caterpillar: pale yellow with dark stripes; Adult: straw-colored moth",
                        damage_type="Boring",
                        life_cycle="Egg to adult in 35-45 days. 3-4 generations per year.",
                        control_methods=["Remove and destroy egg masses", "Light traps for adult moths", "Pheromone traps"],
                        organic_control=["Trichogramma egg parasitoid release", "Bacillus thuringiensis (Bt) spray"],
                        chemical_control=["Chlorpyrifos 20 EC @ 2.5ml/L", "Carbofuran 3G granules in whorl"],
                        prevention=["Timely planting", "Balanced fertilization", "Destroy crop residues after harvest"],
                        severity_level="severe"
                    ),
                    PestInfo(
                        name="Thrips", scientific_name="Thrips tabaci",
                        affected_crops=["Onion", "Chilli", "Cotton", "Groundnut", "Tomato"],
                        description="Tiny slender insects that rasp leaf surfaces and suck cell contents, causing silvery streaks and transmitting viruses.",
                        symptoms=["Silvery streaks on leaves", "Leaf curl", "Distorted flowers", "Premature fruit drop", "Scarring on onion bulbs"],
                        appearance="1-2mm, slender, yellowish-brown to dark brown",
                        damage_type="Rasping-sucking",
                        life_cycle="Egg to adult in 2-3 weeks. Multiple generations.",
                        control_methods=["Blue sticky traps", "Avoid water stress", "Reflective mulch"],
                        organic_control=["Neem seed kernel extract 5%", "Spinosad 45 SC @ 0.3ml/L"],
                        chemical_control=["Fipronil 5 SC @ 1.5ml/L", "Imidacloprid 17.8 SL @ 0.5ml/L"],
                        prevention=["Avoid planting near infected fields", "Crop rotation", "Remove weeds"],
                        severity_level="moderate"
                    ),
                    PestInfo(
                        name="Mealybug", scientific_name="Phenacoccus solenopsis",
                        affected_crops=["Cotton", "Tomato", "Brinjal", "Papaya", "Grapes"],
                        description="White waxy-coated insects that cluster on stems and leaf joints, sucking sap and excreting honeydew.",
                        symptoms=["White cottony masses on stems/joints", "Yellowing and wilting", "Sooty mold", "Stunted growth"],
                        appearance="3-5mm, oval, covered in white waxy powder",
                        damage_type="Sucking",
                        life_cycle="Egg to adult in 30-40 days. Spread by ants, wind, and farm equipment.",
                        control_methods=["Control ants (which protect mealybugs)", "Prune heavily infested parts", "Avoid excess nitrogen"],
                        organic_control=["Neem oil 2%", "Beauveria bassiana spray", "Release Cryptolaemus beetles"],
                        chemical_control=["Profenofos 50 EC @ 2ml/L", "Buprofezin 25 SC @ 1ml/L"],
                        prevention=["Use certified pest-free planting material", "Quarantine new plants", "Regular field monitoring"],
                        severity_level="moderate"
                    ),
                    PestInfo(
                        name="Red Spider Mite", scientific_name="Tetranychus urticae",
                        affected_crops=["Tomato", "Brinjal", "Cucumber", "Beans", "Cotton"],
                        description="Tiny mites that feed on leaf undersides, causing bronzing and webbing. Severe in hot dry conditions.",
                        symptoms=["Tiny yellow/white dots on leaves", "Bronze or rusty discoloration", "Fine webbing on undersides", "Leaf drop"],
                        appearance="0.5mm, oval, red/orange/green, barely visible to naked eye",
                        damage_type="Piercing-sucking",
                        life_cycle="Egg to adult in 7-10 days in hot weather. Rapid population buildup.",
                        control_methods=["Maintain adequate soil moisture", "Avoid dusty conditions", "Spray water on undersides"],
                        organic_control=["Neem oil 2%", "Sulphur 80 WP @ 2g/L", "Predatory mite release"],
                        chemical_control=["Abamectin 1.8 EC @ 0.5ml/L", "Spiromesifen 22.9 SC @ 1ml/L"],
                        prevention=["Avoid water stress", "Avoid broad-spectrum insecticides that kill natural enemies", "Intercrop with repellent plants"],
                        severity_level="moderate"
                    ),
                    PestInfo(
                        name="American Bollworm", scientific_name="Helicoverpa armigera",
                        affected_crops=["Cotton", "Tomato", "Chickpea", "Sorghum", "Maize"],
                        description="Major polyphagous pest. Caterpillar bores into bolls, fruits, and pods causing severe yield loss.",
                        symptoms=["Circular holes in fruits/bolls", "Frass at entry point", "Premature fruit drop", "Damaged seeds in pods"],
                        appearance="Caterpillar: green/brown with pale stripes; Adult: yellowish-brown moth",
                        damage_type="Boring",
                        life_cycle="Egg to adult in 30-35 days. 5-6 generations per year.",
                        control_methods=["Pheromone traps (5/acre)", "Light traps", "Hand-pick egg masses"],
                        organic_control=["Bacillus thuringiensis (Bt) spray @ 2g/L", "Nuclear Polyhedrosis Virus (NPV) @ 250 LE/ha"],
                        chemical_control=["Emamectin benzoate 5 SG @ 0.4g/L", "Chlorantraniliprole 18.5 SC @ 0.3ml/L"],
                        prevention=["Use Bt cotton varieties", "Avoid late planting", "Destroy crop residues", "Intercrop with marigold"],
                        severity_level="severe"
                    ),
                    PestInfo(
                        name="Leaf Miner", scientific_name="Liriomyza trifolii",
                        affected_crops=["Tomato", "Potato", "Beans", "Pea", "Celery"],
                        description="Larvae tunnel between leaf surfaces creating visible winding mines, reducing photosynthesis.",
                        symptoms=["Winding white/grey trails (mines) on leaves", "Blotchy patches", "Premature leaf drop", "Reduced photosynthesis"],
                        appearance="Adult: tiny black-yellow fly (2mm); Larva: pale yellow maggot inside leaf",
                        damage_type="Mining",
                        life_cycle="Egg to adult in 2-3 weeks. Multiple overlapping generations.",
                        control_methods=["Yellow sticky traps", "Remove and destroy mined leaves", "Avoid broad-spectrum pesticides"],
                        organic_control=["Neem oil 2%", "Spinosad 45 SC @ 0.3ml/L", "Release Diglyphus parasitoids"],
                        chemical_control=["Abamectin 1.8 EC @ 0.5ml/L", "Cyromazine 75 WP @ 0.6g/L"],
                        prevention=["Use fine mesh nets in nursery", "Crop rotation", "Remove crop debris"],
                        severity_level="mild"
                    ),
                ]
                session.add_all(pests)
                await session.commit()
                logger.info("Pest encyclopedia data seeded.")
            
            # Seed market prices if empty
            market_result = await session.execute(select(MarketPrice).limit(1))
            if not market_result.scalar_one_or_none():
                logger.info("Seeding market price data...")
                prices = [
                    # Karnataka
                    MarketPrice(commodity="Tomato", price=2500, unit="Quintal", location="Kolar Mandi, Kolar, Karnataka",
                                trend=TrendType.UP, change_percent=5.0, min_price=2200, max_price=2800),
                    MarketPrice(commodity="Potato", price=1800, unit="Quintal", location="Hassan Mandi, Hassan, Karnataka",
                                trend=TrendType.DOWN, change_percent=-2.0, min_price=1600, max_price=2000),
                    MarketPrice(commodity="Onion", price=3200, unit="Quintal", location="Yeshwanthpur Mandi, Bengaluru, Karnataka",
                                trend=TrendType.UP, change_percent=8.0, min_price=2900, max_price=3500),
                    MarketPrice(commodity="Green Chilli", price=4500, unit="Quintal", location="Chikkaballapur Mandi, Chikkaballapur, Karnataka",
                                trend=TrendType.STABLE, change_percent=0.0, min_price=4200, max_price=4800),
                    MarketPrice(commodity="Wheat", price=2100, unit="Quintal", location="Belagavi Mandi, Belagavi, Karnataka",
                                trend=TrendType.UP, change_percent=1.0, min_price=2000, max_price=2200),
                    MarketPrice(commodity="Rice (Sona Masoori)", price=4800, unit="Quintal", location="Raichur Mandi, Raichur, Karnataka",
                                trend=TrendType.DOWN, change_percent=-1.5, min_price=4500, max_price=5000),
                    MarketPrice(commodity="Cotton", price=6200, unit="Quintal", location="Haveri Mandi, Haveri, Karnataka",
                                trend=TrendType.UP, change_percent=3.0, min_price=5900, max_price=6500),
                    MarketPrice(commodity="Maize", price=1950, unit="Quintal", location="Davangere Mandi, Davangere, Karnataka",
                                trend=TrendType.STABLE, change_percent=0.0, min_price=1800, max_price=2100),
                    MarketPrice(commodity="Tur Dal", price=8500, unit="Quintal", location="Kalaburagi Mandi, Kalaburagi, Karnataka",
                                trend=TrendType.UP, change_percent=10.0, min_price=8000, max_price=9000),
                    MarketPrice(commodity="Groundnut", price=5600, unit="Quintal", location="Chitradurga Mandi, Chitradurga, Karnataka",
                                trend=TrendType.DOWN, change_percent=-4.0, min_price=5200, max_price=6000),
                    MarketPrice(commodity="Banana", price=1200, unit="Quintal", location="Shimoga Mandi, Shimoga, Karnataka",
                                trend=TrendType.STABLE, change_percent=0.5, min_price=1100, max_price=1400),
                    MarketPrice(commodity="Coconut", price=1800, unit="Quintal", location="Tumkur Mandi, Tumkur, Karnataka",
                                trend=TrendType.UP, change_percent=4.0, min_price=1600, max_price=2000),
                    MarketPrice(commodity="Red Chilli", price=9500, unit="Quintal", location="Byadagi Mandi, Haveri, Karnataka",
                                trend=TrendType.UP, change_percent=6.0, min_price=9000, max_price=10000),
                    MarketPrice(commodity="Soybean", price=4200, unit="Quintal", location="Dharwad Mandi, Dharwad, Karnataka",
                                trend=TrendType.DOWN, change_percent=-2.5, min_price=3900, max_price=4500),
                    MarketPrice(commodity="Sugarcane", price=3500, unit="Quintal", location="Mandya Mandi, Mandya, Karnataka",
                                trend=TrendType.STABLE, change_percent=0.0, min_price=3200, max_price=3700),
                    # Maharashtra
                    MarketPrice(commodity="Onion", price=2900, unit="Quintal", location="Lasalgaon Mandi, Nashik, Maharashtra",
                                trend=TrendType.DOWN, change_percent=-3.0, min_price=2600, max_price=3200),
                    MarketPrice(commodity="Tomato", price=2200, unit="Quintal", location="Pune Mandi, Pune, Maharashtra",
                                trend=TrendType.STABLE, change_percent=0.0, min_price=2000, max_price=2500),
                    MarketPrice(commodity="Wheat", price=2250, unit="Quintal", location="Nagpur Mandi, Nagpur, Maharashtra",
                                trend=TrendType.UP, change_percent=1.5, min_price=2100, max_price=2400),
                    MarketPrice(commodity="Cotton", price=6500, unit="Quintal", location="Akola Mandi, Akola, Maharashtra",
                                trend=TrendType.UP, change_percent=2.0, min_price=6200, max_price=6800),
                    MarketPrice(commodity="Soybean", price=4400, unit="Quintal", location="Latur Mandi, Latur, Maharashtra",
                                trend=TrendType.UP, change_percent=3.5, min_price=4100, max_price=4700),
                    MarketPrice(commodity="Turmeric", price=12000, unit="Quintal", location="Sangli Mandi, Sangli, Maharashtra",
                                trend=TrendType.UP, change_percent=7.0, min_price=11000, max_price=13000),
                    MarketPrice(commodity="Grapes", price=5500, unit="Quintal", location="Nashik Mandi, Nashik, Maharashtra",
                                trend=TrendType.STABLE, change_percent=0.5, min_price=5000, max_price=6000),
                    # Andhra Pradesh & Telangana
                    MarketPrice(commodity="Red Chilli", price=10000, unit="Quintal", location="Guntur Mandi, Guntur, Andhra Pradesh",
                                trend=TrendType.UP, change_percent=8.0, min_price=9500, max_price=11000),
                    MarketPrice(commodity="Rice (BPT)", price=5200, unit="Quintal", location="Nellore Mandi, Nellore, Andhra Pradesh",
                                trend=TrendType.STABLE, change_percent=0.0, min_price=5000, max_price=5400),
                    MarketPrice(commodity="Maize", price=2100, unit="Quintal", location="Nizamabad Mandi, Nizamabad, Telangana",
                                trend=TrendType.UP, change_percent=2.0, min_price=1950, max_price=2250),
                    MarketPrice(commodity="Cotton", price=6800, unit="Quintal", location="Warangal Mandi, Warangal, Telangana",
                                trend=TrendType.DOWN, change_percent=-1.0, min_price=6500, max_price=7100),
                    # Tamil Nadu
                    MarketPrice(commodity="Tomato", price=3100, unit="Quintal", location="Koyambedu Mandi, Chennai, Tamil Nadu",
                                trend=TrendType.UP, change_percent=6.0, min_price=2800, max_price=3400),
                    MarketPrice(commodity="Banana", price=1400, unit="Quintal", location="Trichy Mandi, Trichy, Tamil Nadu",
                                trend=TrendType.STABLE, change_percent=1.0, min_price=1200, max_price=1600),
                    MarketPrice(commodity="Coconut", price=2000, unit="Quintal", location="Coimbatore Mandi, Coimbatore, Tamil Nadu",
                                trend=TrendType.UP, change_percent=3.0, min_price=1800, max_price=2200),
                    MarketPrice(commodity="Groundnut", price=6000, unit="Quintal", location="Vellore Mandi, Vellore, Tamil Nadu",
                                trend=TrendType.UP, change_percent=2.0, min_price=5700, max_price=6300),
                    # Uttar Pradesh & Punjab
                    MarketPrice(commodity="Wheat", price=2300, unit="Quintal", location="Muzaffarnagar Mandi, Muzaffarnagar, Uttar Pradesh",
                                trend=TrendType.UP, change_percent=2.0, min_price=2150, max_price=2450),
                    MarketPrice(commodity="Potato", price=1600, unit="Quintal", location="Agra Mandi, Agra, Uttar Pradesh",
                                trend=TrendType.DOWN, change_percent=-5.0, min_price=1400, max_price=1800),
                    MarketPrice(commodity="Rice (Basmati)", price=7500, unit="Quintal", location="Amritsar Mandi, Amritsar, Punjab",
                                trend=TrendType.STABLE, change_percent=0.0, min_price=7000, max_price=8000),
                    MarketPrice(commodity="Maize", price=1900, unit="Quintal", location="Ludhiana Mandi, Ludhiana, Punjab",
                                trend=TrendType.DOWN, change_percent=-1.5, min_price=1750, max_price=2050),
                    # Rajasthan & Gujarat
                    MarketPrice(commodity="Jowar", price=2800, unit="Quintal", location="Jaipur Mandi, Jaipur, Rajasthan",
                                trend=TrendType.UP, change_percent=3.0, min_price=2600, max_price=3000),
                    MarketPrice(commodity="Bajra", price=1750, unit="Quintal", location="Bikaner Mandi, Bikaner, Rajasthan",
                                trend=TrendType.STABLE, change_percent=0.0, min_price=1600, max_price=1900),
                    MarketPrice(commodity="Castor Seed", price=5800, unit="Quintal", location="Unjha Mandi, Mehsana, Gujarat",
                                trend=TrendType.UP, change_percent=5.0, min_price=5500, max_price=6200),
                    MarketPrice(commodity="Cumin (Jeera)", price=45000, unit="Quintal", location="Unjha Mandi, Mehsana, Gujarat",
                                trend=TrendType.DOWN, change_percent=-8.0, min_price=42000, max_price=48000),
                    MarketPrice(commodity="Cotton", price=6400, unit="Quintal", location="Rajkot Mandi, Rajkot, Gujarat",
                                trend=TrendType.STABLE, change_percent=0.5, min_price=6100, max_price=6700),
                    MarketPrice(commodity="Garlic", price=8000, unit="Quintal", location="Deesa Mandi, Banaskantha, Gujarat",
                                trend=TrendType.UP, change_percent=12.0, min_price=7500, max_price=9000),
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

"""
Database Seed Data
Creates sample users, questions, and other test data for development.
"""
import logging
from datetime import datetime, timedelta
import random

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, UserRole, UserStatus
from app.models.question import Question, QuestionStatus, Answer
from app.models.market import MarketPrice, TrendType
from app.auth.jwt_handler import hash_password

logger = logging.getLogger(__name__)


async def seed_database(session: AsyncSession) -> None:
    """Seed sample data for development/testing."""
    try:
        print("🌱 Starting database seeding...")
        await seed_users(session)
        await seed_questions(session)
        await seed_market_prices(session)
        print("✅ Database seeding completed successfully!")
        logger.info("Database seeding completed.")
    except Exception as e:
        print(f"❌ Error during seeding: {e}")
        logger.error(f"Error during seeding: {e}")
        raise


async def seed_users(session: AsyncSession) -> None:
    """Seed sample users (admin, farmers, experts)."""
    
    # Check if admin exists
    print("   Checking for existing admin user...")
    result = await session.execute(
        select(User).where(User.email == "admin@cropdiagnosis.com")
    )
    if result.scalar_one_or_none():
        print("   ⏭️  Users already seeded, skipping...")
        logger.info("Users already seeded, skipping...")
        return
    
    print("   Creating new users...")
    
    users = [
        # Admin
        User(
            email="admin@cropdiagnosis.com",
            password_hash=hash_password("admin123"),
            full_name="System Admin",
            phone="+91-9999999999",
            role=UserRole.ADMIN,
            status=UserStatus.ACTIVE,
            is_verified=True,
        ),
        # Farmers
        User(
            email="farmer1@example.com",
            password_hash=hash_password("farmer123"),
            full_name="Raju Kumar",
            phone="+91-9876543210",
            role=UserRole.FARMER,
            status=UserStatus.ACTIVE,
            location="Karnataka, India",
            is_verified=True,
        ),
        User(
            email="farmer2@example.com",
            password_hash=hash_password("farmer123"),
            full_name="Lakshmi Devi",
            phone="+91-9876543211",
            role=UserRole.FARMER,
            status=UserStatus.ACTIVE,
            location="Tamil Nadu, India",
            is_verified=True,
        ),
        # Experts
        User(
            email="expert1@example.com",
            password_hash=hash_password("expert123"),
            full_name="Dr. Anil Sharma",
            phone="+91-9988776655",
            role=UserRole.EXPERT,
            status=UserStatus.ACTIVE,
            qualification="PhD in Plant Pathology",
            expertise_domain="Tomato & Potato Diseases",
            experience_years=15,
            is_verified=True,
        ),
        User(
            email="expert2@example.com",
            password_hash=hash_password("expert123"),
            full_name="Dr. Priya Patel",
            phone="+91-9988776656",
            role=UserRole.EXPERT,
            status=UserStatus.PENDING,  # Pending approval
            qualification="MSc Agriculture",
            expertise_domain="Rice & Wheat Diseases",
            experience_years=8,
            is_verified=True,
        ),
    ]
    
    session.add_all(users)
    await session.commit()
    print(f"   ✅ Seeded {len(users)} users.")
    logger.info(f"Seeded {len(users)} users.")


async def seed_questions(session: AsyncSession) -> None:
    """Seed sample questions and answers."""
    
    # Check if questions exist
    result = await session.execute(select(Question).limit(1))
    if result.scalar_one_or_none():
        logger.info("Questions already seeded, skipping...")
        return
    
    # Get farmer and expert IDs
    farmer_result = await session.execute(
        select(User).where(User.email == "farmer1@example.com")
    )
    farmer = farmer_result.scalar_one_or_none()
    
    expert_result = await session.execute(
        select(User).where(User.email == "expert1@example.com")
    )
    expert = expert_result.scalar_one_or_none()
    
    if not farmer or not expert:
        logger.warning("Cannot seed questions: farmers/experts not found")
        return
    
    # Sample questions
    questions = [
        Question(
            farmer_id=farmer.id,
            question_text="My tomato plants have dark spots on the leaves with yellow rings around them. What disease is this and how do I treat it?",
            status=QuestionStatus.ANSWERED,
            created_at=datetime.utcnow() - timedelta(days=5),
        ),
        Question(
            farmer_id=farmer.id,
            question_text="The leaves on my potato plants are turning brown and wilting rapidly. Is this late blight? What should I do immediately?",
            status=QuestionStatus.OPEN,
            created_at=datetime.utcnow() - timedelta(days=2),
        ),
        Question(
            farmer_id=farmer.id,
            question_text="What is the best organic treatment for powdery mildew on my wheat crop?",
            status=QuestionStatus.OPEN,
            created_at=datetime.utcnow() - timedelta(hours=12),
        ),
    ]
    
    session.add_all(questions)
    await session.flush()
    
    # Add answer to the first (resolved) question
    answer = Answer(
        question_id=questions[0].id,
        expert_id=expert.id,
        answer_text="""Based on your description, this sounds like **Early Blight** caused by the fungus *Alternaria solani*.

**Immediate Treatment:**
1. Remove and destroy infected leaves
2. Apply Mancozeb 75% WP (2.5g/L of water) spray
3. Repeat every 7-10 days

**Organic Alternative:**
- Neem oil spray (5ml/L water)
- Copper fungicide

**Prevention:**
- Ensure proper plant spacing for air circulation
- Water at the base, not on leaves
- Practice crop rotation

Your plants should recover within 2-3 weeks with proper treatment.""",
        rating=5,
        created_at=datetime.utcnow() - timedelta(days=4),
    )
    
    session.add(answer)
    await session.commit()


async def seed_market_prices(session: AsyncSession) -> None:
    """Seed sample market price data."""
    
    # Check if market prices already exist
    print("   Checking for existing market prices...")
    result = await session.execute(select(MarketPrice).limit(1))
    if result.scalar_one_or_none():
        print("   ⏭️  Market prices already seeded, skipping...")
        logger.info("Market prices already seeded, skipping...")
        return
    
    print("   Creating market price entries...")
    
    # Sample market prices for various commodities across Karnataka and neighboring states
    market_prices = [
        MarketPrice(
            commodity="Tomato",
            price=2800.0,
            unit="Quintal",
            location="Kolar, Bangalore Rural, Karnataka",
            trend=TrendType.UP,
            change_percent=5.2,
            min_price=2600.0,
            max_price=3000.0,
            arrival_qty=150.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Potato",
            price=1500.0,
            unit="Quintal",
            location="Hassan, Hassan, Karnataka",
            trend=TrendType.DOWN,
            change_percent=-2.1,
            min_price=1400.0,
            max_price=1600.0,
            arrival_qty=200.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Onion",
            price=3200.0,
            unit="Quintal",
            location="Nashik, Nashik, Maharashtra",
            trend=TrendType.UP,
            change_percent=8.5,
            min_price=3000.0,
            max_price=3500.0,
            arrival_qty=500.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Rice",
            price=2100.0,
            unit="Quintal",
            location="Mandya, Mandya, Karnataka",
            trend=TrendType.STABLE,
            change_percent=0.5,
            min_price=2000.0,
            max_price=2200.0,
            arrival_qty=800.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Wheat",
            price=2400.0,
            unit="Quintal",
            location="Dharwad, Dharwad, Karnataka",
            trend=TrendType.UP,
            change_percent=3.2,
            min_price=2300.0,
            max_price=2500.0,
            arrival_qty=350.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Cotton",
            price=6800.0,
            unit="Quintal",
            location="Raichur, Raichur, Karnataka",
            trend=TrendType.STABLE,
            change_percent=0.0,
            min_price=6500.0,
            max_price=7000.0,
            arrival_qty=120.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Maize",
            price=1800.0,
            unit="Quintal",
            location="Davangere, Davangere, Karnataka",
            trend=TrendType.UP,
            change_percent=4.1,
            min_price=1700.0,
            max_price=1900.0,
            arrival_qty=450.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Green Chilli",
            price=4500.0,
            unit="Quintal",
            location="Guntur, Guntur, Andhra Pradesh",
            trend=TrendType.UP,
            change_percent=12.5,
            min_price=4000.0,
            max_price=5000.0,
            arrival_qty=80.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Groundnut",
            price=5200.0,
            unit="Quintal",
            location="Bellary, Bellary, Karnataka",
            trend=TrendType.DOWN,
            change_percent=-1.5,
            min_price=5000.0,
            max_price=5400.0,
            arrival_qty=220.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Tur Dal",
            price=7500.0,
            unit="Quintal",
            location="Gulbarga, Gulbarga, Karnataka",
            trend=TrendType.STABLE,
            change_percent=1.0,
            min_price=7200.0,
            max_price=7800.0,
            arrival_qty=180.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Cabbage",
            price=1200.0,
            unit="Quintal",
            location="Ooty, Nilgiris, Tamil Nadu",
            trend=TrendType.DOWN,
            change_percent=-3.2,
            min_price=1100.0,
            max_price=1300.0,
            arrival_qty=300.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Carrot",
            price=1800.0,
            unit="Quintal",
            location="Bangalore, Bangalore Urban, Karnataka",
            trend=TrendType.STABLE,
            change_percent=0.0,
            min_price=1700.0,
            max_price=1900.0,
            arrival_qty=150.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Cauliflower",
            price=1600.0,
            unit="Quintal",
            location="Mysore, Mysore, Karnataka",
            trend=TrendType.UP,
            change_percent=6.5,
            min_price=1500.0,
            max_price=1700.0,
            arrival_qty=200.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Beans",
            price=3500.0,
            unit="Quintal",
            location="Chikmagalur, Chikmagalur, Karnataka",
            trend=TrendType.UP,
            change_percent=9.2,
            min_price=3200.0,
            max_price=3800.0,
            arrival_qty=100.0,
            recorded_at=datetime.utcnow(),
        ),
        MarketPrice(
            commodity="Brinjal",
            price=2200.0,
            unit="Quintal",
            location="Hubli, Dharwad, Karnataka",
            trend=TrendType.STABLE,
            change_percent=-0.5,
            min_price=2100.0,
            max_price=2300.0,
            arrival_qty=180.0,
            recorded_at=datetime.utcnow(),
        ),
    ]
    
    session.add_all(market_prices)
    await session.commit()
    print(f"   ✅ Seeded {len(market_prices)} market price entries.")
    logger.info(f"Seeded {len(market_prices)} market price entries.")


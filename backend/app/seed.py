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
from app.auth.jwt_handler import hash_password

logger = logging.getLogger(__name__)


async def seed_database(session: AsyncSession) -> None:
    """Seed sample data for development/testing."""
    try:
        print("🌱 Starting database seeding...")
        await seed_users(session)
        await seed_questions(session)
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
            status=QuestionStatus.RESOLVED,
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
    logger.info(f"Seeded {len(questions)} questions with answers.")

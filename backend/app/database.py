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
    """Initialize default data (e.g. admin user)."""
    # Import inside function to avoid circular import (User -> Base -> User)
    from app.models.user import User, UserRole, UserStatus
    from app.auth.jwt_handler import hash_password

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
        except Exception as e:
            logger.error(f"Error initializing data: {e}")
            await session.rollback()

async def close_db() -> None:
    """Close database connections."""
    await engine.dispose()

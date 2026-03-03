"""
Test Configuration and Fixtures
"""

import os
os.environ["ENVIRONMENT"] = "test"

import uuid
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.pool import NullPool

from app.main import app
from app.database import Base, get_db
from app.models import User, UserRole, UserStatus
from app.auth.jwt_handler import hash_password, create_access_token


TEST_DATABASE_URL = "postgresql+asyncpg://postgres:12345@localhost:5433/crop_diagnosis_test"

engine = create_async_engine(
    TEST_DATABASE_URL,
    echo=False,
    poolclass=NullPool
)

TestingSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False
)


# ✅ IMPORTANT: name must be test_db
@pytest_asyncio.fixture(scope="function")
async def test_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)

    async with TestingSessionLocal() as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def client(test_db):

    async def override_get_db():
        async with TestingSessionLocal() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest_asyncio.fixture(scope="function")
async def test_user(test_db):
    user = User(
        id=uuid.uuid4(),
        email="testfarmer@example.com",
        password_hash=hash_password("password123"),
        full_name="Test Farmer",
        role=UserRole.FARMER,
        status=UserStatus.ACTIVE,
        is_verified=True,
    )
    test_db.add(user)
    await test_db.commit()
    await test_db.refresh(user)
    return user


@pytest_asyncio.fixture(scope="function")
async def auth_token(test_user):
    return create_access_token({"sub": str(test_user.id)})


@pytest_asyncio.fixture(scope="function")
async def auth_client(client, auth_token):
    client.headers["Authorization"] = f"Bearer {auth_token}"
    return client
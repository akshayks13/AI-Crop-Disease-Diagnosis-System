"""
Test Configuration and Fixtures
"""
import asyncio
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from app.main import app
from app.database import Base, get_db
from app.models import User, UserRole, UserStatus
from app.auth.jwt_handler import hash_password, create_access_token

# Test database URL (in-memory SQLite for tests)
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for pytest-asyncio."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="function")
async def test_db():
    """Create test database and session."""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    session_maker = async_sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with session_maker() as session:
        yield session
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()


@pytest_asyncio.fixture(scope="function")
async def test_user(test_db):
    """Create a test farmer user."""
    user = User(
        email="testfarmer@example.com",
        password_hash=hash_password("password123"),
        full_name="Test Farmer",
        role=UserRole.FARMER,
        status=UserStatus.ACTIVE,
    )
    test_db.add(user)
    await test_db.commit()
    await test_db.refresh(user)
    return user


@pytest_asyncio.fixture(scope="function")
async def test_expert(test_db):
    """Create a test expert user."""
    user = User(
        email="testexpert@example.com",
        password_hash=hash_password("password123"),
        full_name="Test Expert",
        role=UserRole.EXPERT,
        status=UserStatus.ACTIVE,
    )
    test_db.add(user)
    await test_db.commit()
    await test_db.refresh(user)
    return user


@pytest_asyncio.fixture(scope="function")
async def auth_token(test_user):
    """Generate auth token for test user."""
    token = create_access_token({"sub": str(test_user.id)})
    return token


@pytest_asyncio.fixture(scope="function")
async def client(test_db):
    """Create test client with overridden DB dependency."""
    async def override_get_db():
        yield test_db
    
    app.dependency_overrides[get_db] = override_get_db
    
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    
    app.dependency_overrides.clear()


@pytest_asyncio.fixture(scope="function")
async def auth_client(client, auth_token):
    """Create authenticated test client."""
    client.headers["Authorization"] = f"Bearer {auth_token}"
    return client

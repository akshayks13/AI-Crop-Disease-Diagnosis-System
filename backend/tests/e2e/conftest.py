import pytest
import uuid
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.main import app
from app.database import get_db
from app.models.user import User, UserRole, UserStatus
from app.auth.jwt_handler import hash_password, create_access_token
from datetime import datetime

# ----------------------------
# Client with DB override
# ----------------------------

@pytest.fixture
async def client(test_db: AsyncSession):
    async def override_get_db():
        yield test_db

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()


# ----------------------------
# REGISTER + VERIFY + LOGIN
# ----------------------------

@pytest.fixture
async def register_and_login_farmer(client: AsyncClient, test_db: AsyncSession):

    register_data = {
        "email": "e2e_farmer@example.com",
        "password": "farmer123",
        "full_name": "E2E Farmer",
        "role": "FARMER"
    }

    # Register
    await client.post("/auth/register", json=register_data)

    # Fetch from SAME DB session
    result = await test_db.execute(
        select(User).where(User.email == "e2e_farmer@example.com")
    )
    user = result.scalar_one()

    otp = user.otp_code

    # Verify
    response = await client.post(
        "/auth/verify",
        json={"email": user.email, "otp": otp},
    )

    access_token = response.json()["access_token"]

    return {
        "Authorization": f"Bearer {access_token}"
    }

#Expert 
@pytest_asyncio.fixture
async def register_and_login_expert(client, test_db):
    """
    Creates and logs in an expert user for E2E testing.
    Returns authorization headers.
    """

    email = "e2e_expert@example.com"
    password = "Password123!"

    # Create expert user directly in DB
    expert = User(
        id=uuid.uuid4(),
        email=email,
        password_hash=hash_password(password),
        full_name="E2E Expert",
        role=UserRole.EXPERT,
        status=UserStatus.ACTIVE,
        is_verified=True,
    )

    test_db.add(expert)
    await test_db.commit()

    # Login
    response = await client.post(
        "/auth/login",
        json={
            "email": email,
            "password": password
        }
    )

    assert response.status_code == 200

    token = response.json()["access_token"]

    return {
        "Authorization": f"Bearer {token}"
    }

#Admin
@pytest_asyncio.fixture
async def register_and_login_admin(test_db):
    admin_user = User(
        id=uuid.uuid4(),
        email="admin_e2e@test.com",
        password_hash=hash_password("admin123"),
        full_name="E2E Admin",
        role=UserRole.ADMIN,
        status=UserStatus.ACTIVE,
        is_verified=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    test_db.add(admin_user)
    await test_db.commit()

    token = create_access_token({"sub": str(admin_user.id)})

    return {"Authorization": f"Bearer {token}"}
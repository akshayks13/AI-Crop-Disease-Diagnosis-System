import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.main import app
from app.database import get_db
from app.models.user import User


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
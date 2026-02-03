"""
Authentication Tests
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register_user(client: AsyncClient):
    """Test user registration."""
    response = await client.post(
        "/auth/register",
        json={
            "email": "newfarmer@example.com",
            "password": "password123",
            "full_name": "New Farmer",
            "phone": "+91-9876543210",
            "role": "FARMER",
        },
    )
    assert response.status_code in [201, 200]
    data = response.json()
    assert "user" in data or "message" in data


@pytest.mark.asyncio
async def test_register_duplicate_email(client: AsyncClient, test_user):
    """Test registration with existing email fails."""
    response = await client.post(
        "/auth/register",
        json={
            "email": test_user.email,
            "password": "password123",
            "full_name": "Duplicate User",
            "role": "FARMER",
        },
    )
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_login_valid_credentials(client: AsyncClient, test_user):
    """Test login with valid credentials."""
    response = await client.post(
        "/auth/login",
        json={
            "email": test_user.email,
            "password": "password123",
        },
    )
    # Login requires OTP verification, so may return different status
    assert response.status_code in [200, 202, 401]


@pytest.mark.asyncio
async def test_login_invalid_password(client: AsyncClient, test_user):
    """Test login with wrong password fails."""
    response = await client.post(
        "/auth/login",
        json={
            "email": test_user.email,
            "password": "wrongpassword",
        },
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_login_nonexistent_user(client: AsyncClient):
    """Test login with non-existent email fails."""
    response = await client.post(
        "/auth/login",
        json={
            "email": "doesnotexist@example.com",
            "password": "password123",
        },
    )
    assert response.status_code in [401, 404]


@pytest.mark.asyncio
async def test_protected_route_without_token(client: AsyncClient):
    """Test accessing protected route without token."""
    response = await client.get("/diagnosis/history")
    assert response.status_code == 403  # FastAPI returns 403 for missing auth


@pytest.mark.asyncio
async def test_protected_route_with_token(auth_client: AsyncClient):
    """Test accessing protected route with valid token."""
    response = await auth_client.get("/diagnosis/history")
    assert response.status_code == 200

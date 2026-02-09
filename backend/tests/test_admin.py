"""
Admin Endpoint Tests - Real API Tests
"""
import pytest
from httpx import AsyncClient
import uuid
from app.models import User, UserRole, UserStatus
from app.auth.jwt_handler import create_access_token, hash_password


@pytest.fixture
async def admin_user(test_db):
    """Create an admin user for testing."""
    admin = User(
        id=uuid.uuid4(),
        email="testadmin@crop.ai",
        password_hash=hash_password("admin123"),
        full_name="Test Admin",
        role=UserRole.ADMIN,
        status=UserStatus.ACTIVE,
        is_verified=True,
    )
    test_db.add(admin)
    await test_db.commit()
    await test_db.refresh(admin)
    return admin


@pytest.fixture
async def admin_client(client: AsyncClient, admin_user):
    """Get authenticated admin client."""
    token = create_access_token({"sub": str(admin_user.id)})
    client.headers["Authorization"] = f"Bearer {token}"
    return client


@pytest.fixture
async def pending_expert(test_db):
    """Create a pending expert for approval testing."""
    expert = User(
        id=uuid.uuid4(),
        email="pendingexpert@crop.ai",
        password_hash=hash_password("expert123"),
        full_name="Pending Expert",
        role=UserRole.EXPERT,
        status=UserStatus.PENDING,
        is_verified=True,
        expertise_domain="Plant Pathology",
        qualification="PhD",
        experience_years=5,
    )
    test_db.add(expert)
    await test_db.commit()
    await test_db.refresh(expert)
    return expert


@pytest.mark.asyncio
async def test_admin_dashboard(admin_client: AsyncClient):
    """Test admin dashboard returns metrics."""
    response = await admin_client.get("/admin/dashboard")
    assert response.status_code == 200
    data = response.json()
    
    # Response uses 'metrics' wrapper
    assert "metrics" in data
    assert "total_users" in data["metrics"]
    assert "total_farmers" in data["metrics"]
    assert "total_experts" in data["metrics"]
    assert "pending_experts" in data["metrics"]
    assert "total_diagnoses" in data["metrics"]
    assert "diagnoses_today" in data["metrics"]
    
    # Should also have trends
    assert "trends" in data
    assert "system_health" in data


@pytest.mark.asyncio
async def test_admin_get_pending_experts(admin_client: AsyncClient, pending_expert):
    """Test admin can list pending experts."""
    response = await admin_client.get("/admin/experts/pending")
    assert response.status_code == 200
    data = response.json()
    
    assert "experts" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_admin_approve_expert(admin_client: AsyncClient, pending_expert):
    """Test admin can approve a pending expert."""
    response = await admin_client.post(f"/admin/experts/approve/{pending_expert.id}")
    assert response.status_code == 200
    data = response.json()
    
    assert "message" in data
    assert "approved" in data["message"].lower() or "already" in data["message"].lower()


@pytest.mark.asyncio
async def test_admin_get_users(admin_client: AsyncClient):
    """Test admin can get user list."""
    response = await admin_client.get("/admin/users")
    assert response.status_code == 200
    data = response.json()
    
    assert "users" in data
    assert "total" in data
    assert "page" in data


@pytest.mark.asyncio
async def test_admin_get_system_logs(admin_client: AsyncClient):
    """Test admin can get system logs."""
    response = await admin_client.get("/admin/logs")
    assert response.status_code == 200
    data = response.json()
    
    assert "logs" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_admin_get_diagnoses(admin_client: AsyncClient):
    """Test admin can get all diagnoses."""
    response = await admin_client.get("/admin/diagnoses")
    assert response.status_code == 200
    data = response.json()
    
    assert "diagnoses" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_admin_get_questions(admin_client: AsyncClient):
    """Test admin can get all questions."""
    response = await admin_client.get("/admin/questions")
    assert response.status_code == 200
    data = response.json()
    
    assert "questions" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_farmer_cannot_access_admin_dashboard(auth_client: AsyncClient):
    """Test that farmers cannot access admin endpoints."""
    response = await auth_client.get("/admin/dashboard")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_admin_daily_metrics(admin_client: AsyncClient):
    """Test admin can get daily metrics."""
    response = await admin_client.get("/admin/metrics/daily?days=7")
    assert response.status_code == 200
    data = response.json()
    
    assert "metrics" in data
    assert isinstance(data["metrics"], list)

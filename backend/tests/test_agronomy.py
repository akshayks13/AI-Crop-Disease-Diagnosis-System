"""
Test Agronomy Read Endpoints
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_diagnostic_rules(auth_client: AsyncClient):
    """Test listing diagnostic rules (any authenticated user)."""
    response = await auth_client.get("/agronomy/diagnostic-rules")
    assert response.status_code == 200
    data = response.json()
    assert "rules" in data
    assert isinstance(data["rules"], list)


@pytest.mark.asyncio
async def test_list_treatment_constraints(auth_client: AsyncClient):
    """Test listing treatment constraints (any authenticated user)."""
    response = await auth_client.get("/agronomy/treatment-constraints")
    assert response.status_code == 200
    data = response.json()
    assert "constraints" in data
    assert isinstance(data["constraints"], list)


@pytest.mark.asyncio
async def test_list_seasonal_patterns(auth_client: AsyncClient):
    """Test listing seasonal patterns (any authenticated user)."""
    response = await auth_client.get("/agronomy/seasonal-patterns")
    assert response.status_code == 200
    data = response.json()
    assert "patterns" in data
    assert isinstance(data["patterns"], list)


@pytest.mark.asyncio
async def test_unauthenticated_cannot_access_agronomy(client: AsyncClient):
    """Test that unauthenticated users cannot access agronomy endpoints."""
    response = await client.get("/agronomy/diagnostic-rules")
    assert response.status_code == 401

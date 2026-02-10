"""
Unit Tests for Market API
"""
import pytest
from httpx import AsyncClient


class TestMarketAPI:
    """Tests for market price endpoints."""

    @pytest.mark.asyncio
    async def test_get_market_prices(self, auth_client: AsyncClient):
        """Test fetching market prices."""
        response = await auth_client.get("/market/prices")
        assert response.status_code == 200
        data = response.json()
        assert "prices" in data
        assert "total" in data
        assert isinstance(data["prices"], list)

    @pytest.mark.asyncio
    async def test_get_market_prices_with_filter(self, auth_client: AsyncClient):
        """Test fetching market prices with commodity filter."""
        response = await auth_client.get("/market/prices", params={"commodity": "Tomato"})
        assert response.status_code == 200
        data = response.json()
        assert "prices" in data
        # All returned prices should contain "Tomato" in commodity
        for price in data["prices"]:
            assert "tomato" in price["commodity"].lower()

    @pytest.mark.asyncio
    async def test_get_market_prices_pagination(self, auth_client: AsyncClient):
        """Test market prices pagination."""
        response = await auth_client.get("/market/prices", params={"page": 1, "page_size": 5})
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["page_size"] == 5
        assert len(data["prices"]) <= 5

    @pytest.mark.asyncio
    async def test_unauthorized_access(self, client: AsyncClient):
        """Test that unauthenticated requests are rejected."""
        response = await client.get("/market/prices")
        assert response.status_code == 401  # OAuth2 returns 401 for missing auth

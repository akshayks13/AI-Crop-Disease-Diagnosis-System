"""
Unit Tests for Encyclopedia API
"""
import pytest
from httpx import AsyncClient


class TestEncyclopediaAPI:
    """Tests for crop encyclopedia endpoints."""

    @pytest.mark.asyncio
    async def test_get_crops(self, auth_client: AsyncClient):
        """Test fetching encyclopedia crops."""
        response = await auth_client.get("/encyclopedia/crops")
        assert response.status_code == 200
        data = response.json()
        assert "crops" in data
        assert isinstance(data["crops"], list)

    @pytest.mark.asyncio
    async def test_search_crops(self, auth_client: AsyncClient):
        """Test searching crops by name."""
        response = await auth_client.get("/encyclopedia/crops", params={"search": "tomato"})
        assert response.status_code == 200
        data = response.json()
        assert "crops" in data
        # Results should match search term
        for crop in data["crops"]:
            assert "tomato" in crop["name"].lower()

    @pytest.mark.asyncio
    async def test_get_diseases(self, auth_client: AsyncClient):
        """Test fetching encyclopedia diseases."""
        response = await auth_client.get("/encyclopedia/diseases")
        assert response.status_code == 200
        data = response.json()
        assert "diseases" in data
        assert isinstance(data["diseases"], list)

    @pytest.mark.asyncio
    async def test_filter_diseases_by_crop(self, auth_client: AsyncClient):
        """Test filtering diseases by affected crop."""
        response = await auth_client.get("/encyclopedia/diseases", params={"crop": "Tomato"})
        assert response.status_code == 200
        data = response.json()
        assert "diseases" in data
        # Results should affect the specified crop
        for disease in data["diseases"]:
            crops_lower = [c.lower() for c in disease.get("affected_crops", [])]
            assert "tomato" in crops_lower

    @pytest.mark.asyncio
    async def test_get_crop_detail(self, auth_client: AsyncClient):
        """Test fetching crop details by ID."""
        # First get list to find an ID
        list_response = await auth_client.get("/encyclopedia/crops")
        crops = list_response.json().get("crops", [])
        
        if crops:
            crop_id = crops[0]["id"]
            response = await auth_client.get(f"/encyclopedia/crops/{crop_id}")
            assert response.status_code == 200
            data = response.json()
            assert data["id"] == crop_id

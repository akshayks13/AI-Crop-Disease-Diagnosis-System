"""
Unit Tests for Farm API
"""
import pytest
from datetime import datetime, timedelta
from httpx import AsyncClient


class TestFarmAPI:
    """Tests for farm management endpoints."""

    @pytest.mark.asyncio
    async def test_get_crops_empty(self, auth_client: AsyncClient):
        """Test fetching crops when empty."""
        response = await auth_client.get("/farm/crops")
        assert response.status_code == 200
        data = response.json()
        assert "crops" in data
        assert data["total"] == 0

    @pytest.mark.asyncio
    async def test_create_crop(self, auth_client: AsyncClient):
        """Test creating a new crop."""
        crop_data = {
            "name": "Tomatoes Field A",
            "crop_type": "Tomato",
            "field_name": "Field A",
            "area_size": 2.5,
            "sow_date": datetime.now().strftime("%Y-%m-%d"),
        }
        response = await auth_client.post("/farm/crops", json=crop_data)
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == crop_data["name"]
        assert data["crop_type"] == crop_data["crop_type"]
        assert "id" in data

    @pytest.mark.asyncio
    async def test_get_tasks_empty(self, auth_client: AsyncClient):
        """Test fetching tasks when empty."""
        response = await auth_client.get("/farm/tasks")
        assert response.status_code == 200
        data = response.json()
        assert "tasks" in data
        assert data["total"] == 0

    @pytest.mark.asyncio
    async def test_create_task(self, auth_client: AsyncClient):
        """Test creating a new task."""
        task_data = {
            "title": "Water the tomatoes",
            "description": "Apply 2L per plant",
            "priority": "high",
            "due_date": (datetime.now() + timedelta(days=1)).isoformat(),
        }
        response = await auth_client.post("/farm/tasks", json=task_data)
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == task_data["title"]
        assert data["is_completed"] == False

    @pytest.mark.asyncio
    async def test_complete_task(self, auth_client: AsyncClient):
        """Test completing a task."""
        # Create task first
        task_data = {"title": "Task to Complete", "priority": "medium"}
        create_response = await auth_client.post("/farm/tasks", json=task_data)
        task_id = create_response.json()["id"]
        
        # Complete it
        complete_response = await auth_client.put(f"/farm/tasks/{task_id}/complete")
        assert complete_response.status_code == 200
        data = complete_response.json()
        assert data["is_completed"] == True

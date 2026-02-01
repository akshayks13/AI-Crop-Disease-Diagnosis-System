"""
Questions (Expert Q&A) Tests
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_question(auth_client: AsyncClient):
    """Test creating a new question."""
    response = await auth_client.post(
        "/questions",
        json={
            "question_text": "My tomato plants have yellow spots on the leaves. What could this be?"
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert "id" in data or "question_id" in data


@pytest.mark.asyncio
async def test_create_question_too_short(auth_client: AsyncClient):
    """Test question validation - too short."""
    response = await auth_client.post(
        "/questions",
        json={"question_text": "Help?"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_get_my_questions(auth_client: AsyncClient):
    """Test fetching user's questions."""
    response = await auth_client.get("/questions")
    assert response.status_code == 200
    data = response.json()
    assert "questions" in data


@pytest.mark.asyncio
async def test_get_question_detail(auth_client: AsyncClient, test_db):
    """Test getting question details."""
    # First create a question
    create_response = await auth_client.post(
        "/questions",
        json={
            "question_text": "What is the best treatment for early blight on potatoes?"
        },
    )
    
    if create_response.status_code == 201:
        data = create_response.json()
        question_id = data.get("id") or data.get("question_id")
        
        # Then fetch it
        response = await auth_client.get(f"/questions/{question_id}")
        assert response.status_code == 200


@pytest.mark.asyncio
async def test_question_unauthorized(client: AsyncClient):
    """Test question endpoints require authentication."""
    response = await client.get("/questions")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_question_not_found(auth_client: AsyncClient):
    """Test getting non-existent question."""
    fake_id = "00000000-0000-0000-0000-000000000000"
    response = await auth_client.get(f"/questions/{fake_id}")
    assert response.status_code == 404

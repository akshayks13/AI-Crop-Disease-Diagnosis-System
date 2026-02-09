"""
Expert Endpoint Tests - Real API Tests
"""
import pytest
from httpx import AsyncClient
import uuid
from app.models import User, UserRole, UserStatus, Question, QuestionStatus
from app.auth.jwt_handler import create_access_token, hash_password


@pytest.fixture
async def expert_user(test_db):
    """Create an approved expert user."""
    expert = User(
        id=uuid.uuid4(),
        email="expertuser@crop.ai",
        password_hash=hash_password("expert123"),
        full_name="Test Expert",
        role=UserRole.EXPERT,
        status=UserStatus.ACTIVE,
        is_verified=True,
        expertise_domain="Plant Pathology",
        qualification="MSc Agriculture",
        experience_years=5,
    )
    test_db.add(expert)
    await test_db.commit()
    await test_db.refresh(expert)
    return expert


@pytest.fixture
async def expert_client(client: AsyncClient, expert_user):
    """Get authenticated expert client."""
    token = create_access_token({"sub": str(expert_user.id)})
    client.headers["Authorization"] = f"Bearer {token}"
    return client


@pytest.fixture
async def test_question(test_db, test_user):
    """Create a test question for expert to answer."""
    from datetime import datetime
    question = Question(
        id=uuid.uuid4(),
        farmer_id=test_user.id,
        question_text="My tomato plants have yellow leaves. What should I do?",
        status=QuestionStatus.OPEN,
        created_at=datetime.utcnow(),
    )
    test_db.add(question)
    await test_db.commit()
    await test_db.refresh(question)
    return question


@pytest.mark.asyncio
async def test_get_expert_status(expert_client: AsyncClient):
    """Test expert can get their status."""
    response = await expert_client.get("/expert/status")
    assert response.status_code == 200
    data = response.json()
    
    assert "id" in data
    assert "email" in data
    assert "role" in data
    assert "is_approved" in data
    assert "status" in data


@pytest.mark.asyncio
async def test_get_expert_stats(expert_client: AsyncClient):
    """Test expert can get their statistics."""
    response = await expert_client.get("/expert/stats")
    assert response.status_code == 200
    data = response.json()
    
    assert "total_answers" in data
    assert "is_approved" in data
    assert "status" in data


@pytest.mark.asyncio
async def test_get_open_questions(expert_client: AsyncClient, test_question):
    """Test expert can get open questions."""
    response = await expert_client.get("/expert/questions")
    assert response.status_code == 200
    data = response.json()
    
    assert "questions" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_expert_submit_answer(expert_client: AsyncClient, test_question):
    """Test expert can submit an answer."""
    response = await expert_client.post(
        "/expert/answer",
        json={
            "question_id": str(test_question.id),
            "answer_text": "Yellow leaves on tomato plants could indicate nitrogen deficiency. Consider applying a balanced fertilizer and ensure proper watering."
        }
    )
    
    assert response.status_code == 201
    data = response.json()
    assert "id" in data
    assert "message" in data


@pytest.mark.asyncio
async def test_expert_cannot_answer_twice(expert_client: AsyncClient, test_question):
    """Test expert cannot answer the same question twice."""
    # First answer
    await expert_client.post(
        "/expert/answer",
        json={
            "question_id": str(test_question.id),
            "answer_text": "This is the first answer with enough characters to pass validation."
        }
    )
    
    # Try second answer
    response = await expert_client.post(
        "/expert/answer",
        json={
            "question_id": str(test_question.id),
            "answer_text": "This is another answer attempt with enough characters."
        }
    )
    
    assert response.status_code == 409  # Conflict


@pytest.mark.asyncio
async def test_farmer_cannot_access_expert_questions(auth_client: AsyncClient):
    """Test that farmers cannot access expert endpoints."""
    response = await auth_client.get("/expert/questions")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_get_my_answers(expert_client: AsyncClient):
    """Test expert can get their answered questions."""
    response = await expert_client.get("/expert/my-answers")
    assert response.status_code == 200
    data = response.json()
    
    assert "answers" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_update_expert_profile(expert_client: AsyncClient):
    """Test expert can update their profile."""
    response = await expert_client.put(
        "/expert/profile",
        json={
            "expertise_domain": "Plant Pathology & Entomology",
            "experience_years": 7
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


@pytest.mark.asyncio
async def test_get_trending_diseases(expert_client: AsyncClient):
    """Test expert can get trending diseases."""
    response = await expert_client.get("/expert/trending-diseases")
    assert response.status_code == 200
    data = response.json()
    
    assert "trending" in data
    assert "period" in data

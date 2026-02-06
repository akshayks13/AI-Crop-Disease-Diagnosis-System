"""
Diagnosis Tests

NOTE: AI/ML model integration is TODO - these tests cover API structure only.
"""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_diagnosis_history_empty(auth_client: AsyncClient):
    """Test getting empty diagnosis history."""
    response = await auth_client.get("/diagnosis/history")
    assert response.status_code == 200
    data = response.json()
    assert "diagnoses" in data
    assert isinstance(data["diagnoses"], list)


@pytest.mark.asyncio
async def test_diagnosis_history_pagination(auth_client: AsyncClient):
    """Test diagnosis history pagination parameters."""
    response = await auth_client.get("/diagnosis/history?page=1&page_size=10")
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "page" in data


@pytest.mark.asyncio
async def test_diagnosis_unauthorized(client: AsyncClient):
    """Test diagnosis endpoints require authentication."""
    response = await client.get("/diagnosis/history")
    assert response.status_code == 403  # FastAPI returns 403 for missing auth


# ============== TODO: AI/ML Integration ==============
# The following tests are placeholders for when AI model is integrated:
#
# - test_diagnosis_predict_with_image: Upload real image, get disease prediction
# - test_diagnosis_confidence_threshold: Verify confidence scoring
# - test_diagnosis_treatment_plan: Verify treatment recommendations
# - test_diagnosis_model_loading: Verify ML model loads correctly

"""
E2E Test: Farmer Complete Flow
"""

import pytest


@pytest.mark.asyncio
async def test_farmer_question_flow(client, register_and_login_farmer):
    """
    Full farmer journey:
    - Login
    - Create question
    - Fetch own questions
    """

    headers = register_and_login_farmer

    question_data = {
        "question_text":"Leaves turning yellow suddenly on my crop. What should I do ?"
    }

    create_response = await client.post(
        "/questions",
        json=question_data,
        headers=headers
    )

    assert create_response.status_code == 201

    my_questions = await client.get(
        "/questions",
        headers=headers
    )

    assert my_questions.status_code == 200
    data = my_questions.json()
    assert "questions" in data
    assert isinstance(data["questions"], list)
    assert len(data["questions"]) >= 1
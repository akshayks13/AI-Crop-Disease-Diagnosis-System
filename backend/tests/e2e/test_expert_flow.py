import pytest


@pytest.mark.asyncio
async def test_expert_full_flow(
    client,
    register_and_login_farmer,
    register_and_login_expert
):
    """
    Full system flow:
    Farmer creates question →
    Expert answers →
    Expert cannot answer twice
    """

    farmer_headers = register_and_login_farmer
    expert_headers = register_and_login_expert

    # 1️⃣ Farmer creates question
    create_q = await client.post(
        "/questions",
        json={
            "question_text": "My crop leaves are turning brown suddenly. What should I do?"
        },
        headers=farmer_headers,
    )

    assert create_q.status_code in [200, 201]

    question_id = create_q.json()["id"]

    # 2️⃣ Expert answers question
    answer = await client.post(
        "/expert/answer",
        json={
            "question_id": question_id,
            "answer_text": "This may be fungal infection. Use appropriate fungicide."
        },
        headers=expert_headers,
    )

    assert answer.status_code in [200, 201]

    # 3️⃣ Expert cannot answer twice
    second_attempt = await client.post(
        "/expert/answer",
        json={
            "question_id": question_id,
            "answer_text": "Another answer attempt."
        },
        headers=expert_headers,
    )

    assert second_attempt.status_code == 409
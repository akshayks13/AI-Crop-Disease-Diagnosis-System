import pytest


@pytest.mark.asyncio
async def test_admin_can_access_admin_endpoint(client, register_and_login_admin):
    """
    Admin full flow:
    - Login as admin
    - Access admin-only endpoint
    - Should succeed
    """

    headers = register_and_login_admin

    response = await client.get("/admin/users", headers=headers)

    assert response.status_code == 200


@pytest.mark.asyncio
async def test_farmer_cannot_access_admin_endpoint(client, register_and_login_farmer):
    """
    Security check:
    - Login as farmer
    - Try accessing admin endpoint
    - Should fail
    """

    headers = register_and_login_farmer

    response = await client.get("/admin/users", headers=headers)

    assert response.status_code == 403
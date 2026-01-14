import asyncio
import httpx
import sys
import os

# Add parent dir to path if needed (though we're running http requests so it doesn't matter much)

async def test_admin_access():
    base_url = "http://localhost:8000"
    
    # 1. Login
    print("Logging in...")
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(f"{base_url}/auth/login", json={
                "email": "admin@cropdiagnosis.com",
                "password": "admin_password"
            })
            
            if resp.status_code != 200:
                print(f"Login failed: {resp.status_code} - {resp.text}")
                return
            
            token = resp.json()["access_token"]
            print("Login successful, token obtained.")
            
            # 2. Access Dashboard
            print("Accessing /admin/dashboard...")
            resp = await client.get(
                f"{base_url}/admin/dashboard",
                headers={"Authorization": f"Bearer {token}"}
            )
            
            print(f"Dashboard Response: {resp.status_code}")
            if resp.status_code != 200:
                print(f"Error: {resp.text}")
            else:
                print("Success!")
                
        except Exception as e:
            print(f"Request failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_admin_access())

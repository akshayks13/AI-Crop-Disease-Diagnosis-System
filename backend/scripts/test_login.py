import asyncio
import os
import sys

# Add the parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from app.database import async_session_maker
from app.models.user import User
from app.auth.jwt_handler import verify_password, hash_password

async def test_admin_login():
    email = "admin@cropdiagnosis.com"
    password = "admin_password"
    
    print(f"Testing login for {email} with password: {password}")
    
    async with async_session_maker() as db:
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        
        if not user:
            print("❌ User not found!")
            return

        print(f"User found: {user.full_name} ({user.role})")
        # print(f"Stored Hash: {user.password_hash}")
        
        is_valid = verify_password(password, user.password_hash)
        
        if is_valid:
            print("✅ Password verified successfully!")
        else:
            print("❌ Password verification FAILED!")
            
            # Reset password to be sure
            print("Resetting password...")
            user.password_hash = hash_password(password)
            await db.commit()
            print("✅ Password reset to 'admin_password'")

if __name__ == "__main__":
    asyncio.run(test_admin_login())

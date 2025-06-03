#!/usr/bin/env python3
"""
Script to create an admin user for the LLM orchestration system
"""
import asyncio
import sys
from sqlalchemy.orm import Session
from database.connection import SessionLocal
from api.services.auth import register_user
from core.security import get_password_hash

async def create_admin_user():
    """Create an admin user with elevated privileges"""
    db = SessionLocal()
    
    admin_data = {
        "email": "admin@vigor.com",
        "username": "admin",
        "password": "admin123!",  # Change this in production!
        "fitness_level": "advanced",
        "goals": ["muscle_gain"],
        "equipment": "full"
    }
    
    try:
        # Try to create admin user
        user = await register_user(db, admin_data)
        print(f"✅ Admin user created successfully!")
        print(f"   Email: {user.email}")
        print(f"   Username: {user.username}")
        print(f"   User ID: {user.id}")
        print(f"   Default Password: admin123! (CHANGE IN PRODUCTION)")
        
        # Note: In a real system, you'd set admin privileges in a separate table
        # For now, we'll document that this user should be treated as admin
        print(f"\n📝 To grant admin privileges, add this user ID to your admin configuration")
        return user
        
    except Exception as e:
        if "Email already registered" in str(e):
            print("ℹ️  Admin user already exists")
        else:
            print(f"❌ Error creating admin user: {e}")
    finally:
        db.close()

async def main():
    print("🔧 Creating admin user for LLM Orchestration system...")
    await create_admin_user()
    print("\n🎯 Next steps:")
    print("1. Log in with admin@vigor.com / admin123!")
    print("2. Test admin endpoints at http://localhost:8001/docs")
    print("3. Configure model priorities and routing rules")
    print("4. Set up budget management and monitoring")

if __name__ == "__main__":
    asyncio.run(main()) 
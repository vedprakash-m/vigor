"""
Simple validation test for our modernized functions
Tests basic functionality without requiring Azure connections
"""

import os
import sys
import json
from datetime import datetime, timezone

# Add the current directory to path for imports
sys.path.append('.')

def test_configuration():
    """Test configuration loading"""
    print("🧪 Testing Configuration...")
    
    # Set mock environment variables
    os.environ['COSMOS_DB_ENDPOINT'] = 'https://test.documents.azure.com:443/'
    os.environ['COSMOS_DB_KEY'] = 'test_key'
    os.environ['COSMOS_DB_DATABASE_NAME'] = 'vigor_test'
    os.environ['JWT_SECRET_KEY'] = 'test_secret_key_12345678901234567890'
    os.environ['GOOGLE_AI_API_KEY'] = 'test_gemini_key'
    os.environ['ADMIN_EMAIL'] = 'admin@vigor.test'
    os.environ['ADMIN_PASSWORD'] = 'TestAdmin123!'
    
    try:
        from config import get_settings
        settings = get_settings()
        
        assert settings.COSMOS_DB_ENDPOINT == 'https://test.documents.azure.com:443/'
        assert settings.JWT_SECRET_KEY == 'test_secret_key_12345678901234567890'
        assert settings.COSMOS_DB_DATABASE_NAME == 'vigor_test'
        
        print("  ✅ Configuration loaded successfully")
        print(f"  ✅ Database endpoint: {settings.COSMOS_DB_ENDPOINT}")
        print(f"  ✅ Database name: {settings.COSMOS_DB_DATABASE_NAME}")
        return True
        
    except Exception as e:
        print(f"  ❌ Configuration test failed: {str(e)}")
        return False

def test_models():
    """Test Pydantic models"""
    print("🧪 Testing Data Models...")
    
    try:
        from models import UserProfile, WorkoutPlan, Exercise, WorkoutGenerationRequest
        
        # Test user profile model
        from datetime import datetime
        profile_data = {
            "id": "test-profile-123",
            "userId": "test-123",
            "email": "test@vigor.com",
            "username": "testuser",
            "profile": {
                "fitnessLevel": "intermediate",
                "goals": ["lose_weight"],
                "equipment": "bodyweight",
                "tier": "free"
            },
            "preferences": {
                "workoutDuration": 30,
                "restDays": ["sunday"],
                "notifications": True
            },
            "createdAt": datetime.utcnow(),
            "updatedAt": datetime.utcnow()
        }
        
        user_profile = UserProfile(**profile_data)
        assert user_profile.userId == "test-123"
        assert user_profile.email == "test@vigor.com"
        
        # Test exercise model
        exercise_data = {
            "name": "Push-ups",
            "sets": 3,
            "reps": 10,
            "restSeconds": 60,
            "instructions": "Keep your body straight"
        }
        
        exercise = Exercise(**exercise_data)
        assert exercise.name == "Push-ups"
        assert exercise.sets == 3
        
        # Test workout generation request
        request_data = {
            "durationMinutes": 20,
            "difficulty": "moderate",
            "equipment": "bodyweight",
            "focusAreas": ["cardio", "strength"]
        }
        
        workout_request = WorkoutGenerationRequest(**request_data)
        assert workout_request.durationMinutes == 20
        assert workout_request.difficulty == "moderate"
        
        print("  ✅ User profile model validation passed")
        print("  ✅ Exercise model validation passed")
        print("  ✅ Workout request model validation passed")
        return True
        
    except Exception as e:
        print(f"  ❌ Model test failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_auth_module():
    """Test authentication utilities"""
    print("🧪 Testing Authentication Module...")
    
    try:
        from auth import create_access_token, hash_password, verify_password
        
        # Test password hashing
        password = "TestPassword123!"
        hashed = hash_password(password)
        assert len(hashed) > 0
        assert hashed != password
        
        # Test password verification
        assert verify_password(password, hashed) == True
        assert verify_password("WrongPassword", hashed) == False
        
        # Test token creation
        user_data = {
            "user_id": "test-user-123",
            "email": "test@vigor.com",
            "username": "testuser",
            "tier": "free"
        }
        
        token = create_access_token(user_data)
        assert len(token) > 0
        assert isinstance(token, str)
        
        print("  ✅ Password hashing and verification working")
        print("  ✅ JWT token creation working")
        return True
        
    except Exception as e:
        print(f"  ❌ Auth test failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_rate_limiter():
    """Test rate limiting module"""
    print("🧪 Testing Rate Limiter...")
    
    try:
        from rate_limiter import RateLimiter
        
        limiter = RateLimiter()
        
        # Test basic rate limiting
        key = "test_user_123"
        limit = 5
        window = 60
        
        # Should allow first few requests
        for i in range(limit):
            assert limiter.is_allowed(key, limit, window) == True
        
        # Should deny the next request
        assert limiter.is_allowed(key, limit, window) == False
        
        # Test remaining count
        remaining = limiter.get_remaining(key, limit, window)
        assert remaining == 0
        
        # Test reset
        limiter.reset(key)
        assert limiter.is_allowed(key, limit, window) == True
        
        print("  ✅ Rate limiting logic working")
        print("  ✅ Rate limit reset working")
        return True
        
    except Exception as e:
        print(f"  ❌ Rate limiter test failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_migration_data():
    """Test migration data handling"""
    print("🧪 Testing Migration Data...")
    
    try:
        # Check if sample data file exists
        if os.path.exists('sample_migration_data.json'):
            with open('sample_migration_data.json', 'r') as f:
                data = json.load(f)
            
            assert 'users' in data
            assert 'workouts' in data
            assert 'chat_sessions' in data
            assert 'summary' in data
            
            # Validate data structure
            assert len(data['users']) > 0
            assert len(data['workouts']) > 0
            
            user = data['users'][0]
            assert 'email' in user
            assert 'username' in user
            
            workout = data['workouts'][0]
            assert 'title' in workout
            assert 'exercises' in workout
            
            print("  ✅ Sample migration data structure valid")
            print(f"  ✅ Found {len(data['users'])} users, {len(data['workouts'])} workouts")
            return True
        else:
            print("  ⚠️  Sample migration data not found")
            return False
        
    except Exception as e:
        print(f"  ❌ Migration data test failed: {str(e)}")
        return False

def run_all_tests():
    """Run all validation tests"""
    print("🚀 Starting Vigor Functions Validation Tests")
    print("=" * 50)
    
    tests = [
        test_configuration,
        test_models,
        test_auth_module,
        test_rate_limiter,
        test_migration_data
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        print()
    
    print("=" * 50)
    print(f"🎯 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("✅ All tests passed! Functions are ready for deployment.")
        return True
    else:
        print("❌ Some tests failed. Please review the errors above.")
        return False

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)

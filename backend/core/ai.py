from typing import List, Dict, Any, Optional
import json
from sqlalchemy.orm import Session

from .admin_llm_manager import get_admin_llm_manager
from database.connection import get_db

async def generate_workout_plan(
    user_goals: List[str],
    equipment: str,
    duration_minutes: int = 45,
    focus_areas: Optional[List[str]] = None,
    user_id: Optional[str] = None,
    db: Session = None
) -> Dict[str, Any]:
    """Generate a personalized workout plan using admin-managed LLM system."""
    
    if db is None:
        db = next(get_db())
    
    llm_manager = get_admin_llm_manager(db)
    
    # Create system prompt
    system_prompt = """You are an expert fitness trainer creating personalized workout plans. 
    Respond with a valid JSON object containing: name, description, exercises (array), 
    duration_minutes, difficulty, equipment_needed (array), and notes."""
    
    # Create user message
    focus_text = f" focusing on {', '.join(focus_areas)}" if focus_areas else ""
    user_message = f"""Create a {duration_minutes}-minute workout plan for someone with goals: {', '.join(user_goals)}. 
    Available equipment: {equipment}.{focus_text}
    
    Include specific exercises with sets, reps, and brief instructions."""
    
    messages = [{"role": "user", "content": user_message}]
    
    try:
        response, cost, provider_used = await llm_manager.chat_completion(
            messages=messages,
            system_prompt=system_prompt,
            max_tokens=800,
            temperature=0.7,
            json_response=True,
            user_id=user_id,
            endpoint="workout-plan"
        )
        
        # Parse JSON response
        workout_data = json.loads(response)
        
        # Add metadata
        workout_data["ai_cost"] = cost
        workout_data["ai_provider"] = provider_used
        
        return workout_data
        
    except json.JSONDecodeError:
        # Fallback if JSON parsing fails
        return {
            "name": "Custom Workout",
            "description": "A personalized workout plan",
            "exercises": [
                {
                    "name": "Push-ups",
                    "sets": 3,
                    "reps": "8-12",
                    "rest": "60 seconds",
                    "instructions": "Keep your core tight and lower your chest to the ground"
                },
                {
                    "name": "Squats",
                    "sets": 3,
                    "reps": "12-15", 
                    "rest": "60 seconds",
                    "instructions": "Keep your chest up and weight in your heels"
                }
            ],
            "duration_minutes": duration_minutes,
            "difficulty": "intermediate",
            "equipment_needed": [equipment] if equipment != "none" else [],
            "notes": "AI response parsing failed - using fallback workout",
            "ai_cost": 0.0,
            "ai_provider": "fallback"
        }

async def get_ai_coach_response(
    user_message: str,
    user_context: Optional[Dict[str, Any]] = None,
    user_id: Optional[str] = None,
    db: Session = None
) -> str:
    """Get a response from the AI fitness coach using admin-managed LLM system."""
    
    if db is None:
        db = next(get_db())
    
    llm_manager = get_admin_llm_manager(db)
    
    # Create system prompt
    system_prompt = """You are a knowledgeable, encouraging fitness coach. Provide helpful, 
    personalized advice about workouts, nutrition, motivation, and fitness goals. 
    Keep responses conversational but informative. Always prioritize safety."""
    
    # Add context if available
    context_text = ""
    if user_context:
        if user_context.get("fitness_level"):
            context_text += f"User fitness level: {user_context['fitness_level']}. "
        if user_context.get("goals"):
            context_text += f"User goals: {', '.join(user_context['goals'])}. "
        if user_context.get("equipment"):
            context_text += f"Available equipment: {user_context['equipment']}. "
    
    full_message = f"{context_text}User question: {user_message}"
    messages = [{"role": "user", "content": full_message}]
    
    try:
        response, cost, provider_used = await llm_manager.chat_completion(
            messages=messages,
            system_prompt=system_prompt,
            max_tokens=500,
            temperature=0.8,
            json_response=False,
            user_id=user_id,
            endpoint="chat"
        )
        
        return response
        
    except Exception as e:
        # Log error and return fallback
        return f"I'm having trouble connecting to my AI systems right now. In the meantime, remember that consistency is key to achieving your fitness goals! If you have specific questions about exercises or nutrition, I'd be happy to help once my systems are back online."

async def analyze_workout_log(
    workout_data: Dict[str, Any],
    user_context: Optional[Dict[str, Any]] = None,
    user_id: Optional[str] = None,
    db: Session = None
) -> Dict[str, Any]:
    """Analyze a completed workout and provide feedback using admin-managed LLM system."""
    
    if db is None:
        db = next(get_db())
    
    llm_manager = get_admin_llm_manager(db)
    
    # Create system prompt
    system_prompt = """You are a fitness coach analyzing a completed workout. 
    Respond with a valid JSON object containing: overall_assessment, strengths (array), 
    areas_for_improvement (array), recommendations (array), and next_steps."""
    
    # Create analysis message
    workout_summary = f"""Analyze this completed workout:
    Duration: {workout_data.get('duration_minutes', 'unknown')} minutes
    Exercises completed: {len(workout_data.get('exercises_completed', []))}
    User notes: {workout_data.get('notes', 'None')}
    
    Exercise details: {json.dumps(workout_data.get('exercises_completed', []), indent=2)}"""
    
    if user_context:
        workout_summary += f"\n\nUser context - Fitness level: {user_context.get('fitness_level', 'unknown')}, Goals: {user_context.get('goals', [])}"
    
    messages = [{"role": "user", "content": workout_summary}]
    
    try:
        response, cost, provider_used = await llm_manager.chat_completion(
            messages=messages,
            system_prompt=system_prompt,
            max_tokens=600,
            temperature=0.7,
            json_response=True,
            user_id=user_id,
            endpoint="analysis"
        )
        
        # Parse JSON response
        analysis_data = json.loads(response)
        
        # Add metadata
        analysis_data["ai_cost"] = cost
        analysis_data["ai_provider"] = provider_used
        
        return analysis_data
        
    except json.JSONDecodeError:
        # Fallback analysis
        return {
            "overall_assessment": "Good job completing your workout! Consistency is the key to progress.",
            "strengths": ["Completed the planned workout", "Stayed committed to your fitness goals"],
            "areas_for_improvement": ["Consider tracking more detailed metrics", "Focus on proper form"],
            "recommendations": ["Stay hydrated", "Get adequate rest", "Continue with regular workouts"],
            "next_steps": "Keep up the great work and consider gradually increasing intensity",
            "ai_cost": 0.0,
            "ai_provider": "fallback"
        } 
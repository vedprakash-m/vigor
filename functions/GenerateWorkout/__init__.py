"""
Generate Workout Function
Creates personalized workout plans based on user input
"""

import azure.functions as func
import json
import logging
import sys
import os

# Add the parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.ai_utils import generate_workout_plan

# Create a Function App
app = func.FunctionApp()

@app.function_name(name="GenerateWorkout")
@app.route(route="generate-workout", auth_level=func.AuthLevel.FUNCTION)
async def generate_workout_function(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP Trigger function to generate workout plans.

    Parameters in request body:
    - fitness_level: User's fitness level (beginner, intermediate, advanced)
    - goals: List of user goals
    - equipment: Available equipment (optional)
    - duration_minutes: Workout duration (optional)
    - focus_areas: Specific focus areas (optional)
    """

    logging.info("Processing workout generation request")

    try:
        # Parse request body
        req_body = req.get_json()
        fitness_level = req_body.get("fitness_level", "beginner")
        goals = req_body.get("goals", ["General fitness"])
        equipment = req_body.get("equipment")
        duration_minutes = req_body.get("duration_minutes", 45)
        focus_areas = req_body.get("focus_areas")

        # Generate workout plan using shared AI utility
        workout_plan = await generate_workout_plan(
            fitness_level=fitness_level,
            goals=goals,
            equipment=equipment,
            duration_minutes=duration_minutes,
            focus_areas=focus_areas
        )

        # Return the generated workout plan
        return func.HttpResponse(
            body=json.dumps(workout_plan),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"Error generating workout: {str(e)}")
        error_response = {
            "error": "Failed to generate workout plan",
            "detail": str(e)
        }
        return func.HttpResponse(
            body=json.dumps(error_response),
            mimetype="application/json",
            status_code=500
        )

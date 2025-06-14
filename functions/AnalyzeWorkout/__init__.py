"""
Analyze Workout Function
Analyzes completed workouts and provides feedback
"""

import azure.functions as func
import json
import logging
import sys
import os

# Add the parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.ai_utils import analyze_workout_performance

# Create a Function App
app = func.FunctionApp()

@app.function_name(name="AnalyzeWorkout")
@app.route(route="analyze-workout", auth_level=func.AuthLevel.FUNCTION)
async def analyze_workout_function(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP Trigger function to analyze completed workouts.

    Parameters in request body:
    - workout_data: Completed workout data
    - user_fitness_level: User's fitness level
    - previous_workouts: Optional list of previous workouts for context
    """

    logging.info("Processing workout analysis request")

    try:
        # Parse request body
        req_body = req.get_json()
        workout_data = req_body.get("workout_data", {})
        user_fitness_level = req_body.get("user_fitness_level", "beginner")
        previous_workouts = req_body.get("previous_workouts", None)

        # Analyze workout using shared AI utility
        analysis = await analyze_workout_performance(
            workout_data=workout_data,
            user_fitness_level=user_fitness_level,
            previous_workouts=previous_workouts
        )

        # Return the workout analysis
        return func.HttpResponse(
            body=json.dumps(analysis),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"Error analyzing workout: {str(e)}")
        error_response = {
            "error": "Failed to analyze workout",
            "detail": str(e)
        }
        return func.HttpResponse(
            body=json.dumps(error_response),
            mimetype="application/json",
            status_code=500
        )

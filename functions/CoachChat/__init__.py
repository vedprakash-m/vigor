"""
Coach Chat Function
Handles conversations with the AI fitness coach
"""

import azure.functions as func
import json
import logging
import sys
import os

# Add the parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.ai_utils import get_ai_coach_response

# Create a Function App
app = func.FunctionApp()

@app.function_name(name="CoachChat")
@app.route(route="coach-chat", auth_level=func.AuthLevel.FUNCTION)
async def coach_chat_function(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP Trigger function to get responses from the AI coach.

    Parameters in request body:
    - message: User's message
    - fitness_level: User's fitness level
    - goals: User's fitness goals
    - conversation_history: Optional conversation history
    """

    logging.info("Processing coach chat request")

    try:
        # Parse request body
        req_body = req.get_json()
        message = req_body.get("message")
        fitness_level = req_body.get("fitness_level", "beginner")
        goals = req_body.get("goals", ["General fitness"])
        conversation_history = req_body.get("conversation_history")

        # Validate required fields
        if not message:
            return func.HttpResponse(
                body=json.dumps({"error": "Message is required"}),
                mimetype="application/json",
                status_code=400
            )

        # Get coach response using shared AI utility
        response = await get_ai_coach_response(
            user_message=message,
            user_fitness_level=fitness_level,
            user_goals=goals,
            conversation_history=conversation_history
        )

        # Return the coach response
        return func.HttpResponse(
            body=json.dumps({"response": response}),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"Error in coach chat: {str(e)}")
        error_response = {
            "error": "Failed to get coach response",
            "detail": str(e)
        }
        return func.HttpResponse(
            body=json.dumps(error_response),
            mimetype="application/json",
            status_code=500
        )

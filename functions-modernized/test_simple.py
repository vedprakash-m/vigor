import azure.functions as func
import json


def main(req: func.HttpRequest) -> func.HttpResponse:
    """Simple test function to verify Function App is working"""
    try:
        return func.HttpResponse(
            json.dumps({
                "status": "ok",
                "message": "Function App is running",
                "method": req.method,
                "url": req.url
            }),
            status_code=200,
            mimetype="application/json"
        )
    except Exception as e:
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json"
        )

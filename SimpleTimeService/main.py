from flask import Flask, request, Response
import datetime
import json

app = Flask(__name__)

@app.route('/')
def get_time():
    # Get client IP address
    ip = request.headers.get('X-Forwarded-For', request.remote_addr)
    
    # Create response object with the exact format requested
    response = {
        "timestamp": datetime.datetime.now().isoformat(),
        "ip": ip
    }
    
    # Return a pure JSON response with proper Content-Type
    return Response(
        json.dumps(response),
        mimetype='application/json'
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)

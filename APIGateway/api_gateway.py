from flask import Flask, request, jsonify, Response
import threading
import time
import json
import requests

from notification import MSNotification
from common.models import Auction, Bid, Message
from common.rabbitmq import RabbitMQ
from common.config import EXCHANGE_NAME
from sse import app as sse_app, SSE

# ---- Configuração URLs dos microsserviços ----
MS_AUCTION_URL = "http://host.docker.internal:5004"
MS_BID_URL = "http://host.docker.internal:5005"

app = Flask(__name__)
rabbitmq = RabbitMQ()
exchange = EXCHANGE_NAME

# ------ Tracking de interesse ------
interests = {}  # {auction_id: set(user_id)}

@app.route('/api/interest', methods=['POST'])
def register_interest():
    """
    REST endpoint to register user interest in an auction.
    Body JSON: { "auction_id": ..., "user_id": ... }
    """
    data = request.json
    try:
        auction_id = str(data['auction_id'])
        user_id = str(data['user_id'])
        if auction_id not in interests:
            interests[auction_id] = set()
        interests[auction_id].add(user_id)
        return jsonify({"message": f"Interest registered for auction {auction_id} by user {user_id}."}), 200
    except Exception as e:
        return jsonify({"error": f"Invalid data: {str(e)}"}), 400

@app.route('/api/interest', methods=['DELETE'])
def cancel_interest():
    """
    REST endpoint to cancel user interest in an auction.
    Body JSON: { "auction_id": ..., "user_id": ... }
    """
    data = request.json
    try:
        auction_id = str(data['auction_id'])
        user_id = str(data['user_id'])
        if auction_id in interests and user_id in interests[auction_id]:
            interests[auction_id].remove(user_id)
            return jsonify({"message": f"Interest canceled for auction {auction_id} by user {user_id}."}), 200
        else:
            return jsonify({"error": "Interest not found."}), 404
    except Exception as e:
        return jsonify({"error": f"Invalid data: {str(e)}"}), 400

@app.route('/api/interest', methods=['GET'])
def list_interests():
    """List interests (debug purposes)"""
    return jsonify({k: list(v) for k, v in interests.items()}), 200

# ---- Auction REST endpoints ----
@app.route('/api/auction', methods=['GET'])
def get_auctions():
    try:
        response = requests.get(f"{MS_AUCTION_URL}/api/auction")
        return jsonify(response.json()), response.status_code
    except Exception as e:
        return jsonify({"error": f"Error contacting auction service: {str(e)}"}), 500

@app.route('/api/auction', methods=['POST'])
def create_auction():
    data = request.json
    try:
        response = requests.post(f"{MS_AUCTION_URL}/api/auction", json=data)
        return jsonify(response.json()), response.status_code
    except Exception as e:
        return jsonify({"error": f"Error contacting auction service: {str(e)}"}), 500

# ---- Bid REST endpoint ----
@app.route('/api/bid', methods=['POST'])
def post_bid():
    data = request.json
    try:
        response = requests.post(f"{MS_BID_URL}/api/bid", json=data)
        return jsonify(response.json()), response.status_code
    except Exception as e:
        return jsonify({"error": f"Error contacting bid service: {str(e)}"}), 500

# ---- Payment RabbitMQ/REST endpoint ----
@app.route('/api/payment', methods=['POST'])
def request_payment():
    # Proxy! Usuário chama payment, Gateway publica mensagem para o msPagamento via RabbitMQ/rest
    data = request.json
    try:
        msg = Message(event_type="request_payment", payload=data)
        rabbitmq.publish(exchange, "request_payment", msg.to_dict())
        return jsonify({"message": "Payment requested!"}), 202
    except Exception as e:
        return jsonify({"error": f"Invalid data: {str(e)}"}), 400

# ---- SSE (Server-Sent Events) ----
@app.route('/events/<auction_id>')
def sse_auction(auction_id):
    """
    SSE endpoint for a given auction.
    """
    # O notification.py já faz o forward dos eventos para o SSE
    return sse_app.full_dispatch_request()

# ---- Startup ----
def start_notification_listener():
    notification_service = MSNotification()
    notification_service.listen()

if __name__ == '__main__':
    threading.Thread(target=start_notification_listener, daemon=True).start()
    app.run(debug=True, host='0.0.0.0', port=8000)

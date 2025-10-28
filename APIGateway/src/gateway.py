import uuid
import threading
import json
import requests
from flask import Flask, jsonify

from common.rabbitmq import RabbitMQ
# from common.models import Bid, Message
from common import config

app = Flask(__name__)
MSAUCTION_URL = "http://localhost:5001/api/leiloes"
MSBID_URL = "http://localhost:5002/api/lance" 


auction_interests = {}
sse_connections = {}

@app.route('/leiloes', methods=['GET'])
def listar_leiloes():
    response = requests.get(MSAUCTION_URL)
    leiloes = response.json()
    return jsonify(leiloes)

# Esperado pelo corpo da requisição:
# json
# {
#   "id": 3,
#   "description": "TV 50 polegadas",
#   "start_time": "2025-10-21T15:00:00",
#   "end_time": "2025-10-21T16:00:00"
# }
@app.route('/leiloes', methods=['POST'])
def criar_leilao_gateway():
    dados_leilao = request.json
    resp = requests.post(MSAUCTION_URL, json=dados_leilao)
    return jsonify(resp.json()), resp.status_code

@app.route('/lance', methods=['POST'])
def efetuar_lance():
    try:
        dados_lance = request.json
        
        required_fields = ['auction_id', 'user_id', 'amount']
        for field in required_fields:
            if field not in dados_lance:
                return jsonify({"error": f"Campo obrigatório ausente: {field}"}), 400
        
        response = requests.post(MSBID_URL, json=dados_lance)
        return jsonify(response.json()), response.status_code
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

# POST /interesse
# Content-Type: application/json

# {
#   "user_id": "user123",
#   "auction_id": 1
# }
@app.route('/interesse', methods=['POST'])
def registrar_interesse():
    """
    Registra interesse de um usuário em receber notificações sobre um leilão.
    Payload esperado: {"user_id": "user123", "auction_id": 1}
    """
    try:
        data = request.json
        user_id = data['user_id']
        auction_id = data['auction_id']
        
        # Adiciona o interesse
        if auction_id not in auction_interests:
            auction_interests[auction_id] = set()
        
        auction_interests[auction_id].add(user_id)
        
        print(f"[Gateway] Interesse registrado: user {user_id} no leilão {auction_id}")
        return jsonify({
            "message": "Interesse registrado com sucesso",
            "user_id": user_id,
            "auction_id": auction_id
        }), 201
        
    except KeyError as e:
        return jsonify({"error": f"Campo obrigatório ausente: {str(e)}"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# DELETE /interesse
# Content-Type: application/json

# {
#   "user_id": "user123",
#   "auction_id": 1
# }
@app.route('/interesse', methods=['DELETE'])
def cancelar_interesse():
    """
    Cancela interesse de um usuário em receber notificações sobre um leilão.
    Payload esperado: {"user_id": "user123", "auction_id": 1}
    """
    try:
        data = request.json
        user_id = data['user_id']
        auction_id = data['auction_id']
        
        # Remove o interesse se existir
        if auction_id in auction_interests:
            auction_interests[auction_id].discard(user_id)
            
            # Remove o conjunto se ficar vazio
            if not auction_interests[auction_id]:
                del auction_interests[auction_id]
        
        print(f"[Gateway] Interesse cancelado: user {user_id} no leilão {auction_id}")
        return jsonify({
            "message": "Interesse cancelado com sucesso",
            "user_id": user_id,
            "auction_id": auction_id
        }), 200
        
    except KeyError as e:
        return jsonify({"error": f"Campo obrigatório ausente: {str(e)}"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/interesses/<user_id>', methods=['GET'])
def listar_interesses(user_id):
    """
    Lista todos os leilões nos quais o usuário tem interesse registrado.
    """
    try:
        interesses = [
            auction_id 
            for auction_id, users in auction_interests.items() 
            if user_id in users
        ]
        
        return jsonify({
            "user_id": user_id,
            "auction_ids": interesses
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(port=5000)
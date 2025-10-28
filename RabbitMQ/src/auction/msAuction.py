import time
import sched
from datetime import datetime, timedelta
from common.rabbitmq import RabbitMQ
from common.models import Auction, Message
from common import config
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/api/leiloes', methods=['GET'])
def get_leiloes_abertos():
    leiloes_ativos = [auction.to_dict() for auction in auctions if auction.status == "active"]
    return jsonify(leiloes_ativos)

@app.route('/api/leiloes', methods=['POST'])
def criar_leilao():
    data = request.json
    novo_leilao = Auction(
        id=data['id'],
        description=data['description'],
        start_time=datetime.fromisoformat(data['start_time']),
        end_time=datetime.fromisoformat(data['end_time']),
        status="pending"
    )
    auctions.append(novo_leilao)
    return jsonify({"message": "Leilão criado", "leilao": novo_leilao.to_dict()}), 201

# Lista pré-configurada de leilões
auctions = [
    Auction(
        id=1,
        description="Notebook Gamer",
        start_time=datetime.now() + timedelta(seconds=10),
        end_time=datetime.now() + timedelta(seconds=60),
        status="pending"
    ),
    Auction(
        id=2,
        description="Smartphone novo",
        start_time=datetime.now() + timedelta(seconds=20),
        end_time=datetime.now() + timedelta(seconds=80),
        status="pending"
    )
]

def check_auctions_job(sc, rabbitmq_instance):
    """
    Função de trabalho que verifica o estado dos leilões e se re-agenda.
    """
    now = datetime.now()
    for auction in auctions:
        # Inicia o leilão se o tempo for atingido
        if auction.status == "pending" and now >= auction.start_time:
            auction.status = "active"
            message = Message(event_type="leilao_iniciado", payload=auction.to_dict())
            rabbitmq_instance.publish(exchange=config.EXCHANGE_NAME, routing_key="leilao_iniciado", body=message.to_dict())
            print(f"Leilão {auction.id} ({auction.description}) iniciado.")

        # Finaliza o leilão se o tempo expirar
        elif auction.status == "active" and now >= auction.end_time:
            auction.status = "encerrado"
            message = Message(event_type="leilao_finalizado", payload=auction.to_dict())
            rabbitmq_instance.publish(exchange=config.EXCHANGE_NAME, routing_key="leilao_finalizado", body=message.to_dict())
            print(f"Leilão {auction.id} ({auction.description}) finalizado.")

    # Re-agenda a mesma função para ser executada daqui a 1 segundo
    sc.enter(1, 1, check_auctions_job, (sc, rabbitmq_instance))

def main():
    """Função principal do microsserviço de Leilão."""
    rabbitmq = RabbitMQ()
    rabbitmq.declare_exchange(config.EXCHANGE_NAME, ex_type='direct')

    # Cria uma instância do scheduler
    scheduler = sched.scheduler(time.time, time.sleep)

    print("Microsserviço de Leilão iniciado. Verificações agendadas a cada segundo.")
    print("Pressione Ctrl+C para sair.")

    try:
        # Agenda a primeira execução da tarefa
        scheduler.enter(1, 1, check_auctions_job, (scheduler, rabbitmq))
        # Inicia o scheduler (é uma chamada bloqueante)
        scheduler.run()
    except KeyboardInterrupt:
        print("\nMicrosserviço de Leilão encerrado.")

if __name__ == '__main__':
    app.run(port=5001)
    main()
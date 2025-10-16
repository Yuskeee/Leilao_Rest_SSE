import json
import threading
import time
import os

from common.rabbitmq import RabbitMQ
from common.models import Bid, Message
from common import config

class MSPayment:
    def __init__(self):
        pass

    def listen(self):
        def _listen():
            self.rabbitmq.declare_exchange(config.EXCHANGE_NAME, ex_type="direct")
            queue_name = self.rabbitmq.declare_queue("", exclusive=True)
            for routing_key in ["leilao_vencedor"]:
                self.rabbitmq.bind_queue(
                    queue=queue_name,
                    exchange=config.EXCHANGE_NAME,
                    routing_key=routing_key
                )
            self.rabbitmq.consume(queue=queue_name, callback=self.handle_event)
        t = threading.Thread(target=_listen, daemon=True)
        t.start()


    # payload={
    #     "auction_id": auction_id,
    #     "winner_id": winner_info['user_id'],
    #     "value": winner_info['amount']
    # }

    def process_winner(self, auction_data):
        try:
            auction_id = auction_data['auction_id']
            winner_id = auction_data['winner_id']
            value = auction_data['value']

            self._request_payment(value, winner_id)
        
        except Exception as e:
            print("It was not possible to fetch the winner from the auction data: {e}")

    def _request_payment(self, value, winner_id):

        # Requisicao REST enviando os dados
        # Recebe um link de pagamento e publica em queue link_pagamento.
        pass

    def process_payment(self):
        
        pass
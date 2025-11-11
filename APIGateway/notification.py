import threading
import json
import datetime
from common.rabbitmq import RabbitMQ
from common import config
from sse import SSE, app

class MSNotification:
    def __init__(self):
        self.exchange = config.EXCHANGE_NAME
        self.rabbitmq = RabbitMQ()

    def listen(self):
        def _listen():
            self.rabbitmq.declare_exchange(self.exchange, ex_type="direct")
            queue_name = self.rabbitmq.declare_queue("", exclusive=True)
            self.rabbitmq.bind_queue(queue=queue_name, exchange=self.exchange, routing_key="lance_validado")
            self.rabbitmq.bind_queue(queue=queue_name, exchange=self.exchange, routing_key="lance_invalidado")
            self.rabbitmq.bind_queue(queue=queue_name, exchange=self.exchange, routing_key="leilao_vencedor")
            self.rabbitmq.bind_queue(queue=queue_name, exchange=self.exchange, routing_key="link_pagamento")
            self.rabbitmq.bind_queue(queue=queue_name, exchange=self.exchange, routing_key="status_pagamento")
            self.rabbitmq.consume(queue=queue_name, callback=self.handle_event)
        t = threading.Thread(target=_listen, daemon=True)
        t.start()

    def handle_event(self, ch, method, properties, body):
        try:
            data = json.loads(body.decode())
            event_type = method.routing_key
            payload = data.get("payload", {})
            # Eventos a encaminhar para SSE
            if event_type in ["lance_validado", "leilao_vencedor", "link_pagamento", "status_pagamento"]:
                self.notify_auction(payload, event_type)
        except Exception as e:
            print(f"[MSNotification] Error processing event: {e}")

    def notify_auction(self, payload, event_type):
        try:
            auction_id = payload.get('auction_id') or payload.get('id')
            if not auction_id:
                print("[MSNotification] No 'auction_id' in payload, skipping notification.")
                return
            message = {
                "event_type": event_type,
                "payload": payload,
                "timestamp": datetime.datetime.now().isoformat()
            }
            SSE.server_side_event(message, app.app_context)
            print(f"[MSNotification] Forwarded event '{event_type}' for auction '{auction_id}'.")
        except Exception as e:
            print(f"[MSNotification] Error forwarding notification: {e}")

if __name__ == "__main__":
    import time
    notification_service = MSNotification()
    notification_service.listen()
    print("[MSNotification] Service is running...")
    while True:
        time.sleep(10)

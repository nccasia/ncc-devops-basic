"""Publish N "order created" messages to the orders.created queue.

Run:
    python3 -m venv venv && ./venv/bin/pip install -r requirements.txt
    export RABBITMQ_HOST=192.168.56.11 RABBITMQ_VHOST=/training \
           RABBITMQ_USER=orders_app RABBITMQ_PASSWORD='...'
    ./venv/bin/python producer.py 10

Note: this sample does NOT configure durability yet — that is your job in step 8.
"""
import json
import os
import sys
import uuid
from datetime import datetime, timezone

import pika

QUEUE = "orders.created"


def connect() -> pika.BlockingConnection:
    params = pika.ConnectionParameters(
        host=os.environ.get("RABBITMQ_HOST", "localhost"),
        port=int(os.environ.get("RABBITMQ_PORT", "5672")),
        virtual_host=os.environ.get("RABBITMQ_VHOST", "/"),
        credentials=pika.PlainCredentials(
            os.environ["RABBITMQ_USER"], os.environ["RABBITMQ_PASSWORD"]
        ),
    )
    return pika.BlockingConnection(params)


def main() -> None:
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    conn = connect()
    channel = conn.channel()
    channel.queue_declare(queue=QUEUE)

    for i in range(1, count + 1):
        order = {
            "order_id": str(uuid.uuid4()),
            "seq": i,
            "amount": i * 10_000,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        channel.basic_publish(exchange="", routing_key=QUEUE, body=json.dumps(order))
        print(f"[producer] sent #{i} {order['order_id']}")

    conn.close()


if __name__ == "__main__":
    main()

"""Receive and "process" messages from the orders.created queue.

Run (same environment variables as producer.py):
    ./venv/bin/python consumer.py

Optional environment variables:
    PREFETCH_COUNT   max number of unacked messages the consumer holds (default 1)
    WORK_SECONDS     simulated processing time per message (default 1)
"""
import json
import os
import socket
import time

import pika

from producer import QUEUE, connect

WORKER = f"{socket.gethostname()}:{os.getpid()}"


def handle(channel, method, properties, body) -> None:
    order = json.loads(body)
    print(f"[{WORKER}] processing #{order['seq']} {order['order_id']} "
          f"(redelivered={method.redelivered})", flush=True)
    time.sleep(float(os.environ.get("WORK_SECONDS", "1")))
    channel.basic_ack(delivery_tag=method.delivery_tag)
    print(f"[{WORKER}] done #{order['seq']}", flush=True)


def main() -> None:
    conn = connect()
    channel = conn.channel()
    channel.queue_declare(queue=QUEUE)
    channel.basic_qos(prefetch_count=int(os.environ.get("PREFETCH_COUNT", "1")))
    channel.basic_consume(queue=QUEUE, on_message_callback=handle)
    print(f"[{WORKER}] waiting for messages on {QUEUE}. Ctrl+C to exit.", flush=True)
    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        channel.stop_consuming()
    finally:
        conn.close()


if __name__ == "__main__":
    main()

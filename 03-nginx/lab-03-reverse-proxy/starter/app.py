"""Sample app for the reverse proxy lab.

Run:
    python3 -m venv venv
    ./venv/bin/pip install -r requirements.txt
    ./venv/bin/python app.py
"""
import os
import socket
import time

from flask import Flask, jsonify, request

app = Flask(__name__)


@app.get("/")
def index():
    return f"""<!doctype html>
<html>
  <head><meta charset="utf-8"><title>Site 3</title></head>
  <body>
    <h1>Hello from app on port 3000</h1>
    <p>Hostname: {socket.gethostname()} · Port: {os.getenv("APP_PORT", "3000")}</p>
    <p>See received headers at <a href="/headers">/headers</a></p>
  </body>
</html>"""


@app.get("/headers")
def headers():
    """Return what the app received, to verify proxy headers."""
    return jsonify(
        remote_addr=request.remote_addr,
        host=request.host,
        scheme=request.scheme,
        headers=dict(request.headers),
    )


@app.get("/slow")
def slow():
    """Sleep N seconds to reproduce a 504 Gateway Timeout."""
    seconds = min(int(request.args.get("seconds", 10)), 120)
    time.sleep(seconds)
    return jsonify(slept=seconds)


@app.get("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host=os.getenv("APP_HOST", "127.0.0.1"), port=int(os.getenv("APP_PORT", "3000")))

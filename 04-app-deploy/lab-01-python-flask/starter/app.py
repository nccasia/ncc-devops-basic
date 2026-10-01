"""Employees API — Flask.

Run locally (dev):
    python3 -m venv venv
    ./venv/bin/pip install -r requirements.txt
    set -a; . ./app.env.example; set +a
    ./venv/bin/flask --app app run --port 5000

Run in production: use gunicorn (see the lab README).
"""
import os

import psycopg
from flask import Flask, jsonify
from psycopg.rows import dict_row

app = Flask(__name__)


def get_conn():
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
        row_factory=dict_row,
    )


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/api/employees")
def list_employees():
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT e.id, e.full_name, e.email, COALESCE(d.name, '') AS department FROM employees e LEFT JOIN departments d ON d.id = e.department_id ORDER BY e.id"
        ).fetchall()
    return jsonify(rows)


@app.errorhandler(psycopg.OperationalError)
def db_unavailable(err):
    app.logger.error("Database error: %s", err)
    return jsonify(error="database unavailable"), 503

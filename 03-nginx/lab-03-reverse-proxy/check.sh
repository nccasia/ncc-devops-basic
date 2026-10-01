#!/usr/bin/env bash
# Check lab 03 — run on vm3 (client) while the sample app starter/app.py runs on the server.
# Usage: ./check.sh [server-ip]   (default 192.168.56.12)
set -euo pipefail

SERVER="${1:-192.168.56.12}"
CLIENT_IP="$(ip -4 route get "$SERVER" | grep -oP 'src \K[0-9.]+' || true)"
fail=0

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS  $desc"
  else
    echo "FAIL  $desc"
    fail=1
  fi
}

check "site3.local returns the port 3000 app content" bash -c "curl -s --max-time 5 http://site3.local/ | grep -q 'port 3000'"
check "Port 3000 is not directly reachable from the client" bash -c "! curl -s --max-time 3 http://$SERVER:3000/"
check "Backend receives X-Real-IP = client IP ($CLIENT_IP)" \
  bash -c "curl -s --max-time 5 http://site3.local/headers | grep -q '\"X-Real-Ip\": *\"$CLIENT_IP\"'"
check "Backend receives X-Forwarded-For" bash -c "curl -s --max-time 5 http://site3.local/headers | grep -q 'X-Forwarded-For'"
check "Backend receives Host = site3.local" bash -c "curl -s --max-time 5 http://site3.local/headers | grep -q '\"host\": *\"site3.local\"'"

[ "$fail" -eq 0 ] && echo "==> All checks PASSED" || { echo "==> Some checks FAILED"; exit 1; }

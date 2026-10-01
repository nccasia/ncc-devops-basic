#!/usr/bin/env bash
# Shared check for labs 01..03 of module 04.
# Run on the server (vm2) so both the service and the endpoints can be checked.
# Usage: ./check.sh <base-url> <systemd-service> <app-port>
#   VD: ./check.sh http://flask.training.local flaskapp 5000
set -euo pipefail

BASE_URL="${1:?Missing base-url, e.g. http://flask.training.local}"
SERVICE="${2:?Missing systemd service name, e.g. flaskapp}"
PORT="${3:?Missing app port, e.g. 5000}"
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

check "Service $SERVICE is active"   systemctl is-active --quiet "$SERVICE"
check "Service $SERVICE enable khi boot" systemctl is-enabled --quiet "$SERVICE"
check "Service does not run as root" \
  bash -c "pid=\$(systemctl show -p MainPID --value $SERVICE); [ \"\$pid\" != 0 ] && [ \"\$(ps -o user= -p \$pid)\" != root ]"
check "Service uses EnvironmentFile" bash -c "systemctl cat $SERVICE | grep -q '^EnvironmentFile='"
check "App only listens on 127.0.0.1:$PORT" \
  bash -c "ss -tlnH | awk '{print \$4}' | grep -qE '^(127\\.0\\.0\\.1|\\[::1\\]):$PORT\$' && ! ss -tlnH | awk '{print \$4}' | grep -qE '^(0\\.0\\.0\\.0|\\*|\\[::\\]):$PORT\$'"
check "GET /health returns status ok via Nginx" bash -c "curl -sf --max-time 5 $BASE_URL/health | grep -q '\"status\" *: *\"ok\"'"
check "GET /api/employees returns the list from DB" bash -c "curl -sf --max-time 5 $BASE_URL/api/employees | grep -q '@'"
check "Response goes through Nginx (Server header)" bash -c "curl -sI --max-time 5 $BASE_URL/health | grep -qi '^server: nginx'"

[ "$fail" -eq 0 ] && echo "==> All PASS" || { echo "==> Some checks FAILED"; exit 1; }

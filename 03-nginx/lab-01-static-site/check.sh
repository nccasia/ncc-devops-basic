#!/usr/bin/env bash
# Check lab 01 — run from a client (vm3 or a host machine with bash).
# Usage: ./check.sh [server-ip]   (default 192.168.56.12)
set -euo pipefail

SERVER="${1:-192.168.56.12}"
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

status_of() { curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$1"; }

check "Home page returns 200"        test "$(status_of "http://$SERVER/")" = "200"
check "about.html returns 200"       test "$(status_of "http://$SERVER/about.html")" = "200"
check "CSS returns 200"              test "$(status_of "http://$SERVER/css/style.css")" = "200"
check "Missing page returns 404"     test "$(status_of "http://$SERVER/does-not-exist-$RANDOM")" = "404"
check "404 page is a custom page (not the nginx default)" \
  bash -c "! curl -s --max-time 5 'http://$SERVER/does-not-exist' | grep -q '<center>nginx'"

[ "$fail" -eq 0 ] && echo "==> All checks PASSED" || { echo "==> Some checks FAILED"; exit 1; }

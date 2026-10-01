#!/usr/bin/env bash
# Check lab 02 — run on vm3 (client configured to use the private DNS).
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

check "site1.local resolves to $SERVER" bash -c "getent hosts site1.local | grep -q '$SERVER'"
check "site2.local resolves to $SERVER" bash -c "getent hosts site2.local | grep -q '$SERVER'"
check "site1.local is not from /etc/hosts (uses DNS)" bash -c "! grep -qE '\\bsite1\\.local\\b' /etc/hosts"
check "site1.local shows 'Welcome to Site 1'" bash -c "curl -s --max-time 5 http://site1.local/ | grep -q 'Welcome to Site 1'"
check "site2.local shows 'Welcome to Site 2'" bash -c "curl -s --max-time 5 http://site2.local/ | grep -q 'Welcome to Site 2'"
check "Unknown Host does not fall into site1/site2" \
  bash -c "! curl -s --max-time 5 -H 'Host: unknown.example' http://$SERVER/ | grep -qE 'Welcome to Site (1|2)'"
check "Access by IP does not fall into site1/site2" \
  bash -c "! curl -s --max-time 5 http://$SERVER/ | grep -qE 'Welcome to Site (1|2)'"

[ "$fail" -eq 0 ] && echo "==> All checks PASSED" || { echo "==> Some checks FAILED"; exit 1; }

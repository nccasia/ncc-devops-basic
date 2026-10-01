#!/usr/bin/env bash
# Check lab 04 — run on vm3 (client already trusts the private CA).
# Usage: ./check.sh [domain]   (default app.training.local)
set -euo pipefail

DOMAIN="${1:-app.training.local}"
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

check "Valid HTTPS without -k" curl -sf --max-time 5 "https://$DOMAIN/"
check "HTTP redirect 301 sang HTTPS" \
  bash -c "curl -sI --max-time 5 http://$DOMAIN/ | grep -qiE '^HTTP/[0-9.]+ 301' && curl -sI --max-time 5 http://$DOMAIN/ | grep -qi '^location: https://'"
check "/api/headers returns JSON from the backend" bash -c "curl -sf --max-time 5 https://$DOMAIN/api/headers | grep -q 'headers'"
check "Backend receives X-Forwarded-Proto: https" \
  bash -c "curl -sf --max-time 5 https://$DOMAIN/api/headers | grep -qi '\"X-Forwarded-Proto\": *\"https\"'"
check "Certificate SAN contains $DOMAIN" \
  bash -c "echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -ext subjectAltName | grep -q 'DNS:$DOMAIN'"
check "TLS 1.3 is supported" \
  bash -c "echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN -tls1_3 2>/dev/null | grep -q 'TLSv1.3'"
check "TLS 1.1 is rejected" \
  bash -c "! echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN -tls1_1 -cipher DEFAULT@SECLEVEL=0 2>/dev/null | grep -q 'Cipher is [A-Z]'"
check "Strict-Transport-Security header is present" bash -c "curl -sI --max-time 5 https://$DOMAIN/ | grep -qi '^strict-transport-security'"

[ "$fail" -eq 0 ] && echo "==> All checks PASSED" || { echo "==> Some checks FAILED"; exit 1; }

#!/usr/bin/env bash
# Check lab-03: run on vm2 (must connect) and vm3 (must be blocked).
#
# Usage:
#   export PGPASSWORD='...'            # usertest2's password, never hardcode it in the script
#   ./check.sh [-h host] [-p port] [-U user] [-d db] [-e allow|deny]
#
# -e: expected result. Defaults by host IP: 192.168.56.12 -> allow, 192.168.56.13 -> deny.
set -euo pipefail

HOST=192.168.56.11
PORT=5432
DB_USER=usertest2
DB_NAME=trainingdb
EXPECT=""
FAIL=0

pass() { echo -e "\e[32mPASS\e[0m $1"; }
fail() { echo -e "\e[31mFAIL\e[0m $1"; FAIL=1; }
info() { echo -e "\e[33mINFO\e[0m $1"; }

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while getopts "h:p:U:d:e:" opt; do
  case $opt in
    h) HOST=$OPTARG ;;
    p) PORT=$OPTARG ;;
    U) DB_USER=$OPTARG ;;
    d) DB_NAME=$OPTARG ;;
    e) EXPECT=$OPTARG ;;
    *) usage ;;
  esac
done

command -v psql >/dev/null || { echo "psql is not installed: sudo apt-get install -y postgresql-client" >&2; exit 2; }

MY_IPS=$(hostname -I)
if [[ -z $EXPECT ]]; then
  if   [[ " $MY_IPS " == *" 192.168.56.12 "* ]]; then EXPECT=allow
  elif [[ " $MY_IPS " == *" 192.168.56.13 "* ]]; then EXPECT=deny
  else
    echo "Cannot detect host role (IP: $MY_IPS). Pass -e allow or -e deny." >&2
    exit 2
  fi
fi
[[ $EXPECT == allow || $EXPECT == deny ]] || usage

info "Current host: $(hostname) [$MY_IPS]"
info "Checking $DB_USER@$HOST:$PORT/$DB_NAME — expected: $EXPECT"
[[ -n ${PGPASSWORD:-} ]] || info "PGPASSWORD is not set (psql will use ~/.pgpass if present)"

# --- Network layer: TCP connect ---
TCP_ERR=$(timeout 5 bash -c "exec 3<>/dev/tcp/$HOST/$PORT" 2>&1) && TCP=open || {
  rc=$?
  if [[ $rc -eq 124 ]]; then TCP=timeout
  elif [[ $TCP_ERR == *"refused"* ]]; then TCP=refused
  else TCP="error: $TCP_ERR"
  fi
}
info "TCP $HOST:$PORT -> $TCP"

# --- PostgreSQL layer: login + SELECT ---
PSQL_OUT=""
PSQL_OK=0
if [[ $TCP == open ]]; then
  if PSQL_OUT=$(PGCONNECT_TIMEOUT=5 psql -h "$HOST" -p "$PORT" -U "$DB_USER" -d "$DB_NAME" \
        -w -X -At -c 'SELECT count(*) FROM employees;' 2>&1); then
    PSQL_OK=1
  fi
  info "psql -> $(echo "$PSQL_OUT" | head -n 2 | tr '\n' ' ')"
fi

# Classify the blocking layer
if [[ $TCP == timeout ]]; then
  LAYER="network (firewall/security group drops packets)"
elif [[ $TCP == refused ]]; then
  LAYER="network (nothing listening / listen_addresses / firewall reject)"
elif [[ $PSQL_OK -eq 1 ]]; then
  LAYER="not blocked"
elif [[ $PSQL_OUT == *"pg_hba.conf"* ]]; then
  LAYER="pg_hba.conf"
elif [[ $PSQL_OUT == *"password authentication failed"* || $PSQL_OUT == *"no password supplied"* ]]; then
  LAYER="password (pg_hba.conf DOES allow this host, password is wrong/missing)"
elif [[ $PSQL_OUT == *"permission denied"* ]]; then
  LAYER="database privileges (login succeeded)"
else
  LAYER="other"
fi
info "Blocking layer: $LAYER"

echo "== Result =="
if [[ $EXPECT == allow ]]; then
  if [[ $PSQL_OK -eq 1 ]]; then
    pass "connected and SELECT works (employees: $PSQL_OUT rows)"
  else
    fail "must be able to connect and SELECT from this host"
  fi
  if [[ $PSQL_OK -eq 1 ]]; then
    if PGCONNECT_TIMEOUT=5 psql -h "$HOST" -p "$PORT" -U "$DB_USER" -d "$DB_NAME" -w -X -At \
         -c "INSERT INTO departments(name) VALUES ('chk_$$');" >/dev/null 2>&1; then
      fail "$DB_USER must NOT be able to INSERT (user must be read-only)"
    else
      pass "$DB_USER cannot INSERT (read-only)"
    fi
  fi
else
  case $LAYER in
    network*|pg_hba.conf)
      pass "blocked at layer: $LAYER" ;;
    password*)
      fail "still reaches password authentication — pg_hba.conf does not block this host" ;;
    *)
      fail "must be blocked from this host (current layer: $LAYER)" ;;
  esac
fi

if [[ $FAIL -ne 0 ]]; then
  echo -e "\n\e[31mSome checks FAILED\e[0m"
  exit 1
fi
echo -e "\n\e[32mAll checks PASSED\e[0m"

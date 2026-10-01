#!/usr/bin/env bash
# Create users/groups for lab-01 (idempotent - safe to re-run)
# Usage: sudo ./setup.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Must be run with sudo: sudo $0" >&2
  exit 1
fi

for g in developers testers; do
  if getent group "$g" >/dev/null; then
    echo "[skip] group $g already exists"
  else
    groupadd "$g" && echo "[ok]   created group $g"
  fi
done

for u in john mary; do
  if id "$u" >/dev/null 2>&1; then
    echo "[skip] user $u already exists"
  else
    useradd -m -s /bin/bash "$u" && echo "[ok]   created user $u"
  fi
done

usermod -aG developers john
usermod -aG testers mary
echo "[ok]   john -> developers, mary -> testers"

# John creates project.txt
if [[ ! -f /home/john/project.txt ]]; then
  sudo -u john bash -c 'cd ~ && touch project.txt && echo "Hello World" > project.txt'
  echo "[ok]   created /home/john/project.txt"
fi

id john
id mary

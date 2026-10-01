#!/usr/bin/env bash
# Check lab-03 results (run after revoking bob's access and restoring ACLs).
# Usage: sudo ./check.sh
set -euo pipefail

BASE=/projects/web
FAIL=0
TAG="chk_$$"

pass() { echo -e "\e[32mPASS\e[0m $1"; }
fail() { echo -e "\e[31mFAIL\e[0m $1"; FAIL=1; }
check() { local desc=$1; shift; if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi; }
check_not() { local desc=$1; shift; if "$@" >/dev/null 2>&1; then fail "$desc"; else pass "$desc"; fi; }
as() { local u=$1; shift; sudo -u "$u" bash -c "$*"; }

if [[ $EUID -ne 0 ]]; then
  echo "Must be run with sudo: sudo $0" >&2
  exit 2
fi

cleanup() { find "$BASE" -name "${TAG}*" -exec rm -rf {} + 2>/dev/null || true; }
trap cleanup EXIT

command -v getfacl >/dev/null || { fail "acl package is installed"; exit 1; }
for u in john mary alice bob; do
  id "$u" >/dev/null 2>&1 || { fail "user $u exists"; exit 1; }
done

echo "== alice: read-only on public & private (old and new files) =="
for d in public private; do
  as john "umask 077; echo secret > $BASE/$d/${TAG}_new.txt" || fail "john can create a file in $d"
  check     "alice can list $d"           as alice "ls $BASE/$d"
  check     "alice can read NEW files in $d" as alice "cat $BASE/$d/${TAG}_new.txt"
  check_not "alice can NOT write files in $d" as alice "echo x >> $BASE/$d/${TAG}_new.txt"
  check_not "alice can NOT create files in $d" as alice "touch $BASE/$d/${TAG}_alice"
done
if [[ -f $BASE/private/report.txt ]]; then
  check "alice can read private/report.txt" as alice "cat $BASE/private/report.txt"
else
  fail "$BASE/private/report.txt exists"
fi

echo "== bob: access revoked =="
BOB_ENTRIES=$(getfacl -R -p /projects 2>/dev/null | grep -c 'user:bob:' || true)
check     "no user:bob entries left in /projects (found: $BOB_ENTRIES)" test "$BOB_ENTRIES" -eq 0
check_not "bob can NOT read report.txt"  as bob "cat $BASE/private/report.txt"
check_not "bob can NOT write report.txt"  as bob "echo x >> $BASE/private/report.txt"

echo "== testers: can write public/uploads, read-only on public =="
if [[ -d $BASE/public/uploads ]]; then
  check     "mary can create files in public/uploads" as mary "touch $BASE/public/uploads/${TAG}_up"
  check     "mary can delete her own files in uploads" as mary "rm $BASE/public/uploads/${TAG}_up"
else
  fail "$BASE/public/uploads exists"
fi
check_not "mary can NOT create files in public" as mary "touch $BASE/public/${TAG}_mary"

echo "== Default ACLs exist for future files =="
check "public has a default ACL for alice"  bash -c "getfacl -p $BASE/public  | grep -q '^default:user:alice:r'"
check "private has a default ACL for alice" bash -c "getfacl -p $BASE/private | grep -q '^default:user:alice:r'"

echo "== Objects with extended ACLs =="
getfacl -R -s -p /projects 2>/dev/null | grep '^# file:' || true

if [[ $FAIL -ne 0 ]]; then
  echo -e "\n\e[31mSome checks FAILED\e[0m"
  exit 1
fi
echo -e "\n\e[32mAll checks PASSED\e[0m"

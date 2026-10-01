#!/usr/bin/env bash
# Check lab-02 results. Usage: sudo ./check.sh
# Creates temporary users chk_dev (developers) and chk_other to test access; cleaned up on exit.
set -euo pipefail

BASE=/projects/web
FAIL=0
TAG="chk_$$"

pass() { echo -e "\e[32mPASS\e[0m $1"; }
fail() { echo -e "\e[31mFAIL\e[0m $1"; FAIL=1; }
info() { echo -e "\e[33mINFO\e[0m $1"; }
check() { local desc=$1; shift; if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi; }
check_not() { local desc=$1; shift; if "$@" >/dev/null 2>&1; then fail "$desc"; else pass "$desc"; fi; }
as() { local u=$1; shift; sudo -u "$u" bash -c "$*"; }

if [[ $EUID -ne 0 ]]; then
  echo "Must be run with sudo: sudo $0" >&2
  exit 2
fi

cleanup() {
  find "$BASE" -name "${TAG}*" -exec rm -rf {} + 2>/dev/null || true
  userdel chk_dev >/dev/null 2>&1 || true
  userdel chk_other >/dev/null 2>&1 || true
}
trap cleanup EXIT

for d in "$BASE" "$BASE/public" "$BASE/private" "$BASE/config"; do
  [[ -d $d ]] || { fail "$d exists"; exit 1; }
done
for u in john mary; do id "$u" >/dev/null 2>&1 || { fail "user $u exists (run lab-01/setup.sh)"; exit 1; }; done

userdel chk_dev >/dev/null 2>&1 || true; userdel chk_other >/dev/null 2>&1 || true
useradd -M -s /bin/bash -G developers chk_dev
useradd -M -s /bin/bash chk_other

echo "== Group owner & SGID =="
for d in "$BASE" "$BASE/public" "$BASE/private"; do
  check "$d has group developers" test "$(stat -c %G "$d")" = developers
  check "$d has SGID"             test -g "$d"
done

echo "== Developers have full access =="
for d in public private; do
  check "chk_dev can create files in $d"  as chk_dev "echo hi > $BASE/$d/${TAG}_dev.txt"
  check "chk_dev can modify files in $d"  as chk_dev "echo more >> $BASE/$d/${TAG}_dev.txt"
  check "chk_dev can delete files in $d"  as chk_dev "rm $BASE/$d/${TAG}_dev.txt"
done

echo "== Testers have read & execute only =="
as john "echo data > $BASE/public/${TAG}_r.txt" || fail "john can create a file in public"
check     "mary can list public"    as mary "ls $BASE/public"
check     "mary can read files"          as mary "cat $BASE/public/${TAG}_r.txt"
check_not "mary can NOT create files"    as mary "touch $BASE/public/${TAG}_mary.txt"
check_not "mary can NOT delete files"    as mary "rm -f $BASE/public/${TAG}_r.txt"
check_not "mary can NOT modify files"    as mary "echo x >> $BASE/public/${TAG}_r.txt"

echo "== Permission inheritance (creator uses umask 077) =="
as john "umask 077; echo new > $BASE/private/${TAG}_inherit.txt; mkdir $BASE/private/${TAG}_dir" || fail "john (umask 077) can create files/dirs in private"
F="$BASE/private/${TAG}_inherit.txt"
D="$BASE/private/${TAG}_dir"
check "new file has group developers"          test "$(stat -c %G "$F")" = developers
check "new dir has group developers"       test "$(stat -c %G "$D")" = developers
check "new dir also has SGID"              test -g "$D"
check "another developer can write the new file"      as chk_dev "echo x >> $F"
check "mary can read the new file"                as mary "cat $F"
check "another developer can create files in the new dir" as chk_dev "touch $D/${TAG}_x"

echo "== config/ is owner-only =="
OWNER=$(stat -c %U "$BASE/config")
info "owner of config/: $OWNER"
check     "owner ($OWNER) can access config/"   as "$OWNER" "ls $BASE/config"
if [[ $OWNER != chk_dev ]]; then
  check_not "another developer can NOT access config/" as chk_dev "ls $BASE/config"
fi
check_not "mary can NOT access config/"       as mary "ls $BASE/config"

echo "== Others =="
check_not "others can NOT list $BASE"   as chk_other "ls $BASE"
check_not "others can NOT read files"        as chk_other "cat $BASE/public/${TAG}_r.txt"

echo "== ⭐ Sticky bit on public (optional) =="
if [[ -k $BASE/public ]]; then
  if as chk_dev "rm -f $BASE/public/${TAG}_r.txt" 2>/dev/null && [[ ! -e $BASE/public/${TAG}_r.txt ]]; then
    info "sticky bit is set but another developer can still delete john's file"
  else
    info "sticky bit works: another developer cannot delete john's file"
  fi
else
  info "public/ has no sticky bit"
fi

if [[ $FAIL -ne 0 ]]; then
  echo -e "\n\e[31mSome checks FAILED\e[0m"
  exit 1
fi
echo -e "\n\e[32mAll checks PASSED\e[0m"

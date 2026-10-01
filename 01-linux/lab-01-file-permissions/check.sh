#!/usr/bin/env bash
# Check lab-01 results. Usage: sudo ./check.sh
# Creates 2 temporary users (chk_dev in developers, chk_other) to test access; removed on exit.
set -euo pipefail

FILE=/home/john/project.txt
FAIL=0

pass() { echo -e "\e[32mPASS\e[0m $1"; }
fail() { echo -e "\e[31mFAIL\e[0m $1"; FAIL=1; }
check() { local desc=$1; shift; if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi; }
check_not() { local desc=$1; shift; if "$@" >/dev/null 2>&1; then fail "$desc"; else pass "$desc"; fi; }

if [[ $EUID -ne 0 ]]; then
  echo "Must be run with sudo: sudo $0" >&2
  exit 2
fi

cleanup() { userdel -r chk_dev >/dev/null 2>&1 || true; userdel -r chk_other >/dev/null 2>&1 || true; }
trap cleanup EXIT

in_group() { id -nG "$1" | tr ' ' '\n' | grep -qx "$2"; }

echo "== User & group =="
check     "user john exists"            id john
check     "user mary exists"            id mary
check     "john is in developers"       in_group john developers
check     "mary is in testers"          in_group mary testers
check_not "mary is NOT in developers"   in_group mary developers

echo "== File =="
if [[ ! -f $FILE ]]; then
  fail "$FILE exists"
  exit 1
fi
check "owner is john"       test "$(stat -c %U "$FILE")" = john
check "group is developers" test "$(stat -c %G "$FILE")" = developers
check "content is 'Hello World'" grep -qx "Hello World" "$FILE"

cleanup
useradd -M -s /bin/bash -G developers chk_dev
useradd -M -s /bin/bash chk_other

echo "== Real access tests =="
check     "mary can read"                     sudo -u mary cat "$FILE"
check_not "mary can NOT write"                sudo -u mary sh -c "printf '' >> '$FILE'"
check     "developers members can write"      sudo -u chk_dev sh -c "printf '' >> '$FILE'"
check_not "others can NOT read"               sudo -u chk_other cat "$FILE"
check     "john can read & write"             sudo -u john sh -c "cat '$FILE' && printf '' >> '$FILE'"

echo "== /home/john directory permissions =="
OTHER_PERM=$(stat -c %A /home/john | cut -c8-10)
check "others have no r/w on /home/john (current: $OTHER_PERM)" test "${OTHER_PERM:0:2}" = "--"

echo "== Current permissions =="
ls -l "$FILE"
getfacl -p "$FILE" 2>/dev/null || true

if [[ $FAIL -ne 0 ]]; then
  echo -e "\n\e[31mSome checks FAILED\e[0m"
  exit 1
fi
echo -e "\n\e[32mAll checks PASSED\e[0m"

#!/usr/bin/env bash
# update.sh 의 semver_lt 함수가 pre-release suffix 버전에서 crash 없이 동작하는지 검증
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE_SH="$ROOT/update.sh"

[ -f "$UPDATE_SH" ] || { echo "✗ update.sh 없음: $UPDATE_SH"; exit 1; }

# update.sh 는 source 시 uninstall/install 부작용이 있으므로 semver_lt 함수만 추출해 로드
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
awk '/^semver_lt[[:space:]]*\(\)[[:space:]]*\{/,/^\}/' "$UPDATE_SH" > "$TMP"
[ -s "$TMP" ] || { echo "✗ semver_lt 함수 추출 실패"; exit 1; }
# shellcheck disable=SC1090
source "$TMP"

echo "=== test-update-semver (spec-x-update-semver-suffix-fix) ==="

pass=0
fail=0

# semver_lt NEW PREV → expected 종료코드 (0 = less, 1 = not-less)
check() {
  local new="$1" prev="$2" expected="$3" desc="$4" actual
  if semver_lt "$new" "$prev"; then actual=0; else actual=1; fi
  if [ "$actual" = "$expected" ]; then
    printf "  ✅ PASS: %s\n" "$desc"
    pass=$((pass + 1))
  else
    printf "  ❌ FAIL: %s (got=%s want=%s)\n" "$desc" "$actual" "$expected"
    fail=$((fail + 1))
  fi
}

check 0.15.0       0.16.0       0 "정상: 0.15.0 < 0.16.0"
check 0.16.0       0.15.0       1 "정상: 0.16.0 > 0.15.0"
check 0.15.0       0.15.0       1 "정상: 동일 버전"
check 0.15.0-leo.1 0.15.0-leo.1 1 "suffix 동일 — crash 없이 not-less"
check 0.15.0-leo.1 0.16.0-leo.1 0 "suffix 무시 — MINOR 작음"
check 0.16.0-leo.1 0.15.0       1 "suffix 무시 — MINOR 큼"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  결과: PASS=$pass  FAIL=$fail"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ "$fail" -eq 0 ]

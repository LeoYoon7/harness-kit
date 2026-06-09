#!/usr/bin/env bash
# spec-x-sdd-robustness-fixes: sdd_ship_scope 단위 검증
# Bug 1 회귀 — ship 커밋 subject scope 가 spec-x slug 을 truncate 하면 안 됨.
#   spec-x-{slug}        → 전체 id (truncate 금지)
#   spec-{N}-{seq}-{slug} → 첫 3필드 (spec-{N}-{seq})
# 소스 가드(`[ "${BASH_SOURCE[0]}" = "$0" ]`) 덕에 source 시 main 미실행이어야 함.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SDD="$ROOT/sources/bin/sdd"

PASS=0; FAIL=0
ok()  { echo "  PASS: $*"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $*"; FAIL=$((FAIL + 1)); }

echo "=== test-sdd-ship-scope ==="

# sdd 를 source. 소스 가드가 있으면 main 미실행, 없으면(미수정 상태) main 출력 억제.
# shellcheck disable=SC1090
source "$SDD" >/dev/null 2>&1 || true
set +e  # 소싱이 가져온 옵션 영향 차단 — 테스트가 흐름 제어

if ! type sdd_ship_scope >/dev/null 2>&1; then
  bad "sdd_ship_scope 미정의 (헬퍼 + 소스 가드 필요)"
  echo "=== 결과: PASS=$PASS FAIL=$FAIL ==="
  exit 1
fi

check() {  # check <input> <expected>
  local got
  got="$(sdd_ship_scope "$1")"
  if [ "$got" = "$2" ]; then ok "$1 → $got"; else bad "$1 → '$got' (기대 '$2')"; fi
}

# spec-x: 전체 id 보존 (truncate 금지)
check "spec-x-review-b1-default" "spec-x-review-b1-default"
check "spec-x-a-b-c"             "spec-x-a-b-c"
check "spec-x-single"            "spec-x-single"
# 일반 spec: 첫 3필드
check "spec-08-01-foo"           "spec-08-01"
check "spec-1-02-bar-baz"        "spec-1-02"

echo "=== 결과: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ] || exit 1

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

echo "=== test-sdd-ship-scope ==="

# sdd 를 source. 소스 가드가 있으면 main 미실행, 없으면(미수정) main 출력 억제.
# 주의: sdd/common.sh 가 ok()/fail() 등을 정의하므로, 테스트 헬퍼는 source *이후* 고유 이름으로 정의.
# shellcheck disable=SC1090
source "$SDD" >/dev/null 2>&1 || true
set +e

T_PASS=0; T_FAIL=0
t_ok()  { echo "  PASS: $*"; T_PASS=$((T_PASS + 1)); }
t_bad() { echo "  FAIL: $*"; T_FAIL=$((T_FAIL + 1)); }

if ! type sdd_ship_scope >/dev/null 2>&1; then
  t_bad "sdd_ship_scope 미정의 (헬퍼 + 소스 가드 필요)"
  echo "=== 결과: PASS=$T_PASS FAIL=$T_FAIL ==="
  exit 1
fi

t_check() {  # t_check <input> <expected>
  local got
  got="$(sdd_ship_scope "$1")"
  if [ "$got" = "$2" ]; then t_ok "$1 → $got"; else t_bad "$1 → '$got' (기대 '$2')"; fi
}

# spec-x: 전체 id 보존 (truncate 금지)
t_check "spec-x-review-b1-default" "spec-x-review-b1-default"
t_check "spec-x-a-b-c"             "spec-x-a-b-c"
t_check "spec-x-single"            "spec-x-single"
# 일반 spec: 첫 3필드
t_check "spec-08-01-foo"           "spec-08-01"
t_check "spec-1-02-bar-baz"        "spec-1-02"

echo "=== 결과: PASS=$T_PASS FAIL=$T_FAIL ==="
[ "$T_FAIL" -eq 0 ] || exit 1

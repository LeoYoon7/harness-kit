#!/usr/bin/env bash
# tests/test-sdd-config.sh
# spec-x-governance-ask-user-guideline: sdd config ux-mode 커맨드 검증
# spec-x-review-base-config: sdd config default-branch 검증 (T7~T10)
#
# 4 시나리오:
#   T1: sdd config ux-mode text        → installed.json uxMode=text 갱신
#   T2: sdd config ux-mode interactive → installed.json uxMode=interactive 갱신
#   T3: sdd config ux-mode (인자 없음) → 현재 설정 출력
#   T4: 잘못된 값                       → 오류 메시지 출력

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB="$SCRIPT_DIR/lib/fixture.sh"
SDD="$ROOT/sources/bin/sdd"

PASS=0; FAIL=0
ok()   { echo "  ✅ PASS: $*"; PASS=$(( PASS + 1 )); }
fail() { echo "  ❌ FAIL: $*"; FAIL=$(( FAIL + 1 )); }

echo "=== test-sdd-config ==="

if [ ! -f "$LIB" ]; then
  fail "tests/lib/fixture.sh 없음"
  exit 1
fi
if [ ! -f "$SDD" ]; then
  fail "sources/bin/sdd 없음"
  exit 1
fi

source "$LIB"

FIXTURES_TO_CLEAN=()
cleanup() {
  local d
  for d in "${FIXTURES_TO_CLEAN[@]:-}"; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
  done
}
trap cleanup EXIT

run_sdd() {
  local fx="$1"; shift
  ( cd "$fx" && HARNESS_DRIFT_FETCH=0 bash "$SDD" "$@" 2>&1 )
}

get_ux_mode() {
  local fx="$1"
  jq -r '.uxMode // empty' "$fx/.harness-kit/installed.json" 2>/dev/null || echo ""
}

# ─────────────────────────────────────────────────────────
# T1: sdd config ux-mode text → installed.json uxMode=text
# ─────────────────────────────────────────────────────────
echo ""
echo "T1: sdd config ux-mode text → installed.json uxMode=text"
F1=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F1")

run_sdd "$F1" config ux-mode text >/dev/null
ACTUAL=$(get_ux_mode "$F1")
if [ "$ACTUAL" = "text" ]; then
  ok "installed.json uxMode=text 갱신됨"
else
  fail "uxMode 갱신 실패 — 예상: text, 실제: $ACTUAL"
fi

# ─────────────────────────────────────────────────────────
# T2: sdd config ux-mode interactive → uxMode=interactive
# ─────────────────────────────────────────────────────────
echo ""
echo "T2: sdd config ux-mode interactive → uxMode=interactive"
F2=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F2")

# 먼저 text로 설정 후 interactive로 복원
run_sdd "$F2" config ux-mode text >/dev/null
run_sdd "$F2" config ux-mode interactive >/dev/null
ACTUAL2=$(get_ux_mode "$F2")
if [ "$ACTUAL2" = "interactive" ]; then
  ok "installed.json uxMode=interactive 복원됨"
else
  fail "uxMode 복원 실패 — 예상: interactive, 실제: $ACTUAL2"
fi

# ─────────────────────────────────────────────────────────
# T3: sdd config ux-mode (인자 없음) → 현재 설정 출력
# ─────────────────────────────────────────────────────────
echo ""
echo "T3: sdd config ux-mode (인자 없음) → 현재값 출력"
F3=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F3")

# uxMode=text 로 설정 후 인자 없이 호출
run_sdd "$F3" config ux-mode text >/dev/null
OUT3=$(run_sdd "$F3" config ux-mode)
if echo "$OUT3" | grep -qE "text"; then
  ok "현재 uxMode 출력됨: $OUT3"
else
  fail "현재 uxMode 출력 실패 — 실제: $OUT3"
fi

# ─────────────────────────────────────────────────────────
# T4: 잘못된 값 → 오류 메시지
# ─────────────────────────────────────────────────────────
echo ""
echo "T4: sdd config ux-mode invalid → 오류 출력"
F4=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F4")

OUT4=$(run_sdd "$F4" config ux-mode invalid 2>&1 || true)
if echo "$OUT4" | grep -qiE "invalid|error|오류|허용|interactive|text"; then
  ok "잘못된 값에 오류 메시지 출력"
else
  fail "오류 메시지 누락 — 실제: $OUT4"
fi

# ─────────────────────────────────────────────────────────
# T5: sdd config ux-mode toggle → 현재값 자동 반전
# ─────────────────────────────────────────────────────────
echo ""
echo "T5: sdd config ux-mode toggle → 현재값 자동 반전"
F5=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F5")

# 초기 상태: interactive (fixture 기본값) → toggle → text 가 되어야 함
run_sdd "$F5" config ux-mode interactive >/dev/null
OUT5A=$(run_sdd "$F5" config ux-mode toggle 2>&1)
ACTUAL5A=$(get_ux_mode "$F5")
if [ "$ACTUAL5A" = "text" ] && echo "$OUT5A" | grep -q "text"; then
  ok "toggle: interactive → text 반전 + 출력에 새 값 포함"
else
  fail "toggle interactive→text 실패 — installed: $ACTUAL5A, 출력: $OUT5A"
fi

# 한 번 더 toggle → interactive 복원
OUT5B=$(run_sdd "$F5" config ux-mode toggle 2>&1)
ACTUAL5B=$(get_ux_mode "$F5")
if [ "$ACTUAL5B" = "interactive" ] && echo "$OUT5B" | grep -q "interactive"; then
  ok "toggle: text → interactive 복원 + 출력에 새 값 포함"
else
  fail "toggle text→interactive 실패 — installed: $ACTUAL5B, 출력: $OUT5B"
fi

# ─────────────────────────────────────────────────────────
# T6: invalid 입력 에러 메시지에 toggle 도 표시되는지
# ─────────────────────────────────────────────────────────
echo ""
echo "T6: invalid 입력 에러에 toggle 허용값 노출"
F6=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F6")

OUT6=$(run_sdd "$F6" config ux-mode invalid 2>&1 || true)
if echo "$OUT6" | grep -q "toggle"; then
  ok "에러 메시지에 toggle 노출"
else
  fail "에러 메시지에 toggle 누락 — 실제: $OUT6"
fi

# ─────────────────────────────────────────────────────────
# T7: sdd config default-branch (미설정) → main 출력
# ─────────────────────────────────────────────────────────
echo ""
echo "T7: sdd config default-branch (미설정) → main 출력"
F7=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F7")

OUT7=$(run_sdd "$F7" config default-branch)
if echo "$OUT7" | grep -q "main"; then
  ok "미설정 조회 시 main 출력: $OUT7"
else
  fail "미설정 조회 실패 — 실제: $OUT7"
fi

# ─────────────────────────────────────────────────────────
# T8: sdd config default-branch <branch> → 설정 + 조회
#     (실재 브랜치는 경고 없음, 부재 브랜치는 경고 후 설정)
# ─────────────────────────────────────────────────────────
echo ""
echo "T8: sdd config default-branch 설정 + 조회 (실재/부재 경고)"
F8=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F8")
git -C "$F8" branch develop 2>/dev/null

run_sdd "$F8" config default-branch develop >/dev/null
ACTUAL8=$(jq -r '.defaultBranch // empty' "$F8/.harness-kit/installed.json" 2>/dev/null)
if [ "$ACTUAL8" = "develop" ]; then
  ok "installed.json defaultBranch=develop 갱신됨"
else
  fail "defaultBranch 갱신 실패 — 예상: develop, 실제: $ACTUAL8"
fi

OUT8B=$(run_sdd "$F8" config default-branch ghost-branch)
ACTUAL8B=$(jq -r '.defaultBranch // empty' "$F8/.harness-kit/installed.json" 2>/dev/null)
if [ "$ACTUAL8B" = "ghost-branch" ] && echo "$OUT8B" | grep -qE "⚠|경고|없"; then
  ok "부재 브랜치 → 경고 후 설정됨 (거부 아님)"
else
  fail "부재 브랜치 처리 실패 — installed: $ACTUAL8B, 출력: $OUT8B"
fi

OUT8C=$(run_sdd "$F8" config default-branch)
if echo "$OUT8C" | grep -q "ghost-branch"; then
  ok "설정 후 조회 = ghost-branch"
else
  fail "설정 후 조회 실패 — 실제: $OUT8C"
fi

# ─────────────────────────────────────────────────────────
# T9: 부적합 브랜치명 (형식 위반) → 거부 + 미설정 유지
# ─────────────────────────────────────────────────────────
echo ""
echo "T9: sdd config default-branch 'bad branch' → 형식 거부"
F9=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F9")

RC9=0
run_sdd "$F9" config default-branch "bad branch" >/dev/null || RC9=$?
ACTUAL9=$(jq -r '.defaultBranch // empty' "$F9/.harness-kit/installed.json" 2>/dev/null)
if [ "$RC9" -ne 0 ] && [ -z "$ACTUAL9" ]; then
  ok "형식 위반 거부 (exit=$RC9) + defaultBranch 미설정 유지"
else
  fail "형식 위반 미거부 — exit: $RC9, installed: $ACTUAL9"
fi

# ─────────────────────────────────────────────────────────
# T10: sdd status --json 에 defaultBranch 노출
# ─────────────────────────────────────────────────────────
echo ""
echo "T10: sdd status --json 에 defaultBranch 노출"
F10=$(make_fixture)
FIXTURES_TO_CLEAN+=("$F10")

JSON10A=$( cd "$F10" && HARNESS_DRIFT_FETCH=0 bash "$SDD" status --json 2>/dev/null )
VAL10A=$(echo "$JSON10A" | jq -r '.defaultBranch // empty' 2>/dev/null)
if [ "$VAL10A" = "main" ]; then
  ok "미설정 시 status --json defaultBranch=main"
else
  fail "미설정 노출 실패 — 실제: '$VAL10A'"
fi

git -C "$F10" branch develop 2>/dev/null
run_sdd "$F10" config default-branch develop >/dev/null
JSON10B=$( cd "$F10" && HARNESS_DRIFT_FETCH=0 bash "$SDD" status --json 2>/dev/null )
VAL10B=$(echo "$JSON10B" | jq -r '.defaultBranch // empty' 2>/dev/null)
if [ "$VAL10B" = "develop" ]; then
  ok "설정 후 status --json defaultBranch=develop"
else
  fail "설정 후 노출 실패 — 실제: '$VAL10B'"
fi

# ─────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  결과: PASS=$PASS  FAIL=$FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ "$FAIL" -eq 0 ]

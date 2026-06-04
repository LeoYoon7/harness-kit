#!/usr/bin/env bash
# tests/test-role-model-config.sh
# spec-21-04: 역할 기반 모델 config (sdd config models) + agent.md §6.6 de-hardcode 검증
#
# 검증 항목:
#   C1: installed.json .models 기본 3역할(director/worker/scout) — fresh install
#   C2: sdd config models (인수 없음) → 3역할 매핑 출력
#   C3: sdd config models <role> <model> → installed.json 갱신
#   C4: agent.md §6.6 역할 참조(models.*) 존재 + 모델명(Opus/Sonnet) 하드코딩 부재
#   C5: 이중 미러 parity (agent.md + sdd)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB="$SCRIPT_DIR/lib/fixture.sh"
SDD="$ROOT/sources/bin/sdd"
AGENT="$ROOT/sources/governance/agent.md"
AGENT_MIRROR="$ROOT/.harness-kit/agent/agent.md"
SDD_MIRROR="$ROOT/.harness-kit/bin/sdd"

PASS=0; FAIL=0
ok()   { echo "  PASS: $*"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $*"; FAIL=$(( FAIL + 1 )); }

echo "=== test-role-model-config ==="

if [ ! -f "$LIB" ]; then fail "tests/lib/fixture.sh 없음"; exit 1; fi
if [ ! -f "$SDD" ]; then fail "sources/bin/sdd 없음"; exit 1; fi

source "$LIB"

FIXTURES_TO_CLEAN=""
cleanup() {
  local d
  for d in $FIXTURES_TO_CLEAN; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
  done
}
trap cleanup EXIT

run_sdd() {
  local fx="$1"; shift
  ( cd "$fx" && HARNESS_DRIFT_FETCH=0 bash "$SDD" "$@" 2>&1 )
}
get_model() {
  jq -r --arg r "$2" '.models[$r] // empty' "$1/.harness-kit/installed.json" 2>/dev/null
}
section_66() {
  awk '/^### 6\.6 /{f=1} /^### 6\.7 /{f=0} f' "$AGENT"
}

# --- C1: 기본 .models 3역할 ---
echo "▶ C1: installed.json .models 기본 3역할"
F1=$(make_fixture)
FIXTURES_TO_CLEAN="$FIXTURES_TO_CLEAN $F1"
c1_ok=1
for role in director worker scout; do
  v=$(get_model "$F1" "$role")
  [ -n "$v" ] || { c1_ok=0; fail ".models.$role 기본값 없음"; }
done
[ "$c1_ok" = 1 ] && ok ".models director/worker/scout 기본값 존재"

# --- C2: sdd config models (list) ---
echo "▶ C2: sdd config models 출력에 3역할"
OUT2=$(run_sdd "$F1" config models)
if echo "$OUT2" | grep -q "director" && echo "$OUT2" | grep -q "worker" && echo "$OUT2" | grep -q "scout"; then
  ok "config models 출력에 director/worker/scout 포함"
else
  fail "config models 출력 누락 — 실제: $OUT2"
fi

# --- C3: sdd config models <role> <model> (set) ---
echo "▶ C3: sdd config models scout haiku → 갱신"
F3=$(make_fixture)
FIXTURES_TO_CLEAN="$FIXTURES_TO_CLEAN $F3"
run_sdd "$F3" config models scout haiku >/dev/null
ACT3=$(get_model "$F3" scout)
if [ "$ACT3" = "haiku" ]; then
  ok "scout=haiku 갱신됨"
else
  fail "set 실패 — 예상: haiku, 실제: $ACT3"
fi

# --- C4: §6.6 역할 참조 + 모델명 부재 ---
echo "▶ C4: agent.md §6.6 역할 참조 + 모델명 하드코딩 부재"
SEC=$(section_66)
if echo "$SEC" | grep -q "models.director" && echo "$SEC" | grep -q "models.worker" && echo "$SEC" | grep -q "models.scout"; then
  ok "§6.6 models.director/worker/scout 참조 존재"
else
  fail "§6.6 역할 참조(models.*) 누락"
fi
if echo "$SEC" | grep -qE 'Opus|Sonnet'; then
  fail "§6.6 에 모델명(Opus/Sonnet) 하드코딩 잔존"
else
  ok "§6.6 모델명 하드코딩 부재"
fi

# --- C5: 이중 미러 parity ---
echo "▶ C5: 이중 미러 parity"
if diff -q "$AGENT" "$AGENT_MIRROR" > /dev/null 2>&1; then
  ok "agent.md 미러 동기화 OK"
else
  fail "agent.md 미러 불일치"
fi
if diff -q "$SDD" "$SDD_MIRROR" > /dev/null 2>&1; then
  ok "sdd 미러 동기화 OK"
else
  fail "sdd 미러 불일치"
fi

echo ""
echo "=== 결과: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ] || exit 1

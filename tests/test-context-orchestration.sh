#!/usr/bin/env bash
# §6.6 컨텍스트 오케스트레이션 정책(orchestrator-worker) + ADR-010 존재 + 미러 parity 검증
#
# spec-21-01: 메인 = context orchestrator 정책을 agent.md §6.6 에 확립한다.
# 3 checks (단어 예산 가드는 test-governance-dedup.sh Check 3 가 담당 — 이중 baseline 방지):
#   Check 1: §6.6 핵심 용어(orchestrator/worker/offloading/distilled) 존재
#   Check 2: sources ↔ .harness-kit agent.md 미러 parity
#   Check 3: ADR-010-context-orchestration.md 존재 + type: decision

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

AGENT="$ROOT/sources/governance/agent.md"
AGENT_MIRROR="$ROOT/.harness-kit/agent/agent.md"
ADR="$ROOT/docs/decisions/ADR-010-context-orchestration.md"

FAIL=0
TOTAL=0
pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
check() { TOTAL=$((TOTAL + 1)); }

echo "═══════════════════════════════════════════"
echo " Context Orchestration Verification"
echo "═══════════════════════════════════════════"
echo ""

# --- Check 1: §6.6 핵심 용어 ---
echo "▶ Check 1: §6.6 context orchestration 용어 존재"
for TERM in orchestrator worker offloading distilled; do
  check
  if grep -qi "$TERM" "$AGENT" 2>/dev/null; then
    pass "용어 확인: $TERM"
  else
    fail "용어 누락: $TERM (sources/governance/agent.md)"
  fi
done

# --- Check 2: 미러 parity ---
echo ""
echo "▶ Check 2: sources ↔ .harness-kit agent.md 미러 parity"
check
if diff -q "$AGENT" "$AGENT_MIRROR" >/dev/null 2>&1; then
  pass "agent.md 미러 동기화 OK"
else
  fail "agent.md 미러 불일치 (sources ↔ .harness-kit)"
fi

# --- Check 3: ADR-010 존재 + type ---
echo ""
echo "▶ Check 3: ADR-010 존재 + type: decision"
check
if [ -f "$ADR" ]; then
  if grep -q "^type: decision" "$ADR" 2>/dev/null; then
    pass "ADR-010 존재 + type: decision"
  else
    fail "ADR-010 존재하지만 type: decision frontmatter 없음"
  fi
else
  fail "docs/decisions/ADR-010-context-orchestration.md 없음"
fi

# --- Summary ---
echo ""
echo "═══════════════════════════════════════════"
if [ "$FAIL" -eq 0 ]; then
  echo " ✅ ALL $TOTAL CHECKS PASSED"
else
  echo " ❌ $FAIL/$TOTAL CHECKS FAILED"
fi
echo "═══════════════════════════════════════════"

exit $FAIL

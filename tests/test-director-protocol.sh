#!/usr/bin/env bash
# tests/test-director-protocol.sh
# spec-21-03: §6.8 Director Mode Protocol + §6.1 위임 단락 + director-mode.md 가이드 + ADR-011 검증
#
# 검증 항목:
#   C1: agent.md 에 §6.8 Director Mode Protocol 섹션 존재
#   C2: 핵심 불변식 용어 (intent handshake / distilled contract / re-ingestion·full transcript / Plan Accept)
#   C3: §6.1 Director Mode delegation 단락 + artifact files 커밋 범위 용어 + §6.8→§6.1 참조
#   C4: 이중 미러 parity (agent.md + director-mode.md, sources ↔ .harness-kit)
#   C5: director-mode.md 운영 가이드 존재 (source + 미러)
#   C6: ADR-011 존재 + type: decision
#
# 주의: 단어 예산(6000w) 체크는 본 테스트에 미포함. SSOT 는 tests/test-governance-dedup.sh Check 3.
#       (동일 지표 이중 baseline 금지 — spec-21-01 결정)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

AGENT="$ROOT/sources/governance/agent.md"
AGENT_MIRROR="$ROOT/.harness-kit/agent/agent.md"
GUIDE="$ROOT/sources/governance/director-mode.md"
GUIDE_MIRROR="$ROOT/.harness-kit/agent/director-mode.md"
ADR="$ROOT/docs/decisions/ADR-011-director-mode.md"

PASS=0; FAIL=0
ok()   { echo "  PASS: $*"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $*"; FAIL=$(( FAIL + 1 )); }

echo "=== test-director-protocol ==="

if [ ! -f "$AGENT" ]; then
  fail "sources/governance/agent.md 없음"
  exit 1
fi

# --- C1: §6.8 섹션 존재 ---
echo "▶ C1: §6.8 Director Mode Protocol 섹션"
if grep -q "6.8 Director Mode Protocol" "$AGENT"; then
  ok "§6.8 Director Mode Protocol 섹션 발견"
else
  fail "§6.8 Director Mode Protocol 섹션 없음 (agent.md)"
fi

# --- C2: 핵심 불변식 용어 ---
echo "▶ C2: 핵심 불변식 용어"
if grep -qi "intent handshake" "$AGENT"; then
  ok "'intent handshake' 확인"
else
  fail "'intent handshake' 없음"
fi
if grep -qi "distilled contract" "$AGENT"; then
  ok "'distilled contract' 확인"
else
  fail "'distilled contract' 없음"
fi
if grep -qi "re-ingest\|full transcript" "$AGENT"; then
  ok "'re-ingestion' 또는 'full transcript' 확인"
else
  fail "'re-ingestion' / 'full transcript' 없음"
fi
if grep -q "Plan Accept" "$AGENT"; then
  ok "'Plan Accept' 확인"
else
  fail "'Plan Accept' 없음"
fi

# --- C3: §6.1 Director Mode delegation 단락 ---
echo "▶ C3: §6.1 Director Mode delegation 단락"
if grep -q "Director Mode delegation" "$AGENT"; then
  ok "'Director Mode delegation' 확인 (§6.1 위임 단락)"
else
  fail "'Director Mode delegation' 없음 (§6.1 위임 단락 미추가)"
fi
if grep -qi "artifact files\|planning artifacts" "$AGENT"; then
  ok "'artifact files' / 'planning artifacts' 확인 (산출물 커밋 범위)"
else
  fail "'artifact files' / 'planning artifacts' 없음 (산출물 커밋 범위 미명시)"
fi
if grep -q "§6.1 Director Mode delegation\|→ §6.1" "$AGENT"; then
  ok "§6.8→§6.1 참조 줄 확인"
else
  fail "§6.8→§6.1 참조 줄 없음"
fi

# --- C4: 이중 미러 parity ---
echo "▶ C4: 이중 미러 parity (sources ↔ .harness-kit)"
if diff -q "$AGENT" "$AGENT_MIRROR" > /dev/null 2>&1; then
  ok "agent.md 미러 동기화 OK"
else
  fail "agent.md 미러 불일치"
fi
if [ -f "$GUIDE" ] && [ -f "$GUIDE_MIRROR" ] && diff -q "$GUIDE" "$GUIDE_MIRROR" > /dev/null 2>&1; then
  ok "director-mode.md 미러 동기화 OK"
else
  fail "director-mode.md 미러 불일치 또는 파일 없음"
fi

# --- C5: director-mode.md 가이드 존재 ---
echo "▶ C5: director-mode.md 운영 가이드 존재"
if [ -f "$GUIDE" ]; then
  ok "sources/governance/director-mode.md 존재"
else
  fail "sources/governance/director-mode.md 없음"
fi

# --- C6: ADR-011 존재 + type ---
echo "▶ C6: ADR-011 존재 + type: decision"
if [ -f "$ADR" ]; then
  ok "ADR-011-director-mode.md 존재"
else
  fail "ADR-011-director-mode.md 없음"
fi
if [ -f "$ADR" ] && grep -q "type: decision" "$ADR"; then
  ok "ADR-011 type: decision 확인"
else
  fail "ADR-011 type: decision 없음"
fi

echo ""
echo "=== 결과: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ] || exit 1

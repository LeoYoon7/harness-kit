#!/usr/bin/env bash
# spec-x-review-b1-default: hk-code-review B1 패턴 업그레이드 + ADR-013/014 구조 검증
#
# 검증 항목 (grep 기반 구조 — test-director-protocol.sh 패턴):
#   C1: hk-code-review.md 에 B1 용어 (self-consistency / generalist / 결과 계약 / 증류)
#   C2: 페르소나 패널 opt-in 섹션 (페르소나 / opt-in / 폭 지배 / 미구현)
#   C3: ADR-010 참조 (결과 계약 only 근거)
#   C4: 도그푸딩 미러 parity (sources/commands ↔ .claude/commands)
#   C5: ADR-013-review-value-baseline 존재 + type: invariant
#   C6: ADR-014-review-eval-independence 존재 + type: invariant
#   C7: 증류 조작적 정의 (dedup / 합의 / 심각도) — 재현성 blocking enforcement
#   C8: 부분 실패 fallback (fallback / 미반환)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CMD="$ROOT/sources/commands/hk-code-review.md"
CMD_MIRROR="$ROOT/.claude/commands/hk-code-review.md"
ADR13="$ROOT/docs/decisions/ADR-013-review-value-baseline.md"
ADR14="$ROOT/docs/decisions/ADR-014-review-eval-independence.md"

PASS=0; FAIL=0
ok()   { echo "  PASS: $*"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $*"; FAIL=$(( FAIL + 1 )); }

# has <file> <term> : 파일에 term 이 있으면 0
has() { grep -qF "$2" "$1" 2>/dev/null; }

echo "=== test-review-b1 ==="

if [ ! -f "$CMD" ]; then
  fail "sources/commands/hk-code-review.md 없음"
  echo "=== 결과: PASS=$PASS FAIL=$FAIL ==="
  exit 1
fi

# --- C1: B1 용어 ---
echo "▶ C1: B1 패턴 용어"
for term in "self-consistency" "generalist" "결과 계약" "증류"; do
  if has "$CMD" "$term"; then ok "C1 '$term'"; else fail "C1 '$term' 없음"; fi
done

# --- C2: 페르소나 opt-in 섹션 ---
echo "▶ C2: 페르소나 패널 opt-in"
for term in "페르소나" "opt-in" "폭 지배" "미구현"; do
  if has "$CMD" "$term"; then ok "C2 '$term'"; else fail "C2 '$term' 없음"; fi
done

# --- C3: ADR-010 참조 ---
echo "▶ C3: ADR-010 참조 (결과 계약 only)"
if has "$CMD" "ADR-010"; then ok "C3 ADR-010 참조"; else fail "C3 ADR-010 참조 없음"; fi

# --- C4: 미러 parity ---
echo "▶ C4: 도그푸딩 미러 parity"
if [ -f "$CMD_MIRROR" ] && diff -q "$CMD" "$CMD_MIRROR" > /dev/null 2>&1; then
  ok "C4 sources ↔ .claude 동기화"
else
  fail "C4 미러 불일치 또는 파일 없음 (.claude/commands/hk-code-review.md)"
fi

# --- C5: ADR-013 ---
echo "▶ C5: ADR-013-review-value-baseline + type: invariant"
if [ -f "$ADR13" ]; then ok "C5 ADR-013 존재"; else fail "C5 ADR-013 없음"; fi
if [ -f "$ADR13" ] && has "$ADR13" "type: invariant"; then ok "C5 type: invariant"; else fail "C5 type: invariant 없음"; fi

# --- C6: ADR-014 ---
echo "▶ C6: ADR-014-review-eval-independence + type: invariant"
if [ -f "$ADR14" ]; then ok "C6 ADR-014 존재"; else fail "C6 ADR-014 없음"; fi
if [ -f "$ADR14" ] && has "$ADR14" "type: invariant"; then ok "C6 type: invariant"; else fail "C6 type: invariant 없음"; fi

# --- C7: 증류 조작적 정의 ---
echo "▶ C7: 증류 조작적 정의 (재현성)"
for term in "dedup" "합의" "심각도"; do
  if has "$CMD" "$term"; then ok "C7 '$term'"; else fail "C7 '$term' 없음"; fi
done

# --- C8: 부분 실패 fallback ---
echo "▶ C8: 부분 실패 fallback"
if has "$CMD" "fallback" || has "$CMD" "미반환"; then
  ok "C8 fallback / 미반환"
else
  fail "C8 fallback / 미반환 없음"
fi

echo ""
echo "=== 결과: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ] || exit 1

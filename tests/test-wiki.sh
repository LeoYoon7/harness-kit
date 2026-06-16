#!/usr/bin/env bash
# tests/test-wiki.sh
# phase-23 통합 테스트 — sdd doctor 의 wiki/문서 건강 점검 3종 + 템플릿 Related 회귀
#   (a) 고아 [[wikilink]]  (b) 90일+ stale ADR/RCA  (c) governance 단어수 상한
# 모두 경고(_doc_warn) 수준. 대상 디렉토리 부재 시 silent skip.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL="$ROOT/install.sh"
SDD="$ROOT/sources/bin/sdd"

FAIL=0
TOTAL=0
pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
check() { TOTAL=$((TOTAL + 1)); }

make_fixture() {
  local d
  d="$(mktemp -d)"
  git -C "$d" init -q
  git -C "$d" checkout -b main 2>/dev/null || true
  git -C "$d" config user.email "test@local"
  git -C "$d" config user.name "test"
  echo "$d"
}

echo "═══════════════════════════════════════════"
echo " test-wiki.sh — phase-23 wiki/문서 건강 점검"
echo "═══════════════════════════════════════════"

# ──────────────────────────────────────────────
# 템플릿 Related 회귀 (phase 시나리오 2 — spec-23-01 산출물)
# ──────────────────────────────────────────────
echo ""
echo "▶ 템플릿 Related 섹션 (spec-23-01)"

for t in spec walkthrough; do
  check
  if grep -q '관련 문서' "$ROOT/sources/templates/$t.md"; then
    pass "templates/$t.md — '관련 문서' Related 섹션 존재"
  else
    fail "templates/$t.md — Related 섹션 없음"
  fi
done

for t in adr rca; do
  check
  if grep -q '\[\[wikilink\]\] 컨벤션' "$ROOT/sources/templates/$t.md"; then
    pass "templates/$t.md — [[wikilink]] 안내 보강 존재"
  else
    fail "templates/$t.md — [[wikilink]] 안내 없음"
  fi
done

# ──────────────────────────────────────────────
# (c) governance 단어수 상한 점검
# ──────────────────────────────────────────────
echo ""
echo "▶ (c) governance 단어수 상한 (6500, ADR-012)"

FIXC="$(make_fixture)"
trap 'rm -rf "$FIXC"' EXIT
bash "$INSTALL" --yes "$FIXC" > /dev/null 2>&1

# 섹션 존재 + PASS 라인 (실제 governance ~6391w < 6500)
outc="$(cd "$FIXC" && bash "$SDD" doctor 2>/dev/null || true)"

check
if printf '%s' "$outc" | grep -q "wiki/문서 건강"; then
  pass "c-section: doctor 출력에 'wiki/문서 건강' 섹션 포함"
else
  fail "c-section: 'wiki/문서 건강' 섹션 없음"
fi

check
if printf '%s' "$outc" | grep -q "governance 단어수.*상한 6500 이하"; then
  pass "c-1: 실제 governance (<6500) → PASS 라인"
else
  fail "c-1: governance 단어수 PASS 라인 미검출"
fi

# WARN 케이스: agent.md 에 단어 대량 추가 → 6500 초과
for _ in $(seq 400); do printf 'filler '; done >> "$FIXC/.harness-kit/agent/agent.md"
outc2="$(cd "$FIXC" && bash "$SDD" doctor 2>/dev/null || true)"

check
if printf '%s' "$outc2" | grep -q "governance 단어수.*상한 6500 초과"; then
  pass "c-2: 단어 추가 (>6500) → WARN 라인 발화"
else
  fail "c-2: WARN 라인 미발화"
fi

# ──────────────────────────────────────────────
# 결과
# ──────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
PASS=$((TOTAL - FAIL))
echo " 결과: $PASS / $TOTAL PASS"
if [ "$FAIL" -eq 0 ]; then
  echo " ✅ ALL PASS"
  exit 0
else
  echo " ❌ $FAIL FAIL"
  exit 1
fi

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
# (a) 고아 [[wikilink]] 점검
# ──────────────────────────────────────────────
echo ""
echo "▶ (a) 고아 [[wikilink]]"

FIXA="$(make_fixture)"
trap 'rm -rf "$FIXC" "$FIXA"' EXIT
bash "$INSTALL" --yes "$FIXA" > /dev/null 2>&1
mkdir -p "$FIXA/docs/wiki"

# 깨진 링크 → 고아 경고
printf '# index\n[[wiki/nonexistent]]\n' > "$FIXA/docs/wiki/index.md"
outa="$(cd "$FIXA" && bash "$SDD" doctor 2>/dev/null || true)"
check
if printf '%s' "$outa" | grep -q "고아 wiki 링크"; then
  pass "a-1: 깨진 [[wiki/nonexistent]] → 고아 경고 발화"
else
  fail "a-1: 고아 경고 미발화"
fi

# 정상 링크 → 무경고 (오탐 방지)
printf '# index\n[[wiki/index]]\n' > "$FIXA/docs/wiki/index.md"
outa2="$(cd "$FIXA" && bash "$SDD" doctor 2>/dev/null || true)"
check
if printf '%s' "$outa2" | grep -q "고아 wiki 링크"; then
  fail "a-2: 정상 [[wiki/index]] 인데 고아 경고 발화 (오탐)"
else
  pass "a-2: 정상 [[wiki/index]] → 고아 경고 없음"
fi

# docs/wiki/ 부재 → silent skip
check
if printf '%s' "$outc" | grep -q "고아 wiki 링크"; then
  fail "a-3: docs/wiki/ 없는 fixture(FIXC)인데 고아 점검 발화"
else
  pass "a-3: docs/wiki/ 부재 → 고아 점검 silent skip"
fi

# 컨벤션 placeholder(ADR-NNN, wiki/page-name, spec-NN-NN) → 오탐 없음
rm -f "$FIXA/docs/wiki/index.md"
printf '# purpose\n[[ADR-NNN]] [[wiki/page-name]]\n' > "$FIXA/docs/wiki/purpose.md"
printf '# decisions\n[[ADR-NNN]] [[spec-NN-NN]]\n' > "$FIXA/docs/wiki/decisions.md"
outa3="$(cd "$FIXA" && bash "$SDD" doctor 2>/dev/null || true)"
check
if printf '%s' "$outa3" | grep -q "고아 wiki 링크"; then
  fail "a-4: convention placeholder 오탐 발화 (purpose.md 제외/concrete-format 실패)"
else
  pass "a-4: convention placeholder(ADR-NNN/wiki/page-name) → 오탐 없음"
fi

# ──────────────────────────────────────────────
# (b) 90일+ stale ADR/RCA 점검
# ──────────────────────────────────────────────
echo ""
echo "▶ (b) 90일+ stale ADR/RCA"

FIXB="$(make_fixture)"
trap 'rm -rf "$FIXC" "$FIXA" "$FIXB"' EXIT
bash "$INSTALL" --yes "$FIXB" > /dev/null 2>&1
mkdir -p "$FIXB/docs/decisions"

# 오래된 ADR (date 2020) → stale 경고
printf -- '---\nid: ADR-001\ndate: 2020-01-01\n---\n# old\n' > "$FIXB/docs/decisions/ADR-001-old.md"
outb="$(cd "$FIXB" && bash "$SDD" doctor 2>/dev/null || true)"
check
if printf '%s' "$outb" | grep -q "stale 결정문서"; then
  pass "b-1: 오래된 ADR(2020) → stale 경고 발화"
else
  fail "b-1: stale 경고 미발화"
fi

# updated: 오늘 → stale 아님 (updated 우선)
rm -f "$FIXB/docs/decisions/ADR-001-old.md"
TODAY="$(date +%Y-%m-%d)"
printf -- '---\nid: ADR-002\ndate: 2020-01-01\nupdated: %s\n---\n# fresh\n' "$TODAY" > "$FIXB/docs/decisions/ADR-002-fresh.md"
outb2="$(cd "$FIXB" && bash "$SDD" doctor 2>/dev/null || true)"
check
if printf '%s' "$outb2" | grep -q "stale 결정문서"; then
  fail "b-2: updated=today ADR 인데 stale 경고 (updated 우선 실패)"
else
  pass "b-2: updated=today → stale 아님 (updated: 우선)"
fi

# docs/decisions·docs/rca 부재(FIXC) → silent skip
check
if printf '%s' "$outc" | grep -q "stale 결정문서"; then
  fail "b-3: docs/decisions 없는 fixture(FIXC)인데 stale 점검 발화"
else
  pass "b-3: docs/decisions·rca 부재 → stale 점검 silent skip"
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

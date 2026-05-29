#!/usr/bin/env bash
# sdd doctor 의 ignore 위생 점검 (spec-x-install-ignore-coverage)
#
# 검증 (Task 5: .gitignore 부분):
#   .gitignore 점검 (a):
#     1) install 후 .gitignore 등재 → PASS 라인 grep
#     2) .gitignore 에서 항목 제거 → WARN 라인 grep
#
# Task 6 (.dockerignore 매트릭스) 시나리오는 후속 commit 에서 추가.
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

echo "═══════════════════════════════════════════"
echo " Doctor Ignore Coverage Verification (spec-x-install-ignore-coverage)"
echo "═══════════════════════════════════════════"
echo ""

make_fixture() {
  local d
  d="$(mktemp -d)"
  git -C "$d" init -q
  git -C "$d" checkout -b main 2>/dev/null || true
  git -C "$d" config user.email "test@local"
  git -C "$d" config user.name "test"
  echo "$d"
}

# ──────────────────────────────────────────────
# Setup: install + 후속 doctor 점검 시나리오
# ──────────────────────────────────────────────

FIX="$(make_fixture)"
trap 'rm -rf "$FIX"' EXIT

bash "$INSTALL" --yes "$FIX" > /dev/null 2>&1

# ──────────────────────────────────────────────
# .gitignore 점검 (a)
# ──────────────────────────────────────────────
echo "▶ .gitignore 점검 (a)"

# (a-1) install 직후 .gitignore 등재 → doctor PASS
out="$(cd "$FIX" && bash "$SDD" doctor 2>/dev/null || true)"

check
if printf '%s' "$out" | grep -q "ignore 위생"; then
  pass "a-section: doctor 출력에 'ignore 위생' 섹션 포함"
else
  fail "a-section: doctor 출력에 'ignore 위생' 섹션 없음"
fi

check
if printf '%s' "$out" | grep -q ".gitignore.*리뷰 출력 패턴 등재"; then
  pass "a-1: install 직후 .gitignore 등재 → PASS 라인 검출"
else
  fail "a-1: .gitignore PASS 라인 미검출"
fi

# (a-2) .gitignore 에서 신규 라인 제거 → doctor WARN
sed -i.bak '/^specs\/\*\*\/code-review\*\.md$/d' "$FIX/.gitignore"
rm -f "$FIX/.gitignore.bak"

out2="$(cd "$FIX" && bash "$SDD" doctor 2>/dev/null || true)"

check
if printf '%s' "$out2" | grep -q ".gitignore.*'specs/\*\*/code-review\*\.md'.*미등재"; then
  pass "a-2: .gitignore 항목 제거 후 doctor WARN 라인 검출"
else
  fail "a-2: WARN 라인 미검출"
fi

echo ""

# ──────────────────────────────────────────────
# 결과
# ──────────────────────────────────────────────
echo "═══════════════════════════════════════════"
PASS=$((TOTAL - FAIL))
echo " 결과: $PASS / $TOTAL PASS"
if [ $FAIL -eq 0 ]; then
  echo " ✅ ALL PASS"
  exit 0
else
  echo " ❌ $FAIL FAIL"
  exit 1
fi

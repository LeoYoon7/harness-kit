#!/usr/bin/env bash
# sdd doctor 의 ignore 위생 점검 (spec-x-install-ignore-coverage)
#
# 검증:
#   .gitignore 점검 (a):
#     a-section: doctor 출력에 'ignore 위생' 섹션 존재
#     a-1) install 후 .gitignore 등재 → PASS 라인 grep
#     a-2) .gitignore 에서 항목 제거 → WARN 라인 grep
#   .dockerignore 점검 (b) 매트릭스:
#     b-1) Dockerfile 없음 → .dockerignore 점검 silent skip
#     b-2) Dockerfile 있음, .dockerignore 없음 → WARN
#     b-3) Dockerfile 있음, .dockerignore 에 .harness-kit 없음 → WARN
#     b-4a) Dockerfile 있음, .dockerignore .harness-kit/ (정확 매치) → PASS
#     b-4b) Dockerfile 있음, .dockerignore **/.harness-kit/ (와일드카드) → PASS (관대성)
#     b-4c) Dockerfile 있음, .dockerignore .harness-kit (슬래시 없이) → PASS (관대성)
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
# .dockerignore 점검 (b) 매트릭스
# Restore .gitignore line so .gitignore (a) WARN 미발화 → .dockerignore portion 만 검증
# ──────────────────────────────────────────────
echo "▶ .dockerignore 점검 (b) 매트릭스"

echo 'specs/**/code-review*.md' >> "$FIX/.gitignore"

# b-1: Dockerfile 없음 → .dockerignore silent skip
check
rm -f "$FIX/Dockerfile" "$FIX/.dockerignore"
out3="$(cd "$FIX" && bash "$SDD" doctor 2>/dev/null || true)"
if ! printf '%s' "$out3" | grep -q "Dockerfile 존재"; then
  pass "b-1: Dockerfile 없음 → .dockerignore WARN silent skip"
else
  fail "b-1: Dockerfile 없는데 .dockerignore 경고 발화"
fi

# b-2: Dockerfile 있음, .dockerignore 없음 → WARN
check
echo 'FROM alpine' > "$FIX/Dockerfile"
rm -f "$FIX/.dockerignore"
out4="$(cd "$FIX" && bash "$SDD" doctor 2>/dev/null || true)"
if printf '%s' "$out4" | grep -q "Dockerfile 존재.*\.dockerignore.*미등재"; then
  pass "b-2: Dockerfile + .dockerignore 없음 → WARN 발화"
else
  fail "b-2: WARN 미발화"
fi

# b-3: Dockerfile + .dockerignore 있지만 .harness-kit 없음 → WARN
check
echo 'node_modules' > "$FIX/.dockerignore"
out5="$(cd "$FIX" && bash "$SDD" doctor 2>/dev/null || true)"
if printf '%s' "$out5" | grep -q "Dockerfile 존재.*\.dockerignore.*미등재"; then
  pass "b-3: Dockerfile + .dockerignore 에 .harness-kit 없음 → WARN 발화"
else
  fail "b-3: WARN 미발화"
fi

# b-4a: .dockerignore 에 .harness-kit/ 정확 매치 → PASS
check
printf 'node_modules\n.harness-kit/\n' > "$FIX/.dockerignore"
out6="$(cd "$FIX" && bash "$SDD" doctor 2>/dev/null || true)"
if printf '%s' "$out6" | grep -q "\.dockerignore.*\.harness-kit.*등재"; then
  pass "b-4a: .dockerignore '.harness-kit/' 정확 매치 → PASS 라인"
else
  fail "b-4a: PASS 라인 미검출"
fi

# b-4b: .dockerignore 에 **/.harness-kit/ 와일드카드 → PASS (관대성)
check
printf 'node_modules\n**/.harness-kit/\n' > "$FIX/.dockerignore"
out7="$(cd "$FIX" && bash "$SDD" doctor 2>/dev/null || true)"
if printf '%s' "$out7" | grep -q "\.dockerignore.*\.harness-kit.*등재"; then
  pass "b-4b: .dockerignore '**/.harness-kit/' 와일드카드 → PASS (관대성)"
else
  fail "b-4b: 와일드카드 패턴 PASS 미검출 (사용자 자유도 침해)"
fi

# b-4c: .dockerignore 에 .harness-kit (슬래시 없이) → PASS (관대성)
check
printf 'node_modules\n.harness-kit\n' > "$FIX/.dockerignore"
out8="$(cd "$FIX" && bash "$SDD" doctor 2>/dev/null || true)"
if printf '%s' "$out8" | grep -q "\.dockerignore.*\.harness-kit.*등재"; then
  pass "b-4c: .dockerignore '.harness-kit' (슬래시 없이) → PASS (관대성)"
else
  fail "b-4c: 슬래시 없는 패턴 PASS 미검출"
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

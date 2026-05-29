#!/usr/bin/env bash
set -euo pipefail

# test-gitignore-config.sh
# spec-9-006: .harness-kit/ gitignore config 옵션 검증
#
# 검증 항목:
#   A) --yes (기본) 설치 → .gitignore에 ".harness-kit/" 포함, config "gitignore":true
#   B) --no-gitignore 설치 → .gitignore에 "!.harness-kit/" 포함, config "gitignore":false
#   C) --gitignore 명시 설치 → .gitignore에 ".harness-kit/" 포함
#   D) 재설치 멱등성 — .gitignore 중복 항목 없음
#   E) update.sh 후 gitignore=true 보존
#   F) update.sh 후 gitignore=false 보존
#   G) --yes 플래그 → 기본(Y) 자동 적용

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL="$ROOT/install.sh"
UPDATE="$ROOT/update.sh"

FAIL=0
TOTAL=0

pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
check() { TOTAL=$((TOTAL + 1)); }

echo "═══════════════════════════════════════════"
echo " Gitignore Config Verification (spec-9-006)"
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
# Scenario A: --yes (기본) → ".harness-kit/" in .gitignore, gitignore=true in config
# ──────────────────────────────────────────────
echo "▶ Scenario A: --yes 설치 (기본 gitignore=true)"
FIX_A="$(make_fixture)"
trap 'rm -rf "$FIX_A"' EXIT

bash "$INSTALL" --yes "$FIX_A" > /dev/null 2>&1

check
if grep -q '^\.harness-kit/$' "$FIX_A/.gitignore" 2>/dev/null; then
  pass "A-1: .gitignore에 '.harness-kit/' 포함"
else
  fail "A-1: .gitignore에 '.harness-kit/' 없음"
fi

check
_gi_val=$(jq -r 'if has("gitignore") then (.gitignore | tostring) else "MISSING" end' "$FIX_A/.harness-kit/harness.config.json" 2>/dev/null || echo "MISSING")
if [ "$_gi_val" = "true" ]; then
  pass "A-2: harness.config.json gitignore=true"
else
  fail "A-2: harness.config.json gitignore 값이 '$_gi_val' (expected: true)"
fi

check
if ! grep -q '^!\.harness-kit/$' "$FIX_A/.gitignore" 2>/dev/null; then
  pass "A-3: .gitignore에 '!.harness-kit/' 미포함 (un-ignore 없음)"
else
  fail "A-3: .gitignore에 '!.harness-kit/' 가 있음 (un-ignore가 잘못 추가됨)"
fi

check
# spec-x-install-ignore-coverage: 리뷰 도구 출력물 ignore 라인
if grep -q '^specs/\*\*/code-review\*\.md$' "$FIX_A/.gitignore" 2>/dev/null; then
  pass "A-4: .gitignore 에 'specs/**/code-review*.md' 포함 (리뷰 출력 ignore)"
else
  fail "A-4: .gitignore 에 'specs/**/code-review*.md' 없음"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario B: --no-gitignore → "!.harness-kit/" in .gitignore, gitignore=false in config
# ──────────────────────────────────────────────
echo "▶ Scenario B: --no-gitignore 설치"
FIX_B="$(make_fixture)"
trap 'rm -rf "$FIX_A" "$FIX_B"' EXIT

bash "$INSTALL" --yes --no-gitignore "$FIX_B" > /dev/null 2>&1

check
if grep -q '^!\.harness-kit/$' "$FIX_B/.gitignore" 2>/dev/null; then
  pass "B-1: .gitignore에 '!.harness-kit/' 포함 (un-ignore)"
else
  fail "B-1: .gitignore에 '!.harness-kit/' 없음"
fi

check
_gi_val=$(jq -r 'if has("gitignore") then (.gitignore | tostring) else "MISSING" end' "$FIX_B/.harness-kit/harness.config.json" 2>/dev/null || echo "MISSING")
if [ "$_gi_val" = "false" ]; then
  pass "B-2: harness.config.json gitignore=false"
else
  fail "B-2: harness.config.json gitignore 값이 '$_gi_val' (expected: false)"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario C: --gitignore 명시 → ".harness-kit/" in .gitignore
# ──────────────────────────────────────────────
echo "▶ Scenario C: --gitignore 명시 설치"
FIX_C="$(make_fixture)"
trap 'rm -rf "$FIX_A" "$FIX_B" "$FIX_C"' EXIT

bash "$INSTALL" --yes --gitignore "$FIX_C" > /dev/null 2>&1

check
if grep -q '^\.harness-kit/$' "$FIX_C/.gitignore" 2>/dev/null; then
  pass "C-1: --gitignore 플래그 → '.harness-kit/' in .gitignore"
else
  fail "C-1: --gitignore 플래그 → '.harness-kit/' 없음"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario D: 재설치 멱등성 — 중복 항목 없음
# ──────────────────────────────────────────────
echo "▶ Scenario D: 재설치 멱등성"
bash "$INSTALL" --yes "$FIX_A" > /dev/null 2>&1

check
_count=$(grep -c '^\.harness-kit/$' "$FIX_A/.gitignore" 2>/dev/null || echo "0")
if [ "$_count" -eq 1 ]; then
  pass "D-1: 재설치 후 '.harness-kit/' 항목 1개 (중복 없음)"
else
  fail "D-1: '.harness-kit/' 항목이 ${_count}개 (중복 발생)"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario E: update.sh 후 gitignore=true 보존
# ──────────────────────────────────────────────
echo "▶ Scenario E: update.sh 후 gitignore=true 보존"
bash "$UPDATE" --yes "$FIX_A" > /dev/null 2>&1

check
if grep -q '^\.harness-kit/$' "$FIX_A/.gitignore" 2>/dev/null; then
  pass "E-1: update 후 '.harness-kit/' 유지"
else
  fail "E-1: update 후 '.harness-kit/' 사라짐"
fi

check
_gi_val=$(jq -r 'if has("gitignore") then (.gitignore | tostring) else "MISSING" end' "$FIX_A/.harness-kit/harness.config.json" 2>/dev/null || echo "MISSING")
if [ "$_gi_val" = "true" ]; then
  pass "E-2: update 후 harness.config.json gitignore=true 유지"
else
  fail "E-2: update 후 harness.config.json gitignore='$_gi_val' (expected: true)"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario F: update.sh 후 gitignore=false 보존
# ──────────────────────────────────────────────
echo "▶ Scenario F: update.sh 후 gitignore=false 보존"
bash "$UPDATE" --yes "$FIX_B" > /dev/null 2>&1

check
if grep -q '^!\.harness-kit/$' "$FIX_B/.gitignore" 2>/dev/null; then
  pass "F-1: update 후 '!.harness-kit/' 유지"
else
  fail "F-1: update 후 '!.harness-kit/' 사라짐"
fi

check
_gi_val=$(jq -r 'if has("gitignore") then (.gitignore | tostring) else "MISSING" end' "$FIX_B/.harness-kit/harness.config.json" 2>/dev/null || echo "MISSING")
if [ "$_gi_val" = "false" ]; then
  pass "F-2: update 후 harness.config.json gitignore=false 유지"
else
  fail "F-2: update 후 harness.config.json gitignore='$_gi_val' (expected: false)"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario H: self-host guard — .harness-kit/ 가 git-tracked 이면 .gitignore 에 추가 안 함
# ──────────────────────────────────────────────
echo "▶ Scenario H: self-host guard (git-tracked .harness-kit/ 존재 시 .gitignore 추가 안 함)"
FIX_H="$(make_fixture)"
trap 'rm -rf "$FIX_A" "$FIX_B" "$FIX_C" "$FIX_H"' EXIT

# .harness-kit/ 하위에 파일을 직접 만들고 git-track 해서 self-host 상태 시뮬레이션
mkdir -p "$FIX_H/.harness-kit"
echo "tracked" > "$FIX_H/.harness-kit/installed.json"
git -C "$FIX_H" add ".harness-kit/installed.json"
git -C "$FIX_H" commit -q -m "chore: track .harness-kit"

# --yes (기본 gitignore=true) 로 install — self-host guard 가 동작해야 함
bash "$INSTALL" --yes "$FIX_H" > /dev/null 2>&1

check
if ! grep -q '^\.harness-kit/$' "$FIX_H/.gitignore" 2>/dev/null; then
  pass "H-1: self-host 감지 → .gitignore 에 '.harness-kit/' 추가 안 함"
else
  fail "H-1: self-host 감지 실패 → .gitignore 에 '.harness-kit/' 추가됨"
fi

# H-2: spec-x-install-ignore-coverage 정책 전환 — self-host 시에도 헤더 강제 추가
# (이전 정책: 헤더 cosmetic 노이즈 회피 목적으로 skip. 신규 정책: 신규 라인의 고아 라인
#  방지를 위해 헤더 필수. ADR-005 참조 — uninstall awk 가 헤더 시작점을 찾지 못하면
#  신규 라인이 영원히 잔존하는 위험.)
check
if grep -qE '^# harness-kit$' "$FIX_H/.gitignore" 2>/dev/null; then
  pass "H-2: self-host 시 '# harness-kit' 헤더 강제 추가 (고아 라인 방지)"
else
  fail "H-2: self-host 인데 '# harness-kit' 헤더 미추가 (신규 라인 고아화 위험)"
fi

# H-3: self-host 시 신규 라인 (specs/**/code-review*.md) 도 추가되어야 함
check
if grep -q '^specs/\*\*/code-review\*\.md$' "$FIX_H/.gitignore" 2>/dev/null; then
  pass "H-3: self-host 시 'specs/**/code-review*.md' 추가됨 (always-apply)"
else
  fail "H-3: self-host 시 'specs/**/code-review*.md' 미추가"
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

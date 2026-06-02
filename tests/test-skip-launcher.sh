#!/usr/bin/env bash
set -euo pipefail

# test-skip-launcher.sh
# spec-x-skip-perms-launcher: --with-skip-launcher opt-in 런처 설치 검증
#
# 검증 항목:
#   A) install (플래그 없음)        → 런처 미설치 + config skipLauncher=false + .gitignore 미등재
#   B) install --with-skip-launcher → 런처 설치 + .gitignore 등재 + config skipLauncher=true + 내용
#   C) 재설치 멱등                  → .gitignore 런처 라인 정확히 1회
#   (D/E/F 는 후속 task 에서 추가 — update 보존 / uninstall 대칭 / doctor 경고)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL="$ROOT/install.sh"
UPDATE="$ROOT/update.sh"
UNINSTALL="$ROOT/uninstall.sh"
SDD="$ROOT/sources/bin/sdd"

LAUNCHER="claude-dangerously-skip-permissions.sh"
GI_PAT="^/claude-dangerously-skip-permissions\.sh$"

FAIL=0
TOTAL=0
_CLEAN=""

pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
check() { TOTAL=$((TOTAL + 1)); }
cleanup() { for d in $_CLEAN; do rm -rf "$d"; done; }
trap cleanup EXIT

mk() {
  local d
  d="$(mktemp -d)"
  git -C "$d" init -q
  git -C "$d" checkout -b main 2>/dev/null || true
  git -C "$d" config user.email "test@local"
  git -C "$d" config user.name "test"
  echo "$d"
}

_config_sl() {
  # harness.config.json 의 skipLauncher 값 (부재 시 false 로 간주)
  jq -r 'if has("skipLauncher") then (.skipLauncher | tostring) else "false" end' \
    "$1/.harness-kit/harness.config.json" 2>/dev/null || echo "false"
}

echo "═══════════════════════════════════════════"
echo " Skip-Perms Launcher (spec-x-skip-perms-launcher)"
echo "═══════════════════════════════════════════"
echo ""

# ──────────────────────────────────────────────
# Scenario A: 플래그 없음 → 런처 미설치
# ──────────────────────────────────────────────
echo "▶ Scenario A: install (플래그 없음)"
FIX_A="$(mk)"; _CLEAN="$_CLEAN $FIX_A"
bash "$INSTALL" --yes "$FIX_A" > /dev/null 2>&1

check
if [ ! -f "$FIX_A/$LAUNCHER" ]; then
  pass "A-1: 런처 파일 미설치"
else
  fail "A-1: 런처 파일이 설치됨 (플래그 없는데 존재)"
fi

check
_sl_a="$(_config_sl "$FIX_A")"
if [ "$_sl_a" = "false" ]; then
  pass "A-2: config skipLauncher=false"
else
  fail "A-2: config skipLauncher='$_sl_a' (expected false)"
fi

check
if ! grep -qE "$GI_PAT" "$FIX_A/.gitignore" 2>/dev/null; then
  pass "A-3: .gitignore 에 런처 라인 미등재"
else
  fail "A-3: .gitignore 에 런처 라인이 등재됨"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario B: --with-skip-launcher → 런처 설치
# ──────────────────────────────────────────────
echo "▶ Scenario B: install --with-skip-launcher"
FIX_B="$(mk)"; _CLEAN="$_CLEAN $FIX_B"
# 미구현 단계(Red)에서 알 수 없는 옵션으로 die 해도 스크립트가 중단되지 않도록 가드.
# 구현(Green) 후에는 정상 종료하며, 실패 시에도 아래 assertion 이 신호를 잡는다.
bash "$INSTALL" --yes --with-skip-launcher "$FIX_B" > /dev/null 2>&1 || true

check
if [ -f "$FIX_B/$LAUNCHER" ]; then
  pass "B-1: 런처 파일 설치됨"
else
  fail "B-1: 런처 파일 미설치 (플래그 있는데 부재)"
fi

check
_cnt_b=$(grep -cE "$GI_PAT" "$FIX_B/.gitignore" 2>/dev/null || true)
if [ "$_cnt_b" -eq 1 ]; then
  pass "B-2: .gitignore 에 런처 라인 1회 등재"
else
  fail "B-2: .gitignore 런처 라인 $_cnt_b 회 (expected 1)"
fi

check
_sl_b="$(_config_sl "$FIX_B")"
if [ "$_sl_b" = "true" ]; then
  pass "B-3: config skipLauncher=true"
else
  fail "B-3: config skipLauncher='$_sl_b' (expected true)"
fi

check
if grep -q 'exec claude --dangerously-skip-permissions' "$FIX_B/$LAUNCHER" 2>/dev/null; then
  pass "B-4: 런처 내용에 exec claude --dangerously-skip-permissions 포함"
else
  fail "B-4: 런처 내용 불일치"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario C: 재설치 멱등 → 런처 라인 정확히 1회
# ──────────────────────────────────────────────
echo "▶ Scenario C: --with-skip-launcher 재설치 멱등"
bash "$INSTALL" --yes --with-skip-launcher "$FIX_B" > /dev/null 2>&1 || true

check
_cnt_c=$(grep -cE "$GI_PAT" "$FIX_B/.gitignore" 2>/dev/null || true)
if [ "$_cnt_c" -eq 1 ]; then
  pass "C-1: 재설치 후 .gitignore 런처 라인 정확히 1회"
else
  fail "C-1: 재설치 후 런처 라인 $_cnt_c 회 (expected 1)"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario D: update 후 skipLauncher 선택 보존
# ──────────────────────────────────────────────
echo "▶ Scenario D: update 후 보존"
# FIX_B 는 --with-skip-launcher 로 설치된 상태. update 후에도 선택이 보존돼야 한다.
bash "$UPDATE" --yes "$FIX_B" > /dev/null 2>&1 || true

check
if [ -f "$FIX_B/$LAUNCHER" ]; then
  pass "D-1: update 후 런처 파일 보존"
else
  fail "D-1: update 후 런처 파일 소실"
fi

check
_sl_d="$(_config_sl "$FIX_B")"
if [ "$_sl_d" = "true" ]; then
  pass "D-2: update 후 config skipLauncher=true 보존"
else
  fail "D-2: update 후 config skipLauncher='$_sl_d' (expected true)"
fi

check
_cnt_d=$(grep -cE "$GI_PAT" "$FIX_B/.gitignore" 2>/dev/null || true)
if [ "$_cnt_d" -ge 1 ]; then
  pass "D-3: update 후 .gitignore 런처 라인 보존"
else
  fail "D-3: update 후 .gitignore 런처 라인 소실"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario E: uninstall 대칭 제거 (ADR-005)
# ──────────────────────────────────────────────
echo "▶ Scenario E: uninstall 대칭 제거"
FIX_E="$(mk)"; _CLEAN="$_CLEAN $FIX_E"
bash "$INSTALL" --yes --with-skip-launcher "$FIX_E" > /dev/null 2>&1 || true
bash "$UNINSTALL" --yes "$FIX_E" > /dev/null 2>&1 || true

check
if [ ! -f "$FIX_E/$LAUNCHER" ]; then
  pass "E-1: uninstall 후 런처 파일 제거"
else
  fail "E-1: uninstall 후 런처 파일 잔존"
fi

check
_cnt_e=$(grep -cE "$GI_PAT" "$FIX_E/.gitignore" 2>/dev/null || true)
if [ "$_cnt_e" -eq 0 ]; then
  pass "E-2: uninstall 후 .gitignore 런처 라인 제거"
else
  fail "E-2: uninstall 후 .gitignore 런처 라인 $_cnt_e 회 잔존 (orphan)"
fi

echo ""

# ──────────────────────────────────────────────
# Scenario F: sdd doctor .dockerignore 경고 (Dockerfile 존재 시)
# ──────────────────────────────────────────────
echo "▶ Scenario F: doctor .dockerignore 경고"
FIX_F="$(mk)"; _CLEAN="$_CLEAN $FIX_F"
bash "$INSTALL" --yes --with-skip-launcher "$FIX_F" > /dev/null 2>&1 || true
printf 'FROM scratch\n' > "$FIX_F/Dockerfile"
rm -f "$FIX_F/.dockerignore"

# F-1: 런처 설치 + Dockerfile + .dockerignore 미등재 → WARN
out_f1="$(cd "$FIX_F" && bash "$SDD" doctor 2>/dev/null || true)"
check
if printf '%s' "$out_f1" | grep -q "권한 우회 런처 설치됨"; then
  pass "F-1: 런처+Dockerfile+미등재 → doctor WARN 검출"
else
  fail "F-1: WARN 미검출"
fi

# F-2: .dockerignore 에 런처 등재 → PASS 라인
printf 'claude-dangerously-skip-permissions.sh\n' > "$FIX_F/.dockerignore"
out_f2="$(cd "$FIX_F" && bash "$SDD" doctor 2>/dev/null || true)"
check
if printf '%s' "$out_f2" | grep -q "권한 우회 런처 등재"; then
  pass "F-2: .dockerignore 등재 → doctor PASS 라인 검출"
else
  fail "F-2: PASS 라인 미검출"
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

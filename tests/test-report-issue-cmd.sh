#!/usr/bin/env bash
# /hk-report-issue 커맨드 포팅 구조 검증 (sources/installed 존재 + 동일 + 핵심 섹션 + 등록)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/sources/commands/hk-report-issue.md"
INST="$ROOT/.claude/commands/hk-report-issue.md"
README="$ROOT/README.md"
INSTALLED_JSON="$ROOT/.harness-kit/installed.json"

fail=0
pass() { echo "  ✓ $1"; }
err()  { echo "  ✗ $1"; fail=$((fail + 1)); }

echo "▶ hk-report-issue 커맨드 포팅 검증"

# 1. sources 커맨드 존재
[ -f "$SRC" ] && pass "sources 커맨드 존재" || err "sources 커맨드 없음: $SRC"

# 2. installed 커맨드 존재
[ -f "$INST" ] && pass "installed 커맨드 존재" || err "installed 커맨드 없음: $INST"

# 3. sources ↔ installed byte-identical
if [ -f "$SRC" ] && [ -f "$INST" ]; then
  if diff -q "$SRC" "$INST" >/dev/null 2>&1; then pass "sources↔installed 동일"; else err "sources↔installed 불일치"; fi
else
  err "동일성 검사 스킵 (파일 누락)"
fi

# 4. 핵심 섹션 포함
if [ -f "$SRC" ]; then
  for kw in "판정 게이트" "gh issue create" "시크릿" "[Y/n]"; do
    grep -qF "$kw" "$SRC" && pass "섹션 포함: $kw" || err "섹션 누락: $kw"
  done
fi

# 5. installedCommands 등록
if grep -q '"hk-report-issue"' "$INSTALLED_JSON" 2>/dev/null; then pass "installedCommands 등록"; else err "installedCommands 미등록"; fi

# 6. README 언급
if grep -q "hk-report-issue" "$README" 2>/dev/null; then pass "README 언급"; else err "README 미언급"; fi

echo ""
if [ "$fail" -eq 0 ]; then echo "✅ ALL PASS"; exit 0; else echo "❌ $fail FAIL"; exit 1; fi

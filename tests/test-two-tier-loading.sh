#!/usr/bin/env bash
set -euo pipefail

# test-two-tier-loading.sh
# 2단계 로딩 구조 검증:
# - CLAUDE.md / fragment에 @import 없음
# - align 커맨드에 @import 존재
# - fragment word count 적정

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FRAGMENT="$ROOT/sources/claude-fragments/CLAUDE.fragment.md"
NOTIFY="$ROOT/sources/governance/notify.md"
CLAUDE_MD="$ROOT/CLAUDE.md"
# hk-align.md (sources) 또는 설치된 .claude/commands/hk-align.md 중 존재하는 것 사용
ALIGN_CMD=""
for _f in "$ROOT/sources/commands/hk-align.md" "$ROOT/.claude/commands/hk-align.md" "$ROOT/.claude/commands/align.md"; do
  [ -f "$_f" ] && ALIGN_CMD="$_f" && break
done

FAIL=0
TOTAL_CHECKS=0

pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
check() { TOTAL_CHECKS=$((TOTAL_CHECKS + 1)); }

echo "═══════════════════════════════════════════"
echo " Two-Tier Loading Verification"
echo "═══════════════════════════════════════════"
echo ""

# --- Check 1: fragment에 @import 없음 ---
echo "▶ Check 1: CLAUDE.md.fragment에 @agent/ import 없음"
check
if grep -q '^- @agent/' "$FRAGMENT" 2>/dev/null; then
  fail "fragment에 @agent/ import가 여전히 존재"
else
  pass "@agent/ import 제거됨"
fi

# --- Check 2: CLAUDE.md 본체에 @import 없음 (HARNESS-KIT 블록 내) ---
echo ""
echo "▶ Check 2: CLAUDE.md HARNESS-KIT 블록에 @agent/ import 없음"
check
# HARNESS-KIT 블록 추출 후 @agent 검색
HARNESS_BLOCK=$(sed -n '/HARNESS-KIT:BEGIN/,/HARNESS-KIT:END/p' "$CLAUDE_MD")
if echo "$HARNESS_BLOCK" | grep -q '^- @agent/' 2>/dev/null; then
  fail "CLAUDE.md HARNESS-KIT 블록에 @agent/ import 존재"
else
  pass "@agent/ import 제거됨"
fi

# --- Check 3: align 커맨드에 @.harness-kit/agent/ import 존재 ---
echo ""
echo "▶ Check 3: align 커맨드에 @.harness-kit/agent/ import 유지"
check
if grep -q '@\.harness-kit/agent/constitution\.md' "$ALIGN_CMD" 2>/dev/null; then
  pass "align 커맨드에 @.harness-kit/agent/constitution.md 존재"
else
  fail "align 커맨드에 @.harness-kit/agent/constitution.md 누락"
fi

check
if grep -q '@\.harness-kit/agent/agent\.md' "$ALIGN_CMD" 2>/dev/null; then
  pass "align 커맨드에 @.harness-kit/agent/agent.md 존재"
else
  fail "align 커맨드에 @.harness-kit/agent/agent.md 누락"
fi

check
if grep -q '@\.harness-kit/agent/align\.md' "$ALIGN_CMD" 2>/dev/null; then
  pass "align 커맨드에 @.harness-kit/agent/align.md 존재"
else
  fail "align 커맨드에 @.harness-kit/agent/align.md 누락"
fi

# --- Check 4: fragment word count ---
echo ""
echo "▶ Check 4: fragment word count ≤ 150"
check
FRAG_WORDS=$(wc -w < "$FRAGMENT" | tr -d ' ')
echo "  fragment: ${FRAG_WORDS} words"
if [ "$FRAG_WORDS" -le 150 ]; then
  pass "fragment ${FRAG_WORDS}w — 목표(≤150w) 달성"
else
  fail "fragment ${FRAG_WORDS}w — 목표(≤150w) 초과"
fi

# --- Check 5: 핵심 규칙 요약 유지 ---
echo ""
echo "▶ Check 5: 핵심 규칙 요약 유지"
check
if grep -q '핵심 규칙 요약' "$FRAGMENT" 2>/dev/null; then
  pass "핵심 규칙 요약 존재"
else
  fail "핵심 규칙 요약 누락"
fi

# --- Check 6: notify.md (tier-2) 존재 + 알림 프로토콜/선택지 규약 이전됨 ---
echo ""
echo "▶ Check 6: notify.md 에 알림 프로토콜/선택지 규약 이전됨"
check
if [ -f "$NOTIFY" ] && grep -q '의사결정 알림 프로토콜' "$NOTIFY" 2>/dev/null && grep -q '선택지 제시 규약' "$NOTIFY" 2>/dev/null; then
  pass "notify.md 존재 + 알림 프로토콜/선택지 규약 보유"
else
  fail "notify.md 누락 또는 알림 프로토콜/선택지 규약 미이전"
fi

# --- Check 7: align 커맨드에 notify.md import 추가 ---
echo ""
echo "▶ Check 7: align 커맨드에 @.harness-kit/agent/notify.md import"
check
if grep -q '@\.harness-kit/agent/notify\.md' "$ALIGN_CMD" 2>/dev/null; then
  pass "align 커맨드에 @.harness-kit/agent/notify.md 존재"
else
  fail "align 커맨드에 @.harness-kit/agent/notify.md 누락"
fi

# --- Check 8: fragment 에서 알림 프로토콜 본문 헤딩 제거됨 (실제 이전 확인) ---
echo ""
echo "▶ Check 8: fragment 에 알림 프로토콜 본문 헤딩 없음"
check
if grep -qE '^##+ 의사결정 알림 프로토콜' "$FRAGMENT" 2>/dev/null; then
  fail "fragment 에 '의사결정 알림 프로토콜' 헤딩이 여전히 존재 (이전 안 됨)"
else
  pass "fragment 에서 알림 프로토콜 본문 헤딩 제거됨"
fi

# --- 결과 ---
echo ""
echo "═══════════════════════════════════════════"
if [ $FAIL -eq 0 ]; then
  echo " ✅ ALL ${TOTAL_CHECKS} CHECKS PASSED"
else
  echo " ❌ ${FAIL}/${TOTAL_CHECKS} CHECKS FAILED"
fi
echo "═══════════════════════════════════════════"

exit $FAIL

#!/usr/bin/env bash
# tests/test-notify-telegram-markdown.sh
# spec-x-notify-channel-formatter: notify-telegram.sh markdown_simplify 회귀 보장 (F4·A4)
#
# 본 테스트는 notify-telegram.sh 의 markdown_simplify 함수가 마크다운 메타문자를
# 일관되게 제거함을 명시 (Telegram 가독성 회귀 방지).
# Edge case (A4) 는 *현재 동작 명시 fixture* — 메타 잔존 케이스도 *허용 한계* 로 박음.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/../sources/bin/notify-telegram.sh"

if [ ! -f "$NOTIFY_SCRIPT" ]; then
    echo "❌ FAIL: notify-telegram.sh 없음 — $NOTIFY_SCRIPT"
    exit 1
fi

PASS=0
FAIL=0
ok()   { echo "  ✅ PASS: $*"; PASS=$(( PASS + 1 )); }
fail() {
    echo "  ❌ FAIL: $*"
    FAIL=$(( FAIL + 1 ))
    if [ -n "${EXPECTED:-}" ] && [ -n "${ACTUAL:-}" ]; then
        echo "    [expected]"
        printf '%s\n' "$EXPECTED" | sed 's/^/      /'
        echo "    [actual]"
        printf '%s\n' "$ACTUAL" | sed 's/^/      /'
    fi
}

extract_body() {
    local input="$1"
    local raw
    raw=$(NOTIFY_DRYRUN=1 bash "$NOTIFY_SCRIPT" "$input" info 2>/dev/null \
          | tr '\0' '\n')
    # 첫 줄 (헤더 "ℹ️ [REPO]") 제거 + 마지막 빈 줄 제거
    printf '%s' "$raw" | sed -n '2,$p' | sed -e :a -e '/^$/{$d;N;ba' -e '}'
}

run_case() {
    local label="$1"
    local input="$2"
    local expected="$3"
    local actual
    actual=$(extract_body "$input")
    EXPECTED="$expected"
    ACTUAL="$actual"
    if [ "$actual" = "$expected" ]; then
        ok "$label"
    else
        fail "$label"
    fi
}

# ─────────────────────────────────────────────────────────
# 기본 케이스 (F4 1-6)
# ─────────────────────────────────────────────────────────

echo ""
echo "=== 기본 1. **bold** → bold ==="
run_case "B1: **bold** 메타문자 제거" "**bold**" "bold"

echo ""
echo "=== 기본 2. \`code\` → code ==="
run_case "B2: inline code 메타문자 제거" '`code`' "code"

echo ""
echo "=== 기본 3. # heading → heading ==="
run_case "B3: heading 선두 # 제거" "# heading" "heading"

echo ""
echo "=== 기본 4. | a | b | → a — b ==="
run_case "B4: 표 행 셀 join" "| a | b |" "a — b"

echo ""
echo "=== 기본 5. \`\`\` 펜스 라인 제거, 본문 보존 ==="
run_case "B5: 펜스 라인 제거 + 본문 보존" '```
inner body
```' "inner body"

echo ""
echo "=== 기본 6. [text](url) → text (url) ==="
run_case "B6: link 평문화" "[Discord](https://discord.com)" "Discord (https://discord.com)"

# ─────────────────────────────────────────────────────────
# Edge case (A4 7-12)
# ─────────────────────────────────────────────────────────

echo ""
echo "=== Edge 7. ***strong italic*** → strong italic (별표 3겹) ==="
run_case "E7: 별표 3겹 중첩 → 메타문자 모두 제거" "***strong italic***" "strong italic"

echo ""
echo "=== Edge 8. ___strong___ → strong (밑줄 3겹) ==="
run_case "E8: 밑줄 3겹 중첩 → 메타문자 모두 제거" "___strong___" "strong"

echo ""
echo "=== Edge 9. **bold ** test (별표 사이 공백) — 현재 동작 명시 ==="
# 실제 동작: `\*\*([^*]+)\*\*` 가 "bold " 매칭 → 메타문자 제거 → "bold  test"
run_case "E9: unbalanced 별표 (사이 공백) — 메타 제거됨" "**bold ** test" "bold  test"

echo ""
echo "=== Edge 10. **unclosed — 메타 잔존 허용 ==="
# 닫는 별표 없음 → 매칭 실패 → 메타문자 그대로 잔존
run_case "E10: unclosed 별표 — 메타 잔존 (한계 fixture)" "**unclosed" "**unclosed"

echo ""
echo "=== Edge 11. branch 이름에 backtick — sed 매칭 한계 ==="
# `spec-x-notify`test` → 첫 매칭 `spec-x-notify` → "spec-x-notify" + "test`"
# branch 이름에 backtick 사용 금지 (한계 명시)
run_case "E11: backtick branch — 일부만 매칭 (한계 fixture)" '`spec-x-notify`test`' 'spec-x-notifytest`'

echo ""
echo "=== Edge 12. \`\`\`bash 언어 hint → 본문만 보존, 언어 hint 제거 ==="
# 펜스 라인 자체 (` ```bash ` 포함) 가 `/^[[:space:]]*```/` 패턴으로 next → 언어 hint 도 제거
run_case "E12: 언어 hint 펜스 → 라인 자체 제거 + 본문 보존" '```bash
echo hello
```' "echo hello"

# ─────────────────────────────────────────────────────────
# 결과 요약
# ─────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  결과: PASS=$PASS  FAIL=$FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

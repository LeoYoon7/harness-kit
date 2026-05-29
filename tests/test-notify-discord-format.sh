#!/usr/bin/env bash
# tests/test-notify-discord-format.sh
# spec-x-notify-channel-formatter: notify-discord.sh 표 변환 fixture 검증
#
# 실행 모드: NOTIFY_DRYRUN=1 으로 notify-discord.sh 호출.
# .env.discord 검증 우회 + API 호출 대신 청크 본문을 NUL 구분자로 stdout 출력.
#
# 검증 대상:
#   - T1. 표 없는 raw 입력 → 그대로 통과 (회귀 보호)
#   - T2. 마크다운 표 → code-block ASCII 정렬 (TDD red — 현재 함수 비활성으로 fail)
#   - T3. 표 + bold 혼합 → 표만 변환, 그 외 raw 통과
#   - T4. ASCII 전용 표 → 정렬 보존
#   - T5. 한글 전용 표 → 정렬 보존
#   - T6. 한글 + ASCII 혼합 표 → 정렬 깨짐 허용 (NF6 한계, 현재 동작 명시)
#   - T7. Edge cases (빈 표, 한 셀, 컬럼 수 불균형)
#   - T8. 셀 데이터 내 escape `\|` → `|` 복원

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/../sources/bin/notify-discord.sh"

if [ ! -f "$NOTIFY_SCRIPT" ]; then
    echo "❌ FAIL: notify-discord.sh 없음 — $NOTIFY_SCRIPT"
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

# 단일 청크 본문 추출 — 헤더 (첫 줄) 제거 후 trailing newline 정리
extract_body() {
    local input="$1"
    local raw
    raw=$(NOTIFY_DRYRUN=1 bash "$NOTIFY_SCRIPT" "$input" info 2>/dev/null \
          | tr '\0' '\n')
    # 첫 줄 (헤더) 제거
    printf '%s' "$raw" | sed -n '2,$p' | sed -e :a -e '/^$/{$d;N;ba' -e '}'
}

# ─────────────────────────────────────────────────────────
# T1. 표 없는 raw 입력 → 그대로 통과 (회귀 보호)
# ─────────────────────────────────────────────────────────
echo ""
echo "=== T1. 표 없는 raw 입력 ==="
INPUT_T1='**[헤더]**
일반 텍스트 본문
`inline code`'
EXPECTED_T1="$INPUT_T1"
ACTUAL=$(extract_body "$INPUT_T1")
EXPECTED="$EXPECTED_T1"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    ok "T1: raw 입력 → 변경 없이 통과"
else
    fail "T1: raw 입력이 변경됨"
fi

# ─────────────────────────────────────────────────────────
# T2. 마크다운 표 → code-block 안 정렬 ASCII 표
# ─────────────────────────────────────────────────────────
echo ""
echo "=== T2. 마크다운 표 → code-block ASCII (TDD red — fail 예상) ==="
INPUT_T2='| col1 | col2 |
| --- | --- |
| a | b |'
EXPECTED_T2='```
| col1 | col2 |
| ---- | ---- |
| a    | b    |
```'
ACTUAL=$(extract_body "$INPUT_T2")
EXPECTED="$EXPECTED_T2"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    ok "T2: 표 → code-block ASCII 정렬"
else
    fail "T2: 표가 code-block ASCII 로 변환되지 않음"
fi

# ─────────────────────────────────────────────────────────
# T3. 표 + bold 혼합 → 표만 변환, 그 외 raw 통과
# ─────────────────────────────────────────────────────────
echo ""
echo "=== T3. 표 + bold 혼합 ==="
INPUT_T3='**[데이터]**

| col1 | col2 |
| --- | --- |
| a | b |

**[끝]**'
EXPECTED_T3='**[데이터]**

```
| col1 | col2 |
| ---- | ---- |
| a    | b    |
```

**[끝]**'
ACTUAL=$(extract_body "$INPUT_T3")
EXPECTED="$EXPECTED_T3"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    ok "T3: 표만 변환, bold 라벨은 raw 통과"
else
    fail "T3: 표 + bold 혼합 변환 실패"
fi

# ─────────────────────────────────────────────────────────
# T4. ASCII 전용 표 → 정렬 보존 (다중 행)
# ─────────────────────────────────────────────────────────
echo ""
echo "=== T4. ASCII 전용 표 ==="
INPUT_T4='| spec-id | level |
| --- | --- |
| spec-x-notify-channel-formatter | info |
| spec-x-foo | stop |'
EXPECTED_T4='```
| spec-id                         | level |
| ------------------------------- | ----- |
| spec-x-notify-channel-formatter | info  |
| spec-x-foo                      | stop  |
```'
ACTUAL=$(extract_body "$INPUT_T4")
EXPECTED="$EXPECTED_T4"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    ok "T4: ASCII 전용 표 정렬 보존"
else
    fail "T4: ASCII 전용 표 정렬 깨짐"
fi

# ─────────────────────────────────────────────────────────
# T5. 한글 전용 표 → 정렬 보존
# ─────────────────────────────────────────────────────────
echo ""
echo "=== T5. 한글 전용 표 ==="
INPUT_T5='| 항목 | 값 |
| --- | --- |
| 식별자 | 데이터 |
| 분류 | 정보 |'
EXPECTED_T5='```
| 항목   | 값     |
| ------ | ------ |
| 식별자 | 데이터 |
| 분류   | 정보   |
```'
ACTUAL=$(extract_body "$INPUT_T5")
EXPECTED="$EXPECTED_T5"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    ok "T5: 한글 전용 표 정렬 (character count 기반 padding)"
else
    fail "T5: 한글 전용 표 정렬 깨짐"
fi

# ─────────────────────────────────────────────────────────
# T6. 한글 + ASCII 혼합 → 정렬 깨짐 허용 (NF6 한계)
# ─────────────────────────────────────────────────────────
# CJK 폭 보정 안 함. 본 테스트는 *현재 동작 명시* — 변환은 수행되되 시각 정렬 깨짐.
echo ""
echo "=== T6. 한글 + ASCII 혼합 (NF6 한계, 정렬 깨짐 허용) ==="
INPUT_T6='| spec-id | 상태 |
| --- | --- |
| spec-x-foo | 완료 |'
# character count 기반: spec-id (7) / 상태 (2)
# 즉 ASCII spec-id 7자 + 한글 상태 2자
# Discord 등폭 폰트에선 한글이 2배 폭이라 시각 정렬 깨지지만,
# character count 기반 padding 은 변환 자체는 수행. 본 테스트는 변환 성공만 검증.
EXPECTED_T6='```
| spec-id    | 상태 |
| ---------- | ---- |
| spec-x-foo | 완료 |
```'
ACTUAL=$(extract_body "$INPUT_T6")
EXPECTED="$EXPECTED_T6"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    ok "T6: 한글+ASCII 혼합 — character count 기반 변환 수행 (시각 정렬 깨짐 허용, NF6)"
else
    fail "T6: 한글+ASCII 혼합 변환 실패"
fi

# ─────────────────────────────────────────────────────────
# T7. Edge cases: 빈 표 (헤더만), 한 셀, 컬럼 수 불균형
# ─────────────────────────────────────────────────────────
echo ""
echo "=== T7a. 빈 표 (헤더만, 데이터 없음) ==="
INPUT_T7A='| col1 | col2 |
| --- | --- |'
EXPECTED_T7A='```
| col1 | col2 |
| ---- | ---- |
```'
ACTUAL=$(extract_body "$INPUT_T7A")
EXPECTED="$EXPECTED_T7A"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    ok "T7a: 빈 표 — 헤더 + dash separator 만"
else
    fail "T7a: 빈 표 처리 실패"
fi

echo ""
echo "=== T7b. 한 셀 표 (단일 컬럼) ==="
INPUT_T7B='| col |
| --- |
| a |
| bb |'
EXPECTED_T7B='```
| col |
| --- |
| a   |
| bb  |
```'
ACTUAL=$(extract_body "$INPUT_T7B")
EXPECTED="$EXPECTED_T7B"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    ok "T7b: 한 셀 표"
else
    fail "T7b: 한 셀 표 처리 실패"
fi

# ─────────────────────────────────────────────────────────
# T8. 셀 데이터 내 escape `\|` → `|` 복원
# ─────────────────────────────────────────────────────────
echo ""
echo "=== T8. 셀 escape \\| → | 복원 ==="
# 입력은 셀 안에 escape 된 `\|` 를 포함. 출력 시 escape 풀려 `|` 복원.
INPUT_T8='| col1 | col2 |
| --- | --- |
| a \| b | c |'
EXPECTED_T8='```
| col1   | col2 |
| ------ | ---- |
| a | b  | c    |
```'
ACTUAL=$(extract_body "$INPUT_T8")
EXPECTED="$EXPECTED_T8"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    ok "T8: \\| escape 복원"
else
    fail "T8: \\| escape 복원 실패"
fi

# ─────────────────────────────────────────────────────────
# 결과 요약
# ─────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  결과: PASS=$PASS  FAIL=$FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

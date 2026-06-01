#!/usr/bin/env bash
# tests/test-notify-discord-chunking.sh
# spec-x-notify-channel-formatter: 표 변환 ↔ chunking 상호작용 검증 (NF4 적극)
#
# 검증 대상:
#   - C1. CHUNK_SIZE (1700) 초과 입력 → 2개 이상 청크 분할
#   - C2. 각 청크가 valid 마크다운 (펜스 ``` 균형 — 짝수 개 + open 시 close)
#   - C3. 청크 경계가 표 중간이면 양쪽 청크가 ``` 펜스 포함 (fence-balance awk)
#   - C4. 표 변환 후 본문이 CHUNK_SIZE 이하면 단일 청크
#
# 검증 방법: NOTIFY_DRYRUN=1 으로 청크들을 NUL 구분자 출력 받아 분석.

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
fail() { echo "  ❌ FAIL: $*"; FAIL=$(( FAIL + 1 )); }

# 청크 개수 = NUL 구분자 개수
count_chunks() {
    local input="$1"
    NOTIFY_DRYRUN=1 bash "$NOTIFY_SCRIPT" "$input" info 2>/dev/null \
        | tr -cd '\0' | wc -c | tr -d ' '
}

# 각 청크의 ``` 펜스 카운트 (균형 = 짝수)
# 출력: 청크별 펜스 개수, 공백 구분
fence_counts_per_chunk() {
    local input="$1"
    local tmp
    tmp=$(mktemp 2>/dev/null || echo "/tmp/notify-test.$$")
    NOTIFY_DRYRUN=1 bash "$NOTIFY_SCRIPT" "$input" info 2>/dev/null > "$tmp"

    local counts=""
    while IFS= read -r -d '' CHUNK; do
        local n
        n=$(printf '%s' "$CHUNK" | grep -c '^```' 2>/dev/null || true)
        # grep -c 가 매칭 0 시 1 출력하는 호환성 회피
        [ -z "$n" ] && n=0
        counts="$counts $n"
    done < "$tmp"
    rm -f "$tmp" 2>/dev/null || true
    echo "$counts"
}

# 큰 표 생성 (3000+ byte) — 60행 * 행당 약 60 byte = ~3600 byte
generate_large_table() {
    local n="${1:-60}"
    printf '| col1 | col2 | col3 |\n'
    printf '| --- | --- | --- |\n'
    local i=1
    while [ "$i" -le "$n" ]; do
        printf '| row_%04d_data | value_%04d | desc_%04d |\n' "$i" "$i" "$i"
        i=$(( i + 1 ))
    done
}

# 작은 표 생성 (CHUNK_SIZE 이하)
generate_small_table() {
    printf '| col1 | col2 |\n| --- | --- |\n| a | b |\n| c | d |\n'
}

# ─────────────────────────────────────────────────────────
# C1. CHUNK_SIZE 초과 입력 → 2+ 청크 분할
# ─────────────────────────────────────────────────────────
echo ""
echo "=== C1. CHUNK_SIZE 초과 입력 → 다중 청크 ==="
LARGE_TABLE=$(generate_large_table 60)
LARGE_SIZE=$(printf '%s' "$LARGE_TABLE" | wc -c | tr -d ' ')
echo "    입력 크기: ${LARGE_SIZE} byte (CHUNK_SIZE=1700)"
CHUNK_COUNT=$(count_chunks "$LARGE_TABLE")
echo "    청크 수: ${CHUNK_COUNT}"
if [ "$CHUNK_COUNT" -ge 2 ]; then
    ok "C1: 다중 청크 분할 (${CHUNK_COUNT} 청크)"
else
    fail "C1: 단일 청크로 처리됨 (${CHUNK_COUNT}) — CHUNK_SIZE 초과 입력인데 분할 미발생"
fi

# ─────────────────────────────────────────────────────────
# C2. 각 청크 펜스 균형 (짝수 개)
# ─────────────────────────────────────────────────────────
echo ""
echo "=== C2. 각 청크 펜스 균형 ==="
FENCE_COUNTS=$(fence_counts_per_chunk "$LARGE_TABLE")
echo "    청크별 펜스 개수:${FENCE_COUNTS}"
ALL_BALANCED=1
for n in $FENCE_COUNTS; do
    if [ "$(( n % 2 ))" -ne 0 ]; then
        ALL_BALANCED=0
        break
    fi
done
if [ "$ALL_BALANCED" -eq 1 ]; then
    ok "C2: 모든 청크 펜스 균형 (짝수 개)"
else
    fail "C2: 펜스 균형 깨진 청크 존재 — fence-balance 로직 회귀"
fi

# ─────────────────────────────────────────────────────────
# C3. 청크 경계가 표 중간 → 양쪽 청크 ``` 포함
# ─────────────────────────────────────────────────────────
# C2 가 PASS 면 C3 도 만족 (펜스가 짝수 = 양쪽 청크에 펜스 존재).
# 추가 검증: 멀티 청크 중 *모든* 청크가 ``` 1개 이상 포함하는지 (표 입력이라).
echo ""
echo "=== C3. 멀티 청크 시 표 펜스 양쪽 분포 ==="
if [ "$CHUNK_COUNT" -ge 2 ]; then
    ANY_CHUNK_HAS_NO_FENCE=0
    for n in $FENCE_COUNTS; do
        if [ "$n" -eq 0 ]; then
            ANY_CHUNK_HAS_NO_FENCE=1
            break
        fi
    done
    if [ "$ANY_CHUNK_HAS_NO_FENCE" -eq 0 ]; then
        ok "C3: 모든 청크가 표 펜스 포함 (양쪽 valid markdown)"
    else
        fail "C3: 일부 청크에 펜스 없음 — 표 분할 시 한쪽 청크 raw 표가 됨"
    fi
else
    ok "C3: 단일 청크 (skip — C1 단계에서 다중 청크 미발생)"
fi

# ─────────────────────────────────────────────────────────
# C4. 작은 표 → 단일 청크
# ─────────────────────────────────────────────────────────
echo ""
echo "=== C4. CHUNK_SIZE 이하 표 → 단일 청크 ==="
SMALL_TABLE=$(generate_small_table)
SMALL_COUNT=$(count_chunks "$SMALL_TABLE")
if [ "$SMALL_COUNT" -eq 1 ]; then
    ok "C4: 작은 표 단일 청크"
else
    fail "C4: 작은 표가 다중 청크 분할됨 (${SMALL_COUNT}) — chunking 회귀"
fi

# ─────────────────────────────────────────────────────────
# 결과 요약
# ─────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  결과: PASS=$PASS  FAIL=$FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

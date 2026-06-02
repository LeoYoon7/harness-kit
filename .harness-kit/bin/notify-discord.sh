#!/usr/bin/env bash
# notify-discord.sh
# harness-kit SDD 워크플로우용 Discord 알림 헬퍼 (notify-telegram.sh 와 1:1 대응)
#
# 사용법:
#   bash .harness-kit/bin/notify-discord.sh "메시지 본문"
#   bash .harness-kit/bin/notify-discord.sh "메시지" "info"
#   bash .harness-kit/bin/notify-discord.sh "메시지" "stop"
#
# 레벨 (2번째 인자, notify-telegram.sh 와 동일):
#   info   - ℹ️  일반 정보 (기본값)
#   align  - 📊  /hk-align 세션 상태 보고
#   plan   - 📝  spec/plan/task 작성 완료
#   accept - ✅  Plan Accept, Execution 모드 진입
#   stop   - 🛑  Hard Stop, 즉시 개입 필요
#   ship   - 🚀  PR 생성 완료
#   merge  - 🎉  Merged, 다음 단계 제안
#   phase  - 🏁  Phase Ship Go/No-Go
#
# 환경변수 (.env.discord 에서 로드):
#   DISCORD_BOT_TOKEN  - Discord 봇 토큰
#   DISCORD_CHANNEL_ID - 발송 대상 채널 ID
#                        (Discord 클라이언트에서 개발자 모드 활성화 →
#                         채널 우클릭 → "채널 ID 복사")
#
# Discord 마크다운 정책 (telegram 과 결정적 차이):
#   - **bold**, *italic*, __underline__, ~~strike~~, `code`, ```block```,
#     > quote, # ## ### heading, - * bullet — 모두 raw 로 전송 (Discord 가 렌더링).
#   - 표 (|col|col|) — Discord 미지원이므로 셀을 " — " 로 join 변환.
#   - [text](url) — 일반 메시지에선 md link 미지원이므로 "text (url)" 변환
#     (Discord 가 url 만 auto-link 처리).
#   - 메시지 본문 길이 제한 2000자 — 1897자 초과 시 "..." truncate.
#
# 이 파일이 없거나 네트워크 실패 시 silent skip (exit 0) — SDD 흐름 영향 없음.

set -uo pipefail

# 프로젝트 루트 찾기 (이 스크립트 위치 기준 2단계 상위)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ENV_FILE="$PROJECT_ROOT/.env.discord"

# NOTIFY_DRYRUN=1 — 테스트 전용 모드. .env 검증 우회 + API 호출 대신 stdout 출력.
# 청크 본문을 NUL (\0) 구분자로 분리 출력 — 테스트가 `read -d ''` 로 청크별 추출 가능.
# 일반 사용 시 NOTIFY_DRYRUN 미설정 → 기존 동작 (silent skip / API 호출) 유지.
if [ -z "${NOTIFY_DRYRUN:-}" ]; then
    # .env.discord 없으면 조용히 종료
    [ -f "$ENV_FILE" ] || exit 0

    # 환경변수 로드
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a

    # 필수 변수 확인 — 둘 중 하나라도 비어있으면 silent skip
    if [ -z "${DISCORD_BOT_TOKEN:-}" ] || [ -z "${DISCORD_CHANNEL_ID:-}" ]; then
        exit 0
    fi
fi

# 인자 파싱
MESSAGE="${1:-}"
LEVEL="${2:-info}"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <message> [info|align|plan|accept|stop|ship|merge|phase]" >&2
    exit 1
fi

# 명시적 호출이면 cooldown 마커 기록 — 직후 30초 내 hook 자동 알림 차단
# (telegram 과 동일한 마커 파일 공유 — 둘 다 사용 시 한 쪽 명시 호출이
#  다른 쪽 hook 자동 호출까지 함께 차단하여 4중 알림 방지)
if [ "${HARNESS_NOTIFY_FROM_HOOK:-0}" != "1" ]; then
    EXPLICIT_MARKER="${TMPDIR:-/tmp}/notify-explicit-$(basename "$PROJECT_ROOT")"
    date +%s > "$EXPLICIT_MARKER" 2>/dev/null || true
fi

# Discord 마크다운 변환 — 표 → code-block ASCII 정렬 (spec-x-notify-channel-formatter)
# Discord 는 표준 markdown table 미지원이라 raw 통과 시 정렬 깨짐. 본 함수는 표만 추출하여
# code-block 안 정렬된 ASCII 표로 변환. bold/italic/code/quote 등 다른 마크다운은 raw 통과
# (Discord 가 네이티브 렌더링).
#
# 알고리즘 (plan.md A 절 명세):
#   - State machine: outside / seen_header / in_table
#   - 셀 분할 시 `\|` escape 는 PIPE_PH placeholder 로 치환 후 출력 시 복원
#   - 셀 폭 = max(헤더, 데이터의 awk length()) — UAX #11 CJK 보정 없음 (NF6 한계)
#   - 좌측 정렬 padding (`printf "%-Ws"`)
#   - 표 종료 시 펜스 닫기, 비표 라인 그대로 통과
#
# `[text](url)` 변환은 비활성 유지 — 현재 사례 영향 없음 (Out of Scope).
markdown_to_discord() {
    awk '
        function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
        function unescape_pipe(s) { gsub(PIPE_PH, "|", s); return s }
        function is_table_row(s) { return (s ~ /^[[:space:]]*\|.*\|[[:space:]]*$/) }
        function is_separator_row(s,    inner) {
            if (!is_table_row(s)) return 0
            inner = s
            sub(/^[[:space:]]*\|/, "", inner)
            sub(/\|[[:space:]]*$/, "", inner)
            return (inner ~ /^[[:space:]:|*-]+$/)
        }
        function parse_cells(line, arr,    n, i) {
            sub(/^[[:space:]]*\|/, "", line)
            sub(/\|[[:space:]]*$/, "", line)
            n = split(line, arr, /\|/)
            for (i = 1; i <= n; i++) arr[i] = trim(arr[i])
            return n
        }
        function flush_table(    i, j, line, dashes, w, val, ncols) {
            ncols = num_cols
            # 표 인정 조건: 헤더 + separator (table_rows 는 0 일 수 있음 — 빈 표 허용)
            print "```"
            # 헤더 행
            line = "|"
            for (j = 1; j <= ncols; j++) {
                val = unescape_pipe(header_cells[j])
                line = line " " sprintf("%-" col_width[j] "s", val) " |"
            }
            print line
            # dash separator
            line = "|"
            for (j = 1; j <= ncols; j++) {
                dashes = ""
                w = col_width[j]
                while (length(dashes) < w) dashes = dashes "-"
                line = line " " dashes " |"
            }
            print line
            # 데이터 행
            for (i = 1; i <= table_rows; i++) {
                line = "|"
                for (j = 1; j <= ncols; j++) {
                    val = (i SUBSEP j) in table_data ? unescape_pipe(table_data[i, j]) : ""
                    line = line " " sprintf("%-" col_width[j] "s", val) " |"
                }
                print line
            }
            print "```"
            # reset
            table_rows = 0
            num_cols = 0
            delete header_cells
            delete table_data
            for (j in col_width) delete col_width[j]
        }
        function emit_raw(s) {
            print unescape_pipe(s)
        }
        BEGIN {
            PIPE_PH = "\001\002"
            state = "outside"
            table_rows = 0
            num_cols = 0
        }
        {
            line = $0
            gsub(/\\\|/, PIPE_PH, line)
        }
        {
            if (state == "outside") {
                if (is_table_row(line) && !is_separator_row(line)) {
                    # 헤더 후보 buffering
                    header_line_buf = line
                    num_cols = parse_cells(line, header_cells)
                    for (j = 1; j <= num_cols; j++) {
                        w = length(header_cells[j])
                        if (w > col_width[j]) col_width[j] = w
                    }
                    state = "seen_header"
                    next
                }
                emit_raw(line)
                next
            }
            if (state == "seen_header") {
                if (is_separator_row(line)) {
                    state = "in_table"
                    next
                }
                # separator 가 아님 → 헤더 후보 fallback (표 아님)
                emit_raw(header_line_buf)
                num_cols = 0
                delete header_cells
                for (j in col_width) delete col_width[j]
                state = "outside"
                # 현재 라인 재처리 — 표 행이면 다시 outside → 헤더 후보
                if (is_table_row(line) && !is_separator_row(line)) {
                    header_line_buf = line
                    num_cols = parse_cells(line, header_cells)
                    for (j = 1; j <= num_cols; j++) {
                        w = length(header_cells[j])
                        if (w > col_width[j]) col_width[j] = w
                    }
                    state = "seen_header"
                } else {
                    emit_raw(line)
                }
                next
            }
            if (state == "in_table") {
                if (is_table_row(line) && !is_separator_row(line)) {
                    table_rows++
                    cn = parse_cells(line, row_cells)
                    if (cn > num_cols) num_cols = cn
                    for (j = 1; j <= cn; j++) {
                        table_data[table_rows, j] = row_cells[j]
                        w = length(row_cells[j])
                        if (w > col_width[j]) col_width[j] = w
                    }
                    delete row_cells
                    next
                }
                # 표 종료
                flush_table()
                state = "outside"
                emit_raw(line)
                next
            }
        }
        END {
            if (state == "in_table") {
                flush_table()
            } else if (state == "seen_header") {
                emit_raw(header_line_buf)
            }
        }
    '
}
MESSAGE=$(printf '%s\n' "$MESSAGE" | markdown_to_discord)

# 레벨별 이모지 prefix (telegram 과 동일)
case "$LEVEL" in
    info)   PREFIX="ℹ️" ;;
    align)  PREFIX="📊" ;;
    plan)   PREFIX="📝" ;;
    accept) PREFIX="✅" ;;
    stop)   PREFIX="🛑" ;;
    ship)   PREFIX="🚀" ;;
    merge)  PREFIX="🎉" ;;
    phase)  PREFIX="🏁" ;;
    *)      PREFIX="ℹ️" ;;
esac

# 프로젝트 이름 (디렉토리명) — Discord 는 bold 지원하므로 강조
REPO_NAME="$(basename "$PROJECT_ROOT")"

# Discord 한 메시지 본문 2000자 제한 대응 — chunking 으로 분할 전송.
# 본문(MESSAGE)을 라인 단위로 누적해 CHUNK_SIZE 초과 직전마다 청크 emit.
# 추가로 코드 펜스(```) 균형을 보장 — 청크 끝 시점에 펜스가 열려 있으면
# 자동으로 ``` 닫고 다음 청크 시작에 ``` 재오픈해 두 청크 모두 valid 마크다운.
# 한 라인이 CHUNK_SIZE 를 넘는 예외 케이스는 단순 절단 fallback.
# (spec-x-notify-chunk-line-aware)
# 안전 마진: 헤더 약 60자 여유 → 본문 1700 byte (awk length 는 byte 단위).
CHUNK_SIZE=1700

command -v jq >/dev/null 2>&1 || exit 0

# awk 로 라인 누적 + 펜스 카운트 + NUL 구분자 출력.
# 임시 파일에 써서 bash 의 `read -d ''` 로 한 청크씩 추출 — bash 3.2 호환.
TMP_CHUNKS=$(mktemp 2>/dev/null || echo "/tmp/notify-discord.$$.chunks")
printf '%s\n' "$MESSAGE" | awk -v CS="$CHUNK_SIZE" '
    BEGIN { acc = ""; n = 0; fence_open = 0 }
    {
        line_len = length($0) + 1
        is_fence = ($0 ~ /^[[:space:]]*```/) ? 1 : 0
        if (n + line_len > CS && n > 0) {
            # 청크 emit — 펜스 열려 있으면 닫고 다음 청크 ``` 재오픈
            if (fence_open) {
                printf "%s```\n%c", acc, 0
                acc = "```\n"
                n = 4
            } else {
                printf "%s%c", acc, 0
                acc = ""
                n = 0
            }
        }
        if (line_len > CS) {
            # 한 라인 fallback — 펜스 보호 포기, 단순 절단
            while (length($0) >= CS) {
                printf "%s\n%c", substr($0, 1, CS - 1), 0
                $0 = substr($0, CS)
            }
            acc = acc $0 "\n"
            n = length(acc)
            next
        }
        acc = acc $0 "\n"
        n += line_len
        if (is_fence) {
            fence_open = !fence_open
        }
    }
    END { if (acc != "") printf "%s%c", acc, 0 }
' > "$TMP_CHUNKS"

NUM_CHUNKS=$(tr -cd '\0' < "$TMP_CHUNKS" | wc -c | tr -d ' ')
[ "$NUM_CHUNKS" -lt 1 ] && NUM_CHUNKS=1

i=0
while IFS= read -r -d '' CHUNK; do
    if [ "$NUM_CHUNKS" -eq 1 ]; then
        HEADER="${PREFIX} **[${REPO_NAME}]**"
    else
        HEADER="${PREFIX} **[${REPO_NAME}]** [$((i + 1))/${NUM_CHUNKS}]"
    fi
    FULL_MESSAGE="${HEADER}
${CHUNK}"

    if [ -n "${NOTIFY_DRYRUN:-}" ]; then
        # dry-run: 청크 본문을 NUL 구분자로 stdout 출력. 테스트가 `read -d ''` 로 추출.
        printf '%s\0' "$FULL_MESSAGE"
    else
        # Discord API 호출
        # Windows Git Bash 의 UTF-8 처리 이슈 회피를 위해 JSON body 를 임시 파일에 쓴 뒤
        # --data-binary @file 로 전송 (telegram helper 와 동일 패턴).
        TMP_BODY=$(mktemp 2>/dev/null || echo "/tmp/notify-discord.$$.$i.json")
        jq -nc --arg c "$FULL_MESSAGE" '{content:$c}' > "$TMP_BODY" 2>/dev/null
        curl -s -X POST \
            -H "Authorization: Bot ${DISCORD_BOT_TOKEN}" \
            -H "Content-Type: application/json" \
            --data-binary "@$TMP_BODY" \
            "https://discord.com/api/v10/channels/${DISCORD_CHANNEL_ID}/messages" \
            --max-time 5 > /dev/null 2>&1 || true
        rm -f "$TMP_BODY" 2>/dev/null || true

        # Discord rate limit (채널당 5 msg / 5s) 대비 청크 사이 짧은 간격
        [ "$((i + 1))" -lt "$NUM_CHUNKS" ] && sleep 0.3
    fi

    i=$((i + 1))
done < "$TMP_CHUNKS"

rm -f "$TMP_CHUNKS" 2>/dev/null || true

exit 0

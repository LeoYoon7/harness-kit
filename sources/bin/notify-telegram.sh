#!/usr/bin/env bash
# notify-telegram.sh
# harness-kit SDD 워크플로우용 Telegram 알림 헬퍼
#
# 사용법:
#   bash .harness-kit/bin/notify-telegram.sh "메시지 본문"
#   bash .harness-kit/bin/notify-telegram.sh "메시지" "info"
#   bash .harness-kit/bin/notify-telegram.sh "메시지" "stop"
#
# 레벨 (2번째 인자):
#   info   - ℹ️  일반 정보 (기본값)
#   align  - 📊  /hk-align 세션 상태 보고
#   plan   - 📝  spec/plan/task 작성 완료
#   accept - ✅  Plan Accept, Execution 모드 진입
#   stop   - 🛑  Hard Stop, 즉시 개입 필요
#   ship   - 🚀  PR 생성 완료
#   merge  - 🎉  Merged, 다음 단계 제안
#   phase  - 🏁  Phase Ship Go/No-Go
#
# 환경변수 (.env.telegram 에서 로드):
#   TELEGRAM_BOT_TOKEN - BotFather 봇 토큰
#   TELEGRAM_CHAT_ID   - 수신자 chat_id
#
# 이 파일이 없거나 네트워크 실패 시 silent skip (exit 0)

set -uo pipefail

# 프로젝트 루트 찾기 (이 스크립트 위치 기준 2단계 상위)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ENV_FILE="$PROJECT_ROOT/.env.telegram"

# NOTIFY_DRYRUN=1 — 테스트 전용 모드 (notify-discord.sh 와 동일 패턴).
# .env 검증 우회 + API 호출 대신 청크 본문을 NUL 구분자로 stdout 출력.
# 일반 사용 시 미설정 → 기존 동작 (silent skip / API 호출) 유지.
if [ -z "${NOTIFY_DRYRUN:-}" ]; then
    # .env.telegram 없으면 조용히 종료
    [ -f "$ENV_FILE" ] || exit 0

    # 환경변수 로드
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a

    # 필수 변수 확인
    if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
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
# (사용자/SDD 워크플로우의 의도적 알림 + hook 의 turn-end 자동 알림 중복 방지)
# hook 이 호출하는 경우는 HARNESS_NOTIFY_FROM_HOOK=1 환경변수로 식별하여 마커 갱신 skip.
if [ "${HARNESS_NOTIFY_FROM_HOOK:-0}" != "1" ]; then
    EXPLICIT_MARKER="${TMPDIR:-/tmp}/notify-explicit-$(basename "$PROJECT_ROOT")"
    date +%s > "$EXPLICIT_MARKER" 2>/dev/null || true
fi

# 마크다운 → plain text 변환
# - 표 separator 행 (|---|---|) 제거
# - 표 데이터/헤더 행 (|a|b|) 은 셀을 " — " 로 join
# - 코드 펜스 (```) 라인 제거 (내부 내용은 보존)
# - **bold**, __bold__, *italic*, _italic_, `code`, # heading 마커 제거
# - [text](url) → "text (url)" (모바일에서 url 클릭 가능하도록 유지)
markdown_simplify() {
    awk '
        function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
        /^[[:space:]]*```/ { next }
        /^[[:space:]]*\|[[:space:]:|-]+\|[[:space:]]*$/ { next }
        /^[[:space:]]*\|.*\|[[:space:]]*$/ {
            sub(/^[[:space:]]*\|/, "")
            sub(/\|[[:space:]]*$/, "")
            n = split($0, c, /\|/)
            out = ""
            for (i = 1; i <= n; i++) {
                if (i > 1) out = out " — "
                out = out trim(c[i])
            }
            $0 = out
        }
        { print }
    ' | sed -E '
        s/\*\*([^*]+)\*\*/\1/g
        s/__([^_]+)__/\1/g
        s/`([^`]+)`/\1/g
        s/^[[:space:]]*#{1,6}[[:space:]]+//
        s/\[([^]]+)\]\(([^)]+)\)/\1 (\2)/g
        s/\*([^*[:space:]][^*]*[^*[:space:]]?)\*/\1/g
        s/_([^_[:space:]][^_]*[^_[:space:]]?)_/\1/g
    '
}
MESSAGE=$(printf '%s\n' "$MESSAGE" | markdown_simplify)

# 레벨별 이모지 prefix
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

# 프로젝트 이름 (디렉토리명)
REPO_NAME="$(basename "$PROJECT_ROOT")"

# Telegram 한 메시지 본문 4096자 제한 대응 — chunking 으로 분할 전송.
# 본문(MESSAGE)을 라인 단위로 누적해 CHUNK_SIZE 초과 직전마다 청크 emit.
# 각 청크 앞에 헤더(`prefix [repo] [N/M]`) prepend. 라인 경계 보호로 단어/문장
# 중간 끊김 방지 (spec-x-notify-chunk-line-aware). 한 라인이 CHUNK_SIZE 를 넘는
# 예외 케이스는 그 라인만 단순 절단 fallback.
# 안전 마진: 헤더 약 50자 여유 → 본문 3800 byte (awk length 는 byte 단위).
CHUNK_SIZE=3800

command -v jq >/dev/null 2>&1 || exit 0

# awk 로 라인 누적 + NUL 구분자 출력 (각 청크 사이 NUL).
# 임시 파일에 써서 bash 의 `read -d ''` 로 한 청크씩 추출 — bash 3.2 호환.
TMP_CHUNKS=$(mktemp 2>/dev/null || echo "/tmp/notify-telegram.$$.chunks")
printf '%s\n' "$MESSAGE" | awk -v CS="$CHUNK_SIZE" '
    BEGIN { acc = ""; n = 0 }
    {
        line_len = length($0) + 1
        if (n + line_len > CS && n > 0) {
            printf "%s%c", acc, 0
            acc = ""
            n = 0
        }
        if (line_len > CS) {
            # 한 라인이 너무 김 — 단순 절단 fallback (multiple chunks)
            while (length($0) >= CS) {
                printf "%s\n%c", substr($0, 1, CS - 1), 0
                $0 = substr($0, CS)
            }
            acc = $0 "\n"
            n = length(acc)
            next
        }
        acc = acc $0 "\n"
        n += line_len
    }
    END { if (acc != "") printf "%s%c", acc, 0 }
' > "$TMP_CHUNKS"

NUM_CHUNKS=$(tr -cd '\0' < "$TMP_CHUNKS" | wc -c | tr -d ' ')
[ "$NUM_CHUNKS" -lt 1 ] && NUM_CHUNKS=1

i=0
while IFS= read -r -d '' CHUNK; do
    if [ "$NUM_CHUNKS" -eq 1 ]; then
        HEADER="${PREFIX} [${REPO_NAME}]"
    else
        HEADER="${PREFIX} [${REPO_NAME}] [$((i + 1))/${NUM_CHUNKS}]"
    fi
    FULL_MESSAGE="${HEADER}
${CHUNK}"

    if [ -n "${NOTIFY_DRYRUN:-}" ]; then
        # dry-run: 청크 본문을 NUL 구분자로 stdout 출력. 테스트가 `read -d ''` 로 추출.
        printf '%s\0' "$FULL_MESSAGE"
    else
        # Telegram API 호출
        # Windows Git Bash 의 `curl --data-urlencode "text=$var"` 가 한글 UTF-8 을 깨뜨려
        # Telegram 이 400 (Bad Request: text must be encoded in UTF-8) 으로 반려하는 버그를
        # 우회하기 위해 JSON body 를 임시 파일에 쓴 뒤 `--data-binary @file` 로 전송.
        # parse_mode 는 사용하지 않음 — 본문에 들어가는 transcript 발췌의 `[`/`*`/`_`
        # 메타문자가 깨지거나 파싱 실패로 메시지 전체가 거절되는 fragility 회피.
        TMP_BODY=$(mktemp 2>/dev/null || echo "/tmp/notify-telegram.$$.$i.json")
        jq -nc --arg c "$TELEGRAM_CHAT_ID" --arg t "$FULL_MESSAGE" \
            '{chat_id:$c, text:$t}' > "$TMP_BODY" 2>/dev/null
        curl -s -X POST -H "Content-Type: application/json" \
            --data-binary "@$TMP_BODY" \
            "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            --max-time 5 > /dev/null 2>&1 || true
        rm -f "$TMP_BODY" 2>/dev/null || true

        # Telegram rate limit (per-chat 1 msg/s) 대비 청크 사이 짧은 간격
        [ "$((i + 1))" -lt "$NUM_CHUNKS" ] && sleep 0.3
    fi

    i=$((i + 1))
done < "$TMP_CHUNKS"

rm -f "$TMP_CHUNKS" 2>/dev/null || true

exit 0

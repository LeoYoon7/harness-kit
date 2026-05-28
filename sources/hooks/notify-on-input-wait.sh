#!/usr/bin/env bash
# notify-on-input-wait.sh
# Claude Code가 사용자 입력을 대기하는 순간 자동 알림 (dispatcher 경유)
#
# 트리거: Notification 이벤트 (Claude Code가 자동 발화)
#   - Claude가 사용자 응답을 60초 이상 대기 중
#   - 권한 승인 다이얼로그 대기
#   - 명시적 사용자 결정 요청
#
# 입력: Claude Code가 JSON을 stdin으로 전달
#   {
#     "session_id": "...",
#     "transcript_path": "...",
#     "hook_event_name": "Notification",
#     "message": "Claude is waiting for your input"
#   }
#
# 동작:
#   - notify.sh dispatcher 호출 → NM_NOTIFY_CHANNEL 에 따라 telegram/discord 분기
#   - .env.{telegram,discord} 미존재 시 dispatcher 하위 헬퍼가 silent skip
#   - 네트워크 실패 시에도 Claude Code 흐름 유지 (exit 0)
#   - 최근 대화 맥락을 함께 전송하여 사용자가 상황 파악 가능

set -uo pipefail

# 이 스크립트 위치 기준으로 프로젝트 루트 찾기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NOTIFY_HELPER="$PROJECT_ROOT/.harness-kit/bin/notify.sh"

# dispatcher 없으면 조용히 종료
[ -f "$NOTIFY_HELPER" ] || exit 0

# 명시적 호출 cooldown — 직전 30초 내 명시적 notify-telegram 호출이 있었으면
# hook 자동 알림 skip (계층 1 자동 + 계층 2 명시적 호출 중복 차단)
EXPLICIT_MARKER="${TMPDIR:-/tmp}/notify-explicit-$(basename "$PROJECT_ROOT")"
if [ -f "$EXPLICIT_MARKER" ]; then
    last_explicit=$(cat "$EXPLICIT_MARKER" 2>/dev/null)
    if [ -n "$last_explicit" ] && [ $(($(date +%s) - last_explicit)) -lt 30 ]; then
        exit 0
    fi
fi

# Claude Code가 stdin으로 JSON 전달
INPUT_JSON=$(cat)

# hook input 파싱
if command -v jq >/dev/null 2>&1; then
    EVENT=$(echo "$INPUT_JSON" | jq -r '.hook_event_name // ""' 2>/dev/null)
    HOOK_MSG=$(echo "$INPUT_JSON" | jq -r '.message // "의사결정 대기 중"' 2>/dev/null)
    TRANSCRIPT=$(echo "$INPUT_JSON" | jq -r '.transcript_path // ""' 2>/dev/null)
else
    EVENT=""
    HOOK_MSG="의사결정 대기 중"
    TRANSCRIPT=""
fi

# 권한 요청 감지 — Notification 이벤트 + Claude Code 의 권한 메시지 패턴
# 권한 요청 감지 (안전망 — (b)/(c) 미감지 시에만 brief 적용)
IS_PERMISSION=0
if [ "$EVENT" = "Notification" ] && \
   echo "$HOOK_MSG" | grep -qiE 'permission|approve|requesting|needs|allow|승인|허가|권한'; then
    IS_PERMISSION=1
fi

# transcript 분석 — 3 케이스 (a/b/c) 구분
# (a) 순수 도구 권한: (b)/(c) 미감지 + IS_PERMISSION=1 → brief
# (b) 텍스트 선택지: 직전 assistant text 마지막 5줄에 선택지 패턴 → transcript 발췌
# (c) AskUserQuestion: 최근 tool_use 가 AskUserQuestion → 질문/옵션 요약
ASK_USER_Q_BODY=""
CONTEXT=""
HAS_TEXT_CHOICE=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] && command -v jq >/dev/null 2>&1; then
    # (c) AskUserQuestion 최근 호출 추출 — header / question / options.label
    AUQ_JSON=$(tail -100 "$TRANSCRIPT" 2>/dev/null | \
        jq -rs '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "AskUserQuestion")] | last // empty' 2>/dev/null || echo "")

    if [ -n "$AUQ_JSON" ]; then
        ASK_USER_Q_BODY=$(echo "$AUQ_JSON" | jq -r '
            "[질문 " + (.input.questions | length | tostring) + "개]\n" +
            ([.input.questions | to_entries[] |
                (.value.header // "" | if . == "" then "" else "[" + . + "] " end) as $hdr |
                "\(.key + 1). \($hdr)\(.value.question)\n   옵션: " +
                (.value.options | map(.label) | join(" / "))
            ] | join("\n"))
        ' 2>/dev/null || echo "")
    fi

    # (b) 직전 assistant text 발췌 (기존 로직 유지)
    CONTEXT=$(tail -100 "$TRANSCRIPT" 2>/dev/null | \
              jq -rs '[.[] | select(.type == "assistant") | (.message.content // []) | map(select(.type == "text") | .text) | join("\n") | select(. != "")] | last // "" | .[:3000]' 2>/dev/null || echo "")

    # 선택지 패턴 감지 — 마지막 단락 (직전 5줄) 만 매칭 (false positive 차단)
    # `^\d+\)` 제거 — 회고/예시 텍스트 오탐 원인 (Critique 발견)
    if [ -n "$CONTEXT" ]; then
        LAST_PARAGRAPH=$(echo "$CONTEXT" | tail -5)
        if echo "$LAST_PARAGRAPH" | grep -qE '\[선택지\]|\[권장\]|\[Recommendation\]|\[Y/n\]|\[y/N\]|\[의사결정 요청\]|\[Decision Request\]'; then
            HAS_TEXT_CHOICE=1
        fi
    fi
fi

# 현재 브랜치 정보
BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current 2>/dev/null || echo "unknown")

# 알림 본문 분기 — 우선순위: (c) > (b) > (a) > 일반
if [ -n "$ASK_USER_Q_BODY" ]; then
    NOTIFY_BODY="사용자 질문 대기
Branch: $BRANCH

$ASK_USER_Q_BODY"
elif [ "$HAS_TEXT_CHOICE" = "1" ]; then
    NOTIFY_BODY="사용자 선택 대기
Branch: $BRANCH

[최근 Claude 메시지]
$CONTEXT"
elif [ "$IS_PERMISSION" = "1" ]; then
    NOTIFY_BODY="권한 승인 대기
Branch: $BRANCH
$HOOK_MSG"
elif [ -n "$CONTEXT" ]; then
    NOTIFY_BODY="사용자 입력 대기 중
Branch: $BRANCH

[최근 Claude 메시지 일부]
$CONTEXT"
else
    NOTIFY_BODY="사용자 입력 대기 중
Branch: $BRANCH
Message: $HOOK_MSG"
fi

# Dedupe — Notification + Stop 양쪽 hook 발화로 인한 같은 본문 중복 차단
# Notification 의 idle timeout(~60초) 과 Stop 의 turn-end 발화 간격을 커버하도록 TTL 300초.
# 같은 fingerprint 가 최근 300초 내 발화됐으면 skip. 본문이 다르면(의미 있는 새 알림) 통과.
DEDUP_FILE="${TMPDIR:-/tmp}/notify-dedupe-$(basename "$PROJECT_ROOT")"
FP=$(printf '%s' "$NOTIFY_BODY" | md5sum 2>/dev/null | awk '{print $1}')
NOW=$(date +%s)
if [ -n "$FP" ] && [ -f "$DEDUP_FILE" ]; then
    last_ts=$(awk -F: -v fp="$FP" '$2==fp { print $1 }' "$DEDUP_FILE" 2>/dev/null | tail -1)
    if [ -n "$last_ts" ] && [ $((NOW - last_ts)) -lt 300 ]; then
        exit 0
    fi
fi
[ -n "$FP" ] && echo "$NOW:$FP" >> "$DEDUP_FILE" 2>/dev/null
# 파일 비대화 방지 — 100줄 초과 시 최근 50줄만 유지
if [ -f "$DEDUP_FILE" ] && [ "$(wc -l < "$DEDUP_FILE" 2>/dev/null || echo 0)" -gt 100 ]; then
    tail -50 "$DEDUP_FILE" > "$DEDUP_FILE.tmp" 2>/dev/null && mv -f "$DEDUP_FILE.tmp" "$DEDUP_FILE" 2>/dev/null
fi

# dispatcher 호출 (실패해도 Claude Code 흐름 유지)
# HARNESS_NOTIFY_FROM_HOOK=1 으로 하위 helper 가 explicit cooldown 마커를 갱신하지 않게 표시
HARNESS_NOTIFY_FROM_HOOK=1 bash "$NOTIFY_HELPER" "$NOTIFY_BODY" stop >/dev/null 2>&1 || true

exit 0

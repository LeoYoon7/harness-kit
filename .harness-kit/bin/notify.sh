#!/usr/bin/env bash
# harness-kit SDD 알림 dispatcher — NM_NOTIFY_CHANNEL 값에 따라 telegram/discord 헬퍼로 분기
#
# 사용법 (notify-telegram.sh / notify-discord.sh 와 동일 인터페이스):
#   bash .harness-kit/bin/notify.sh "메시지 본문"
#   bash .harness-kit/bin/notify.sh "메시지" "info"
#   bash .harness-kit/bin/notify.sh "메시지" "stop"
#
# 레벨 (info|align|plan|accept|stop|ship|merge|phase) — 하위 헬퍼와 동일.
#
# 채널 라우팅 (환경변수 NM_NOTIFY_CHANNEL):
#   telegram                  → notify-telegram.sh 호출
#   discord                   → notify-discord.sh  호출
#   none / 미설정 / 알 수 없는 값 → 발송 안 함 (silent skip)
#
# 채널은 launcher 가 export (telegram.sh → telegram, discord.sh → discord).
# 직접 claude 실행 시 미설정 → silent skip (spec-x-notify-launcher-only 이후).
# 발송 측 명시성 원칙 — launcher 가 채널을 명시 선언했을 때만 발송.
#
# 'both' 는 spec-x-notify-drop-both 에서 제거 — ADR-004 의 단일 소스 원칙과 충돌
# (응답 측 ack 가 한쪽 채널에만 도달 → 반대 채널에 "응답 미완" 인상 잔존).
# Redundancy 가 필요하면 외부 wrapper 로 두 helper 를 직접 호출.
#
# 하위 헬퍼가 없거나 .env.{telegram,discord} 가 없으면 헬퍼 내부에서 silent skip.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MESSAGE="${1:-}"
LEVEL="${2:-info}"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <message> [info|align|plan|accept|stop|ship|merge|phase]" >&2
    exit 1
fi

CHANNEL="${NM_NOTIFY_CHANNEL:-none}"

call_helper() {
    local helper="$1"
    local path="$SCRIPT_DIR/$helper"
    [ -f "$path" ] || return 0
    bash "$path" "$MESSAGE" "$LEVEL" || true
}

case "$CHANNEL" in
    telegram) call_helper "notify-telegram.sh" ;;
    discord)  call_helper "notify-discord.sh" ;;
    *)
        # none / 미설정 / 알 수 없는 값 → silent skip
        # launcher 가 명시한 채널만 발송 (spec-x-notify-launcher-only)
        : ;;
esac

exit 0

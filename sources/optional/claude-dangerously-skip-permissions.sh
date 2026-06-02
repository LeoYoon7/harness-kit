#!/usr/bin/env bash
# Claude Code 를 권한 확인 절차 없이 실행하는 로컬 런처 (opt-in, 개인 편의용)
#
# 본 런처는 install.sh --with-skip-launcher 로만 설치되며, 대상 프로젝트의
# .gitignore 에 등재되어 커밋되지 않는다. Claude Code 의 권한 시스템을 전면
# 우회하므로 설치를 선택한 사용자 본인의 환경에서만 사용한다.
set -euo pipefail
exec claude --dangerously-skip-permissions "$@"

#!/usr/bin/env bash
# gemini-review.sh
# harness-kit — 현재 spec 브랜치의 코드 변경을 Gemini CLI 로 cross-model 리뷰
#
# 사용법:
#   bash .harness-kit/bin/gemini-review.sh
#
# 출력:
#   specs/<spec-dir>/code-review-gemini.md
#
# 의존성: bash 3.2+, jq, git, gemini CLI (https://geminicli.com)
# 실행 모드: read-only (gemini --approval-mode plan)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

# 1. gemini CLI 존재 확인
if ! command -v gemini >/dev/null 2>&1; then
    echo "✗ gemini CLI 가 설치되지 않았습니다 (https://geminicli.com)" >&2
    exit 1
fi

# 2. 활성 spec 식별
SDD_BIN="$PROJECT_ROOT/.harness-kit/bin/sdd"
if [ ! -x "$SDD_BIN" ]; then
    echo "✗ sdd 가 설치되지 않았습니다: $SDD_BIN" >&2
    exit 1
fi
STATUS_JSON=$(bash "$SDD_BIN" status --json --no-drift 2>/dev/null)
if [ -z "$STATUS_JSON" ]; then
    echo "✗ sdd status --json 호출 실패" >&2
    exit 1
fi

SPEC_ID=$(echo "$STATUS_JSON" | jq -r '.spec // empty')
if [ -z "$SPEC_ID" ]; then
    echo "✗ 활성 spec 이 없습니다" >&2
    exit 1
fi

# spec 디렉토리 탐색 (spec-x-{slug} 또는 spec-{N}-{seq}-{slug})
SPEC_DIR=""
for d in specs/${SPEC_ID}*/; do
    [ -d "$d" ] || continue
    SPEC_DIR="${d%/}"
    break
done

if [ -z "$SPEC_DIR" ]; then
    echo "✗ spec 디렉토리를 찾을 수 없습니다: $SPEC_ID" >&2
    exit 1
fi

if [ ! -f "$SPEC_DIR/spec.md" ]; then
    echo "✗ $SPEC_DIR/spec.md 가 없습니다" >&2
    exit 1
fi

# 3. PR base 결정 (phase base 또는 main)
BASE_BRANCH=$(echo "$STATUS_JSON" | jq -r '.baseBranch // "main"')
if [ -z "$BASE_BRANCH" ] || [ "$BASE_BRANCH" = "null" ]; then
    BASE_BRANCH="main"
fi

# 4. diff 범위 확인
DIFF_STAT=$(git diff "${BASE_BRANCH}...HEAD" --stat 2>/dev/null)
if [ -z "$DIFF_STAT" ]; then
    echo "✗ 리뷰할 변경이 없습니다 (${BASE_BRANCH}...HEAD)" >&2
    exit 1
fi

# 5. 입력 본문 구성 (stdin 으로 전달 — argv 크기 한계 회피)
INPUT_FILE=$(mktemp)
{
    echo "# Spec ($SPEC_ID)"
    echo
    cat "$SPEC_DIR/spec.md"
    echo
    echo "---"
    echo
    echo "# Diff (${BASE_BRANCH}...HEAD)"
    echo
    echo '```diff'
    git diff "${BASE_BRANCH}...HEAD"
    echo '```'
} > "$INPUT_FILE"

# 6. 짧은 지시문 (argv 안전 크기)
INSTRUCTION="당신은 독립적인 시니어 개발자 코드 리뷰어입니다. 위 spec 의 요구사항과 실제 코드 변경 (diff) 을 비교하여 다음 3가지 관점에서 리뷰하세요. (1) Spec 대비 구현 검증 — Functional Requirements 모두 충족됐는가, scope creep 은 없는가. (2) 코드 품질 — KISS / DRY / Feature Envy / Dead Code / 네이밍 / 에러 처리. (3) 테스트 커버리지 — happy path / edge case / 동작 검증 vs 구현 검증. 발견된 문제마다 심각도 (Critical / Major / Minor) 를 매기고, 반드시 파일경로:라인번호 형식으로 위치를 명시하세요. 발견 없음인 관점은 '발견 없음' 으로 표기. 출력은 한국어 마크다운 형식. 첫 줄은 '# Code Review (Gemini): ${SPEC_ID}'. 다음 섹션: ## 요약 (전체 평가 Approve/Request Changes/Comment, Critical N, Major N, Minor N), ## 상세 리뷰 (### 1. Spec 대비 구현 검증, ### 2. 코드 품질, ### 3. 테스트 커버리지), ## 권고사항. 다른 텍스트는 출력하지 마세요."

OUTPUT_FILE="$SPEC_DIR/code-review-gemini.md"
echo "🔍 Gemini 리뷰 실행 중 ($SPEC_ID, base=$BASE_BRANCH)..." >&2

GEMINI_STDERR=$(mktemp)
if ! gemini -p "$INSTRUCTION" --approval-mode plan < "$INPUT_FILE" > "$OUTPUT_FILE" 2>"$GEMINI_STDERR"; then
    echo "✗ gemini CLI 호출 실패" >&2
    echo "--- gemini stderr ---" >&2
    cat "$GEMINI_STDERR" >&2
    rm -f "$OUTPUT_FILE" "$GEMINI_STDERR" "$INPUT_FILE"
    exit 1
fi
rm -f "$GEMINI_STDERR" "$INPUT_FILE"

if [ ! -s "$OUTPUT_FILE" ]; then
    echo "✗ Gemini 가 빈 응답을 반환했습니다" >&2
    rm -f "$OUTPUT_FILE"
    exit 1
fi

# 7. 요약 추출 (마크다운 리스트 마커 / 공백 변형 허용)
echo "✅ Gemini 리뷰 완료: $OUTPUT_FILE" >&2
grep -E "^[-*]\s+(전체 평가|Critical|Major|Minor)" "$OUTPUT_FILE" 2>/dev/null | head -4 >&2 || true

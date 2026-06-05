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
# 실행 모드: 방어적 래퍼 — --approval-mode plan 의 read-only 보장을 신뢰하지 않고,
#           실행 전후 HEAD/워킹트리 스냅샷으로 부수효과(커밋/파일변경)를 감지·거부한다
#           (spec-x-gemini-review-sandbox: gemini 가 plan 모드에서 워크스페이스를 변조한 사고 대응).

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

# 부수효과 감지용 사전 스냅샷 (--approval-mode plan 의 read-only 보장은 신뢰 불가)
BEFORE_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "")
PRE_STATUS=$(git status --porcelain 2>/dev/null || echo "")

# gemini stdout 은 repo 밖 TEMP 로 받는다 (검증 통과 후에만 OUTPUT_FILE 로 이동)
OUT_TMP=$(mktemp)
GEMINI_STDERR=$(mktemp)
if ! gemini -p "$INSTRUCTION" --approval-mode plan < "$INPUT_FILE" > "$OUT_TMP" 2>"$GEMINI_STDERR"; then
    echo "✗ gemini CLI 호출 실패" >&2
    echo "--- gemini stderr ---" >&2
    cat "$GEMINI_STDERR" >&2
    rm -f "$OUT_TMP" "$GEMINI_STDERR" "$INPUT_FILE"
    exit 1
fi
rm -f "$GEMINI_STDERR" "$INPUT_FILE"

# 7. 부수효과 감지 — gemini 가 read-only 를 어기고 워크스페이스를 변조했는가
AFTER_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "")
POST_STATUS=$(git status --porcelain 2>/dev/null || echo "")
if [ "$AFTER_HEAD" != "$BEFORE_HEAD" ] || [ "$PRE_STATUS" != "$POST_STATUS" ]; then
    echo "✗ Gemini 가 워크스페이스를 변조했습니다 (read-only 위반) — 리뷰 거부" >&2
    if [ "$AFTER_HEAD" != "$BEFORE_HEAD" ]; then
        echo "  · 신규 커밋:" >&2
        git log --oneline "${BEFORE_HEAD}..${AFTER_HEAD}" 2>/dev/null | sed 's/^/    /' >&2
    fi
    if [ "$PRE_STATUS" != "$POST_STATUS" ]; then
        echo "  · 워킹트리 변경 감지" >&2
    fi
    if [ -z "$PRE_STATUS" ] && [ -n "$BEFORE_HEAD" ]; then
        git reset --hard "$BEFORE_HEAD" >/dev/null 2>&1
        git clean -fd >/dev/null 2>&1
        echo "  · 로컬 변경 자동 원복 완료 (사전 워킹트리 clean)" >&2
    else
        echo "  · 사전 워킹트리가 clean 아님 → 자동 원복 생략, 수동 확인 필요" >&2
    fi
    echo "  ⚠ 원격(push/PR)은 자동 감지·원복 불가 — 직접 확인하세요" >&2
    rm -f "$OUT_TMP"
    exit 1
fi

if [ ! -s "$OUT_TMP" ]; then
    echo "✗ Gemini 가 빈 응답을 반환했습니다" >&2
    rm -f "$OUT_TMP"
    exit 1
fi

# 8. 출력 형식 검증 — 리뷰가 아닌 출력(구현 요약/잡음) 오저장 방지
if ! grep -qE '# Code Review|## 요약' "$OUT_TMP"; then
    echo "✗ Gemini 출력이 리뷰 형식이 아닙니다 (구현 요약/잡음 의심) — 리뷰 거부" >&2
    rm -f "$OUT_TMP"
    exit 1
fi

mv "$OUT_TMP" "$OUTPUT_FILE"

# 9. 요약 추출 (마크다운 리스트 마커 / 공백 변형 허용)
echo "✅ Gemini 리뷰 완료: $OUTPUT_FILE" >&2
grep -E "^[-*]\s+(전체 평가|Critical|Major|Minor)" "$OUTPUT_FILE" 2>/dev/null | head -4 >&2 || true

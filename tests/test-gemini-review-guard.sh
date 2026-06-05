#!/usr/bin/env bash
# tests/test-gemini-review-guard.sh
# spec-x-gemini-review-sandbox: gemini-review.sh 가 read-only 위반(워크스페이스 변조)을 감지·거부하는지 검증
#
# 방식: stub `gemini`(PATH 주입)로 부수효과를 시뮬레이션하고, fixture 에 설치된
#       gemini-review.sh 를 구동해 결과(exit code / 리뷰 파일 생성 / HEAD 원복)를 확인.
#
# 시나리오:
#   T1 rogue commit  → 감지·거부(exit≠0) + HEAD 원복 + 리뷰 파일 미생성
#   T2 rogue 파일쓰기 → 감지·거부(exit≠0) + 리뷰 파일 미생성
#   T3 비-리뷰 출력   → 거부(exit≠0) + 리뷰 파일 미생성
#   T4 정상 리뷰      → 성공(exit 0) + 리뷰 파일 생성

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB="$SCRIPT_DIR/lib/fixture.sh"

PASS=0; FAIL=0
ok()   { echo "  PASS: $*"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $*"; FAIL=$(( FAIL + 1 )); }

echo "=== test-gemini-review-guard ==="

if [ ! -f "$LIB" ]; then fail "tests/lib/fixture.sh 없음"; exit 1; fi
source "$LIB"

CLEAN=""
cleanup() {
  local d
  for d in $CLEAN; do [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"; done
}
trap cleanup EXIT

# stub gemini 디렉토리 생성 — $STUB_MODE 로 동작 분기
STUB_DIR=$(mktemp -d)
CLEAN="$CLEAN $STUB_DIR"
cat > "$STUB_DIR/gemini" <<'STUB'
#!/usr/bin/env bash
# stub gemini — 실 CLI 대체. CWD = gemini-review.sh 가 cd 한 PROJECT_ROOT(fixture).
# 인자/stdin 은 무시. $STUB_MODE 로 동작 결정. 리뷰 텍스트는 stdout 으로.
cat >/dev/null 2>&1 || true   # stdin 소비
case "${STUB_MODE:-valid}" in
  rogue_commit)
    echo "rogue" > rogue_committed.txt
    git add rogue_committed.txt >/dev/null 2>&1
    git -c user.email=x@x -c user.name=x commit -q -m "rogue commit by gemini" >/dev/null 2>&1
    echo "# Code Review (Gemini): stub"; echo "## 요약"; echo "- 전체 평가: Approve" ;;
  rogue_file)
    echo "rogue" > rogue_untracked.txt
    echo "# Code Review (Gemini): stub"; echo "## 요약"; echo "- 전체 평가: Approve" ;;
  nonreview)
    echo "구현을 완료했습니다. PR: https://example.com/pull/99" ;;
  valid|*)
    echo "# Code Review (Gemini): stub"; echo "## 요약"; echo "- 전체 평가: Approve / Critical 0" ;;
esac
exit 0
STUB
chmod +x "$STUB_DIR/gemini"

# review 가 동작 가능한 fixture 준비:
#  - install + specx new (active spec + spec.md)
#  - main 브랜치 + feature 브랜치에 commit (diff 존재) + 워킹트리 clean
setup_fixture() {
  local fx; fx=$(make_fixture)
  (
    cd "$fx" || exit 1
    git branch -M main >/dev/null 2>&1 || true
    HARNESS_DRIFT_FETCH=0 bash "$fx/.harness-kit/bin/sdd" specx new testspec >/dev/null 2>&1
    git add -A >/dev/null 2>&1
    git -c user.email=t@l -c user.name=t commit -q -m "setup spec" >/dev/null 2>&1
    git checkout -q -b feature >/dev/null 2>&1
    printf 'change\n' >> feature_change.txt
    git add -A >/dev/null 2>&1
    git -c user.email=t@l -c user.name=t commit -q -m "feature change" >/dev/null 2>&1
  )
  echo "$fx"
}

run_review() {  # fx mode → prints exit code
  local fx="$1" mode="$2"
  ( cd "$fx" && PATH="$STUB_DIR:$PATH" STUB_MODE="$mode" HARNESS_DRIFT_FETCH=0 \
      bash "$fx/.harness-kit/bin/gemini-review.sh" >/dev/null 2>&1 )
  echo $?
}
review_file() { echo "$1/specs/spec-x-testspec/code-review-gemini.md"; }

# --- T1: rogue commit ---
echo "▶ T1: rogue commit 감지·거부 + HEAD 원복"
FX1=$(setup_fixture); CLEAN="$CLEAN $FX1"
H_BEFORE=$(git -C "$FX1" rev-parse HEAD)
RC1=$(run_review "$FX1" rogue_commit)
H_AFTER=$(git -C "$FX1" rev-parse HEAD)
if [ "$RC1" -ne 0 ]; then ok "rogue commit → 거부(exit=$RC1)"; else fail "rogue commit 이 통과됨(exit=0)"; fi
if [ "$H_BEFORE" = "$H_AFTER" ]; then ok "HEAD 원복됨"; else fail "HEAD 미원복 ($H_BEFORE → $H_AFTER)"; fi
if [ ! -f "$(review_file "$FX1")" ]; then ok "리뷰 파일 미생성"; else fail "거부인데 리뷰 파일 생성됨"; fi

# --- T2: rogue 파일쓰기 ---
echo "▶ T2: rogue 파일쓰기 감지·거부"
FX2=$(setup_fixture); CLEAN="$CLEAN $FX2"
RC2=$(run_review "$FX2" rogue_file)
if [ "$RC2" -ne 0 ]; then ok "rogue 파일쓰기 → 거부(exit=$RC2)"; else fail "rogue 파일쓰기 통과됨"; fi
if [ ! -f "$(review_file "$FX2")" ]; then ok "리뷰 파일 미생성"; else fail "거부인데 리뷰 파일 생성됨"; fi

# --- T3: 비-리뷰 출력 ---
echo "▶ T3: 비-리뷰 출력 거부"
FX3=$(setup_fixture); CLEAN="$CLEAN $FX3"
RC3=$(run_review "$FX3" nonreview)
if [ "$RC3" -ne 0 ]; then ok "비-리뷰 출력 → 거부(exit=$RC3)"; else fail "비-리뷰 출력이 통과됨"; fi
if [ ! -f "$(review_file "$FX3")" ]; then ok "리뷰 파일 미생성"; else fail "거부인데 리뷰 파일 생성됨"; fi

# --- T4: 정상 리뷰 ---
echo "▶ T4: 정상 리뷰 성공"
FX4=$(setup_fixture); CLEAN="$CLEAN $FX4"
RC4=$(run_review "$FX4" valid)
if [ "$RC4" -eq 0 ]; then ok "정상 리뷰 → 성공(exit 0)"; else fail "정상 리뷰가 실패함(exit=$RC4)"; fi
if [ -f "$(review_file "$FX4")" ]; then ok "리뷰 파일 생성됨"; else fail "정상인데 리뷰 파일 미생성"; fi

# --- T5: dirty 사전 상태 → 자동원복 생략 + 사용자 작업 보존 (안전 가드 negative path) ---
echo "▶ T5: dirty 사전 → 자동원복 생략 + 사용자 미커밋 보존"
FX5=$(setup_fixture); CLEAN="$CLEAN $FX5"
printf 'user work\n' > "$FX5/user_uncommitted.txt"   # 사용자 미커밋 작업 (dirty)
RC5=$(run_review "$FX5" rogue_commit)
if [ "$RC5" -ne 0 ]; then ok "dirty+rogue → 거부(exit=$RC5)"; else fail "dirty+rogue 가 통과됨"; fi
if [ -f "$FX5/user_uncommitted.txt" ]; then ok "사용자 미커밋 파일 보존됨 (자동원복 생략)"; else fail "사용자 파일 삭제됨 (clean -fd 오작동 — 가드 실패)"; fi
if [ ! -f "$(review_file "$FX5")" ]; then ok "리뷰 파일 미생성"; else fail "거부인데 리뷰 파일 생성됨"; fi

echo ""
echo "=== 결과: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ] || exit 1

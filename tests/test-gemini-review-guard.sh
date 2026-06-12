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
# capture 모드: argv/stdin 을 repo 밖 $CAPTURE_DIR 로 기록(부수효과 미발생) 후 정상 리뷰.
if [ "${STUB_MODE:-valid}" = "capture" ]; then
  printf '%s\n' "$@" > "${CAPTURE_DIR:?}/argv"
  cat > "${CAPTURE_DIR:?}/stdin"
  echo "# Code Review (Gemini): stub"; echo "## 요약"; echo "- 전체 평가: Approve / Critical 0"
  exit 0
fi
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

# --- T6: 비-ASCII argv 안전 (지시문이 argv 아닌 stdin 으로 전달) ---
# 마커는 ASCII("Feature Envy", INSTRUCTION 고유)만 사용 — git-bash 의 grep argv 손상 회피.
echo "▶ T6: 비-ASCII argv 안전 (argv 순수 ASCII + 지시문 stdin 전달)"
FX6=$(setup_fixture); CLEAN="$CLEAN $FX6"
CAP6=$(mktemp -d); CLEAN="$CLEAN $CAP6"
( cd "$FX6" && PATH="$STUB_DIR:$PATH" STUB_MODE=capture CAPTURE_DIR="$CAP6" HARNESS_DRIFT_FETCH=0 \
    bash "$FX6/.harness-kit/bin/gemini-review.sh" >/dev/null 2>&1 )
if [ -f "$CAP6/argv" ]; then
  if LC_ALL=C grep -q '[^[:print:][:space:]]' "$CAP6/argv"; then
    fail "argv 에 비-ASCII 포함 (CP949 손상 위험)"
  else
    ok "argv 순수 ASCII"
  fi
else
  fail "argv 캡처 실패 (stub 미호출)"
fi
if [ -f "$CAP6/stdin" ] && grep -q "Feature Envy" "$CAP6/stdin"; then
  ok "지시문이 stdin 으로 전달됨"
else
  fail "지시문이 stdin 에 없음 (여전히 argv 전달 의심)"
fi

# --- T7: base 브랜치 부재 → main fallback ---
echo "▶ T7: base 브랜치 부재 → main fallback"
FX7=$(setup_fixture); CLEAN="$CLEAN $FX7"
STATE7="$FX7/.claude/state/current.json"
TMP7=$(mktemp)
jq '.baseBranch="phase-99-missing"' "$STATE7" > "$TMP7" && mv "$TMP7" "$STATE7"
RC7=$(run_review "$FX7" valid)
if [ "$RC7" -eq 0 ]; then ok "base 부재 → fallback 성공(exit 0)"; else fail "base 부재인데 리뷰 실패(exit=$RC7)"; fi
if [ -f "$(review_file "$FX7")" ]; then ok "리뷰 파일 생성됨(main fallback)"; else fail "fallback 실패 — 리뷰 파일 미생성"; fi

# --- T8: installed.json defaultBranch=develop → diff base 가 develop (spec-x-review-base-config) ---
echo "▶ T8: defaultBranch=develop → Diff (develop...HEAD)"
FX8=$(setup_fixture); CLEAN="$CLEAN $FX8"
git -C "$FX8" branch develop main >/dev/null 2>&1
INST8="$FX8/.harness-kit/installed.json"
TMP8=$(mktemp)
jq '.defaultBranch="develop"' "$INST8" > "$TMP8" && mv "$TMP8" "$INST8"
CAP8=$(mktemp -d); CLEAN="$CLEAN $CAP8"
( cd "$FX8" && PATH="$STUB_DIR:$PATH" STUB_MODE=capture CAPTURE_DIR="$CAP8" HARNESS_DRIFT_FETCH=0 \
    bash "$FX8/.harness-kit/bin/gemini-review.sh" >/dev/null 2>&1 )
RC8=$?
if [ "$RC8" -eq 0 ]; then ok "defaultBranch 리뷰 성공(exit 0)"; else fail "defaultBranch 리뷰 실패(exit=$RC8)"; fi
if [ -f "$CAP8/stdin" ] && grep -q "Diff (develop...HEAD)" "$CAP8/stdin"; then
  ok "diff base = develop 반영됨"
else
  fail "diff base 가 develop 이 아님 (defaultBranch 미반영)"
fi

# --- T9: defaultBranch 실재 안 함 → 2단 fallback 종착(main) 으로 진행 ---
echo "▶ T9: defaultBranch 부재 ref → main 종착 fallback"
FX9=$(setup_fixture); CLEAN="$CLEAN $FX9"
INST9="$FX9/.harness-kit/installed.json"
TMP9=$(mktemp)
jq '.defaultBranch="no-such-branch"' "$INST9" > "$TMP9" && mv "$TMP9" "$INST9"
CAP9=$(mktemp -d); CLEAN="$CLEAN $CAP9"
( cd "$FX9" && PATH="$STUB_DIR:$PATH" STUB_MODE=capture CAPTURE_DIR="$CAP9" HARNESS_DRIFT_FETCH=0 \
    bash "$FX9/.harness-kit/bin/gemini-review.sh" >/dev/null 2>&1 )
RC9=$?
if [ "$RC9" -eq 0 ]; then ok "부재 defaultBranch → fallback 성공(exit 0)"; else fail "부재 defaultBranch 인데 리뷰 실패(exit=$RC9)"; fi
if [ -f "$CAP9/stdin" ] && grep -q "Diff (main...HEAD)" "$CAP9/stdin"; then
  ok "diff base = main 종착 fallback 반영됨"
else
  fail "main 종착 fallback 미동작"
fi

echo ""
echo "=== 결과: PASS=$PASS FAIL=$FAIL ==="
[ "$FAIL" -eq 0 ] || exit 1

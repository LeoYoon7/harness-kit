#!/usr/bin/env bash
# tests/test-sdd-spec-new-drift-warn.sh
# spec-20-03 (#158): sdd spec new / specx new 가 브랜치 생성 직전
#   미커밋 install drift(.harness-kit/·.claude/)를 비차단 경고하는지 검증.

set -uo pipefail

PASS=0; FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SDD="$PROJECT_ROOT/sources/bin/sdd"
SDD_LIB_DIR="$PROJECT_ROOT/sources/bin/lib"
SDD_TEMPLATES_DIR="$PROJECT_ROOT/sources/templates"

ok()   { echo "  ✅ PASS: $*"; PASS=$(( PASS + 1 )); }
fail() { echo "  ❌ FAIL: $*"; FAIL=$(( FAIL + 1 )); }

CLEANUP=()
trap 'for d in "${CLEANUP[@]:-}"; do [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"; done' EXIT

# 검증된 fixture 패턴 (test-sdd-phase-activate.sh) 차용
make_fixture() {
  local dir
  dir="$(mktemp -d)"; CLEANUP+=("$dir")
  mkdir -p "$dir/.claude/state"
  mkdir -p "$dir/backlog"
  mkdir -p "$dir/.harness-kit/bin/lib"
  mkdir -p "$dir/.harness-kit/agent/templates"

  cp "$SDD" "$dir/.harness-kit/bin/sdd"
  local f
  for f in "$SDD_LIB_DIR"/*.sh; do
    cp "$f" "$dir/.harness-kit/bin/lib/$(basename "$f")"
  done
  for f in "$SDD_TEMPLATES_DIR"/*.md; do
    cp "$f" "$dir/.harness-kit/agent/templates/$(basename "$f")"
  done

  cat > "$dir/.claude/state/current.json" <<'EOF'
{
  "kitVersion": "0.6.2",
  "stack": "generic",
  "phase": null,
  "spec": null,
  "planAccepted": false,
  "lastTestPass": null,
  "baseBranch": null
}
EOF

  cp "$SDD_TEMPLATES_DIR/queue.md" "$dir/backlog/queue.md"

  git -C "$dir" init -q
  git -C "$dir" config user.email "test@local"
  git -C "$dir" config user.name "test"
  git -C "$dir" commit --allow-empty -m "init" -q

  echo "$dir"
}

# 사전 정의 phase 파일 + 활성화 (spec new 의 전제: active phase)
activate_phase() {
  local dir="$1"
  cat > "$dir/backlog/phase-01.md" <<'EOF'
# phase-01: drift 경고 테스트

## 📋 메타

| 항목 | 값 |
|---|---|
| **Phase ID** | `phase-01` |
| **상태** | Planning |
| **Base Branch** | 없음 / `phase-01` (opt-in) |

## 🎯 배경 및 목표

테스트용 phase.
EOF
  (cd "$dir" && bash .harness-kit/bin/sdd phase activate phase-01 >/dev/null 2>&1)
}

# ─────────────────────────────────────────────────────────
# Check 1: dirty install + sdd spec new → 경고 + rc=0 + spec 생성
#   make_fixture 는 .harness-kit/ 를 커밋하지 않음 → untracked → drift
# ─────────────────────────────────────────────────────────
echo ""
echo "Check 1: dirty install + sdd spec new → 미커밋 경고 + rc=0 + 생성"

F1="$(make_fixture)"
activate_phase "$F1"

out=$(cd "$F1" && bash .harness-kit/bin/sdd spec new foo 2>&1)
rc=$?

if echo "$out" | grep -q "미커밋 install"; then
  ok "spec new: 미커밋 install 경고 출력"
else
  fail "spec new: 경고 누락 — out=$out"
fi

if [ "$rc" -eq 0 ]; then
  ok "spec new: rc=0 (비차단)"
else
  fail "spec new: rc=$rc (0이어야 — 비차단)"
fi

if [ -d "$F1/specs/spec-01-01-foo" ]; then
  ok "spec new: spec 디렉토리 정상 생성"
else
  fail "spec new: spec 디렉토리 미생성"
fi

# ─────────────────────────────────────────────────────────
# Check 2: dirty install + sdd specx new → 경고 + rc=0 + spec-x 생성
# ─────────────────────────────────────────────────────────
echo ""
echo "Check 2: dirty install + sdd specx new → 미커밋 경고 + rc=0 + 생성"

F2="$(make_fixture)"

out=$(cd "$F2" && bash .harness-kit/bin/sdd specx new bar 2>&1)
rc=$?

if echo "$out" | grep -q "미커밋 install"; then
  ok "specx new: 미커밋 install 경고 출력"
else
  fail "specx new: 경고 누락 — out=$out"
fi

if [ "$rc" -eq 0 ]; then
  ok "specx new: rc=0 (비차단)"
else
  fail "specx new: rc=$rc (0이어야 — 비차단)"
fi

if [ -d "$F2/specs/spec-x-bar" ]; then
  ok "specx new: spec-x 디렉토리 정상 생성"
else
  fail "specx new: spec-x 디렉토리 미생성"
fi

# ─────────────────────────────────────────────────────────
# Check 3: clean install (.harness-kit/.claude 커밋) → 경고 없음 (조건부)
# ─────────────────────────────────────────────────────────
echo ""
echo "Check 3: clean install + sdd specx new → 경고 없음 (조건부 발화)"

F3="$(make_fixture)"
git -C "$F3" add .harness-kit .claude backlog >/dev/null 2>&1
git -C "$F3" commit -q --no-verify -m "commit install (clean baseline)" >/dev/null 2>&1

out=$(cd "$F3" && bash .harness-kit/bin/sdd specx new baz 2>&1)
rc=$?

if echo "$out" | grep -q "미커밋 install"; then
  fail "clean 인데 경고 출력됨 (조건부여야) — out=$out"
else
  ok "clean: 미커밋 경고 미출력"
fi

# ─────────────────────────────────────────────────────────
# 결과
# ─────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  결과: PASS=$PASS  FAIL=$FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
[ "$FAIL" -eq 0 ]

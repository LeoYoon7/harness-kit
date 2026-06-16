#!/usr/bin/env bash
# spec-x-defaultbranch-consistency: _resolve_base_branch 해석 체인 단위 검증
# 체인: state.baseBranch(phase) → installed.json defaultBranch → "main",
#       각 후보를 git rev-parse 로 실재 확인 후 미존재면 다음 단계로 fallback.
# 소스 가드([ "${BASH_SOURCE[0]}" = "$0" ]) 덕에 source 시 main 미실행.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SDD="$ROOT/sources/bin/sdd"

echo "=== test-sdd-base-resolution ==="

# shellcheck disable=SC1090
source "$SDD" >/dev/null 2>&1 || true
set +e

T_PASS=0; T_FAIL=0
t_ok()  { echo "  PASS: $*"; T_PASS=$((T_PASS + 1)); }
t_bad() { echo "  FAIL: $*"; T_FAIL=$((T_FAIL + 1)); }

if ! type _resolve_base_branch >/dev/null 2>&1; then
  t_bad "_resolve_base_branch 미정의 (헬퍼 + 소스 가드 필요)"
  echo "=== 결과: PASS=$T_PASS FAIL=$T_FAIL ==="
  exit 1
fi

# resolve_in <baseBranch|""> <defaultBranch|""|__none__> <생성할 브랜치(공백구분)> → 해석 결과 echo
resolve_in() {
  local bb="$1" db="$2" branches="$3" d b
  d="$(mktemp -d)"
  git -C "$d" init -q >/dev/null 2>&1
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  git -C "$d" commit --allow-empty -m init -q
  git -C "$d" branch -M main >/dev/null 2>&1
  for b in $branches; do
    [ "$b" = "main" ] && continue
    git -C "$d" branch "$b" >/dev/null 2>&1
  done
  mkdir -p "$d/.claude/state" "$d/.harness-kit"
  if [ -n "$bb" ]; then
    printf '{"baseBranch":"%s"}\n' "$bb" > "$d/.claude/state/current.json"
  else
    printf '{}\n' > "$d/.claude/state/current.json"
  fi
  if [ "$db" = "__none__" ]; then
    :  # installed.json 부재 케이스
  elif [ -n "$db" ]; then
    printf '{"defaultBranch":"%s"}\n' "$db" > "$d/.harness-kit/installed.json"
  else
    printf '{}\n' > "$d/.harness-kit/installed.json"
  fi
  ( SDD_ROOT="$d"; SDD_STATE="$d/.claude/state/current.json"; _resolve_base_branch )
  rm -rf "$d"
}

t_eq() {  # <got> <expected> <desc>
  if [ "$1" = "$2" ]; then t_ok "$3 → $1"; else t_bad "$3 → '$1' (기대 '$2')"; fi
}

t_eq "$(resolve_in 'phase-1-x' 'develop' 'phase-1-x develop')" "phase-1-x" "baseBranch 우선(실재)"
t_eq "$(resolve_in '' 'develop' 'develop')"                    "develop"   "defaultBranch 선택"
t_eq "$(resolve_in '' '' '')"                                  "main"      "둘 다 없음 → main"
t_eq "$(resolve_in '' '__none__' '')"                          "main"      "installed.json 부재 → main"
t_eq "$(resolve_in 'phase-9-x' 'develop' 'develop')"           "develop"   "baseBranch 미존재(JIT) → defaultBranch (회귀 방지)"
t_eq "$(resolve_in '' 'nope' '')"                              "main"      "defaultBranch 미존재 → main 종착"

echo "=== 결과: PASS=$T_PASS FAIL=$T_FAIL ==="
[ "$T_FAIL" -eq 0 ] || exit 1

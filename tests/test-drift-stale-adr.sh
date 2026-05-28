#!/usr/bin/env bash
# tests/test-drift-stale-adr.sh
#
# Verifies _drift_stale_adr() in sources/bin/sdd:
#   1. Clean state (no fixture ADR) → no "stale ADR" line in drift section
#   2. Fixture ADR with missing path → "stale ADR: 1 (missing-path)" line
#   3. ADR-001 regression: clean state after fixture removal still PASS
#
# bash 3.2+ compatible.

set -euo pipefail

SDD_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SDD_ROOT"

# sources/bin/sdd 호출 (test-sdd-drift.sh 와 일관성) — sources/ 패치가 즉시 테스트에 반영되도록.
SDD_BIN="sources/bin/sdd"
FIXTURE="docs/decisions/ADR-999-stale-fixture.md"
VALID_FIXTURE="docs/decisions/ADR-998-valid-paths-fixture.md"
RELATIVE_FIXTURE="docs/decisions/ADR-997-relative-path-fixture.md"

# Ensure clean state on exit (even on test failure)
cleanup() { rm -f "$FIXTURE"; }
cleanup_valid() { rm -f "$VALID_FIXTURE"; }
cleanup_relative() { rm -f "$RELATIVE_FIXTURE"; }
trap 'cleanup; cleanup_valid; cleanup_relative' EXIT

pass() { printf "  ✓ %s\n" "$1"; }
fail() { printf "  ✗ %s\n" "$1"; echo "    output: $2"; exit 1; }

echo "Test: _drift_stale_adr()"

# ─── Step 1: clean state ─────────────────────────────────────────
cleanup
output=$(HARNESS_DRIFT_FETCH=0 bash "$SDD_BIN" status 2>&1 || true)
if echo "$output" | grep -q "stale ADR"; then
  fail "clean state should not report stale ADR" "$output"
fi
pass "clean state: no stale ADR line"

# ─── Step 2: fixture with missing path ───────────────────────────
mkdir -p docs/decisions
cat > "$FIXTURE" <<'EOF'
---
id: ADR-999
type: decision
date: 2026-05-16
status: accepted
---
# ADR-999: Fixture for stale detection

## Context
Existing path: `sources/bin/sdd`
Missing path: `src/removed-module-fixture-spec-16-03.ts`

## Decision
This ADR exists only for the stale-detection unit test.
EOF

output=$(HARNESS_DRIFT_FETCH=0 bash "$SDD_BIN" status 2>&1 || true)
if ! echo "$output" | grep -q "stale ADR: 1 (missing-path)"; then
  fail "fixture should produce 'stale ADR: 1 (missing-path)' line" "$output"
fi
pass "fixture ADR (1 missing path) → stale ADR: 1 detected"

# ─── Step 3: regression with self-contained valid-paths fixture ──
# Self-contained: a fixture ADR whose backtick paths all exist → no stale line.
# Does NOT depend on ADR-001 body (W3 — spec-17-04).
cleanup
cat > "$VALID_FIXTURE" <<'EOF'
---
id: ADR-998
type: decision
date: 2026-05-17
status: accepted
---
# ADR-998: Fixture for regression — all paths valid

## Context
Existing paths only: `sources/bin/sdd`, `README.md`, `version.json`.

## Decision
This ADR exists only for the regression test (Step 3) — all backtick paths MUST exist.
EOF

output=$(HARNESS_DRIFT_FETCH=0 bash "$SDD_BIN" status 2>&1 || true)
cleanup_valid
if echo "$output" | grep -q "stale ADR"; then
  fail "regression: fixture with all-valid paths should produce no stale line" "$output"
fi
pass "regression: ADR-998 (all-valid-paths fixture) → no stale line"

# ─── Step 4: ../ relative-path token exclude (spec-x-sdd-drift-fixes) ────
# ADR 본문에 ../ 시작하는 path token 만 missing 인 경우 stale 카운트 0 이어야 함.
# 사유: 이런 토큰은 보통 *심볼릭 링크 가설* 이나 *예시 인용* (ADR-003 의 link 모델 비채택 설명 등) 이라
# 실재 파일을 가리키는 의도가 아님.
cat > "$RELATIVE_FIXTURE" <<'EOF'
---
id: ADR-997
type: decision
date: 2026-05-28
status: accepted
---
# ADR-997: Fixture for relative-path exclude

## Context
가설 인용: `../../sources/governance/agent.md` 같은 상대경로 표기는 ADR 본문의
*심볼릭 링크 예시* 일 가능성이 높음. 진단에서 제외해야 함.

## Decision
This ADR exists only for spec-x-sdd-drift-fixes Test D.
EOF

output=$(HARNESS_DRIFT_FETCH=0 bash "$SDD_BIN" status 2>&1 || true)
cleanup_relative
if echo "$output" | grep -q "stale ADR"; then
  fail "ADR with only ../ relative-path token should NOT be flagged stale" "$output"
fi
pass "ADR with only ../ relative-path token → no stale line (false positive exclude)"

echo ""
echo "All tests passed."

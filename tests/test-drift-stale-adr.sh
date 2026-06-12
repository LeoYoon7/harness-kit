#!/usr/bin/env bash
# tests/test-drift-stale-adr.sh
#
# Verifies _drift_stale_adr() in sources/bin/sdd. 각 step 은 *자기 fixture* 의
# ADR 파일명이 stale 목록에 있/없는지만 단언한다 (전역 stale count/부재 의존 금지).
# 사유: _drift_stale_adr 는 docs/decisions/ADR-*.md 를 전역 glob 하므로, 다른
# 테스트(예: test-phase16-integration)가 동시 실행 중 ADR fixture 를 떨구면 전역
# count/부재 단언이 간섭받는다 (spec-x-drift-test-fixture-race: cross-test 견고화).
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
ARCHIVED_SPEC_ADR="docs/decisions/ADR-996-archived-path-fixture.md"
ARCHIVED_SPEC_DIR="archive/specs/spec-x-archived-fixture"
ARCHIVED_BACKLOG_ADR="docs/decisions/ADR-995-archived-backlog-fixture.md"
ARCHIVED_BACKLOG_FILE="archive/backlog/phase-fixture.md"
TEMPLATE_NOTE_FIXTURE="docs/decisions/ADR-994-template-note-fixture.md"

# Ensure clean state on exit (even on test failure)
cleanup() { rm -f "$FIXTURE"; }
cleanup_valid() { rm -f "$VALID_FIXTURE"; }
cleanup_relative() { rm -f "$RELATIVE_FIXTURE"; }
cleanup_archived_spec() { rm -rf "$ARCHIVED_SPEC_DIR"; rm -f "$ARCHIVED_SPEC_ADR"; }
cleanup_archived_backlog() { rm -f "$ARCHIVED_BACKLOG_FILE" "$ARCHIVED_BACKLOG_ADR"; }
cleanup_template_note() { rm -f "$TEMPLATE_NOTE_FIXTURE"; }
trap 'cleanup; cleanup_valid; cleanup_relative; cleanup_archived_spec; cleanup_archived_backlog; cleanup_template_note' EXIT

pass() { printf "  ✓ %s\n" "$1"; }
fail() { printf "  ✗ %s\n" "$1"; echo "    output: $2"; exit 1; }

echo "Test: _drift_stale_adr()"

# ─── Step 1: clean state ─────────────────────────────────────────
cleanup
output=$(HARNESS_DRIFT_FETCH=0 bash "$SDD_BIN" status 2>&1 || true)
if echo "$output" | grep -q "ADR-999-stale-fixture"; then
  fail "own fixture should not be stale in clean state" "$output"
fi
pass "clean state: own fixture not in stale list"

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
if ! echo "$output" | grep -q "ADR-999-stale-fixture"; then
  fail "own fixture (missing path) should be reported stale" "$output"
fi
pass "fixture ADR (missing path) → own fixture detected stale"

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
if echo "$output" | grep -q "ADR-998-valid-paths-fixture"; then
  fail "regression: own all-valid-paths fixture should not be stale" "$output"
fi
pass "regression: ADR-998 (all-valid-paths fixture) → not in stale list"

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
if echo "$output" | grep -q "ADR-997-relative-path-fixture"; then
  fail "own ADR with only ../ relative-path token should NOT be flagged stale" "$output"
fi
pass "ADR with only ../ relative-path token → not in stale list (false positive exclude)"

# ─── Step 5: archived spec path resolution (spec-x-stale-adr-archive-path) ─
# ADR 이 specs/X/spec.md 를 참조하지만 그 spec 이 sdd archive 로
# archive/specs/X/spec.md 로 이동된 경우 → stale 로 잡으면 안 됨 (이동 ≠ 삭제).
mkdir -p "$ARCHIVED_SPEC_DIR"
echo "archived spec fixture" > "$ARCHIVED_SPEC_DIR/spec.md"
cat > "$ARCHIVED_SPEC_ADR" <<'EOF'
---
id: ADR-996
type: decision
date: 2026-06-09
status: accepted
---
# ADR-996: Fixture for archived spec path resolution

## Context
참조 spec (archive 로 이동됨): `specs/spec-x-archived-fixture/spec.md`

## Decision
This ADR exists only for spec-x-stale-adr-archive-path Step 5 — the referenced spec
lives at archive/specs/spec-x-archived-fixture/spec.md after sdd archive.
EOF

output=$(HARNESS_DRIFT_FETCH=0 bash "$SDD_BIN" status 2>&1 || true)
cleanup_archived_spec
if echo "$output" | grep -q "ADR-996-archived-path-fixture"; then
  fail "own ADR referencing an archived spec should NOT be flagged stale" "$output"
fi
pass "archived spec ref (archive/specs/...) → resolved, not in stale list"

# ─── Step 6: archived backlog path resolution (prefix generality) ─────────
# 동일 fallback 이 specs/ 뿐 아니라 backlog/ prefix 에도 동작해야 함.
mkdir -p archive/backlog
echo "archived backlog fixture" > "$ARCHIVED_BACKLOG_FILE"
cat > "$ARCHIVED_BACKLOG_ADR" <<'EOF'
---
id: ADR-995
type: decision
date: 2026-06-09
status: accepted
---
# ADR-995: Fixture for archived backlog path resolution

## Context
참조 backlog 파일 (archive 로 이동됨): `backlog/phase-fixture.md`

## Decision
This ADR exists only for spec-x-stale-adr-archive-path Step 6 — the referenced file
lives at archive/backlog/phase-fixture.md after sdd archive.
EOF

output=$(HARNESS_DRIFT_FETCH=0 bash "$SDD_BIN" status 2>&1 || true)
cleanup_archived_backlog
if echo "$output" | grep -q "ADR-995-archived-backlog-fixture"; then
  fail "own ADR referencing an archived backlog file should NOT be flagged stale" "$output"
fi
pass "archived backlog ref (archive/backlog/...) → resolved, not in stale list"

# ─── Step 7: ADR 템플릿 note 가 자가-트리거하지 않음 (issue #55, spec-x-adr-template-stale-note) ─
# 라이브 템플릿의 note blockquote 를 그대로 ADR 본문에 삽입한다. note 는 stale 검사 규칙을
# *설명*하는 문구이므로, 그 안의 예시 경로가 backtick 토큰이면 자기 자신이 missing-path 로
# 잡혀 note 를 가진 모든 다운스트림 ADR 이 영구 stale 이 된다.
# 이 Step 은 미래에 누군가 트리거 예시(backtick+슬래시+확장자 미실재 경로)를 템플릿에
# 재도입하면 실패한다 — 하드코딩 텍스트가 아니라 grep 으로 라이브 note 를 끌어오므로.
TEMPLATE_NOTE=$(grep '^>' sources/templates/adr.md)
cat > "$TEMPLATE_NOTE_FIXTURE" <<EOF
---
id: ADR-994
type: decision
date: 2026-06-12
status: accepted
---
# ADR-994: Fixture embedding the live ADR template note

$TEMPLATE_NOTE

## Decision
This ADR exists only for issue #55 regression — the live template note MUST NOT self-trigger stale.
EOF

output=$(HARNESS_DRIFT_FETCH=0 bash "$SDD_BIN" status 2>&1 || true)
cleanup_template_note
if echo "$output" | grep -q "ADR-994-template-note-fixture"; then
  fail "live ADR template note must NOT self-trigger stale (issue #55)" "$output"
fi
pass "template note fixture (live note embedded) → not in stale list"

echo ""
echo "All tests passed."

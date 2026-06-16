# Project Constitution

harness-kit is a reliability layer for AI-assisted engineering. The Constitution below defines the invariant laws that make this layer enforceable.

The Constitution defines the invariant laws of this project. All Agents MUST comply with these rules at all times. This document takes precedence over all other instructions.

---

## 1. Authority & Decision Model

### 1.1 Roles
- **User**: Final decision maker and sole merge authority.
- **Agent**: Delegated executor within explicitly approved boundaries.

### 1.2 Decision Ownership
- The Agent MAY propose options with reasoning.
- The User MUST explicitly approve: Work Mode (SDD/FF), Spec scope, Plan (execution contract), and any merge to the main branch.
- The Agent MUST NOT self-approve any of the above.

## 2. Work Modes

### 2.1 Mode A — SDD-P (Spec-Driven Development, Phase-bound)
- A Pull Request is produced. The change belongs to a Phase (multi-spec initiative).
- **REQUIRED for**: New features, architectural changes, non-trivial refactoring.

### 2.2 Mode B — SDD-x (Spec-Driven Development, Solo)
- A Pull Request is produced. The change is self-contained with no Phase affiliation.
- See §5.1 Solo Spec conditions and §6.2 for the `spec-x-{slug}` identifier.

### 2.3 Mode C — FF (Fast Flow)
- No Pull Request is produced.
- ONLY allowed with explicit User approval.
- LIMITED to: Inline fixes, minor wording, config tweaks that do not warrant a PR.
- **State Rule**: FF work MUST NOT modify `state.json`'s active phase/spec.

### 2.4 Work Mode Decision Tree

Use this two-step check at the start of every Alignment Phase (→ agent.md §3):

```
Step 1 — Is a PR required?
  NO  → FF  (Mode C)
  YES → Step 2

Step 2 — Is a Phase required?
  YES → SDD-P  (Mode A)  spec-{phaseN}-{seq}-{slug}
  NO  → SDD-x  (Mode B)  spec-x-{slug}
```

**Edge Cases**: one-line typo → FF; `update.sh` rewrite or PR-UX standardization (PR, no phase) → SDD-x; adding 5 hooks or a new critique workflow (feature) → SDD-P.

## 3. Work Type Model

This section defines the roles and boundaries of work types used in harness-kit. The Agent MUST classify work by this model before starting any task.

### 3.1 Phase (Epic)

- **Role**: A grouping of related work (Specs plus small phase-FF commits). Can serve as an independent integration test and release unit.
- **In-Phase Work Sizing (phase-FF)**: Not every Phase item is a Spec — small/clear/reversible items (1–2 commits) MAY commit directly to the phase branch as **phase-FF** (no spec artifacts, no per-item re-approval; a first-class up-front choice, not just a fallback → agent.md §11.4, ADR-009). Unlike FF (§2.3), phase-FF lands in the Phase PR and MUST NOT change `state.json`'s active spec.
- **Entry Condition**: 3+ Specs, or inter-Spec dependencies exist, or integration testing is required.
- **Exit Condition**: All Specs merged, integration tests PASS, User go/no-go via `/hk-phase-ship`, and (base mode) Phase PR merge (→ agent.md §6.3.2).
- **Phase Ship Rule**: a Phase PR (phase branch → main) MUST NOT be created without explicit User go/no-go; `/hk-phase-ship` (success-criteria + integration-test verification + go/no-go report) MUST complete before PR creation. Phase PR body follows the `phase-ship.md` template.
- **Base Branch (opt-in)**: a Phase MAY have a `phase-{N}-{slug}` base branch — Spec PRs target it instead of main, and it merges to main after all Specs complete (created just-in-time at the first Spec's hk-ship).
- **Identifier**: `phase-{N}` (→ §6.1)

### 3.2 Spec
A single PR unit within a Phase, independently testable + fully functional. **Entry**: a User-approved Plan in the Phase. **Exit**: unit tests PASS + walkthrough/pr_description + PR merge. **PR Target**: `phase-{N}-{slug}` (base mode) else `defaultBranch` (default `main`; → ADR-015). **Identifier**: `spec-{phaseN}-{seq}-{slug}` (→ §6.2).

### 3.3 spec-x (Solo Spec)
A standalone PR with no Phase — urgent fixes / one-offs too small for a Phase. **Entry** (ALL, → §5.1): single-PR-completable; type `chore`/`fix`/`docs`/small `refactor`; no new architecture or features. **Exit**: PR merge + queue.md done update. **PR Target**: `defaultBranch` (default `main`; → ADR-015). **Identifier**: `spec-x-{slug}` (→ §6.2).

### 3.4 Icebox
Holding area for ideas/deferred/future work (free-form in queue.md Icebox section). **Promotion**: related items accumulate → new Phase; standalone → spec-x. **NON-EXECUTABLE** — no code/tasks/commits until promoted to a Phase or spec-x (→ §12).

## 4. Alignment Requirement (Mandatory)

Before any Spec, Plan, or execution:
1. The Agent MUST present: Intent understanding, Work Mode options, and a Recommendation.
2. The User MUST explicitly select a mode. No mode is valid without explicit confirmation.

## 5. Spec, Plan, and PR Contract

### 5.1 Spec Rules
- **One Spec = One Pull Request.**
- If the scope exceeds a single PR, the Spec MUST be split, and overflow moved to the Backlog.
- Every Spec MUST belong to a Phase. Orphan Specs are forbidden (use `phase-0` if no logical home exists).
- **Phase Base Branch Branching Rule**: When creating a new Spec branch in phase base branch mode, the previous Spec's PR MUST be merged into the phase base branch first. If the previous PR is unmerged, the Agent MUST ask the User to merge it before proceeding. If starting before merge is unavoidable, the Agent MUST branch from the previous Spec branch and explicitly notify the User.
- **Exception — Solo Spec**: A Spec MAY be created without a Phase using the `spec-x-{slug}` identifier when ALL of the following conditions are met:
  1. The change is self-contained and completable in a single PR.
  2. The type is limited to `chore`, `fix`, `docs`, or small-scope `refactor`.
  3. No new architectural decisions or feature additions are involved.
  - Solo Specs do NOT require a `phase.md` entry or `queue.md` update.

### 5.2 Plan Accept & Critique Recognition
- A Plan is an execution contract — no execution without an approved Plan. The Plan MUST include branch-creation and test-execution tasks.
- **Mandatory Offer**: on plan completion the Agent MUST present both options ("1) Accept — start execution / 2) Critique — feedback") before waiting for input.
- **Plan Accept Recognition (SSOT)** (case-insensitive): `1`, `Y`, `yes`, `ok`, `accept`, `plan accept`, `/hk-plan-accept`. **Critique**: `2` or `/hk-spec-critique`. Any other response → the Agent MUST re-request the selection.

### 5.3 Premature Execution (Critical)
- **Zero Tolerance**: Writing production code or changing project state BEFORE the User has explicitly approved the `plan.md` is a **CRITICAL VIOLATION**.
- **Planning Mode**: Until approval is given, the Agent MUST remain in PLANNING mode and only edit documentation.

### 5.4 Artifact Integrity (Critical)
- **Template Enforcement**: Generating `phase`, `spec`, `plan`, `task`, `walkthrough`, or `pr_description` WITHOUT reading and following the official templates in `.harness-kit/agent/templates/` is a **CRITICAL VIOLATION**.
- **Language Requirement**: All artifacts MUST be written in **Korean** (except for code, file paths, and standard technical terms) to ensure clear communication with the User.
- **Quality Bar**: Each artifact MUST be rich enough to be self-contained for review. Vague placeholders are not acceptable in finalized artifacts.

### 5.5 Idea Capture Gate
When a new idea/request/tangent arises during active work (Spec execution, PR review, any SDD phase), the Agent MUST NOT execute it immediately — first record it as a one-line `backlog/queue.md` Icebox entry, then present exactly two choices: **1) Continue** (resume active task; idea stays in Icebox) or **2) Park** (update `task.md` progress — `[x]` done, `[ ]` remaining — then re-align to the new work). Executing an unplanned idea without Icebox capture + the User's explicit choice is a VIOLATION.

### 5.6 Opinion Divergence Protocol
When the User's opinion/direction **conflicts** with the active Plan, Spec scope, or Phase goals, the Agent MUST: (1) acknowledge the conflict explicitly (plan says X vs. User suggests Y), (2) propose reconciliation options (amend plan / defer to Icebox / split new Spec), (3) wait for the User's selection, (4) record the decision in the relevant artifact (`plan.md`/`walkthrough.md`/`queue.md`/`phase.md`; during PR review → `walkthrough.md`, the living decision log → agent.md §6.3). The Agent MUST NOT silently follow a divergent opinion without surfacing the conflict first.

### 5.7 Action Confirmation Rules

Governs how the Agent confirms irreversible external actions (push, PR creation).

**Push (`git push`)**
- After Plan Accept, push is **fully automatic** — display a push info block (🚀 Push: 브랜치 `<head> ▶ <base>` / 제목 = `pr_description.md` 첫 줄 / 커밋 수 / 변경 파일 수), then push immediately with **NO user response required**.

**PR Creation**
- Display the info block, then ask exactly one question: `생성할까요? [Y/n]`
- Do NOT use numbered lists (e.g., `1) 생성 / 2) 취소`). The only valid format is `[Y/n]`.
- **Recognized YES** (case-insensitive, proceed): `Y`, `y`, `yes`, `1`, `ok`, `네`, `ㅛ`
- **Recognized NO** (abort and report): `N`, `n`, `no`, `아니`
- **Unrecognized**: Re-display `생성할까요? [Y/n]` once. If still unrecognized, abort and report.
- When called from `hk-ship` (post-Plan-Accept flow): **skip confirmation entirely** (`--no-confirm` mode).

## 6. Identifier System (lowercase, hyphen-separated)

### 6.1 Phase Identifier
- `phase-{N}` (N positive integer; e.g. `phase-01`). Descriptive name lives only in `phase.md`'s title, not the ID/directory.
- **Phase Base Branch**: base-branch mode adds a `phase-{N}-{slug}` branch (slug from phase.md title; e.g. `phase-08-work-model`).

### 6.2 Spec Identifier
- `spec-{phaseN}-{seq}` (seq = 2-digit, reset per phase; e.g. `spec-01-01`). A Spec ID is immutable once assigned.
- **Solo Spec**: `spec-x-{slug}` when no Phase affiliation (→ §5.1). `x` is literal (not a phase number); `{slug}` unique across all specs. E.g. `spec-x-update-migration`.

### 6.3 Layout (Flat)
- `backlog/queue.md` (sdd-managed dashboard) · `backlog/phase-{N}.md` (one flat file/phase: spec table + integration tests + ADR refs) · `specs/spec-{phaseN}-{seq}-{slug}/` (artifacts). `backlog/` = plan, `specs/` = progress log (sibling dirs).
- ADR: `docs/decisions/ADR-{NNN}-{slug}.md` for architectural/cross-Spec/long-lived decisions (routine ones stay in walkthrough/plan/phase). Template `.harness-kit/agent/templates/adr.md`; frontmatter MUST include `type:` from §6.4 vocabulary.

### 6.4 Knowledge Type Vocabulary

Artifacts whose frontmatter exposes a `type:` field MUST use exactly one of the following values:

| Type | Used in | When to apply |
|---|---|---|
| `decision` | ADR only | A non-trivial design choice with rationale; long-lived. |
| `invariant` | ADR + runbook-style notes (shared) | A property the system MUST preserve (e.g. domain ≠ infra). |
| `failure-pattern` | RCA only | A recurring failure with reproduction + prevention. |
| `convention` | ADR + style guide (shared) | A naming/structure rule adopted for consistency. |
| `tradeoff` | ADR only | A choice with explicit cost on the rejected side. |

Rules:
- `type:` MUST be present in any frontmatter that adopts this vocabulary. Both RCA and ADR adopt the same closure (5 values), but each artifact MUST use only the types marked applicable in the "Used in" column above (e.g. ADR MUST NOT use `failure-pattern`; RCA MUST NOT use `decision`).
- Values outside the set are a violation — grep tools rely on closure.
- Vocabulary changes (add / rename / remove) are themselves architecture decisions — record as an ADR with `type: decision`.

### 6.5 Branch Naming
- Spec branch name = spec directory name (`spec-{phaseN}-{seq}-{slug}`), **no `feature/` prefix** (e.g. `spec-01-01-stock-row-locking`). Phase base branch: `phase-{N}-{slug}` (→ §6.1).

## 7. Execution Delegation

### 7.1 Delegation Rule
Once a Plan is explicitly accepted (Plan Accept), the Agent is authorized to:
- Execute tasks in `task.md`, commit per Task, run tests, ship walkthrough, push the feature branch, and create a Pull Request.

### 7.2 Delegation Limits
- Valid ONLY if execution stays within Plan scope.
- Any deviation (e.g., needing a new file, a new dependency, or a new decision) MUST immediately stop execution for re-alignment.

## 8. Task & Commit Integrity

- **One Task = One Commit**: Each task in `task.md` represents one logical unit of work.
- **No Batch Commits**: Grouping multiple tasks into one commit is a CRITICAL VIOLATION.
- **Commit history MUST reflect the intent and order of tasks** (commit subject mentions the SPEC ID).

## 9. Testing Requirements (Two-Tier)

### 9.1 Spec-level (Unit Tests, Mandatory)
All testable behavior a SPEC introduces MUST have passing unit tests before the SPEC is Done. **No Test, No Commit** — committing code without passing tests is prohibited unless justified (e.g. docs-only).

### 9.2 Spec-level Integration Tests (Optional, Declared)
A SPEC MAY require integration tests; if so it MUST declare them in its `Integration Test Required` field, and they MUST pass before ship.

### 9.3 Phase-level (Integration Tests, Mandatory)
A PHASE is Done only when all SPECs are merged AND the phase-level integration scenarios (inline in `backlog/phase-{N}.md`) pass end-to-end; the phase walkthrough MUST attach evidence.

## 10. Git Law (Strict Enforcement)

### 10.1 Branch Protection
- **No Work on `main`**: All work MUST be done on feature branches.
- Direct commits to `main` are strictly forbidden. The Agent MUST verify the current branch before starting any task.

### 10.2 Commit Protocol
- **Pre-Push Validation**: The Agent MUST execute the project's local test suite and confirm it passes before pushing a feature branch for review. **phase-FF exception** (→ §3.1, ADR-009): a phase-FF commit keeps the test requirement (testable changes still need passing tests) but has no per-item Spec PR — its review is folded into the phase-ship PR's integration check, not a separate per-item review.
- **Commit Title Format**: MUST follow `<type>(spec-{phaseN}-{seq}): <description>` (all lowercase).
  - Allowed types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`, `build`, `ci`.
  - Example: `feat(spec-01-01): introduce row-level lock for stock decrement`.
- **Pull Request Creation**: Once a Plan is accepted (→ §7.1), the Agent is authorized to push the feature branch and create a PR as part of the Ship task. Explicit per-action confirmation is not required. The Agent MUST ship `walkthrough.md` / `pr_description.md` under the SPEC directory before PR creation.

## 11. Backlog Law

- Backlog items are NON-EXECUTABLE.
- They MUST NOT produce code changes, tasks, or commits until promoted to a SPEC inside a PHASE with User approval.

## 12. Enforcement

- Violation of any rule invalidates current execution authority.
- The Agent MUST immediately stop, acknowledge the violation, and request user re-alignment.
- Hooks installed under `.claude/settings.json` may enforce specific rules at the tool-call level (e.g., main branch protection, plan-accept gate). Hook stderr output is authoritative.

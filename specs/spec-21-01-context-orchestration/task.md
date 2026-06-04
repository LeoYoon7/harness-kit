# Task List: spec-21-01

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-21.md SPEC 표 — sdd 자동 갱신)
- [x] 사용자 Plan Accept

---

## Task 1: 실패 테스트 작성 (TDD Red)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-21-01-context-orchestration` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 테스트 작성 (TDD Red)
- [x] `tests/test-context-orchestration.sh` 작성 (bash 3.2 호환, `set -uo pipefail`, 3 checks — 단어 예산 가드 제외, critique 대안 C):
  - Check 1: §6.6 에 `orchestrator` / `worker` / `offloading` / `distilled` 용어 grep
  - Check 2: `sources/governance/agent.md` ↔ `.harness-kit/agent/agent.md` parity (`diff -q`)
  - Check 3: `docs/decisions/ADR-010-context-orchestration.md` 존재 + `type: decision`
- [x] `bash tests/test-context-orchestration.sh` 실행 → Fail 확인 (5/6 FAIL — Check 1 용어 4 + Check 3 ADR)
- [x] Commit: `test(spec-21-01): add failing test for context orchestration policy`

---

## Task 2: §6.6 컨텍스트 오케스트레이션 정책 확립 (TDD Green)

> §6.6 규칙 + ADR-010 근거 + 미러는 *하나의 거버넌스 결정* — net-neutral 다이어트 포함 단일 커밋.

### 2-1. 거버넌스 + ADR + 미러
- [x] `sources/governance/agent.md §6.6` 확장: 제목 → `Model & Context Allocation Strategy`, offloading 5축 단락 추가(영어, 간결) + always-on 명시
- [x] net-neutral 다이어트: §6.6 위임 지시 문장(3축 흡수) + docs-only 예외(§6.7 참조 축약) + intro/예시 중복 트림 → 순증 +48w (baseline 7285 → 7333, ±50w 내)
- [x] `docs/decisions/ADR-010-context-orchestration.md` 작성 (frontmatter `type: decision`, 한국어 본문, fork 고유 결정 초점, upstream ADR-005 는 참조로만)
- [x] `.harness-kit/agent/agent.md` 미러 동기화 (parity)
- [x] `bash tests/test-context-orchestration.sh` → 6 checks PASS 확인 (용어 4 + 미러 + ADR)
- [x] `bash tests/test-governance-dedup.sh` → Check 3 +48w(±50w 내) + 그 외 무 NEW 회귀(1/8 FAIL = baseline Check 3 동일)
- [x] Commit: `feat(spec-21-01): establish context orchestration policy (§6.6 + ADR-010)`

---

## Task 3: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [x] 전체 키트 테스트 실행 → 무 NEW 회귀 (`test-context-orchestration` 6/6, `test-governance-dedup` Check 3 만 baseline red)
- [x] **walkthrough.md 작성** (5축 결정·단어 수 before/after 7285→7333 +48w 증거)
- [x] **pr_description.md 작성** (템플릿 준수, base = `phase-21-director-mode`)
- [x] 코드 리뷰 게이트 (§6.3.8): **Gemini cross-model 실행 → Approve** (Critical 0/Major 0/Minor 1, ASCII 반영)
- [x] **Ship Commit**: `docs(spec-21-01): ship walkthrough and pr description`
- [x] **Push**: `git push -u origin spec-21-01-context-orchestration`
- [x] **PR 생성**: base `phase-21-director-mode` 자동 생성
- [x] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 3 (+ Ship) |
| **예상 commit 수** | 3 (test / feat / ship docs) |
| **현재 단계** | Execution (Task 2 완료, 다음 Ship) |
| **마지막 업데이트** | 2026-06-04 |

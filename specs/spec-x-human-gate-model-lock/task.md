# Task List: spec-x-human-gate-model-lock

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> docs/config 성격 — 단위 테스트 없음 (constitution §9.1). TDD 대신 *frontmatter 적용 → grep 확인*.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 표 없음
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [ ] `git checkout -b spec-x-human-gate-model-lock`
- [ ] 계획 산출물(spec/plan/task + queue 등록분) 초기 커밋

---

## Task 2: 게이트 커맨드 잠금 (disable-model-invocation)

### 2-1. human-gate frontmatter 추가 + 동기화
- [ ] `sources/commands/hk-plan-accept.md` + `sources/commands/hk-phase-ship.md` frontmatter 에 `disable-model-invocation: true` 추가
- [ ] `.claude/commands/hk-plan-accept.md` + `.claude/commands/hk-phase-ship.md` 동기화 (설치본)
- [ ] `grep` 으로 4개 파일 모두 frontmatter 보유 확인
- [ ] Commit: `fix(spec-x-human-gate-model-lock): disable-model-invocation 으로 plan-accept·phase-ship 게이트 잠금`

---

## Task 3: 사용 playbook §1.5 정정

### 3-1. 검증 결과 반영 + 동기화
- [ ] `sources/governance/native-feature-usage.md` §1.5 정정 — SlashCommand/Skill tool 기준, `/workflows`(뷰어)·`/team-onboarding` → 👤, `/batch` → 🤖, `disable-model-invocation` 레버 + `/hk-*` invocable 명시
- [ ] `.harness-kit/agent/native-feature-usage.md` 동기화
- [ ] Commit: `docs(spec-x-human-gate-model-lock): playbook §1.5 를 SlashCommand/Skill tool 검증 결과로 정정`

---

## Task 4: ADR-008 작성

### 4-1. invariant ADR
- [ ] `docs/decisions/ADR-008-human-gate-model-invocation.md` 작성 (type: invariant) — 사람 게이트 model-invocable 금지 + disable-model-invocation 정책 + settings 레이어 보류 근거 + 검증 출처
- [ ] Commit: `docs(spec-x-human-gate-model-lock): ADR-008 human-gate model-invocation 금지 invariant`

---

## Task 5: Ship (필수)

- [-] 코드 품질 점검 — 해당 없음 (docs/config)
- [-] 전체 테스트 — 단위 테스트 없음. 거버넌스 편집 시 Task 3 에서 동기화 회귀 확인
- [-] 통합 테스트 — Integration Test Required = no
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성**
- [ ] **코드 리뷰 게이트** — docs/config → walkthrough 에 `docs-only` 기록 (agent.md §6.3.8)
- [ ] **Ship Commit**: `docs(spec-x-human-gate-model-lock): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-human-gate-model-lock`
- [ ] **PR 생성**: `gh pr create` (base = fork main, ASCII title + --body-file)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 (Ship 포함) |
| **예상 commit 수** | 계획(1) + Task 2·3·4(3) + ship(1) = 5 |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-04 |

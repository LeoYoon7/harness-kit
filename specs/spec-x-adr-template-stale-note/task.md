# Task List: spec-x-adr-template-stale-note

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new adr-template-stale-note`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 phase.md 없음 (queue.md specx 등록은 sdd 가 자동 수행)
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성 + 계획 산출물 + Icebox 커밋

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-adr-template-stale-note`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 계획 산출물 + Icebox 등록 커밋
- [x] `backlog/queue.md` Icebox 에 1건 등록 (monorepo sibling 레포 stale-ADR false-positive)
- [x] Commit: `docs(spec-x-adr-template-stale-note): add spec/plan/task and icebox entry` (`182ff30`)

---

## Task 2: 회귀 테스트 추가 (TDD Red)

### 2-1. Step 7 작성
- [x] `tests/test-drift-stale-adr.sh` 에 Step 7 추가 — 라이브 템플릿 note 삽입 fixture ADR-994 가 stale 미보고 단언 + trap cleanup 등록
- [x] `bash tests/test-drift-stale-adr.sh` → Step 7 Fail 확인 (Step 1~6 PASS, Step 7 ✗ — `stale ADR: 1 — ADR-994-template-note-fixture.md`)
- [ ] Commit: `test(spec-x-adr-template-stale-note): add failing regression for template note self-trigger`

---

## Task 3: 템플릿 note fix (TDD Green)

### 3-1. 템플릿 수정
- [x] `sources/templates/adr.md` note 의 예시 `` `src/foo.ts` `` → 평문화 + `../` 제외 규칙 명시
- [x] `.harness-kit/agent/templates/adr.md` 동기 (pre-edit IDENTICAL 확인 후 cp)
- [x] `bash tests/test-drift-stale-adr.sh` → Step 1~7 전부 Pass 확인 (7/7, EXITCODE=0) + 정적 검사 트리거 토큰 0개
- [ ] Commit: `fix(spec-x-adr-template-stale-note): plain-text path example in adr template note`

---

## Task 4: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 전체 테스트 실행 → PASS (`test-drift-stale-adr` + 회귀: `test-install-manifest-sync`, `test-wiki-structure` 등 템플릿 영향 suite)
- [ ] 수동 검증 시나리오 1~2 수행
- [ ] **walkthrough.md 작성**
- [ ] **pr_description.md 작성** (`Fixes #55` 포함)
- [ ] 코드 리뷰 게이트 (gemini / opus / skip — walkthrough 에 기록)
- [ ] **Ship Commit**: `docs(spec-x-adr-template-stale-note): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-adr-template-stale-note`
- [ ] **PR 생성**: `/hk-pr-gh` (base: fork main, body 에 `Fixes #55`)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고
- [ ] (머지 후) `sdd specx done adr-template-stale-note` + 이슈 #55 close 확인

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 |
| **예상 commit 수** | 4 |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-12 |

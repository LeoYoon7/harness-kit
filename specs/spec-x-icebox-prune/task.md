# Task List: spec-x-icebox-prune

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.
> 본 spec 은 doc 정리 — 코드 TDD task 없음 (grep/diff 기반 검증).

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`spec-x-icebox-prune`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 (phase.md SPEC 표) — spec-x 는 phase 비소속, 해당 없음
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성 + planning 산출물 commit

- [x] `git checkout -b spec-x-icebox-prune`
- [x] 현재 브랜치가 `main` 이 아님을 확인
- [x] planning 산출물 stage: `specs/spec-x-icebox-prune/{spec,plan,task}.md` + `backlog/queue.md` (specx 등록 hunk만 — Icebox 편집 전이라 자동 분리됨)
- [x] Commit: `docs(spec-x-icebox-prune): add spec/plan/task` (38437ae)

---

## Task 2: Icebox 해소 항목 5줄 제거

- [x] `backlog/queue.md` 🧊 Icebox 에서 5줄 제거 (spec.md 요구사항 표의 5개 항목)
- [x] 검증: `grep` 으로 5개 항목 부재 확인 → 0
- [x] 검증: `git diff backlog/queue.md` 로 5줄 삭제만 / 마커 무변경 확인 (`@@ -36,16 +36,11 @@`)
- [x] 검증: `sdd status` 정상 동작 확인
- [x] Commit: `chore(spec-x-icebox-prune): remove 5 resolved icebox items`

---

## Task 3: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 회귀 확인 — 기존 키트 테스트 스위트 실행 (존재 시) → PASS
- [ ] **walkthrough.md 작성** (증거 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] 코드 리뷰 게이트 — docs-only 사유 기록 (walkthrough 코드 리뷰 필드)
- [ ] **Ship Commit**: `docs(spec-x-icebox-prune): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-icebox-prune`
- [ ] **PR 생성**: `/hk-pr-gh` 로 생성 (base = fork main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 3 (+ Ship) |
| **예상 commit 수** | 2 (제거 1 + ship 1) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-04 |

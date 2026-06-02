# Task List: spec-x-review-gate-default

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 업데이트 — spec-x 는 queue.md specx 섹션이 `sdd specx new` 로 이미 갱신됨 (phase.md 없음)
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-review-gate-default` (브랜치 이름 = spec 디렉토리 이름)
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: agent.md §6.3-8 게이트 정책 개정

> 거버넌스 규칙을 "기본 실행 + 감사형 Skip" 으로 개정 (FR 1).

### 2-1. 정책 문구 개정
- [ ] `sources/governance/agent.md` §6.3 8번 "Code Review Gate (optional)" 항목 수정
- [ ] 정적 검증: `grep -nE "auditable skip|사유 기록|default-run" sources/governance/agent.md` → 매치
- [ ] Commit: `docs(spec-x-review-gate-default): 코드 리뷰 게이트를 기본 실행+감사형 skip 으로 개정`

---

## Task 3: hk-ship.md §1.5 절차 재구성

> 커맨드 절차에 Skip 사유 기록을 명시 (FR 2).

### 3-1. §1.5 절차 수정
- [x] `sources/commands/hk-ship.md` §1.5 게이트 프레이밍 + Skip 분기에 사유 기록 절차 추가
- [x] 정적 검증: `grep -nE "사유" sources/commands/hk-ship.md` → 매치
- [x] Commit: `docs(spec-x-review-gate-default): hk-ship §1.5 에 skip 사유 기록 절차 추가`

---

## Task 4: walkthrough.md 템플릿에 코드 리뷰 칸 추가

> 감사 기록 surface 신설 (FR 3).

### 4-1. 템플릿 칸 추가
- [ ] `sources/templates/walkthrough.md` 에 "🔍 코드 리뷰" 칸 신설 (수행/Skip 두 경우 커버)
- [ ] 정적 검증: `grep -nE "코드 리뷰" sources/templates/walkthrough.md` → 매치
- [ ] Commit: `docs(spec-x-review-gate-default): walkthrough 템플릿에 코드 리뷰 기록 칸 추가`

---

## Task 5: ADR-006 작성

> 정책 결정 기록 (FR 4).

### 5-1. ADR 작성
- [ ] `.harness-kit/agent/templates/adr.md` 템플릿 읽기
- [ ] `docs/decisions/ADR-006-code-review-gate-default-run.md` 작성 (type: decision, 기각 대안 포함)
- [ ] 정적 검증: `grep -nE "^type:\s*decision" docs/decisions/ADR-006-code-review-gate-default-run.md` → 매치
- [ ] Commit: `docs(spec-x-review-gate-default): ADR-006 코드 리뷰 게이트 기본 실행 정책 기록`

---

## Task 6: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 정적 검증 4종 (plan.md 검증 계획) 모두 통과
- [ ] (docs-only — 단위/통합 테스트 N/A)
- [ ] **walkthrough.md 작성** (증거 로그, 신설된 코드 리뷰 칸 포함)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-x-review-gate-default): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-review-gate-default`
- [ ] **PR 생성**: `/hk-pr-gh --no-confirm` (base = main)
- [ ] **spec-x 완료 처리**: `sdd specx done review-gate-default`
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 (브랜치 + 4 변경 + ship) |
| **예상 commit 수** | 5 (Task 2~5 각 1 + ship 1) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-02 |

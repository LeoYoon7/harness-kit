# Task List: spec-x-cc-native-adoption

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.
> 본 spec 은 Research(분석)이므로 TDD 대신 "report 섹션 작성 → commit" 단위로 구성합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [-] 백로그 phase.md 표 갱신 — spec-x 는 phase 비소속이라 해당 없음
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 생성 + report.md 골격

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-cc-native-adoption`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. report.md 골격 작성
- [x] `specs/spec-x-cc-native-adoption/report.md` 생성 — 조사 배경 + 분석 프레임(7축) + 문서 가정 교정 4건
- [x] Commit: `docs(spec-x-cc-native-adoption): add research report skeleton and framing`

---

## Task 2: 기능별 적합도 분석 (17개 × 7축)

> report.md 본문 — 고유 기능 17개를 7개 충돌 축으로 재검증, 각 기능에 재검증 등급(✅/⚠️/🔍/⛔) + Go/No-Go 부여.

- [x] ✅군 분석: `/deep-research`, `/workflows`, `/copy`, `/rewind`, `/team-onboarding`, `/powerup`, `/radio`
- [x] ⚠️군 분석: `/goal`, `/effort ultracode`, `/fewer-permission-prompts`, `/code-review`(ultra 포함)
- [x] 🔍군 분석: `/background`, `/batch`, `/branch`, `/ultraplan`
- [x] 등급표 미수록 2종 분석: `/btw`, 스킬 시스템(`/skills`)
- [x] Commit: `docs(spec-x-cc-native-adoption): per-feature fitness analysis (17 features x 7 axes)`

---

## Task 3: 단계별 도입 로드맵 + Go/No-Go 종합

- [x] report.md 에 1단계(즉시) / 2단계(게이트 통합) / 3단계(검증 후) / 보류 로드맵 작성
- [x] 문서 2 로드맵과의 차이(교정점)를 근거와 함께 표기
- [x] Commit: `docs(spec-x-cc-native-adoption): staged adoption roadmap and go/no-go summary`

---

## Task 4: 후속 spec 후보 Icebox 등록

- [x] `backlog/queue.md` Icebox 에 도입 가치 확인 항목을 후속 spec 후보로 한 줄씩 등록
- [x] Commit: `docs(spec-x-cc-native-adoption): register follow-up adoption candidates to icebox`

---

## Task 5: Ship (필수)

> 모든 분석 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [-] 코드 품질 점검 (lint / type check) — docs-only 라 해당 없음
- [-] 전체 테스트 실행 — docs-only 라 해당 없음 (constitution §9.1 예외)
- [ ] **walkthrough.md 작성** (조사 결정·발견 기록)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-x-cc-native-adoption): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-cc-native-adoption`
- [ ] **코드 리뷰 게이트** — docs-only 변경이므로 `docs-only` 사유로 skip 가능 (agent.md §6.3.8)
- [ ] **PR 생성**: `/hk-pr-gh` 로 생성 (base = fork main)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 |
| **예상 commit 수** | 6 (report 골격 + 분석 + 로드맵 + Icebox + ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-02 |

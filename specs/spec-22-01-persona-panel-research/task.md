# Task List: spec-22-01 (Research)

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.
> 본 spec 은 Research — production 코드가 없어 TDD red/green 대신 *POC 실증*으로 검증한다 (§9.1). commit type 은 주로 `docs`.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-22.md SPEC 표 — sdd 자동 갱신)
- [x] Critique 수행 + 반영 (2026-06-08, 6항목 all → spec/plan/task)
- [ ] 사용자 Plan Accept

---

## Task 1: 브랜치 + 연구 리포트 스캐폴딩

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-22-01-persona-panel-research`
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. report.md 스캐폴딩
- [x] `specs/spec-22-01-persona-panel-research/report.md` 생성 — 섹션 골격(5난점 설계 / 측정 설계 / POC 설계 / 실행 결과(liveness+value) / Go-No-Go)
- [x] Commit: `docs(spec-22-01): scaffold research report`

---

## Task 2: 5난점 설계 분석 (각 ≥2안) + 측정 설계

- [ ] 종료조건(consensus+라운드상한≤3) / 증류(이견보존+issue retention rate) / 무한루프(의미중복탐지) / 불변식양립 / context격리 각각 ≥2안 트레이드오프 비교 → report.md 설계 섹션
- [ ] **측정 설계**: value 축(놓친 이슈/거짓 양성/retention) + 비용/지연 + baseline(단일 Opus N회 투표) 정의
- [ ] **연구 파라미터**: 페르소나 수·구성 + archived spec 표본 선정 기준 확정
- [ ] ADR-008/010/011 정합 점검 명시
- [ ] Commit: `docs(spec-22-01): analyze 5 difficulties + define value/cost measurement`

---

## Task 3: POC 프로토타입 정의

- [ ] `scripts/research/persona-panel-poc.md` 작성 — 페르소나 정의, dispatch(fan-out·결과 계약만), 종료조건, 증류 단계, **baseline(단일 Opus N회 투표) 프로토콜**
- [ ] Commit: `docs(spec-22-01): define persona-panel POC prototype`

---

## Task 4: POC 실행 + baseline 비교 + value/수렴 증빙

- [ ] archived spec 1건(이견 갈리는 표본)에 POC 패널 실행 (페르소나 sub-agent 팬아웃)
- [ ] **동일 spec 에 baseline(단일 Opus N회 투표) 실행** — 앙상블 vs 페르소나 기여 분리
- [ ] `scripts/research/persona-panel-poc-run.md` 에 실행 로그(페르소나별 결과 계약 / 라운드 수 / 증류 산출물 / 격리 + baseline 결과 + value 비교표) 기록
- [ ] report.md "실행 결과" 섹션 — liveness(수렴/격리) + **value(놓친 이슈·거짓 양성·issue retention rate·비용/지연) 패널 vs baseline 비교**
- [ ] Commit: `docs(spec-22-01): run POC + baseline and capture value/convergence evidence`

---

## Task 5: Go/No-Go 권고

- [ ] report.md "Go/No-Go" 섹션 — 명시적 결론 + 근거(난점 해소도 + **value > baseline 입증 여부**). Go 면 spec-22-02 범위 제안, No-Go 면 근거 + Icebox 처리안
- [ ] Commit: `docs(spec-22-01): document go/no-go recommendation`

---

## Task 6: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 리뷰 게이트 — research/docs-only 이므로 Skip 가능 (walkthrough 코드리뷰 칸에 `docs-only` 기록)
- [ ] 전체 키트 테스트 회귀 확인 (영향권만) → PASS
- [ ] **walkthrough.md 작성** (연구 결정·발견·증빙 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-22-01): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-22-01-persona-panel-research`
- [ ] **PR 생성**: `gh pr create` (base = `main`, repo = fork) — 사용자 승인 후
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 (작업 5 + Ship 1) |
| **예상 commit 수** | 6 |
| **현재 단계** | Planning (Critique 반영 완료) |
| **마지막 업데이트** | 2026-06-08 |

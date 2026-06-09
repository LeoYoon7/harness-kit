# Task List: spec-x-persona-hybrid-research (Research)

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 본 spec 은 Research — production 코드가 없어 TDD red/green 대신 *POC 실증*으로 검증한다 (§9.1). commit type 은 주로 `docs`.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new persona-hybrid-research`)
- [x] spec.md 작성
- [x] report.md 스캐폴딩 (§9.2 핵심 산출물)
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 — spec-x 라 phase.md 불요. queue.md specx 마커 등록(specx new). Icebox 하이브리드 라인은 Task 1 에서 promote 표기.
- [x] Critique 수행(2026-06-09 Opus) + 대안 B 전면 반영
- [x] 사용자 Plan Accept

---

## Task 1: 브랜치 + 계획 산출물 커밋

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-persona-hybrid-research` (main 기준 사전 분기)
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 계획 산출물 + Icebox promote 표기 커밋
- [x] `git add specs/spec-x-persona-hybrid-research/{spec,report,plan,task,critique}.md backlog/queue.md`
- [x] queue.md Icebox 의 "persona-panel 하이브리드 재설계 research" 라인을 본 spec-x 로 promote 표기.
- [x] Commit: `docs(spec-x-persona-hybrid-research): add spec/report/plan/task (대안 B)`

---

## Task 2: 하이브리드 설계(H1 확정) + 측정 설계 + 사전등록

- [x] H1/H2/H3 트레이드오프 표 → report.md §2. **POC 대상 = H1 단일** 확정 + H1 상세(페르소나3+generalist1, 결과계약, 증류) §2.1.1.
- [x] 측정 설계 — phase-22 §3 재사용 + **평가 독립성(Gemini blind 채점)** + baseline 2변형(B0/B1) → report.md §3.2~3.3.
- [x] **사전 등록** — 깊이회복≥2/3·폭retention≥0.8·ROI≥1.0·페르소나순기여>0 + Go/No-Go 판정 규칙 박제 → report.md §3.4.
- [x] ADR-008/010/011 정합 점검 명시 → report.md §2.2.
- [x] Commit: `docs(spec-x-persona-hybrid-research): fix H1 design + define measurement + pre-register thresholds`

---

## Task 3: POC 프로토콜 정의 (2자 + 채점 분리)

- [x] `scripts/research/persona-hybrid-poc.md` — H1 dispatch(페르소나3+generalist1, 결과 계약만), 종료/증류, **baseline B0/B1**, **Gemini blind 채점(라벨 제거)** 절차, 2자 비교. phase-22 POC 확장.
- [x] 표본 2건 확정 — S1 `spec-x-notify-channel-formatter`(폭) + S2 `spec-x-notify-chunk-line-aware`(깊이/청킹 경계) + 근거(균형 표집).
- [x] Commit: `docs(spec-x-persona-hybrid-research): define hybrid POC protocol with blind cross-model scoring`

---

## Task 4: POC 실행 (표본 ≥2) + 2자 비교 + blind 채점

> 증분 실행(사용자 결정 2026-06-09): S1 먼저 → 보고 → S2 결정.

### 4-S1 (완료)
- [x] S1 H1 4워커 + B0 3워커 팬아웃(격리/종료/증류 확인) + B1=B0∪G.
- [x] **Gemini blind 채점**(라벨 익명화 A/B/C) → A(H1) 4/4 GT, C(B1) 3/4(GT1 놓침), B(B0) 2/4.
- [x] `persona-hybrid-poc-run.md` S1 + report.md §5 S1 — 4기준 모두 H1 PASS.
- [x] Commit: `docs(spec-x-persona-hybrid-research): run S1 hybrid POC with blind cross-model scoring`

### 4-S2 (완료)
- [x] S2(`spec-x-notify-chunk-line-aware`, 깊이 표본) H1 4워커 + B0 3 + B1=B0∪G, Gemini blind 채점.
- [x] 결과: A(H1) 5/5 GT·valid 10, **C(B1) 5/5 GT·valid 12 → cheaperEqual=YES, H1 FAIL** (ROI 0.83, 페르소나 순기여≈0). poc-run.md S2 + report §5 S2 + 교차 종합.
- [x] Commit: `docs(spec-x-persona-hybrid-research): run S2 hybrid POC + cross-sample synthesis`

---

## Task 5: Go/No-Go 권고

- [x] report.md §0 요약 + §6 Go/No-Go — **Conditional No-Go(블랭킷 패널)** + B1 정독 win 채택 권고. 사전등록 1/2 + 메커니즘(폭 lever vs 깊이 lever).
- [x] (방향 확정 시) `review-value-baseline` + `review-eval-independence` ADR 후보 §6 에 기록(결론 확정 시 작성).
- [x] Commit: `docs(spec-x-persona-hybrid-research): document go/no-go recommendation`

---

## Task 6: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [x] 리뷰 게이트 — **Skip (`docs-only`)**: research 산출물(report/scripts/md, production 코드 0) + 내부적으로 Gemini cross-model blind 채점 수행(독립 검증 내재). walkthrough 코드리뷰 칸 기록.
- [x] 회귀 확인 — production 코드 미변경(docs/research only) → 회귀 대상 없음
- [x] **walkthrough.md 작성** (연구 결정·발견·증빙 로그)
- [x] **pr_description.md 작성** (템플릿 준수)
- [x] **Ship Commit**: `docs(spec-x-persona-hybrid-research): ship walkthrough and pr description`
- [x] **Push**: `git push -u origin spec-x-persona-hybrid-research`
- [x] **PR 생성**: `gh pr create --base main` (spec-x → main, fork)
- [x] **사용자 알림**: 푸시 완료 + PR URL 보고
- [-] **specx done** (post-merge): `sdd specx done persona-hybrid-research` — 머지 후 단계, 의도적 연기

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 (작업 5 + Ship) |
| **실제 commit 수** | 7 (계획 / 설계·측정 / POC프로토콜 / S1실행 / S2+종합+Go-No-Go / ship) |
| **현재 단계** | Ship |
| **마지막 업데이트** | 2026-06-09 |

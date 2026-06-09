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

- [ ] H1/H2/H3 트레이드오프 표 → report.md §2. **POC 대상 = H1 단일** 확정(H2/H3 문서만) + 근거.
- [ ] 측정 설계 — phase-22 §3 재사용 + **평가 독립성(Gemini blind 채점)** + baseline 2변형(B0/B1) → report.md §3.2~3.3.
- [ ] **사전 등록** — 깊이회복/폭유지/ROI 정량 임계 + Go/No-Go 판정 규칙을 report.md §3.4 에 박제(POC 전).
- [ ] ADR-008/010/011 정합 점검 명시 → report.md §2.2.
- [ ] Commit: `docs(spec-x-persona-hybrid-research): fix H1 design + define measurement + pre-register thresholds`

---

## Task 3: POC 프로토콜 정의 (2자 + 채점 분리)

- [ ] `scripts/research/persona-hybrid-poc.md` — H1 dispatch(페르소나3+generalist1, 결과 계약만), 종료/증류, **baseline B0/B1**, **Gemini blind 채점(라벨 제거)** 절차, 2자 비교. phase-22 POC 확장.
- [ ] 표본 2건 확정 — ① `spec-x-notify-channel-formatter`(폭 표본) + ② **깊이-중심 대조 표본 1건**(구체/플랫폼 버그 핵심) + 선정 근거(균형 표집).
- [ ] Commit: `docs(spec-x-persona-hybrid-research): define hybrid POC protocol with blind cross-model scoring`

---

## Task 4: POC 실행 (표본 ≥2) + 2자 비교 + blind 채점

- [ ] 표본 1·2 에 H1 실행(sub-agent 팬아웃, 격리/종료/증류 기록).
- [ ] 동일 표본에 baseline B0(Opus×3) + B1(Opus×3+정독1패스) 실행. pure-panel 은 phase-22 데이터 서술 참조.
- [ ] **Gemini blind 채점**(산출물 라벨 제거) → value/깊이회복/폭유지 판정.
- [ ] `scripts/research/persona-hybrid-poc-run.md` 실행 로그 + report.md §5 — liveness + 2자 비교표 + 표본별 PASS/FAIL(사전등록 임계 대비).
- [ ] Commit: `docs(spec-x-persona-hybrid-research): run H1 vs baseline POC across >=2 samples with blind scoring`

---

## Task 5: Go/No-Go 권고

- [ ] report.md §0 요약 + §6 Go/No-Go — **사전등록(§3.4) 규칙 기반** 결론 + 근거 + n=2 방향일치(일반화 금지) 한계.
- [ ] (방향 확정 시) `review-value-baseline` + `review-eval-independence` ADR 작성 판단.
- [ ] Commit: `docs(spec-x-persona-hybrid-research): document go/no-go recommendation`

---

## Task 6: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 리뷰 게이트 — 판단(연구 docs-only 면 Skip + 사유 기록 가능; gemini 는 본 연구 무관이라 사용 가능)
- [ ] 회귀 확인 — production 코드 미변경(docs/research only) → 회귀 대상 없음
- [ ] **walkthrough.md 작성** (연구 결정·발견·증빙 로그)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-x-persona-hybrid-research): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-persona-hybrid-research`
- [ ] **PR 생성**: `gh pr create --base main` (spec-x → main, fork)
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고
- [ ] **specx done** (post-merge): `sdd specx done persona-hybrid-research`

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 6 (작업 5 + Ship) |
| **예상 commit 수** | 6 (계획 / 설계·측정 / POC프로토콜 / POC실행 / Go-No-Go / ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-09 |

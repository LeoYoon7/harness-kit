# Walkthrough: spec-22-01 페르소나 리뷰 패널 연구

> 작업 기록 — 결정·협의·검증. Research Spec (§9), 산출물 = `report.md` + POC.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 작업 모드 | spec-x / 새 phase | 새 phase-22 (SDD-P) | feature 라 spec-x 자격 미달(§3.3), phase-21 닫혀 spec-21-06 불가 |
| 접근 | 구현 직행 / research-first | research-first | defer 사유(5난점) 미해결 — 수렴·value 검증 후 결정 |
| Critique 반영 | 일부 / all | **all (6항목)** | liveness 만 측정하던 성공기준에 value(baseline 대비) 축 추가 — Go 판정 공허화 방지 |
| POC 표본 | channel-formatter / ignore-coverage | channel-formatter | 설계·거버넌스·모바일 UX 가 고루 갈려 페르소나 다양성 검증 적합 |
| 최종 권고 | Go / No-Go / Conditional | **Conditional No-Go** | n=1 POC 에서 패널이 self-consistency baseline 을 지배 못함(상보적, 비용 동급). 단순 패널 ROI 불명확 |
| spec-22-02 | 구현 / drop | **drop** (하이브리드는 Icebox) | value 미입증 → 단순 패널 구현 보류. 하이브리드(패널+generalist) 는 별도 research |

### ADR 승격 가이드
- [ ] ADR 승격 대상 있음
- [x] 없음 (후보 `persona-panel-orchestration` 은 Go 전제라 미작성; `review-value-baseline` invariant 후보는 n=1 근거라 Icebox 트리거 대기)

## 💬 사용자 협의

- **주제**: spec-21-06 재개 방식
  - **사용자 의견**: persona-review-panel 진행
  - **합의**: phase-21 닫혀 새 phase-22, research-first 모드
- **주제**: critique 반영 범위
  - **사용자 의견**: all
  - **합의**: 6항목 모두 spec/plan/task 반영 (liveness+value 측정)
- **주제**: 연구 결론(Conditional No-Go) 처리
  - **사용자 의견**: 1번 (No-Go 수용)
  - **합의**: research Ship + phase-22 Done, spec-22-02 drop, 하이브리드 Icebox

## 🧪 검증 결과

### 1. 자동화 테스트
- **단위 테스트**: 해당 없음 — Research/docs-only (production 코드 미변경). 검증은 POC 실증으로 대체 (§9.1).

### 2. 수동 검증 (POC 실증, n=1)
1. **Action**: 페르소나 패널 3(설계자/규제자/사용자옹호자) + baseline(Opus×3) 병렬 팬아웃, 대상 `archive/specs/spec-x-notify-channel-formatter/spec.md`
   - **Result**: 6 워커 전원 JSON 결과 계약만 반환 → **context 격리 실증** (transcript 미유입, ADR-010 정합). 라운드 1 수렴, 무한 루프 없음.
2. **Action**: 패널 vs baseline value 비교
   - **Result**: 패널=framing 폭(모바일→embed 핵심 이슈 포착) 우위 / baseline=구체 버그(awk locale, 3/3) 우위. **패널이 baseline 지배 못함, 비용 동급** → Conditional No-Go.

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **Skip 사유** | `docs-only` (research 산출물 + scripts/research POC 정의, production 코드 미변경) |

## 🔍 발견 사항

- **패널 ↔ self-consistency 는 상보적** — 페르소나 렌즈는 framing 폭을 주지만 깊은 구현 디테일(locale 등)을 희생. 동일 프롬프트 N회 정독이 구체 버그에 더 강함.
- **하이브리드 방향** (패널 + generalist 정독 1패스)가 유망 — 다음 research 후보.
- **재사용 측정틀** 확보: value(놓친 이슈/거짓 양성/고유 관점) + issue retention rate + 비용/지연 + self-consistency baseline — 향후 review 기법 비교에 재사용 가능.
- **n=1 한계**: 단일 표본·도메인. 일반화 금지.

## 🚧 이월 항목

- 하이브리드(패널+generalist) 재설계 research → `backlog/queue.md` Icebox
- `review-value-baseline` invariant ADR 후보 (다관점 리뷰 도입은 baseline 대비 value 측정을 Go 전제로) → Icebox 트리거 대기

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-08 |
| **최종 commit** | (ship commit 후 갱신) |

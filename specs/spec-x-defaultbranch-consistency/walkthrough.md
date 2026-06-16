# Walkthrough: spec-x-defaultbranch-consistency

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 작업 모드 | bundled spec-x / phase | bundled spec-x | 단일 테마(defaultBranch 정합), 새 인프라 아닌 기존 전파. phase 는 over-ceremony |
| origin/HEAD 자동추론 | 채택 / 비채택 | 비채택 (ADR-015) | symbolic-ref 부재 함정 + claude-code #31614. 명시 설정 우선이 안정적 |
| 헬퍼 ref-실재 확인 | 값-체인만 / 2단 ref-fallback | 2단 ref-fallback | critique #1 — base-branch 모드 첫 spec(JIT 미생성)에서 머지 감지 무음 실패 방지 |
| **hk-ship 적용 방식 (plan 정정)** | plan 의 "line 139 병합" / 별도 default_branch 추출 | **별도 추출** | plan/critique 의 line-139 병합을 그대로 따르면 `if [ base != null ]` 의 *phase-base-mode 감지*가 깨짐(defaultBranch 를 phase 브랜치로 오인). line 139 는 baseBranch 전용 유지, default_branch 별도 추출 후 144/150 적용 |
| lib 단일화 (3벌 중복) | 지금 통합 / 부채 가시화 후 보류 | 보류 (ADR-015 (d)) | gemini-review 독립성 파괴 + 도그푸딩 전 추상화(YAGNI). 다음 트리거 시 재평가 |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-015-review-base-resolution-chain.md` (type: tradeoff)
- [ ] 없음

## 💬 사용자 협의

- **주제**: 작업 모드 → bundled spec-x 승인 (PC 응답 1).
- **주제**: Plan Accept 전 critique → 사용자가 2(Critique) 선택 → Opus 비평 수행 → 7개 항목 all 반영 → Plan Accept(1).
- **주제**: critique 반영 범위 → all (PC 응답).

## 🧪 검증 결과

### 1. 자동화 테스트

- **신규 `tests/test-sdd-base-resolution.sh`**: ✅ 6/6 — baseBranch 우선 / defaultBranch 선택 / 둘 다 없음→main / installed.json 부재→main / **JIT 미존재→defaultBranch(회귀 방지)** / defaultBranch 미존재→main 종착. (sdd source + 소스 가드로 `_resolve_base_branch` 직접 단위 테스트)
- **`tests/test-sdd-base-branch.sh`**: ✅ 4/4 (회귀 없음)
- **`tests/test-governance-dedup.sh`**: ✅ 8/8 (sync + 예산 6400w≤6500)
- **`bash -n` (sources + 설치본 sdd)**: ✅ OK

### 2. 사전 존재 실패 (이 spec 무관 — stash 비교로 확정)

`test-sdd-status-cross-check.sh`(5/2)·`test-sdd-phase-done-accuracy.sh`(3/1)는 내 sdd 변경을 `git stash` 한 상태에서도 **동일하게 실패** → 사전 존재. 원인: fixture 가 `master` 브랜치 + defaultBranch 미설정이라 신·구 코드 모두 `main` 으로 귀결(동작 중립), phase-done Check 4 는 메시지에 "(미구현)" 명시된 placeholder.

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-x-defaultbranch-consistency/code-review-gemini.md` |
| **요약** | **Approve** — Critical 0 / Major 0 / Minor 0. ref-fallback 회귀 방어 + hk-ship 정정 + ADR-015 부채 가시화 모두 검증. 발견 없음 |
| **Skip 사유** | — |

## 🔍 발견 사항

- critique 가 코드 대조로 **plan 의 line-139 지시가 hk-ship 구조에서 버그를 유발**함을 간접 노출 — Strict Loop 중 정정(별도 추출)으로 흡수. plan 은 draft 라는 ADR-002 원칙의 실증.
- base 해석 동일 패턴이 sdd 헬퍼·gemini-review.sh·sdd state_dump 에 3벌 — ADR-015 에 부채로 박음 (다음 트리거 시 lib 통합 재평가).

## 🚧 이월 항목

- lib/base.sh 단일화 (3벌 통합) → ADR-015 (d), 다음 트리거 시.
- 사전 존재 fixture-on-master 테스트 실패 2건 → Windows best-effort 계열 (별도).

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (+ Opus critique) + Leo |
| **작성 기간** | 2026-06-16 |
| **최종 commit** | (ship commit 시 갱신) |

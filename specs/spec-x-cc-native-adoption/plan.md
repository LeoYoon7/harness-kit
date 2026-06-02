# Implementation Plan: spec-x-cc-native-adoption

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-cc-native-adoption` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> 본 Plan 을 Accept 하기 전에 사용자가 명시적으로 확인해야 할 항목들.

> [!IMPORTANT]
> - [ ] **분석 단위 = 고유 기능 17개** (alias 통합) — 사용자 승인 완료(범위 선택 1번)
> - [ ] **산출물 = 분석 문서(report.md)** — 본 spec 은 기능을 실제 도입·구현하지 않는다. 거버넌스/코드 무수정
> - [ ] **유일한 repo 상태 변경 = `report.md` 신규 + `queue.md` Icebox 등록** — 그 외 파일 변경 없음

> [!WARNING]
> - [ ] 도입 *판단*만 산출하며, 실제 도입은 본 조사 결과를 근거로 한 *후속 spec* 에서 진행됨
> - [ ] 검증 체크리스트 7종(실측)은 본 spec 범위 밖 — "검증 필요" 분류만

## 🎯 핵심 전략 (Core Strategy)

### 분석 프레임 — 8개 충돌 축 × 17개 기능 매트릭스

문서 2의 4등급을 그대로 계승하지 않고, 아래 8개 축으로 각 기능을 실제 harness-kit 상태에 비추어 재평가한다. 이 매트릭스가 report.md 의 뼈대다. (축 H 는 사용자 피드백으로 추가)

| 축 | 내용 | 근거 문서 |
|---|---|---|
| A | Plan Accept / §8.5 게이트 보존 | constitution §5.2·5.3, agent.md §8.5 |
| B | 2계층 알림 정합성 | CLAUDE.fragment §1~§10 |
| C | 멀티모델 전략 override | agent.md §6.6 |
| D | PR 플랫폼 (GitHub 도그푸딩 / Bitbucket target) | `/hk-pr-gh`, `/hk-pr-bb` |
| E | 세션 라이프사이클 · 공유 config 병렬 제약 | 멀티세션 제약 (메모리) |
| F | git hook 게이트 정합성 | sources/hooks/* |
| G | 기존 자산 중복 | `/hk-gemini-review`, AUQ 금지 |
| H | 사용 제한 (플랜/사용량/크레딧/백엔드) — *피드백 추가* | 입력 문서 + CC 플랜 정책 |

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **분석 프레임** | 7충돌축 × 17기능 매트릭스 | 문서 2의 4등급보다 누락 없는 체계적 평가. "왜 그 등급인가"를 축으로 추적 가능 |
| **산출물 분리** | `spec.md`(조사 정의) + `report.md`(조사 결과) 분리 | Research §9.2 정신 + hook 안전(spec.md 유지로 게이트 호환) |
| **등급 체계** | 문서 2의 4등급(✅/⚠️/🔍/⛔) 계승 + 실제 상태 교정 | 기존 분석 재활용, 사용자 친숙도. 교정 4건은 근거와 함께 표기 |
| **두 시점 명시** | 키트 원본 vs 도그푸딩 적용 결과를 충돌마다 구분 | PR 플랫폼 등은 시점에 따라 충돌 양상이 다름(CLAUDE.md 두 시점 원칙) |

### 📑 ADR 후보

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: `native-feature-adoption-policy` (type: convention) — **도입 spec 트리거 시 작성** (본 조사 단계 아님)
- [ ] 없음

## 📂 Proposed Changes

### 분석 산출물

#### [NEW] `specs/spec-x-cc-native-adoption/report.md`
- Research Report 본체. 구성:
  1. 조사 배경 · 분석 프레임(7축)
  2. 문서 가정 교정 4건 (근거)
  3. 기능별 적합도 분석 — 17개 고유 기능 × 7축, 각 기능 재검증 등급 + Go/No-Go
  4. 단계별 도입 로드맵 (1/2/3단계 + 보류)
  5. 후속 spec 후보 목록 (Icebox 등록 대상)

#### [MODIFY] `backlog/queue.md`
- Icebox 섹션에 도입 가치 확인된 후속 spec 후보를 한 줄씩 등록 (실행 불가 메모)

#### [MODIFY] `specs/spec-x-cc-native-adoption/walkthrough.md` · `pr_description.md`
- ship 단계 산출물

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
# 해당 없음 — 본 spec 은 분석 문서(docs-only)로, 실행 코드 변경이 없다.
# constitution §9.1 "documentation-only changes" 예외 적용.
```

### 수동 검증 시나리오
1. report.md 가 문서 가정 교정 4건을 모두 반영하는가 — 기대: 알림/PR플랫폼/cross-model/AUQ 4건 명시
2. 17개 고유 기능이 전수 분석되었는가 — 기대: 누락 0, 각 기능에 재검증 등급 + Go/No-Go 존재
3. 단계별 로드맵이 실제 harness-kit 제약을 반영하는가 — 기대: 문서 2 로드맵과의 차이를 근거와 함께 표기
4. queue.md Icebox 에 후속 spec 후보가 등록되었는가 — 기대: 도입 가치 항목이 한 줄 메모로 존재

## 🔁 Rollback Plan

- 본 spec 은 분석 문서 + Icebox 메모만 생성하므로 시스템 영향이 없다. 문제 시 브랜치 폐기로 완전 롤백 (`git branch -D spec-x-cc-native-adoption`).
- queue.md Icebox 등록은 되돌리려면 해당 줄 제거만으로 충분.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship

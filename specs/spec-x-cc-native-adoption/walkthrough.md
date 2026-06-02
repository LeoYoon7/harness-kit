# Walkthrough: spec-x-cc-native-adoption

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 산출물 형태 | 1.채팅 분석 / 2.Research spec-x / 3.즉시 통합 | **2** | "방안 수립"의 가치는 영속성. 원본 문서가 repo 밖(D:\tmp)이라 교정 결과를 repo 안에 남겨야 후속 spec 근거가 됨. 3(즉시 구현)은 시기상조 |
| 분석 범위 | 1.고유 기능 17개 전수 / 2.문서2 대상 15개 | **1** | 빠짐없는 전수가 목적에 부합. 빠진 2개(`/btw`·스킬)도 harness-kit 자산과 맞닿아 등급 판단 필요 |
| 산출물 구조 | spec+report 분리 / report 단일 | **분리** | Research §9.2 정신 + hook 안전(spec.md 유지로 게이트 호환) |
| 분석 프레임 | 문서2 4등급 계승 / 7충돌축 매트릭스 | **7축 매트릭스** | "왜 그 등급인가"를 축으로 추적 가능. 문서2 4등급보다 누락 없음 |
| §2 Plan 게이트 원격 알림 | notify.sh 발송 / 보류 | **보류** | Git Bash 비-ASCII argv 손상 위험([[gitbash-nonascii-argv-codepage]]). PC 세션 실시간 응답 가능 상태라 판단 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — `native-feature-adoption-policy`(convention) 후보는 *실제 도입 spec 시점*에 작성하는 것이 적절. 본 조사 단계에서 박지 않음 (spec.md ADR 후보란에 명시)

## 💬 사용자 협의

- **주제**: 산출물 형태
  - **사용자 의견**: 2번 (Research spec-x) 선택
  - **합의**: report.md 영속화 + Icebox 후속 등록, 거버넌스/코드 무수정
- **주제**: 기능 카운트 (사용자 질문 "23종인데 추려서 14종인가?")
  - **사용자 의견**: 문서의 23종과 에이전트가 말한 14종의 불일치 지적
  - **합의**: 에이전트의 "14종"은 부정확한 표현으로 정정. 23 = alias 포함 개별 슬래시 토큰, 고유 기능 17개. 분석 단위는 고유 기능 17개 전수로 확정

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: 해당 없음 — 본 spec 은 분석 문서(docs-only)로 실행 코드 변경이 없음 (constitution §9.1 예외)
- **결과**: N/A (면제)

### 2. 수동 검증

> plan.md §검증 계획의 수동 시나리오 4종.

1. **Action**: report.md 가 문서 가정 교정 4건(알림/PR플랫폼/cross-model/AUQ)을 반영하는지 확인
   - **Result**: ✅ §3.1~3.4 에 4건 모두 근거와 함께 명시
2. **Action**: 17개 고유 기능 전수 분석 여부 확인
   - **Result**: ✅ §4.0 요약 매트릭스 17행(+ `/code-review` 기본형 11b 분리) + §4.1~4.4 산문, 각 기능에 재검증 등급 + Go/No-Go 존재
3. **Action**: 단계별 로드맵이 실제 제약 반영 + 문서2 차이 표기 여부
   - **Result**: ✅ §5 1/2/3단계 + 보류 + "문서2 차이(교정 요약)" 표 6행
4. **Action**: queue.md Icebox 후속 후보 등록 확인
   - **Result**: ✅ 4항목 등록 (정책 spec / 검증 spec / `/batch` 정합성 / 1단계 즉시 채택)

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **결과 파일** | N/A |
| **요약** | N/A |
| **Skip 사유** | `docs-only` — 분석 문서(.md) + queue Icebox 메모만, 실행 코드 변경 없음 (agent.md §6.3.8) |

## 🔍 발견 사항

- **두 시점 충돌의 비대칭** — `gh` 전제 기능(`/batch` 자동 PR, `/code-review --comment`)은 도그푸딩(GitHub)에선 정합하나 키트 배포 대상(target Bitbucket)에선 불일치. 키트가 메타 도구라 "어느 시점이냐"가 도입 판단을 가른다. 문서2가 단정한 "Bitbucket 불일치"는 시점 분기로 교정됨.
- **외부 문서의 메모리 드리프트** — 두 입력 문서가 메모리 가정으로 작성돼 실제 구현과 4건 어긋남. 특히 cross-model 리뷰(`/hk-gemini-review`)·AUQ 금지 정책은 이미 반영된 사항이라, 외부 분석을 그대로 수용하지 않고 실제 소스 대조가 필수였음.
- **`/code-review` 기본형 중복** — native `/code-review`(기본)는 `/hk-code-review`(Opus)와 역할 동일 → 도입 불요. ultra(클라우드)만 보강 가치.

## 🚧 이월 항목

- 2단계 정책 spec (`native-feature-adoption-policy`) → `backlog/queue.md` Icebox 등록됨
- 3단계 검증 spec (`/background`·`/branch` 실측) → Icebox 등록됨
- `/batch` Bitbucket 정합성 → Icebox 등록됨
- 1단계 9종 즉시 채택 (관행화) → Icebox 등록됨

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-02 ~ 2026-06-02 |
| **최종 commit** | ship commit (push 직전) |

# spec-x-cc-native-adoption: Claude Code 네이티브 기능의 harness-kit 도입 적합도 조사

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-cc-native-adoption` |
| **Phase** | 없음 (spec-x, Solo) |
| **Branch** | `spec-x-cc-native-adoption` |
| **상태** | Planning |
| **타입** | Research |
| **Integration Test Required** | no |
| **작성일** | 2026-06-02 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

harness-kit 은 Claude Code 전용 SDD 거버넌스 부트스트랩 툴킷이다. 현재 다음 자산을 운영한다.

- `/hk-*` 슬래시 커맨드 16종 (align, plan-accept, ship, pr-gh, pr-bb, code-review, gemini-review, phase-ship 등)
- 2계층 알림 프로토콜 — `notify.sh` dispatcher + `notify-telegram.sh` / `notify-discord.sh` 멀티채널, `notify-on-input-wait.sh` hook, 양방향 채널 응답 인식(CLAUDE.fragment §10)
- git hook 게이트 13종 (check-branch, check-plan-accept, check-test-passed, check-commit-msg, check-scope 등)
- 멀티모델 전략 (agent.md §6.6 — main=Opus, 구현=Sonnet, 리뷰=Opus)
- Choice Presentation Protocol (agent.md §8.5) + AUQ 절대 금지 정책

한편 Claude Code 네이티브에는 슬래시 명령 23개(alias 포함, 고유 기능 17개)가 존재하나, 이들을 harness-kit 거버넌스에 도입할지에 대한 방침이 정의되어 있지 않다.

### 문제점

외부 검토 문서 2종(`D:\tmp\claude-code-기능-활용-가이드.md`, `claude-code-harness-kit-compatibility.md`)이 도입 적합도를 4등급으로 분석했으나, **메모리 기반 가정으로 작성되어 실제 구현과 최소 4건 어긋난다**.

1. **알림 구조** — 문서는 `notify-telegram.sh` 단일 가정. 실제는 `notify.sh` dispatcher + Discord/Telegram 멀티채널 + 양방향(§10) + 채널별 포맷터.
2. **PR 플랫폼** — 문서는 Bitbucket 전제. 실제는 `/hk-pr-gh`(GitHub) + `/hk-pr-bb`(Bitbucket) 둘 다 존재하며, 본 repo 도그푸딩은 GitHub fork 사용. Bitbucket 은 *target(nextmarket-api)* 스택.
3. **cross-model 리뷰** — 문서는 "/code-review ultra 가 Codex 와 역할 중복" 우려. 실제는 이미 `/hk-gemini-review`(cross-model)가 ship 게이트 권장 리뷰로 통합됨(agent.md §6.3).
4. **AUQ 정책** — 문서는 §8.4 "AskUserQuestion 선호" 가정. 실제는 AUQ 절대 금지로 정책 전환됨(양방향 정책 + 메모리).

이 어긋남을 교정하지 않고 문서 2의 로드맵을 그대로 따르면 부정확한 도입 판단을 내린다. 또한 자율 기능(`/goal`, `/effort ultracode`)과 세션 분리 기능(`/background`, `/batch`, `/branch`)이 harness-kit 의 게이트·알림·멀티모델·공유 글로벌 config 제약과 충돌할 여지가 크다.

### 해결 방안 (요약)

17개 고유 네이티브 기능을 **실제 harness-kit 상태 기준**으로 7개 충돌 축에 대해 재검증하여, 4등급 적합도 + 단계별 도입 로드맵 + 기능별 Go/No-Go 권장을 `report.md` 에 산출한다. 도입 가치가 확인된 항목은 후속 spec 후보로 `backlog/queue.md` Icebox 에 등록한다. 본 spec 은 **조사(Research)** 이며 기능을 실제로 도입·구현하지 않는다.

## 🎯 요구사항

### Functional Requirements

1. **7개 충돌 축 분석 프레임** — 17개 고유 기능 각각을 다음 축으로 평가한다.
   - (A) Plan Accept / §8.5 Choice Presentation 게이트 보존 여부
   - (B) 2계층 알림 프로토콜(`notify.sh`, `notify-on-input-wait.sh`, 양방향 §10) 정합성
   - (C) 멀티모델 전략(§6.6 phase별 모델 지정) override 여부
   - (D) PR 플랫폼 정합성 (GitHub 도그푸딩 / Bitbucket target 두 시점)
   - (E) 세션 라이프사이클 · 공유 글로벌 config 병렬 제약
   - (F) git hook 게이트(check-branch / check-plan-accept 등) 정합성
   - (G) 기존 harness-kit 자산과의 중복 (`/hk-gemini-review`, AUQ 금지 등)
2. **4등급 재검증** — 문서 2의 ✅(바로 도입) / ⚠️(게이트 안쪽) / 🔍(검증 필요) / ⛔(현 상태 지양) 등급을 실제 상태로 재검증하고, 교정 시 근거를 명시한다.
3. **단계별 도입 로드맵** — 1단계(즉시) / 2단계(게이트 통합 후) / 3단계(검증 테스트 후) / 보류로 분류한다.
4. **기능별 Go/No-Go 권장** — Research DoD(agent.md §9.1)에 따라 각 기능에 명확한 도입 판단을 제시한다.
5. **Icebox 후속 등록** — 도입 가치가 확인된 항목을 `backlog/queue.md` Icebox 에 후속 spec 후보로 한 줄씩 등록한다.

### Non-Functional Requirements

1. 거버넌스 문서(`agent.md` / `CLAUDE.md`) 및 코드는 변경하지 않는다 — 순수 분석. 유일한 repo 상태 변경은 `report.md` 신규 + `queue.md` Icebox 등록.
2. 모든 산출물은 한국어로 작성한다.
3. harness-kit 의 두 시점(키트 원본 vs 도그푸딩 적용 결과)을 구분하여, "어느 시점의 충돌인가"를 명시한다.

## 🚫 Out of Scope

- 네이티브 기능의 실제 도입 · 구현 (확정 후 별도 후속 spec 으로 진행)
- 거버넌스 문서(`agent.md` / `CLAUDE.md` / constitution) 본문 수정
- 문서 2의 검증 체크리스트 7개(예: `/background` 실행 중 알림 도달 실측)의 실제 실행 — report 는 "검증 필요"로 분류만 하고, 실측은 3단계 후속 spec 의 몫
- 네이티브 명령 내부 동작의 역공학 · 소스 분석

## 📑 ADR 후보 (Architecture Decision Records)

> 본 spec 은 조사이므로 정책 ADR(`native-feature-adoption-policy`, type: convention)은 *실제 도입 spec 시점*에 작성하는 것이 적절하다. 조사 결과만으로 ADR 을 박지 않는다.

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: `native-feature-adoption-policy` (type: convention) — **단, 도입 spec 트리거 시 작성** (본 조사 단계 아님)
- [ ] 없음

## ✅ Definition of Done

- [ ] `report.md` 작성 — 17개 기능 × 7축 분석 + 4등급 재검증 + 단계별 로드맵
- [ ] Trade-off 분석 — 등급별 근거 명시 (Research §9.1)
- [ ] 기능별 Go/No-Go/조건부 권장 문서화 (Research §9.1)
- [ ] `backlog/queue.md` Icebox 후속 spec 후보 등록
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-cc-native-adoption` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료
- [-] 단위 테스트 — **docs-only(분석 문서)이므로 면제** (constitution §9.1 예외)

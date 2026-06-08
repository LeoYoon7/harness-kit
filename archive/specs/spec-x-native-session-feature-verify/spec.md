# spec-x-native-session-feature-verify: Claude Code 세션 기능(/background·/branch) 게이트 보존 검증

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-native-session-feature-verify` |
| **Phase** | `phase-x` |
| **Branch** | `spec-x-native-session-feature-verify` |
| **상태** | Planning |
| **타입** | Research |
| **Integration Test Required** | no |
| **작성일** | 2026-06-02 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

직전 세션(`spec-x-cc-native-adoption` 조사 → `spec-x-native-feature-adoption-policy` 정책화, PR #25·#26)에서 Claude Code 네이티브 17개 기능의 도입 적합도를 재검증했다. 그 결과 `/background`(`/bg`)·`/branch`(`/fork`) 2종은 **🔍군 (검증 필요)** 으로 분류되어, 도입 로드맵 **3단계 (검증 테스트 통과 후)** 로 보류되었다 (report §4.3, §5).

ADR-007 + agent.md §6.7 은 *조건부 Go* 7종의 게이트 보존 조건을 명문화했으나, `/background`·`/branch` 는 **실측이 선행되어야** 등급이 확정되므로 정책에 조건이 담기지 못한 상태다.

### 문제점

report 부록 A 의 검증 테스트 **1·4** 가 미해소 상태로 남아, 두 기능은 3단계에 무기한 정체된다. 구체적 위험은 다음과 같다.

- **축 B (알림) — `/background`**: `notify-on-input-wait.sh` 는 `Notification`·`Stop` hook 에 등록되어 input-wait 시점에 발화한다(CLAUDE.fragment §1). 세션이 백그라운드 에이전트로 분리되면 hook 발화 *타이밍/대상*이 달라져 **알림 누락·오발화** 가능성이 있다. §9 절차상 알림 누락은 *모바일 사용자가 응답 여부 자체를 모름 → 회복 불가* 라는 비대칭 비용을 갖는다.
- **축 A/F/C (게이트·hook·멀티모델) — `/branch`**: fork 세션이 §8.5 텍스트 게이트, git hook(check-branch 등), 멀티모델 지정(§6.6)을 온전히 승계하는지 불명이다. 미승계 시 포크된 세션이 게이트를 우회할 수 있다. `CLAUDE_CODE_FORK_SUBAGENT` 설정 여부에 따라 동작이 또 갈린다(report §4.3).

### 해결 방안 (요약)

`/background`·`/branch` 의 위 동작을 **Claude Code 공식 문서 조사 + harness-kit hook 배선 정적 분석 + `CLAUDE_CODE_FORK_SUBAGENT` 의미 분석**으로 판정하여, 기능별 **Go / No-Go / 조건부 Go** 와 (조건부 Go 시) 게이트 보존 조건을 산출한다. 라이브 대화형 실행이 *반드시* 필요한 잔여 claim 은 **사용자 실행용 확인 체크리스트**로 분리한다(Done 조건 아님).

## 🎯 요구사항

### Functional Requirements

1. **`/background` 검증 (test 1)** — `/background` 의 세션 분리 모델에서 input-wait 알림(축 B)이 채널로 정상 도달하는지를, 공식 문서 + harness-kit 의 hook 등록 배선(`settings.json` 의 `Notification`/`Stop` → `notify-on-input-wait.sh` 발화 조건) 정적 분석으로 판정한다. 추가 세션의 공유 글로벌 config 병렬 제약(축 E)도 함께 평가한다.
2. **`/branch` 검증 (test 4)** — `/branch` fork 세션이 git hook(축 F)·§8.5 텍스트 게이트(축 A)·멀티모델 지정(축 C)을 승계하는지를, 공식 문서 + `CLAUDE_CODE_FORK_SUBAGENT` 의미 분석으로 판정한다(설정 유무별 동작 차이 포함).
3. **Go/No-Go 산출** — 두 기능 각각에 대해 ≥2 선택지(조건부 채택 vs 보류 유지)를 trade-off 비교하고, Go / No-Go / 조건부 Go 판정 + 조건을 `report.md` 에 기록한다(agent.md §9.1 Research DoD).
4. **정책 반영** — 판정 결과를 정책에 반영한다.
   - *조건부 Go* 결론 시: agent.md §6.7 + ADR-007 을 갱신하여 해당 기능을 3단계 → 2단계(조건부)로 승격하고 게이트 보존 조건을 명문화한다.
   - *보류 유지* 결론 시: 근거를 `report.md` + `backlog/queue.md` Icebox 에 기록하고 3단계에 잔류시킨다.

### Non-Functional Requirements

1. **자율 완료 가능성** — 백그라운드 에이전트가 라이브 대화형 실행에 *의존하지 않고* 본 spec 을 Done 까지 끌고 갈 수 있어야 한다. 라이브 실측은 선택적 사용자 체크리스트로만 제공한다.
2. **두 시점 중립성** — 판정은 키트 배포 대상(하위 플랜 포함)의 가용성·플랫폼 중립성을 함께 고려한다(report §6 두 시점 관점).

## 🚫 Out of Scope

- **에이전트의 `/background`·`/branch` 라이브 자가 실행 및 관측** — 본 에이전트는 백그라운드 잡으로 실행 중이라 대화형 세션 제어 명령을 스스로 호출해 동작을 관측할 수 없다. 라이브 실측은 *사용자 실행용 체크리스트*로만 제공하며 Done 조건이 아니다.
- **`/batch` 검증** — report §7-4 의 별도 보류 항목(검증 테스트 2·3·5). 본 spec 범위 밖.
- **`/ultraplan`** — 이미 "복귀 플랜을 `/hk-plan-accept` 로 재게이팅" 조건으로 2단계 승격 경로가 명시됨(report §5). 본 spec 범위 밖.
- **알림 hook 의 차단 모드 승격** — 경고→차단 단계론(CLAUDE.md §5)은 별도 운영 결정.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: 본 spec 의 결론은 신규 ADR 이 아니라 **기존 ADR-007 (native-feature-adoption-policy) 의 amendment** 로 반영한다 (조건부 Go 결론 시). 신규 ADR 미발급.
- [ ] 없음

## ✅ Definition of Done

- [ ] `report.md` 작성 — 기능별 ≥2 선택지 trade-off + Go/No-Go 판정 + 조건 (agent.md §9.1)
- [ ] 정책 반영 완료 — (조건부 Go 시) agent.md §6.7 + ADR-007 갱신, (보류 시) report + Icebox 근거 기록
- [ ] 단위 테스트: **해당 없음** — Research/docs 성격, production 코드 변경 없음 (constitution §9.1 justified)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-native-session-feature-verify` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료

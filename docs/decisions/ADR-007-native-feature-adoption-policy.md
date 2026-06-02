---
id: ADR-007
type: convention
date: 2026-06-02
status: accepted
---

# ADR-007: Claude Code 네이티브 기능의 게이트 보존 도입 정책

> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로(슬래시+확장자)는 `sdd status` 의 stale ADR 검사 대상입니다. spec 참조는 archive 시 경로가 깨지므로 *이름/PR 번호* 로만 표기합니다.

## 📚 Context

조사 `spec-x-cc-native-adoption`(PR #25 머지)이 Claude Code 네이티브 기능 17종을 8개 충돌 축(게이트·알림·멀티모델·PR플랫폼·세션·git hook·기존자산·사용제한)으로 재검증하여 **7종을 "조건부 Go"** 로 분류했다. 이들은 Plan Accept·§8.5 Choice Presentation 게이트, 멀티모델 전략(§6.6), 권한 자세를 건드릴 수 있어, 무조건 도입하면 거버넌스 게이트를 *조용히 우회*한다.

그러나 이 조건들은 조사 산출물(report.md)에만 존재해 **강제력이 없었다**. "조건부 Go"가 실효를 가지려면 조건이 거버넌스 규약으로 승격되어야 한다.

## 🎯 Decision

7종 네이티브 기능은 아래 **게이트 보존 조건 하에서만** 사용한다 (convention).

| 기능 | 게이트 보존 조건 | 막는 충돌 |
|---|---|---|
| `/goal` | 단일 spec/phase 의 acceptance criteria 를 조건으로 삼고, 조건문에 "각 게이트에서 멈추고 보고"를 명시. phase 경계 불가침 | 자율 지속이 §8.5·Plan Accept 건너뜀 |
| `/effort ultracode` | spec·plan 이 확정된 *구현 phase 내부* 한정. 전체 프로젝트 적용 금지 | 자동 오케스트레이션이 phase별 모델 지정 override |
| `/fewer-permission-prompts` | 생성된 allowlist 를 *커밋 전 검토*. `.env`·SSH 키 가드 우회 금지 | 무검토 allowlist 가 통제된 권한 자세 약화 |
| `/code-review ultra` | 중요 PR 의 ship 직전 *보강 1회*(크레딧 제한). 정식 리뷰는 `/hk-gemini-review` + `/hk-code-review` | 크레딧 소진 + 정식 리뷰 대체 오인 |
| `/code-review` 기본형 | 수시 정리·자동수정(`--fix`) *보조*. ship 게이트 정식 리뷰 대체 금지 | spec 대비 검증·테스트 커버리지 누락 |
| `/ultraplan` | 복귀한 플랜을 반드시 `/hk-plan-accept` 로 *재게이팅* | 계획이 훅·멀티모델·§8.5 밖에서 수립 |
| 스킬 시스템 | `/hk-*` 와 *중복 안 되는* 작업 한정. 컨텍스트 비용(bash > slash > skill > MCP) 인지 | 거버넌스 워크플로 중복·컨텍스트 비용 |

**공통 원칙**: 자율(`/goal`·`ultracode`)·세션분리·웹핸드오프 기능이 텍스트 게이트(§8.5)·Plan Accept·양방향 알림(§10) 응답 기회를 박탈하지 않도록, *각 게이트에서 멈추고 보고하는 조건*을 보존한다. (AUQ 가 아닌 텍스트 게이트가 기준 — 정책 전환 반영.)

본 정책은 **규약(convention) 수준**이며 hook 강제가 아니다. 위반은 walkthrough/RCA 로 학습한다.

## 📊 Consequences

- **긍정**: 조건부 Go 기능을 게이트 우회 없이 안전하게 활용 가능. 조사 결과가 강제 규약으로 승격되어 실효 확보. 상세는 본 ADR, agent.md 엔 요지만 두어 거버넌스 본문 비대화 최소화.
- **부정**: agent.md 에 요지 추가로 단어 수 소폭 증가(요지만). 사용자가 조건을 인지할 부담.
- **중립**: hook 강제 아님 — 규약 수준에 머문다. hook 화는 "경고 1주 후 차단 승격"(CLAUDE.md hook 단계론)을 따라 별도 검토.

## 🔀 Alternatives

- **agent.md 본문에 전체 박기**: 7종 상세를 거버넌스 본문에. — 비채택: 단어 수 한계(6000w, 현재 초과) 악화.
- **전면 금지**: 조건부 Go 기능을 아예 차단. — 비채택: 조건 하에서 실질 가치가 있음(예: `/goal` 로 phase 자동화).
- **hook 즉시 강제**: 위반 시 차단 hook. — 비채택: 본 spec 은 규약 명문화까지. hook 은 단계론(경고→차단)을 따라 별도 spec.

## 📌 Status

Accepted (2026-06-02, `spec-x-native-feature-adoption-policy` 머지 시점). 첫 적용: agent.md §6.7 요지 + 본 ADR 참조.

## 🔗 Related

- 조사: `spec-x-cc-native-adoption` (PR #25) — 8충돌축 매트릭스 + Go/No-Go 종합
- ADR-006 (code-review-gate-default-run) — cross-model 리뷰 게이트
- 검증 후속(Icebox): `/background`·`/branch` 세션 기능 실측, `/batch` Bitbucket 정합성

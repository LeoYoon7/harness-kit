# spec-x-human-gate-model-lock: 사람 승인 게이트 커맨드의 모델 자가 호출 차단

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-human-gate-model-lock` |
| **Phase** | `phase-x` |
| **Branch** | `spec-x-human-gate-model-lock` |
| **상태** | Planning |
| **타입** | Fix (거버넌스 하드닝) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-04 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

Claude Code 에는 모델(에이전트)이 커스텀 커맨드/스킬을 *프로그래밍적으로 호출*하는 메커니즘이 있다 (SlashCommand/Skill tool). 검증(claude-code-guide + 외부 docs 교차) 결과:

- 커스텀 커맨드/스킬은 `description` frontmatter 가 있고 `disable-model-invocation: true` 가 아니면 **기본 model-invocable**.
- harness-kit 의 `/hk-*` 는 **모두 `description` 보유**, **`disable-model-invocation` 0건** (repo 전체 grep) → 전부 기본 model-invocable.
- 커맨드 호출 시 그 본문이 instruction 으로 실행됨.

### 문제점

**`/hk-plan-accept` 가 model-invocable** 이다. 이는 *사람이 승인하는 게이트*(constitution §5.2/§5.3 — Premature Execution = CRITICAL VIOLATION)인데, 에이전트가 자가 호출하면 **자가 승인 = Plan Accept 게이트 우회**가 된다. `/hk-phase-ship`(Phase go/no-go, constitution §3.1 Phase Ship Rule) 도 동일하다.

거버넌스는 hook 으로 *편집*을 게이팅하지만, 정작 그 게이트를 *여는 커맨드*를 모델이 스스로 호출할 수 있으면 enforcement 모델이 무력화된다. 기본 권한 posture 가 silent-allow 라면 사람이 인지조차 못 하는 silent 우회다.

### 해결 방안 (요약)

human-gate 커맨드(`/hk-plan-accept`, `/hk-phase-ship`)의 frontmatter 에 **`disable-model-invocation: true`** 를 추가해 *모델 자가 호출만 차단*한다 (사람 타이핑 호출은 그대로). 이는 두 출처(claude-code-guide + 외부 docs)가 *합의한 robust 레버*로, 도구 이름(SlashCommand vs Skill)·권한 syntax 논쟁과 무관하게 frontmatter 한 줄로 작동한다. 배포되어 모든 설치 대상에 적용된다.

## 🎯 요구사항

### Functional Requirements

1. **게이트 커맨드 잠금** — `sources/commands/hk-plan-accept.md` + `sources/commands/hk-phase-ship.md` frontmatter 에 `disable-model-invocation: true` 추가.
2. **도그푸딩 동기화** — `.claude/commands/hk-plan-accept.md` + `.claude/commands/hk-phase-ship.md` 에 동일 반영 (설치본 정합).
3. **사용 playbook 정정** — `sources/governance/native-feature-usage.md`(+ `.harness-kit/agent/` 동기화) §1.5 를 검증 결과로 갱신: 기준은 SlashCommand/Skill tool(skill 목록 아님), `/workflows`(뷰어)·`/team-onboarding` 은 내장→👤, `/batch` 는 skill→🤖, 그리고 `disable-model-invocation` 레버 + `/hk-*` invocable 사실 명시.
4. **ADR-008 작성** — invariant: "사람 승인 게이트 커맨드는 model-invocable 이면 안 된다" + `disable-model-invocation` 정책 + settings 권한 레이어 보류 근거.

### Non-Functional Requirements

1. **사람 호출 무영향** — `disable-model-invocation` 은 *모델* 호출만 막고 사람의 `/hk-plan-accept` 타이핑은 정상 동작해야 한다.
2. **배포 정합** — 원본(`sources/`)과 설치본(`.claude/commands/`, `.harness-kit/agent/`)이 동기화돼야 한다.

## 🚫 Out of Scope

- **settings.json SlashCommand/Skill 권한 화이트리스트** — 도구 이름(SlashCommand vs Skill)·권한 syntax(`SlashCommand:/cmd` vs `Skill(name)`)·기본 posture 가 두 출처 간 불일치. `disable-model-invocation` 만으로 게이트는 닫히므로, 권한 레이어는 *별도 검증 후* (Icebox). 본 spec 에 포함하지 않음.
- **다른 `/hk-*` 잠금** — `/hk-ship`·`/hk-pr-*` 등은 Plan Accept 후 *위임된 권한*(constitution §7.1)이라 model-invocable 유지가 정합. 본 spec 은 `plan-accept`·`phase-ship` 2개 게이트만.
- **모델 호출 차단의 런타임 실증** — 모델의 invocable 집합을 직접 관측하긴 어려움. 본 spec 은 frontmatter 적용까지. (적용이 안 먹으면 → Hard Stop, §plan 위험 참조.)

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보: `ADR-008-human-gate-model-invocation` (type: **invariant** — 사람 승인 게이트는 model-invocable 금지)
- [ ] 없음

## ✅ Definition of Done

- [ ] `hk-plan-accept.md` + `hk-phase-ship.md` 에 `disable-model-invocation: true` (sources + .claude/commands 동기화)
- [ ] 사용 playbook §1.5 검증 결과 반영 (sources/governance + .harness-kit/agent 동기화)
- [ ] `docs/decisions/ADR-008-human-gate-model-invocation.md` 작성 (type: invariant)
- [ ] 단위 테스트: 해당 없음 — docs/config (constitution §9.1). 거버넌스 동기화(Check 2) 영향 시 회귀 확인
- [ ] `walkthrough.md` / `pr_description.md` ship commit
- [ ] `spec-x-human-gate-model-lock` 브랜치 push
- [ ] 사용자 검토 요청 알림

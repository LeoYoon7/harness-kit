---
id: ADR-008
type: invariant
date: 2026-06-04
status: accepted
---

# ADR-008: 사람 승인 게이트 커맨드는 model-invocable 이면 안 된다

> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로(슬래시+확장자)는 `sdd status` 의 stale ADR 검사 대상입니다. 커맨드는 *이름*(`/hk-plan-accept`)으로 표기해 archive/경로 이동에 안전하게 둡니다.

## 📚 Context

Claude Code 에는 모델(에이전트)이 커스텀 커맨드·번들 스킬을 *프로그래밍적으로 호출*하는 메커니즘(SlashCommand/Skill tool)이 있다. 검증(claude-code-guide + 외부 docs 교차) 결과: 커맨드는 `description` frontmatter 가 있고 `disable-model-invocation: true` 가 아니면 **기본 model-invocable** 이고, 호출 시 본문이 instruction 으로 실행된다.

harness-kit 의 `/hk-*` 는 모두 `description` 보유 + `disable-model-invocation` 0건이었다 → 전부 기본 model-invocable. 그 결과 **`/hk-plan-accept`**(사람 승인 게이트, constitution §5.2/§5.3 — Premature Execution = CRITICAL VIOLATION)와 **`/hk-phase-ship`**(Phase go/no-go, §3.1)을 에이전트가 *자가 호출 = 자가 승인* 하면 게이트가 우회된다. hook 은 편집을 게이팅하지만, 게이트를 *여는 커맨드*를 모델이 스스로 부를 수 있으면 enforcement 가 무력화된다.

## 🎯 Decision

**사람의 명시적 승인을 요구하는 게이트 커맨드는 model-invocable 이면 안 된다** (invariant). 해당 커맨드의 frontmatter 에 `disable-model-invocation: true` 를 둔다 — 모델 자가 호출만 차단하고 사람 타이핑 호출은 보존한다. 최초 적용: `/hk-plan-accept`, `/hk-phase-ship`.

## 📊 Consequences

- **긍정**: 사람 승인 게이트의 자가 승인 우회가 차단된다. 커맨드 frontmatter 라 **install 로 모든 설치 대상에 배포**되어 보호가 전파된다. 사람 호출·다른 `/hk-*`(post-accept 위임: `/hk-ship`·`/hk-pr-*`)의 model-invocable 성은 유지 — 자율 체이닝 봉쇄 없음.
- **부정**: ① `disable-model-invocation` 이 `.claude/commands` 의 커맨드 파일(스킬 아님)에 적용된다는 *가정* 의존 — 안 먹으면 settings 권한 레이어 또는 커맨드→스킬 전환이 fallback. ② **회귀 가드 미비** — 신규 사람-게이트 커맨드 추가 시 이 frontmatter 누락 위험. doctor/test 점검은 후속 과제(Icebox).
- **중립**: settings 의 SlashCommand/Skill 권한 화이트리스트는 본 ADR 범위 밖(보류) — 도구 이름(SlashCommand vs Skill)·권한 syntax·기본 posture 가 출처 간 불일치하여 별도 검증 후 결정. 현재는 frontmatter 레버만으로 게이트를 닫는다.

## 🔀 Alternatives

- **settings 에서 SlashCommand/Skill tool 전체 deny**: 모델의 모든 커맨드 자가 호출 차단. — 비채택: 자율 `/hk-*` 체이닝(예: `/hk-spec-critique`)까지 봉쇄 + 도구명·syntax 불확실로 정확한 규칙 작성 불가.
- **게이트 커맨드를 스킬(`.claude/skills`)로 전환**: — 비채택: 과함. frontmatter 한 줄(`disable-model-invocation`)이 두 형식 모두에 작동한다는 검증 결과로 충분.
- **무조치(convention 만)**: 규약으로 "에이전트는 게이트를 자가 호출하지 말라" 명문화. — 비채택: convention 은 시든다 (`/hk-code-review` optional→always-skip 전례, ADR-006). 기계적 차단이 정합.

## 📌 Status

Accepted (2026-06-04, `spec-x-human-gate-model-lock` 머지 시점). 적용: `/hk-plan-accept`, `/hk-phase-ship`.

## 🔗 Related

- 검증/적용: `spec-x-human-gate-model-lock` — SlashCommand/Skill tool 메커니즘 docs 검증 + frontmatter 적용
- ADR-007 (native-feature-adoption-policy) — 호출 주체(🤖 에이전트 / 👤 사용자) 구분의 출발점
- ADR-006 (code-review-gate-default-run) — "convention 은 시든다" 전례 (forcing 레버 필요 근거)
- 사용 playbook: `.harness-kit/agent/native-feature-usage.md` §1.5 (호출 주체 + 본 invariant 반영)

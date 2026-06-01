---
id: ADR-003
type: convention
date: 2026-05-28
status: accepted
---

# ADR-003: harness-kit self-host 의 dogfood sync 정책 — `update.sh` SSOT

## 📚 Context

harness-kit 는 자기 자신에게 키트를 install 해 도그푸딩한다 (CLAUDE.md). `sources/` 의 변경분이 본 저장소의 `.harness-kit/` · `.claude/` · 프로젝트 루트에 *자동* 적용되지 않아, 다수 PR (특히 `spec-x-notify-channels` 머지 후) 의 자산 누락이 발견되었다 (`spec-x-dogfood-sync`). 동시에 self-hosting 의 *복사 모델 일관성* 과 *link 모델 도입 유혹* 사이의 결정도 함께 필요하다.

## 🎯 Decision

본 저장소의 sources → installed 동기화는 **키트 자체 `update.sh` 가 SSOT 다.** 수동 `cp` / symlink / 설치본 직접 편집은 금지한다. 외부 target 프로젝트와 동일한 *복사 모델* 을 유지한다 (link 모델 미도입).

`update.sh` 외 경로로 `.harness-kit/*` / `.claude/*` / 프로젝트 루트 설치 자산을 변경하는 PR 은 본 정책 위반이다 — 정당한 사유 (예: install.sh 자체 수정 검증 fixture) 가 있으면 PR 본문에 명시하고 후속 sync 가 그 변경을 다시 적용·관리한다.

## 📊 Consequences

- **긍정**: dogfood sync 의 *판단 기준* 이 단일화됨. 향후 drift 가 발견되면 "`update.sh` 1회 호출" 이라는 표준 경로 하나만 검토. 외부 target 프로젝트와 self-host 가 같은 install 모델을 공유해 *도그푸딩 의미* 보존 (외부에서만 깨지는 도구 사용 회피).
- **부정**: drift 가 자동으로 *가시화* 되지 않음 — 사람이 우연히 `diff -rq` 또는 sync 사고로 발견할 때까지 누적. 본 한계는 별도 후속 (`도그푸딩 sync 자동화`, queue.md Icebox) 으로 닫는다.
- **중립**: `update.sh` 가 destructive 동작 (uninstall → install) 이라 실행 중 다른 도구 호출 금지 가드가 운영상 필요 (`spec-x-dogfood-sync` 의 FR6 로 박힘).

### Constraints (`drift-visibility-deferred` 흡수)

본 ADR 은 drift 가시화 메커니즘 (sdd doctor / CI check / post-merge auto-update) 을 의도적으로 분리한다. 이유: 본 정책 PR (`spec-x-dogfood-sync`) 의 범위 부풀림 방지 + 가시화 메커니즘 자체의 alternative analysis (3개 옵션) 가 별도 검토 가치를 가짐. 6 개월 안에 본 결정을 뒤집을 가능성이 있어 *tradeoff* 성격을 가지나, 핵심 정책(SSOT = update.sh) 은 가시화 방식과 직교 — 별도 ADR 로 승격하지 않고 본 ADR 의 *제약* 으로 흡수한다.

## 🔀 Alternatives

- **수동 선별 복사 (`cp` 로 drift 표 항목만)**: 누락 위험. drift 표 자체가 사람이 만든 스냅샷이라 일부만 본 다음 빠진 항목을 발견하지 못 함. 비채택 이유: `update.sh` 가 키트 자체 멱등 메커니즘으로 *전체* 를 다룸.

- **link 모델 (`.harness-kit/agent/agent.md` → `../../sources/governance/agent.md` symlink)**: drift 가 원천적으로 0. 비채택 이유: 외부 target 프로젝트는 여전히 snapshot — self-host 만 link 면 *도그푸딩의 의미* (외부와 동일 install 경험) 가 깨짐. Windows symlink 권한 이슈도 추가 위험.

- **카테고리별 분할 sync commit** (governance / dispatcher / runtime hooks / runtime root): commit 가독성 ↑. 비채택 이유: `update.sh` 가 한 번에 모두 적용하므로 분할은 *인공적* — 의미 단위가 "sources@vX.Y.Z 적용" 하나로 환원됨.

- **drift 가시화 메커니즘을 같은 PR 에 포함**: 본 사건 (drift 누적 → 사고) 의 근본 원인을 같은 PR 에서 닫음. 비채택 이유: spec 의 OOS 를 깸. 가시화 방식 자체가 별도 설계 검토 가치 — 본 ADR 의 *Constraints* 로 흡수.

## 📌 Status

**Accepted (2026-05-28, `spec-x-dogfood-sync` 머지 직후, PR #2).**

첫 사용자: 본 저장소 (harness-kit self-host). 다른 적용처 없음 (self-host 단독 정책).

## 🔗 Related

- Spec: `archive/specs/spec-x-dogfood-sync/spec.md`
- Walkthrough: `archive/specs/spec-x-dogfood-sync/walkthrough.md`
- Critique: `archive/specs/spec-x-dogfood-sync/critique.md` (대안 분석 원본)
- PR: `LeoYoon7/harness-kit#2`
- 후속: queue.md Icebox 의 "도그푸딩 sync 자동화" / "check-secrets.sh `.env.*.example` 패턴 제외 fix"

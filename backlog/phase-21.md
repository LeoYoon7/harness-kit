# phase-21: director-mode

> 본 phase 의 모든 SPEC 을 한 파일에 요점/방향성으로 나열합니다.
> *구체적* 작업 내용은 `specs/spec-21-{seq}-{slug}/spec.md` 에서 다룹니다.
>
> 본 문서는 "이번 phase 에서 무엇을 어디까지 할 것인가" 를 한 번에 보기 위한 *업무 지도* 입니다.

## 📋 메타

| 항목 | 값 |
|---|---|
| **Phase ID** | `phase-21` |
| **상태** | Planning |
| **시작일** | 2026-06-04 |
| **목표 종료일** | (미정) |
| **소유자** | Leo |
| **Base Branch** | `phase-21-director-mode` (opt-in, 첫 hk-ship 시 자동 생성) |

## 🎯 배경 및 목표

### 현재 상황

phase-20(upstream-parity)에서 quick wins(`/hk-report-issue`, doctor/footgun fix)와 phase-FF 1급화는 달성했으나, **director mode(컨텍스트 오케스트레이션)** 는 규모상 본 phase 로 의식적 이관했다 (phase-20 결정 기록, 2026-06-04).

upstream(Changsik00/harness-kit)은 이 기능을 ADR-005(context-orchestration)·ADR-006(director-mode) + 6개 spec(switch / protocol / ceremony 분업 / model config de-hardcode / 중재 research / 페르소나 패널)으로 구현했다. 단순 cherry-pick 은 불가하다: ① upstream agent.md §6.6/§6.8 재작성이 fork 의 §6.6(Model Allocation)·§6.7(Workflow Patterns)·ADR-007/008 과 충돌, ② **ADR 번호 의미 정면 충돌**(upstream 005/006 = context-orch/director vs fork 005/006 = ignore-symmetry/code-review-gate).

동시에 fork 의 거버넌스 단어 예산 테스트(`tests/test-governance-dedup.sh` Check 3)가 **현재 red** 다 — constitution+agent.md 합계 **7285w > 6000w 상한**. director mode 는 거버넌스에 *내용을 추가*하므로, 이 phase 는 추가와 다이어트를 **동시에** 풀어야 한다 (upstream 은 상한을 8000w 로 올려 회피했으나, fork 의 "컨텍스트 비용 0 우선" 원칙과 상충).

### 목표 (Goal)

upstream 의 director mode 가치를 **fork 구조(§6.6/§6.7·ADR-007/008)에 맞춰 재구현**한다. cherry-pick 이 아니라 패턴 포팅 + 신규 ADR 번호(010/011) 부여. 토글 표면(mechanical)은 자족적이라 포팅 가능, governance prose 는 fork 구조에 정합하도록 재작성. **agent.md 축소를 병행해 거버넌스 단어 예산 테스트를 green 으로 복구**한다.

### 성공 기준 (Success Criteria) — 정량 우선

1. **토글 표면**: `sdd config director-mode on/off/toggle` + `installed.json` `directorMode` 영속화 + `sdd status`/`sdd doctor` 노출이 동작 (전용 테스트 PASS, `sources ↔ .claude`/`.harness-kit` 미러 parity).
2. **context orchestration**: agent.md §6.6 가 orchestrator–worker + context offloading 정책(5축)으로 확장되고, ADR-010 작성 + **검증 불변식(워커 transcript 전문 재흡수 금지)** 명문화 (전용 테스트 PASS).
3. **Director Mode Protocol**: agent.md §6.8(intent handshake / scoped brief / distilled contract / 행동 검증 / 게이트 보유 / over-dispatch 금지) + §6.1 delegation 단락 + ADR-011, fork §6.6/§6.7·ADR-007/008 과 **충돌 없음**.
4. **단어 예산 해소**: `tests/test-governance-dedup.sh` Check 3 가 **GREEN** (현재 7285w red → 상한 내). governance 일관성 테스트 무 NEW 회귀 + `sources ↔ installed` sync 유지.
5. **역할 기반 모델 config**: director/worker/scout 역할 → 모델 매핑이 config 로 분리되어 모델 이름 하드코딩 제거 (`sdd config models` 출력 + 전용 테스트).

## 🧩 작업 단위 (SPECs)

> 본 표는 phase 의 *작업 지도* 입니다. SPEC 은 *요점 + 방향성 + 참조* 까지만 적습니다.
> 자세한 spec/plan/task 는 `specs/spec-21-{seq}-{slug}/` 에서 작성합니다.
> sdd 가 `<!-- sdd:specs:start --> ~ <!-- sdd:specs:end -->` 사이를 자동 갱신하므로 마커는 그대로 두세요.
>
> ⚠ **본 분해는 DRAFT** (constitution §11.3). 각 spec 시작 전 직전 spec 의 실제 변경 영향을 재검증하고 bundle/phase-FF/순서 조정한다. 특히 §6.8 protocol 의 *배치*(agent.md 인라인 vs 별도 가이드 문서)는 spec-21-01 계획 시 확정한다(아래 위험 표 참조).

<!-- sdd:specs:start -->
| ID | 슬러그 | 우선순위 | 상태 | 디렉토리 |
|---|---|:---:|---|---|
| `spec-21-01` | context-orchestration | P? | Merged | `specs/spec-21-01-context-orchestration/` |
| `spec-21-02` | director-mode-switch | P? | Merged | `specs/spec-21-02-director-mode-switch/` |
| `spec-21-03` | director-protocol | P? | Merged | `specs/spec-21-03-director-protocol/` |
| `spec-21-04` | role-model-config | P? | Active | `specs/spec-21-04-role-model-config/` |
<!-- sdd:specs:end -->

> 상태 허용값: `Backlog` / `In Progress` / `Merged`
> sdd가 ship 시 자동으로 `Merged`로 갱신합니다. `In Progress`는 active spec에 자동 마킹됩니다.

### spec-21-01 — context-orchestration (foundation, 먼저)

- **요점**: agent.md §6.6(Model Allocation Strategy)를 **orchestrator–worker + context offloading 정책**으로 확장하고 ADR-010 작성. director mode 토글과 무관하게 *항상 적용*되는 기반 정책(upstream ADR-005 는 암묵 always-on 전략).
- **방향성**: cherry-pick 금지 — fork §6.6 구조에 5축(① 위임 대상: 토큰 무거운/오염성 노동 vs 판단·조정, ② scoped slice 만 주입, ③ distilled result contract 만 반환, ④ 검증은 orchestrator 보유, ⑤ 독립 job fan-out)을 재작성. **단어 예산 전략을 본 spec 에서 확정**(별도 가이드 분리 여부).
- **참조**: upstream `ADR-005-context-orchestration`, upstream `agent.md §6.6/§6.7`, fork `ADR-007/008`(정합 점검)
- **연관 모듈**: `sources/governance/agent.md`, `.harness-kit/agent/agent.md`(미러), `docs/decisions/ADR-010-*`

### spec-21-02 — director-mode-switch (mechanical 표면, 포팅)

- **요점**: `/hk-director` 토글 커맨드 + `sdd config director-mode`(on/off/toggle/조회) + `installed.json` `directorMode` 영속화 + `sdd status`/`sdd doctor` 노출.
- **방향성**: upstream spec-20-01 표면은 자족적(sdd config 분기)이라 **복사 포팅** 가능. `sources/commands/hk-director.md` + `.claude/commands/` 미러 + `sources/bin/sdd` config 분기 + 단위 테스트(`test-director-mode.sh` 포팅).
- **참조**: upstream `sources/commands/hk-director.md`, upstream `tests/test-director-mode.sh`
- **연관 모듈**: `sources/commands/hk-director.md`, `sources/bin/sdd`, `installed.json`

### spec-21-03 — director-protocol (행동 규약 + 불변식)

- **요점**: agent.md **§6.8 Director Mode Protocol** + §6.1 delegation 단락 + ADR-011. 검증 불변식(디렉터는 워커 transcript 전문 재흡수 금지 — *테스트 재실행 + 동작 스모크 + 증류 계약 대조*로만 검수).
- **방향성**: upstream spec-20-02 재구현 — intent handshake / scoped brief 명세 / distilled contract 반납 / 행동 검증 불변식 / Plan Accept·Ship 게이트 보유 / over-dispatch 금지. 간결하게(≤300w) 작성하고 근거는 ADR 참조. **fork 의 §5/§9 알림 게이트·human-gate(ADR-008)와 정합 필수** — 디렉터가 워커에 게이트를 내리면 안 됨.
- **참조**: upstream `ADR-006-director-mode`, upstream `spec-20-02-director-protocol`, upstream `tests/test-director-protocol.sh`, fork `ADR-008`(human-gate-model)
- **연관 모듈**: `sources/governance/agent.md`, `.harness-kit/agent/agent.md`(미러), `docs/decisions/ADR-011-*`

### spec-21-04 — role-model-config (de-hardcode)

- **요점**: director/worker/scout 역할 → 모델 매핑을 config 로 분리(`sdd config models`). agent.md §6.6 의 모델 이름 하드코딩(Opus/Sonnet) 제거 → 모델 세대 churn 에 거버넌스가 견딤.
- **방향성**: upstream spec-20-04 — `installed.json`(또는 `harness.config.json`)에 역할→모델 매핑 + `sdd config models` 출력. fork §6.6 모델 표와 정합(표는 역할 참조로 전환).
- **참조**: upstream spec-20-04(director-protocol Out of Scope 참조), upstream `tests/test-director-mode.sh` T12
- **연관 모듈**: `sources/bin/sdd`, `installed.json`, `sources/governance/agent.md`

### spec-21-05 — persona-review-panel

- **요점**: review 커맨드(`hk-code-review`/`hk-spec-critique`/`hk-phase-review`)에 **페르소나 패널** 오케스트레이션 — 단일 Opus 대신 페르소나 부여 워커 패널 + 보고 종합/중재.
- **방향성**: upstream spec-20-06 — fork 의 `hk-*-review` 커맨드 텍스트에 페르소나 패널 절 추가 + 미러 parity. upstream 도 중재 패턴(spec-20-05)은 research-only 였으므로, 종료조건·증류 난점은 §11.3 재검증으로 신중히(분해 또는 후순위 판단).
- **참조**: upstream spec-20-06(director-protocol Out of Scope 참조), upstream `tests/test-director-mode.sh` T13/T14
- **연관 모듈**: `sources/commands/hk-code-review.md`, `sources/commands/hk-spec-critique.md`, `sources/commands/hk-phase-review.md`, `.claude/commands/`(미러)

### spec-21-06 — governance-diet (단어 예산 green 복구)

- **요점**: constitution+agent.md 합계를 6000w 상한 내로 다이어트 (현재 7333w → 목표 <6000w, ~1333w+ 절감). 성공기준 4(`test-governance-dedup.sh` Check 3 GREEN) 달성.
- **방향성**: 의미 손실 없이 중복/장황 prose 압축 + 별도 가이드(native-feature-usage·director-mode)로 분리 가능한 인라인 잔재 정리. 21-03 의 §6.8 stub 순증분도 흡수. **add/delete 혼재 회피를 위해 protocol(21-03)과 분리** — 본 spec 은 *삭제/압축 전용*.
- **참조**: `tests/test-governance-dedup.sh` Check 3, 21-01 walkthrough(±50w 순증 이월 결정)
- **연관 모듈**: `sources/governance/constitution.md`, `sources/governance/agent.md`, `.harness-kit/agent/`(미러)

> **agent.md 다이어트(성공기준 4)** 는 spec-21-03 §11.3 재검증서 그 규모(~1333w)가 protocol 추가와 독립적이고 크다고 확인되어 **별도 spec-21-06 으로 분리**한다(위 narrative). 21-03 은 §6.8 배치 전략(별도 `director-mode.md` 가이드 + 간결 stub)으로 agent.md 순증을 최소화하는 데 그치고, 단어 예산 green(<6000w)은 21-06 이 책임진다. 따라서 Check 3 GREEN 은 21-03 의 DoD 가 아니라 **phase Done 조건**이다.

## 📌 결정 기록 (Review)

> Phase PR review 중 발생한 결정·합의·발견을 누적합니다. Spec walkthrough 의 결정 기록과 동일 패턴이며 Phase 레벨 living decision log 역할 (→ agent.md §6.3.2).
> review 핑퐁으로 success criterion / 통합 테스트 시나리오 / spec 구성이 바뀌면 본 문서 해당 섹션을 직접 갱신하고, *왜* 그렇게 결정했는지의 이유를 본 표에 추가로 남깁니다.

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 통합 방식 | 전체 merge / cherry-pick / 재구현 | **재구현 + 표면 포팅 혼합** | upstream agent.md §6.6/§6.8 재작성이 fork §6.6/§6.7·ADR-007/008 과 충돌. 토글 표면만 자족적이라 포팅 가능 |
| ADR 번호 | upstream 005/006 재사용 / fork 신규 | **fork 신규 010/011** | fork ADR-005/006 은 ignore-symmetry/code-review-gate — 의미 충돌. upstream 005/006 은 참조로만 |
| §6.8 배치 | agent.md 인라인 / 별도 가이드 문서 | **별도 `director-mode.md` 가이드 + agent.md 간결 stub** | native-feature-usage.md 패턴. agent.md 순증 최소화(stub). 21-01 이 §6.8 을 분리 후보로 표시 (spec-21-03 §11.3 재검증서 확정) |
| 단어 예산 상한 | 6000w 유지 / 8000w 상향(upstream) | **6000w 유지 + 다이어트는 spec-21-06 분리** | fork "컨텍스트 비용 0 우선". 다이어트 ~1333w 가 protocol 추가와 독립·대규모 → add/delete 혼재 회피. 상향은 anti-bloat 충돌 (spec-21-03 §11.3 재검증서 확정) |

## 🧪 통합 테스트 시나리오 (간결)

> 본 phase 의 Done 조건 중 하나. 키트 자체 검증 스크립트는 `tests/` 에 위치.

### 시나리오 1: director mode 토글 + 거버넌스 정합
- **Given**: director mode 표면(21-02) + protocol(21-03) 재구현 완료
- **When**: `sdd config director-mode on` 실행 후 `sdd status` / `sdd doctor` / governance 일관성 테스트 실행
- **Then**: `directorMode=true` 가 status/doctor 에 노출 + §6.6/§6.7 충돌 없음 + `sources ↔ installed` 미러 parity 유지
- **연관 SPEC**: spec-21-02, spec-21-03

### 시나리오 2: 거버넌스 단어 예산 green + 무회귀
- **Given**: context orchestration(21-01) + protocol(21-03) + 다이어트 반영 완료
- **When**: `bash tests/test-governance-dedup.sh` 전체 실행
- **Then**: Check 3(단어 예산) GREEN + Check 1/2/4/5/6 무 NEW 회귀 (이전 red → 전체 green)
- **연관 SPEC**: spec-21-01, spec-21-03

### 시나리오 3: 역할 기반 모델 config 노출
- **Given**: role-model-config(21-04) 완료
- **When**: `sdd config models` 실행
- **Then**: director/worker/scout 역할 → 모델 매핑 출력 + agent.md §6.6 에 하드코딩된 모델 이름 부재
- **연관 SPEC**: spec-21-04

### 통합 테스트 실행
```bash
bash tests/test-governance-dedup.sh
# + spec 별 신규 테스트 (test-director-mode.sh, test-director-protocol.sh, test-context-orchestration.sh 등)
```

## 🔗 의존성

- **선행 phase**: 없음 (phase-20 upstream-parity 에서 director mode 만 의식적 이관)
- **외부 시스템**: upstream remote(Changsik00/harness-kit, read-only) — 참조용. 로컬 `upstream/main` ref 에 director 자산 fetch 완료(`hk-director.md`, `ADR-005/006`, `spec-20-01/02`, `test-director-*.sh`).
- **연관 ADR**:
  - `docs/decisions/ADR-010-context-orchestration.md` (신규, spec-21-01)
  - `docs/decisions/ADR-011-director-mode.md` (신규, spec-21-03)
  - 정합 점검: fork `ADR-007`(native-feature-adoption), `ADR-008`(human-gate-model). upstream `ADR-005/006` 은 *참조*(번호 충돌로 그대로 못 씀).

## 📝 위험 요소 및 완화

| 위험 | 영향 | 완화책 |
|---|---|---|
| **agent.md 단어 예산** (director 추가 vs 6000w 상한, 현재 이미 7285w red) | 거버넌스 테스트 계속 red, phase Done 불가 | §6.8 protocol 을 별도 `director-mode.md` 가이드로 분리 + agent.md 간결 stub + 기존 중복 다이어트. 상한 상향은 최후 수단 |
| ADR 번호 충돌 (upstream 005/006 ↔ fork 005/006) | cherry-pick 시 의미 혼선 | fork 신규 010/011 부여, upstream 은 참조로만 |
| §6.6/§6.8 머지 충돌 | director 통합 난이도↑ | cherry-pick 대신 fork 구조 재구현 |
| director mode scope 과대 (upstream 6 spec) | phase 비대 | §11.3 재검증으로 분해/순서/bundle 판단. 3부작 + config + 다이어트로 압축 |
| 페르소나 패널 종료조건/증류 난점 | 무한 루프·context 오염 | upstream 도 중재(20-05)는 research-only. fork 도 신중히 — 분해 또는 후순위 |
| 디렉터 게이트 위임 위험 | human-gate(ADR-008)·§5/§9 알림 우회 | §6.8 에 "Plan Accept·Ship 게이트는 디렉터+사용자 보유, 워커에 내리지 않음" 명문화 |

## 🏁 Phase Done 조건

- [ ] 모든 SPEC 이 merge (base branch 모드: `phase-21-director-mode` → main)
- [ ] 통합 테스트 전 시나리오 PASS
- [ ] 성공 기준 정량 측정 결과 기록 (특히 단어 예산 green 증빙)
- [ ] 사용자 최종 승인 (`/hk-phase-ship` go/no-go)

## 📊 검증 결과 (phase 완료 시 작성)

<!-- 통합 테스트 로그, 성공 기준 측정값(단어 예산 before/after), 회귀 점검 결과 -->

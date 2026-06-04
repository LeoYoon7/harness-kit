# spec-21-04: 역할 기반 모델 config (de-hardcode)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-21-04` |
| **Phase** | `phase-21` |
| **Branch** | `spec-21-04-role-model-config` |
| **상태** | Planning |
| **타입** | Feature |
| **Integration Test Required** | no |
| **작성일** | 2026-06-05 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

agent.md **§6.6 Model & Context Allocation Strategy** 가 모델 이름을 *하드코딩*하고 있다.

- prose: "The main session runs on **Opus** ... Sub-agents are dispatched with explicit model overrides."
- 4행 표의 Model 열: `Opus (main)` / `Sonnet (sub-agent)` / `Opus (sub-agent)` ×2.

spec-21-03 이 §6.8/§6.1 에 "director/worker" *역할 언어*를 도입했으나, 정작 §6.6 의 역할→모델 매핑은 여전히 모델 이름으로 박혀 있다.

### 문제점

- **모델 세대 churn 부채**: Opus/Sonnet 세대가 바뀔 때마다(예: 4.7→4.8) 거버넌스 문서를 직접 수정해야 한다. 거버넌스는 *정책*(어떤 역할에 어떤 티어)이어야 하는데 *구현 디테일*(모델 이름)에 묶여 있다.
- **단일 소스 부재**: 역할→모델 매핑이 코드/설정이 아니라 산문에 흩어져 있어, 사용자가 티어를 조정(예: worker 를 다른 모델로)할 방법이 없다.
- **§6.8 역할 언어와 불일치**: §6.8 은 director/worker 를 말하는데 §6.6 은 Opus/Sonnet 을 말해, 역할 추상화가 일관되지 않다.

### 해결 방안 (요약)

역할→모델 매핑을 `installed.json` `.models` 로 분리하고 `sdd config models` 로 노출한다(기존 `_config_director_mode` 패턴 미러). §6.6 의 모델 이름을 **역할 참조**(director/worker/scout → `models.*`)로 de-hardcode 한다. 결정 근거는 ADR-011(이미 "모델 티어 = 역할 기반 config" 명시)에 귀속 — 신규 ADR 불요.

## 📊 개념도

```text
설치 환경 (installed.json)
  .models = { director: "opus", worker: "sonnet", scout: "opus" }
        │
        ├── sdd config models            → 매핑 출력 (list)
        ├── sdd config models <role> <m> → 단일 역할 갱신 (set)
        │
거버넌스 (agent.md §6.6)
  표 = 역할(director/worker/scout) → `models.*` 참조 (모델 이름 부재)
        │
  근거 = ADR-011 (모델 티어 = 역할 기반 config, 모델 churn 견딤)
```

## 🎯 요구사항

### Functional Requirements

1. **`.models` config 필드**: `installed.json` 에 `models` 매핑 추가 — `director` / `worker` / `scout` 3역할. 기본값은 현 동작 보존(`director: opus`, `worker: sonnet`, `scout: opus`).
2. **`sdd config models` (list)**: 인수 없이 호출 시 역할→모델 매핑을 출력. `cmd_config` 의 `models)` 분기 + `_config_models` 함수(기존 `_config_director_mode`/`_config_precheck` 패턴).
3. **`sdd config models <role> <model>` (set)**: 단일 역할의 모델을 갱신(installed.json 기록). 미지원 role 은 명확한 에러.
4. **§6.6 de-hardcode**: §6.6 표의 모델 이름(Opus/Sonnet)을 역할(director/worker/scout) → `models.*` 참조로 전환. prose "runs on Opus" → "runs as director (`models.director`)". 모델 티어가 config 임을 명시(→ ADR-011, `sdd config models`).
5. **역할 taxonomy 정의**: §6.6 의 기존 4역할을 3역할로 매핑 — authoring/judgment/**review·critique** → `director`, task execution → `worker`, code analysis/broad search → `scout`. (taxonomy 확정은 plan User Review 항목.)
6. **단위 테스트**: `tests/test-role-model-config.sh` — `.models` 기본 3역할 존재 / `sdd config models` list 출력 / `set` 갱신 / §6.6 역할 참조(`models.director` 등) 존재 + 모델 이름 하드코딩 부재 / 이중 미러 parity.

### Non-Functional Requirements

1. **기본 동작 보존**: 기존 설치 환경(`.models` 미존재)에서도 폴백 기본값(director=opus/worker=sonnet/scout=opus)으로 동작. backward compatible.
2. **언어 분리**: §6.6(agent.md) 영어. `sdd config models` 출력 라벨 한국어 허용(기존 config 출력 관행).
3. **이중 미러 parity**: `sources/governance/agent.md` ↔ `.harness-kit/agent/agent.md` + `sources/bin/sdd` ↔ `.harness-kit/bin/sdd` 동기화.
4. **bash 3.2 호환**: `declare -A` 등 bash4 기능 금지 — `.models` 는 jq 로 다룬다(연관배열 미사용).
5. **단어 예산**: §6.6 de-hardcode 는 표를 4행→3행으로 줄여 agent.md 가 **줄어들 가능성**이 높다(21-06 다이어트 부담 경감). green(<6000w) 복구는 본 spec scope 아님(→ 21-06).
6. **No over-engineering**: `models` 는 3역할에 한정. 사용처 없는 역할(예: 별도 reviewer/embedder) 추가 금지(constitution / 프로젝트 원칙).

## 🚫 Out of Scope

- **단어 예산 green 복구** → spec-21-06.
- **페르소나 리뷰 패널** → spec-21-05.
- **§6.7 "Model transparency" 예시 문자열**(`[Opus 4.7 — main]`) — *예시 포맷*이지 역할→모델 정책 표가 아님. 변경하지 않음(필요 시 21-06 에서 표현 정리).
- **ADR-010/011 의 Opus/Sonnet 언급** — 시점 기록(historical), de-hardcode 대상 아님.
- **런타임 모델 자동 적용** — 본 spec 은 *config + 거버넌스 문서* 분리만. 에이전트가 config 를 읽어 실제 디스패치 모델을 바꾸는 자동화는 범위 밖(에이전트는 §6.6 참조로 판단).

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — de-hardcode 근거는 **ADR-011**(director-mode) 의 "모델 티어 = 역할 기반 config 매핑, 모델 churn 견딤" 결정에 이미 귀속. 본 spec 은 그 구현.

## ✅ Definition of Done

- [ ] `installed.json` `.models` 3역할 기본값 추가 (source `sources/root` 또는 install 시드 경로 + 로컬)
- [ ] `sdd config models` (list) + `sdd config models <role> <model>` (set) 구현 (source + 미러)
- [ ] agent.md §6.6 de-hardcode (역할 참조, source + 미러)
- [ ] `tests/test-role-model-config.sh` 신규 작성 및 전체 PASS
- [ ] `test-governance-dedup.sh` 무 NEW 회귀 (Check 3 red 유지 — 21-06 책임) + `test-director-mode.sh`/`test-director-protocol.sh` 무 회귀
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-21-04-role-model-config` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료

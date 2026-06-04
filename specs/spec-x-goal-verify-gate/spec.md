# spec-x-goal-verify-gate: `/goal` 자율 실행 시 검증 강제 게이트 정책

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-goal-verify-gate` |
| **Phase** | 해당 없음 (spec-x) |
| **Branch** | `spec-x-goal-verify-gate` |
| **상태** | Planning |
| **타입** | docs (governance) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-04 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

ADR-007 은 `/goal` 을 **2단계(조건부 Go)** 로 두고, 게이트 보존 조건으로 "단일 spec/phase 의 acceptance criteria 한정 + 각 게이트에서 멈추고 보고 + phase 경계 불가침" 을 규정한다. `/goal` 은 👤 사용자 전용 자율 기능으로, 목표 도달까지 에이전트가 자율 진행하는 것이 본래 목적이다.

### 문제점

"각 게이트에서 멈추고 보고" 조건이 `/goal` 의 자율 진행 목적과 **본질적으로 충돌**한다. 게이트마다 멈추면 자율성이 사실상 사장된다. 그렇다고 무중단 자율을 허용하면 Plan Accept·권한 게이트를 조용히 우회할 위험이 생긴다. 현재 조건은 이 긴장을 해소하지 못한 채 "멈춤" 쪽으로만 기울어 있다.

### 해결 방안 (요약)

`/goal` 자율 실행에 **검증 강제 레이어**(진입 전 critique + ship 전 code-review)를 추가해 자율 진행의 신뢰도를 높인다. 동시에 **검증(verification)과 승인(authorization)을 분리**하여, 검증 강제로 멈춤 빈도는 낮추되 권한 게이트 2개(Plan Accept·계획밖 deviation)는 hard-stop 으로 보존한다.

## 🎯 요구사항

### Functional Requirements

1. **검증 강제** — `/goal` 이 spec(6+ task)/phase 급 범위로 실행될 때, **진입 전 critique 강제** + **ship 전 code-review 강제(skip 불가)**.
2. **검증 ≠ 승인 명문화** — code-review/critique 통과가 Plan Accept·scope 확장·merge 승인을 *대체하지 않음*을 거버넌스에 명시.
3. **hard-stop 2개 보존** — `/goal` 자율 실행 중에도 ① 진입 Plan Accept(ADR-008 하드락) ② 계획 밖 권한 필요 deviation(헌법 §7.2 / agent.md §7)은 멈춘다.
4. **launch ritual 앵커링** — 에이전트가 `/goal` 모드를 신뢰성 있게 자동 감지하지 못할 수 있으므로(👤 기능), 정책을 *사용자의 `/goal` 시작 의식*에 앵커링한다 (시작 전 critique 실행 + ship code-review 강제 인지).
5. **강제 임계값 = §11.2 재사용** — spec(6+ task)/phase 급이면 critique+code-review 둘 다 강제, 그 미만이면 ship code-review 만. 새 임계값 도입하지 않음.
6. **1차는 보수안(Q1-a)** — 가역적 in-scope 마이크로 A/B 결정도 hard-stop 유지. 적극안(Q1-b, agent.md §7 hard-stop 완화 = logged-default 레인)은 본 spec 범위 밖, 추후 별도 spec 으로 승격(Icebox).

### Non-Functional Requirements

1. **규약(convention) 수준** — hook 강제가 아님(ADR-007 일관). 위반은 walkthrough/RCA 로 학습.
2. **거버넌스 본문 비대화 최소화** — 상세는 ADR-007 Amendment + 플레이북에 두고, `agent.md §6.7` 은 요지 + ADR 포인터만 (거버넌스 단어수 한계 인지 — queue.md Icebox).
3. **도그푸딩 sync** — `agent.md`/플레이북의 sources ↔ installed 정합 유지(ADR-003).

## 🚫 Out of Scope

- **Q1-b (agent.md §7 hard-stop 완화 — logged-default 레인)**: 본 spec 은 보수안만. 완전 무중단 자율은 별도 spec.
- **`/goal` 자동 감지 hook/메커니즘**: 본 spec 은 launch-ritual 운영 규칙만 도입.
- **code-review 강제의 hook 화**: 규약 수준 유지(차단 hook 아님).
- **다른 👤 기능(`/background`·`/effort ultracode` 등)의 검증 정책**: `/goal` 한정.

## 📑 ADR 후보

> 본 spec 의 결정은 ADR-007 의 `/goal` 조건 *refinement* 이므로, **신규 ADR 이 아니라 ADR-007 Amendment** 로 기록한다 (ADR-007 의 기존 Amendment 패턴과 일관). type 은 ADR-007 의 `convention` 유지.

- [x] ADR-007 Amendment 로 기록 (신규 번호 미발급)
- [ ] 없음

## ✅ Definition of Done

- [ ] governance 일관성 검증 — `tests/test-governance-dedup.sh` 등 무 NEW 회귀 (docs-only, 단위테스트 미해당 — 헌법 §9.1 문서 변경 예외)
- [ ] ADR-007 Amendment ↔ `agent.md §6.7` ↔ 플레이북 `/goal` 행 3자 일관성 육안 확인
- [ ] sources ↔ installed diff 0 (agent.md / native-feature-usage.md)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-goal-verify-gate` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료

# spec-x-fragment-two-tier-restore: fragment 슬림화로 2단계 로딩 구조 복원

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-fragment-two-tier-restore` |
| **Phase** | `phase-x` (Phase 비소속) |
| **Branch** | `spec-x-fragment-two-tier-restore` |
| **상태** | Planning |
| **타입** | Refactor |
| **Integration Test Required** | no |
| **작성일** | 2026-06-16 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

harness-kit 은 거버넌스를 **2단계로 로딩**하도록 설계되었다.

- **tier-1 (상시 로딩)**: `sources/claude-fragments/CLAUDE.fragment.md` — 대상 프로젝트의 `CLAUDE.md` 가 `@import` 하여 **매 세션 항상** 컨텍스트에 올라온다. 설계 의도는 *핵심 규칙 요약만* 담는 것 (테스트 목표 ≤150w).
- **tier-2 (필요 시 로딩)**: `sources/governance/{constitution,agent,align}.md` — `/hk-align` 슬래시 커맨드가 `@import` 하여 SDD 작업 시작 시에만 로딩되는 상세 규약.

이 구조는 `tests/test-two-tier-loading.sh` 가 강제한다 (Check 4: fragment ≤150w).

### 문제점

알림 프로토콜(Telegram/Discord §1~§10) · 선택지 제시 규약 · 검증된 패턴/안티패턴이 시간이 지나며 tier-1 fragment 에 **누적**되었다. 그 결과:

- **fragment 가 3095w 로 비대화** → `test-two-tier-loading.sh` **Check 4 FAIL** (목표 ≤150w, 현재 main 에 상존하는 실패).
- 약 3000w 의 운영 상세가 **매 세션 상시 로딩**되어, 프로젝트 1차 원칙인 "컨텍스트 비용 0 우선" (CLAUDE.md 작업 원칙 §2) 을 위배한다.
- 2단계 로딩 설계 의도(tier-1=요약, tier-2=상세)가 사실상 무너진 상태.

### 해결 방안 (요약)

fragment 를 **핵심 규칙 요약(실측 101w)만 남기고**, 비대화의 원인인 상세 내용을 tier-2 로 이전한다. 알림 프로토콜 + 선택지 제시 규약은 신규 tier-2 문서 `sources/governance/notify.md` 로, 검증된 패턴/안티패턴은 의미상 적합한 `sources/governance/align.md` 로 옮긴다. `notify.md` 는 `/hk-align` 커맨드에서 `@import` 한다. 이로써 Check 4 가 통과하고 2단계 로딩 구조가 원래 의도대로 복원된다.

## 🎯 요구사항

### Functional Requirements

1. `sources/claude-fragments/CLAUDE.fragment.md` 가 **핵심 규칙 요약 섹션만** 보유하여 단어 수 ≤150w 를 만족한다 (Check 4 PASS). 단, "핵심 규칙 요약" 문구는 유지한다 (Check 5 PASS).
2. fragment 에서 제거되는 상세는 **삭제가 아니라 이전**되어야 한다 — 내용 손실 0.
   - 의사결정 알림 프로토콜(§1~§10) + 선택지 제시 규약 + 알림 마크다운 컨벤션 → 신규 `sources/governance/notify.md`.
   - 검증된 패턴 & 안티패턴(phase-08~18 distilled) → `sources/governance/align.md`.
3. `notify.md` 의 알림 프로토콜 섹션 번호(§1~§10)는 **기존 체계를 그대로 보존**한다 — `agent.md` 및 fragment 요약이 "§5/§9 알림" 으로 참조하는 링크가 유지되도록.
4. `/hk-align` 커맨드(`sources/commands/hk-align.md`)가 `@.harness-kit/agent/notify.md` 를 `@import` 한다.
5. fragment 요약에 tier-2 로 이전된 상세의 **위치 포인터**(notify.md / align.md 참조)를 1줄 남긴다.
6. 도그푸딩 정합: sources 편집 후 설치본(`.harness-kit/`, `.claude/commands/`)을 동기화하여 `sdd status` drift 미발생.

### Non-Functional Requirements

1. **회귀 안전**: `tests/test-two-tier-loading.sh` 와 `tests/test-governance-dedup.sh` 가 모두 PASS.
2. **내용 무손실**: 이전 전후 알림/선택지/패턴의 의미가 보존됨 (단순 relocation, 재작성 아님).
3. **기능 무회귀 인지**: 알림 프로토콜 상세가 tier-2(=`/hk-align` 시 로딩)로 내려가므로, `/hk-align` 없이 시작한 세션은 상세를 컨텍스트에 갖지 않는다. 단 (a) hook 기반 계층 1 자동 알림은 시스템 레벨이라 영향 없음, (b) 핵심 하드 규칙("선택지 시 권장안 필수")은 fragment 요약에 1줄로 상존, (c) 모든 SDD 작업은 `/hk-align` 으로 시작하므로 실질 영향 없음. 이 트레이드오프를 walkthrough 에 명시.

## 🚫 Out of Scope

- 알림 프로토콜 / 선택지 규약 / 패턴의 **내용 재작성·정책 변경** — 본 spec 은 *위치 이동*만 한다.
- 신규 tier-2 문서(`notify.md`)에 대한 **단어 수 상한(budget) 테스트 신설** — 내용이 늘어난 게 아니라 이동한 것이므로 본 spec 범위 밖. 필요 시 Icebox follow-up.
- `agent.md`/`constitution.md` 의 §5/§9 참조 텍스트 **재서술** — 섹션 번호 보존으로 링크가 유지되므로 손대지 않음 (surgical change).
- fragment 내용을 대상 프로젝트 일반화(generic) 하는 작업 — 현 분포(전 대상 배포)를 그대로 유지.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 2단계 로딩 구조(tier-1 요약 / tier-2 상세)는 *이미 존재하는 컨벤션*이며 테스트가 강제 중. 본 spec 은 드리프트된 상태를 원 의도로 *복원*할 뿐 새 결정을 만들지 않는다.

## ✅ Definition of Done

- [ ] `test-two-tier-loading.sh` PASS (Check 4 포함 전체)
- [ ] `test-governance-dedup.sh` PASS
- [ ] fragment ≤150w + "핵심 규칙 요약" 유지
- [ ] 이전된 상세(알림/선택지/패턴) 내용 무손실 확인
- [ ] 설치본 동기화 → `sdd status` drift 깔끔
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-fragment-two-tier-restore` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료

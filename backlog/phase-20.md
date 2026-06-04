# phase-20: upstream-parity

> 본 phase 의 모든 SPEC 을 한 파일에 요점/방향성으로 나열합니다.
> *구체적* 작업 내용은 `specs/spec-20-{seq}-{slug}/spec.md` 에서 다룹니다.

## 📋 메타

| 항목 | 값 |
|---|---|
| **Phase ID** | `phase-20` |
| **상태** | Planning |
| **시작일** | 2026-06-04 |
| **목표 종료일** | (미정) |
| **소유자** | Leo |
| **Base Branch** | `phase-20-upstream-parity` (opt-in, 첫 hk-ship 시 자동 생성) |

## 🎯 배경 및 목표

### 현재 상황

본 fork(LeoYoon7/harness-kit)는 upstream(Changsik00/harness-kit)에서 `0.13.6` 시점에 분기해 독자 진행했다(fork-ahead 77 / upstream-ahead 30). 그동안 upstream 이 추가한 신규 기능 — **director mode(컨텍스트 오케스트레이션)**, **phase-FF 1급화**, **`/hk-report-issue`**, 소규모 fix — 를 fork 가 보유하지 못했다.

단순 `git merge upstream/main` 은 불가하다: ① `agent.md`/`constitution.md`/`CLAUDE.fragment` 양쪽 대폭 수정 충돌, ② **ADR-004/005/006 번호 의미 정면 충돌**(upstream=phase-FF/context-orch/director vs fork=notification/ignore-symmetry/code-review-gate), ③ notify/wiki/secrets 는 양쪽 병렬 진화.

### 목표 (Goal)

upstream 의 가치 있는 신규 기능을 **fork 구조에 맞게** 적용한다. 충돌 위험에 따라 혼합 전략 — 신규 파일형은 포팅(복사), governance-heavy 는 fork 거버넌스(§6.6/§6.7/ADR-007·008)와 정합하도록 **재구현**(신규 ADR 번호 부여). quick wins 로 흐름을 검증한 뒤 director mode 를 신중히.

### 성공 기준 (Success Criteria) — 정량 우선

1. `/hk-report-issue` 가 fork 에 설치·동작 (sources + installed 동기화 + 단위 테스트 PASS).
2. director mode(컨텍스트 오케스트레이션) 가 fork 의 §6.6/§6.7·ADR-007/008 과 **충돌 없이** 재구현 (전용 테스트 PASS, 신규 ADR 번호).
3. phase-FF 1급 작업 모드가 fork 거버넌스(constitution/agent.md/fragment)에 반영.
4. upstream 소규모 fix(doctor lefthook×hooksPath #162, footgun #158)는 충돌 점검 후 반영 *또는* 의식적 제외(사유 기록).
5. governance 일관성 테스트 무 NEW 회귀 + `sources ↔ installed` sync 유지.

## 🧩 작업 단위 (SPECs)

> SPEC 은 *요점 + 방향성 + 참조* 까지만. 자세한 내용은 `specs/spec-20-{seq}-{slug}/`.
> sdd 가 마커 사이를 자동 갱신하므로 그대로 두세요.

<!-- sdd:specs:start -->
| ID | 슬러그 | 우선순위 | 상태 | 디렉토리 |
|---|---|:---:|---|---|
| `spec-20-01` | hk-report-issue | P? | Merged | `specs/spec-20-01-hk-report-issue/` |
| `spec-20-02` | doctor-lefthook | P? | Merged | `specs/spec-20-02-doctor-lefthook/` |
| `spec-20-03` | harness-footguns | P? | Active | `specs/spec-20-03-harness-footguns/` |
<!-- sdd:specs:end -->

> 상태 허용값: `Backlog` / `In Progress` / `Merged`

### spec-20-01 — hk-report-issue (quick win, 먼저)

- **요점**: upstream 의 `/hk-report-issue` 커맨드(키트 자체 버그를 kit GitHub repo 에 이슈로 환류)를 fork 에 포팅.
- **방향성**: 커맨드 파일이 자족적이라(`kitOrigin`/gh 기반, 분기 거버넌스 비의존) **복사 포팅** 가능. `sources/commands/` + `.claude/commands/` + README + `installed.json` installedCommands + 단위 테스트.
- **참조**: upstream `98912f0`, `sources/commands/hk-report-issue.md`
- **연관**: `installed.json`, `README.md`

### (후속, 충돌 점검 후) 소규모 fix — phase-FF 후보

- **요점**: doctor lefthook×core.hooksPath 충돌 탐지(#162), 하네스 footgun 3종(#158).
- **방향성**: fork sdd 분기와 충돌 점검 → 낮으면 phase-FF(직접 커밋), 높으면 소규모 재구현. §11.3 inter-spec 재검증으로 시점 판단.

### (후반) director mode 3부작 — 재구현

- **요점**: context orchestration(메인=orchestrator + offloading) + `/hk-director` 모드 + ceremony 위임 + 페르소나 리뷰 패널.
- **방향성**: upstream agent.md 재작성을 cherry-pick 하지 않고, **fork §6.6/§6.7 구조에 맞춰 재구현**. ADR 신규 번호(009+). 검증 불변식(워커 transcript 전문 재흡수 금지) 포함. multi-spec 예상 — quick wins 후 §11.3 재검증으로 spec 분해(또는 별도 phase 승격) 판단.
- **참조**: upstream ADR-005/006, `agent.md §6.1/6.6/6.8`, `hk-director.md`, `tests/test-director-*.sh`

### (후반) phase-FF 1급화 — 재구현

- **요점**: phase 내 작업을 항목별 right-size(작고 가역 → phase-FF). pre-push gate de-hardcode.
- **방향성**: fork 의 §11.4·CLAUDE.fragment(notify 프로토콜로 비대)에 맞춰 재구성. ADR 신규 번호.
- **참조**: upstream ADR-004, constitution §3.1, agent.md §11.4

## 📌 결정 기록 (Review)

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 통합 방식 | 전체 merge / cherry-pick / 재구현 | 기능별 혼합 (포팅+재구현) | fork↔upstream 분기 과대 — merge 충돌·ADR 번호 충돌·병렬작업 혼입 |
| 시작 순서 | quick wins / director mode | quick wins 먼저 | 낮은 위험으로 포팅 흐름 검증 + /hk-report-issue 즉시 가치(hook 결함 리포팅) |

## 🧪 통합 테스트 시나리오 (간결)

### 시나리오 1: hk-report-issue 도달성
- **Given**: fork 에 `/hk-report-issue` 포팅 완료
- **When**: 커맨드의 판정 게이트·본문 생성 로직을 dry 실행(게시 직전까지)
- **Then**: kitOrigin 에서 slug 도출 + 본문 템플릿 생성 + `[Y/n]` 게이트 도달 (실제 게시 없이)
- **연관 SPEC**: spec-20-01

### 시나리오 2: director mode 토글 + 거버넌스 정합
- **Given**: director mode 재구현 완료
- **When**: `sdd config director-mode on` + governance 일관성 테스트
- **Then**: directorMode 가 status/doctor 에 노출 + §6.6/§6.7 충돌 없음 + sync 유지
- **연관 SPEC**: director mode 관련 spec

### 통합 테스트 실행
```bash
bash tests/test-governance-dedup.sh
# + spec 별 신규 테스트 (test-report-issue.sh, test-director-*.sh 등)
```

## 🔗 의존성

- **선행 phase**: 없음
- **외부 시스템**: upstream remote(Changsik00/harness-kit, read-only) — 참조용. `gh` (이슈/PR).
- **연관 ADR**: 신규 부여 예정(director mode·phase-FF). upstream ADR-004/005/006 은 *참조*(번호 충돌로 그대로 못 씀).

## 📝 위험 요소 및 완화

| 위험 | 영향 | 완화책 |
|---|---|---|
| ADR 번호 충돌 (004/005/006) | cherry-pick 시 의미 혼선 | fork 신규 번호(009+) 부여, upstream 은 참조로만 |
| agent.md §6.6/§6.8 머지 충돌 | director mode 통합 난이도↑ | cherry-pick 대신 fork 구조 재구현 |
| 병렬 진화 기능 중복 | notify/wiki/secrets 재도입 위험 | 본 phase 범위에서 제외(이미 fork 보유) |
| director mode 과대 scope | phase 비대 | §11.3 재검증으로 분해/별도 phase 승격 판단 |

## 🏁 Phase Done 조건

- [ ] 모든 SPEC 이 merge (base branch 모드: `phase-20-upstream-parity` → main)
- [ ] 통합 테스트 전 시나리오 PASS
- [ ] 성공 기준 정량 측정 결과 기록
- [ ] 사용자 최종 승인 (`/hk-phase-ship` go/no-go)

## 📊 검증 결과 (phase 완료 시 작성)

<!-- 통합 테스트 로그, 성공 기준 측정값, 회귀 점검 결과 -->

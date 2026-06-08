# spec-20-03: 운영 footgun 3종 fork 반영 (upstream #158 parity)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-20-03` |
| **Phase** | `phase-20` |
| **Branch** | `spec-20-03-harness-footguns` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-06-04 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

upstream(Changsik00/harness-kit)이 PR #158(`spec-x-harness-footguns`)에서 도그푸딩 현장 제보 3건을 묶어 수정했다. fork(LeoYoon7/harness-kit)는 `0.13.6` 분기 이후 이 fix 를 보유하지 못했다. spec-20-02(doctor lefthook, #162) 작업 시 footgun(#158)은 "fork 와 중복+sdd 분기로 복잡"하다는 이유로 별도 triage 로 분리해 이월했다(spec-20-02 walkthrough 이월 항목).

본 spec 은 그 이월 항목을 받아, **fork 의 병렬 진화·sdd 분기에 맞게 3종을 재반영**한다.

### 문제점 (triage 결과 — fork 현재 상태 대조)

| Footgun | upstream fix | fork 현재 상태 | 판정 |
|---|---|---|---|
| **#2 시크릿 가드 오탐** | 값이 shell 보간(`${..}`/`$(..)`/`$VAR`)·placeholder 면 시크릿 오탐에서 제외 | fork 는 **다른** 진화(`.md` 본문 제외, `staged_diff_no_md`)만 보유. 비-`.md` 파일의 `${POSTGRES_PASSWORD:-default}` 는 **여전히 오탐** | 병렬 진화 — 두 예외를 **머지** |
| **#1a update 산물 미커밋** | `update.sh` 종료 시 미커밋 install 산물 감지 → 명시적 커밋 안내 | fork `update.sh` 는 해당 안내 블록 **없음**(diff 확인) | 깔끔한 additive 포팅 |
| **#1b branch 생성 시 drift 경고** | `sdd spec new`/`specx new` 시 `_warn_install_drift`(비차단 경고) | fork 는 `_warn_install_drift` 헬퍼·호출 **없음**. 단 `sdd status` 레벨 drift 탐지는 보유(다른 surface) | 채택 — 능동 경고 보강 |
| **#3 phase activate 마찰** | `--base=<branch>` 인자 + phase.md 메타 자동 기입 + 같은 phase 재활성 시 active spec 보존 | fork 는 메타 미기입 시 **die**, 같은 phase 재활성은 `--force` 강요 → active spec 리셋 | 재구현 |

**구체적 통증**.

1. **#2** — fork 에서 `docker-compose.yml`·`.env.example`·shell 스크립트 등 비-`.md` 파일에 `${DB_PASSWORD:-changeme}` 같은 정상 env 보간이 들어가면 시크릿 가드가 오탐해 커밋이 막힌다. fork 의 `.md` 제외는 문서 본문만 커버하고 실제 코드 파일의 보간은 못 막는다.
2. **#1a/#1b** — `/hk-update` 가 `.harness-kit/*`·`.claude/*` 를 덮어쓰고 커밋하지 않아, 이후 새 spec 브랜치를 따면 그 변경이 따라붙어 PR scope 를 오염시킨다(spec-20-02 walkthrough 발견 "doctor.sh CRLF→LF 정규화" 도 동류). 사용자가 커밋해야 함을 능동적으로 알려주는 신호가 없다.
3. **#3** — phase-20 자체가 base 모드(`phase-20-upstream-parity`)다. base 브랜치를 나중에 지정·정정하려고 같은 phase 를 재활성하면 active spec 컨텍스트가 리셋되거나(또는 `--force` 강요), phase.md 메타가 비어 있으면 die 해서 state 수술을 강요한다.

### 해결 방안 (요약)

3종 footgun 을 **하나의 spec 으로 묶어** fork 구조에 맞게 반영한다. #2 는 두 오탐 예외(fork `.md` + upstream 보간/placeholder)를 머지하고, #1a/#1b 는 안내·경고를 보강하며, #3 은 phase activate 의 base 인자·재활성 시맨틱을 재구현한다. 모든 신규 경고는 **비차단(warn 모드)** 으로, hook 단계론을 따라 차단 승격하지 않는다.

## 🎯 요구사항

### Functional Requirements

1. **FR-1 (#2)**: `check-secrets.sh` 의 일반 시크릿 검사가 값이 ① shell 변수 보간(`${..}`/`$(..)`/`$VAR`), ② placeholder(`changeme`/`example`/`<...>` 등), ③ bash 파라미터 확장 연산자(`${VAR:-default}`)인 경우 오탐에서 제외한다. **동시에** fork 의 기존 `.md` 본문 제외(`staged_diff_no_md`)도 유지한다. 실제 하드코딩 시크릿(`password=hunter2`)은 계속 차단.
2. **FR-2 (#1a)**: `update.sh` 종료 시 `.harness-kit/`·`.claude/` 에 미커밋 변경이 있으면 비차단 경고 + 커밋 명령 예시를 출력한다.
3. **FR-3 (#1b)**: `sdd spec new`·`sdd specx new` 가 브랜치 생성 직전 미커밋 install drift 를 감지하면 `_warn_install_drift` 로 비차단 경고를 출력한다(rc 보존).
4. **FR-4 (#3)**: `sdd phase activate` 가 ① `--base=<branch>` 인자를 받고, ② 인자 미지정 시 phase.md 메타에서 추출하며, ③ 같은 phase 재활성(`cur_phase == id`) 시 active spec·planAccepted 를 보존하고 active-spec 가드를 건너뛰며, ④ 결정된 base 브랜치를 phase.md 'Base Branch' 메타에 자동 기입한다(`_set_phase_base_meta` 헬퍼 포팅).

### Non-Functional Requirements

1. **NFR-1 (무회귀)**: 기존 동작 보존 — fork 의 `.md` 제외(#2), 기존 phase activate 동작(메타 fallback / 다른 phase die), 기존 update/spec-new 동작에 회귀 없음.
2. **NFR-2 (sources↔installed sync)**: `sources/bin/sdd` ↔ `.harness-kit/bin/sdd`, `sources/hooks/check-secrets.sh` ↔ `.harness-kit/hooks/check-secrets.sh` 가 동일하게 유지(`diff -q` SYNCED). `update.sh` 는 루트 단일 파일.
3. **NFR-3 (bash 3.2+)**: 모든 신규 코드는 bash 3.2 호환 — `declare -A`/`mapfile`/`**` globstar/`${var,,}` 등 bash 4+ 문법 금지(CLAUDE.md §3).
4. **NFR-4 (비차단)**: 모든 신규 경고는 rc 를 유지(exit 0 / 경고만). 차단 승격 없음.

## 🚫 Out of Scope

- director mode·phase-FF 1급화(별도 phase-20 후속 작업).
- fork 의 `sdd status` 레벨 drift 탐지 로직 변경 — #1b 는 별도 surface(spec new 시점)이며 status drift 와 병존. status drift 자체는 건드리지 않음.
- check-secrets 의 AWS/Private Key/GitHub 토큰 강형식 패턴(`.md` 포함 전 파일 적용) 변경 — 본 spec 은 "일반 시크릿 할당" 패턴만 다룸.
- update.sh 의 자동 커밋 — dirty repo 위험으로 upstream 과 동일하게 *안내만* 한다(자동 git 변경 금지).

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — upstream 검증된 footgun fix 의 fork 적응. #2 병렬 진화 머지 결정은 walkthrough 에 기록(국소 머지, 장기 불변식 아님). phase-20 plan 도 footgun 을 ADR 비대상으로 명시(ADR 은 director mode/phase-FF 용 009+ 예약).

## ✅ Definition of Done

- [ ] 모든 단위 테스트 PASS (`test-check-secrets-dual-mode.sh` / `test-update.sh` / `test-sdd-spec-new-drift-warn.sh`(신규) / `test-sdd-phase-activate.sh`)
- [ ] `sources` ↔ `.harness-kit` sync 유지 (`diff -q` SYNCED)
- [ ] governance 일관성 무회귀 (`test-governance-dedup.sh`)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-20-03-harness-footguns` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료

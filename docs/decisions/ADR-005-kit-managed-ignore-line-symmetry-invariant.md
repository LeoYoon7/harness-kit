---
id: ADR-005
type: invariant
date: 2026-05-29
status: accepted
---

# ADR-005: install.sh ↔ uninstall.sh `.gitignore` 라인 대칭성 invariant

## 📚 Context

`install.sh` 는 사용자 프로젝트의 `.gitignore` 에 `# harness-kit` 헤더 블록을 만들고 그 안에 키트 관리 라인 (`/.harness-kit/`, `.harness-backup-*/`, `.claude/state/`, `.env.telegram`, `.env.discord`, `specs/**/code-review*.md`) 을 추가한다.

대칭 동작으로 `uninstall.sh` 는 그 블록을 *통째로* 제거해야 하지만, 구현은 `awk` 의 *알려진 패턴 enumeration* 방식이다 (`uninstall.sh:159-167`).

```awk
/^# harness-kit$/                  { inblk=1; next }
inblk==1 && /^!?\.harness-kit\/$/   { next }
inblk==1 && /^\.harness-backup-\*\/$/ { next }
inblk==1 && /^\.claude\/state\/$/   { next }
inblk==1 && /^\.env\.telegram$/     { next }
inblk==1 && /^\.env\.discord$/      { next }
inblk==1                           { inblk=0 }
{ print }
```

`inblk==1 { inblk=0 }` 후행 액션이 *알려지지 않은 라인을 만나는 순간* 블록을 조기 종료시킨다. 이후 라인은 `inblk=0` 상태로 `{ print }` 까지 흘러 *제거 대상에서 빠진다*.

따라서 `install.sh` 가 신규 라인을 추가했는데 `uninstall.sh` awk 에 대응 패턴이 누락되면 다음 두 부작용이 동시 발생한다.

1. 신규 라인 자체가 stale 잔존
2. 신규 라인이 블록 *중간* 에 있을 경우 그 뒤의 알려진 라인까지 *추출 실패*

`spec-x-install-ignore-coverage` critique 가 이 비대칭을 critical 누락으로 식별했고, 본 spec 에서 발견된 위반 사례가 invariant 명시의 필요성을 직접 증명했다.

## 🎯 Decision

**Invariant**: `install.sh` 가 `.gitignore` 의 `# harness-kit` 헤더 블록에 추가하는 *모든* 라인은 `uninstall.sh` 의 awk 블록 (line 159-167) 에 *명시 매칭 라인* (`inblk==1 && /^<pattern>$/ { next }`) 으로 대응 등재되어야 한다.

이 invariant 는 다음 세 위치에서 동시에 강제된다.

1. `install.sh` 의 `_gi_ensure` 호출 라인 (추가/수정 시 본 ADR 참조 주석 의무)
2. `uninstall.sh` awk 블록의 알려진 패턴 enumeration (라인 1대 1 대응)
3. `tests/test-gitignore-config.sh` Scenario J (install/uninstall 라운드 트립 검증) + Scenario I (다중 라운드 안정성)

## 📊 Consequences

- **긍정**: install/uninstall 라운드 트립 무결성 보장 — `update.sh` (uninstall → install) 의 다중 라운드에서도 `.gitignore` 형태 안정. 사용자 `.gitignore` 에 stale harness-kit 라인 잔존 위험 제거.
- **긍정**: 향후 신규 ignore 라인 추가 시점에 본 ADR 가 *self-check 체크리스트* 역할 — install 만 수정하고 uninstall 깜빡하는 함정 차단.
- **부정**: 매 신규 라인 추가마다 *3군데* (install / uninstall / test) 동시 수정 필요 — review/CI 에서 잊기 쉬움. *향후 개선* 으로 `sdd doctor` 가 self-host 시 install.sh 의 `_gi_ensure` 호출과 uninstall.sh awk 패턴의 일치성을 자동 검증하는 점검 추가 가능.
- **중립**: `# harness-kit` 헤더는 self-host 환경에서도 강제 추가됨 (이전 정책: cosmetic 노이즈 회피 목적 skip → 신규 정책: 헤더 부재 시 신규 라인이 고아 라인이 되어 uninstall awk 가 시작점 못 찾는 위험 차단). 본 정책 전환은 `spec-x-install-ignore-coverage` plan.md §주요결정 표에 명시.

## 🔀 Alternatives

- **awk 패턴 enumeration → 헤더~빈줄 사이 전체 제거**: awk 로직을 "헤더 발견 후 다음 빈 줄까지 모두 제거" 로 단순화. 비채택 이유: 사용자가 헤더 블록 안에 *수동 라인* 을 추가했을 때 (예: 본인이 추가한 도구 ignore) 그것까지 함께 제거되는 부작용. 현재 enumeration 방식은 사용자 수동 라인 보존이 명시적 장점.
- **install.sh / uninstall.sh 의 라인 enumeration 을 공통 source 로 분리**: 두 스크립트가 같은 `lib/gitignore-lines.sh` 같은 파일을 source 해서 single source of truth 화. 비채택 이유: bash 의 의존성 그래프 / 설치 동선 (uninstall 은 키트 제거 후에도 동작해야 함) 복잡도 증가. 현재 규모 (라인 6개) 에서는 invariant 명시 + 회귀 테스트 강제로 충분.
- **`# harness-kit` 헤더를 self-host 시 skip 유지 (원래 정책)**: 신규 라인 추가 후에도 self-host 시 헤더 미생성 유지. 비채택 이유: 헤더 부재 시 신규 라인이 *고아 라인* (어느 도구가 관리하는지 불명 + uninstall awk 가 시작점 못 찾음) 이 되어 영원히 잔존 위험. 본 spec critique 의 핵심 발견.

## 📌 Status

Accepted (2026-05-29, `spec-x-install-ignore-coverage` 머지 시점). 첫 적용: `install.sh` `.gitignore` 블록 + `uninstall.sh` awk 블록 (commits `f371be4`, `e701433`).

## 🔗 Related

- `spec-x-install-ignore-coverage` — 본 invariant 의 발견 spec + 첫 적용
- `specs/spec-x-install-ignore-coverage/critique.md` §1 (유사 기법 조사 시사점) — *루트 침입형* `.gitignore` 갱신의 위험 분석
- `tests/test-gitignore-config.sh` Scenario I (다중 라운드) + Scenario J (uninstall 대칭성) — invariant 회귀 강제

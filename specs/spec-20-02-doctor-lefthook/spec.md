# spec-20-02: doctor 의 lefthook × core.hooksPath 충돌 탐지

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-20-02` |
| **Phase** | `phase-20` (upstream-parity) |
| **Branch** | `spec-20-02-doctor-lefthook` |
| **상태** | Planning |
| **타입** | Fix (port) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-04 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

upstream(`9db74c8`, #162 / issue #161)은 `sdd doctor` 와 root `doctor.sh` 에 **lefthook × `core.hooksPath` 충돌 탐지**를 추가했다. fork 는 이 진단을 보유하지 않는다.

### 문제점

**lefthook v2.x 는 `core.hooksPath` 가 로컬 설정되어 있으면 `lefthook install`(prepare 단계)을 거부**한다 → `pnpm install` / `turbo` 연쇄가 실패한다. harness-kit 이 hook 을 `core.hooksPath` 로 설치하는 프로젝트에서 lefthook 을 함께 쓰면 조용히 깨진다. fork 의 doctor 는 이를 못 잡아 사용자가 원인 추적에 시간을 쓴다.

### 해결 방안 (요약)

upstream 의 `_check_lefthook_hookspath()` 검사를 fork 의 `sdd doctor` + `doctor.sh` 에 **포팅**한다. fork doctor 가 동일 helper(`_doc_warn`/`_doc_pass`/`$SDD_ROOT`)를 보유하므로 additive 로 거의 그대로 이식 가능. **진단·안내만** 하고 git 설정을 자동 변경하지 않는다.

## 🎯 요구사항

### Functional Requirements

1. `sdd doctor`(sources/bin/sdd + .harness-kit/bin/sdd)에 `_check_lefthook_hookspath()` 추가 — lefthook 사용(lefthook.yml/.yaml 또는 package.json lefthook) + `core.hooksPath` 로컬 설정 감지 시 `_doc_warn`, lefthook 사용 + 미설정 시 `_doc_pass`. `_check_hooks` 호출 직후 호출.
2. root `doctor.sh` 에 동일 검사 추가.
3. **진단만** — git config 자동 변경 없음. 해결책(`git config --unset --local core.hooksPath`)을 경고 메시지로 안내.
4. 검사 동작 단위 테스트 추가 (lefthook+hooksPath → warn / lefthook+미설정 → pass / lefthook 없음 → skip).

### Non-Functional Requirements

1. **additive** — 기존 doctor 동작·출력 무변경 (새 검사 블록만 추가).
2. fork doctor helper 재사용, **bash 3.2 호환** (declare -A 등 금지).
3. sources ↔ installed sdd byte-identical (해당 검사 블록).

## 🚫 Out of Scope

- **lefthook-native 통합** (upstream Icebox 항목) — 본 spec 은 *탐지·안내*만.
- **자동 git config 변경** — 진단만, 사용자가 직접 해결.

## 📑 ADR 후보

- [ ] 있음
- [x] 없음 — 단순 진단 검사 포팅

## ✅ Definition of Done

- [ ] 단위 테스트 PASS (`tests/test-doctor-hookspath-lefthook.sh`)
- [ ] `sdd doctor` + `doctor.sh` 양쪽에 검사 추가, sources↔installed sdd sync
- [ ] 기존 doctor 동작 회귀 없음
- [ ] `walkthrough.md` / `pr_description.md` 작성 및 ship commit
- [ ] `spec-20-02-doctor-lefthook` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료

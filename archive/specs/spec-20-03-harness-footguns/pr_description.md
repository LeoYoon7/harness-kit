fix(spec-20-03): 운영 footgun 3종 fork 반영 (upstream #158 parity)

## 📋 Summary

### 배경 및 목적

upstream(Changsik00/harness-kit) PR #158(`spec-x-harness-footguns`)이 도그푸딩 현장 제보 3건을 묶어 수정했으나, fork 는 `0.13.6` 분기 이후 이를 보유하지 못했다. spec-20-02(doctor lefthook, #162)에서 footgun(#158)은 "fork 와 중복+sdd 분기로 복잡"하다는 이유로 별도 triage 로 이월했다. 본 spec 이 그 이월 항목을 받아 fork 의 병렬 진화·sdd 분기에 맞게 재반영한다.

### 주요 변경 사항

- [x] **#2 시크릿 가드 오탐**: `check-secrets.sh` 일반 시크릿 검사에 shell 보간 제외 필터(`_var_re`/`_op_re`) 추가 — `${VAR:-default}`/`$VAR`/`$(..)` 정상 보간을 시크릿 오탐에서 제외. fork 의 `.md` 본문 제외(`staged_diff_no_md`)는 유지.
- [x] **#1a update 산물 안내**: `update.sh` 종료 시 `.harness-kit/`·`.claude/` 미커밋 변경 감지 → 비차단 커밋 안내(자동 커밋 금지).
- [x] **#1b 브랜치 drift 경고**: `_warn_install_drift` 헬퍼 추가 — `sdd spec new`/`specx new` 시 미커밋 install drift 비차단 경고(rc 보존).
- [x] **#3 phase activate**: `--base=<branch>` 인자 + phase.md 메타 자동 기입(`_set_phase_base_meta`) + 같은 phase 재활성 시 active spec/planAccepted 보존.

### Phase 컨텍스트
- **Phase**: `phase-20` (upstream-parity, base 모드)
- **본 SPEC 의 역할**: quick-win 흐름 연장 — upstream footgun parity 확보. 성공 기준 4(소규모 fix 반영) 충족.

## 🎯 Key Review Points

1. **#2 병렬 진화 머지 (`_ph_re` 제외)**: fork 의 `.md` 제외와 upstream 의 보간 제외는 직교한 오탐 원인. upstream `_ph_re`(placeholder)는 fork 기존 `Test 15`(비-.md 맨 placeholder 차단)와 충돌 → **보간 필터만 머지**. 보고된 footgun(env 보간)은 `_var_re`+`_op_re` 로 완전 해결.
2. **#3 state 시맨틱 변경**: 같은 phase 재활성(`same_phase`) 시 active spec 보존 + 가드 생략 — 미세한 행동 변경. `test-sdd-phase-activate.sh` Check 1-9 회귀 보존으로 검증.
3. **sources↔installed sync**: `sdd`/`check-secrets.sh` 양쪽 동기(`diff -q` SYNCED). `update.sh` 는 루트 단일.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-check-secrets-dual-mode.sh   # 19/19
bash tests/test-update.sh                    # 12/12
bash tests/test-sdd-spec-new-drift-warn.sh   # 7/7 (신규)
bash tests/test-sdd-phase-activate.sh        # 17/17 (Check 10/11 신규 + 1-9 회귀)
bash tests/test-sdd-spec-new-seq.sh          # 5/5 (회귀)
```

**결과 요약**: ✅ 전 스위트 PASS. sources↔installed SYNCED.

> 참고: `test-governance-dedup.sh` 는 7/8 — Check 3(constitution+agent.md word count 7073w>6000w)은 본 spec 무관한 **기존 문서 비대화 경고**(변경 파일에 governance 문서 없음).

### 코드 리뷰
- Gemini cross-model: **Approve** (Critical 0 / Major 0 / Minor 2). Minor 2건은 비기능적(regex 이미 양케이스)·입력검증 차단으로 미변경. → `code-review-gemini.md`.

### 수동 검증 시나리오
1. 비-`.md` 파일 `password=${PG_PW:-changeme}` staged → commit — 통과(오탐 없음).
2. 비-`.md` 파일 실제 시크릿 staged → commit — 차단(regression 보존).
3. dirty `.harness-kit/` → `sdd specx new foo` — 경고 + rc=0 + 정상 생성.
4. `sdd phase activate phase-03 --base=phase-03-v2` (active spec 상태) — spec 보존 + 메타 자동 기입.

## 📦 Files Changed

### 🆕 New Files
- `tests/test-sdd-spec-new-drift-warn.sh`: install drift 경고 단위 테스트

### 🛠 Modified Files
- `sources/hooks/check-secrets.sh` / `.harness-kit/hooks/check-secrets.sh`: 보간 제외 필터
- `update.sh`: 미커밋 산물 커밋 안내
- `sources/bin/sdd` / `.harness-kit/bin/sdd`: `_warn_install_drift` + `_set_phase_base_meta` + `phase_activate` 재구현
- `tests/test-check-secrets-dual-mode.sh`: Test 17/18/19
- `tests/test-update.sh`: 시나리오 D
- `tests/test-sdd-phase-activate.sh`: Check 10/11

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] `bash -n` 문법 점검 통과 (shellcheck 미설치 — skip)
- [x] 코드 리뷰 실행 (Gemini, Approve)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Phase: `backlog/phase-20.md`
- Walkthrough: `specs/spec-20-03-harness-footguns/walkthrough.md`
- 코드 리뷰: `specs/spec-20-03-harness-footguns/code-review-gemini.md`
- upstream 참조: PR #158 (`spec-x-harness-footguns`)

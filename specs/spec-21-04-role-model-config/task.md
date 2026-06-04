# Task List: spec-21-04

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd spec new role-model-config`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [x] 백로그 업데이트 (phase-21.md SPEC 표 자동 갱신 — spec-21-04 Active)
- [x] 사용자 Plan Accept (Telegram "1")

---

## Task 1: 브랜치 + 검증 테스트 (TDD Red)

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-21-04-role-model-config` (시작점 = `phase-21-director-mode`)
- [x] Commit: 없음 (브랜치 생성만)

### 1-2. 테스트 작성 (TDD Red)
- [x] `tests/test-role-model-config.sh` 작성 — C1 `.models` 3역할, C2 `sdd config models` list, C3 `set` 갱신(fixture), C4 §6.6 `models.*` 참조 + 모델명 부재, C5 이중 미러 parity(agent.md+sdd).
- [x] 테스트 실행 → Fail 확인 (PASS=2 FAIL=7 — Red)
- [x] Commit: `test(spec-21-04): add failing test for role-model config`

---

## Task 2: config 표면 — sdd config models + 시드

> 논리 단위: "역할→모델 매핑 config 도입" (명령 + 시드 + 로컬값).

### 2-1. config 구현
- [ ] `sources/bin/sdd`: `cmd_config` 에 `models)` 분기 + `_config_models`(list/set, fallback director=opus/worker=sonnet/scout=opus) + `cmd_help` config 사용법 1줄.
- [ ] `.harness-kit/bin/sdd` 미러 동기화 (cp 로 보장).
- [ ] `install.sh`: installed.json heredoc 에 `.models` 기본값 시드.
- [ ] `.harness-kit/installed.json` (로컬): `.models` 3역할 추가 (추적 여부 `git ls-files` 확인 후 처리).
- [ ] 검증: `bash tests/test-role-model-config.sh` → C1/C2/C3 PASS (C4/C5 agent.md 아직 red)
- [ ] Commit: `feat(spec-21-04): add sdd config models (role-model mapping)`

---

## Task 3: §6.6 de-hardcode — GREEN

### 3-1. agent.md §6.6 역할 참조 전환
- [ ] `sources/governance/agent.md`: §6.6 prose "runs on Opus" → "runs as director(`models.director`)", 표 모델명 → 역할(director/worker/scout)+`models.*` 참조(4행→3행, review→director 흡수), config 명시(→ ADR-011).
- [ ] `.harness-kit/agent/agent.md` 미러 동기화 (cp 로 보장).
- [ ] 검증: `bash tests/test-role-model-config.sh` → **전체 PASS (GREEN)**
- [ ] 회귀: `test-governance-dedup.sh`(무 NEW 회귀, Check 3 red 유지·가능하면 단어수 감소 기록) + `test-director-mode.sh` + `test-director-protocol.sh` 무 회귀
- [ ] Commit: `refactor(spec-21-04): de-hardcode 6.6 model names to role config`

---

## Task 4: Ship (필수)

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] 전체 테스트 실행 → `test-role-model-config.sh` PASS + 회귀 무 NEW
- [ ] 코드 리뷰 게이트 (§6.3 — Gemini 권장 / Opus / Skip)
- [ ] **walkthrough.md 작성** (검증 결과, 단어수 before/after, 결정 기록)
- [ ] **pr_description.md 작성** (템플릿 준수)
- [ ] **Ship Commit**: `docs(spec-21-04): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-21-04-role-model-config`
- [ ] **PR 생성**: `/hk-pr-gh` — base = `phase-21-director-mode`
- [ ] **사용자 알림**: 푸시 완료 + PR URL 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 4 (작업 3 + Ship) |
| **예상 commit 수** | 5 (planning / test / config / de-hardcode / ship) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-06-05 |

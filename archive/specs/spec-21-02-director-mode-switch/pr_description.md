# feat(spec-21-02): director-mode toggle switch (/hk-director + sdd config)

## 📋 Summary

### 배경 및 목적

spec-21-01 에서 context orchestration 정책(§6.6, ADR-010)을 *always-on* 으로 확립했다. 본 spec 은 사용자가 director mode 를 **명시적으로 켜는 스위치**를 추가한다 — upstream spec-20-01 의 스위치 표면을 fork 구조에 포팅. **switch-only**: `on` 은 플래그만 세팅하며, 그 플래그가 *무엇을 하는지*(행동 규약)는 §6.8/spec-21-03 책임.

### 주요 변경 사항
- [x] `sdd config director-mode (on|off|toggle|조회)` — `_config_ux_mode` 미러 + `--argjson` boolean
- [x] `installed.json` `directorMode` 필드 (영속화)
- [x] `/hk-director` 슬래시 커맨드 (+`.claude` 미러)
- [x] `sdd status` "Director Mode" 행 (on 시) + `sdd doctor` 진단
- [x] `tests/test-director-mode.sh` (upstream T01~T10 부분집합, fixture 기반)

### Phase 컨텍스트
- **Phase**: `phase-21` (director-mode), base branch 모드
- **본 SPEC 의 역할**: director mode 의 *사용자 진입점*. 후속 protocol(§6.8/21-03)·model config(21-04)·페르소나 패널(21-05)이 읽을 토글 + 노출 기반.

## 🎯 Key Review Points

1. **switch-only 스코프**: 행동 로직 없이 플래그+노출만. `directorMode=true` 의 동작은 의도적으로 §6.8(21-03)로 이연.
2. **jq 타입**: `ux-mode`(`--arg` 문자열)와 달리 `--argjson`(boolean). mktemp+mv atomic write, `// false` fallback.
3. **이중 미러**: `sources/bin/sdd` ↔ `.harness-kit/bin/sdd` (도그푸딩 installed 본), `sources/commands` ↔ `.claude/commands`.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-director-mode.sh
```

**결과 요약**:
- ✅ `test-director-mode.sh`: **10/10 PASS** (T01~T10)
- ✅ `test-governance-dedup.sh`: 무 NEW 회귀 (거버넌스 문서 미변경)
- ✅ Gemini cross-model 리뷰: **Approve** (Critical 0 / Major 0 / Minor 2 — 옵션, deferred)

### 수동 검증 시나리오 (스모크)
1. `sdd config director-mode on` → installed.json `directorMode=true` + `sdd status` 에 "Director Mode: on" 행
2. `sdd config director-mode toggle` 왕복 → off↔on 반전
3. 미러 parity (`diff -q`) — sdd / command 모두 동일

## 📦 Files Changed

### 🆕 New Files
- `sources/commands/hk-director.md` (+`.claude/commands/hk-director.md` 미러): `/hk-director` 토글 커맨드
- `tests/test-director-mode.sh`: 토글 스위치 검증 (T01~T10)

### 🛠 Modified Files
- `sources/bin/sdd` (+`.harness-kit/bin/sdd` 미러): `config director-mode` + `_config_director_mode()` + status/doctor 노출
- `.harness-kit/installed.json`: `directorMode` 필드
- `backlog/phase-21.md` / `backlog/queue.md`: spec-21-02 dashboard

## ✅ Definition of Done

- [x] 단위 테스트 10/10 PASS
- [x] 미러 parity (sdd / command)
- [x] 실제 동작 스모크 (installed sdd 도그푸딩)
- [x] `walkthrough.md` / `pr_description.md` ship
- [x] 코드 리뷰 (Gemini Approve)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Phase: `backlog/phase-21.md`
- Walkthrough: `specs/spec-21-02-director-mode-switch/walkthrough.md`
- 선행: spec-21-01 (context-orchestration, ADR-010) — 본 토글의 always-on 기반
- 후속: spec-21-03 (director protocol §6.8 — directorMode=true 의 행동)
- 참조: upstream spec-20-01 (director-switch)

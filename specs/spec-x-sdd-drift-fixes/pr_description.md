# fix(spec-x-sdd-drift-fixes): sdd drift 진단 두 fix bundle (dogfood-sync 감지 + ADR ../ exclude)

## 📋 Summary

### 배경 및 목적

`sdd status` 의 `🔄 동기화 상태` 섹션이 두 가지 정확도 이슈를 가졌다.

1. **dogfood-sync drift False Negative**: PR #4 작업 중 두 차례 재현된 패턴 — `sources/hooks/check-secrets.sh` 가 PR 머지 후에도 `.harness-kit/hooks/check-secrets.sh` 와 비동기 상태로 잔존. 기존 `_drift_install` 은 *untracked* 만 다루고 tracked 비동기는 검출 안 됨. → 다음 Ship 시점까지 발견 미뤄지면서 Hard Stop + 추가 chore commit 비용 발생.
2. **ADR stale-path False Positive**: `docs/decisions/ADR-003-dogfood-sync-policy.md` line 34 의 *심볼릭 링크 비채택 설명* 안의 backtick `\`../../sources/governance/agent.md\`` 가 stale로 잡혀 매 `sdd status` 호출마다 노이즈 1줄.

본 PR 은 `sources/bin/sdd` 한 파일에 두 fix 를 bundle 로 적용.

### 주요 변경 사항

- [x] `sources/bin/sdd` 의 `_drift_stale_adr` token 필터 체인에 `^\.\./` 시작 제외 1줄 추가 (가설/예시 인용 토큰 진단 제외).
- [x] `sources/bin/sdd` 에 `_drift_dogfood_sync` 함수 신규 추가 — tracked `.harness-kit/{hooks,agent/templates}/*` + `.claude/commands/*` 가 대응 `sources/{hooks,templates,commands}/*` 와 `diff -q` 로 다르면 카운트. 메시지: `도그푸딩 sync: N 파일 sources/와 비동기 — bash update.sh --yes 권장`.
- [x] `_status_drift` 호출 체인에 `_drift_dogfood_sync` 등록 (`_drift_install` 다음).
- [x] **외부 target 가드**: `_drift_dogfood_sync` 는 `sources/` 디렉토리 *존재 시에만* 동작. 외부 사용자 환경 무영향.
- [x] `tests/test-drift-stale-adr.sh` 에 Step 4 (Test D, `../` exclude) 추가 + `SDD_BIN` 을 `sources/bin/sdd` 로 변경 (`test-sdd-drift.sh` 와 일관성).
- [x] `tests/test-sdd-drift.sh` 에 T6/T7/T8 (Test A/B/C, dogfood-sync 검출) 추가.
- [x] **dogfood self-verify**: 본 PR 의 fix 가 *자기 자신의 dogfood-sync drift* 를 fix 하는 메타 구조. Task 6-0 chore commit (`b4f73ae`) 에서 update.sh 동기화 확인.

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — bundle fix)
- **본 SPEC 의 역할**: PR #3/#4 의 walkthrough 에 follow-up 후보로 기록된 두 항목을 사용자 우선순위 분석 후 bundle 진행. dogfood 환경의 ergonomic + drift 가시화 개선.

## 🎯 Key Review Points

1. **외부 target 호환** (P1) — `_drift_dogfood_sync` 는 `[ -d "$SDD_ROOT/sources" ] || return 1` 가드로 외부 사용자 환경 (sources/ 없음) 에서 호출 자체가 skip. Test 8 자동 검증.
2. **`_drift_install` 의도 보존** (P1) — install 부산물 (untracked) 과 dogfood-sync (tracked) 의 의도 분리 위해 새 함수로 분리. 기존 함수 미변경.
3. **`../` 토큰 제외 범위 최소화** — `^\.\./` 시작만 제외. 다른 false positive 패턴 (`*` glob, repo reference, anchor 등) 은 관찰되지 않은 가설로 YAGNI.
4. **bash 3.2 호환** — heredoc + while read 패턴 (기존 `_drift_install` 과 동일 기법). `declare -A` 등 bash 4+ 기능 미사용.
5. **EOL 노이즈** (Task 3 commit, `c67cbfc`) — Windows Git Bash 의 CRLF→LF 변환으로 `sources/bin/sdd` diff 가 2400줄로 표시. *실제 content 변경은 1줄*. 별 spec 후보 (`.gitattributes` 강제 LF) 로 walkthrough 이월 항목에 기록.

## 🧪 Verification

### 자동 테스트

```bash
bash tests/test-drift-stale-adr.sh
bash tests/test-sdd-drift.sh
```

**결과 요약**:
- `test-drift-stale-adr.sh`: 4/4 PASS (Step 4 신규 Test D 포함).
- `test-sdd-drift.sh`: 신규 T6/T7/T8 모두 PASS. T1 의 첫 check (`동기화 상태 섹션 누락`) 은 본 PR 변경 *이전부터* 존속하는 baseline fail — 본 PR 무관.

### 수동 검증 (dogfood self-verify)

1. Task 5 commit 직후 — `bash .harness-kit/bin/sdd status` → 옛 sdd 가 호출되어 `stale ADR: 1 (missing-path)` 줄 출력.
2. `bash update.sh --yes` + Task 6-0 chore commit (`b4f73ae`) → `.harness-kit/bin/sdd` 동기화.
3. `bash .harness-kit/bin/sdd status` 재실행 → `stale ADR` 줄 사라짐 ✓. `_drift_dogfood_sync` 도 활성화 (현재는 sync 완료 상태라 미출력).

## 📦 Files Changed

### 🛠 Modified Files

- `sources/bin/sdd` (+~30, -2): `_drift_stale_adr` 에 `../` 제외 1줄 + `_drift_dogfood_sync` 함수 신규 ~25줄 + `_status_drift` 호출 추가 1줄. **EOL 변환** 으로 git diff 가 2400줄로 표시 — 실제 변경은 위 셋만.
- `.harness-kit/bin/sdd` (+~30, -2): 위 변경의 dogfood sync 결과 (Task 6-0 chore).
- `.harness-kit/installed.json` (+1, -1): update.sh 의 timestamp 갱신.
- `tests/test-drift-stale-adr.sh` (+30, -3): SDD_BIN 변경 + Step 4 추가.
- `tests/test-sdd-drift.sh` (+60): T6/T7/T8 추가.
- `backlog/queue.md` (+1): `<!-- sdd:specx -->` 마커 자동 등록.

### 🆕 New Files

- `specs/spec-x-sdd-drift-fixes/spec.md` / `plan.md` / `task.md` / `walkthrough.md` / `pr_description.md`: SDD 산출물 (한국어).

**Total**: 11 files changed

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (본 PR 신규 4건 + 기존 회귀 가드 — baseline T1 fail 은 본 PR 무관)
- [-] 통합 테스트 — Integration Test Required = no
- [x] `walkthrough.md` ship 완료
- [x] `pr_description.md` ship 완료
- [x] lint / type check — `shellcheck` 미설치 환경 (Windows Git Bash) 으로 skip. `check-staged-lint.sh` 경고만.
- [x] 사용자 검토 요청 알림 — PR 생성 후 Telegram

## 🔗 관련 자료

- 선행 PR: `#3` (spec-x-check-secrets-env-example) — `.env.*.example` 필터 + 첫 dogfood-sync drift 발생.
- 선행 PR: `#4` (spec-x-check-secrets-docs-context) — `.md` exclude + 두 번째 dogfood-sync drift 발생 + 본 spec 의 follow-up 후보 기록.
- 관련 ADR: `docs/decisions/ADR-003-dogfood-sync-policy.md` (dogfood sync = update.sh SSOT 원칙 — 본 PR 가 이 원칙의 *가시성* 보강).
- Walkthrough: `specs/spec-x-sdd-drift-fixes/walkthrough.md`

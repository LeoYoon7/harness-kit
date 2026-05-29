# chore(spec-x-dogfood-sync): 도그푸딩 sync drift 일괄 해소 — update.sh 1회 호출 + 4 commit

## 📋 Summary

### 배경 및 목적

본 저장소(harness-kit) 는 자기 자신에게 키트를 install 해 도그푸딩 합니다 (CLAUDE.md). 그런데 `sources/` 의 변경분이 본 저장소의 `.harness-kit/`·`.claude/`·프로젝트 루트에 **자동 적용되지 않는다** 는 사실이 누적 누락으로 드러났습니다.

확인된 drift (`diff -rq`):

| 경로 | Pre | Post |
|---|---|---|
| `.harness-kit/agent/agent.md` | 442L (§7 보강·§8.5 누락) | 490L ✓ |
| `.harness-kit/CLAUDE.fragment.md` | 26L | 305L ✓ |
| `.claude/commands/hk-*.md` (15개) | 다수 다름 | 모두 sources 동기화 ✓ |
| `.harness-kit/hooks/notify-on-input-wait.sh` | 미설치 | 설치됨 ✓ |
| `.harness-kit/bin/notify{,-telegram,-discord}.sh` | 미설치 (3개) | 설치됨 ✓ |
| 프로젝트 루트 `telegram.sh`·`discord.sh` | 미설치 | 설치됨 ✓ |
| `.env.telegram.example`·`.env.discord.example` | 미생성 | 생성됨 ✓ (gitignored — 본문 §주요 변경 §5) |
| `.claude/state/current.json` | 부재 (sdd specx new 가 실패) | 존재 ✓ (gitignored, runtime state) |

### 주요 변경 사항

1. ✅ **`bash update.sh --yes` 1회 실행** — uninstall(state 보존) → install → state 복원 → doctor. 모든 sync 카테고리를 한 번에 처리. (commit `bff0c01`, +6163/-5229, 41 files)
2. ✅ **신규 `*.sh` 6개의 실행 비트 보정** — Windows MINGW `core.fileMode=false` 우회. `git update-index --chmod=+x`. (commit `59e4053`)
3. ✅ **`backlog/queue.md` Icebox 후속 항목 3건 등록** — 도그푸딩 sync 자동화 / ADR-NNN-dogfood-sync-policy 작성 / check-secrets.sh `.env.*.example` 패턴 fix. (commit `b9844f9`)
4. ✅ **spec/plan/task/critique 산출물** — Plan Accept 직후 별도 commit 으로 sync diff 와 격리. (commit `a5a55b8`)
5. ⚠ **`.env.*.example` 을 `.gitignore` 에 추가** (self-host 전용) — kit 의 `check-secrets.sh` 가 `(^|/)\.env(\..+)?$` 패턴으로 `.env.*.example` 까지 false positive 처리하는 버그 회피. install 이 매번 재생성하는 아티팩트라 추적 불필요. 근본 fix 는 후속 spec.

### 컨텍스트

- **모드**: SDD-x (Phase 비소속, 단발). PR 타깃: **fork main** (`LeoYoon7/harness-kit:main`). upstream(`Changsik00`) PR 아님.
- **critique 반영**: `/hk-spec-critique` 권장안 9개 항목 반영 (누락 1·2·3·4, 모순 6, 과잉 7, 모호 9, ADR 11, 후속 12). 거부된 대안 A/B/C/D 는 critique.md 참조.
- **실행 환경**: Windows 11 + Git Bash (MINGW64). 키트 1차 타깃은 macOS 이나 본 도그푸딩은 Windows.

## 🎯 Key Review Points

1. **`check-diff-size.sh` warn 통과 (~11000줄 diff)**: sync commit 단일 단위가 ~6000줄. `check-diff-size.sh` 가 warn 모드 (block 아님) 라 통과는 정상. 우회 환경변수 미사용. 의미 단위가 "sources@v0.13.6 적용" 하나라 분할은 인공적 (대안 A 거부 — critique 참조).

2. **실행 비트 보정 commit (`59e4053`)**: Windows MINGW 환경에서 `git add` 가 신규 `*.sh` 를 무조건 `100644` 로 기록 (`core.fileMode=false`). sources 의 동일 blob 은 `100755` 인데 install 결과는 `100644` → macOS/Linux 클론 시 실행 권한 누락 위험. `git update-index --chmod=+x` 로 6개 파일 보정. 향후 sync 작업에서도 동일 절차 필요.

3. **`.env.*.example` gitignore 결정 (self-host 한정)**: `check-secrets.sh` 의 `(^|/)\.env(\..+)?$` 가 `.example` 접미사를 구분 못 함. self-host 한정 회피 후 근본 fix 는 별도 spec. **target 프로젝트도 동일 영향 가능** — queue.md Icebox 후속 spec 우선순위.

4. **`sdd specx new` chicken-and-egg**: 본 PR 의 직접 동기 중 하나가 `.claude/state/current.json` 부재로 `sdd specx new` 가 실패하는 문제. 본 spec 부트스트랩 자체를 수동 `git checkout -b` + 수동 디렉토리 생성으로 우회. PR 머지 후 fresh-install 환경에서는 정상 작동 (Task 2 의 `sdd doctor` smoke 로 검증).

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-gitignore-idempotent.sh   # 22/22 PASS
bash tests/test-install-layout.sh         # 15/15 PASS
```

### update.sh 내장 doctor
```text
[7/7] 프로젝트 품질 도구
  ✓ Shell 프로젝트 감지 — lint/test 불필요
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PASS: 48    WARN: 1    FAIL: 0
하네스 설치 상태 양호.
```
- WARN 1: `OS = MINGW64_NT-10.0-26200 (미지원)` — 알려진 non-blocking.

### sdd doctor (smoke)
```bash
bash .harness-kit/bin/sdd doctor   # ALL PASS
```

### 수동 검증 시나리오
1. **drift 표 모든 항목 해소 확인** → `diff -rq` 빈 출력 + 미설치 파일 모두 등장 + state 파일 인식 ✓
2. **placeholder 사전 분석** → `.env.*.example` 빈 placeholder 라 시크릿 할당 패턴 (`<KEY>=<VAL>` 형태로 우변이 채워진 경우) 안 걸림. 파일명 false positive 는 `.gitignore` 로 회피 ✓
3. **chmod 보정** → 6개 sh 파일 git index `100755` 확인 ✓

## 📦 Files Changed

### 🆕 New Files (sync 본체)
- `.harness-kit/bin/notify.sh`, `notify-telegram.sh`, `notify-discord.sh`: 알림 dispatcher (+383)
- `.harness-kit/hooks/notify-on-input-wait.sh`: 입력 대기 자동 알림 hook (+121)
- `telegram.sh`, `discord.sh` (프로젝트 루트): 알림 채널 런처 (+86)

### 🆕 New Files (spec 산출물)
- `specs/spec-x-dogfood-sync/spec.md`, `plan.md`, `task.md`, `critique.md`, `walkthrough.md`, `pr_description.md`

### 🛠 Modified Files (sync 본체)
- `.harness-kit/agent/agent.md` (+48): §7 보강 + §8.5 Choice Presentation 신설
- `.harness-kit/CLAUDE.fragment.md` (+279): 선택지 규약·Telegram 알림 프로토콜 등
- `.claude/commands/hk-*.md` (15개): sources 동기화
- `.claude/settings.json`: fragment 머지 결과로 재생성 (permissions 68개, hooks 등록)
- `.harness-kit/agent/templates/*.md` (11개): 템플릿 동기화
- `.harness-kit/bin/sdd` (massive): sdd 메타 명령 갱신
- `.harness-kit/installed.json`, `harness.config.json`: 메타 갱신
- `.gitignore` (+6): `.env.*.example` self-host 회피 + 주석
- `backlog/queue.md` (+3): Icebox 후속 항목

**Total**: 4 commits, ~50 files changed, +~6500 / -~5300 (net +~1200).

## ✅ Definition of Done

- [x] `bash update.sh --yes` 실행 → exit 0
- [x] drift 표의 모든 항목 해소 (`diff -rq` 빈 출력 + 미설치 파일 모두 등장)
- [x] `sdd doctor` state 파일 인식 + ALL PASS
- [x] `.env.*.example` placeholder 가 commit 차단하지 않음 (gitignore 회피)
- [x] 회귀 테스트 22/22 + 15/15 PASS
- [x] `walkthrough.md` / `pr_description.md` 작성 및 ship commit
- [x] `backlog/queue.md` Icebox 후속 항목 3건 등록
- [ ] PR push + fork main 으로 생성 (이 PR)
- [ ] 사용자 머지

## 🔗 관련 자료

- Spec: `specs/spec-x-dogfood-sync/spec.md`
- Plan: `specs/spec-x-dogfood-sync/plan.md`
- Critique: `specs/spec-x-dogfood-sync/critique.md`
- Walkthrough: `specs/spec-x-dogfood-sync/walkthrough.md`
- ADR 후보 (머지 후): `docs/decisions/ADR-NNN-dogfood-sync-policy.md` (queue.md Icebox 등록)
- 직전 PR (sync 대상 sources 의 일부 마지막 변경분): `LeoYoon7/harness-kit#1` (spec-x-notify-channels)

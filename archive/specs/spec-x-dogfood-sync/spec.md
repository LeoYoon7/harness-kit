# spec-x-dogfood-sync: 도그푸딩 sync drift 일괄 해소

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-dogfood-sync` |
| **Phase** | (없음 — spec-x 단발) |
| **Branch** | `spec-x-dogfood-sync` |
| **상태** | Planning |
| **타입** | Chore (Dogfood Sync) |
| **Integration Test Required** | no |
| **작성일** | 2026-05-28 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

본 프로젝트(harness-kit) 는 자기 자신에게 키트를 install 해 도그푸딩하고 있습니다 (CLAUDE.md). 그런데 `sources/` 의 변경분이 본 저장소의 `.harness-kit/`·`.claude/`·프로젝트 루트에 **자동 적용되지 않는다** 는 사실이 누락 누적으로 드러났습니다.

### 문제점

확인된 drift (`diff -rq`).

| 경로 | 상태 |
|---|---|
| `sources/governance/agent.md` (490L) vs `.harness-kit/agent/agent.md` (442L) | **+48줄 누락** — §7 보강·§8.5 Choice Presentation 신설분 미반영 |
| `sources/commands/hk-ship.md` vs `.claude/commands/hk-ship.md` | 다름 |
| `sources/hooks/notify-on-input-wait.sh` | **미설치** (`.harness-kit/hooks/` 부재) |
| `sources/bin/notify.sh`·`notify-telegram.sh`·`notify-discord.sh` | **미설치 (3개)** |
| `sources/claude-fragments/CLAUDE.fragment.md` (305L) vs `.harness-kit/CLAUDE.fragment.md` (26L) | 거대 갭 (선택지 규약 등 다수 누락) |
| `sources/claude-fragments/settings.json.fragment` ↔ `.claude/settings.json` | **다름** (fragment 머지 결과로 재생성 필요) |
| `sources/root/telegram.sh`·`discord.sh` | **프로젝트 루트에 미설치** |
| `.env.telegram.example`·`.env.discord.example` | **미생성** |
| `.claude/state/current.json` | **부재** (sdd specx new 가 실패하는 직접 원인) |
| `sources/governance/constitution.md`·`align.md` ↔ 설치본 | ✅ 동일 |
| `sources/templates/` ↔ 설치본 | ✅ 동일 |

> 위 표가 본 spec 의 **DoD 판정 모집합** 이다. plan §Proposed Changes 의 모든 항목은 본 표의 부분집합 또는 mechanical 부산물 (재생성된 settings.json, gitignore 멱등 갱신 등) 이다.

영향.
1. **에이전트 거버넌스 갭**. 설치본 agent.md 에 §8.5 가 없어 본 세션의 에이전트가 대부분의 상황에서 선택지 제시 시 [Recommendation] 을 누락할 수 있음. 사용자가 모바일로 검토하는 워크플로우에 직격.
2. **방금 머지된 알림 자산 휴면**. `spec-x-notify-channels` 의 dispatcher·런처가 본 저장소엔 깔리지 않아 실제로 알림이 동작하지 않음.
3. **sdd 도구 불완전**. `sdd specx new` 가 `.claude/state/current.json` 부재로 실패. 이번 세션에서 수동 부트스트랩 우회로 진행 중.

### 해결 방안 (요약)

키트 자체 메커니즘인 `bash update.sh --yes` 를 1회 실행해 누적된 drift 를 한 번에 닫습니다. `update.sh` 는 uninstall(state 보존) → install → state 복원 → doctor 순서로 동작하며, 모든 sync 카테고리를 다룹니다. 결과 diff 를 단일 commit 으로 박고 fork main 에 PR.

### 실행 환경

- **OS**: Windows 11, **Shell**: Git Bash (MINGW64). 키트 1차 타깃은 macOS 이나 본 도그푸딩은 Windows 에서 실행됨.
- `.gitattributes` 의 `*.sh text eol=lf` 가 install 시 LF 강제 — 정상 동작하나, uninstall→install race 에서 부분 CRLF 가 끼면 한 commit 에 EOL 변경이 섞일 수 있음. commit 직전 `git diff --stat` 로 LF 단일성 확인.

## 🎯 요구사항

### Functional Requirements

1. `bash update.sh --yes` 1회 실행으로 위 drift 표의 모든 "미설치 / 다름 / 부재" 항목이 해소되어야 한다.
2. 실행 후 `diff -rq sources/governance .harness-kit/agent` 가 빈 출력이어야 한다 (templates 디렉토리 포함).
3. 실행 후 `sdd specx new <dummy-slug>` 가 성공하는 *경량 동치* 로 `sdd doctor` 가 `.claude/state/current.json` 을 인식하고 ✗ 없이 종료해야 한다 (critique 권장안 — dummy specx new 의 부수효과 청소 부담 회피).
4. 프로젝트 루트에 `telegram.sh`·`discord.sh` 가 +x 권한으로 설치되어야 한다.
5. `.env.telegram.example`·`.env.discord.example` 가 placeholder 토큰 포함해 생성되어야 한다. 실제 `.env.*` 파일은 **건드리지 않는다** (본 저장소엔 미존재 — 미생성 분기만 본 PR 에서 검증됨. "있으면 보존" 분기는 `spec-x-notify-channels` 의 uninstall.sh §2·§7 에서 이미 검증).
6. **`update.sh` 실행 중 다른 도구 호출 금지** — Claude Code 가 hook 을 trigger 하면 transient hook 부재 상태에서 fail-open. 본 spec 의 task 는 `bash update.sh --yes` 호출 동안 어떤 Bash/Edit/Write 호출도 직렬 후순위로 두어야 한다.
7. **`.env.*.example` placeholder 가 `check-secrets.sh` 패턴에 false positive 로 걸리지 않음을 commit 직전 검증** — `bash .harness-kit/hooks/check-secrets.sh` 를 placeholder 파일에 대해 dry-run 으로 한 번 호출하여 0 또는 warn 종료 확인.

### Non-Functional Requirements

1. `update.sh` 의 state 보존 로직은 정상 동작해야 한다. **본 PR 실행 시점에 `.claude/state/current.json` 은 부재 — fresh install 분기로 진행한다.** 본 spec 작성 중에는 임시 state 를 생성하지 않으며, 부트스트랩은 install.sh 의 기본 초기값에 위임한다.
2. 본 저장소의 `.gitignore` 에 `.env.telegram`·`.env.discord` 항목이 멱등으로 들어가야 한다 (`spec-x-notify-channels` 의 install 로직).
3. **`check-diff-size.sh` 는 warn 모드** (기본값 500줄 임계치). 본 PR 의 단일 sync commit 은 ~1500줄 예상으로 임계치 초과. warn 통과는 정상 — PR 본문에 "예상된 노이즈" 로 명시한다. 환경변수로 우회하지 않는다.

## 🚫 Out of Scope

- **재발 방지 메커니즘** (post-merge auto-update / `sdd doctor` 의 sources vs installed drift 경고 등) — 별도 spec/phase 로 분리. 본 PR Ship 단계에서 walkthrough ideabox 한 줄에 더해 `backlog/queue.md` Icebox 에 *즉시* 항목 등록 (단순 캡처보다 강한 후속 보장).
- **sources 자체 수정** — 본 PR 은 sources 를 그대로 두고 *적용*만 한다.
- **upstream(Changsik00) 동기화** — 본 PR 은 fork(LeoYoon7) main 만 대상.

## 📑 ADR 후보

- [x] **ADR 가치 있는 결정 있음** → 후보: `dogfood-sync-policy` (type: **convention**)
  - **결정 요지**: 본 저장소(harness-kit self-host) 에서 sources → installed 동기화는 *키트 자체 `update.sh`* 가 SSOT. 수동 `cp` / symlink / 직접 편집 금지.
  - **함께 박을 부정 결정**: self-hosting 에 link(symlink) 모델 도입 거부 — 도그푸딩의 의미(외부 프로젝트와 동일한 install 모델) 보존.
  - **Constraints 흡수**: critique 의 `drift-visibility-deferred` (tradeoff) — drift 가시화를 본 sync PR 에서 의도적으로 분리한 이유 (PR 부풀림 방지) 를 같은 ADR Constraints 섹션에 한 줄로 기록.
  - **작성 시점**: 본 PR 머지 직후. `backlog/queue.md` Icebox 에 후속 항목으로 등록 (Ship task 에서 처리).

## 🔍 Critique 결과 (요약)

- 전체 결과: `specs/spec-x-dogfood-sync/critique.md`
- 권장안: 현재 spec 유지 + 4개 보완. 본 spec 은 권장안 9개 항목 반영본.
- 거부된 대안: A (카테고리 분할 commit — 인공적), B (재발 방지 동일 PR 포함 — 범위 부풀림), C (FF 강등 — 매몰비용), D (link 모델 — 도그푸딩 의미 상실).

## ✅ Definition of Done

- [ ] `bash update.sh --yes` 실행 → 정상 종료 (exit 0)
- [ ] drift 표의 모든 항목 해소 확인 (`diff -rq` 빈 출력 / 미설치 파일 모두 등장)
- [ ] `sdd doctor` 가 state 파일 인식 + ✗ 없음
- [ ] `.env.*.example` placeholder 가 `check-secrets.sh` false positive 안 걸림 검증
- [ ] `walkthrough.md` / `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-dogfood-sync` 브랜치 push 완료
- [ ] **PR 생성**: base=`LeoYoon7/harness-kit:main`, head=`LeoYoon7:spec-x-dogfood-sync` 명시. `/hk-pr-gh` 호출 시 base/head 확인 블록에서 fork PR 인지 검증.
- [ ] `backlog/queue.md` Icebox 에 후속 항목 등록 (도그푸딩 sync 자동화 + ADR-NNN-dogfood-sync-policy 작성)

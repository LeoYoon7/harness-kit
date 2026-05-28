# Implementation Plan: spec-x-dogfood-sync

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-dogfood-sync` (이미 생성됨 — sdd specx new 가 state 부재로 실패하여 수동 `git checkout -b` 로 부트스트랩)
- 시작 지점: `main` (= `f80091a chore: mark spec-x-notify-channels done in queue`)
- **Plan Accept 직후 첫 Task 는 spec 산출물(spec/plan/task/critique) commit 분리** — sync diff 와 spec 작성 diff 가 한 commit 에 섞이지 않도록 격리 (critique 누락 #5 반영).

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] `update.sh` 가 본 저장소의 `.harness-kit/`·`.claude/`·프로젝트 루트를 대상으로 destructive 갱신을 수행 (uninstall → install). state 보존 로직이 있으나 본 저장소엔 보존할 state 가 없음 — **fresh install 분기로 단정**.
> - [ ] 결과 diff 가 다수 파일·~1500줄 예상 — `check-diff-size.sh` warn 통과 (block 아님). PR 본문에 노이즈 기록.

> [!WARNING]
> - [ ] `bash update.sh --yes` 실행 동안 **다른 도구 호출 금지** (Bash/Edit/Write/MultiEdit). hook 재설치 transient 상태에서 fail-open 회피.
> - [ ] commit 직전 `.env.*.example` placeholder 의 `check-secrets.sh` false positive 검증 필수.
> - [ ] PR 생성 시 base/head 가 fork 인지 명시적 확인 (upstream 오송신 방지).

## 🎯 핵심 전략 (Core Strategy)

### 아키텍처 컨텍스트

```
sources/  ──(update.sh)──▶  .harness-kit/  (governance·hooks·bin·templates·CLAUDE.fragment)
                            .claude/       (commands·settings.json·state)
                            ./             (telegram.sh, discord.sh, .env.*.example, .gitattributes, .gitignore)

update.sh = uninstall(--keep-state) → install → state restore → doctor
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **실행 방식** | `bash update.sh --yes` 1회 호출 | 키트 자체 메커니즘. 수동 선별 복사 대비 누락 없음. (critique 대안 A 거부) |
| **commit 분리** | spec 산출물 commit → sync commit → icebox commit → ship commit (총 4개) | spec 작성 / sync / 후속 캡처 / 산출물 ship 의 의미가 분리됨. one task = one commit. |
| **smoke 검증** | `sdd doctor` 로 state 인식 확인 (dummy specx new 미사용) | dummy 의 부수효과 청소 부담이 `Integration Test Required: no` 와 일관성 깨뜨림 (critique 과잉설계 반영). |
| **회귀 테스트** | `test-gitignore-idempotent.sh` + `test-install-layout.sh` 만 실행. 키트 코드 변경 없음 (sources 그대로) — 회귀 유발 가능성 0 의 추가 보증. | belt-and-suspenders. 5초 안에 끝남. |
| **재발 방지** | `backlog/queue.md` Icebox 에 즉시 항목 등록 (walkthrough 캡처보다 강한 후속 보장) | critique 의 후속 작업 보장 강화. 동일 PR 포함은 거부 (대안 B). |
| **diff-size 노이즈** | warn 통과 / 우회 환경변수 미사용 / PR 본문에 기록 | hook 강제 우회는 antipattern. warn 은 정상 동작. |

### 📑 ADR 후보

- [x] **ADR 가치 있는 결정 있음** → `dogfood-sync-policy` (type: **convention**) — sources → installed SSOT = `update.sh`, link 모델 거부, drift-visibility-deferred 흡수.
- **작성 시점**: 본 PR 머지 직후. Ship task 에서 `backlog/queue.md` Icebox 등록.

## 📂 Proposed Changes

### 도그푸딩 install 자산 (예상 변경 범위 — `update.sh` 가 자동 처리)

#### [MODIFY] `.harness-kit/agent/agent.md`
sources 의 490 줄 버전으로 동기화. §7 Hard Stop 보강(`An unplanned decision is required` 항목·§8.5 reference), §8.5 Choice Presentation Protocol 신설 포함.

#### [MODIFY] `.harness-kit/CLAUDE.fragment.md`
sources 의 305 줄 버전으로 동기화. 선택지 규약·검증된 패턴 섹션 포함.

#### [MODIFY] `.claude/commands/hk-ship.md`
sources 와 동기화.

#### [NEW] `.harness-kit/hooks/notify-on-input-wait.sh`
`spec-x-notify-channels` 의 입력 대기 hook (실제 알림 동작에 필요).

#### [NEW] `.harness-kit/bin/notify.sh`·`notify-telegram.sh`·`notify-discord.sh`
알림 dispatcher.

#### [NEW] `telegram.sh`·`discord.sh` (프로젝트 루트)
알림 채널 런처. `*.sh text eol=lf` 적용.

#### [NEW] `.env.telegram.example`·`.env.discord.example` (프로젝트 루트)
placeholder 토큰 템플릿 (실제 `.env.*` 는 미생성).

#### [NEW] `.claude/state/current.json`
sdd 상태 파일 초기 부트스트랩 — install.sh 의 fresh 초기값 그대로 (본 spec 은 별도 지정 없음).

#### [MODIFY] `.gitignore`
harness 블록에 `.env.telegram`·`.env.discord` 추가 (멱등). update.sh 의 멱등 로직이 처리.

#### [MODIFY] `.claude/settings.json`
sources fragment 와 user customization 의 머지 결과로 재생성.

> 위 목록은 `update.sh` 실행 결과의 **예측**. 실행 후 `git diff --stat` 으로 실제 변경을 확정하고 spec drift 표 (DoD 판정 모집합) 와 일치 확인.

## 🧪 검증 계획 (Verification Plan)

### 사전 검증 (update.sh 호출 직전)

```bash
# install.sh 의 매핑 (sources/* → installed) 이 spec drift 표와 일치하는지 확인
grep -E "^(install_|cp_|copy_)" install.sh | head -30
# baseline drift 캡처
diff -rq sources/governance .harness-kit/agent
diff -rq sources/templates .harness-kit/agent/templates
```

### 사후 검증 (update.sh 종료 후)

```bash
# 1:1 비교 — install.sh 가 sources/governance/{constitution,agent,align}.md → .harness-kit/agent/ 로 옮기는 매핑 기준
diff -rq sources/governance .harness-kit/agent | grep -v "Only in .*/templates"  # templates 는 별도
diff -rq sources/templates .harness-kit/agent/templates
# 신규 파일 등장 확인
ls .harness-kit/hooks/notify-on-input-wait.sh
ls .harness-kit/bin/notify.sh .harness-kit/bin/notify-telegram.sh .harness-kit/bin/notify-discord.sh
ls telegram.sh discord.sh .env.telegram.example .env.discord.example
ls .claude/state/current.json
# placeholder secret false positive 검증
bash .harness-kit/hooks/check-secrets.sh < /dev/null  # 또는 dry-run 적용 — install 직후 모드 확인
# smoke
bash .harness-kit/bin/sdd doctor
```

### 회귀 테스트

```bash
bash tests/test-gitignore-idempotent.sh   # 22/22 PASS 기대
bash tests/test-install-layout.sh         # 15/15 PASS 기대
```

> 본 PR 은 sources 미수정 → 회귀 유발 가능성 0. 위 2개는 추가 보증 (실행 5초 내).

## 🔁 Rollback Plan

- `update.sh` 가 백업 디렉토리를 만들고 doctor 까지 통과해야 종료. 중간 실패 시 백업에서 복구 가능 (update.sh 내장).
- 결과가 깨지면 본 브랜치 폐기 + main 으로 복귀 (`git reset --hard` 는 deny — `git checkout main && git branch -D spec-x-dogfood-sync`).

## 📦 Deliverables 체크

- [x] spec.md 작성 (critique 반영본)
- [x] plan.md 작성 (critique 반영본)
- [x] critique.md 작성
- [ ] task.md 작성 (다음 단계 — critique 반영본)
- [ ] 사용자 Plan Accept
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship
- [ ] (실행 후) backlog/queue.md Icebox 항목 등록

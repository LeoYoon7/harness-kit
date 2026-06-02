# Walkthrough: spec-x-native-session-feature-verify

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 검증 방법론 | 라이브 실측 / 문서+정적 분석 | **문서+정적 분석** | 본 에이전트는 백그라운드 잡 — `/background`·`/branch` 라이브 자가 실행 불가. 문서·hook 배선으로 판정 가능 + 자율 완료 보장. 라이브는 선택적 사용자 체크리스트로 분리 |
| bg 격리 가드 vs SDD 브랜치 | EnterWorktree / `bgIsolation:none` 로컬 설정 | **`bgIsolation:none`** | 키트는 macOS 단일 체크아웃 + SDD 브랜치 격리 모델. worktree 는 `sdd`/hook 과 미검증. `.claude/settings.local.json`(gitignore)에 적용 — 가역적. 이 충돌 자체가 §2.4 발견의 근거 |
| `/background` 판정 | 보류 유지 / 조건부 Go(제한) | **조건부 Go(제한)** | 계층 1 자동 알림만 미확정. 계층 2 명시 알림 + 게이트-free 구간 한정으로 리스크 한정 → 완전 보류는 과함 |
| `/branch` 판정 | 보류 유지 / 조건부 Go | **조건부 Go** | settings(hook)·CLAUDE.md·모델·git 상태 승계 + 같은 working dir → 게이트 보존 doc-확정 |
| 정책 반영 위치 | agent.md 본문 / ADR+포인터 | **ADR+포인터** | 거버넌스 단어 수 한계(이미 초과). 상세는 ADR-007 Amendment, agent.md §6.7 엔 요지 한 절. prior spec(native-feature-adoption-policy) 선례 답습 |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: 신규 ADR 아님. 기존 `docs/decisions/ADR-007-native-feature-adoption-policy.md` 에 Amendment 절 추가 (세션 기능 2종 조건부 Go 승격)
- [ ] 없음

## 💬 사용자 협의

- **주제**: 후속작업 선택 (이전 세션 = CC 네이티브 채택)
  - **사용자 의견**: A (`spec-x-native-session-feature-verify` 검증 spec — report §7-3)
  - **합의**: SDD-x, Research 성격으로 진행
- **주제**: Plan Accept 게이트
  - **사용자 의견**: 1 (Plan Accept)
  - **합의**: Strict Loop 진입

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: 해당 없음 — Research/docs spec (production 코드 변경 없음, constitution §9.1 justified)

#### 거버넌스 정합성 테스트 (정책 편집분 회귀 확인)
- **명령**: `bash tests/test-governance-dedup.sh`
- **결과**: ❌ 1/8 FAIL (Check 3 단어 수) — 단, **본 spec 이 깨뜨린 회귀 아님**
- **로그 요약**:
```text
Check 2: sources ↔ .harness-kit 동기화  ✅ agent.md / constitution.md 동기화 OK
Check 3: 단어 수  constitution 2672 + agent.md 4349 = 7021w  ❌ > 상한 6000w
  (본 spec 전 6994w 로 이미 초과. 본 spec +27w — 정책 필수 최소)
Check 1·4·5·6: ✅ PASS
```

### 2. 수동 검증

1. **Action**: claude-code-guide 서브에이전트 + 공식 문서로 `/background`·`/branch` 동작 조사
   - **Result**: `/branch` 의 settings/CLAUDE.md/모델/git 상태 승계 확정. `/background` 의 계층 1 hook 발화는 문서 미명시(라이브 필요). worktree 격리 사실 확인(§2.4 근거)
2. **Action**: `settings.json` hook 등록 + `notify-on-input-wait.sh` 정적 분석
   - **Result**: `notify-on-input-wait.sh` 가 `Notification`·`Stop` 양쪽 등록. git hook 은 `PreToolUse`. 배선 확인 → 판정 근거
3. **Action**: ADR-007 Amendment + agent.md §6.7(양쪽) + queue.md Icebox 편집 후 `test-governance-dedup.sh`
   - **Result**: Check 2(동기화) PASS — sources↔.harness-kit 정합

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **결과 파일** | N/A |
| **요약** | N/A |
| **Skip 사유** | `docs-only` — report + 거버넌스 문서(ADR Amendment + agent.md 요지) + queue 만, 실행 코드 변경 없음 (agent.md §6.3.8) |

## 🔍 발견 사항

- **CC 의 병렬/백그라운드 세션 격리 = git worktree** (공식 문서). 본 spec 작업 중 부딪힌 bg-isolation 가드의 정체이자, harness-kit 의 SDD 단일 체크아웃 브랜치 모델과의 상호작용 지점(§2.4). `/background` 도입 시 worktree 격리가 기본 작동.
- **계층 1(자동 hook) vs 계층 2(명시 notify.sh)의 비대칭 견고성**: 계층 2 는 단순 Bash 라 백그라운드에서도 동작 확정. 불확실한 건 계층 1 뿐 → "게이트-free 구간 한정 + 계층 2 필수"로 리스크 한정 가능.
- **`CLAUDE_CODE_FORK_SUBAGENT=1`** 은 `/fork` 를 백그라운드 subagent 로 전환 → `/branch` 가 아니라 `/background` 조건을 상속. 두 기능이 이 변수로 연결됨.

## 🚧 이월 항목

- **거버넌스 다이어트** (7021w vs 6000w 한도) → `backlog/queue.md` Icebox 기존 항목. 본 spec +27w 는 정책 필수 최소이며 FAIL 본질은 기존 비대화. 별도 spec 필요 (constitution §9.1 justified skip).
- **라이브 확인 (report §6 체크리스트)** — `/background` 계층 1 알림(test 1) 등은 사용자 라이브 세션에서 1회 확인 시 조건 완화 가능. Done 조건 아님. 알림 누락 반복 관측 시 RCA 후보.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-02 ~ 2026-06-02 |
| **최종 commit** | ship commit (push 직전) |

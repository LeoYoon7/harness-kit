# Walkthrough: spec-x-dogfood-sync

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 누적된 drift 의 닫는 방식 | A) `update.sh` 1회 / B) 카테고리별 분할 commit / C) 본 PR 에 재발 방지 메커니즘 포함 / D) FF 강등 / E) link 모델 | **A** | 키트 자체 메커니즘 SSOT — 수동 선별 복사 대비 누락 없음. critique 권장안. |
| `.env.*.example` placeholder 가 `check-secrets.sh` false positive 로 commit 차단 가능성 | a) `.gitignore` 추가 / b) `check-secrets.sh` 패턴 fix / c) `--no-verify` 우회 | **a** + 후속 **b** | 본 PR 범위(self-host sync) 내에선 a 로 회피. b 는 `queue.md` Icebox 등록 (다른 target 프로젝트에도 영향). c 는 antipattern 거부. |
| 신규 `*.sh` 6개가 Windows MINGW `core.fileMode=false` 로 `100644` commit | a) `git update-index --chmod=+x` 별도 commit / b) sync commit amend | **a** | CLAUDE.md "amend 보다 새 commit" 지침. 발견·수정 과정의 정직한 history. |
| task.md 의 in-progress 갱신 commit 분리 여부 | a) 매 task 후 별도 commit (prior repo 패턴) / b) Ship 직전 일괄 commit | **b** | task.md = 진행 기록의 메타. spec 4 commit 구조에 추가 noise 누적 방지. Ship 시 `task.md 모든 체크박스 확인` 단계와 자연 결합. |
| sync commit 크기 ~6000줄 → `check-diff-size.sh` 임계치 초과 | a) 환경변수 우회 / b) warn 통과 + PR 본문에 기록 | **b** | hook 의 warn 모드는 정상 동작. 우회는 antipattern. PR 본문에 "예상 노이즈" 로 정당화. |

### ADR 승격 가이드

- [x] **ADR 승격 대상 있음** → 후보: `ADR-NNN-dogfood-sync-policy` (type: **convention**) — 본 PR 머지 직후 작성 (queue.md Icebox 등록 완료).
  - 결정: 본 저장소(self-host) 의 sources → installed 동기화는 *키트 자체 `update.sh`* 가 SSOT. 수동 cp / symlink / 직접 편집 금지.
  - 부정 결정 함께 박음: link(symlink) 모델 도입 거부 — 도그푸딩의 의미(외부 프로젝트와 동일 install 모델) 보존.
  - Constraints 흡수: critique 의 `drift-visibility-deferred` (tradeoff) — drift 가시화를 본 PR 에서 의도적으로 분리한 이유를 한 줄로 기록.

## 💬 사용자 협의

- **주제**: 드러난 drift 해소 방식 선택
  - **사용자 의견**: "설치 파일 수정내용이 정작 본 프로젝트에는 적용 안됨" → 4개 옵션 제시 (spec-x sync / FF / 선별 복사 / 재발 방지 포함) 후 spec-x 선택.
  - **합의**: spec-x 로 진행, 재발 방지는 별도 작업으로 분리.

- **주제**: critique 권장안 반영 범위
  - **사용자 의견**: "권장안대로 진행".
  - **합의**: 권장된 9개 항목 반영 (1, 2, 3, 4, 6, 7, 9, 11, 12). 선택 항목(5, 8, 10) 은 다음 sync 작업으로 미룸.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 회귀 테스트
- **명령**: `bash tests/test-gitignore-idempotent.sh && bash tests/test-install-layout.sh`
- **결과**: ✅ **22/22 + 15/15 PASS**

```text
test-gitignore-idempotent.sh:
  ▶ A~H 8개 시나리오 — 멱등성 검증
  ═══════════════════════════════════════════
   ✅ ALL 22 CHECKS PASSED

test-install-layout.sh:
  ▶ Check 1~8 — 디렉토리 / 파일 / 템플릿 / .gitignore 검증
  ═══════════════════════════════════════════
   ✅ ALL PASS (15/15)
```

#### doctor (update.sh 내장)
- **명령**: `bash update.sh --yes` 의 마지막 단계 `doctor` 호출
- **결과**: **PASS 48 / WARN 1 / FAIL 0**
- **WARN 1 건**: `OS = MINGW64_NT-10.0-26200 (미지원)` — 알려진 non-blocking (키트 1차 타깃 macOS, 본 도그푸딩은 Windows 에서 실행).

#### sdd doctor (smoke)
- **명령**: `bash .harness-kit/bin/sdd doctor`
- **결과**: ✅ **ALL PASS** (필수 도구 + 설치 파일 + 훅 권한 모두 ✅, `.claude/state/current.json` 인식 OK)

### 2. 수동 검증

1. **Action**: `diff -rq sources/governance .harness-kit/agent`
   - **Pre-update.sh Result**: `agent.md` 만 differ (+ templates 별도 디렉토리)
   - **Post-update.sh Result**: `Only in .harness-kit/agent: templates` (templates 는 install.sh 의 의도된 매핑) — agent.md 동기화 ✓

2. **Action**: `diff -rq sources/templates .harness-kit/agent/templates`
   - **Result**: 빈 출력 — 동기화 ✓

3. **Action**: 신규 파일 9개 존재 + 실행 권한 확인
   - **Result**: 6 sh 파일 (notify dispatcher 4 + 루트 런처 2) 모두 디스크 `rwx`, git index `100755` (chmod 보정 후). `.env.*.example` 2 + `.claude/state/current.json` 1 디스크에 존재.

4. **Action**: placeholder secret false positive 사전 분석
   - **Result**: `.env.*.example` 의 값(BOT_TOKEN, CHAT_ID) 은 빈 placeholder 라 시크릿 할당 패턴 (`<KEY>=<VAL>` 형태로 우변이 채워진 경우) 안 걸림. 그러나 *파일명* 자체가 `(^|/)\.env(\..+)?$` 에 매칭 → `.gitignore` 추가로 회피, 후속 fix queue.md Icebox 등록.

## 🔍 발견 사항

1. **Windows MINGW `core.fileMode=false` 의 실행 비트 누락** — `git add` 가 새 파일을 무조건 `100644` 로 기록. macOS/Linux 클론 시 기능 깨짐 위험. 본 PR 에서는 `git update-index --chmod=+x` 로 보정한 별도 commit (`59e4053`) 추가. 향후 sync 작업에서 신규 sh 파일이 생기면 동일 절차 필요.

2. **`check-secrets.sh` `.env.*.example` false positive** — critique 가 예측한 정확한 시나리오 발생. 본 PR self-host 한정 회피했으나 *target 프로젝트도 동일 영향*. queue.md Icebox 후속 (`check-secrets.sh .env.*.example 패턴 제외 fix`).

3. **`sdd specx new` state 의존성** — `.claude/state/current.json` 부재 시 spec-x 부트스트랩 자체가 깨짐. 본 PR 작업이 그 의존성을 닫는 동안 *수동 `git checkout -b` + 수동 spec 디렉토리 생성* 으로 chicken-and-egg 우회. 향후 fresh-install 환경에서도 동일 패턴 발생 가능.

4. **install.sh self-host 분기 감지 정확** — `.harness-kit/` 가 이미 git 추적 중이면 `.gitignore` 에 추가 건너뜀. self-host 모드에서 `.harness-kit/*` 변경이 PR diff 로 노출되어 리뷰 가능 — 도그푸딩 의도와 일치.

## 🚧 이월 항목

- **도그푸딩 sync 자동화** — drift 가시화 메커니즘 (sdd doctor / CI check / post-merge auto-update). 본 사건의 근본 원인 → `backlog/queue.md` Icebox 등록 (commit `b9844f9`).
- **ADR-NNN-dogfood-sync-policy 작성** (convention) — 본 PR 머지 직후 → `backlog/queue.md` Icebox 등록.
- **`check-secrets.sh` `.env.*.example` 패턴 제외 fix** — target 프로젝트 영향 → `backlog/queue.md` Icebox 등록.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7) + Leo |
| **작성 기간** | 2026-05-28 |
| **최종 commit** | `b9844f9` (icebox) — Ship commit 직전 |
| **Branch** | `spec-x-dogfood-sync` |
| **PR 대상** | `LeoYoon7/harness-kit:main` (fork main) |

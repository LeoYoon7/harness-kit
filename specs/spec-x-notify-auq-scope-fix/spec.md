# spec-x-notify-auq-scope-fix: notify hook 의 AskUserQuestion 추출 scope 좁히기 (stale AUQ false positive 제거)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-notify-auq-scope-fix` |
| **Phase** | (없음 — Solo Spec) |
| **Branch** | `spec-x-notify-auq-scope-fix` |
| **상태** | Planning |
| **타입** | Fix (PR #8 regression) |
| **Integration Test Required** | no |
| **작성일** | 2026-05-28 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

PR #8 (`spec-x-notify-choice-context`) 가 `sources/hooks/notify-on-input-wait.sh` 의 본문 분기 (a)/(b)/(c) 를 정교화. (c) AskUserQuestion 분기는 다음 jq 쿼리로 추출:

```bash
AUQ_JSON=$(tail -100 "$TRANSCRIPT" 2>/dev/null | \
    jq -rs '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and .name == "AskUserQuestion")] | last // empty' 2>/dev/null || echo "")
```

이 쿼리는 *tail -100 transcript 의 모든 assistant turn 에서* AskUserQuestion tool_use 를 flatten 한 뒤 마지막 1개를 선택.

### 문제점

**현재 trigger 와 무관한 stale AskUserQuestion 이 (c) 분기로 잘못 선택됨**.

실증 사례 (2026-05-28, 사용자 보고 + 스크린샷, Telegram msg #3066):

1. PR #8 머지 직후, 사용자 응답에 따라 에이전트가 *post-merge 처리* 진행
2. 처리 중 `Bash` 도구 권한 요청 (예: `sdd specx done`, `git push`) 다이얼로그가 발화 → `Notification` 이벤트
3. hook 가 발화하여 jq 쿼리 실행 → `tail -100` 안에 *Ship pre-flight 시점의 AskUserQuestion* (옵션: Gemini / Opus / Skip) 가 *여전히 존재*
4. `[...]| last` 가 그 AskUserQuestion 을 선택 → ASK_USER_Q_BODY 생성 → (c) 분기로 잘못 라우팅
5. 결과: 사용자 모바일에 `사용자 질문 대기 / [질문 1개] / 1. [리뷰 게이트] Ship 직전 코드 리뷰 옵션 — 어떤 리뷰로 진행할까요? / 옵션: Gemini ... / Skip` 알림 — **현재 trigger 와 완전히 무관한 stale 콘텐츠**

이는 PR #8 의 Critique (`specs/spec-x-notify-choice-context/critique.md` §2 모호함) 가 지적한 "직전 에이전트 발화" 정의 모호성의 실증 사례.

### 해결 방안 (요약)

jq 쿼리 scope 를 *tail -100 전체* → *마지막 assistant turn 안* 으로 좁힘. 마지막 turn 에 AskUserQuestion tool_use 가 *있는 경우만* (c) 분기 작동.

```jq
# Before (bug)
[.[] | select(.type == "assistant") | .message.content[]? | select(.type=="tool_use" and .name=="AskUserQuestion")] | last // empty

# After (fix)
[.[] | select(.type == "assistant")] | last // null | .message.content | map(select(.type=="tool_use" and .name=="AskUserQuestion")) | .[0] // empty
```

## 🎯 요구사항

### Functional Requirements

1. **jq 쿼리 scope 좁힘** — `sources/hooks/notify-on-input-wait.sh` 의 AUQ_JSON 추출 쿼리를 위 "After" 형태로 교체.
2. **도그푸딩 sync** — `.harness-kit/hooks/notify-on-input-wait.sh` 도 같이 갱신.
3. **신규 smoke test 케이스 (FP-stale)** — transcript 에 old AUQ tool_use entry + 새로운 assistant text-only entry → trigger 시 (a)/(b)/일반 으로 분기되어야 (c) 가 아니어야 함.

### Non-Functional Requirements

1. **bash 3.2+ 호환** 유지.
2. **jq 의존성 유지**.
3. **기존 (a)/(b)/(c) 본문 분기 형태 무변경** — 본 fix 는 *(c) 진입 조건* 만 좁힘.
4. **PR #8 의 4 케이스 smoke test 모두 회귀 PASS** — (a)/(b)/(c)/(FP 기존) 가 여전히 정상.

## 🚫 Out of Scope

- (b) 텍스트 선택지 분기의 scope 변경 — 이미 마지막 assistant text turn 기준이라 영향 없음.
- 사용자 응답 직후 fast follow-up AskUserQuestion 의 정밀 추적 — 안 2 (마지막 2 turn) 는 보수적 안 1 선택으로 제외 (Out-of-Scope 명시).
- AskUserQuestion 의 tool_result 까지 transcript 분석 — 본 spec 은 tool_use 발견까지만.
- 외부 도구 (claude_nextmarket 같은 3rd party bot) 의 permission UI 개선 — 본 키트 영역 외.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — PR #8 의 ADR-004 가 컨벤션 정의. 본 fix 는 그 컨벤션 구현 보강이라 별도 ADR 가치 낮음.

## 🔍 Critique 결과 (선택)

미실행 — fix 가 명확하고 단순 (jq 쿼리 한 곳 변경 + smoke test 1 케이스 추가).

## ✅ Definition of Done

- [ ] `sources/hooks/notify-on-input-wait.sh` 의 AUQ_JSON 쿼리 scope 좁힘
- [ ] `.harness-kit/hooks/notify-on-input-wait.sh` 도그푸딩 sync
- [ ] 신규 smoke test (FP-stale) 케이스 PASS
- [ ] 회귀 smoke test — (a)/(b)/(c)/(FP 기존) 모두 PASS
- [ ] `walkthrough.md` + `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-notify-auq-scope-fix` 브랜치 push 완료
- [ ] PR 생성 + 사용자 알림 완료

# fix(spec-x-notify-auq-scope-fix): notify hook AskUserQuestion 추출 scope 좁힘 (PR #8 regression)

## 📋 Summary

### 배경 및 목적

PR #8 (`spec-x-notify-choice-context`) 직후 사용자가 라이브 버그 보고 (스크린샷 + Telegram msg #3066):

> "bash퍼미션 요청 아래의 메시지를 보라구 퍼미션 요청과 관련된 메시지가 아니라 직전 스샷과 동일 내용이잖아"

상황: Bash 권한 요청에 대해 hook 이 알림 발송했는데, 본문이 *이전 turn 의 AskUserQuestion* (Ship pre-flight 의 "Gemini / Opus / Skip") 내용이었음. 현재 trigger 와 무관한 stale 콘텐츠.

근본 원인: PR #8 의 jq 쿼리가 `tail -100 transcript` *전체* 에서 마지막 AskUserQuestion 을 추출. 시간상 오래된 AUQ entry 가 잡혀 (c) 분기로 잘못 선택됨.

```jq
# Before (bug)
[.[] | select(.type == "assistant") | .message.content[]? | select(.type=="tool_use" and .name=="AskUserQuestion")] | last

# After (fix)
[.[] | select(.type == "assistant")] | last // null |
if . == null then empty
else (.message.content // []) | map(select(.type=="tool_use" and .name=="AskUserQuestion")) | .[0] // empty
end
```

핵심: *마지막 assistant turn* 을 선택한 후 *그 turn 안의* AUQ tool_use 만 검색. 마지막 turn 이 Bash tool_use 라면 AUQ 없음 → (c) 미선택 → 정확한 분기.

### 주요 변경 사항

- [x] `sources/hooks/notify-on-input-wait.sh` (+6, -2): AUQ_JSON jq 쿼리 scope 좁힘
- [x] `.harness-kit/hooks/notify-on-input-wait.sh` (+6, -2): 도그푸딩 sync
- [x] Smoke test 5 케이스 PASS — 신규 (FP-stale) + 회귀 (a)/(b)/(c)/(FP)

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — Solo Spec)
- **본 SPEC 의 역할**: PR #8 의 라이브 regression fix

## 🎯 Key Review Points

1. **jq scope 변경**: `tail -100` 전체 → 마지막 assistant turn 만. fast follow-up 시나리오는 의도적 Out-of-Scope (마지막 turn 1개 안에 AUQ 있어야 (c)).
2. **null 안전**: assistant turn 0개 시 `last // null` → if/else 로 empty 반환. jq error 미발생.
3. **회귀 영향 0**: PR #8 의 (a)/(b)/(c)/(FP) 4 케이스 모두 동작 무변경 — smoke test 로 입증.
4. **Critique 가설 실증**: PR #8 critique.md §2 모호함의 "직전 에이전트 발화 정의 모호" 가 실제 발생한 결함. Critique 권장사항은 모두 반영하는 것이 안전하다는 데이터 점.

## 🧪 Verification

### 수동 검증 시나리오 (5 케이스 모두 PASS)

| 케이스 | 입력 | 출력 시작 | 결과 |
|---|---|---|---|
| **(FP-stale) 신규** | AUQ → user response → assistant text + Bash tool_use, hook trigger = Bash 권한 | `"권한 승인 대기"` | ✓ PASS — 이전 AUQ 가 (c) 로 잘못 선택되지 않음 |
| **(a) 회귀** | 평범한 text + 권한 메시지 | `"권한 승인 대기"` | ✓ PASS |
| **(b) 회귀** | `[선택지]` + `[권장]` 마지막 5줄 | `"사용자 선택 대기"` + transcript | ✓ PASS |
| **(c) 회귀** | AUQ x2 questions (마지막 turn 안) | `"사용자 질문 대기"` + 질문/옵션 | ✓ PASS |
| **(FP) 회귀** | 회고 `1) 2) 3)` 텍스트 | `"사용자 입력 대기 중"` 일반 | ✓ PASS |

## 📦 Files Changed

### 🛠 Modified Files

- `sources/hooks/notify-on-input-wait.sh` (+6, -2): AUQ_JSON 쿼리 scope 좁힘
- `.harness-kit/hooks/notify-on-input-wait.sh` (+6, -2): 도그푸딩 sync
- `backlog/queue.md` (+1): spec-x 등록 + Icebox 항목 (Telegram ack 중복) 추가

### 🆕 New Files

- `specs/spec-x-notify-auq-scope-fix/{spec,plan,task,walkthrough,pr_description}.md`

## ✅ Definition of Done

- [x] hook 의 AUQ_JSON 쿼리 scope 좁힘 (마지막 assistant turn 만)
- [x] 도그푸딩 sync
- [x] 신규 smoke test (FP-stale) PASS
- [x] 회귀 smoke test 4 케이스 모두 PASS
- [x] walkthrough + pr_description ship commit
- [x] (예정) push + PR 생성 + 사용자 알림

## 🔗 관련 자료

- Spec: `specs/spec-x-notify-auq-scope-fix/spec.md`
- Plan: `specs/spec-x-notify-auq-scope-fix/plan.md`
- Walkthrough: `specs/spec-x-notify-auq-scope-fix/walkthrough.md`
- 직전 PR (회귀 발생): #8 `spec-x-notify-choice-context`
- 관련 ADR-004: `docs/decisions/ADR-004-notification-twofold-decision-flow.md` — 양방향 알림 컨벤션
- 사용자 보고: Telegram msg #3066 (스크린샷)
- 후속 Icebox: spec-x-notify-ack-dedup (Telegram 경유 응답 시 중복 발송 제거)

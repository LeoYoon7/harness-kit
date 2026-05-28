# fix(spec-x-notify-choice-context): 의사결정 알림 flow 양방향 강화 (요청 시 선택지 보존 + 응답 시 ack)

## 📋 Summary

### 배경 및 목적

본 키트의 의사결정 알림 (Telegram/Discord) 에 두 가지 결함 식별:

1. **입력 측 (hook)**: `notify-on-input-wait.sh` 가 권한 요청 패턴 매치 시 transcript 발췌를 일괄 skip. 결과: 에이전트가 선택지를 제시한 직후 권한 다이얼로그가 발화되면 *"권한 승인 대기"* 한 줄만 알림으로 옴 → 사용자가 무엇을 선택해야 할지 알 수 없음. AskUserQuestion 의 탭 멀티 질문 케이스도 미고려.

2. **출력 측 (multi-device)**: 사용자가 PC 에서 의사결정에 응답해도 모바일에는 *응답됨* 신호가 없어 "응답해야 하는 상황인지, 응답 후 진행 중인지" 구분 불가.

본 PR 은 양방향 강화:
- **(입력 측)** hook 본문 분기를 (a) 순수 도구 권한 / (b) 텍스트 선택지 / (c) AskUserQuestion 3 케이스로 정교화. 우선순위 (c) > (b) > (a) > 일반.
- **(출력 측)** `CLAUDE.fragment.md` 에 §9 신규 — 사용자가 의사결정에 응답하면 에이전트가 즉시 `notify-telegram.sh ... "✅ [ack] 사용자 응답: ..." info` 호출.
- ADR-004 양방향 컨벤션으로 문서화.

### 주요 변경 사항

- [x] `sources/hooks/notify-on-input-wait.sh` — IS_PERMISSION 분기를 (a)/(b)/(c) 우선순위로 재정렬. AskUserQuestion `header`/`question`/`options.label` jq 파싱 추가. 텍스트 선택지 패턴 *마지막 5줄 단락만* 매칭 (false positive 차단).
- [x] `sources/claude-fragments/CLAUDE.fragment.md` — §9 신규 섹션 "사용자 응답 직후 — 진행 시작 알림". `[ack]` prefix 필수, 누락 비용 비대칭 자각 명시.
- [x] `docs/decisions/ADR-004-notification-twofold-decision-flow.md` — 양방향 컨벤션 ADR (`type: convention`). 대안 B(hook 자동화)/C(edit) 트레이드오프 명시.
- [x] 도그푸딩 sync — `.harness-kit/hooks/`, `.harness-kit/CLAUDE.fragment.md`.
- [x] 4 케이스 smoke test PASS 포함 — (a)/(b)/(c) + false positive 회피.

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — Solo Spec)
- **본 SPEC 의 역할**: multi-device 사용자 경험 핵심 결함 해소 + 양방향 알림 컨벤션 정립

## 🎯 Key Review Points

1. **(b) 패턴 매칭 범위 — 마지막 5줄로 제한**. `^\d+\)` 패턴 제거. Critique 권장으로 false positive (회고 텍스트 `1) X 2) Y` 류) 차단. Smoke test 검증 완료.
2. **(c) AskUserQuestion 의 `header` 필드 파싱**. 탭 라벨이 알림 본문에 `[모드] 어떤 모드?` 형태로 노출 — 사용자가 "어떤 컨텍스트의 질문인지" 즉시 인지 가능.
3. **§9 의 `[ack]` prefix 필수**. 사후 grep 으로 응답 알림 누락 사례 추적 가능. walkthrough/RCA 와 보완.
4. **§9 의 누락 비용 비대칭**. 다른 절차 누락은 PC 세션에서 회복 가능. **§9 누락은 모바일 사용자가 응답 여부 자체를 모름 → 회복 불가**. ADR-004 의 부정적 결과 절에 명시 — 절차 위반 시 RCA 작성 우선 고려.
5. **자동화 대안 (UserPromptSubmit hook) 의 의도적 보류**. 데이터 (walkthrough/RCA 누적) 가 쌓인 후 별도 spec 으로 평가. ADR-004 의 대안 B 트레이드오프 절 참조.

## 🧪 Verification

### 수동 검증 시나리오 (Hook smoke test — 4 케이스 PASS)

1. **(a) 순수 권한**: transcript 에 선택지/AUQ 없음 + 권한 메시지 → `"권한 승인 대기"` brief ✓
2. **(b) 텍스트 선택지**: transcript 마지막 5줄에 `[선택지]` + `[권장]` → `"사용자 선택 대기"` + 발췌 ✓
3. **(c) AskUserQuestion**: tool_use AUQ (questions x2, header/question/options) → `"사용자 질문 대기"` + `[질문 2개]` + `[모드]/[범위]` header ✓
4. **(FP) False positive 회피**: 회고 `1) 2) 3)` 텍스트 → `"사용자 입력 대기 중"` 일반 모드 (b 오판 없음) ✓

### 메타 dogfood (출력 측 §9)

§9 작성 (`1d14dc1`) 이후 모든 사용자 응답에 `[ack]` prefix 알림 발송. walkthrough §3 메타 dogfood 절에 발송 이력 기록.

## 📦 Files Changed

### 🆕 New Files

- `docs/decisions/ADR-004-notification-twofold-decision-flow.md`: 양방향 알림 컨벤션 ADR
- `specs/spec-x-notify-choice-context/{spec,plan,task,walkthrough,pr_description,critique}.md`

### 🛠 Modified Files

- `sources/hooks/notify-on-input-wait.sh` (+46, -10): IS_PERMISSION 분기를 (a)/(b)/(c) 우선순위로 재정렬, AskUserQuestion 파싱, 마지막 5줄 매칭
- `.harness-kit/hooks/notify-on-input-wait.sh` (+46, -10): 도그푸딩 sync
- `sources/claude-fragments/CLAUDE.fragment.md` (+49): §9 신규 섹션
- `.harness-kit/CLAUDE.fragment.md` (+49): 도그푸딩 sync
- `backlog/queue.md` (+1): spec-x 등록

## ✅ Definition of Done

- [x] 입력 측 hook 본문 분기 (a)/(b)/(c) 우선순위 적용
- [x] 도그푸딩 sync (`.harness-kit/hooks/`, `.harness-kit/CLAUDE.fragment.md`)
- [x] 4 케이스 smoke test 모두 PASS
- [x] 출력 측 fragment §9 신규 섹션 추가
- [x] 메타 dogfood — §9 작성 *직후* 모든 응답에 `[ack]` prefix 적용
- [x] ADR-004 양방향 컨벤션 작성
- [x] `walkthrough.md` + `pr_description.md` ship commit
- [x] (예정) push + PR 생성 + 사용자 알림

## 🔗 관련 자료

- Spec: `specs/spec-x-notify-choice-context/spec.md`
- Plan: `specs/spec-x-notify-choice-context/plan.md`
- Walkthrough: `specs/spec-x-notify-choice-context/walkthrough.md`
- Critique: `specs/spec-x-notify-choice-context/critique.md` — Opus 1M sub-agent 리뷰 + 권장 5항목
- ADR-004: `docs/decisions/ADR-004-notification-twofold-decision-flow.md`
- 관련 외부 자료:
  - Slack Acknowledging requests (ack 3초 룰): cross-channel 의사결정 동기화 사례
  - n8n Human-in-the-Loop Wait Node: 워크플로우 wait/resume 패턴
  - GitHub Issue claude-code#13830: AskUserQuestion 전용 hook 이벤트 요청 (향후 마이그레이션 후보)

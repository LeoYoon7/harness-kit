# docs(spec-x-notify-bidirectional-policy): 의사결정 알림 양방향 정책 전환 + 채널 중립화 + AUQ 사용 제거

## 📋 Summary

### 배경 및 목적

PR #10 (spec-x-notify-channel-coherence) 까지 의사결정 알림 protocol 이 단일 소스 원칙으로 정착. 그러나 라이브 운영 중 사용자가 *fragment 의 내부 모순* 식별:

1. **모순 1**: 섹션 서두 (line 93) "원격 판단 지원" vs 정책 표 (line 379) "보조 채널 — 응답 차단" — 정면 모순
2. **모순 2**: 제목 "Telegram 의사결정..." vs Discord 병행 현실 (dispatcher PR #10) — Telegram 만 명시 = 현실 미반영
3. **모순 3**: AUQ 사용 (§1.5 등) vs multi-device 가치 — AUQ 는 PC 모달 전용 → 모바일 응답 불가
4. **모순 4**: line 122/136 "에이전트는 아무것도 안 함 / 최종 의사결정은 PC/CLI" — 양방향 정책과 모순

본 PR 은 6+1 layer 정합화 + ADR-004 Amendment.

### 주요 변경 사항

- [x] **Layer 1 — 제목 채널 중립화**: `## Telegram 의사결정 알림 프로토콜` → `## 의사결정 알림 프로토콜 (Telegram/Discord)`
- [x] **Layer 2 — 정책 표 라인 교체**: "보조 채널 (응답 비활성)" → "**양방향 채널** (알림 + 응답 인식)"
- [x] **Layer 3 — 신규 §10** (응답 채널 인식 + ChatOps 매핑 알고리즘 한 줄)
- [x] **Layer 4 — AUQ 사용 제거 명시 + §5 dead text 솔직 인지** (legacy 보호 표현 제거)
- [x] **Layer 5 (축소 적용 — Critique #1)** — Telegram 명시 7곳 (제목/정책/§10/line 85/93/120/122/136/140) 만 중립화. 환경변수/.env.telegram/dedupe/비활성화 안내는 보호
- [x] **Layer 7 — governance/agent.md L401 영문 정합** (Critique #8, cross-document)
- [x] **ADR-004 Amendment 추가** + 부정 절 보강 (결정 ID 부재 휴리스틱 한계 + dead branch/text 인지)
- [x] 도그푸딩 sync — `.harness-kit/CLAUDE.fragment.md`, `.harness-kit/agent/agent.md`

### Phase 컨텍스트

- **Phase**: 없음 (spec-x — Solo Spec)
- **본 SPEC 의 역할**: 응답 측 정책의 *완성형* — ADR-004 양방향 컨벤션의 *불완전 활성화* 해소

## 🎯 Key Review Points

1. **정책 전환의 본질** — "보조 채널" 정책 라인 (anomaly) 제거. 서두의 *원격 판단 지원* 의도와 fragment 본문이 처음으로 정합. multi-device 원래 가치 정상화.
2. **AUQ 사용 제거의 *적용 범위*** — 본 에이전트 + sub-agent. 외부 도구 (Gemini CLI, Codex) 는 OOS. hook (c) AUQ 분기 + §5 조건부 생략 규칙은 *dead branch/text 솔직 인지* (6개월 후 완전 제거 트리거).
3. **응답 매핑 알고리즘 (ChatOps 패턴)** — §10 에 "숫자/권장 키워드/라벨 substring → 옵션. 모호 시 사용자 확인 요청" 명시. 에이전트별 해석 차이 차단.
4. **Layer 5 축소 (Critique #1)** — 18곳 일괄 X. 핵심 7곳만. 환경변수/dedupe/비활성화 안내는 Discord active 시점 별도 spec.
5. **검증 중 추가 모순 발견** (line 136) — 사전 식별 불완전. 정합화 완료. 향후 spec 의 *모순 검사 완전성* 학습 사례.

## 🧪 Verification

### grep 검증
- `보조 채널` = **0** ✓
- `양방향 채널` = **3** ✓
- `Telegram notifications` (agent.md) = **0** ✓

### 메타 dogfood — *본 spec 진행 자체* 가 §10 dogfood (2회 실증)
- msg #3130 (Telegram "2", Critique) → §10 응답 인식 + mcp reply ack
- msg #3136 (Telegram "1", Plan Accept) → §10 응답 인식 + mcp reply ack
- 모든 게이트 텍스트 형식 (AUQ 미사용 ✓)
- 채널별 단일 sink (Telegram → mcp / PC chat → notify.sh) 보존 (PR #10 정합)

## 📦 Files Changed

### 🛠 Modified Files

- `sources/claude-fragments/CLAUDE.fragment.md`: 제목 / 정책 표 / 신규 §10 / §5 dead text 노트 / 5곳 중립화 / line 136 추가 정합
- `.harness-kit/CLAUDE.fragment.md`: 도그푸딩 sync
- `sources/governance/agent.md` L401: 영문 채널 중립화
- `.harness-kit/agent/agent.md`: 도그푸딩 sync
- `docs/decisions/ADR-004-notification-twofold-decision-flow.md`: Amendment 추가
- `backlog/queue.md`: spec-x 등록

### 🆕 New Files

- `specs/spec-x-notify-bidirectional-policy/{spec,plan,task,walkthrough,pr_description,critique}.md`

## ✅ Definition of Done

- [x] Fragment line 91 제목 채널 중립화
- [x] Fragment line 379 정책 표 라인 교체
- [x] Fragment 신규 §10 (응답 채널 인식 + 매핑 알고리즘)
- [x] Fragment Telegram 명시 *축소* 7곳 + line 122/136 정합
- [x] AUQ 사용 제거 명시 + §5 dead text 솔직 인지
- [x] ADR-004 Amendment 추가 + 부정 절 보강
- [x] Layer 7 — governance/agent.md L401 정합
- [x] 도그푸딩 sync
- [x] 메타 dogfood — 본 spec 의 §10 절차 2회 실증
- [x] walkthrough + pr_description ship commit
- [x] (예정) push + PR 생성 + 사용자 알림

## 🔗 관련 자료

- Spec: `specs/spec-x-notify-bidirectional-policy/spec.md`
- Plan: `specs/spec-x-notify-bidirectional-policy/plan.md`
- Walkthrough: `specs/spec-x-notify-bidirectional-policy/walkthrough.md`
- Critique: `specs/spec-x-notify-bidirectional-policy/critique.md` — Opus 1M, 10항목 권장 all 반영
- 직전 PR: #10 `spec-x-notify-channel-coherence` (단일 소스 원칙) — 본 spec 이 양방향 정책 완성
- ADR-004 Amendment: `docs/decisions/ADR-004-notification-twofold-decision-flow.md` `## 🔄 Amendments`
- 사용자 보고 트리거: Telegram msg #3113 (§1.5 AUQ 선택지 미노출) → 정책 재검토 → 본 spec

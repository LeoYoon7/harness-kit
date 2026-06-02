# docs(spec-x-native-feature-usage): native feature usage playbook (situation to feature to condition)

## 📋 Summary

### 배경 및 목적

Claude Code 네이티브 기능의 도입 판단·조건이 세 곳(`report.md` 조사, `ADR-007` 정책, `agent.md §6.7` 요지)에 분산되어 "지금 이 상황엔 뭘 쓰지?"를 한눈에 볼 수 없었다. 본 spec 은 이를 **상황-우선 사용 playbook** 으로 통합하고, 1단계 즉시채택 6종을 공식화한다. CC 네이티브 도입 arc(조사 #25 → 정책 #26 → 검증 #27)의 마무리.

### 주요 변경 사항

- [x] **신설** `docs/native-feature-usage.md` — 상황(when) → 권장 기능 → tier → 조건 표
- [x] 1·2·3단계 채택 기능 15종 전부 + 보류(`/batch`)·거버넌스무관(`/powerup`·`/radio`) 각주 수록
- [x] **1단계 6종 채택 공식화** (`/deep-research`·`/workflows`·`/copy`·`/rewind`·`/team-onboarding`·`/btw`)
- [x] `ADR-007` Related 에 본 문서 포인터 (정본=ADR-007, 모순 시 ADR-007 우선 명시)

### Phase 컨텍스트
- **Phase**: 없음 (spec-x, docs)
- **본 SPEC 의 역할**: 흩어진 네이티브 기능 사용 지침을 운영자/미래 세션이 즉시 쓰는 단일 playbook 으로 통합

## 🎯 Key Review Points

1. **정책 무변경 확인**: 본 문서가 ADR-007 조건을 *합성*만 하고 *변경*하지 않는가. "정본=ADR-007, 모순 시 우선" 명시로 drift 방지하는가.
2. **상황 매핑의 정확성**: §2 표의 상황 → 기능 → 조건이 ADR-007 / report 와 일치하는가.
3. **위치 선택**: `docs/`(미배포) + agent.md 미편집 — governance 단어수 회피 + 배포 중립성. 적절한가.

## 🧪 Verification

### 자동 테스트
```text
해당 없음 — docs-only. agent.md/constitution 미편집 → test-governance-dedup 회귀 무관.
```

### 수동 검증 시나리오
1. **정본 대조**: playbook 전 기능(15종+보류+N-A)이 ADR-007/report 등급·조건과 일치 → 모순 없음 ✓
2. **링크**: ADR-007 Related → `docs/native-feature-usage.md` 포인터 정확 ✓

## 📦 Files Changed

### 🆕 New Files
- `docs/native-feature-usage.md`: 네이티브 기능 사용 playbook (상황→기능→조건)
- `specs/spec-x-native-feature-usage/{spec,plan,task,walkthrough,pr_description}.md`

### 🛠 Modified Files
- `docs/decisions/ADR-007-native-feature-adoption-policy.md` (+1 line): Related 에 playbook 포인터

**Total**: 신규 6 + 수정 1

## ✅ Definition of Done

- [x] `docs/native-feature-usage.md` 작성 (상황-우선 표 + 전 채택 기능 + 경계 각주)
- [x] ADR-007 Related 포인터 추가
- [x] (docs-only — 단위 테스트 해당 없음)
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 브랜치 push
- [x] 사용자 검토 요청 알림

## 🔗 관련 자료

- 정책 정본: `docs/decisions/ADR-007-native-feature-adoption-policy.md`
- 조사: `spec-x-cc-native-adoption` (PR #25), 정책: `spec-x-native-feature-adoption-policy` (PR #26), 검증: `spec-x-native-session-feature-verify` (PR #27)

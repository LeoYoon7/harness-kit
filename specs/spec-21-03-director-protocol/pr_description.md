# feat(spec-21-03): director mode protocol (6.8 + 6.1 delegation + ADR-011)

## 📋 Summary

### 배경 및 목적

phase-21 의 spec-21-01(§6.6 always-on orchestration + ADR-010)·spec-21-02(`/hk-director` 토글 + `directorMode` 영속화)이 *기반*과 *표면*을 깔았으나, **`directorMode=true` 의 행동이 비어 있었다**. 본 spec 은 디렉터의 운영 규약 — 의도 합의 / 워커 위임 명세 / 검증 불변식 / 게이트 보유 — 을 거버넌스에 명문화한다.

### 주요 변경 사항

- [x] agent.md **§6.8 Director Mode Protocol** stub 추가 (영어, 6규칙 + 핵심 불변식 용어 + 참조)
- [x] **`director-mode.md`** 운영 가이드 신규 (한국어, native-feature-usage.md 패턴 — 설치 대상 자족 지침)
- [x] agent.md **§6.1 Director Mode delegation** 단락 추가 (Strict Loop 실행 위임 분업 계약)
- [x] **ADR-011** director-mode 작성 (type: decision, upstream ADR-006 의 fork 재구현)
- [x] **`test-director-protocol.sh`** 신규 (13 checks: 섹션/용어/위임/이중 미러/가이드/ADR)

### Phase 컨텍스트

- **Phase**: `phase-21` (director-mode)
- **본 SPEC 의 역할**: 성공기준 3(Director Mode Protocol) 충족. 토글(21-02)에 *행동*을 부여하고 ADR-010 ④축(검증 불변식)을 운영화. 단어 예산 green(성공기준 4)은 본 spec scope 외 — spec-21-06 으로 분리.

## 🎯 Key Review Points

1. **게이트 정합 (§6.8 규칙 5)**: Plan Accept·Ship·§5/§9 알림 게이트를 워커에 위임하지 않음을 명문화 — human-gate(ADR-008)·양방향 알림 우회 차단.
2. **검증 불변식 (§6.8 규칙 4)**: 디렉터 검수 = 테스트 재실행 + 동작 스모크 + 증류 계약 대조. 워커 transcript 전문 재흡수 = VIOLATION (ADR-010 ④ 운영화).
3. **stub-guide 배치 전략**: agent.md inline 대신 간결 stub + 별도 한국어 가이드로 단어 예산 압박 분산. agent.md 순증 +171w (목표 ~150w, 21-06 흡수).
4. **단어 예산**: 본 spec 은 순증 전용 — `test-governance-dedup.sh` Check 3 red 유지가 **정상**(green 은 spec-21-06 + phase Done 조건).

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-director-protocol.sh
bash tests/test-governance-dedup.sh
bash tests/test-director-mode.sh
bash tests/test-context-orchestration.sh
```

**결과 요약**:
- ✅ `test-director-protocol.sh`: 13/13 PASS (GREEN)
- ✅ `test-governance-dedup.sh`: Check 1/2/4/5/6 PASS, Check 3(단어 예산) red 유지 — 무 NEW 회귀(예상)
- ✅ `test-director-mode.sh`: 10/10 PASS (무 회귀)
- ✅ `test-context-orchestration.sh`: 6/6 PASS (무 회귀)

### 수동 검증 시나리오
1. **§6.8 stub 존재**: `grep "6.8 Director Mode Protocol" sources/governance/agent.md` → 검출.
2. **이중 미러 parity**: `diff -q` agent.md / director-mode.md (source ↔ .harness-kit) → 차이 없음.

## 📦 Files Changed

### 🆕 New Files
- `sources/governance/director-mode.md` (+72): 디렉터 모드 운영 가이드(한국어)
- `.harness-kit/agent/director-mode.md` (+72): 미러
- `docs/decisions/ADR-011-director-mode.md` (+56): 디렉터 모드 ADR(type: decision)
- `tests/test-director-protocol.sh` (+123): 검증 테스트(13 checks)
- `specs/spec-21-03-director-protocol/{spec,plan,task}.md`: 산출물

### 🛠 Modified Files
- `sources/governance/agent.md` (+13): §6.8 stub + §6.1 delegation 단락
- `.harness-kit/agent/agent.md` (+13): 미러
- `backlog/phase-21.md` (+14, -3): OPEN 결정 2건 해소 + spec-21-06 추가
- `backlog/queue.md` (+1, -1): active spec 갱신

**Total**: 11 files changed (+668, -4)

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (test-director-protocol 13/13)
- [x] 회귀 무 NEW (Check 3 red 유지 — 예상, 21-06 책임)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] 코드 리뷰 (Gemini cross-model — Approve)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Phase: `backlog/phase-21.md`
- Walkthrough: `specs/spec-21-03-director-protocol/walkthrough.md`
- 관련 ADR: `docs/decisions/ADR-011-director-mode.md` (토대: ADR-010, 정합: ADR-007/008)

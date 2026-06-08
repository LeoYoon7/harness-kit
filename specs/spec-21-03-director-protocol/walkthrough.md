# Walkthrough: spec-21-03

> 작업 기록 — 디렉터 운영 프로토콜(§6.8 + §6.1 위임 + ADR-011) 명문화.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| §6.8 배치 | agent.md inline / 별도 가이드+stub | **별도 `director-mode.md` 가이드 + agent.md 간결 stub** | native-feature-usage.md 패턴. agent.md 순증 최소화. 21-01 이 §6.8 을 분리 후보로 표시 (§11.3 재검증서 확정) |
| 단어 예산 처리 | 21-03 동시 다이어트 / 21-06 분리 / 8000w 상향 | **6000w 유지 + 다이어트 spec-21-06 분리** | 다이어트 ~1333w 가 protocol 추가와 독립·대규모 → add/delete 혼재 회피. 상향은 anti-bloat 충돌 (§11.3 재검증서 확정) |
| 구현 주체 | 메인 직접 / 워커 위임 | **메인 직접 작성** | governance prose 는 판단·정합 검토 중심(orchestrator 보유 노동). ADR-010 docs-only dispatch 예외 |
| 테스트 단어예산 게이트 | test-director-protocol 에 포함 / SSOT 분리 | **SSOT 분리** (test-governance-dedup Check 3) | 동일 지표 이중 baseline 금지(21-01 결정). 본 spec 은 Check 3 red 유지가 정상 |
| ADR 번호 | upstream 006 재사용 / fork 신규 011 | **fork 신규 011** | fork ADR-006=code-review-gate — 번호 충돌. upstream 005/006 은 참조만 |
| agent.md 순증 NFR2 | ~150w 목표 엄수 / +171w 수용 | **+171w 수용** | enforcement 절(VIOLATION/PROHIBITED/게이트 리스트) 보존 우선. 1차 +201w → 트림 +171w. 21-06 다이어트가 흡수 |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-011-director-mode.md` (type: decision)
- [ ] 없음

## 💬 사용자 협의

- **주제**: §11.3 재검증 — 단어 예산 처리 방향
  - **사용자 의견**: 1번 (protocol-only + 다이어트 21-06 분리)
  - **합의**: 21-03 = protocol-only(stub+가이드), 6000w 유지, 다이어트는 신설 spec-21-06. phase.md OPEN 결정 2건 해소 + 21-06 추가.
- **주제**: Plan Accept vs Critique
  - **합의**: Plan Accept (1) — upstream spec-20-02 의 잘 이해된 패턴 재구현, 가역적.
- **주제**: Ship 코드 리뷰 게이트
  - **사용자 의견**: 1번 (Gemini cross-model)
  - **합의**: Gemini 리뷰 실행 → **Approve**.

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-director-protocol.sh`
- **결과**: ✅ Passed (PASS=13 FAIL=0)
- **로그 요약**:
```text
C1 §6.8 섹션 · C2 핵심 용어×4 · C3 §6.1 delegation×3 · C4 이중 미러 parity×2 · C5 가이드 존재 · C6 ADR-011+type
결과: PASS=13 FAIL=0
```

#### 회귀
- **명령**: `bash tests/test-governance-dedup.sh` / `test-director-mode.sh` / `test-context-orchestration.sh`
- **결과**: governance-dedup 1/8 (Check 3 단어 예산만 red — **무 NEW 회귀**, Check 1/2/4/5/6 PASS). director-mode 10/10 PASS. context-orchestration 6/6 PASS.
- **단어 예산 (before/after)**:
```text
before (21-02 머지 후): constitution 2798 + agent.md 4535 = 7333w
after  (본 spec):        constitution 2798 + agent.md 4706 = 7504w
agent.md 순증: +171w (목표 ~150w, +21w — enforcement 절 보존 위해 수용)
Check 3 red 유지 = 예상된 결과. green 복구는 spec-21-06 책임.
```

### 2. 수동 검증

1. **Action**: `grep "6.8 Director Mode Protocol" sources/governance/agent.md` — **Result**: stub 헤더 검출.
2. **Action**: `diff -q sources/governance/director-mode.md .harness-kit/agent/director-mode.md` — **Result**: 차이 없음(parity).
3. **Action**: `diff -q sources/governance/agent.md .harness-kit/agent/agent.md` — **Result**: 차이 없음(parity, cp 보장).

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-21-03-director-protocol/code-review-gemini.md` |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 1~2 |
| **Minor 처리** | #1 agent.md +171w(>목표) — **수용**, 21-06 다이어트가 흡수(spec 명시). #2 테스트 ADR type 체크 — `$ADR` 경로 정확 타겟팅이라 무문제(관찰) |

> base(`phase-21-director-mode`) 존재로 Gemini diff 정상. 21-01 의 first-spec 빈 diff 이슈 없음.

## 🔍 발견 사항

- **stub-guide 패턴 검증**: agent.md inline 대신 stub(영어, 강제 규약+용어) + director-mode.md(한국어, how-to) 분리가 단어 예산 압박을 분산. native-feature-usage.md 와 동일 위상으로 install glob 자동 배포(별도 install.sh 수정 불요).
- **이중 미러 = cp 로 보장**: 미러 분기 위험을 source 편집 후 `cp` 로 원천 차단(diff parity 테스트로 강제).
- **§6.8 게이트 보유(5)가 ADR-008·§5/§9 와 정합**: 디렉터가 게이트를 워커에 내리지 않음을 명문화해 human-gate·양방향 알림 우회를 차단.

## 🚧 이월 항목

- **거버넌스 다이어트(6000w green 복구, +171w stub 순증 포함)** → spec-21-06 (governance-diet, phase.md 등록).
- **역할 기반 모델 config de-hardcode** → spec-21-04.
- **페르소나 리뷰 패널** → spec-21-05.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent(Opus orchestrator) + Leo |
| **작성 기간** | 2026-06-05 |
| **최종 commit** | `b4e0440` (ship commit 직전) |

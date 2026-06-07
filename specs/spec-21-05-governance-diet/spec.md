# spec-21-05: 거버넌스 단어 예산 다이어트 (Check 3 green 복구)

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-21-05` |
| **Phase** | `phase-21` |
| **Branch** | `spec-21-05-governance-diet` |
| **상태** | Planning |
| **타입** | Refactor |
| **Integration Test Required** | no |
| **작성일** | 2026-06-08 |
| **소유자** | Leo |

> **번호 주의**: governance-diet 를 persona-panel 보다 먼저 착수해 sdd 가 diet=`spec-21-05` 부여(persona=21-06). 머지된 21-03/21-04 walkthrough 의 "→ spec-21-06"(diet) 포워드 참조는 historical (phase.md 정정 노트 참조).

## 📋 배경 및 문제 정의

### 현재 상황

`tests/test-governance-dedup.sh` Check 3(단어 예산)는 constitution.md + agent.md 합계 상한을 **6000w** 로 강제한다. phase-21(director-mode)에서 §6.6/§6.8/§6.1·ADR 참조가 누적되며 현재 **7494w (constitution 2798 + agent.md 4696)** — **+1494w 초과(red)**. 이 red 는 phase-21 내내 의식적으로 21-05 로 이월돼 왔다(21-01 ±50w 결정, 21-03 §11.3 재검증서 분리 확정).

### 문제점

- **phase Done 블로커**: 성공기준 4(Check 3 GREEN)가 미충족이라 phase-21 을 완료할 수 없다.
- **anti-bloat 원칙 위배**: fork 의 "컨텍스트 비용 0 우선" 원칙상 *항상 로딩되는* 거버넌스가 비대하면 매 세션 토큰 비용이 든다.
- 단순 상한 상향(upstream 8000w)은 21-03 에서 명시 비채택(원칙 충돌).

### 해결 방안 (요약)

**relocate > compress > delete** 우선순위로 enforcement 무손실 다이어트를 수행한다. (1) 추출 — 상세·상황형 콘텐츠를 *이미 존재하는* 가이드로 이전(§6.7 native-feature → `native-feature-usage.md` stub). (2) 제거 — stale 콘텐츠(§8.4 AskUserQuestion, fork 미사용 정책). (3) 압축 — 최대 섹션의 장황한 prose/중복/예시를 규칙 보존하며 축약. 목표 <6000w (headroom 위해 ~5700w).

## 📊 개념도

```text
현재 7494w (const 2798 + agent 4696)  ──다이어트──▶  목표 <6000w (~5700w, ~1700w↓)

  [추출]  agent §6.7 native-feature 단락 → stub (상세는 native-feature-usage.md)
  [제거]  agent §8.4 AskUserQuestion → 1줄 stub (fork 미사용)
  [압축]  agent §6(1709)/§11(622), const §5(878)/§3(507)/§6(460) 의 prose·중복·예시
            └ 규칙(MUST/금지/식별자/게이트)은 보존, 설명·예시만 축약
```

## 🎯 요구사항

### Functional Requirements

1. **Check 3 GREEN**: `bash tests/test-governance-dedup.sh` 의 Check 3 (constitution+agent.md ≤ 6000w) 통과. 측정값을 walkthrough 에 before/after 기록.
2. **추출 — §6.7 native-feature**: agent.md §6.7 의 native-feature gate-preservation 장황 단락을 stub(규칙 1–2줄 + `native-feature-usage.md`/ADR-007 참조)으로 축약. 상세는 이미 가이드에 존재(중복 제거).
3. **제거 — §8.4 AUQ**: agent.md §8.4 AskUserQuestion 절을 1줄 stub 으로(“fork 는 AUQ 미사용 — 모든 게이트는 텍스트, → CLAUDE.fragment §notify”). `uxMode` 참조가 다른 곳에 필요하면 보존.
4. **압축**: 최대 섹션(agent §6/§11, const §5/§3/§6)의 prose·중복·예시를 축약. **모든 MUST/금지/식별자 포맷/게이트 규칙·§6.6/§6.8/§6.1(21-03/04 추가분) 보존**.
5. **이중 미러**: `sources/governance/{constitution,agent}.md` ↔ `.harness-kit/agent/` 동기화.

### Non-Functional Requirements

1. **enforcement 무손실 (최우선)**: 강제 규칙(MUST/금지/CRITICAL VIOLATION/식별자/게이트/테스트 요건)은 *단 하나도* 삭제하지 않는다. relocate(가이드 이전)·compress(표현 축약)만. 의미 변경 금지.
2. **무 NEW 회귀**: `test-governance-dedup.sh` Check 1(중복문장 0)/2(미러 sync)/4(dead letter)/5(섹션번호)/6(sdd 경로) 모두 유지. `test-director-mode.sh`/`test-director-protocol.sh`/`test-role-model-config.sh`/`test-context-orchestration.sh` 무 회귀(이들은 거버넌스 용어를 grep — 용어 보존 필수).
3. **참조 무결성**: 섹션 번호 cross-ref(예: `→ §6.7`, `→ constitution §5.3`)가 압축 후에도 유효. 섹션 번호 재배열 금지(§5 섹션번호 중복 테스트와도 정합).
4. **headroom**: 단순 6000w 미만이 아니라 ~5700w 목표(향후 소폭 추가 여유). 과도 삭제로 규칙 손실하지 않는 선에서.
5. **추출 대상 가이드 정합**: §6.7 stub 이 가리키는 `native-feature-usage.md` 가 해당 상세를 실제 보유하는지 확인(stub 이 빈 곳 가리키지 않게 — 21-04 ADR-011 귀속 사고 교훈).

## 🚫 Out of Scope

- **상한 상향(8000w)** — 21-03 에서 비채택(fork anti-bloat). 6000w 유지.
- **persona-review-panel** → spec-21-06.
- **규칙 *내용* 변경/추가** — 본 spec 은 표현 다이어트만. 새 규칙·정책 도입 금지.
- **CLAUDE.fragment.md / CLAUDE.md 다이어트** — 이들은 Check 3 측정 대상 아님(constitution+agent.md 만). 별도 Icebox 항목(root CLAUDE.md 슬림화) 존재.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 표현 다이어트(refactor). "거버넌스는 상한 유지 + 주기적 다이어트(상향 아님)" 원칙은 분기별 prune protocol(Icebox 기존 항목)로 다룰 후보이며 본 spec 범위 밖.

## ✅ Definition of Done

- [ ] `test-governance-dedup.sh` Check 3 GREEN (<6000w) + before/after 기록
- [ ] §6.7 추출(stub) + §8.4 제거(stub) + 최대 섹션 압축 (agent.md source + 미러)
- [ ] constitution 압축 (source + 미러)
- [ ] enforcement 무손실 확인 (MUST/금지/게이트 규칙 보존) + 무 NEW 회귀 (governance + director/role/context 테스트)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-21-05-governance-diet` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료

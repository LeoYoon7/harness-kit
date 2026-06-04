# Walkthrough: spec-x-goal-verify-gate

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| `/goal` 자율성 ↔ 게이트 멈춤 충돌 해소 | 검증 강제 / 게이트 유지 | 검증 강제 + **검증≠승인 분리** | 검증으로 멈춤 빈도↓ 가능하나 권한 게이트는 대체 불가 |
| hard-stop 잔존 범위 (Q1) | a 보수 / b 적극(§7 완화) | **a (1차)**, b 는 Icebox | §7 중앙 규약 완화는 리스크 — hook 단계론으로 데이터 축적 후 승격 |
| `/goal` 모드 감지 (Q2) | 자동 감지 / launch-ritual 앵커링 | **launch-ritual** | 👤 기능이라 자동 감지 불안정 |
| 강제 임계값 (Q3) | 신규 임계 / §11.2 재사용 | **§11.2 재사용** | 새 임계값 도입 회피 |
| 정책 기록 위치 | 신규 ADR / ADR-007 Amendment | **ADR-007 Amendment** | `/goal` 조건 refinement, 번호 인플레 회피 |
| dogfood sync 방식 | update.sh / 직접 동시 편집 | **직접 동시 편집** | 2파일 소규모 — surgical, 부수 drift 회피 |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → **ADR-007 Amendment** 로 기록 (신규 번호 미발급 — 기존 ADR-007 의 `/goal` 조건 refinement)
- [ ] 없음

## 💬 사용자 협의

- **주제**: `/goal` 검증 강제 정책 (4라운드 설계 수렴)
  - **사용자 의견**: `/goal` 은 목표 도달까지 자율 진행인데 게이트에서 막히면 안 됨. `/goal` 켜면 무조건 code-review·critique 로 최대한 검증 후 진행하자.
  - **합의**: **검증 ≠ 승인** 경계 수용 (검증이 권한 게이트를 대체 못 함). Q1=보수(a)+추후 b, Q2=launch-ritual 앵커링, Q3=§11.2 재사용. 최종 "모두 권장으로 진행".

## 🧪 검증 결과

### 1. 자동화 테스트

#### governance 일관성 (단위테스트 대체 — docs-only, 헌법 §9.1)
- **명령**: `bash tests/test-governance-dedup.sh`
- **결과**: ❌ 1/8 (Check 3 단어수만 실패) — **사전 존재 실패**
- **로그 요약**:
```text
✅ Check 2: sources/governance/ ↔ .harness-kit/agent/ 동기화 OK (constitution.md, agent.md)
❌ Check 3: 합계 7045w > 상한 6000w (거버넌스 비대화)
✅ Check 1/4/5/6 PASS
```
- **해석**: Check 3 단어수 초과는 **본 변경 이전부터 존재**(Icebox 기록 — 주로 #26 native-feature §6.7 단락). 본 변경은 agent.md 에 ~25단어 gist 만 추가했고 *새로운* check 를 깨지 않았다. 오히려 **Check 2(동기화)가 PASS 하여 dogfood sync 정확성을 입증**한다.

### 2. 수동 검증

1. **Action**: `git diff` (sources↔installed agent.md) — **Result**: blob `4a4399c→980b529` 양쪽 동일
2. **Action**: `git diff --no-index` (플레이북 양쪽) — **Result**: `exit=0` byte-identical
3. **Action**: ADR-007 Amendment ↔ `agent.md §6.7` ↔ 플레이북 `/goal` 행 3자 일관성 — **Result**: 모순 없음

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **Skip 사유** | `docs-only` (거버넌스 문서/플레이북 변경 — 코드·스크립트·테스트 무변경) |

## 🔍 발견 사항

- **거버넌스 단어수 비대화 가속** — Icebox 기록 시점 6418w → 현재 **7045w**. 주로 #26 의 §6.7 native-feature 단락. Icebox 의 "거버넌스 다이어트" 항목 수치 갱신 + 별도 spec 검토 필요.
- **Q1-b(적극안)** — 완전 무중단 + agent.md §7 hard-stop 완화 + logged-default 레인은 본 spec 보수안 운영 데이터 축적 후 승격 (Icebox 캡처됨).

## 🚧 이월 항목

- Q1-b 적극안(완전 무중단, §7 완화) → `backlog/queue.md` Icebox (`spec-x-goal-verify-gate` 항목에 명시)

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-04 |
| **최종 commit** | ship commit (push 직전 갱신) |

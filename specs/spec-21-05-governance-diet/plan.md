# Implementation Plan: spec-21-05

## 📋 Branch Strategy

- 신규 브랜치: `spec-21-05-governance-diet` (= spec 디렉토리 이름).
- 시작 지점: **`phase-21-director-mode`** (phase base). 직전 spec(21-04) merge 완료.
- 첫 task 가 브랜치 생성. PR target = `phase-21-director-mode`.

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **enforcement 무손실 최우선**: MUST/금지/CRITICAL VIOLATION/식별자 포맷/게이트 규칙·§6.6/§6.8/§6.1 은 절대 삭제 안 함. relocate(가이드 이전) + compress(표현 축약)만.
> - [ ] **목표 <6000w (headroom ~5700w)**: 현재 7494w → ~1700w 절감. 과도 삭제 금지.
> - [ ] **§8.4 AUQ 제거 타당성**: fork 는 AUQ 미사용 정책([[feedback-no-auq-ever]])이라 §8.4 는 사실상 dead. 1줄 stub 으로 축약(uxMode 참조는 보존).

> [!WARNING]
> - [ ] **가장 delicate 한 spec**: 항상 로딩되는 강제 규약(constitution+agent.md) 대규모 편집. 규칙 손실 위험 → 보수적 압축 + 테스트 무회귀로 방어.
> - [ ] **이중 미러 + 용어 보존**: director/role/context 테스트가 거버넌스 용어를 grep — 압축 시 핵심 용어(intent handshake, distilled contract, models.director 등) 보존 필수.
> - [ ] **규모상 Opus critique 권장** (gate 에서 선택 가능).

## 🎯 핵심 전략 (Core Strategy)

### 다이어트 우선순위

```text
1) relocate (무손실)  : §6.7 native-feature 단락 → stub (상세 이미 native-feature-usage.md)
2) delete-stale       : §8.4 AskUserQuestion → 1줄 stub (fork 미사용)
3) compress (보수적)  : 최대 섹션 prose/중복/예시 축약, 규칙 보존
```

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **우선순위** | relocate > compress > delete | enforcement 무손실. 가이드 이전은 정보 손실 0 |
| **§6.7** | stub + native-feature-usage.md 참조 | 상세 중복 — 가이드가 이미 정본(§6.7 도 그렇게 명시). §6.8 stub 패턴과 일관 |
| **§8.4** | 1줄 stub | fork AUQ 미사용 정책 → 절 전체가 dead advisory |
| **압축 대상** | agent §6/§11, const §5/§3/§6 | 최대 섹션. 규칙 외 prose/예시/중복 우선 |
| **섹션 번호** | 불변 | cross-ref(→ §X) 무결성 + Check 5(섹션번호 중복) 정합 |
| **구현 주체** | 메인 직접 | 규칙 보존 판단이 핵심(orchestrator 보유). 위임 부적합 |
| **목표치** | ~5700w (headroom) | 6000 빠듯하면 향후 소폭 추가에 재red. ~300w 여유 |

### 📑 ADR 후보
- [x] 없음 — refactor. (분기별 prune protocol 은 Icebox 별도 항목.)

## 📂 Proposed Changes

### 거버넌스 (governance) — 모두 source + `.harness-kit/agent/` 미러

#### [MODIFY] `sources/governance/agent.md` (현 4696w)
- **§6.7 추출**: native-feature gate-preservation 장황 단락(line ~278) → stub(규칙 1–2줄 + `native-feature-usage.md`/ADR-007 참조). ~200w↓.
- **§8.4 제거**: AskUserQuestion 절(uxMode 표·preferred points·usage notes) → 1줄 stub. ~150–180w↓.
- **§6 압축**: §6.1~6.8 의 장황 prose·예시·중복 축약(규칙·용어 보존). §6.3 walkthrough/리뷰 게이트 서술 등. ~250w↓.
- **§11 압축**: planning economy 의 표·설명 축약(임계·재검증 규칙 보존). ~150w↓.
- **§4 / §3 / §8.5 압축**: §4 layout ascii·서술, §3 alignment, §8.5 choice protocol 의 예시 축약. ~150w↓.

#### [MODIFY] `sources/governance/constitution.md` (현 2798w)
- **§5 압축**(878w): §5.2 Plan Accept 인식 목록·§5.5 idea gate·§5.7 action confirmation(push 정보블록 ASCII 등) 의 예시·중복 축약. 규칙 보존. ~250w↓.
- **§3 / §6 / §2 압축**: §3 work type·§6 identifier 예시·§2 work mode edge-case 표 축약. ~250w↓.

> 누적 목표: agent.md ~900w↓ + constitution ~500w↓ ≈ ~1400–1700w↓ → 합계 <6000w.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-governance-dedup.sh    # Check 3 GREEN(<6000w) + Check 1/2/4/5/6 유지
```

### 회귀 (용어/구조 보존)
```bash
bash tests/test-director-protocol.sh      # §6.8 용어 보존
bash tests/test-role-model-config.sh      # §6.6 models.* 보존
bash tests/test-director-mode.sh
bash tests/test-context-orchestration.sh  # §6.6 orchestrator/worker 용어 보존
```

### 수동 검증 시나리오
1. `wc -w sources/governance/{constitution,agent}.md` before/after → 합계 <6000.
2. `diff -q` 미러 (constitution + agent) → 차이 없음.
3. 규칙 보존 spot-check: "CRITICAL VIOLATION", "One Task = One Commit", "Plan Accept", 식별자 포맷, 게이트 규칙 grep 잔존 확인.
4. cross-ref spot-check: `→ §` 참조가 가리키는 섹션 존재 확인.

## 🔁 Rollback Plan

- 거버넌스 문서 표현 변경만(로직/규칙 불변). 브랜치 폐기/revert 로 즉시 원복.
- 규칙 손실 의심 시: git diff 로 삭제 라인 검토 — 규칙 라인 삭제 발견 시 복원.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship

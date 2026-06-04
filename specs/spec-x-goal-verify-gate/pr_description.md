# docs(spec-x-goal-verify-gate): `/goal` 자율 실행 시 검증 강제 게이트 정책

## 📋 Summary

### 배경 및 목적
`/goal`(👤 사용자 전용 자율 기능)의 게이트 보존 조건("각 게이트에서 멈추고 보고")이 *자율 진행* 목적과 충돌한다. 검증을 강제해 멈춤 빈도는 낮추되 권한 게이트는 보존하는 정책을 거버넌스에 명문화한다.

### 주요 변경 사항
- [x] **ADR-007 Amendment** — `/goal` 검증 강제 정책 (검증≠승인 / 보존 hard-stop 2개 / launch-ritual / §11.2 임계 / Q1-a 채택)
- [x] **agent.md §6.7** — `/goal` 검증 요지 + ADR 포인터 (sources + installed sync)
- [x] **native-feature-usage 플레이북 §2·§3** — `/goal` 행에 검증 조건 (sources + installed sync)

### Phase 컨텍스트
- **Phase**: 해당 없음 (spec-x)
- **역할**: ADR-007(native-feature-adoption-policy)의 `/goal` 조건 refinement.

## 🎯 Key Review Points

1. **검증 ≠ 승인 경계**: code-review/critique 통과가 Plan Accept·scope 확장·merge 권한을 대체하지 않음 (헌법 §1.2/§5.3, ADR-008).
2. **1차 보수안(Q1-a)**: 가역 마이크로 A/B 도 hard-stop 유지 — 완전 무중단은 아님. Q1-b(§7 완화)는 Icebox 후속.
3. **dogfood sync**: agent.md(blob 동일)·플레이북(`--no-index` exit=0) sources↔installed byte-identical 검증.

## 🧪 Verification

### governance 일관성 (docs-only → 단위테스트 미해당, 헌법 §9.1)
```bash
bash tests/test-governance-dedup.sh
```
**결과 요약**:
- ✅ Check 2 (sources↔installed 동기화): agent.md sync 정확성 입증
- ⚠️ Check 3 (단어수 7045w > 6000w): **사전 존재 비대화**(Icebox) — 본 변경(~25w)이 만든 *새 회귀 아님*
- ✅ Check 1/4/5/6

### 수동 검증 시나리오
1. agent.md sources↔installed → blob `4a4399c→980b529` 동일
2. 플레이북 sources↔installed → `git diff --no-index` exit=0 (byte-identical)
3. ADR-007 ↔ agent.md §6.7 ↔ 플레이북 `/goal` 행 3자 일관성 → 모순 없음

## 📦 Files Changed

### 🆕 New Files
- `specs/spec-x-goal-verify-gate/{spec,plan,task,walkthrough,pr_description}.md`: spec 산출물

### 🛠 Modified Files
- `docs/decisions/ADR-007-native-feature-adoption-policy.md` (+30): `/goal` 검증 강제 Amendment
- `sources/governance/agent.md` (+1, -1): §6.7 `/goal` 요지
- `.harness-kit/agent/agent.md` (+1, -1): 설치본 sync
- `sources/governance/native-feature-usage.md` (+2, -2): §2·§3 `/goal` 행
- `.harness-kit/agent/native-feature-usage.md` (+2, -2): 설치본 sync

**Total**: 거버넌스 5파일 + spec 산출물

## ✅ Definition of Done

- [x] governance 일관성 검증 (Check 2 동기화 PASS; Check 3 사전존재 — 무 NEW 회귀)
- [-] 단위 테스트 (docs-only 미해당)
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 코드 리뷰 게이트 (`docs-only` skip, 사유 기록)
- [x] 사용자 검토 요청 알림

## 🔗 관련 자료

- ADR: `docs/decisions/ADR-007-native-feature-adoption-policy.md` (Amendment)
- 관련 ADR: ADR-008 (human-gate-model-invocation), ADR-006 (code-review-gate-default-run)
- Walkthrough: `specs/spec-x-goal-verify-gate/walkthrough.md`

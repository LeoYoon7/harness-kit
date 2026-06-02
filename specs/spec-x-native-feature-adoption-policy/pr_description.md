docs(spec-x-native-feature-adoption-policy): 네이티브 기능 게이트 보존 정책 명문화

## 📋 Summary

### 배경 및 목적

선행 조사 `spec-x-cc-native-adoption`(PR #25)이 Claude Code 네이티브 기능 7종을 "조건부 Go"로 분류했으나, 그 게이트 보존 조건이 **조사 report 에만 있고 거버넌스(강제 규약)에 없었다**. 실제 사용 시 §8.5·Plan Accept·멀티모델 게이트를 조용히 우회할 위험이 남았다. 본 spec 은 그 조건을 **ADR-007(convention)** 로 규약화하고 `agent.md` 에 자족 요지를 추가한다.

### 주요 변경 사항

- [x] **ADR-007** `native-feature-adoption-policy` 신규 — 7종(goal·effort ultracode·fewer-permission-prompts·code-review[ultra/기본형]·ultraplan·스킬) 각 게이트 보존 조건 + 막는 충돌 + 대안
- [x] **agent.md §6.7 요지** — "네이티브 기능은 게이트 보존 조건 하에서만" 자족 문장 + ADR-007 근거 참조 (전파)
- [x] **도그푸딩 동기화** — `sources/governance/` → `.harness-kit/agent/` cp
- [x] 거버넌스 슬림 유지 — 상세는 ADR, 요지만 agent.md(+90w)

### 컨텍스트
- **Phase**: 없음 (spec-x, Solo)
- **역할**: 조사(PR #25)의 "조건부 Go"를 강제 규약으로 승격. 후속 검증/도입 spec 의 정책 기준

## 🎯 Key Review Points

1. **전파 범위 (안 A)**: `sources/governance/agent.md` 수정 → 모든 설치 대상에 전파. ADR 은 키트 repo 전용이라 agent.md 요지를 **자족적**으로 작성(dangling 회피).
2. **ADR-007 Decision 표**: 7종 각 조건이 어떤 충돌 축을 막는지 추적 가능.
3. **거버넌스 단어 수 FAIL (의도적 수용)**: `test-governance-dedup.sh` Check 3 FAIL 은 **기존 비대화(6904w)**가 본질. 본 spec +90w 는 정책 필수 최소. 6000w 는 ADR 이 아닌 테스트 휴리스틱(5000→6000 상향 전례)으로, 다이어트는 별도 Icebox 항목. walkthrough §발견사항 참조.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-governance-dedup.sh
```
**결과 요약**:
- ✅ Check 2 (sources ↔ .harness-kit 동기화): agent.md 동기화 OK
- ❌ Check 3 (단어 수 6994w > 6000w): **기존 초과 유지**, 본 spec 이 새로 깨뜨린 것 아님 (상세 walkthrough)
- ✅ Check 1·4·5·6: PASS

### 수동 검증
1. ADR-007 7종 조건 모두 수록 → ✅
2. agent.md 요지 자족성(ADR 링크 없이 의미 통함) → ✅
3. sources ↔ .harness-kit 일치 → ✅
4. 단어 수 악화 +90w(기존 6904 초과가 본질) → ✅

## 📦 Files Changed

### 🆕 New Files
- `docs/decisions/ADR-007-native-feature-adoption-policy.md`: 정책 ADR (convention)
- `specs/spec-x-native-feature-adoption-policy/*`: spec/plan/task/walkthrough/pr_description

### 🛠 Modified Files
- `sources/governance/agent.md` (+2): §6.7 네이티브 기능 게이트 보존 요지 (전파 원본)
- `.harness-kit/agent/agent.md` (+2): 도그푸딩 동기화

**Total**: 8 files

## ✅ Definition of Done

- [x] ADR-007 작성 (7종 조건 + 근거 + 대안)
- [x] agent.md 자족 요지 + ADR 참조
- [x] 도그푸딩 동기화 (sources ↔ .harness-kit 일치)
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 브랜치 push (ship 시)
- [-] 단위 테스트 — docs-only 면제. 거버넌스 정합성 테스트는 Check 2 OK / Check 3 기존 초과(별도 다이어트)

## 🔗 관련 자료

- ADR: `docs/decisions/ADR-007-native-feature-adoption-policy.md`
- 선행 조사: `spec-x-cc-native-adoption` (PR #25)
- 후속(Icebox): 거버넌스 다이어트, 검증 spec(`/background`·`/branch`)

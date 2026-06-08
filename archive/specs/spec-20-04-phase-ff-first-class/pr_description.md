docs(spec-20-04): phase-FF 를 phase 내 1급 작업 모드로 거버넌스 반영 (upstream ADR-004 parity)

## 📋 Summary

### 배경 및 목적

upstream(Changsik00) ADR-004 가 phase-FF 를 phase 내 1급 작업 모드로 정의했으나, fork 는 `0.13.6` 분기 이후 이를 반영하지 못했다. fork 는 phase-FF "용어"는 보유하지만(agent.md §11.4 재조정 옵션, fragment Good Pattern) **착수 시점 1급 구도·constitution 명문·정식 ADR 이 빠져** 있었고, fragment 는 오히려 "사용자 명시 승인 필요"로 적혀 1급화의 핵심(항목별 재승인 불요)과 충돌했다. 본 spec 이 이를 fork 거버넌스에 반영한다 (phase-20 성공기준 3).

### 주요 변경 사항

- [x] **ADR-009** 신규 — phase-FF 1급화. upstream ADR-004 parity (번호 충돌 회피) + fork 분기점 2개(notify 정합, pre-push 보수적 de-hardcode) 명시.
- [x] **constitution §3.1** — "In-Phase Work Sizing" 명문: phase 내 1–2 commit 가역 항목 = phase-FF(upfront 1급, 재승인 불요, FF Mode C 구별 — active spec 불변).
- [x] **constitution §10.2** — phase-FF pre-push 예외(보수적): 테스트 요건 유지, 개별 spec PR review 만 phase-ship 통합검증으로 이동.
- [x] **agent.md §11.4** — "In-Phase Work Sizing & Re-Adjustment"로 in-place 재구성: 착수 시점 upfront sizing 강조(재조정 표 보존).
- [x] **CLAUDE.fragment** — phase-FF 1급 격상 + "승인 필요" 제거 + notify 정합(개별 게이트 미발생).

### Phase 컨텍스트
- **Phase**: `phase-20` (upstream-parity, base 모드)
- **본 SPEC 의 역할**: 성공기준 3(phase-FF 1급 작업 모드가 fork 거버넌스에 반영) 충족.

## 🎯 Key Review Points

1. **fragment 모순 해소**: fork 가 phase-FF 를 "(사용자 명시 승인 필요)"로 적어 1급화의 "재승인 불요"와 충돌하던 것을 정정 — phase plan 이 이미 항목 실행을 위임.
2. **pre-push gate 보수적 de-hardcode**: 테스트 면제가 *아님*. 해제되는 건 per-item PR review 강제뿐(→ phase-ship). constitution §9 testing 불변.
3. **governance 비대화**: 본 spec +212w(constitution +126, agent.md +86). Check 3(6000w 상한)은 **기존부터 FAIL** — 본 spec 은 §11.4 in-place 재구성 + 간결 추가로 *악화 최소화*만. 완전 해소는 director mode(OOS).

## 🧪 Verification

### 자동 검증 (docs-only)
```bash
bash tests/test-governance-dedup.sh
# Check 1(중복0)/2(sync)/4(dead)/5(섹션)/6(sdd경로) PASS
# Check 3(word count) FAIL — 기존 비대화(+212w 악화 최소)
diff -q sources/governance/constitution.md .harness-kit/agent/constitution.md  # SYNCED
diff -q sources/governance/agent.md       .harness-kit/agent/agent.md          # SYNCED
diff -q sources/claude-fragments/CLAUDE.fragment.md .harness-kit/CLAUDE.fragment.md  # SYNCED
```

**결과 요약**: ✅ Check 1/2/4/5/6 PASS + ALL 3 SYNCED. Check 3 는 기존 FAIL(OOS).

### 수동 검증
1. 4개 문서 통독 — phase-FF 가 "착수 시점 1급 + 재승인 불요 + Mode C 구별 + pre-push 보수 예외"로 일관.
2. ADR-009 frontmatter `type: decision` + §6.4 어휘 준수.

## 📦 Files Changed

### 🆕 New Files
- `docs/decisions/ADR-009-phase-ff-first-class.md`: phase-FF 1급화 ADR

### 🛠 Modified Files
- `sources/governance/constitution.md` / `.harness-kit/agent/constitution.md`: §3.1 + §10.2
- `sources/governance/agent.md` / `.harness-kit/agent/agent.md`: §11.4 재구성
- `sources/claude-fragments/CLAUDE.fragment.md` / `.harness-kit/CLAUDE.fragment.md`: phase-FF 1급 + notify 정합

## ✅ Definition of Done

- [x] FR-1~5 반영 완료 (ADR-009 + constitution + agent.md + fragment)
- [x] `test-governance-dedup.sh` Check 1/2/5/6 PASS (Check 3 기존 FAIL)
- [x] sources↔installed 3쌍 SYNCED
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 코드 리뷰 게이트 처리
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- ADR: `docs/decisions/ADR-009-phase-ff-first-class.md`
- Walkthrough: `specs/spec-20-04-phase-ff-first-class/walkthrough.md`
- upstream 참조: ADR-004 (phase-ff-first-class)

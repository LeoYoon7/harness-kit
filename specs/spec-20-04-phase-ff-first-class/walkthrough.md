# Walkthrough: spec-20-04

> 본 문서는 *작업 기록* 입니다. 결정·협의·검증·발견을 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 통합 방식 | cherry-pick / 재작성 | **재작성(ADR-009)** | fork ADR-004=notification 과 번호 충돌 + fork notify 정합 기술 필요 |
| ADR 번호 | 004 재사용 / 신규 | **009** | fork ADR 008 까지 존재, phase plan "009+" 명시 |
| pre-push gate | 전면 de-hardcode / 보수적 | **보수적** | 테스트 요건 유지(§9 불변), 개별 PR review 강제만 phase-ship 이동 |
| §11.4 반영 | 추가 / in-place 재구성 | **in-place 재구성** | word-count 중립 지향(NFR-1, agent.md 이미 상한 초과) |
| fragment 승인 문구 | 유지 / 제거 | **"사용자 명시 승인 필요" 제거** | 1급화 = 항목별 재승인 불요(phase plan 위임). FF Mode C 와 구별 |

### ADR 승격 가이드
- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-009-phase-ff-first-class.md` (type: decision)

## 💬 사용자 협의

- **주제 1**: phase-20 잔여 작업 → 사용자 1번(phase-FF 1급화) 선택.
- **주제 2**: phase-FF work mode/scope → 사용자 1번(전체 반영: ADR-009 + constitution + agent.md + fragment + pre-push gate). Explore 조사로 gap(정식 ADR·constitution 명문·upfront 구도·pre-push 부재) 확인 후 진행.

## 🧪 검증 결과

### 1. 자동화 검증 (docs-only — TDD 대체)

#### governance 일관성
- **명령**: `bash tests/test-governance-dedup.sh`
- **결과**: Check 1(중복 0)/2(sync)/4(dead letter)/5(섹션번호)/6(sdd경로) **PASS**. Check 3(word count) FAIL.
- **로그 요약**:
```text
Check 1 중복 문장 0건 ✓
Check 2 constitution.md / agent.md 동기화 OK ✓
Check 3 합계 7285w — 상한(6000w) 초과 ❌ (기존 7073w + 본 spec +212w)
Check 5 섹션 번호 중복 없음 ✓
Check 6 sdd 경로 올바름 ✓
```

#### word-count 증가폭 (NFR-1)
- constitution.md: 2672w → **2798w** (+126, §3.1 In-Phase Work Sizing + §10.2 phase-FF 예외)
- agent.md: 4401w → **4487w** (+86, §11.4 upfront framing)
- 합계 +212w. **Check 3 는 본 spec 이전부터 FAIL**(기존 비대화) — 본 spec 은 간결 추가로 *악화 최소화*만 보장. 완전 해소는 director mode 의 agent.md 축소(OOS).

#### sync
- `diff -q` constitution / agent.md / fragment 3쌍 → **ALL 3 SYNCED**.

### 2. 수동 검증 (일관성 통독)
1. **Action**: ADR-009 + constitution §3.1/§10.2 + agent.md §11.4 + fragment 통독 — **Result**: phase-FF 가 4개 문서에서 "착수 시점 1급 + 항목별 재승인 불요 + FF Mode C 구별(active spec 불변) + pre-push 보수적 예외"로 일관 기술됨.
2. **Action**: ADR-009 frontmatter `type: decision` + §6.4 어휘 확인 — **Result**: 준수.

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-20-04-phase-ff-first-class/code-review-gemini.md` |
| **요약** | **Approve** — Critical 0 / Major 0 / Minor 0 (발견 없음). 4개 문서 phase-FF 프레이밍 일관 + FF Mode C 구별 + sources↔installed sync 확인 |

## 🔍 발견 사항

- **fragment 의 승인 문구 모순**: fork 기존 fragment 가 phase-FF 를 "(사용자 명시 승인 필요)"로 적어, upstream 의 "항목별 재승인 불요" 1급 정의와 정면 충돌하고 있었음. 본 spec 이 해소 — 1급화의 핵심 가치(재승인 마찰 제거)가 fragment 에서 무력화돼 있던 셈.
- **governance 비대화 가속**: phase-FF 반영조차 +212w 를 더함. director mode 재구현 시 agent.md 대폭 축소가 시급(Check 3 해소 + 1급화로 절감될 ceremony 토큰의 상쇄).

## 🚧 이월 항목

- governance word-count(Check 3) 완전 해소 — director mode 작업의 agent.md 축소로 위임.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-04 |
| **최종 commit** | (ship commit, push 직전) |

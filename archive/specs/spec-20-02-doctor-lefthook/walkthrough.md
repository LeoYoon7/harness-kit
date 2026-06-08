# Walkthrough: spec-20-02

> 본 문서는 *작업 기록* 입니다. 결정·협의·검증·발견을 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 검사 함수 | 포팅 / 재작성 | **포팅** | fork doctor 가 동일 helper(`_doc_warn`/`_doc_pass`/`$SDD_ROOT`) 보유 → additive 이식 |
| doctor.sh 스타일 | check_warn helper / raw printf | **raw printf** (upstream 블록 그대로) | fork doctor.sh 섹션 6 이 동일 raw-printf 스타일 → 일관 |
| 자동 수정 | git config 변경 / 진단만 | **진단만** | upstream 동일, harness 는 git 설정을 임의 변경하지 않음 |

### ADR 승격 가이드
- [x] 없음 — 진단 검사 포팅

## 💬 사용자 협의

- **주제**: phase-20 두 번째 quick win
  - **§11.3 재검증 결과**: "소규모 fix" 중 #162(doctor lefthook)는 additive·낮은 충돌, #158(footgun)은 fork check-secrets 와 중복+sdd 분기로 복잡 → **#162 만 spec-20-02 로 선정**, #158 은 별도 triage 분리.

## 🧪 검증 결과

### 1. 자동화 테스트
- **명령**: `bash tests/test-doctor-hookspath-lefthook.sh`
- **결과**: ✅ PASS 4 / FAIL 0. TDD Red(2/2 fail) → Green 전환.
- **로그 요약**:
```text
Case 1 sdd doctor → #161 경고 ✓
Case 2 doctor.sh → #161 경고 ✓
Case 3 lefthook+hooksPath 미설정 → 경고 없음 ✓
Case 4 lefthook 미사용 → 경고 없음 ✓
```

### 2. 수동 검증 (회귀)
1. **Action**: `bash .harness-kit/bin/sdd doctor` (실제 repo, lefthook 미사용) — **Result**: lefthook 줄 미출력(검사 skip) + 결과 ✅ ALL PASS → **additive, 기존 동작 무회귀**
2. **Action**: `diff -q sources/bin/sdd .harness-kit/bin/sdd` — **Result**: SYNCED (sources↔installed 동일)

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **Skip 사유** | `small-port` — upstream 검증된 진단 검사 포팅(additive) + 테스트 4/4 PASS + 회귀 없음. 신규 로직 결정 없음 |

## 🔍 발견 사항

- `doctor.sh` CRLF→LF 정규화 경고(git) — line-ending 혼재. 기능 영향 없음(테스트 PASS). 별도 위생 항목 후보.
- fork doctor 가 upstream 과 **helper 호환**(`_doc_warn`/`_doc_pass`/`$SDD_ROOT` + doctor.sh raw-printf) → governance-heavy 가 아닌 sdd 기능은 포팅이 의외로 매끄러움.

## 🚧 이월 항목

- #158(footgun 3종) triage — fork check-secrets 와 중복 가려내기 (phase-20 후속 또는 별도)

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-04 |
| **최종 commit** | ship commit (push 직전) |

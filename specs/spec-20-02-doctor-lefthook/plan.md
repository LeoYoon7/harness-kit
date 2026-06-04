# Implementation Plan: spec-20-02

## 📋 Branch Strategy

- 신규 브랜치: `spec-20-02-doctor-lefthook`
- 시작 지점: `phase-20-upstream-parity` (base 모드 — 직전 spec 머지된 phase 브랜치에서 분기)
- **base 모드**: PR base = `phase-20-upstream-parity`
- 첫 task 가 spec 브랜치 생성.

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **진단만 방침** — 충돌 감지 시 *경고·안내*만, `git config` 자동 변경 없음 (upstream 동일). 동의?
> - [ ] **포팅 방침** — fork doctor 가 동일 helper 보유 → upstream `_check_lefthook_hookspath()` 거의 그대로 이식. 동의?

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| 검사 함수 | upstream `_check_lefthook_hookspath()` **포팅** | fork doctor 가 `_doc_warn`/`_doc_pass`/`$SDD_ROOT` 보유 → additive 이식 가능 |
| sdd sources↔installed | 동일 블록 양쪽 | dogfood sync |
| 검사 시점 | `_check_hooks` 호출 직후 | upstream 과 동일 위치 (훅 파일 섹션) |

### 📑 ADR 후보
- [x] 없음 — 진단 검사 포팅

## 📂 Proposed Changes

#### [MODIFY] `sources/bin/sdd` · `.harness-kit/bin/sdd`
`cmd_doctor()` 에 `_check_lefthook_hookspath()` 정의 + `_check_hooks` 직후 호출 추가. 로직: lefthook 사용(lefthook.yml/.yaml 또는 package.json `lefthook`) 감지 → `core.hooksPath` 로컬 설정 시 `_doc_warn`(해결책 안내), 미설정 시 `_doc_pass`. git work-tree 아니면 skip.

#### [MODIFY] `doctor.sh`
root doctor 에 동일 검사 추가 (doctor.sh 의 pass/warn 컨벤션에 맞춤).

#### [NEW] `tests/test-doctor-hookspath-lefthook.sh`
upstream 테스트를 fork 에 맞게 포팅/적응. 임시 git repo 시나리오: ① lefthook + hooksPath → warn, ② lefthook + 미설정 → pass, ③ lefthook 없음 → 검사 skip.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-doctor-hookspath-lefthook.sh
```

### 수동 검증 시나리오
1. 임시 repo 에 `lefthook.yml` + `git config core.hooksPath .husky` 설정 후 `sdd doctor` 실행 — 기대: lefthook 충돌 warn.
2. 기존 doctor 출력 회귀 확인 (다른 검사 항목 영향 없음) — 기대: 무변경.

## 🔁 Rollback Plan

- additive 검사 블록 추가 → `git revert` 또는 블록 제거로 완전 가역. 기존 doctor 동작 영향 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship

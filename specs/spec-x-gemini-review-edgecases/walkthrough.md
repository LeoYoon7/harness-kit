# Walkthrough: spec-x-gemini-review-edgecases

> 작업 기록 — gemini-review.sh 엣지케이스 2종(base fallback / 비-ASCII argv) 수정 + stale Icebox 정리.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 작업 선택 (post-align) | #1 plan-mode 위반 / 엣지케이스 2종 / 기타 | **엣지케이스 2종** | #1(plan-mode)은 이미 `spec-x-gemini-review-sandbox` 로 해결됨(조사 중 발견) — 같은 스크립트의 실제 미해결 결함으로 전환 |
| (b) 지시문 전달 | argv 영어화 / argv→stdin 이동 | **stdin 이동** | argv 는 git-bash CP949 손상([[gitbash-nonascii-argv-codepage]]). 지시문 전체를 stdin 최상단으로 옮기고 `-p` 만 짧은 ASCII 영어 — 한국어 지시문 원문 보존 |
| (a) base 부재 판정 | 항상 main / base≠main+부재 시만 | **base≠main+부재 시만** | base 실재 시 무회귀. main 캐논 base 전제(리뷰 Minor-1 주석으로 한계 명시) |
| 테스트 stub | repo 내 기록 / repo 밖 CAPTURE_DIR | **repo 밖** | capture 가 워킹트리를 건드리면 sandbox 부수효과 가드가 오작동 → 격리 |
| T6 stdin 마커 | 한국어 substring / ASCII substring | **ASCII(`Feature Envy`)** | 한국어 grep 패턴 argv 도 git-bash 에서 손상 — 회피하려는 결함을 테스트에 재유입하지 않음 |
| ship 코드 리뷰 | Gemini / Opus | **Opus** | gemini 가 본 spec 의 *수정 대상* → 자기 리뷰 순환. sandbox spec 과 동일 논리 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 도구 하드닝(fix). argv-안전 원칙은 메모리 `gitbash-nonascii-argv-codepage` 에 자산화됨.

## 💬 사용자 협의

- **주제**: 작업 선택 — **합의**: 1번(엣지케이스 2종 + stale 정리). 단, 원 선택 #1(plan-mode)은 이미 해결됨을 surface 후 재조정.
- **주제**: 작업 모드 — **합의**: spec-x.
- **주제**: Plan Accept — **합의**: 1번(Accept).
- **주제**: ship 코드 리뷰 — **합의**: 1번(Opus).
- **주제**: 리뷰 권고 처리 — **합의**: 1번(Minor-1만 반영, Minor-2/3 skip).

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-gemini-review-guard.sh`
- **결과**: ✅ Passed (PASS=16 FAIL=0 — 기존 12 + 신규 T6/T7 = 4)
- **로그 요약**:
```text
T6 비-ASCII argv 안전 → argv 순수 ASCII + 지시문 stdin 전달
T7 base 브랜치 부재 → main fallback 성공(exit 0) + 리뷰 파일 생성
=== 결과: PASS=16 FAIL=0 ===
```
- **TDD 궤적**: 신규 테스트만으로 Red(PASS=12 FAIL=4) → fix(b) 후 PASS=14 → fix(a) 후 PASS=16(Green).

#### 회귀
- `bash tests/test-bash-policy-headers.sh` → ✅ ALL 4 CHECKS PASSED
- `bash tests/test-install-manifest-sync.sh` → ✅ PASS=6 FAIL=0

### 2. 수동 검증

1. **Action**: stub gemini(capture) 로 argv 캡처 → **Result**: `LC_ALL=C grep '[^[:print:][:space:]]'` 무매치(순수 ASCII), stdin 에 지시문 존재.
2. **Action**: state.json `baseBranch=phase-99-missing` 주입 후 리뷰 → **Result**: ⚠ fallback 후 main 기준 diff 로 리뷰 성공, `code-review-gemini.md` 생성.
3. **Action**: `diff -q sources/bin/gemini-review.sh .harness-kit/bin/gemini-review.sh` → **Result**: 차이 없음(parity).

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Opus — gemini 는 수정 대상이라 제외) |
| **결과 파일** | `specs/spec-x-gemini-review-edgecases/code-review.md` |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 3 |
| **Minor 처리** | Minor-1(main 캐논 base 한계 주석) → **반영**. Minor-2(T6 한국어 stdin 검증)·Minor-3(queue.md sdd 자동관리) → **skip**(필수 아님/조치 불요) |

## 🔍 발견 사항

- **plan-mode 위반 Icebox 라인이 stale** — `spec-x-gemini-review-sandbox`(2026-06-05 머지)로 이미 해결됐으나 완료 표기 누락. 본 spec 에서 정리.
- **main 캐논 base 가정** — fallback 은 base≠main 부재만 커버. default 가 master/trunk 인 저장소는 범위 외(주석 명시). 프로젝트가 main 강제라 실무 영향 낮음.

## 🚧 이월 항목

- 없음. (리뷰 Minor-2 의 T6 한국어 stdin 검증 보강은 ROI 낮아 미이월 — argv ASCII 검증이 핵심 계약 커버.)

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent(Opus orchestrator) + Opus reviewer + Leo |
| **작성 기간** | 2026-06-09 |
| **최종 commit** | `ef92490` (review Minor-1 반영, ship commit 직전) |

# Walkthrough: spec-x-review-base-config

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 설정 키 이름 | `defaultBranch` vs `integrationBase` | `defaultBranch` | GitHub "default branch" 용어 차용. `integrationBase` 는 phase `baseBranch` 와 혼동 위험 |
| base 자동 추론 (origin/HEAD) | 채택 vs 비채택 | 비채택 | 라이브 케이스 (GitHub default=main 인 채 develop 통합) 를 자동으로 못 풀 수 있음 — critique 대안 A 기각 |
| LLM 절차 base 소스 | state+installed 2-소스 합성 vs status --json 단일화 | status --json 에 defaultBranch 동봉 | LLM 절차 비결정성 제거 (critique 대안 C 핵심 반영) |
| 부재 브랜치 설정 | 거부 vs 경고-후-진행 | 경고-후-진행 | phase base just-in-time 생성 케이스 보존 + 오타 가시화 양립 |
| 2단 fallback 종착 | defaultBranch 에서 멈춤 vs 리터럴 main 종착 | 리터럴 main 종착 | 무한 체인 차단 + defaultBranch 오설정 시에도 안전 진행 (T9 가드) |
| T9 사전 PASS | Red 재설계 vs 회귀 가드로 수용 | 회귀 가드로 수용 | 현 동작도 main 종착이라 사전 PASS 는 정상 — T8 이 Red 를 담당 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — `review-base-resolution-chain` (type: tradeoff) 은 **deferred 후보**로 queue.md Icebox 에 기록 (sdd 내부 fallback 설정화 착수 시 작성, "ADR 은 트리거 대기" 관행)

## 💬 사용자 협의

- **주제**: nextmarket 세션의 Gemini 리뷰 문제 브리핑 → kit 반영 여부
  - **사용자 의견**: 1번 (spec-x — 통합 base 설정화) 선택. 멀티레포 (1b/2) 는 Icebox 분리 동의
  - **합의**: 리뷰 게이트 2종 한정 + Icebox 4건 분리
- **주제**: critique 반영 범위
  - **사용자 의견**: `all` (7건 전체)
  - **합의**: status JSON 단일화 + doctor 노출 + 실재 경고 + hk-gemini-review.md 갱신 + Out of Scope 명시 + 문구 정리 + deferred ADR 기록
- **주제**: 코드 리뷰 게이트
  - **사용자 의견**: 1번 (Gemini cross-model)
  - **합의**: Gemini 단독 실행, 결과 Approve 로 ship 진행

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-sdd-config.sh` / `bash tests/test-gemini-review-guard.sh`
- **결과**: ✅ Passed (config 14/14, guard 20/20)
- **로그 요약**:
```text
test-sdd-config:          결과: PASS=14  FAIL=0  (T7~T10 신규: 미설정 main / 설정+부재경고 / 형식 거부 / status --json 노출)
test-gemini-review-guard: 결과: PASS=20  FAIL=0  (T8: Diff (develop...HEAD) 반영, T9: main 종착 fallback)
TDD Red 증거: T7~T10 사전 FAIL=6 (9e0ecde), T8 사전 FAIL=1 (c7e3c58)
```

#### 회귀 (관련 suite)
- **명령**: `test-sdd-base-branch` / `test-review-b1` / `test-install-manifest-sync` / `test-hk-doctor`
- **결과**: ✅ Passed (4/4, 18/18, 6/6, 7/7 checks)

### 2. 수동 검증

1. **Action**: `sdd config default-branch` (미설정)
   - **Result**: `defaultBranch: main`
2. **Action**: `sdd config default-branch develop` (본 repo 에 develop 없음)
   - **Result**: `⚠ 브랜치 'develop' 가 현재 저장소에 없습니다 — 설정은 진행` + `✓ defaultBranch = develop`, 조회 시 `develop`. 이후 `main` 원복 + installed.json 잔재 (jq 재포맷) `git checkout --` 으로 원복
3. **Action**: `sdd config default-branch "bad name"`
   - **Result**: `✗ 브랜치명 형식 위반` + exit 1
4. **Action**: `sdd doctor`
   - **Result**: `✅ defaultBranch: main (리뷰 diff 기준 — sdd config default-branch)` 표기
5. **Action**: 본 spec 의 Gemini 리뷰 자체가 새 체인으로 실행됨 (`base=main` 해석 로그)
   - **Result**: 도그푸딩 라이브 검증 — 체인 정상 동작

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini) |
| **결과 파일** | `specs/spec-x-review-base-config/code-review-gemini.md` |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 2 |
| **Minor 처리** | ① PROJECT_ROOT vs SDD_ROOT 일관성 — gemini-review.sh 는 자체 기존 패턴 (PROJECT_ROOT) 유지가 정합, 수정 불요 판단. ② BASE/DEFAULT 변수 의미 주석 보강 제안 — 기존 주석 (2단 fallback 단계별) 으로 충분, 미반영 |

## 🔍 발견 사항

- gemini 실행 중 워킹트리를 수정하면 부수효과 가드 (PRE/POST status 비교) 가 오발동해 `reset --hard` 까지 갈 수 있음 — 리뷰 중 파일 작성 금지 + 사전 `git stash -u` 운영으로 회피 (기존 메모리 패턴 재확인).
- `sdd config` 계열의 jq 라운드트립이 installed.json 을 재포맷 (pretty-print) — uxMode 등 기존 키도 동일 동작이라 신규 이슈 아님. 수동 검증 후 잔재는 원복.

## 🚧 이월 항목

- 멀티레포 리뷰 지원 (2-repo diff) → `backlog/queue.md` Icebox
- sdd 내부 main fallback (`sdd:515,1908`) 설정화 + deferred ADR `review-base-resolution-chain` → Icebox
- hk-ship PR_BASE·governance main 전제 재검토 → Icebox
- hk-cleanup defaultBranch 실재 검사 → Icebox

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-12 |
| **최종 commit** | `a8b3425` (+ ship commit) |

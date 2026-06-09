# Walkthrough: spec-x-review-b1-default

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 작업 모드 | spec-x / 새 phase | **spec-x** | 설계는 #48 research 가 이미 확정 — 단일 응집 PR(커맨드+ADR+테스트)로 완결. ceremony 경제(§11.1). 사용자 선택 |
| 범위 (어느 review 커맨드) | hk-code-review 단독 / +hk-phase-review | **hk-code-review 단독** | #48 POC 는 *코드 리뷰*만 검증. phase 회고 self-consistency 는 미검증 + 비용(Opus×N over many files) |
| 페르소나 opt-in 위치 | 커맨드 내 섹션 / 별도 doc | **커맨드 co-location** | 발견성↑. 페르소나 미구현이라 분량 적음 |
| N=3 self-consistency 유지 여부 | 유지 / N=1(generalist만) | **N=3 유지(약근거 명시)** | #48 권고 A 의 문자적 구현. 단 critique 지적 수용 — generalist 가 진짜 win, N=3 은 약근거 기본값으로 정직 표기(NFR4) |
| 증류 재현성 (critique blocking) | 명문화 / 디렉터 재량 | **조작적 정의 명문화** | 규칙 없으면 매 실행 표가 달라져 self-consistency 신호 무의미. dedup/합의(N/k)/심각도충돌/이견보존 박음 |
| review-cost-adaptivity ADR | 신설 / NFR4 흡수 | **NFR4 흡수** | critique 가 "약한 권장, NFR4 흡수 가능" 판정. 미검증 적응형을 지금 ADR 로 박을 필요 없음 |
| 코드 리뷰 게이트 | 실행 / Skip | **Skip(사유 기록)** | docs/거버넌스 + grep 구조 테스트, 실행 production 코드 없음. 독립 Opus critique 가 이미 review 의도 충족 |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨:
  - `docs/decisions/ADR-013-review-value-baseline.md` (type: invariant)
  - `docs/decisions/ADR-014-review-eval-independence.md` (type: invariant)
- [ ] 없음

> 두 ADR 은 #48 가 이미 내린 방법론 결론(측정 전제 / 측정 독립성)을 형식화. cross-spec(향후 모든 리뷰 변경에 강제) + long-lived + `invariant` 어휘 해당 → 3/3 충족.

## 💬 사용자 협의

- **주제**: 작업 모드 선택
  - **사용자 의견**: 1번 (spec-x)
  - **합의**: spec-x-review-b1-default 로 진행
- **주제**: Plan Accept vs Critique
  - **사용자 의견**: 2번 (Critique 먼저)
  - **합의**: Opus 서브에이전트 critique 실행 → 외부 문헌 대조 결과 반환
- **주제**: critique 반영 범위
  - **사용자 의견**: `권장` (A~F 반영 + G=NFR4 흡수)
  - **합의**: spec/plan/task 갱신 후 Plan Accept
- **주제**: Plan Accept
  - **사용자 의견**: 1번 (Accept)
  - **합의**: Strict Loop 실행

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트 (구조 검증)
- **명령**: `bash tests/test-review-b1.sh`
- **결과**: ✅ Passed (18/18 checks, C1~C8)
- **로그 요약**:
```text
▶ C1 B1 용어 / C2 페르소나 opt-in / C3 ADR-010 / C4 미러 parity
▶ C5 ADR-013 invariant / C6 ADR-014 invariant / C7 증류 조작적 정의 / C8 fallback
=== 결과: PASS=18 FAIL=0 ===
```
- TDD 흐름: 테스트 작성 시 16 FAIL(Red) → ADR 작성 후 C5/C6 PASS(6) → 커맨드 B1 후 18 PASS(Green).

#### 회귀 테스트
- `bash tests/test-governance-dedup.sh` → ✅ 8/8 PASS (constitution/agent.md 본문 무변경 확인, 합계 6393w ≤ 6500w).
- `bash tests/test-drift-stale-adr.sh` → ✅ clean state: no stale ADR line (새 ADR 의 backtick 경로 모두 유효).

### 2. 수동 검증

1. **Action**: `cp` 후 `diff -q sources/commands/hk-code-review.md .claude/commands/hk-code-review.md`
   - **Result**: 차이 0 (도그푸딩 미러 byte-identical, ADR-003 정합).
2. **Action**: hk-code-review skill 설명 라인 확인
   - **Result**: "B1 패턴(self-consistency Opus×N + generalist 정독)" 으로 갱신 — `.claude` 미러 라이브 반영 확인.
3. **Action**: 한글 grep argv 프로브 (`grep -c "심각도" ...`)
   - **Result**: exit 0, match 4 — git-bash 의 bash→grep 경로는 CP949 손상 없음(테스트 한글 grep 안전).

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **결과 파일** | — |
| **요약** | — |
| **Skip 사유** | docs/거버넌스(ADR) + grep 구조 테스트 — 실행 production 코드 없음. 독립 Opus critique(`critique.md`)가 외부 문헌 대조까지 거쳐 review 의도를 이미 충족(blocking 갭/약근거 표면화 후 반영). B1 의 실 dogfooding 은 알고리즘 코드 변경 spec 에서 권장. |

## 🔍 발견 사항

- **N=3 약근거 정직화** — #48 데이터에서 깊이 회복 주역은 generalist(B0→B1 차이)이고 self-consistency N=3 의 비용 3배 증분은 분리 미측정. 외부 문헌(arXiv 2511.00751)도 frontier 모델에서 증분 작음. → 후속 B2 에서 N=1 vs N=3 분리 측정 권고(아래 이월).
- **동일-모델 self-consistency 비독립** — PoLL/self-preference 문헌상 correlated blind spot. cross-model(`hk-gemini-review`)이 시스템 차원 분담 — ADR-014 가 포섭.
- **증류 재현성이 B1 의 단일 최대 갭** — 합의 분포가 핵심 신호인데 dedup/충돌해소 규칙 없으면 무의미. critique 가 표면화, 본 spec 에서 조작적 정의로 해소.

## 🚧 이월 항목

- **B2 — self-consistency N 분리 측정** (N=1 vs N=3 ROI) → `backlog/queue.md` Icebox 후보.
- **적응형 N / 폭·깊이 자동 라우팅** (#48 권고 B + critique 대안 A) — 미검증·경계값 임의성으로 보류 → Icebox.
- **hk-phase-review B1 적용 검토** — 코드 리뷰 외 phase 회고에도 self-consistency 가 값하는지 별도 측정 → Icebox.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-09 |
| **최종 commit** | (ship commit 후 갱신) |

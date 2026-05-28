# Walkthrough: spec-x-gemini-review

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 기존 `/hk-code-review` 교체 vs 신규 커맨드 추가 | A) Opus 를 Gemini 로 교체 / B) 신규 `/hk-gemini-review` 추가 | B | 사용자 명시 결정 (Telegram msg #2995) — Opus 리뷰 자산 유지 + cross-validation 가능 |
| 결과 파일 분리 vs 단일 파일 | A) `code-review-gemini.md` 별도 / B) 모델 헤더 표기 단일 파일 | A | cross-validation 시 두 모델 결과 동시 보존 가능 |
| Ship pre-flight 강제성 | A) 안내만 / B) 명시적 3지선다 + [권장] | B | 사용자 "옵션으로 제시" 요청 (Telegram msg #2995) |
| `hk-pr-gh` / `hk-pr-bb` 게이트 추가 | A) hk-ship 만 / B) PR 커맨드도 | A | hk-ship 이 정상 경로 — 직접 PR 생성은 부수적 |
| Gemini 프롬프트 전달 방식 | A) `-p` argv / B) stdin + 짧은 `-p` | B | smoke test 발견: Windows argv 크기 한계 (`Argument list too long`) — stdin 전환으로 회피 |
| `.claude/commands/hk-ship.md` 라인 엔딩 | A) LF (sources 와 일치) / B) CRLF (기존 sibling 매칭) | B | 본 spec 범위 외. 정규화는 별도 spec 후속 가능. PR diff 부풀림 회피 우선 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — "cross-model 리뷰가 self-review 보다 효율적" 은 외부 연구로 정립된 사실, "기존 커맨드 유지" 는 사용자 결정. ADR 가치 낮음.

## 💬 사용자 협의

- **주제**: PR 전 / Ship 전 Gemini 리뷰 도입 검토
  - **사용자 의견**: 이론적으로 cross-model 리뷰가 self-evaluation 보다 효율적 — Gemini CLI 가 이미 설치/인증되어 있음
  - **합의**: `/hk-gemini-review` 신규 추가 + Ship pre-flight 에 선택지 옵션 제시 (사용자가 매번 선택)
- **주제**: 사전 점검 3가지 (결과 파일 위치 / pre-flight 강제성 / hk-pr 적용 범위)
  - **사용자 의견**: "다 권장대로 진행"
  - **합의**: 결과 파일 분리 / 명시적 3지선다 / hk-ship 만 손댐

## 🧪 검증 결과

### 1. 자동화 테스트

본 spec 은 bash 스크립트 + 마크다운 변경이라 자동 단위 테스트가 직접 적용되지 않습니다. 대신 dogfood smoke test 로 검증.

#### 정적 분석
- `shellcheck`: 시스템 미설치 — pre-commit hook 이 자동 skip (확인 메시지: `⚠ [staged-lint] shellcheck 미설치 — Shell lint skip`)

### 2. 수동 검증

1. **Action**: Task 2 종료 시점 `bash .harness-kit/bin/gemini-review.sh` 1차 실행
   - **Result**: 처음에는 `Argument list too long` 으로 실패. stderr 가 `/dev/null` 로 차단되어 원인 식별 안 됨.
2. **Action**: stderr 캡처 (mktemp) 로 진단 → Windows argv 크기 한계 확인
   - **Result**: 프롬프트를 `-p` argv → stdin 으로 전환. 짧은 지시문만 `-p` 로 전달.
3. **Action**: 재실행 — 정상 완료
   - **Result**: `specs/spec-x-gemini-review/code-review-gemini.md` 생성. 요약 stderr 출력 (Critical 3 / Major 1 / Minor 2).
4. **Action**: Gemini 발견사항 분류
   - **Result**: false positive (Critical 4 — Task 3/4/5 미구현 시점 영향) + 유효 발견 (Major 1 stderr 차단 [이미 fix], Minor 2 sdd 경로/grep 경직).
5. **Action**: Minor 2개 fix (sdd 경로 `$PROJECT_ROOT` 명시화, grep 패턴 `^[-*]\s+` 유연화)
   - **Result**: 적용 후 `.harness-kit/bin/gemini-review.sh` 재 sync.
6. **Action**: Task 6 시점 (최종 상태) Gemini 재실행 — §1.5 게이트 dogfood
   - **Result**: **Approve** (Critical 0 / Major 0 / Minor 0). 1차 smoke 의 false positive 4개 (Critical 4 — Tasks 3/4/5 미구현 시점 영향) 가 모두 사라짐. 본문에 grep 패턴 bold 대응 nice-to-have 1개 언급되나 권고 수준 (요약 카운트 0). 결과 파일: `specs/spec-x-gemini-review/code-review-gemini.md` (PR 비포함, 일회성 검증).
   - **검증된 가설**:
     - cross-model 리뷰가 self-evaluation 편향을 줄인다 ✓ (Major 1 [stderr 차단] 은 self-review 였다면 발견 어려운 종류)
     - Ship 직전 시점이 적절한 리뷰 타이밍 ✓ (false positive 가 사라지는 시점)

## 🔍 발견 사항

- **`.claude/commands/` 의 라인 엔딩 mixed**: 기존 main 의 `.claude/commands/*.md` 는 CRLF, `sources/commands/*.md` 는 LF. `.gitattributes` 가 `.sh` 만 LF 강제. 본 spec 범위 외 — 향후 별도 spec-x 로 normalize 가능.
- **Gemini false positive 패턴**: 본 spec 자체에 리뷰를 돌리면 *진행 중인 task* 의 미구현 변경을 "누락" 으로 판정. 이는 Ship 직전 시점이 적절한 리뷰 타이밍이라는 가설을 강화 — 모든 task 종료 후 실행해야 의미 있음.
- **gemini CLI `-p` argv 크기 한계 (Windows)**: 큰 프롬프트는 stdin 으로 전달 필요. 본 패턴은 향후 다른 Gemini 호출 (예: spec-critique 의 Gemini 화) 에도 재사용 가치.

## 🚧 이월 항목

- (없음) — 본 spec 의 모든 task 가 본 PR 안에서 종결.

> 향후 후보 (Icebox 가능):
> - `.claude/commands/*.md` LF 통일 (현재 CRLF/LF 혼재)
> - `/hk-spec-critique` 의 Gemini 화 (별도 spec)
> - `/hk-phase-review` 의 Gemini 화 (별도 spec)
> - README 에 gemini CLI 의존성 안내 추가

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent (Opus 4.7 main) + Leo |
| **작성 기간** | 2026-05-28 |
| **최종 commit** | (push 직전 갱신) |

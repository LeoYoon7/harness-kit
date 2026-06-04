# Walkthrough: spec-21-02

> 작업 기록 — 디렉터 모드 토글 스위치 포팅.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 구현 방식 | 메인 직접 / 워커 위임 | **Sonnet 워커 위임** | 기계적 포팅 — ADR-010 의 implementation-offloading 도그푸딩. 메인은 distilled 계약 검증(4축) |
| config 구현 | 신규 작성 / ux-mode 미러 | **`_config_ux_mode` 미러 + boolean** | 기존 패턴 재사용, churn 최소. `--argjson`(boolean) 으로 타입만 변경 |
| 스코프 | switch+behavior / switch-only | **switch-only** | 행동 규약은 §6.8(spec-21-03). 본 spec 은 플래그+노출만 |
| Gemini Minor 2건 | 반영 / deferred | **deferred** | 둘 다 옵션(efficiency·관찰). verdict Approve, "바로 진행 권고". test+스모크로 정상 검증된 워커 코드 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 기계적 포팅. 아키텍처 결정은 ADR-010 / ADR-011(spec-21-03) 보유.

## 💬 사용자 협의

- **주제**: 다음 spec 선택 — **합의**: §11.3 재검증 후 spec-21-02 착수 (Telegram).
- **주제**: Plan Accept — **합의**: Plan Accept (Telegram "1"), 구현 워커 위임 통지.
- **주제**: Ship 코드 리뷰 — **사용자 의견**: Gemini cross-model (Telegram "1") — **합의**: Gemini 리뷰 실행 → Approve.

## 🧪 검증 결과 (메인 — ADR-010 4축, 워커 transcript 재흡수 없이)

### 1. 자동화 테스트

#### 단위 테스트
- **명령**: `bash tests/test-director-mode.sh` (독립 재실행)
- **결과**: ✅ Passed (PASS=10 FAIL=0)
- **로그 요약**:
```text
T01/T02 커맨드+미러 · T03 조회 · T04/T05 on/off · T06/T07 toggle · T08/T09 status 행 · T10 doctor
결과: PASS=10 FAIL=0
```

#### 회귀
- **명령**: `bash tests/test-governance-dedup.sh`
- **결과**: 1/8 (Check 3 단어 예산만 baseline red — 무 NEW 회귀). spec-21-02 는 거버넌스 문서 미변경.

### 2. 수동 검증 (스모크 — installed sdd 도그푸딩)

1. **Action**: `sdd config director-mode` → **Result**: `directorMode: off` (기본값).
2. **Action**: `sdd config director-mode on` → **Result**: `✓ directorMode = on`, installed.json true.
3. **Action**: `sdd status --no-drift` → **Result**: "**Director Mode: on**" 행 노출.
4. **Action**: `sdd config director-mode off` (리셋) → **Result**: off 복귀.
5. **Action**: `diff -q sources/bin/sdd .harness-kit/bin/sdd` / `diff -q sources/commands/hk-director.md .claude/commands/hk-director.md` → **Result**: 둘 다 parity OK.

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-21-02-director-mode-switch/code-review-gemini.md` |
| **요약** | **Approve** / Critical 0 / Major 0 / Minor 2 |
| **Minor 처리** | **deferred** — #1 `_config_director_mode` `cur` jq 중복(DRY, 로직 무관·옵션) / #2 `cmd_status` jq fallback(관찰, 조치 불요). 향후 cleanup 후보 |

> base(`phase-21-director-mode`)가 spec-21-01 ship 으로 생성돼 이번엔 Gemini diff 정상. 한국어 argv 손상은 ASCII 영어 지시문 직접 호출로 회피(spec-21-01 검증 우회).

## 🔍 발견 사항

- **ADR-010 도그푸딩 성공**: 구현을 Sonnet 워커에 위임(워커 90k 토큰·72 tool use 소모) → distilled 계약(commit SHA·test 결과·이탈 노트)만 반환 → 메인은 sdd 전문 미유입 상태로 4축 검증(test 재실행 + 스모크 + 미러 대조). 본 spec 이 추가한 토글의 기반 정책을 본 작업에 그대로 적용.
- **jq 재포맷 부작용**: `sdd config director-mode` 의 jq+mv 가 installed.json 을 pretty-print 재포맷(값 동일). 스모크 흔적은 `git checkout` 으로 되돌림. 기존 `_config_ux_mode` 와 동일 동작이라 회귀 아님.
- **anchor 드리프트**: plan 의 예상 line(709/2300)과 실제(708/2337) 차이 — 워커가 인접 텍스트 match 로 정확 삽입.

## 🚧 이월 항목

- **directorMode=true 의 *행동* 규약** (§6.8 Director Mode Protocol) → spec-21-03.
- **§6.6 director/worker/scout 역할 용어 + `sdd config models`** (upstream T11/T12) → spec-21-04.
- **페르소나 리뷰 패널** (upstream T13/T14) → spec-21-05.
- **Gemini Minor #1 (DRY)** → 후속 cleanup 후보 (옵션).

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent(Opus orchestrator) + Sonnet worker + Leo |
| **작성 기간** | 2026-06-04 |
| **최종 commit** | `d605098` (ship commit 직전) |

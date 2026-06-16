# Walkthrough: spec-23-02

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| stale 판정 기준 | mtime vs frontmatter 날짜 | frontmatter `updated:`(우선)/`date:` | mtime 은 clone 시 리셋돼 false-negative. frontmatter 는 clone-stable + `updated:` 가 실제 갱신 반영 |
| 날짜 cutoff 계산 | 단일 명령 vs 이식성 분기 | GNU `date -d`/BSD `date -v` `\|\|` 분기 | macOS 1차 타깃 (BSD date). `YYYY-MM-DD` 문자열 비교로 비교 자체는 단순 |
| 고아 링크 오탐 (purpose.md 예시) | 전수 검사 vs 제외 | purpose.md 스캔 제외 + concrete 포맷만 검증 | purpose.md 는 `[[wikilink]]` *컨벤션 문서* — 그 `[[ADR-NNN]]` 등은 형식 예시(placeholder). A1 stale-ADR 오탐 교훈 |
| governance 단어수 파일 조건 | `&&`(쌍 필수) vs `\|\|`(있는 것만 합산) | `&&` 유지 | 6500 은 const+agent *합산* 예산. 한쪽만 6500 과 비교는 의미 오류 (Gemini Minor 미채택) |

### ADR 승격 가이드
- [ ] ADR 승격 대상 있음
- [x] 없음 — phase-19/ADR-012 가 컨벤션·상한 기정립. stale 정의는 본 결정 기록으로 충분.

## 💬 사용자 협의

- **주제**: spec-23-01 머지 후 진행
  - **합의**: phase-23 마저 완주 (spec-23-02 착수) → Plan Accept

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 + 통합 테스트
- **명령**: `bash tests/test-wiki.sh`
- **결과**: ✅ 14/14 PASS — (c)단어수 c-1/c-2, (a)고아링크 a-1~a-4(placeholder 오탐 방지 포함), (b)stale b-1~b-3, 템플릿 Related 4종
- **회귀**: `test-hk-doctor.sh` 7/7 · `test-doctor-ignore-coverage.sh` 10/10 (cmd_doctor 무회귀)

### 2. 수동 검증

1. **Action**: 실제 dogfood 레포 `bash sources/bin/sdd doctor`
   - **Result**: wiki/문서 건강 — `governance 단어수 6400w (상한 6500 이하)` / `wiki 링크 정합 (고아 0)` / `결정문서 최신성 OK (90일+ stale 0)` 전부 PASS. 오탐 0.

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | 실행 (Gemini cross-model) |
| **결과 파일** | `specs/spec-23-02-wiki-doctor/code-review-gemini.md` |
| **요약** | **Approve (with Comments)** — Critical 0 / Major 1 / Minor 2 |
| **Major 처리** | 빈 `docs/wiki/` glob 리터럴 → `[ -e "$_wf" ] \|\| continue` 가드 추가 (`45bfbb4`) |
| **Minor 처리** | (1) `_glob_exists` 재정의 → 무변경(호출당 1회, 비용 무시) · (2) governance `&&`→`\|\|` → 무변경(합산 예산 의미상 `&&` 가 정확) |

## 🔍 발견 사항

- 실제 wiki 의 `[[...]]` 4개가 purpose.md 컨벤션 예시(placeholder) — 오탐 방지 로직(purpose.md 제외 + concrete-format)으로 해소. A1 교훈의 재현.
- 실제 ADR/RCA 90일+ stale 0 — phase-19 가 `updated:` 를 backfill 해 최신성 유지 중으로 추정.

## 🚧 이월 항목

- 없음. (분기별 governance prune 프로토콜은 phase OOS — 기존 Icebox 유지)

## 🔗 관련 문서 (Related)
- 선행 spec: [[spec-23-01]]
- 단어수 상한: [[ADR-012]]
- wiki 스키마: [[wiki/purpose]]
- Phase: `backlog/phase-23.md`

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-16 |
| **최종 commit** | `45bfbb4` (+ ship commit) |

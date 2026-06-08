# spec-x: 코드 리뷰 게이트 — 기본 실행 + 감사형 Skip 전환

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-review-gate-default` |
| **Phase** | 없음 (spec-x, 독립 스펙) |
| **Branch** | `spec-x-review-gate-default` |
| **상태** | Planning |
| **타입** | Refactor (거버넌스 정책) |
| **Integration Test Required** | no |
| **작성일** | 2026-06-02 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

ship 직전 코드 리뷰 게이트는 두 곳에 정의돼 있다.

- `agent.md §6.3-8`: "Code Review Gate (**optional**) ... offers a review choice — Gemini / Opus / **Skip**."
- `hk-ship.md §1.5`: 매 ship 마다 Gemini / Opus / Skip 3지선다를 제시하고, [권장] 은 Gemini.

### 문제점

"optional" 에 **언제 리뷰해야 하는가를 가르는 객관적 기준이 없다**. "사용자가 Skip 할 수 있다" 는 의미일 뿐이라 다음 구조적 문제가 생긴다.

1. **트리거 부재** — 이번 ship 이 리뷰 대상이라고 강제하는 조건이 없어 순수 재량이다.
2. **마찰 비대칭** — 리뷰는 추가 1스텝(특히 Gemini 는 외부 CLI), Skip 은 즉시 push. 기본값이 Skip 으로 기운다.
3. **무감사(無監査)** — Skip 해도 어디에도 기록이 안 남아 "왜 안 했는지" 책임이 0 이다.

결과적으로 실제 운영에서 리뷰 제안 자체가 거의 발화되지 않아 게이트가 **유명무실**해졌다.

### 해결 방안 (요약)

게이트의 **기본값을 "리뷰 실행" 으로 뒤집고, Skip 을 한 줄 사유 기록을 동반하는 감사형(auditable) 행위로 전환**한다. 리뷰를 불가역적으로 강제하지 않되(여전히 Skip 가능), 누락을 *침묵이 아니라 기록되는 의도적 결정* 으로 만들어 forcing function 을 부여한다.

## 🎯 요구사항

### Functional Requirements

1. **agent.md §6.3-8 정책 개정** — "(optional)" 프레이밍을 "기본 실행 + 감사형 Skip" 으로 개정한다. Skip 선택 시 `walkthrough.md` 의 코드 리뷰 칸에 한 줄 사유 기록이 필요함을 명시한다.
2. **hk-ship.md §1.5 절차 재구성** — 기본/권장 동작을 "리뷰 실행" 으로 두고, Skip(3) 선택 시 **한 줄 사유를 받아 walkthrough 에 기록**하도록 절차를 명시한다. 3지선다 구조(Gemini/Opus/Skip) 자체는 유지한다.
3. **walkthrough.md 템플릿에 "코드 리뷰" 기록 칸 추가** — 수행(Gemini/Opus + 결과 파일 링크) 또는 Skip(사유 한 줄) 을 남기는 칸을 신설한다.
4. **ADR-006 작성** — 본 정책 결정을 `docs/decisions/ADR-006-code-review-gate-default-run.md` (type: decision) 로 기록한다. 기각된 대안(순수 optional 유지 / 완전 강제 / 스코프 트리거)과 근거를 포함한다.

### Non-Functional Requirements

1. **설계 의도 양립** — 리뷰를 Skip 불가로 만들지 않는다. `agent.md §6.3` 의 *optional gate* 의도와 충돌하지 않도록, "기록을 동반한 Skip" 까지만 강제한다.
2. **과도한 마찰 방지** — docs/markdown-only 변경은 Skip 사유 `docs-only` 한 단어로 충분함을 가이드에 명시한다.
3. **회귀 없음** — hk-ship 의 나머지 흐름(품질 게이트 §2 / Ship Commit §3 / Push §4 / PR §5)에 영향이 없어야 한다.

## 🚫 Out of Scope

- **스코프 기반 자동 트리거** (diff 크기·파일 타입으로 리뷰 *강제 여부* 를 기계 판정) — 검토 시 방향 1 로 분류돼 기각. 본 spec 제외.
- **완전 강제(mandatory, Skip 불가)** — 설계 의도와 충돌. 본 spec 제외.
- **Critical 하드 게이트** (리뷰에서 Critical 발견 시 "무시하고 ship" 옵션 제거) — 별개 관심사. 필요 시 Icebox 후보로 분리.
- **설치본 동기화** (`.harness-kit/`, `.claude/`) — `update.sh` 책임(ADR-003 도그푸드 동기화 정책). 본 spec 은 `sources/` 원본만 변경.

## 📑 ADR 후보 (Architecture Decision Records)

- [x] ADR 가치 있는 결정 있음 → 후보 한 줄 요약: `code-review-gate-default-run` (type: **decision**)
- [ ] 없음

## ✅ Definition of Done

- [ ] FR 1~4 모두 반영 (`agent.md` / `hk-ship.md` / `walkthrough.md` / ADR-006)
- [ ] docs-only 변경이므로 단위 테스트 N/A — 대신 grep 검증(문구 반영) + 수동 일관성 확인 통과
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-review-gate-default` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료

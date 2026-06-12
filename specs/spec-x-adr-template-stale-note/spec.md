# spec-x-adr-template-stale-note: ADR 템플릿 note 예시의 stale-ADR 자가-트리거 해소

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-x-adr-template-stale-note` |
| **Phase** | 없음 (Solo Spec) |
| **Branch** | `spec-x-adr-template-stale-note` |
| **상태** | Planning |
| **타입** | Fix |
| **Integration Test Required** | no |
| **작성일** | 2026-06-12 |
| **소유자** | Leo |
| **연관 이슈** | #55 |

## 📋 배경 및 문제 정의

### 현재 상황

`sources/templates/adr.md:10` 의 boilerplate note 가 예시 경로를 inline backtick 으로 표기한다.

```
> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로 (예: `src/foo.ts`) 는 ...
```

이 note 는 stale-ADR 검사 규칙을 *설명*하는 문구다. 그런데 예시 토큰 `` `src/foo.ts` `` 자체가 검사 대상 패턴 (inline backtick + 슬래시 + 확장자) 을 충족하면서 실존하지 않는 경로다.

### 문제점

`_drift_stale_adr()` (`sources/bin/sdd:377`) 는 `docs/decisions/ADR-*.md` 본문의 backtick 토큰을 추출해 실재하지 않으면 stale 로 보고한다. 템플릿 note 를 복사한 모든 다운스트림 ADR 은 `` `src/foo.ts` `` 때문에 **영구 stale (false-positive)** 로 보고된다 (이슈 #55: 다운스트림 ADR 2건 실증).

> 범위 메모: 본 repo 의 `docs/decisions/ADR-*.md` 는 이미 안전하다 (ADR-013 류는 실존 경로 예시, ADR-002 류는 트리거 토큰 없음). 트리거 토큰은 **템플릿 2곳** (`sources/templates/adr.md`, dogfood 사본 `.harness-kit/agent/templates/adr.md`) 에만 존재한다. 즉 kit 측 결함은 템플릿이며, 회귀 방지의 핵심은 "템플릿 note 가 미래에도 자가-트리거하지 않음" 을 보장하는 것이다.

### 해결 방안 (요약)

템플릿 note 의 예시를 **backtick 없는 평문**으로 표기해 휴리스틱 추출 대상에서 제외한다 (휴리스틱은 backtick 토큰만 추출). 동시에 note 에 `../` 상대경로 제외 규칙을 명시 (정확도 보강). 휴리스틱 자체는 변경하지 않는다 (template content fix 로 충분, 리스크 최소). dogfood 사본 동기. 회귀 테스트는 **라이브 템플릿 note 를 fixture ADR 에 삽입해** stale 미보고를 단언 (미래 재발 차단).

## 🎯 요구사항

### Functional Requirements

1. `sources/templates/adr.md` note 의 예시 경로 `` `src/foo.ts` `` 를 backtick 없는 평문 표기로 교체 — 휴리스틱 추출 대상에서 제외.
2. note 에 `../` 로 시작하는 상대경로가 검사 제외 대상임을 명시 (휴리스틱 규칙 4 와 정합 — 문서 정확도 보강).
3. note 의 교육적 의도 보존 — "inline backtick 경로는 검사 대상" 설명 + 패턴 (inline backtick + 슬래시 + 확장자) 안내는 유지.
4. `.harness-kit/agent/templates/adr.md` (dogfood 사본) 동기 반영.
5. 회귀 테스트: `tests/test-drift-stale-adr.sh` 에 **라이브 템플릿 note 를 삽입한 fixture ADR 이 stale 로 보고되지 않음**을 검증하는 Step 추가. 미래에 누군가 트리거 예시를 재도입하면 실패해야 한다.

### Non-Functional Requirements

1. bash 3.2+ 호환, 신규 의존성 없음.
2. `_drift_stale_adr()` 휴리스틱 로직 무변경 — 기존 Step 1~6 전부 PASS 유지.
3. 키트 원본 (`sources/templates/`) 과 dogfood 결과 (`.harness-kit/agent/templates/`) 동기.

## 🚫 Out of Scope

- **휴리스틱에서 blockquote/note 라인 제외** (이슈 수정안 후보 ③) — 휴리스틱 변경은 의도치 않은 제외 위험 + Step 1~6 회귀 부담. 템플릿 fix 로 충분하므로 채택 안 함.
- **기존 다운스트림 ADR 의 stale 토큰 일괄 정리** — 다운스트림 소관 (이슈 작성자가 로컬 평문화로 해소 보고). kit 은 템플릿만 책임.
- **monorepo sibling 레포 소관 경로 false-positive** (이슈 "연관 개선 후보") — stale-ADR 휴리스틱이 system 루트 기준이라 sibling 레포 경로 (예: api 레포 업로드 디렉토리) 를 missing 으로 오판. 멀티레포 인식 부재 — 별도 검토. Icebox 등록.

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — 템플릿 문구 1곳 fix + 회귀 테스트. routine.

## 🔍 Critique 결과 (선택)

미실행 (단순 fix — Plan Accept 시 사용자 판단).

## ✅ Definition of Done

- [ ] `tests/test-drift-stale-adr.sh` 전체 PASS (신규 Step 포함)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-x-adr-template-stale-note` 브랜치 push 완료 + PR (`Fixes #55`)
- [ ] 사용자 검토 요청 알림 완료

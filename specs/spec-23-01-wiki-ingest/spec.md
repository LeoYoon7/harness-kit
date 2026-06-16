# spec-23-01: hk-wiki-ingest 슬래시 커맨드 & 템플릿 wikilink 연동

## 📋 메타

| 항목 | 값 |
|---|---|
| **Spec ID** | `spec-23-01` |
| **Phase** | `phase-23` |
| **Branch** | `spec-23-01-wiki-ingest` |
| **상태** | Planning |
| **타입** | Feature |
| **Integration Test Required** | no (phase 통합 테스트 `test-wiki.sh` 는 spec-23-02. 본 spec 의 sdd 변경은 자체 단위 테스트로 검증) |
| **작성일** | 2026-06-16 |
| **소유자** | Leo |

## 📋 배경 및 문제 정의

### 현재 상황

phase-19 가 `docs/wiki/` 토대(`index`·`log`·`decisions`·`patterns`·`purpose` 5페이지)와 `[[wikilinks]]` 컨벤션을 부트스트랩했으나, wiki 를 *갱신*하는 표준 워크플로가 없다. 한 번 합성된 wiki 는 이후 archive 가 쌓여도 stale 해진다.

또한 artifact 템플릿의 Related(관련 문서) 연결 상태가 불균일하다 (실측 2026-06-16):
- `sources/templates/adr.md`(L42), `rca.md`(L26): `## 🔗 Related` 섹션 **보유** — 단 `[[wikilink]]` 컨벤션은 미반영.
- `sources/templates/spec.md`, `walkthrough.md`: Related 섹션 **부재**.

### 문제점

- **wiki stale 위험**: archive 후 wiki 갱신이 임의(ad-hoc)라 raw↔wiki 가 어긋나고, "결정 즉시 참조"라는 wiki layer 의 목적이 무너진다.
- **역참조 단절**: spec/walkthrough 산출물이 `[[wikilink]]` 로 wiki·ADR·다른 spec 을 가리키지 않아, 지식 그래프의 raw→wiki 간선이 끊긴다.

### 해결 방안 (요약)

archive 후 Claude 가 wiki 를 갱신하는 표준 슬래시 커맨드 `/hk-wiki-ingest` 를 신설하고, 4개 artifact 템플릿이 일관된 `[[wikilink]]` "관련 문서" 섹션을 갖도록 정비한다. `sdd archive` 완료 시 ingest 를 권장하는 후처리 힌트를 출력해 워크플로를 연결한다.

## 🎯 요구사항

### Functional Requirements

1. `sources/commands/hk-wiki-ingest.md` 신규 슬래시 커맨드 — 4단계 워크플로를 명시: ① 최근 archived spec 의 `walkthrough.md` 읽기 → ② `docs/wiki/decisions.md`·`patterns.md` 갱신(walkthrough 원문 인용 + "출처: spec-XX §결정" 명시) → ③ `docs/wiki/log.md` 인제스트 이벤트 기록 → ④ `docs/wiki/index.md` 카탈로그 갱신.
2. `sources/templates/spec.md`·`walkthrough.md` 에 "## 🔗 관련 문서 (Related)" 섹션 신규 추가 — `[[spec-id]]`·`[[ADR-NNN]]`·`[[wiki/page]]` 작성 가이드 포함.
3. `sources/templates/adr.md`·`rca.md` 의 기존 `## 🔗 Related` 섹션에 `[[wikilink]]` 컨벤션 사용 가이드 보강(섹션 중복 신설 금지 — 기존 섹션 강화).
4. `sources/bin/sdd` `cmd_archive` 완료 출력 직후, `docs/wiki/` 존재 시에만 `→ /hk-wiki-ingest 로 wiki 갱신 권장` 힌트 한 줄 출력.

### Non-Functional Requirements

1. bash 3.2+ 호환 (`#!/usr/bin/env bash`, bash4+ 기능 금지) — sdd 변경분 한정.
2. `docs/wiki/` 미존재 프로젝트(외부 install 대상)에서 archive 힌트는 silent skip — 노이즈 0.
3. 모든 산출물 한국어 (코드/경로/기술 용어 제외).

## 🚫 Out of Scope

- `sdd doctor` wiki 점검 3종 + `test-wiki.sh` → **spec-23-02**.
- `docs/wiki/` 페이지 내용 자체의 대규모 재합성 (본 spec 은 *워크플로/연결*만 제공, 실제 인제스트 실행은 커맨드 사용 시점).
- governance prune 프로토콜, CLAUDE.md 슬림화 (phase OOS / 이미 완료).

## 📑 ADR 후보 (Architecture Decision Records)

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — phase-19 가 이미 wiki 컨벤션/스키마를 정립. 본 spec 은 그 운영 도구로 신규 아키텍처 결정 없음.

## ✅ Definition of Done

- [ ] `hk-wiki-ingest.md` 커맨드 + 템플릿 4종 Related 정비 완료
- [ ] `sdd archive` 힌트 단위 테스트 PASS (`docs/wiki/` 유/무 양 케이스)
- [ ] `walkthrough.md` 와 `pr_description.md` 작성 및 ship commit
- [ ] `spec-23-01-wiki-ingest` 브랜치 push 완료
- [ ] 사용자 검토 요청 알림 완료

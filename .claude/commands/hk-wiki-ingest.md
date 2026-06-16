---
description: archive 후 docs/wiki/ 지식 레이어를 최신화 — archived walkthrough 를 읽고 decisions/patterns 증류 + log/index 갱신
---

`sdd archive` 로 완료 spec 을 정리한 뒤, 이 명령으로 `docs/wiki/` 지식 레이어를 갱신합니다.
`docs/wiki/` 는 "human curates, LLM maintains" 원칙의 증류 레이어입니다 — raw 산출물(archive)에서 *의미 있는 결정·패턴만* 뽑아 새 세션이 즉시 참조하게 합니다 (스키마/컨벤션: `docs/wiki/purpose.md`).

> `docs/wiki/` 가 없으면 (phase-19 wiki 부트스트랩 미적용 프로젝트) 이 명령은 적용 대상이 아닙니다. 먼저 wiki 레이어를 만들어야 합니다.

## 1. 대상 식별 (archived walkthrough 읽기)

직전 `sdd archive` 로 `archive/specs/` 에 새로 들어온 spec 들을 확인하고, 각 `walkthrough.md` 의 **결정 기록 / 발견 / carry-over** 섹션을 읽습니다.

```bash
git -C . log --oneline -1 --name-only | grep '^archive/specs/'
```

> 증류 원칙: 모든 spec 을 링크하지 않습니다. *반복되거나 중요한* 결정·패턴만 대상.

## 2. 증류 갱신 (decisions.md / patterns.md)

archived walkthrough 에서 뽑은 내용을 `docs/wiki/decisions.md`(핵심 결정), `docs/wiki/patterns.md`(good/anti-pattern)에 반영합니다.

- **본문 인용 필수** (hallucination 방지): walkthrough 원문을 인용하고 `출처: spec-NN-NN §결정` 을 명시합니다.
- **frontmatter `sources:` 갱신**: 합성에 사용한 원본 문서 경로를 추가합니다.
- **`[[wikilinks]]` 연결**: 관련 ADR/RCA/spec 을 `[[ADR-NNN]]`·`[[RCA-NNN]]`·`[[spec-NN-NN]]`·`[[wiki/page]]` 로 링크합니다.
- **`updated:` 갱신**: 오늘 날짜.

## 3. 인제스트 이벤트 기록 (log.md)

`docs/wiki/log.md` 에 이번 인제스트 이벤트를 **append** 합니다 (이력 보존 — 기존 항목 수정 금지).

```
## YYYY-MM-DD
- 대상: spec-NN-NN, spec-NN-NN
- 갱신: decisions.md (결정 N건), patterns.md (패턴 M건)
```

## 4. 인벤토리 갱신 (index.md)

`docs/wiki/index.md` 의 wiki 페이지 + ADR/RCA 인벤토리를 최신 상태로 refresh 합니다 (신규 ADR/RCA 추가분 반영, 카운트 갱신).

## 5. 결과 보고

갱신 내용을 사용자에게 보고합니다:

```
✅ wiki 인제스트 완료
  - 대상 spec: N개 (archive/specs/)
  - decisions.md: 결정 N건 추가/갱신
  - patterns.md: 패턴 M건 추가/갱신
  - log.md / index.md 갱신됨
```

> 💡 wiki 내용 정확성은 사람이 최종 검증합니다 (LLM 유지 + human curates). 의심스러운 합성은 walkthrough 원문과 대조하세요.
> 💡 `sdd doctor` 가 고아 `[[wikilink]]` / stale 결정문서를 점검합니다 (spec-23-02 이후).

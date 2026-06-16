---
id: ADR-015
type: tradeoff
date: 2026-06-16
status: accepted
---

# ADR-015: base 브랜치 해석 체인 (review/ship/cleanup 공통 기준)

## 📚 Context

harness-kit 의 여러 경로(머지 감지, 리뷰 게이트 diff, hk-ship PR 타깃, hk-cleanup 점검)는 "통합 base 브랜치" 를 기준으로 동작한다. base 후보는 세 군데서 온다: phase base 브랜치(state.json `baseBranch`), 통합 base 설정(`.harness-kit/installed.json` `defaultBranch`, `sdd config default-branch`), 그리고 최후의 리터럴 `main`. spec-x-review-base-config 가 `defaultBranch` 인프라를 도입했으나 일부 경로가 여전히 `main` 을 하드코딩해 fork/비-main 기본 브랜치 환경에서 어긋났다. 또한 해석 우선순위가 경로마다 제각각이라 단일 기준을 자산화할 필요가 있었다.

## 🎯 Decision

base 해석을 단일 체인으로 통일한다: **`state.baseBranch` (phase) → `installed.json` `defaultBranch` → 리터럴 `main`**. 각 후보는 `git rev-parse --verify` 로 실재를 확인하고, 미존재면 다음 단계로 fallback 한다 (2단). 자동추론(`git symbolic-ref refs/remotes/origin/HEAD`)은 채택하지 않는다. 참고: 여기서 말하는 `defaultBranch` 는 *리뷰/PR base 기준* 설정으로, git 의 `init.defaultBranch`(신규 repo 생성 시 초기 브랜치명)와 의미가 다르다.

## 📊 Consequences

- **긍정**: fork/비-main 환경에서 머지 감지·PR 타깃·정리 점검이 일관 동작. 단일 해석 규칙이 ADR 로 자산화되어 향후 신규 경로가 동일 기준을 따른다. ref-실재 확인으로 base-branch 모드 phase 의 첫 spec(base 브랜치 JIT 미생성, constitution §3.1)에서 머지 감지 무음 실패를 방지.
- **부정 (감수)**: 현재 동일 해석 패턴이 `sources/bin/sdd` 의 `_resolve_base_branch()`, `sources/bin/gemini-review.sh`(독립 실행 스크립트), sdd 의 review-gate state_dump 에 **물리적으로 3벌** 존재한다. lib/ 단일 함수화는 gemini-review 의 독립성을 깨고 본 spec(1-PR refactor) 범위를 넘으므로 보류 — 다음 트리거(origin/HEAD 재고, 신규 소비처 추가 등) 시 재평가한다.
- **중립**: `defaultBranch` 미설정 시 `main` 폴백이라 기존 사용자(및 dogfood, defaultBranch=main)는 무영향.

## 🔀 Alternatives

- **origin/HEAD 자동추론 (`git symbolic-ref refs/remotes/origin/HEAD`)**: 원격 기본 브랜치를 ref 로 조회 — 비채택 이유: 이 심볼릭 ref 는 `git remote set-head` 를 해야 채워지고 갓 clone/CI fixture 에서는 부재해 에러·오진단을 낸다 (명시 설정보다 불안정). `anthropics/claude-code` #31614 도 `init.defaultBranch` 와 remote HEAD 혼동 사례.
- **lib/base.sh 신설 + 전역 source (완전 DRY)**: 비채택 이유: gemini-review.sh 독립성 파괴 + 도그푸딩 검증 전 추상화(YAGNI). 부채로 가시화 후 다음 트리거에 재평가.
- **테스트 임계 현실화만 / 하드코딩 유지**: 비채택 이유: 구조 부채를 숨길 뿐 fork 환경 불일치를 해결하지 못함.

## 📌 Status

Accepted (2026-06-16, spec-x-defaultbranch-consistency 머지 시점). 첫 사용자: `sources/bin/sdd` `_resolve_base_branch()` + hk-ship/hk-cleanup 커맨드 + constitution §3.2/§3.3.

## 🔗 Related

- spec-x-defaultbranch-consistency (본 ADR 도입 spec) · spec-x-review-base-config (`defaultBranch` 인프라 도입)
- `sources/bin/gemini-review.sh` (체인 + 2단 ref-fallback 레퍼런스)

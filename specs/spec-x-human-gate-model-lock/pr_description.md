# fix(spec-x-human-gate-model-lock): lock human-approval gates from model self-invocation

## 📋 Summary

### 배경 및 목적

Claude Code 의 SlashCommand/Skill tool 로 모델이 커스텀 커맨드를 자가 호출할 수 있다. 검증 결과 harness-kit 의 `/hk-*` 는 전부 `description` 보유 + `disable-model-invocation` 0건 → **기본 model-invocable**. 그 결과 **`/hk-plan-accept`**(사람 승인 게이트, constitution §5.2/§5.3)·**`/hk-phase-ship`**(go/no-go, §3.1)을 에이전트가 *자가 호출 = 자가 승인* 하면 게이트가 우회된다. 본 PR 은 그 구멍을 닫는다.

### 주요 변경 사항

- [x] `/hk-plan-accept`·`/hk-phase-ship` frontmatter 에 **`disable-model-invocation: true`** (원본 `sources/commands` + 설치본 `.claude/commands` 동기화)
- [x] 사용 playbook §1.5 정정 — 기준을 SlashCommand/Skill tool 로 교정, `/workflows`·`/code-review ultra`→👤, `/batch`·`/hk-*`→🤖, 레버 명시 (sources/governance + .harness-kit/agent 동기화)
- [x] `ADR-008` (type: invariant) — 사람 게이트 model-invocable 금지

### Phase 컨텍스트
- **Phase**: 없음 (spec-x, Fix·거버넌스 하드닝)

## 🎯 Key Review Points

1. **메커니즘 가정**: `disable-model-invocation` 이 `.claude/commands/*.md`(스킬 아닌 커맨드)에 실제 적용된다는 가정(두 출처가 commands↔skills 호환 명시). 안 먹으면 무효 — plan 🛑 에 Hard Stop 명시.
2. **잠금 범위의 정합성**: 사람 게이트 2개만 잠그고 post-accept 위임 커맨드(`/hk-ship`·`/hk-pr-*`)는 model-invocable 유지 — constitution §7.1 과 일치하는가.
3. **settings 권한 보류 판단**: 도구명(SlashCommand vs Skill)·syntax 불확실로 권한 화이트리스트는 별도 — frontmatter 만으로 게이트가 닫히는가.

## 🧪 Verification

```bash
grep -l "disable-model-invocation: true" sources/commands/hk-plan-accept.md sources/commands/hk-phase-ship.md .claude/commands/hk-plan-accept.md .claude/commands/hk-phase-ship.md   # → 4/4
bash tests/test-governance-dedup.sh   # Check 2(동기화) PASS; Check 3(단어수) FAIL 은 기존 비대화, 본 spec 영향 0
diff sources/governance/native-feature-usage.md .harness-kit/agent/native-feature-usage.md   # SYNC OK
```

- 단위 테스트: 해당 없음 (docs/config, constitution §9.1 justified)
- 메커니즘은 ship 전 docs 로 검증 (claude-code-guide + 외부 docs 교차)

## 📦 Files Changed

### 🆕 New Files
- `docs/decisions/ADR-008-human-gate-model-invocation.md`
- `specs/spec-x-human-gate-model-lock/{spec,plan,task,walkthrough,pr_description}.md`

### 🛠 Modified Files
- `sources/commands/hk-plan-accept.md` · `sources/commands/hk-phase-ship.md` (+1 each): `disable-model-invocation: true`
- `.claude/commands/hk-plan-accept.md` · `.claude/commands/hk-phase-ship.md` (+1 each): 설치본 동기화
- `sources/governance/native-feature-usage.md` · `.harness-kit/agent/native-feature-usage.md`: §1.5 검증 정정

## ✅ Definition of Done

- [x] 게이트 커맨드 frontmatter (원본+설치본 4파일)
- [x] playbook §1.5 정정 + 동기화
- [x] ADR-008 작성
- [x] (docs/config — 단위 테스트 해당 없음) 동기화 회귀 무 확인
- [x] walkthrough / pr_description ship
- [x] 브랜치 push
- [x] 사용자 검토 요청 알림

## 🔗 관련 자료

- ADR: `docs/decisions/ADR-008-human-gate-model-invocation.md`, `ADR-007`(호출 주체 구분), `ADR-006`(convention 은 시든다 전례)
- playbook: `.harness-kit/agent/native-feature-usage.md` §1.5

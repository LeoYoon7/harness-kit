# Walkthrough: spec-x-human-gate-model-lock

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 게이트 잠금 메커니즘 | settings deny / 커맨드→스킬 전환 / `disable-model-invocation` frontmatter | **frontmatter** | 두 출처 합의 robust 레버, 도구명·syntax 논쟁 무관, 사람 호출 무영향 |
| 잠금 범위 | 모든 /hk-* / 사람 게이트만 | **사람 게이트만** (`/hk-plan-accept`·`/hk-phase-ship`) | post-accept 위임 커맨드(ship·pr)는 model-invocable 유지가 정합(§7.1) |
| settings 권한 레이어 | 포함 / 보류 | **보류** | SlashCommand vs Skill tool 이름·권한 syntax·기본 posture 가 출처 간 불일치 — frontmatter 만으로 게이트는 닫힘 |
| ADR 형태 | ADR-007 amendment / 신규 ADR | **신규 ADR-008 (invariant)** | "사람 게이트 model-invocable 금지" 는 기능 채택(ADR-007)과 별개 불변식 |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-008-human-gate-model-invocation.md` (type: invariant)
- [ ] 없음

## 💬 사용자 협의

- **주제**: 네이티브 커맨드를 에이전트가 직접 실행 가능한가 (사용자가 외부 docs 검증 답변 공유)
  - **사용자 의견**: SlashCommand tool 로 커스텀 커맨드 model-invocable — 제 §1.5 분류가 불완전
  - **합의**: 검증 후, model-invocable 인 사람 게이트(`/hk-plan-accept`·`/hk-phase-ship`)를 `disable-model-invocation` 으로 잠금
- **주제**: 작업 모드 / 잠금 범위
  - **사용자 의견**: 1 (SDD-x), `/hk-plan-accept`·`/hk-phase-ship` 잠금
  - **합의**: SDD-x, 검증을 선행(planning research)한 뒤 spec → Plan Accept(1)

## 🧪 검증 결과

### 1. 자동화 테스트

#### 거버넌스 정합성 (governance/ 파일 편집분 회귀)
- **명령**: `bash tests/test-governance-dedup.sh`
- **결과**: ❌ 1/8 FAIL (Check 3 단어 수) — **본 spec 회귀 아님** (constitution/agent.md 미변경)
- **로그 요약**:
```text
Check 2: sources ↔ .harness-kit 동기화  ✅ PASS
Check 3: 단어 수 7021w  ❌ (기존 비대화, 본 spec 영향 0 — native-feature-usage 는 카운트 대상 아님)
```

### 2. 수동 검증

1. **Action**: SlashCommand/Skill tool 메커니즘 docs 검증 (claude-code-guide) + harness-kit 상태 확인
   - **Result**: `disable-model-invocation: true` 가 모델 호출 차단(양 출처 합의). `/hk-*` 전부 description 보유·opt-out 0건 → 기본 model-invocable. `/hk-plan-accept` 자가 승인 우회 가능 확인. 내장(`/background`·`/branch`·`/effort` 등)은 모델 호출 불가(유리한 보정)
2. **Action**: `grep -l "disable-model-invocation: true"` (4개 파일)
   - **Result**: ✅ 4/4 (원본 2 + 설치본 2)
3. **Action**: playbook §1.5 정정 후 `diff sources ↔ .harness-kit`
   - **Result**: ✅ SYNC OK

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **결과 파일** | N/A |
| **요약** | N/A |
| **Skip 사유** | `docs-only` — 커맨드 frontmatter 1줄 + docs(playbook/ADR), 실행 코드 변경 없음 (agent.md §6.3.8) |

## 🔍 발견 사항

- **검증이 적합도 분석을 좋은 쪽으로 보정**: `/effort ultracode`·`/background`·`/branch` 는 순수 내장 → 에이전트가 자율로 못 켬. verify spec(ADR-007 Amendment)이 우려한 "모델 자율 멀티모델 override" 는 *사람이 켤 때만* 발생 → 자율 오용 위험 해소.
- **진짜 forcing/control 레버**: 세션 내내 논의한 "convention 은 시든다 / 강제 가능한가" 의 답 — `disable-model-invocation` + SlashCommand 권한이 category-1(`/hk-*`·skills)의 *실제* 통제 수단. hk-code-review(ADR-006) 의 "optional→default-run" 과 같은 결의 게이트 잠금.

## 🚧 이월 항목

- **회귀 가드 미비** — 신규 사람-게이트 커맨드에 `disable-model-invocation` 누락 방지 doctor/test 점검. ADR-008 Consequences 에 명시 → `backlog/queue.md` Icebox 후보.
- **settings SlashCommand/Skill 권한 화이트리스트** — 도구명·syntax 확정(별도 docs 검증) 후 defense-in-depth 레이어로 추가 검토. Icebox.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-04 ~ 2026-06-04 |
| **최종 commit** | ship commit (push 직전) |

# Spec Critique: spec-21-01

> 독립 시니어 아키텍트 검토. 검토 대상: `specs/spec-21-01-context-orchestration/spec.md` (+ plan.md).
> scoped brief 의 고정 제약(net-neutral 스코핑, 영어 거버넌스/한국어 ADR, ADR-010 번호, 모델 표 불변)은 전제로 수용하고, 그 *위에서* 비판한다.

## 1. 유사 기법 조사

### 발견된 패턴/도구

- **Anthropic Multi-Agent Research System (Lead Researcher + subagents)**: lead agent 가 전략을 세우고 subagent 에 위임, 각 subagent 는 자기 context window 에서 탐색 후 *distilled finding* 만 반환. 내부 평가에서 single-agent 대비 90.2% 향상, 다만 토큰 ~15배 소모. — 현재 spec 과의 비교: 본 spec 의 5축(위임/scoped slice/distilled/검증/fan-out)과 **거의 1:1 대응**. 특히 "raw 탐색이 아니라 합성을 반환"이 3축과 동일. 즉 5축은 업계 검증된 패턴의 충실한 포팅이며 발명이 아님 — *과잉 설계 아님*의 강한 방증. 단 Anthropic 사례가 강조하는 "토큰 15배 비용"은 본 spec 에 비용/임계 언급이 없음(아래 누락 참조).
- **Orchestrator–Worker (Intelligence Patterns / Arize / Azure AI agent patterns)**: orchestrator 가 decomposition 을 독점하고 worker 는 sub-worker 를 spawn 하지 못함(visibility 부재 → scope 결정 불가). 체이닝은 orchestrator 에서만. — 현재 spec 과의 비교: 본 spec 은 "worker 가 또 위임하면 안 된다"(no nested dispatch)를 *명시하지 않음*. 5축이 단방향 위임을 암시하지만 불변식으로 박혀있지 않다. upstream §6.8 rule 6 "No over-dispatch"가 이를 일부 커버하나 그건 spec-21-03.
- **Fan-out 실패 모드 문헌 (qubytes / Temporal / Build5Nines)**: 가장 흔한 실패는 worker hang/silent timeout. 권고: 모든 worker invocation 에 deadline, 미응답 시 orchestrator 가 failed 표기 + fallback. distilled 스키마에 `completion_status`(full/partial/inferred) 필드를 둬서 "구조적으로는 valid 하나 epistemically weak"한 결과를 orchestrator 가 잡아낼 수 있게 함. partial-failure 정책(3개 중 2개로 진행) 명시 필요. — 현재 spec 과의 비교: 본 spec 의 3축 distilled contract 는 SHA/test status/decisions 만 규정하고 **성공/실패 상태·부분 실패·타임아웃을 다루지 않음**(아래 누락 1·2 의 직접 근거).

### 시사점

5축 자체는 업계 표준(Anthropic lead-researcher, orchestrator–worker)의 정확한 재현이라 **방향성은 견고**하다. 그러나 동일 문헌이 한목소리로 강조하는 *failure/partial/completion-status* 차원이 5축에 빠져 있다. 다만 이 갭의 상당 부분은 phase-21 의 §6.8 protocol(spec-21-03, 검증 불변식)으로 의도적으로 이연됐으므로, 본 spec 의 책임은 "5축 골격을 세우되 failure 차원의 *자리(hook)* 를 남겨두는 것"으로 한정하는 게 현실적이다. 전부 본 spec 에 넣으라는 비판은 phase 분해를 거스른다.

## 2. 요구사항 비판

### 누락

1. **[중] distilled contract 의 완료/실패 상태 필드 부재**: 3축이 "commit SHA · test status · key decisions"만 규정. worker 가 *실패*했을 때 무엇을 반환하는지(예: `completion_status: full|partial|failed`)가 없다. test status 가 "401 PASS"인지 "13 FAIL"인지는 담기지만, worker 가 *작업을 끝내지 못한* 경우(타임아웃·도구 접근 상실)의 계약이 비어 있다. 업계 문헌이 일관되게 지적하는 "structurally valid but epistemically weak" 결과를 4축 검증이 잡으려면 distilled contract 에 *상태 신호*가 있어야 한다. → 최소: 3축에 "성공/부분/실패 상태를 포함"한 줄만 추가하면 단어 비용 거의 0.
2. **[중] worker 실패/타임아웃 시 orchestrator 거동 미정의**: "검증을 보유한다"(4축)는 했으나 검증이 *fail* 했을 때 절차(재디스패치 / hard-stop / 사용자 보고)가 없다. fan-out(5축)에서 N개 중 일부가 실패하면 어떻게 집계하는지도 공백. 본격 정의는 §6.8(spec-21-03)로 이연이 *타당*하나, 본 spec 의 5축에 최소한 "검증 실패 시 §7 Hard Stop 으로"의 *포인터 한 줄*은 있어야 단절이 안 생긴다(§7 은 이미 unplanned decision 을 hard-stop 으로 규정 — 연결만 하면 됨).
3. **[하] no-nested-dispatch 불변식 부재**: worker 가 다시 위임하면 decomposition 권한이 흩어진다(업계 패턴은 이를 금지). upstream 은 §6.8 rule 6 "No over-dispatch"로 처리 → spec-21-03 이연이 합리적. 본 spec 에서는 *명시 불필요*, 단 critique 기록상 spec-21-03 으로 추적 권고.
4. **[하] always-on 의 *주체* 모호**: "every session 에 적용"이라 했으나, director mode *off* 일 때도 메인이 orchestrator 로서 위임하는가, 아니면 off 면 메인이 다 직접 하는가? always-on 의 의미가 "정책 텍스트가 항상 로드됨"인지 "위임 행동이 항상 강제됨"인지 해석이 갈린다. spec 본문 §FR2 와 plan 의 always-on 한 줄("applies to every session regardless of director mode")은 *전자*로 읽히지만, phase-21 이 director mode 토글을 도입하는 맥락에서 후자로 오독될 여지가 크다. ADR-010 Consequences 에 한 문장으로 disambiguate 권고("정책은 항상 적용되나, 위임은 토큰 무거운 노동이 있을 때만 — director mode 는 위임 *적극성* 의 토글이지 정책의 on/off 가 아님").

### 모순

1. **[상] Check 4 baseline(7285) vs 기존 Check 3 LIMIT(6000) 의 이중 기준 + 충돌 가능성**: plan 이 신규 `test-context-orchestration.sh` Check 4 에 `≤ 7285`(baseline ceiling) 가드를 하드코딩한다. 그런데 기존 `test-governance-dedup.sh` Check 3 의 진짜 상한은 `LIMIT=6000`(7285 는 코드가 아니라 *주석*의 현재값)이다. 결과적으로 **동일 지표(constitution+agent.md wc -w)에 두 개의 서로 다른 임계가 두 파일에 박힌다** — 6000(기존, red) 과 7285(신규, "비악화"). 이는 (a) 단일 진실원천 위반, (b) 후속 다이어트 spec 이 단어를 줄여 7285 → 7000 이 돼도 Check 4 는 여전히 통과하지만 *baseline 이 갱신 안 되면* 다음 추가에서 7285 까지 다시 부풀 여지를 허용(ratchet 부재), (c) 두 테스트가 같은 걸 측정해 중복. → 권고: 별도 Check 4 를 신설하지 말고, 본 spec 의 net-neutral 가드를 *기존 Check 3 위에 얹지 말 것*. 대신 "Check 3 의 TOTAL 이 머지 전후로 증가하지 않음"을 PR/walkthrough 의 수동 증빙으로 처리하거나, 굳이 자동화하려면 baseline 을 파일이 아니라 *직전 커밋의 wc -w* 와 비교(ratchet)하게 해야 한다. 7285 하드코딩은 취약하다.
2. **[중] "중복 없음" NFR3 vs net-neutral 상쇄의 실현 가능성**: NFR1 은 "순증 0"을 요구하고 plan 은 그 상쇄원을 "기존 §6.6 의 위임 지시 문장(3축 흡수) + docs-only 예외(§6.7 참조 축약)"로 지목한다. 실측: 흡수 대상인 "When delegating implementation to a Sonnet sub-agent..." 문장은 ~25 words, docs-only 예외 축약 여지 ~20 words. 합쳐 ~45 words 절감 가능. 반면 추가될 5축 단락(plan 의 영어 초안)은 **최소 80~100 words**. → **순증 0 은 산술적으로 어렵다**(약 +40~55w 순증 예상). NFR1("순증시키지 않는다")이 *문자 그대로* 측정되면 본 spec 은 자기 NFR 을 위반한다. 이건 net-neutral 약속이 5축의 텍스트 부피를 과소평가한 데서 온 모순이다.

### 과잉 설계

1. **[하] 5축 전부가 본 spec 에 필요한가 — 5축(fan-out)의 위치**: 5축 fan-out 은 "§6.7 parallel 로 연계"라 본질이 §6.7 에 이미 있다. 본 spec 에서 5축은 *한 줄 포인터*면 충분(plan 이 이미 그렇게 함 — OK). 우려는 5축을 "정책"으로 격상해 부피를 키우는 것. 현재 plan 의 "5. Fan out independent jobs (→ §6.7)." 한 줄은 적절. 과잉 아님.
2. **[하] ADR-010 의 Alternatives 3종**: upstream ADR-005 를 거의 그대로 한국어 재현(전부 직접 / 전문 반환 / 모델만 분배). 본 spec 만의 *새* 의사결정(net-neutral 스코핑, ADR 번호 010, 인라인 배치)이 더 ADR 가치가 큰데 upstream Alternatives 의 재탕에 분량을 쓰는 건 약간의 과잉. ADR-010 은 *fork 고유 결정*(왜 인라인인가, 왜 net-neutral 인가)에 초점을 두는 게 자산가치가 높다(아래 4절).

### 모호함

1. **[중] "토큰 무거운 노동(token-heavy labor)"의 경계**: 1축이 "multi-file impl · broad search · log triage"를 예시하나, "이 정도면 위임"의 *임계*가 없다. 단일 파일 50줄 수정은? 3개 파일이지만 각 5줄은? §6.7 의 "sub-agent dispatch threshold(3+ commands or multi-step)"가 사실상 이 경계를 이미 정의하므로, 1축은 그 threshold 를 *참조*해야 모호성이 제거된다. plan 에 이 연결이 없다.
2. **[중] Check 4 의 7285 baseline 의 취약성(모순 1과 연계)**: 7285 는 "오늘(2026-06-04) 측정값"이라는 시점 의존 상수. 어떤 무관한 후속 작업이 agent.md 에 정당한 1줄을 추가하면 baseline 이 깨져 *본 spec 과 무관한* 테스트가 red 가 된다. baseline 의 의미("이 spec 머지로 인한 순증 0")가 파일에 박힌 절대값과 분리돼 모호하다.
3. **[하] "재작성(rewrite, cherry-pick 금지)"의 범위**: spec 은 "fork 구조에 맞춰 재작성"이라 하나, 실제로 plan 의 영어 5축 초안은 upstream §6.6 "Dispatch policy" 불릿과 문장 단위로 매우 유사(offload/scoped slice/distilled/fan-out 동일 어휘). "재작성"이 의미상 재작성인지 표현만 바꾼 paraphrase 인지 모호 — 라이선스/출처 표기 관점에서 ADR-010 Related 의 "upstream ADR-005 참조" 한 줄로 충분한지 점검 권고(현재 spec 은 충분하다고 판단되나 명시는 약함).

## 3. 대안 제안

### 대안 A: 별도 가이드 문서 분리 (`context-orchestration.md` stub 패턴)

- **아이디어**: 5축 본문을 agent.md 인라인이 아니라 `sources/governance/`(또는 `native-feature-usage.md` 처럼 install 배포되는 가이드)로 빼고, §6.6 에는 2줄 stub + 포인터만. 이미 fork 에 `native-feature-usage.md`(1296w) 선례 존재.
- **장점**: agent.md 본문 부피 압박 즉시 해소(NFR1 순증 모순 1 소멸). phase-21 §6.8 protocol 도 같은 가이드에 합류 가능 → phase 전체 다이어트 전략과 정합(phase-21.md 위험표가 이미 leading 안으로 명시). 항상-로드되는 agent.md 의 토큰 비용 절감.
- **단점**: 5축은 §6.8 protocol(토글형)과 달리 *always-on* 이라 "항상 로드되는 본문에 있어야 한다"는 본 spec 의 배치 논리와 충돌. 가이드는 "필요 시 읽기"라 always-on 강제력이 약화. phase-21.md OPEN 결정은 §6.8 배치만 가이드로 leading 했지 §6.6 always-on 정책까지는 아님. 분리하면 always-on 의 강제력-배치 일관성이 깨진다.

### 대안 B: 본 spec 에서 더 적극적 다이어트 (green 근접)

- **아이디어**: net-neutral("악화 방지")에 그치지 말고, 본 spec 에서 §6.6/§6.7 의 중복·verbose prose 를 대폭 트림해 7285 → ~6800~7000 로 끌어내려 green 에 *근접*. 다이어트를 phase 끝까지 미루지 않음.
- **장점**: phase 성공기준 4(green)를 조기 진척. baseline ratchet 이 자연히 내려감(모순 1 완화). "비악화"라는 약한 목표 대신 측정 가능한 감소.
- **단점**: surgical-changes 원칙 위반 위험(본 spec 과 무관한 prose 까지 건드림). One Task=One Commit 응집도 저하(orchestration 추가 + 광역 다이어트가 한 spec 에 섞임). 다이어트 규모가 커지면 별도 spec(21-06) 분리가 ADR 권고인데(phase-21.md) 그 경계를 흐림. 리뷰 부담↑.

### 대안 C: net-neutral 가드를 기존 Check 3 ratchet 로 통합 (테스트 구조 교정)

- **아이디어**: 신규 `test-context-orchestration.sh` 에 Check 4(7285 하드코딩)를 넣지 말고, 기존 `test-governance-dedup.sh` Check 3 의 *주석 baseline 값*만 갱신하거나, Check 3 를 "직전 태그/커밋 대비 비증가(ratchet)"로 1회 보강. 신규 테스트는 Check 1~3(용어 grep / 미러 parity / ADR 존재)만.
- **장점**: 단일 진실원천(단어 지표는 Check 3 한 곳). 7285 하드코딩 취약성 제거(모순 1·모호 2 동시 해소). 신규 테스트가 *이 spec 고유 산출물*(5축·ADR·미러)만 검증해 응집도↑.
- **단점**: 기존 테스트 수정이 본 spec scope 를 약간 넓힘(governance 테스트 surgical edit). ratchet 도입은 phase 다이어트 spec 의 영역과 겹칠 수 있어 조율 필요.

## 권장안

**현재 spec 유지 + 대안 C 의 테스트 교정 부분 흡수 + 누락 1·2 의 *한 줄* 보강.**

근거. 5축 인라인 배치는 always-on 강제력과 일관되므로 대안 A(분리)는 본 spec 에는 부적합(§6.8 토글형은 분리해도 §6.6 always-on 은 인라인이 옳다). 대안 B(적극 다이어트)는 surgical/One-Task 응집도를 해쳐 phase-21.md 가 이미 "규모 크면 spec-21-06 분리"로 가드한 영역을 침범한다. 반면 **대안 C 는 모순 1(이중 baseline)·모호 2(7285 취약성)를 동시에 제거**하면서 scope 증가가 미미하다 — 신규 테스트에서 Check 4 를 빼고, net-neutral 증빙은 기존 Check 3 의 before/after 수동 비교(walkthrough)로 처리하면 7285 하드코딩 자체가 사라진다. 추가로 누락 1(distilled 상태 필드)·누락 2(검증 실패→§7 포인터)는 각 *한 줄*이라 NFR1 부담이 거의 없고 failure 차원의 hook 을 남겨 spec-21-03 과의 단절을 막는다. 모순 2(순증 0 비현실성)는 NFR1 문구를 "순증 0" → "순증 최소화(±50w 이내) + 후속 다이어트로 흡수"로 완화하거나, 대안 C 로 baseline 하드코딩이 사라지면 자동 측정 압박 자체가 줄어 실질 무해해진다.

## 4. ADR 후보 추출

- [x] 기존 후보 적절: `context-orchestration` — type: **decision** — 메인=orchestrator + 5축. type `decision` 적절(특정 시점의 방향 선택). 단 ADR-010 본문은 upstream Alternatives 재탕보다 *fork 고유 결정*(아래)에 초점 둘 것.
- [ ] 추가 후보(분리 ADR 아님, ADR-010 안에 흡수 권고): `governance-word-budget-net-neutral` — type: **convention** — "거버넌스에 always-on 정책을 추가할 때는 순증 0 을 *spec 단위로* 강제하지 말고 phase 누적으로 green 화하며, 중복 다이어트로 상쇄한다"는 작업 관행. 본 spec 이 처음 확립하는 *재사용 가능한* 규칙(spec-21-03 도 동일 적용)이라 자산가치가 높다. 별도 ADR 신설은 과하니 ADR-010 Consequences/Related 에 한 단락으로 기록 권고.
- [ ] 추가 후보(평가만, 미채택): `always-on-vs-toggle-policy-placement` — type: **invariant** — "always-on 정책은 항상-로드 본문(agent.md)에, 토글형 protocol 은 가이드 stub 에" 배치 불변식. 본 spec 의 인라인 배치 결정의 근거이며 spec-21-03 §6.8 배치와 직접 충돌/정합하는 축. 다만 phase-21.md OPEN 결정(§6.8 배치)이 spec-21-03 에서 확정되므로, 이 invariant 는 spec-21-03 시점에 ADR-011 또는 별도로 박는 게 타이밍상 적절. 본 spec 에서는 critique 기록으로만 추적.

> 종합: ADR-010(decision) 1개로 충분하되, 본문을 upstream 재탕이 아니라 *fork 고유 3결정*(인라인 배치 / net-neutral 스코핑 / 010 번호)에 무게를 싣는 게 자산가치를 극대화한다.

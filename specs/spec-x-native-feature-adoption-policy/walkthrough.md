# Walkthrough: spec-x-native-feature-adoption-policy

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| 산출물 위치 | ADR+포인터 / agent.md 본절 / 별도 가이드 | **ADR+포인터** | 거버넌스 단어 수 한계. 상세는 ADR-007, agent.md 엔 요지만 |
| 전파 범위 | 안 A(전파) / 안 B(키트 한정) | **안 A** | 네이티브 기능 조건은 모든 harness-kit 사용자에 유효. 설치 대상도 같은 게이트 우회 위험에 노출되므로 전파 |
| dangling 참조 | ADR 링크 의존 / 자족 요지 | **자족 요지** | ADR-007 은 키트 repo 에만 존재(미전파). agent.md 요지는 ADR 없이도 의미 통하게 + "(근거: ADR-007)" |
| 단어 수 테스트 FAIL | 요지 유지 / 압축 / 다이어트 포함 | **요지 유지** | FAIL 은 기존 비대화(6904w)가 본질, 본 spec +90w 는 정책 필수 최소. 6000w 통과는 본 spec 으로 불가 → 다이어트 별도 |
| 동기화 방법 | update.sh / 직접 cp | **직접 cp** | 단일 파일이라 전체 재설치(update.sh)는 과함. ADR-003 단방향(원본→설치본) 정신 유지 |

### ADR 승격 가이드

- [x] ADR 승격 대상 있음 → 작성됨: `docs/decisions/ADR-007-native-feature-adoption-policy.md` (type: convention)
- [ ] 없음

## 💬 사용자 협의

- **주제**: 정책 spec 진행 + 산출물 위치
  - **사용자 의견**: 정책 spec(1번) + ADR+포인터(1번) 선택
  - **합의**: ADR-007 + agent.md §6.7 요지
- **주제**: 전파 범위 (Plan Accept 게이트, Discord 채널 응답)
  - **사용자 의견**: "1" (안 A 전파) — Discord 경유 응답, §10 양방향 절차로 처리
  - **합의**: sources/governance/agent.md 수정 → 전파. dangling 회피 자족 요지
- **주제**: 거버넌스 6000w 한도 출처 질문
  - **사용자 의견**: "6000w 는 어디서 정했나?"
  - **합의**: `test-governance-dedup.sh:90` 하드코딩 휴리스틱(ADR 아님), 2026-05-10 5000→6000 상향 전례 확인. FAIL 의 본질은 기존 비대화 → 요지 유지 + 진행(1번)

## 🧪 검증 결과

### 1. 자동화 테스트

#### 거버넌스 정합성 테스트
- **명령**: `bash tests/test-governance-dedup.sh`
- **결과**: ❌ 1/8 FAIL (Check 3 단어 수) — 단, **기존 초과 상태이며 본 spec 이 새로 깨뜨린 것 아님**
- **로그 요약**:
```text
Check 2: sources ↔ .harness-kit 동기화  ✅ agent.md 동기화 OK
Check 3: 단어 수  constitution 2672 + agent.md 4322 = 6994w  ❌ > 상한 6000w
  (본 spec 추가 전 ~6904w 로 이미 904w 초과. 본 spec +90w)
Check 1·4·5·6: ✅ PASS
```

### 2. 수동 검증

1. **Action**: ADR-007 이 7종 조건을 모두 담는가
   - **Result**: ✅ Decision 표에 7종 각 조건 + 막는 충돌 + 공통 원칙
2. **Action**: agent.md 요지가 자족적인가(ADR 링크 없이 의미 통함)
   - **Result**: ✅ "gate-preservation conditions ... stop and report at every decision gate" 단독으로 읽힘. ADR 은 "(근거)" 참조
3. **Action**: `sources/governance/agent.md` ↔ `.harness-kit/agent/agent.md` 일치
   - **Result**: ✅ test Check 2 동기화 OK + cp 전 diff 가 §6.7 추가분 한 줄뿐(다른 drift 없음) 확인
4. **Action**: 단어 수 악화 폭
   - **Result**: +90w (요지). 한도 초과의 본질은 기존 6904w

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **결과 파일** | N/A |
| **요약** | N/A |
| **Skip 사유** | `docs-only` — 거버넌스 문서(ADR + agent.md 요지)만, 실행 코드 변경 없음 (agent.md §6.3.8) |

## 🔍 발견 사항

- **거버넌스 6000w 한도는 ADR 이 아니라 테스트 휴리스틱** — `test-governance-dedup.sh:86-90` 에 하드코딩. 2026-05-10 에 5000→6000 상향 전례(§6.7 신설로 헤드룸 확보). "6500+ 은 별도 정당화 필요" 가드레일. 즉 절대선이 아니라 조정 가능한 경고선.
- **현재 6994w 는 구조적 비대화 신호** — 본 spec +90w 가 아니라 기존 6904w 누적이 본질. 한도 상향(7000)이 아니라 다이어트가 정답("무절제 상향 금지" 정신).
- **전파 vs dangling 트레이드오프** — ADR 은 키트 repo 전용이라 전파되는 agent.md 가 ADR 링크에 의존하면 설치 대상에서 끊김. 요지를 자족적으로 쓰고 ADR 은 "근거"로만 참조해 해소.

## 🚧 이월 항목

- **거버넌스 다이어트** (단어 수 6000w 한도 vs 6994w 현실) → `backlog/queue.md` Icebox 기존 항목 ("거버넌스 문서 단어 수 한계 초과"). 본 spec 으로 미해결(범위 밖), 별도 spec 필요
- 네이티브 기능 hook 강제(경고→차단 승격) → ADR-007 Consequences 에 별도 검토로 명시

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-02 ~ 2026-06-02 |
| **최종 commit** | ship commit (push 직전) |

# Implementation Plan: spec-x-adr-template-stale-note

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-adr-template-stale-note` (브랜치 이름 = spec 디렉토리 이름)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **fix 방식 = 평문 표기 (이슈 후보 ①)** 채택. 후보 ② (`../` prefix 예시) 는 note 가 "이 예시는 검사 대상" 이라 설명하는데 `../` 는 *제외* 대상이라 자기모순 → 기각. 후보 ③ (휴리스틱 변경) 은 Out of Scope.
> - [ ] 휴리스틱 (`_drift_stale_adr`) 무변경 — 템플릿 content fix 만으로 해소

> [!WARNING]
> - [ ] breaking change 없음 — 템플릿 문구 + 테스트만 변경. 기존 ADR/휴리스틱 영향 없음

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **예시 토큰** | backtick 제거 → 평문 src/foo.ts | 휴리스틱은 backtick 토큰만 추출 — 평문은 미추출 |
| **note 정확도** | `../` 상대경로 제외 규칙 명시 | 휴리스틱 규칙 4 와 정합, 다운스트림 작성자 가이드 보강 |
| **휴리스틱** | 무변경 | template fix 로 충분, Step 1~6 회귀 리스크 회피 (Out of Scope ③) |
| **회귀 테스트** | 라이브 템플릿 note 를 fixture ADR 에 삽입 | 미래 트리거 예시 재도입을 직접 차단 (하드코딩 텍스트보다 강함) |

### 📑 ADR 후보

- [x] 없음

## 📂 Proposed Changes

### 템플릿

#### [MODIFY] `sources/templates/adr.md` (note 블록, line 10~12)

Before (line 10):
```
> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로 (예: `src/foo.ts`) 는 `sdd status` 의 stale ADR 검사 대상입니다.
```

After (제안):
```
> **Note — 경로 표기와 stale ADR 검사 대상**: 본 ADR 의 inline backtick 경로는 `sdd status` 의 stale ADR 검사 대상입니다.
> 검사 패턴은 *inline backtick + 슬래시 + 확장자* 를 가진 토큰입니다 (예: 백틱으로 감싼 src/foo.ts 형태). ` ``` ` code fence 안 경로, 슬래시 없는 토큰, `../` 로 시작하는 상대경로, URL 은 무시됩니다.
> 코드 경로가 이동/삭제되면 stale 라인이 떠 ADR 갱신 신호가 됩니다.
```

- `src/foo.ts` 는 평문 (backtick 없음) — 휴리스틱 미추출.
- `../` 제외 규칙 추가 (기존 "슬래시 없는 토큰, URL" 목록에 합류).
- `` `sdd status` `` (슬래시 없음) / ` ``` ` (code fence 예시) 는 기존대로 안전.

#### [MODIFY] `.harness-kit/agent/templates/adr.md`
sources/ 변경분 동기 (pre-edit IDENTICAL 확인 후 cp).

### 테스트

#### [MODIFY] `tests/test-drift-stale-adr.sh` — Step 7 추가

라이브 템플릿 note 를 fixture ADR (`docs/decisions/ADR-994-template-note-fixture.md`) 에 삽입 → `sdd status` 실행 → 해당 ADR 이 stale 목록에 **없음** 단언. self-fixture 특정 단언 (cross-test 견고화 — 기존 파일 정책 준수).

```text
TEMPLATE_NOTE=$(grep '^>' sources/templates/adr.md)   # 템플릿의 note blockquote 추출 (유일 blockquote)
cat > "$TEMPLATE_NOTE_FIXTURE" <<EOF
---
id: ADR-994 / type: decision / date / status: accepted
---
# ADR-994: Fixture embedding live template note
$TEMPLATE_NOTE
## Decision
This ADR exists only for issue #55 regression — the live template note MUST NOT self-trigger stale.
EOF
output=$(sdd status); cleanup
grep -q "ADR-994-template-note-fixture" → 있으면 FAIL (note 가 자가-트리거)
```

- trap cleanup 에 `ADR-994` fixture 추가.
- **Red 검증**: 현 (버그) 템플릿으로 실행 시 note 의 `` `src/foo.ts` `` 때문에 ADR-994 가 stale 로 잡혀 단언 실패 = Red. 템플릿 fix 후 Green.

### 백로그

#### [MODIFY] `backlog/queue.md`
Icebox 에 1건 등록: monorepo sibling 레포 경로 stale-ADR false-positive (system 루트 기준 검사 한계).

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-drift-stale-adr.sh
```

### 수동 검증 시나리오
1. fix 전 `grep '^>' sources/templates/adr.md` 에 `` `src/foo.ts` `` (backtick) 존재 확인 → fix 후 평문화 확인.
2. 템플릿 note 를 복사한 임시 ADR 을 `docs/decisions/` 에 만들고 `bash .harness-kit/bin/sdd status` → stale 목록에 없음 확인 후 삭제.

## 🔁 Rollback Plan

- 커밋 단위 revert — 템플릿 문구/테스트만이라 안전.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship

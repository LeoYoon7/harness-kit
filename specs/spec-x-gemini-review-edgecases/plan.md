# Implementation Plan: spec-x-gemini-review-edgecases

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-gemini-review-edgecases` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main` 에서 사전 분기 (spec-x → PR base=main, 직전 sandbox spec 과 동일)
- 첫 task 가 브랜치 생성 + 계획 산출물 커밋을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] **(b) 지시문 전달 방식 변경**: 한국어 지시문을 `gemini -p` argv → stdin 본문 최상단으로 이동. `-p` 는 ASCII 영어 포인터로 대체. 실제 gemini 동작에서 stdin 상단 지시문이 충분히 반영되는지는 형식-검증 grep 으로 1차 방어하나, 실 CLI 스모크는 권장(선택).
> - [ ] **(a) fallback 판단 기준**: base 가 `main` 이 아니고 commit-ish 로 실재하지 않을 때만 main fallback. base 실재 시 무변경.

> [!WARNING]
> - [ ] breaking change 없음 — 두 변경 모두 *오동작 경로*만 교정. 정상 경로(base 실재 + ASCII)는 무회귀.
> - [ ] 외부 영향: gemini 실 CLI 호출 인자 형태 변경 (argv 축소). stub 테스트로 계약 고정.

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **(a) base fallback** | `git rev-parse --verify --quiet "${BASE}^{commit}"` 실패 + base≠main → `BASE=main` + ⚠ stderr | base-branch phase 첫 spec 은 base 미생성(§3.1). ref 부재를 빈-diff 로 오진단하지 않고 명시적 fallback |
| **(b) argv 안전** | 한국어 `INSTRUCTION` 을 INPUT_FILE(stdin) 최상단으로 prepend, `-p` 는 ASCII 영어 포인터 | git-bash 네이티브 argv 는 CP949 손상([[gitbash-nonascii-argv-codepage]]). stdin 파일은 바이트 보존 |
| **테스트** | stub `gemini` 확장 — argv/stdin 캡처(repo 밖 CAPTURE_DIR) + state.json baseBranch 주입 | 기존 가드 테스트 인프라 재사용. 워크스페이스 변조 없이 계약 검증 |
| **미러 동기화** | source 수정 후 `cp` 로 `.harness-kit/bin/` 미러 보장 | 직전 spec 과 동일 — diff 무결성 |
| **Icebox 정리** | strike-through + 해결 spec 참조 (queue.md 기존 관행) | 사람-편집 섹션. plan-mode 라인 = sandbox 해결, 엣지케이스 라인 = 본 spec 해결 |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음 — fix. argv-안전 원칙은 메모리에 자산화됨 (spec.md ADR 절 참조).

## 📂 Proposed Changes

### gemini-review.sh (source + mirror)

#### [MODIFY] `sources/bin/gemini-review.sh`

- **(a)** base 결정부(line 64~75) 뒤에 fallback 가드 추가:

```bash
# base 브랜치 실재 확인 — 없으면 main 으로 fallback
# (base-branch phase 의 첫 spec 은 base 브랜치가 hk-ship 시점 생성이라 부재 — constitution §3.1)
if ! git rev-parse --verify --quiet "${BASE_BRANCH}^{commit}" >/dev/null 2>&1; then
    if [ "$BASE_BRANCH" != "main" ]; then
        echo "⚠ base 브랜치 '$BASE_BRANCH' 부재 (첫 spec 추정) → main 으로 fallback" >&2
        BASE_BRANCH="main"
    fi
fi
```

- **(b)** INPUT_FILE 구성(line 78~91) 에 지시문을 최상단으로 prepend, gemini 호출(line 106) 의 `-p` 를 ASCII 영어로:

```bash
{
    echo "$INSTRUCTION"          # 한국어 지시문 — argv 아닌 stdin 으로 (CP949 손상 회피)
    echo; echo "---"; echo
    echo "# Spec ($SPEC_ID)"
    ...기존 본문...
} > "$INPUT_FILE"

PROMPT="Follow the reviewer instructions at the top of the input, then review the spec and diff that follow. Output Korean markdown as instructed."
... gemini -p "$PROMPT" --approval-mode plan < "$INPUT_FILE" ...
```

`INSTRUCTION` 변수 정의 자체는 유지(한국어) — 단 *사용처*가 argv→stdin 으로 바뀜.

#### [MODIFY] `.harness-kit/bin/gemini-review.sh`
source 와 바이트 동일하게 `cp` 동기화.

### 테스트

#### [MODIFY] `tests/test-gemini-review-guard.sh`
- stub `gemini` 에 `capture` 모드 추가 — `$CAPTURE_DIR/argv`(printf 각 인자) + `$CAPTURE_DIR/stdin` 기록(repo 밖이라 부수효과 미발생) 후 정상 리뷰 emit.
- **T6 (argv ASCII 안전)**: capture 모드 실행 → `$CAPTURE_DIR/argv` 가 순수 ASCII(`LC_ALL=C grep '[^[:print:][:space:]]'` 무매치) + 한국어 지시문이 `$CAPTURE_DIR/stdin` 에 존재.
- **T7 (base fallback)**: fixture state.json 의 `baseBranch` 를 실존하지 않는 `phase-99-missing` 으로 주입 → valid 모드 실행 → exit 0 + 리뷰 파일 생성(main fallback 성공).

### Icebox

#### [MODIFY] `backlog/queue.md`
- plan-mode 위반 라인 → `~~...~~ → ✓ spec-x-gemini-review-sandbox 로 해결` strike-through.
- 엣지케이스 2종 라인 → `~~...~~ → ✓ spec-x-gemini-review-edgecases` strike-through.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
bash tests/test-gemini-review-guard.sh   # 기존 12 + 신규 T6/T7 = 14 PASS 기대
```

### 회귀
```bash
# gemini-review.sh + test-gemini-review-guard.sh 단일 영역 변경 — 가드 테스트가 직접 커버.
# 전체 스위트는 ship 단계에서 확인.
```

### 수동 검증 시나리오
1. T6 stub capture → argv 캡처 파일에 한글 없음, stdin 캡처에 지시문 존재 — 기대: argv 순수 ASCII.
2. T7 baseBranch=phase-99-missing → exit 0 + `code-review-gemini.md` 생성 — 기대: main fallback.
3. `diff -q sources/bin/gemini-review.sh .harness-kit/bin/gemini-review.sh` — 기대: 차이 없음.
4. (선택) 실 gemini CLI 스모크 — 지시문 stdin 이동 후에도 리뷰 형식 정상 산출 확인.

## 🔁 Rollback Plan

- 단일 스크립트 + 단일 테스트 파일 변경 → 브랜치 폐기 또는 commit revert 로 원복. 상태/데이터 영향 없음.

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship

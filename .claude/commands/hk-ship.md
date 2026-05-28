---
description: 현재 SPEC 작업 종료 — walkthrough/pr_description 검증 후 push + PR 자동 진행
---

현재 SPEC 의 모든 작업 task 가 완료되었을 때 이 명령으로 ship 절차를 시작합니다.
**모든 검증이 통과하면 push + PR 생성까지 자동 진행합니다.** 실패 시에만 멈추고 보고합니다.

## 1. 사전 검증

```bash
./.harness-kit/bin/sdd ship --check
```

확인 항목:
- task.md 의 모든 작업 task 가 `[x]` 또는 `[-]` 인지
- walkthrough.md 가 작성되어 있는지 (placeholder 만 있으면 안 됨)
- pr_description.md 가 작성되어 있는지

부족한 부분이 있으면 사용자에게 정확히 무엇이 부족한지 보고하고 멈춥니다.

## 1.5 코드 리뷰 게이트 (선택)

Push/PR 직전 cross-model 또는 self-model 코드 리뷰를 옵션으로 제공합니다.
사용자에게 다음 선택지를 제시하고 응답을 대기합니다 (CLAUDE.fragment.md 선택지 제시 규약 — [권장] 포함):

```
[상황 / 맥락]
Ship 직전 코드 리뷰 옵션 — push/PR 후에는 리뷰 비용이 커집니다.

[선택지]
1. Gemini (cross-model, 다른 모델 관점) — bash .harness-kit/bin/gemini-review.sh
2. Opus (기존 /hk-code-review)
3. Skip — 리뷰 없이 §2 품질 게이트로 진행

[권장]
1 — cross-model 리뷰가 self-evaluation 편향을 줄입니다 (LLM-as-judge 연구 일관).
    gemini CLI 미설치 또는 빠른 ship 필요 시 3.

[의사결정 요청]
어떤 리뷰로 진행할까요?
```

사용자 응답:
- `1` / `gemini` → `bash .harness-kit/bin/gemini-review.sh` 실행. 결과는 `specs/<spec-dir>/code-review-gemini.md`.
- `2` / `opus` → `/hk-code-review` 절차 실행. 결과는 `specs/<spec-dir>/code-review.md`.
- `3` / `skip` → 바로 §2 로 진행.

**Critical 이슈 발견 시**: 리뷰 결과의 `Critical: N` 이 0 보다 크면 사용자에게 보고 후 다음 선택지를 추가로 제시합니다.

```
[상황] 리뷰에서 Critical N개 발견.

[선택지]
1. 보고 후 멈춤 — 사용자가 fix 진행
2. 그대로 ship 진행 (Critical 무시)

[권장]
1 — Critical 은 ship 후 정정 비용이 큰 항목입니다.

[의사결정 요청]
어떻게 진행할까요?
```

리뷰 실행 실패 (gemini CLI 미설치 등) 시 사용자에게 보고하고 다시 선택지를 제시합니다 (Skip 도 옵션).

## 2. 품질 게이트

**실패 시 즉시 멈추고 사용자에게 보고. 에이전트가 임의로 fix 시도 금지 — 사용자 결정 대기.**

### 2-A. 패키지 매니저 감지 (Node.js)

```bash
if [ -f "pnpm-lock.yaml" ]; then   PM="pnpm"
elif [ -f "yarn.lock" ];           then   PM="yarn"
elif [ -f "package-lock.json" ];   then   PM="npm"
else                                      PM=""
fi
```

### 2-B. Lint / Type Check

**Lint**: `package.json`에 `lint` 스크립트가 있으면 실행합니다.

**Type Check**: 에이전트가 프로젝트 구조를 보고 스스로 판단하여 실행합니다.

판단 순서:
1. `.husky/pre-push`, `lefthook.yml` 등 기존 git pre-push hook 설정이 있으면 → `git push` 시 자동 실행되므로 **여기서는 skip**
2. `installed.json`의 `precheck` 배열에 typecheck 관련 명령이 있으면 → 2-D에서 실행되므로 **여기서는 skip**
3. 위 둘 다 없을 때 에이전트가 직접 판단하여 실행:
   - `turbo.json`에 typecheck task 있으면 → `$PM turbo run typecheck`
   - `package.json` scripts에 `typecheck` / `type-check` 있으면 → `$PM run typecheck`
   - `tsconfig.json` 존재 + 위 스크립트 없으면 → `$PM exec tsc --noEmit`
   - TypeScript 파일 없으면 → skip

실패 시 **즉시 멈춤** — 사용자가 오류를 직접 수정해야 합니다.

### 2-C. 단위 테스트

```bash
has_test=$(jq -r '.scripts.test // empty' package.json 2>/dev/null)
[ -n "$has_test" ] && $PM run test
```

### 2-D. Precheck 명령 (installed.json 등록 항목)

`.harness-kit/installed.json` 에 `precheck` 배열이 있으면 순서대로 실행:

```bash
prechecks=$(jq -r '.precheck[]? // empty' .harness-kit/installed.json 2>/dev/null)
while IFS= read -r cmd; do
  [ -z "$cmd" ] && continue
  echo "▶ precheck: $cmd"
  eval "$cmd" || { echo "✖ precheck 실패: $cmd"; exit 1; }
done <<< "$prechecks"
```

### 2-E. Integration Test

`spec.md` 의 `Integration Test Required: yes` 인 경우에만 실행.

## 3. Ship Commit

`sdd ship` 가 walkthrough.md / pr_description.md 를 한 commit 으로 묶어줍니다:

```bash
./.harness-kit/bin/sdd ship
# 위 명령은 내부에서:
#   git add specs/spec-{phaseN}-{seq}-{slug}/walkthrough.md
#   git add specs/spec-{phaseN}-{seq}-{slug}/pr_description.md
#   git commit -m "docs(spec-{phaseN}-{seq}): ship walkthrough and pr description"
```

## 4. Push (자동 진행)

**[Phase base branch 감지]** Push 전, PR 타깃 결정:

```bash
base_branch=$(./.harness-kit/bin/sdd status --json | jq -r '.baseBranch // "null"')
if [ "$base_branch" != "null" ]; then
  # phase base branch 모드 — remote 존재 여부 확인
  if ! git ls-remote --exit-code origin "$base_branch" >/dev/null 2>&1; then
    echo "phase base branch 없음 — 생성: $base_branch"
    git checkout -b "$base_branch" main
    git push -u origin "$base_branch"
    git checkout -   # spec 브랜치로 복귀
  fi
  PR_BASE="$base_branch"
else
  PR_BASE="main"
fi
```

정보 테이블을 표시한 후 **자동으로 push** 합니다:

| 항목 | 값 |
|---|---|
| 브랜치 | `<head>` ▶ 🎯 `<PR_BASE>` |
| 제목 | `<pr_description.md 첫 줄>` |
| 커밋 수 | N개 |
| 변경 파일 | M개 |

```bash
git push -u origin spec-{phaseN}-{seq}-{slug}
```

push 실패 시 멈추고 사용자에게 보고.

## 5. PR 생성 (자동 진행)

`git remote get-url origin` 의 호스트로 분기:

### 5-A. github.com → `gh` CLI

(사전: `gh auth status` 로 인증 확인. 미인증이면 사용자에게 `gh auth login` 안내 후 멈춤)

`/hk-pr-gh --no-confirm` 슬래시 커맨드의 절차를 따릅니다.
hk-ship 은 Plan Accept 이후 흐름이므로 PR 생성 확인을 생략합니다 (→ constitution §5.7).

> **Phase base branch 모드**: `PR_BASE` 가 `main` 이 아닌 경우 `gh pr create --base $PR_BASE` 를 사용합니다.

### 5-B. bitbucket.org → `bb-pr`

(사전: `~/.config/bitbucket/token` 준비)

`/hk-pr-bb` 슬래시 커맨드의 절차를 따릅니다.

### 5-C. 그 외 (GitLab, GitHub Enterprise, 사내 Bitbucket Server 등)

push 완료 후 수동 PR 생성을 안내:

```
✅ Push 완료: spec-{phaseN}-{seq}-{slug}

다음 단계 (사용자):
1. <hosted git URL>/pull-requests/new?source=spec-{phaseN}-{seq}-{slug}
2. PR 본문에 specs/spec-{phaseN}-{seq}-{slug}/pr_description.md 내용 복사
3. 리뷰어 지정
```

성공 시 PR URL/번호를 사용자에게 보고하고 **머지를 기다립니다**.

## 6. State 업데이트

`sdd ship` 가 이미 state.json 을 초기화합니다 (spec=null, planAccepted=false).
별도 `sdd plan reset` 호출은 불필요합니다.

> **[spec-x 한정] queue.md 완료 갱신**
>
> spec-x (`spec-x-{slug}`) 인 경우 queue.md 갱신:
> ```bash
> ./.harness-kit/bin/sdd specx done {slug}
> ```
> 이 명령은 specx 대기 섹션에서 해당 항목을 제거하고 완료 섹션으로 이동합니다.

> **[Phase base branch 모드] 다음 Spec 시작 전 주의사항**
>
> 현재 Spec PR 이 phase base branch 에 **merge된 후** 다음 Spec 브랜치를 생성해야 합니다.
> merge 전에 다음 Spec 을 시작하면 이전 Spec 의 변경사항이 누락된 base 에서 분기하게 됩니다.
>
> ```
> 올바른 순서:
>   1. PR merge 완료 (phase base branch ← spec 브랜치)
>   2. 다음 Spec 브랜치 생성 (phase base branch 최신 기준)
> ```
>
> (→ constitution §4.1 Phase base branch 분기 규칙)

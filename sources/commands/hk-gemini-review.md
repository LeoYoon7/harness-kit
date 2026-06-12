---
description: 현재 SPEC 브랜치의 코드 변경을 Gemini CLI 로 cross-model 리뷰 (Opus 리뷰 /hk-code-review 와 별개)
---

현재 브랜치의 코드 변경사항을 **Gemini CLI** 로 **cross-model** 관점에서 리뷰합니다.

같은 모델 self-evaluation 의 편향을 줄이기 위한 보조 채널로, 기존 `/hk-code-review` (Opus sub-agent) 와 결과를 별도 파일에 저장하므로 두 모델을 비교 (cross-validation) 할 수도 있습니다.

## 1. 사전 확인

- `gemini` CLI 가 설치 + 인증되어 있어야 합니다 (https://geminicli.com).
- 현재 활성 spec 이 있어야 합니다 (`sdd status --json` 의 `spec` 필드).
- 현재 브랜치와 base 사이에 변경이 있어야 합니다. base 는 해석 체인 `phase baseBranch → defaultBranch → main` 으로 결정됩니다 (`sdd config default-branch` 로 변경).

## 2. 실행

```bash
bash .harness-kit/bin/gemini-review.sh
```

내부 동작:

1. `gemini` CLI 존재 확인 → 미설치 시 명확한 에러 + exit 1.
2. `sdd status --json --no-drift` 로 활성 spec / base 식별 (phase `baseBranch` → installed.json `defaultBranch` → `main` 체인, ref 부재 시 단계별 fallback).
3. `spec.md` 본문 + `git diff <base>...HEAD` 를 stdin 으로 전달 (argv 크기 한계 회피).
4. `gemini -p "<짧은 지시문>" --approval-mode plan` 헤드리스 호출 (read-only — 워크스페이스 수정 차단).
5. 결과를 `specs/<spec-dir>/code-review-gemini.md` 에 저장.

## 3. 결과 보고

성공 시 stderr 로 다음 요약을 출력합니다:

```
✅ Gemini 리뷰 완료: specs/<spec-dir>/code-review-gemini.md
- 전체 평가: (Approve / Request Changes / Comment)
- Critical: N
- Major: N
- Minor: N
```

Critical 이슈가 있으면 ship 전에 해결을 권고합니다.

## 4. Opus 리뷰와의 차이

| 항목 | `/hk-gemini-review` | `/hk-code-review` |
|---|---|---|
| 리뷰어 모델 | Gemini CLI (cross-model) | Opus sub-agent (same-model) |
| 출력 파일 | `code-review-gemini.md` | `code-review.md` |
| 호출 방식 | bash 스크립트 → gemini CLI | Agent tool (`model: "opus"`) |
| 의존성 | gemini CLI 인증 | (없음, Claude Code 내장) |
| 권장 시점 | Ship 직전 (cross-model 편향 감소) | Gemini 결과 검증, 또는 gemini 미설치 시 fallback |

두 리뷰는 **상호 배타가 아닙니다** — 둘 다 실행해 발견사항을 합쳐 cross-validation 도 가능합니다.

## 5. Ship 흐름과의 연결

`/hk-ship` 의 pre-flight 게이트가 자동으로 본 커맨드 (Gemini / Opus / Skip 선택지) 를 제시합니다. 별도 호출은 게이트 외 시점 (수시 리뷰, cross-validation) 에 유용합니다.

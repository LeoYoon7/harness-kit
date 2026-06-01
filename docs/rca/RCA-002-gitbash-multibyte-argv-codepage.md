---
id: RCA-002
type: failure-pattern
date: 2026-06-02
severity: high
status: resolved
---

# RCA-002: git-bash 가 멀티바이트 argv 를 네이티브 프로그램에 ANSI 코드페이지로 손상

## 🔍 Symptom
한글/emoji 가 든 PR 본문으로 `bb-pr` 실행 시 Bitbucket 이 HTTP 400 (`Bad Request`) 반환. GET 계열은 정상, 본문 있는 POST/PUT 만 실패. 인증·스코프가 정상이라 원인 진단이 어려움.

## 🔁 Reproduction
한글 Windows (시스템 로캘 CP949) + git-bash 환경에서:
1. `jq -n --arg x "$KOR"` 로 JSON payload 생성 (jq 출력 자체는 정상 UTF-8).
2. `curl -d "$PAYLOAD"` 로 네이티브 `curl.exe` 에 명령행 인자로 전달.
3. wire 바이트 캡처 결과: "테"(UTF-8 `ed 85 8c`)가 CP949 `c5 d7` 로, emoji 는 `3f 3f`(`??`)로 전송됨.

## 🎯 Root Cause
git-bash (MSYS2) 가 멀티바이트 명령행 인자를 *네이티브* Windows 프로그램 (`curl.exe` 등 ANSI CRT) 에 넘길 때 시스템 ANSI 코드페이지 (한글 Windows = CP949) 로 변환한다. jq 출력은 정상 UTF-8 이지만 `curl -d "$PAYLOAD"` 의 argv 경계에서 손상됨. 서버는 깨진 CP949 바이트를 받고, `application/json` (UTF-8 강제) 이라 디코딩 실패 → 400. (jq 의 `--arg` 는 멀쩡히 통과 — 바이너리별 argv 처리 차이.)

## 🛡 Invariant Violated
**git-bash 에서 네이티브 프로그램에 넘기는 명령행 인자는 ASCII 여야 바이트-투명하다.** 비-ASCII 멀티바이트를 argv 로 네이티브 프로그램에 전달하면 시스템 ANSI 코드페이지 변환에 노출된다 (이전 미명시 — 지금 명시).

## 🚧 Prevention
1. **payload/본문을 ASCII 로 만들어 전달**: JSON 은 `jq -an` (`--ascii-output`) 로 `\uXXXX` escape (#20). ASCII 는 모든 ANSI 코드페이지에 불변.
2. **멀티바이트 본문은 argv 대신 stdin/파일로**: `git commit -F`, `gh pr create --body-file` / `--fill`, `curl --data-binary @file` — argv 경계 우회.
3. 키트의 다른 bin 스크립트가 비-ASCII 를 네이티브 프로그램 argv 로 넘기는 곳이 있으면 동일 패턴을 적용한다.

## 🔗 Related
- PR #20 (bb-pr `jq -an` fix), Release 0.15.1-leo.1
- 보고: NextMarket 세션 bug report (2026-06-01) — `/tmp` 의 bb-pr-* 우회 스크립트 잔재로 재발 확인

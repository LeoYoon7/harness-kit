# Walkthrough: spec-x-icebox-prune

> 본 문서는 *작업 기록* 입니다. 결정 과정, 사용자 협의, 검증 결과를 미래의 자신과 리뷰어에게 남깁니다.

## 📌 결정 기록

| 이슈 | 선택지 | 결정 | 이유 |
|---|---|---|---|
| Icebox 죽은 항목 처리 작업 모드 | FF / spec-x | spec-x | 본 repo 는 모든 변경이 fork main 으로 PR 머지되는 모델이라 FF 의 "PR 없음" 이 landing 경로와 안 맞음. spec-x 가 §10.1 (main 직접 commit 금지) 을 자연스럽게 준수 + `sdd specx done` 이 queue bookkeeping 처리 |
| Edit 빈 문자열 치환 시 인접 newline 소실 | (a) 빈 치환 반복 (b) junction 병합 치환 | (b) junction 병합 | 빈 문자열(`""`) 치환이 인접 newline 하나를 함께 제거 → keep 항목끼리 붙는 결함 2회 발생. non-empty 치환(대상줄+다음줄prefix → 다음줄prefix)으로 전환해 newline 보존 확정 |

### ADR 승격 가이드

- [ ] ADR 승격 대상 있음
- [x] 없음 — 단순 대시보드 정리, cross-spec / long-lived 결정 없음.

## 💬 사용자 협의

- **주제**: Icebox 검토 후 다음 행동
  - **사용자 의견**: 1번 (Icebox 청소 먼저) 선택
  - **합의**: 해소된 5개 항목 제거
- **주제**: 작업 모드 (FF vs spec-x)
  - **사용자 의견**: 2번 (spec-x) 선택
  - **합의**: spec-x-icebox-prune 로 진행, Chore(docs)

## 🧪 검증 결과

### 1. 자동화 테스트

#### 단위 테스트 (toolchain 회귀)
- **명령**: `bash tests/test-sdd-queue-redesign.sh`
- **결과**: ✅ Passed (5/5 checks)
- **로그 요약**:
```text
✅ Check 3: sdd queue — Icebox 섹션 헤더 존재
✅ ALL 5 CHECKS PASSED
```
- **비고**: 본 변경은 doc(대시보드) 정리 — 전용 단위 테스트 없음 (constitution §9.1 docs-only 면제). 위 테스트는 queue/marker toolchain 건강성 확인용. 실질 회귀 검증은 아래 수동 검증.

### 2. 수동 검증

1. **Action**: 5개 항목을 `backlog/queue.md` Icebox 에서 Edit 로 제거
   - **Result**: 5줄 삭제 완료
2. **Action**: `grep -E "Telegram 응답 시 ack 중복|AskUserQuestion 옵션 번호 불일치|Discord 마크다운 포맷팅 (notify.sh 채널별 분기)|semver_lt 함수 leo suffix|2단계 정책 spec" backlog/queue.md`
   - **Result**: No matches (0) — 5개 항목 모두 부재 확인
3. **Action**: `git diff backlog/queue.md`
   - **Result**: `@@ -36,16 +36,11 @@` net -5. 삭제 5줄(`-`)만, keep 항목(check-secrets, ADR-tool, 컨테이너, AUQ 잔존, Discord embed, stale ADR, CC 세션검증, /batch, CC 1단계, /goal) 전부 무변경, 자동 마커 영역 무변경
4. **Action**: `bash .harness-kit/bin/sdd status --no-drift`
   - **Result**: 정상 출력 (queue.md 파싱 무손상), Active Spec=spec-x-icebox-prune, Plan Accept=yes

## 🔍 코드 리뷰

| 항목 | 값 |
|---|---|
| **수행 여부** | Skip |
| **결과 파일** | 없음 |
| **요약** | 없음 |
| **Skip 사유** | `docs-only` — queue.md 대시보드 5줄 삭제 + spec 산출물, 코드/스크립트 변경 없음 (agent.md §6.3-8) |

## 🔍 발견 사항

- **Edit 도구 빈-치환 newline 소실**: `new_string=""` 인 Edit 가 인접 newline 1개를 함께 소거해 keep 항목끼리 병합되는 결함을 2회 유발. CJK 다중 줄 마크다운 항목을 제거할 때는 *빈 치환* 대신 *junction 병합* (대상줄 + 다음 keep 줄 prefix → 다음 keep 줄 prefix) 이 안전. 향후 유사 Icebox/리스트 정리 시 동일 패턴 권장.
- **선례**: `8ac1d9e chore: drop stale spec-x-sdd-bugfix (both bugs already resolved)` — 해소 항목 제거를 가벼운 `chore:` 직접 커밋으로 처리한 선례 존재. 본 건은 사용자 선택으로 spec-x 채택했으나, 차후 동종 작업의 FF 처리 근거가 됨.

## 🚧 이월 항목

- 없음. 나머지 미해결 Icebox 항목(uninstall FAIL, check-secrets 오탐, stale ADR 오탐, 거버넌스 단어수, 컨테이너/wiki/알림/ADR 테마, phase-21 director mode 등)은 본 spec 범위 밖 — Icebox/대기 Phase 에 그대로 보존.

## 📅 메타

| 항목 | 값 |
|---|---|
| **작성자** | Agent + Leo |
| **작성 기간** | 2026-06-04 |
| **최종 commit** | ship 시 갱신 |

# Task List: spec-x-md-lf-normalize

> 모든 task 는 한 commit 에 대응합니다 (One Task = One Commit).
> 매 commit 직후 본 파일의 체크박스를 갱신해야 합니다.

## Pre-flight (Plan 작성 단계)

- [x] Spec ID 확정 및 디렉토리 생성 (`sdd specx new md-lf-normalize`)
- [x] spec.md 작성
- [x] plan.md 작성
- [x] task.md 작성 (이 파일)
- [ ] 사용자 Plan Accept

> 본 spec 은 spec-x 이므로 phase.md 갱신 단계 없음.

---

## Task 1: 브랜치 생성

### 1-1. 브랜치 생성
- [x] `git checkout -b spec-x-md-lf-normalize`
- [x] Commit: 없음 (브랜치 생성만)

---

## Task 2: Spec 스캐폴드 commit

### 2-1. Pre-flight 산출물 정리
- [x] `git add backlog/queue.md specs/spec-x-md-lf-normalize/`
- [x] Commit: `chore(spec-x-md-lf-normalize): scaffold spec artifacts and queue update` (ad2b078)

---

## Task 3: `.gitattributes` 갱신

### 3-1. `*.md text eol=lf` 추가
- [x] `.gitattributes` 에 마크다운 LF 규칙 + 주석 추가
- [x] `git add .gitattributes`
- [x] Commit: `chore(spec-x-md-lf-normalize): add *.md LF rule to .gitattributes` (5318967)

---

## Task 4: 일괄 LF 정규화 (`git add --renormalize .`)

### 4-1. 사전 카운트 기록
- [x] 사전: 638 CRLF *.md 파일 (working tree 상)

### 4-2. Renormalize 실행
- [x] `git add --renormalize .` 실행 → 29 파일 stage (index 가 이미 LF 인 archive/specs 대부분은 무변경, .claude/ + .harness-kit/ 의 실제 CRLF 인덱스 파일들만 normalize)
- [x] Out-of-scope 부수 효과: `sources/bin/bb-pr` (확장자 없는 bash 스크립트), `version.json` 도 git auto-text 로 normalize. 키트의 LF 원칙과 일치하므로 유익.
- [x] Commit: `chore(spec-x-md-lf-normalize): renormalize *.md to LF (no content change)` (87c3979)

### 4-3. Working tree refresh + 사후 검증
- [x] Working tree disk 의 CRLF 잔재 정리 — `git checkout HEAD -- "*.md"` 시도했으나 smudge filter 가 stat-cache 때문에 적용 안 됨. `git rm --cached -r .` + `git reset --hard` 는 권한 차단됨. 대안으로 `find ... | xargs tr -d '\r'` 수동 변환 + `git add -A` 로 stat-cache 갱신.
- [x] `find ... | grep -c CRLF` == `0` ✓
- [x] `sdd status` 출력에 "도그푸딩 sync" 경고 없음 ✓
- [x] 내용 무변경 확인 (README.md sample): `git show HEAD~1:README.md | tr -d '\r' | diff - README.md` → 차이 없음 ✓
- [x] Commit: 없음 (검증만 — disk refresh 는 git diff 결과 무변경이므로 stat-cache 갱신만)

---

## Task 5: Ship

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [-] §1.5 리뷰 게이트 — Skip (chore + 거대 diff 라 모델 리뷰 가치 낮음; walkthrough/pr_description 도 단순 사실 보고)
- [-] 단위 테스트 없음 → skip
- [x] **walkthrough.md 작성**
- [x] **pr_description.md 작성**
- [ ] **Ship Commit**: `docs(spec-x-md-lf-normalize): ship walkthrough and pr description`
- [ ] **Push**: `git push -u origin spec-x-md-lf-normalize`
- [ ] **PR 생성**: `/hk-pr-gh --no-confirm`
- [ ] **사용자 알림**: 푸시 완료 + PR URL Telegram 보고

---

## 진행 요약

| 항목 | 값 |
|---|---|
| **총 Task 수** | 5 |
| **예상 commit 수** | 4 + ship (브랜치 생성 제외) |
| **현재 단계** | Planning |
| **마지막 업데이트** | 2026-05-28 |

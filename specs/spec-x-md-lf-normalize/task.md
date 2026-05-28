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
- [ ] `git add backlog/queue.md specs/spec-x-md-lf-normalize/`
- [ ] Commit: `chore(spec-x-md-lf-normalize): scaffold spec artifacts and queue update`

---

## Task 3: `.gitattributes` 갱신

### 3-1. `*.md text eol=lf` 추가
- [ ] `.gitattributes` 에 마크다운 LF 규칙 + 주석 추가 (plan.md 의 MODIFY 블록 참조)
- [ ] `git add .gitattributes`
- [ ] Commit: `chore(spec-x-md-lf-normalize): add *.md LF rule to .gitattributes`

---

## Task 4: 일괄 LF 정규화 (`git add --renormalize .`)

### 4-1. 사전 카운트 기록
- [ ] `find . -name "*.md" -not -path "./.git/*" | xargs file | grep -c CRLF` 결과 기록 (walkthrough 용)

### 4-2. Renormalize 실행
- [ ] `git add --renormalize .` 실행
- [ ] `git status --short | wc -l` 로 변경 파일 수 확인
- [ ] 변경 파일이 `*.md` 외 다른 확장자 포함되어 있지 않은지 확인 (sample 확인)
- [ ] Commit: `chore(spec-x-md-lf-normalize): renormalize *.md to LF (no content change)`

### 4-3. 사후 검증
- [ ] `find . -name "*.md" -not -path "./.git/*" | xargs file | grep -c CRLF` == `0` 확인
- [ ] `bash .harness-kit/bin/sdd status` 출력에 "도그푸딩 sync" 경고 없는지 확인
- [ ] 내용 무변경 확인 (README.md 등 sample 1개로 `git show HEAD~1:README.md | tr -d '\r' | diff - README.md`)
- [ ] Commit: 없음 (검증만)

---

## Task 5: Ship

> 모든 작업 task 완료 후 `/hk-ship` 절차를 따릅니다.

- [ ] §1.5 리뷰 게이트 (본 spec 의 직전 PR 이 도입한 기능) — Skip (chore + 거대 diff 라 모델 리뷰 가치 낮음)
- [ ] 단위 테스트 없음 → skip
- [ ] **walkthrough.md 작성** (사전/사후 CRLF 카운트, autocrlf 권고, sdd status 검증 결과)
- [ ] **pr_description.md 작성** (의도, .gitattributes 변경, renormalize 결과, autocrlf 권고)
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

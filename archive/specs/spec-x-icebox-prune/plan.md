# Implementation Plan: spec-x-icebox-prune

## 📋 Branch Strategy

- 신규 브랜치: `spec-x-icebox-prune` (브랜치 이름 = spec 디렉토리 이름, `feature/` prefix 없음)
- 시작 지점: `main`
- 첫 task 가 브랜치 생성을 수행함

## 🛑 사용자 검토 필요 (User Review Required)

> [!IMPORTANT]
> - [ ] 제거 대상 5개 항목이 정말 해소되었는지 — 각 항목이 대응 완료 spec slug 로 근거 추적됨 (spec.md 요구사항 표 참조). 5개 중 의심되는 항목이 있으면 Accept 전에 지적.

> [!WARNING]
> - [ ] 본 변경은 doc(대시보드) 정리만 수행. 코드/스크립트 동작 변경 없음 — breaking change 없음.

## 🎯 핵심 전략 (Core Strategy)

### 주요 결정

| 컴포넌트 | 전략 | 이유 |
|:---:|:---|:---|
| **제거 방식** | 5줄을 정확히 식별해 Edit 로 개별 삭제 | 인접 미해결 항목 오삭제 방지 |
| **검증 방식** | grep 으로 제거 확인 + git diff 로 영향 범위 확인 + `sdd status` 무손상 | 코드 테스트가 없는 doc 작업의 verification |
| **commit 단위** | 5줄 제거를 1 commit 으로 | 한 논리 단위 (해소 항목 정리), One Task = One Commit |

### 📑 ADR 후보

- [ ] ADR 가치 있는 결정 있음
- [x] 없음

## 📂 Proposed Changes

### Backlog Dashboard

#### [MODIFY] `backlog/queue.md`

🧊 Icebox 섹션에서 아래 5줄 제거 (각 줄 = 한 bullet).

1. `Telegram 응답 시 ack 중복 발송 — ...` → 해소: `spec-x-notify-drop-both`
2. `§5 stop notification 과 AskUserQuestion 옵션 번호 불일치 — ...` → 해소: `spec-x-notify-auq-scope-fix` + AUQ 미사용 정책
3. `Discord 마크다운 포맷팅 (notify.sh 채널별 분기) — ...` → 해소: `spec-x-notify-channel-formatter`
4. `update.sh semver_lt 함수 leo suffix 버그 — ...` → 해소: `spec-x-update-semver-suffix-fix`
5. `CC 네이티브 기능 도입 — 2단계 정책 spec (native-feature-adoption-policy) — ...` → 해소: `spec-x-native-feature-adoption-policy`

> 자동 마커 영역 / 대기 Phase / 그 외 Icebox 항목은 무변경.

## 🧪 검증 계획 (Verification Plan)

### 단위 테스트 (필수)
```bash
# 본 spec 은 doc 정리 — 전용 단위 테스트 없음.
# 회귀 방지를 위해 기존 키트 테스트 스위트를 실행해 무손상 확인.
bash tests/run-all.sh   # (존재 시) 또는 개별 test-*.sh
```

### 수동 검증 시나리오
1. `grep -c "ack 중복 발송\|AskUserQuestion 옵션 번호\|채널별 분기\|semver_lt 함수 leo\|2단계 정책 spec" backlog/queue.md` → 기대: 0
2. `git diff backlog/queue.md` → 기대: 5줄 삭제만, 추가/수정 없음, 마커 영역 무변경
3. `bash .harness-kit/bin/sdd status` → 기대: 정상 출력 (파싱 오류 없음)

## 🔁 Rollback Plan

- 문제 발생 시 `git checkout backlog/queue.md` 또는 commit revert 로 즉시 복원 (단일 commit, 가역).
- 상태 영향 없음 — state.json 미변경 (spec-x bookkeeping 은 `sdd specx done` 이 별도 처리).

## 📦 Deliverables 체크

- [ ] task.md 작성 (다음 단계)
- [ ] 사용자 Plan Accept 받음
- [ ] (실행 후) 모든 task 완료
- [ ] (실행 후) walkthrough.md / pr_description.md ship

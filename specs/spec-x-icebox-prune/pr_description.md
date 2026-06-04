# chore(spec-x-icebox-prune): Icebox 해소 항목 5개 정리

## 📋 Summary

### 배경 및 목적
`backlog/queue.md` 의 🧊 Icebox 에 이미 완료된 spec 으로 해소된 항목 5개가 남아 있어, Icebox 검토 시 미해결 항목과 섞여 신뢰도·가독성을 떨어뜨렸다. 각 항목은 `완료` 섹션에 동일 slug 의 spec 이 존재해 대응이 명확히 추적된다. 본 PR 은 그 5줄을 제거해 대시보드 정확도를 회복한다.

### 주요 변경 사항
- [x] Telegram 응답 ack 중복 발송 → 해소: `spec-x-notify-drop-both`
- [x] §5 stop ↔ AskUserQuestion 옵션 번호 불일치 → 해소: `spec-x-notify-auq-scope-fix` (+ AUQ 미사용 정책)
- [x] Discord 마크다운 포맷팅 (채널별 분기) → 해소: `spec-x-notify-channel-formatter`
- [x] `update.sh` semver_lt leo suffix 버그 → 해소: `spec-x-update-semver-suffix-fix`
- [x] CC 네이티브 2단계 정책 spec → 해소: `spec-x-native-feature-adoption-policy`

### Phase 컨텍스트
- **Phase**: 없음 (spec-x, Phase 비소속)
- **본 SPEC 의 역할**: Icebox 위생 — 죽은 항목 제거로 향후 promote 판단의 정확도 확보.

## 🎯 Key Review Points

1. **제거 범위**: Icebox 5줄만 삭제. 나머지 미해결 항목 / 대기 Phase / sdd 자동 마커 영역은 무변경 (`git diff` net -5).
2. **해소 근거**: 각 제거 항목이 `완료` 섹션의 동일 slug spec 으로 추적되는지 확인 (Summary 표 참조).

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-sdd-queue-redesign.sh   # 5/5 PASS (queue/marker toolchain)
```

### 수동 검증 시나리오
1. **grep 부재 확인**: 5개 항목 distinctive 문구 검색 → 0 matches.
2. **diff 영향 범위**: `git diff backlog/queue.md` → `@@ -36,16 +36,11 @@`, 삭제 5줄만, keep 항목·마커 무변경.
3. **파싱 무손상**: `sdd status --no-drift` → 정상 출력.

> 본 변경은 docs-only — 코드 리뷰 게이트 `docs-only` 사유로 Skip (walkthrough 기록).

## 📦 Files Changed

### 🛠 Modified Files
- `backlog/queue.md` (+0, -5): Icebox 해소 항목 5줄 제거

### 🆕 New Files (spec 산출물)
- `specs/spec-x-icebox-prune/spec.md`
- `specs/spec-x-icebox-prune/plan.md`
- `specs/spec-x-icebox-prune/task.md`
- `specs/spec-x-icebox-prune/walkthrough.md`
- `specs/spec-x-icebox-prune/pr_description.md`

**Total**: 6 files (1 modified + 5 spec artifacts)

## ✅ Definition of Done

- [x] 5개 항목이 `backlog/queue.md` 에서 제거됨 (grep 0)
- [x] 미해결 항목 / 자동 마커 영역 무변경 (diff 검토)
- [x] `sdd status` 정상 동작
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 브랜치 push + PR 생성
- [x] 사용자 검토 요청 알림

## 🔗 관련 자료

- Walkthrough: `specs/spec-x-icebox-prune/walkthrough.md`
- 선례: `8ac1d9e chore: drop stale spec-x-sdd-bugfix` (해소 항목 제거)

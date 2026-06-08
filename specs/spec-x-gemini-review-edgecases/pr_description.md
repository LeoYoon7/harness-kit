fix(spec-x-gemini-review-edgecases): gemini-review.sh 엣지케이스 2종 수정

## 📋 Summary

### 배경 및 목적

`gemini-review.sh`(cross-model 코드 리뷰 게이트)의 실증된 동작 결함 2종을 수정합니다. 직전 `spec-x-gemini-review-sandbox` 가 안전성(워크스페이스 변조) 결함을 닫았고, 본 spec 은 그 위에 남아 있던 동작 결함(spec-21-01 발견)을 보강합니다.

### 주요 변경 사항

- [x] **(a) base 브랜치 부재 시 main fallback** — base-branch phase 의 첫 spec 은 base 브랜치가 hk-ship 시점에 생성되어 작업 중엔 없다(constitution §3.1). ref 부재를 빈-diff 로 오진단("리뷰할 변경이 없습니다")하던 것을 명시적 `main` fallback + ⚠ 안내로 교정.
- [x] **(b) 비-ASCII argv 손상 회피** — 한국어 리뷰 지시문을 `gemini -p` argv → stdin 입력 본문 최상단으로 이동, `-p` 는 ASCII 영어 포인터로 대체. Windows git-bash 의 CP949 argv 재인코딩 손상 회피.
- [x] **(c) stale Icebox 정리** — 이미 해결된 `plan-mode 위반` 라인 + 본 spec 이 닫는 `엣지케이스 2종` 라인 완료 표기.

### Phase 컨텍스트
- **Phase**: 없음 (spec-x — 비소속)
- **본 SPEC 의 역할**: ship 코드 리뷰 게이트 도구의 신뢰성 보강 (도그푸딩 직접 영향 — 본 환경=Windows git-bash).

## 🎯 Key Review Points

1. **base fallback 가드** (`gemini-review.sh`): `git rev-parse --verify --quiet "${BASE}^{commit}"` 실패 + base≠main 일 때만 fallback. base 실재 시 무회귀. main 자체 부재는 범위 외(주석 명시).
2. **지시문 stdin 이동**: argv 순수 ASCII 보장 + 영어 `-p` 가 stdin 상단 한국어 지시문을 가리켜 리뷰 형식 보존. sandbox 부수효과 가드(전후 스냅샷)와 무간섭.
3. **테스트 설계**: stub `gemini` capture 모드가 repo 밖 `$CAPTURE_DIR` 에만 기록(가드 오작동 회피). T6 마커는 ASCII(`Feature Envy`) — git-bash grep argv 손상 회피.

## 🧪 Verification

### 자동 테스트
```bash
bash tests/test-gemini-review-guard.sh
```

**결과 요약**:
- ✅ `test-gemini-review-guard.sh`: PASS=16 FAIL=0 (기존 12 + 신규 T6/T7)
- ✅ `test-bash-policy-headers.sh`: 4/4
- ✅ `test-install-manifest-sync.sh`: 6/6

### 수동 검증 시나리오
1. **argv ASCII**: capture stub → argv 순수 ASCII + 지시문 stdin 도달 → 통과.
2. **base fallback**: `baseBranch=phase-99-missing` 주입 → main fallback 후 리뷰 성공.
3. **parity**: `diff -q sources/bin/... .harness-kit/bin/...` → 차이 없음.

## 📦 Files Changed

### 🛠 Modified Files
- `sources/bin/gemini-review.sh`: base fallback 가드 + 지시문 argv→stdin 이동 + ASCII 영어 PROMPT.
- `.harness-kit/bin/gemini-review.sh`: 미러 동기화 (바이트 동일).
- `tests/test-gemini-review-guard.sh`: capture 모드 stub + T6(argv ASCII)/T7(base fallback) 추가.
- `backlog/queue.md`: Icebox stale 라인 2종 정리.

**Total**: 4 files changed (+ spec 산출물).

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (16/16)
- [x] `walkthrough.md` ship commit 완료
- [x] `pr_description.md` ship commit 완료
- [x] 코드 리뷰 (Opus) — Approve / Minor-1 반영
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Walkthrough: `specs/spec-x-gemini-review-edgecases/walkthrough.md`
- Code Review: `specs/spec-x-gemini-review-edgecases/code-review.md`
- 관련 spec: `spec-x-gemini-review-sandbox` (직전 안전성 가드)

docs(spec-x-cc-native-adoption): Claude Code 네이티브 기능 도입 적합도 조사

## 📋 Summary

### 배경 및 목적

Claude Code 네이티브 슬래시 명령(23개, 고유 기능 17개)을 harness-kit SDD 거버넌스에 도입할 방침이 미정이었다. 외부 검토 문서 2종이 4등급 적합도를 제시했으나 **메모리 기반 가정으로 작성돼 실제 구현과 4건 어긋난다**. 본 spec 은 그 어긋남을 교정하고 17개 기능을 실제 harness-kit 상태로 재검증하여 실행 가능한 도입 로드맵을 산출한 **Research Spec** 이다. 기능을 실제 도입·구현하지 않는다.

### 주요 변경 사항

- [x] `report.md` 신규 — 17개 고유 기능 × 7개 충돌 축 매트릭스, 4등급 재검증, 단계별 로드맵, Go/No-Go 종합
- [x] 문서 가정 교정 4건 — 알림 구조 / PR 플랫폼 / cross-model 리뷰 / AUQ 정책
- [x] `queue.md` Icebox 후속 spec 후보 4종 등록
- [x] 거버넌스/코드 무수정 — 순수 분석

### 컨텍스트
- **Phase**: 없음 (spec-x, Solo)
- **역할**: 네이티브 기능 도입의 근거 문서. 후속 2/3단계 spec 의 출발점

## 🎯 Key Review Points

1. **문서 가정 교정 4건 (report §3)**: 외부 문서를 그대로 수용하지 않고 실제 소스와 대조한 부분. 특히 cross-model 리뷰는 `/hk-gemini-review` 로 이미 통합됨.
2. **7충돌축 프레임 (report §2)**: 게이트/알림/멀티모델/PR플랫폼/세션라이프사이클/git hook/기존자산중복. 등급 판단의 추적 근거.
3. **두 시점 분기 (report §6)**: `gh` 전제 기능이 도그푸딩(GitHub)/target(Bitbucket)에서 갈림 — 키트 중립성 판단.
4. **Go/No-Go 종합 (report §6)**: 즉시 Go 9 / 조건부 Go 6 / 검증 후 2 / 보류 1 / 도입 불요 1.

## 🧪 Verification

### 자동 테스트
```bash
# 해당 없음 — docs-only (constitution §9.1 예외)
```

### 수동 검증 시나리오
1. **교정 4건 반영**: report §3.1~3.4 → ✅ 4건 명시
2. **17개 전수 분석**: report §4.0 매트릭스 + §4.1~4.4 → ✅ 누락 0, 각 Go/No-Go 존재
3. **로드맵 + 문서2 차이**: report §5 → ✅ 1/2/3단계 + 보류 + 교정 요약 표
4. **Icebox 등록**: queue.md → ✅ 후속 후보 4종

## 📦 Files Changed

### 🆕 New Files
- `specs/spec-x-cc-native-adoption/spec.md`: 조사 정의 (배경/요구사항/범위)
- `specs/spec-x-cc-native-adoption/plan.md`: 조사 수행 계획 (7축 프레임)
- `specs/spec-x-cc-native-adoption/task.md`: 조사 task (5개)
- `specs/spec-x-cc-native-adoption/report.md`: **Research Report 본체**
- `specs/spec-x-cc-native-adoption/walkthrough.md`: 작업 기록
- `specs/spec-x-cc-native-adoption/pr_description.md`: 본 PR 본문

### 🛠 Modified Files
- `backlog/queue.md` (+5): Icebox 후속 spec 후보 4종 등록

**Total**: 7 files

## ✅ Definition of Done

- [x] `report.md` 작성 — 17개 × 7축 + 4등급 재검증 + 로드맵
- [x] Trade-off 분석 + 기능별 Go/No-Go (Research §9.1)
- [x] `queue.md` Icebox 후속 후보 등록
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 브랜치 push (ship 시)
- [-] 단위 테스트 — docs-only 면제 (constitution §9.1)

## 🔗 관련 자료

- Research Report: `specs/spec-x-cc-native-adoption/report.md`
- 입력 문서: `D:\tmp\claude-code-기능-활용-가이드.md`, `claude-code-harness-kit-compatibility.md`
- 후속: queue.md Icebox `native-feature-adoption-policy` 외 3종

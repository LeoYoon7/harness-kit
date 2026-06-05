# Walkthrough - spec-21-04: 역할 기반 모델 config (de-hardcode)

## 📋 개요
본 작업은 거버넌스 문서(`agent.md`)에 하드코딩되어 있던 모델 이름(Opus/Sonnet)을 제거하고, 이를 역할 기반의 설정(`installed.json`의 `.models`)으로 관리하도록 개선했습니다. 이를 통해 모델 세대가 바뀌더라도 거버넌스 정책을 수정할 필요 없이 설정만으로 대응이 가능해졌습니다.

## 🛠️ 주요 변경 사항

### 1. 설정 관리 (sdd config models)
- `sdd config models`: 현재 설정된 역할별 모델 매핑 출력 (fallback 포함).
- `sdd config models <role> <model>`: 특정 역할(`director`, `worker`, `scout`)의 모델을 변경.
- `installed.json`에 `.models` 필드 도입 및 `install.sh` 시드 추가.

### 2. 거버넌스 탈-하드코딩 (§6.6)
- `agent.md` §6.6의 "runs on Opus" 등의 표현을 "runs as director (`models.director`)" 등으로 변경.
- 모델 할당 표를 모델 이름 중심에서 역할/티어 중심으로 재편 (4행 -> 3행).
- 단어 수 변화: 4706w -> **4696w (-10w)**.

### 3. 검증 자동화
- `tests/test-role-model-config.sh` 신규 작성: 설정 조회/변경, 거버넌스 참조 정합성, 이중 미러 parity 검증.

## 🧪 검증 결과
- `tests/test-role-model-config.sh`: **PASS (7/7)**
- `tests/test-governance-dedup.sh`: 무 NEW 회귀 (Check 3 red 유지 - 21-06 처리 대상).
- `tests/test-director-mode.sh`: **PASS**
- `tests/test-director-protocol.sh`: **PASS**

## 📝 결정 사항 및 메모
- **Role Taxonomy**: `director` (authoring/judgment/review), `worker` (execution), `scout` (analysis) 3종으로 확정.
- **Backward Compatibility**: 기존 설치 환경에서 `.models` 필드가 없어도 `sdd` 내부에 정의된 기본값(Opus/Sonnet)으로 폴백하여 정상 동작함.

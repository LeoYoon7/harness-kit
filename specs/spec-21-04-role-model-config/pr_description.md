# refactor(spec-21-04): role-based model config (de-hardcode 6.6)

## 📋 Summary

### 배경 및 목적

agent.md §6.6 이 모델 이름(Opus/Sonnet)을 하드코딩해, 모델 세대 churn(예: 4.7→4.8)마다 거버넌스를 수정해야 하는 부채가 있었다. spec-21-03 이 §6.8 에 director/worker *역할 언어*를 도입한 것과도 불일치했다. 본 spec 은 역할→모델 매핑을 config 로 분리하고 §6.6 을 de-hardcode 한다.

### 주요 변경 사항

- [x] `installed.json` `.models` 도입 — `director`/`worker`/`scout` 3역할 (install.sh 시드 + fallback)
- [x] `sdd config models` (list) + `sdd config models <role> <model>` (set) — 기존 `_config_*` 패턴 미러
- [x] agent.md §6.6 de-hardcode — 모델명 → 역할 참조(`models.*`), 표 4행→3행
- [x] ADR-011 Amendment — role-based config 근거 정합화 (§6.6 `(→ ADR-011)` 포인터 유효화)
- [x] `tests/test-role-model-config.sh` — 9 checks (list/set/de-hardcode/미러/미지원 role/fallback)

### Phase 컨텍스트

- **Phase**: `phase-21` (director-mode)
- **본 SPEC 의 역할**: 성공기준 5(역할 기반 모델 config). 모델 churn 에 거버넌스가 견디게 하고, §6.6 축소(-10w)로 21-06 다이어트 부담 경감.

## 🎯 Key Review Points

1. **de-hardcode 정합**: §6.6 표가 모델명 없이 역할(director/worker/scout) → `models.*` 참조. §6.8 역할 언어·ADR-011 Amendment 와 정합.
2. **backward compat (NFR1)**: `.models` 미존재 시 `_config_models` fallback(opus/sonnet/opus). test C7 로 검증.
3. **bash 3.2 호환**: `.models` 를 jq 로만 처리(연관배열 미사용), `_config_director_mode` 패턴 미러.
4. **단어 예산**: 본 spec 은 §6.6 축소로 -10w. Check 3 green 은 scope 외(→ 21-06).

## 🧪 Verification

```bash
bash tests/test-role-model-config.sh        # 9/9 PASS
bash tests/test-governance-dedup.sh         # 무 NEW 회귀 (Check 3 red 유지 — 21-06)
bash tests/test-director-mode.sh            # 10/10
bash tests/test-director-protocol.sh        # 13/13
```

**수동**: `sdd config models` → 역할 매핑 출력 / `.models` 삭제 후에도 fallback 동작.

## 📦 Files Changed

### 🆕 New Files
- `tests/test-role-model-config.sh` (+137): 검증 테스트(9 checks)

### 🛠 Modified Files
- `sources/bin/sdd` (+40) / `.harness-kit/bin/sdd` (미러): `_config_models` + `models)` 분기 + help
- `install.sh` (+1): installed.json `.models` 시드
- `.harness-kit/installed.json` (+1): `.models` 3역할
- `sources/governance/agent.md` (+11/-...) / `.harness-kit/agent/agent.md` (미러): §6.6 de-hardcode
- `docs/decisions/ADR-011-director-mode.md` (+9): role-based config Amendment
- `backlog/phase-21.md` / `backlog/queue.md`: spec-21-04 등록

**Total**: 15 files changed

## ✅ Definition of Done

- [x] 모든 단위 테스트 통과 (9/9)
- [x] 회귀 무 NEW (Check 3 red 유지 — 예상, 21-06)
- [x] `walkthrough.md` / `pr_description.md` ship commit
- [x] 코드 리뷰 (Opus — Approve, 권고 1/2 반영. Gemini 오작동으로 대체)
- [x] 사용자 검토 요청 알림 완료

## 🔗 관련 자료

- Phase: `backlog/phase-21.md`
- Walkthrough: `specs/spec-21-04-role-model-config/walkthrough.md`
- 관련 ADR: `docs/decisions/ADR-011-director-mode.md` (Amendment: role-based config)

# Issue 69 Keyboard Entry Points Tasks

Last Updated: 2026-06-19

## Checklist

- [x] Issue #69 본문과 댓글을 확인한다.
- [x] `dev/README.md`, `dev/templates/*`, `dev/codex-skill-playbook.md`, `dev/coding-conventions.md`의 관련 지침을 확인한다.
- [x] Track 6 findings 문서와 관련 코드 위치를 읽는다.
- [x] 각 리뷰 사항이 현재 코드 기준으로 타당한지 판단한다.
- [x] 수정 방향, 위험, 검증 기준을 작업 문서에 기록한다.
- [x] 오버레이 닫힘 상태를 extension-local `UserDefaults.standard` 저장으로 변경한다.
- [x] 한글/영문 오버레이 닫힘 상태가 독립적으로 유지되도록 구현한다.
- [x] EnglishKeyboard Debug/Release target에 `APPLICATION_EXTENSION_API_ONLY = YES`를 추가한다.
- [x] 가능한 경우 오버레이 상태 저장 helper의 단위 테스트를 추가하거나, 테스트가 부적합한 이유를 기록한다.
- [x] `HangeulKeyboard` scheme 빌드를 실행한다.
- [x] `EnglishKeyboard` scheme 빌드를 실행한다.
- [x] 전체 접근 미허용 상태에서 한글/영문 키보드 오버레이 닫힘 유지 동작을 수동 확인한다.
- [x] `dev/active/code-review-scope/code-review-scope-findings.md`의 Track 6 상태와 검증 결과를 갱신한다.
- [x] `git status --short`로 의도하지 않은 변경이 없는지 확인한다.
- [x] 완료 내용과 검증 결과를 최종 응답에 요약한다.

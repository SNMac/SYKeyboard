# Base Keyboard VC Responsibility Refactor Tasks

Last Updated: 2026-05-22

## Checklist

- [x] `dev/README.md`와 `dev/templates/` 구조를 확인한다.
- [x] `dev/codex-skill-playbook.md`의 `ios-keyboard-extension`, `hangeul-input-logic`, `docs-and-infrastructure` 관련 지침을 확인한다.
- [x] 현재 git 상태가 깨끗한지 확인한다.
- [x] 최근 `BaseKeyboardViewController` 리팩토링 커밋 목록을 확인한다.
- [x] `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`를 읽고 controller 로직 복제 범위를 확인한다.
- [x] 새 handoff 문서 3종을 `dev/active/base-keyboard-vc-responsibility-refactor/`에 작성한다.
- [x] 문서 생성 후 `git diff --check`를 실행한다.
- [x] 문서 생성 후 `git status --short --untracked-files=all`로 변경 범위를 확인한다.
- [x] 다음 세션에서 키보드 코드 품질 평가 방식을 확정한다.
- [x] 품질 평가 전 `BaseKeyboardViewController`의 책임 목록을 메서드 단위로 다시 작성한다.
- [x] 품질 평가 전 `KeyboardControllerSimulator.swift`와 `HangeulKeyboardCoreViewController.swift`의 중복/동기화 지점을 표로 정리한다.
- [x] 품질 평가 결과를 바탕으로 남은 리팩토링 후보를 우선순위화한다.
- [x] 첫 리팩토링 후보를 정할 때 기능 동일성 검증 기준과 관련 테스트를 먼저 명시한다.
- [x] keyboard layout/update helper를 동작 변경 없이 분리한다.
- [x] `KeyboardPresentationStatePolicyTests` RED/GREEN을 확인한다.
- [x] text interaction gesture 조건을 `KeyboardGesturePolicy`로 동작 변경 없이 분리한다.
- [x] `KeyboardGesturePolicyTests` RED/GREEN을 확인한다.
- [x] period shortcut 조건과 삭제 후 방지 상태를 `KeyboardPeriodShortcutPolicy`로 동작 변경 없이 분리한다.
- [x] `KeyboardPeriodShortcutPolicyTests` RED/GREEN을 확인한다.
- [ ] 한글 조합/삭제/드래그/undo 관련 controller 변경 시 `KeyboardControllerSimulator.swift`를 함께 갱신한다.
- [x] 변경 범위에 맞춰 targeted 테스트 또는 `SYKeyboardCore` 빌드를 실행한다.
- [x] 최종 통합 전 전체 `SYKeyboard` 테스트를 실행하거나, 실행하지 못한 이유를 문서화한다.

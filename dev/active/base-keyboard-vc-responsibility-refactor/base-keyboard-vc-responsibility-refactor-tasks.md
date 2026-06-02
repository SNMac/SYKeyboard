# Base Keyboard VC Responsibility Refactor Tasks

Last Updated: 2026-06-02

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
- [x] symbol keyboard 자동 전환과 입력 상태 표시 조건을 `KeyboardSymbolInputPolicy`로 동작 변경 없이 분리한다.
- [x] `KeyboardSymbolInputPolicyTests` RED/GREEN을 확인한다.
- [x] keyboard height 계산을 `KeyboardHeightPolicy`로 동작 변경 없이 분리한다.
- [x] `KeyboardHeightPolicyTests` RED/GREEN을 확인한다.
- [x] 기존 정책 테스트 묶음에 `KeyboardHeightPolicyTests`를 포함해 재확인한다.
- [x] action binding 감사표를 작성해 버튼별 control event와 gesture 등록 순서를 고정한다.
- [x] action binding 감사표 기준으로 다음 리팩토링 후보를 선별한다.
- [x] text interaction gesture 등록 대상 조건을 `KeyboardGesturePolicy`로 동작 변경 없이 분리한다.
- [x] 확장된 `KeyboardGesturePolicyTests` RED/GREEN을 확인한다.
- [x] text interaction 보조키/삭제/반복 삭제 순수 판단을 `KeyboardTextInteractionPolicy`로 동작 변경 없이 분리한다.
- [x] `KeyboardTextInteractionPolicyTests` RED/GREEN을 확인한다.
- [x] 단일 삭제 undo 기록 문자열 판단을 `KeyboardTextInteractionPolicy`로 동작 변경 없이 분리한다.
- [x] 확장된 `KeyboardTextInteractionPolicyTests` RED/GREEN을 확인한다.
- [x] suggestion 선택의 n-gram 앞 공백과 현재 단어 확정용 단어 추출을 `KeyboardSuggestionSelectionPolicy`로 동작 변경 없이 분리한다.
- [x] `KeyboardSuggestionSelectionPolicyTests` RED/GREEN을 확인한다.
- [x] suggestion 갱신 action 판단을 `KeyboardSuggestionSelectionPolicy`로 동작 변경 없이 분리한다.
- [x] 확장된 `KeyboardSuggestionSelectionPolicyTests` RED/GREEN을 확인한다.
- [x] undo/redo controls 표시 조건을 `KeyboardPresentationStatePolicy`로 동작 변경 없이 분리한다.
- [x] 확장된 `KeyboardPresentationStatePolicyTests` RED/GREEN을 확인한다.
- [x] undo/redo 기능 활성화 설정 조합을 `KeyboardPresentationStatePolicy`로 동작 변경 없이 분리한다.
- [x] 확장된 `KeyboardPresentationStatePolicyTests` RED/GREEN을 확인한다.
- [x] lexicon 로딩 조건을 `KeyboardSuggestionSelectionPolicy`로 동작 변경 없이 분리한다.
- [x] 확장된 `KeyboardSuggestionSelectionPolicyTests` RED/GREEN을 확인한다.
- [x] `BaseKeyboardViewController`를 iOS keyboard extension boundary로 유지하고 리팩토링 마감 결정을 문서화한다.
- [x] action binder, text proxy adapter, full suggestion coordinator 보류 사유를 문서화한다.
- [x] 다음 큰 개선 대상을 controller simulator 중복 축소와 suggestion/undo 도메인 테스트 안정화로 넘긴다.
- [ ] 한글 조합/삭제/드래그/undo 관련 controller 변경 시 `KeyboardControllerSimulator.swift`를 함께 갱신한다.
- [x] 변경 범위에 맞춰 targeted 테스트 또는 `SYKeyboardCore` 빌드를 실행한다.
- [x] 최종 통합 전 전체 `SYKeyboard` 테스트를 실행하거나, 실행하지 못한 이유를 문서화한다.

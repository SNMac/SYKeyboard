# Hangeul Controller Domain Stabilization Plan

Last Updated: 2026-06-03

## Goal

- `KeyboardControllerSimulator.swift`와 `HangeulKeyboardCoreViewController.swift`의 중복 상태 전이를 줄이고, suggestion/undo 도메인 테스트를 안정화한다.

## Current State

- 브랜치명은 `feat/#31-undo-redo`이다.
- `BaseKeyboardViewController`의 action registration 순서와 입력 이벤트 dispatch 순서는 변경하지 않았다.
- `HangeulCompositionState`가 한글 조합/삭제/드래그/repeat 상태 전이를 담당한다.
- `KeyboardControllerSimulator.swift`와 `HangeulKeyboardCoreViewController.swift`는 `HangeulCompositionState`를 공유한다.
- suggestion/undo는 production 수정 없이 도메인 경계 테스트를 보강했다.
- 관련 파일:
  - `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
  - `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`
  - `SYKeyboardTests/Controller/DubeolsikControllerTests.swift`
  - `SYKeyboardTests/Controller/NaratgeulControllerTests.swift`
  - `SYKeyboardTests/Controller/CheonjiinControllerTests.swift`
  - `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardUndoRedoManager.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`
  - `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`
  - `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`

## Approach

1. `HangeulCompositionState`를 새 순수 도메인 타입으로 추가했다.
2. RED/GREEN으로 상태 전이 테스트를 먼저 고정했다.
3. `KeyboardControllerSimulator`가 새 상태 타입을 사용하게 바꿨다.
4. `HangeulKeyboardCoreViewController`가 새 상태 타입을 사용하게 바꾸되, Base hook과 action 흐름은 유지했다.
5. suggestion/undo는 coordinator 추출 없이 정책/manager 테스트를 보강했다.
6. 작업 단위별 커밋 후 전체 `SYKeyboard` 테스트로 마감했다.

## Risks

- 한글 삭제/드래그/undo 경계는 회귀 위험이 높다.
- controller의 proxy side effect와 도메인 상태 전이가 불일치하면 실제 입력 텍스트가 깨질 수 있다.
- Base/action 흐름을 함께 바꾸면 회귀 원인 분리가 어려우므로 이번 범위에서 제외한다.

## Verification

최종 결과:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: `TEST SUCCEEDED`.

상태 타입 targeted 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests
```

한글 controller/simulator 집중 검증:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/DubeolsikControllerTests \
  -only-testing:SYKeyboardTests/NaratgeulControllerTests \
  -only-testing:SYKeyboardTests/CheonjiinControllerTests \
  -only-testing:SYKeyboardTests/HangeulDeleteButtonDragControllerTests
```

최종 통합 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

## Done Criteria

- [x] simulator와 controller가 같은 한글 상태 전이 타입을 공유한다.
- [x] Base/action registration 흐름은 변경되지 않는다.
- [x] suggestion/undo 도메인 테스트가 보강되어 있다.
- [x] 작업 단위별 커밋이 생성되어 있다.
- [x] 전체 `SYKeyboard` 테스트 결과가 기록되어 있다.

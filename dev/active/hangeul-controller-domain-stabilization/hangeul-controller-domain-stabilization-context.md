# Hangeul Controller Domain Stabilization Context

Last Updated: 2026-06-03

## Relevant Files

- `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`: 실제 한글 keyboard extension controller이며 버퍼 상태와 proxy side effect를 함께 처리한다.
- `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`: controller 버퍼 상태를 복제하는 테스트 helper다.
- `Modules/HangeulKeyboardCore/Domain/`: 새 `HangeulCompositionState`를 둘 위치다.
- `SYKeyboardTests/Controller/*ControllerTests.swift`: simulator 기반 한글 controller 레벨 회귀 테스트다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: 이번 범위에서 action 흐름을 변경하지 않을 기준 파일이다.
- `Modules/SYKeyboardCore/Presentation/Utils/KeyboardUndoRedoManager.swift`: undo/redo 도메인 manager다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`: suggestion 선택/갱신 순수 정책이다.
- `Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift`: controller와 simulator가 공유하는 한글 조합/삭제/드래그/repeat 상태 전이다.
- `SYKeyboardTests/Domain/HangeulCompositionStateTests.swift`: 상태 타입의 입력/스페이스/삭제/repeat/delete pan 회귀 테스트다.

## Facts Checked

- 2026-06-03 작업 시작 시 `git status --short --untracked-files=all`는 비어 있었다.
- 현재 브랜치는 `feat/#31-undo-redo`이다.
- `BaseKeyboardViewController.setActions()`는 feedback, input/switch, release 순서에 의존한다.
- Delete는 `.touchDown`, 일반 입력은 `.touchUpInside`, space period shortcut은 `.touchDownRepeat`에 의존한다.
- `HangeulKeyboardCoreViewController`는 `textInteractionWillPerform` / `textInteractionDidPerform` hook 순서로 delete touchDown 전후 상태를 저장한다.
- `KeyboardControllerSimulator`는 controller와 같은 버퍼 전이 로직을 복제하고 있으며, 파일 주석도 controller 변경 시 함께 수정하라고 명시한다.
- `HangeulCompositionState`를 추가했고, simulator와 `HangeulKeyboardCoreViewController`가 같은 상태 타입을 사용한다.
- Controller는 상태 전이가 반환한 `HangeulProxyEdit`만 `insertText`, `deleteText`, `replaceText`로 반영한다.
- Base/action registration과 gesture dispatch 흐름은 변경하지 않았다.
- suggestion/undo 보강 테스트는 production 수정 없이 기존 동작으로 통과했다.

## Decisions

- Base/action registration 순서와 dispatch 흐름은 이번 작업에서 변경하지 않는다.
- 한글 상태 전이는 새 도메인 타입으로 옮긴다.
- Controller는 proxy 반영과 UI/undo side effect를 계속 담당한다.
- Simulator는 새 도메인 타입을 사용해 테스트 helper 역할을 유지한다.
- suggestion/undo는 큰 coordinator 추출 없이 순수 도메인 테스트 보강을 우선한다.
- 삭제 중 committed 마지막 한글을 끌어오는 경우 proxy edit이 두 번 필요하므로 `HangeulCompositionTransition`이 `proxyEdits` 배열을 가진다.

## Open Questions

- 없음.

## Verification Notes

- RED: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/HangeulCompositionStateTests`가 `Cannot find 'HangeulCompositionState' in scope`로 실패함을 확인했다.
- GREEN: `HangeulCompositionStateTests` targeted 테스트가 `TEST SUCCEEDED`.
- Focused controller/simulator: `DubeolsikControllerTests`, `NaratgeulControllerTests`, `CheonjiinControllerTests`, `HangeulDeleteButtonDragControllerTests`가 `TEST SUCCEEDED`.
- Suggestion/undo: `KeyboardSuggestionSelectionPolicyTests`, `KeyboardUndoRedoManagerTests`가 `TEST SUCCEEDED`.
- Final: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`가 `TEST SUCCEEDED`.
- 최종 문서 갱신 전 `git status --short --untracked-files=all`는 비어 있었다.

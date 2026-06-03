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

## Facts Checked

- 2026-06-03 작업 시작 시 `git status --short --untracked-files=all`는 비어 있었다.
- 현재 브랜치는 `feat/#31-undo-redo`이다.
- `BaseKeyboardViewController.setActions()`는 feedback, input/switch, release 순서에 의존한다.
- Delete는 `.touchDown`, 일반 입력은 `.touchUpInside`, space period shortcut은 `.touchDownRepeat`에 의존한다.
- `HangeulKeyboardCoreViewController`는 `textInteractionWillPerform` / `textInteractionDidPerform` hook 순서로 delete touchDown 전후 상태를 저장한다.
- `KeyboardControllerSimulator`는 controller와 같은 버퍼 전이 로직을 복제하고 있으며, 파일 주석도 controller 변경 시 함께 수정하라고 명시한다.

## Decisions

- Base/action registration 순서와 dispatch 흐름은 이번 작업에서 변경하지 않는다.
- 한글 상태 전이는 새 도메인 타입으로 옮긴다.
- Controller는 proxy 반영과 UI/undo side effect를 계속 담당한다.
- Simulator는 새 도메인 타입을 사용해 테스트 helper 역할을 유지한다.
- suggestion/undo는 큰 coordinator 추출 없이 순수 도메인 테스트 보강을 우선한다.

## Open Questions

- `HangeulCompositionState`가 processor start/reset을 직접 호출할지, mutation으로 반환할지는 첫 RED/GREEN 구현 중 가장 단순한 방향으로 확정한다.
- Xcode synchronized root가 새 domain/test 파일을 자동 인식하는지, `project.pbxproj` membership exception 수정이 필요한지는 RED 실행 결과로 확인한다.

## Verification Notes

- 아직 구현 검증은 시작하지 않았다.

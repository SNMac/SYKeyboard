# Hangeul Controller Domain Stabilization Design

Last Updated: 2026-06-03

## Goal

`KeyboardControllerSimulator.swift`와 `HangeulKeyboardCoreViewController.swift`가 중복으로 관리하는 한글 버퍼 상태 전이를 순수 도메인 타입으로 옮기고, suggestion/undo 회귀 위험은 도메인 테스트로 보강한다.

## Scope

- `BaseKeyboardViewController`의 action registration 순서와 입력 이벤트 dispatch 순서는 변경하지 않는다.
- `.touchDown`, `.touchUpInside`, repeat timer, delete pan gesture 흐름은 유지한다.
- 한글 controller의 `textDocumentProxy` side effect는 controller에 남긴다.
- 새 도메인 타입은 한글 입력 상태 전이와 그 결과를 설명하는 값만 담당한다.

## Architecture

새 타입 `HangeulCompositionState`를 `Modules/HangeulKeyboardCore/Domain/`에 둔다. 이 타입은 `committedBuffer`, `composingBuffer`, `protectedCommittedCount`, delete pan 복구 상태, 마지막 입력값을 보관하고, processor 호출 결과를 상태에 반영한다.

Controller와 simulator는 같은 `HangeulCompositionState`를 사용한다. Simulator는 상태 전이 결과를 그대로 검증하고, controller는 상태 전이 결과에 맞춰 `insertText`, `replaceText`, `deleteText`, processor start/reset, undo commit 같은 UIKit side effect만 수행한다.

Suggestion/undo는 coordinator 추출 없이 현재 정책/manager 단위 테스트를 보강한다. 목적은 Base와 결합된 런타임 흐름을 더 건드리지 않고도 중요한 도메인 규칙을 고정하는 것이다.

## Components

- `HangeulCompositionState`: 한글 committed/composing/protected 상태와 삭제 드래그 복구 상태를 관리한다.
- `HangeulCompositionMutation`: controller가 proxy에 반영해야 하는 delete/insert 요청과 processor lifecycle action을 담는다.
- `KeyboardControllerSimulator`: `HangeulCompositionState`를 사용해 controller 레벨 테스트 헬퍼 역할을 유지한다.
- `HangeulKeyboardCoreViewController`: 상태 전이는 `HangeulCompositionState`에 위임하고, UI/proxy/undo side effect만 담당한다.
- `KeyboardSuggestionSelectionPolicy` / `KeyboardUndoRedoManager`: 추가 테스트로 selection, context, deferred commit 경계를 고정한다.

## Testing

TDD로 진행한다. 첫 테스트는 `HangeulCompositionStateTests`가 기존 simulator 대표 시나리오를 새 상태 타입으로 검증하도록 작성하고, 타입 미정의 컴파일 실패를 RED로 확인한다.

주요 검증 명령:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests
```

최종 검증 명령:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

## Risks

- 한글 삭제와 삭제 드래그는 `protectedCommittedCount`, 종성 복원, `tempDeletedCharacters`가 함께 움직여 회귀 위험이 높다.
- Controller가 proxy에 반영하는 delete/insert count와 도메인 상태의 committed/composing 전이가 어긋나면 실제 입력 텍스트만 깨질 수 있다.
- Base/action 흐름까지 동시에 바꾸면 회귀 원인 분리가 어려우므로 이번 범위에서 제외한다.

## Approved Direction

사용자는 2026-06-03에 “Base와 action 흐름은 건드리지 않는다”는 판단을 승인했다. 따라서 이번 구현은 한글 상태 도메인 추출과 테스트 안정화에 집중한다.

# Hangeul Controller Domain Test Stabilization Plan

Last Updated: 2026-06-26

## Goal

- GitHub Issue #91의 범위에 따라 `BaseKeyboardViewController` 대분해 대신 한글 controller/simulator 중복 축소와 suggestion/undo 도메인 테스트 안정화를 진행한다.
- 한글 입력, 삭제, 조합의 사용자 동작은 바꾸지 않고, 변경이 필요해 보이면 별도 fix/feature 이슈로 분리한다.

## Current State

- Issue #91은 열려 있으며 제목은 `[Refactor] 한글 controller 중복 축소와 suggestion/undo 도메인 테스트 안정화`다.
- 이슈의 방향은 현재 코드 기준으로 대체로 타당하며, 작업 결과 production 코드의 의도된 기능 변경 없이 controller의 중복 상태만 줄였다.
  - `HangeulCompositionState`는 이미 한글 조합/삭제 상태 전이를 공유하고 있다.
  - `KeyboardControllerSimulator`는 `HangeulCompositionState`를 사용하지만 controller 시뮬레이션 helper 역할과 테스트용 상태 세팅 API를 함께 가진다.
  - `HangeulKeyboardCoreViewController`에는 삭제 touchDown 직전 상태(`hadComposingBeforeDeleteTouchDown`, `composingBeforeDeleteTouchDown`, `committedBeforeDeleteTouchDown`)를 보관하고 restore replacement를 계산하는 코드가 남아 있다.
  - `SuggestionController`, `KeyboardSuggestionSelectionPolicy`, `KeyboardUndoRedoManager`, `KeyboardUndoRedoSession` 단위 테스트가 이미 있으므로 보강은 기존 테스트와 중복되지 않는 경계 위주로 해야 한다.
- 구현 후 상태:
  - 삭제 touchDown 전 상태 snapshot은 `HangeulCompositionState`가 소유한다.
  - `HangeulKeyboardCoreViewController`는 버튼 lifecycle에서 `beginDeleteButtonTouchDown()`, `endDeleteButtonTouchDown()`, `cancelDeleteButtonTouchDown()`만 호출한다.
  - `deleteBackward()`, `deleteButtonPanDeleteText()`, `deleteButtonPanRestoreText()`, undo/redo commit 호출 순서는 바꾸지 않았다.
  - `KeyboardControllerSimulator`는 이미 `HangeulCompositionState`를 사용하므로 추가 production 변경 없이 역할을 유지했다.
- 관련 파일:
  - `Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift`
  - `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
  - `SYKeyboardTests/Domain/HangeulCompositionStateTests.swift`
  - `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`
  - `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/KeyboardUndoRedoManager.swift`
  - `SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift`
  - `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`
  - `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`
  - `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`

## Technical Evaluation

- 타당함: `KeyboardControllerSimulator` 제거보다 얇게 유지하는 방향.
  - 근거: simulator는 실제 상태 전이를 `HangeulCompositionState`에 위임하고 있어 독립 구현체는 아니다.
  - 주의: 테스트 helper가 controller의 두 번째 구현체처럼 커지는 것은 막아야 한다.
- 타당함: 삭제 touchDown/pan/restore bookkeeping을 `HangeulCompositionState` 중심으로 정리하는 방향.
  - 근거: `HangeulCompositionState.deleteButtonTouchDown(using:)`은 이미 touchDown 전 상태를 내부에서 기록해 restore replacement를 계산한다.
  - 근거: controller에는 같은 목적의 touchDown 전 상태 저장과 `deletePanRestoreReplacementAfterDeleteTouchDown()`가 별도로 남아 있다.
  - 주의: 실제 버튼 이벤트 타이밍은 변경하지 않는다.
- 타당함: suggestion 흐름을 `BaseKeyboardViewController` 직접 테스트보다 domain/policy 테스트로 보강하는 방향.
  - 근거: `BaseKeyboardViewController`는 `KeyboardSuggestionSelectionPolicy`와 `SuggestionController`를 통해 selection/update 조건을 이미 분리한다.
  - 주의: UIKit controller 통합 동작이 필요한 회귀는 별도 integration 검증으로 다뤄야 한다.
- 타당함: undo/redo 흐름을 `KeyboardUndoRedoSession`/manager 단위에서 먼저 검증하는 방향.
  - 근거: 지연 확정, cursor context, 적용 중 history 무효화 방지는 UI보다 session/manager 책임에 가깝다.
  - 주의: `isApplyingEdit` 중 record 방지는 현재 `BaseKeyboardViewController` 호출 경로까지 함께 확인해야 한다.
- 타당함: base coordinator 대분해, `textDocumentProxy` adapter, full suggestion coordinator 추출을 제외하는 범위.
  - 근거: 이번 이슈의 직접 목표는 회귀 위험이 높은 입력 동작 변경이 아니라 중복 축소와 테스트 안정화다.

## Approach

1. Baseline 확인
   - 작업 전 `git status --short`로 변경 범위를 확인한다.
   - targeted 한글 composition/simulator/controller 관련 테스트를 먼저 실행한다.
2. 한글 삭제 상태 전이 보강
   - `HangeulCompositionStateTests`에 delete touchDown 후 첫 pan restore 정책 회귀 테스트를 추가한다.
   - controller가 별도로 보관하는 touchDown 전 상태를 `HangeulCompositionState.deleteButtonTouchDown(using:)` 경로로 대체할 수 있는지 작은 단위로 검토한다.
   - 대체 시 `textInteractionWillPerform`, `textInteractionDidPerform`, `deleteBackward`, `deleteButtonPanDeleteText`, `deleteButtonPanRestoreText` 이벤트 순서를 유지한다.
3. Simulator 역할 축소
   - `KeyboardControllerSimulator`가 테스트 helper임을 문서화하거나, controller 전용 상태 세팅 API를 `HangeulCompositionState` 중심 테스트로 이동한다.
   - simulator에서 실제 controller 상태 전이를 재구현하는 코드가 생기지 않도록 한다.
4. Suggestion domain/policy 테스트 보강
   - `SuggestionControllerTextReplacementTests`는 선택 텍스트, 커서 앞 context, replacement history 경계를 중심으로 빠진 케이스만 추가한다.
   - `SuggestionControllerPreparationTests`는 suspend 해제, 엔진 준비, n-gram callback 경계 중 기존 테스트와 중복되지 않는 케이스를 추가한다.
   - `KeyboardSuggestionSelectionPolicyTests`는 selection/update/base text 조건의 빈 문자열, 다중 공백, nil context 경계를 보강한다.
5. Undo/redo domain 테스트 보강
   - `KeyboardUndoRedoManagerTests`에 pending group 지연 확정, cursor context 적용 가능성, undo/redo 적용 중 history 무효화 방지 경계를 추가한다.
   - session 테스트에서 `performApplyingEdit(_:)` 중 `shouldInvalidateAfterTextChange`가 false를 유지하는지 검증한다.
6. 검증
   - targeted 테스트를 먼저 통과시킨 뒤 전체 `SYKeyboard` 테스트와 `HangeulKeyboard` scheme 빌드를 실행한다.

## Risks

- 한글 삭제 touchDown/pan/restore는 버튼 이벤트 순서, 반복 삭제, 임시 복구 stack과 맞물려 회귀 위험이 높다.
- `HangeulCompositionState`로 상태를 옮길 때 controller의 `deleteBackwardWillPerform()` undo/redo commit 타이밍을 바꾸면 기존 undo grouping이 달라질 수 있다.
- suggestion 테스트를 과도하게 UI controller 쪽으로 확장하면 brittle test가 될 수 있다.
- undo/redo session 테스트는 debounce timer가 `RunLoop.main`에 의존하므로 비동기 테스트가 불안정해질 수 있다. 가능한 한 직접 commit API나 짧은 session 단위 검증을 우선한다.

## Verification

작업 전 baseline:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests
```

결과: 통과.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests \
  -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests
```

결과: 통과.

작업 중 TDD red:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests/testDeleteTouchDown경계기록_첫Pan복구정책
```

결과: `HangeulCompositionState`에 `beginDeleteButtonTouchDown`/`endDeleteButtonTouchDown`가 없어 컴파일 실패했다. 이후 구현으로 green 전환했다.

작업 후 전체 검증:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: 통과. `** TEST SUCCEEDED **`

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

결과: 샌드박스에서 `CoreSimulatorService connection became invalid`로 실패했다. 권한 있는 재실행은 Crashlytics dSYM/build metadata 외부 전송 가능성 때문에 자동 승인 거절됨. 단, 직전 전체 `SYKeyboard` 테스트에서 `HangeulKeyboard` dependency 빌드와 테스트 실행은 통과했다.

필요 시 수동 확인:

- 실제 입력 앱에서 한글 키보드를 열고 삭제 버튼 touchDown, 왼쪽 pan 삭제, 오른쪽 pan restore, 반복 삭제 종료 후 조합 복원 흐름을 확인한다.

## Done Criteria

- `HangeulCompositionStateTests`가 delete touchDown 후 첫 pan restore 정책을 명시적으로 검증한다.
- `HangeulKeyboardCoreViewController`의 삭제 touchDown/pan/restore 상태 관리 중 중복된 부분이 줄거나, 옮기지 않는 이유가 문서화된다.
- `KeyboardControllerSimulator`가 테스트 helper 역할을 넘어서지 않도록 정리된다.
- suggestion/undo domain 테스트가 기존 케이스와 중복되지 않는 경계를 보강한다.
- targeted 테스트, 전체 `SYKeyboard` 테스트, `HangeulKeyboard` build 결과가 기록된다.
- 한글 입력/삭제/조합 사용자 동작 변경이 없다.

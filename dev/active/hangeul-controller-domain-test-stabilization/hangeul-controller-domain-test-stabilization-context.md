# Hangeul Controller Domain Test Stabilization Context

Last Updated: 2026-06-26

## Relevant Files

- `Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift`: 한글 입력, 스페이스, 삭제, 반복 입력/삭제, delete pan restore 상태 전이를 담당한다.
- `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`: 한글 키보드 controller이며 `HangeulCompositionState` 전이를 `textDocumentProxy` 편집으로 적용한다.
- `SYKeyboardTests/Domain/HangeulCompositionStateTests.swift`: `HangeulCompositionState`의 입력/삭제/반복 삭제/delete pan 상태를 검증한다.
- `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`: controller의 핵심 상태 전이를 테스트하기 위한 helper다. 현재 실제 상태 전이는 `HangeulCompositionState`에 위임한다.
- `Modules/SYKeyboardCore/Domain/SuggestionController.swift`: text replacement, predictive text, n-gram 후보 갱신을 담당한다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`: suggestion 선택/갱신 조건을 UI와 분리한 policy다.
- `Modules/SYKeyboardCore/Presentation/Utils/KeyboardUndoRedoManager.swift`: undo/redo edit, cursor context matching, session 지연 commit과 적용 중 상태를 담당한다.
- `SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift`: text replacement와 복구 history를 검증한다.
- `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`: suggestion engine 지연 준비와 n-gram load callback을 검증한다.
- `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`: suggestion selection/update policy를 검증한다.
- `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`: undo/redo manager, cursor navigator, session 일부를 검증한다.

## Facts Checked

- GitHub Issue #91은 2026-06-22 03:06:20 UTC에 생성되었고 현재 open 상태다.
- Issue #91은 `BaseKeyboardViewController` 추가 분해를 이번 범위에서 제외한다.
- Issue #91은 한글 입력/삭제/조합 동작 변경을 금지하고, 변경이 필요하면 별도 fix/feature 이슈로 분리하도록 적고 있다.
- `HangeulCompositionState`에는 `temporaryDeletedCharacters`, `shouldSkipNextDeletePanRestore`, `nextDeletePanRestoreReplacement`가 있다.
- `HangeulCompositionState.deleteButtonTouchDown(using:)`은 삭제 전 composing/committed 상태를 내부에서 캡처하고 `deletePanRestoreReplacementAfterDeleteTouchDown(composingBeforeDelete:committedBeforeDelete:)`로 replacement를 계산한다.
- `HangeulKeyboardCoreViewController`에도 `hadComposingBeforeDeleteTouchDown`, `composingBeforeDeleteTouchDown`, `committedBeforeDeleteTouchDown`가 남아 있다.
- `HangeulKeyboardCoreViewController.textInteractionWillPerform(button:)`는 delete touchDown 직전 상태를 저장하고, delete가 아닌 버튼이면 delete pan restore policy를 초기화한다.
- `HangeulKeyboardCoreViewController.textInteractionDidPerform(button:)`는 delete 버튼일 때 `compositionState.setDeletePanRestorePolicy(...)`를 다시 호출한다.
- `KeyboardControllerSimulator`는 `HangeulCompositionState`를 내부에 두며 `setDeleteDragStateForTesting(...)` 같은 테스트 helper API를 노출한다.
- `SuggestionControllerTextReplacementTests`, `SuggestionControllerPreparationTests`, `KeyboardSuggestionSelectionPolicyTests`, `KeyboardUndoRedoManagerTests`는 이미 존재한다.
- `KeyboardUndoRedoSession.performApplyingEdit(_:)`와 `shouldInvalidateAfterTextChange(...)`는 적용 중 text change 무효화 방지를 위한 hook을 가진다.
- 구현 후 `HangeulKeyboardCoreViewController`의 `hadComposingBeforeDeleteTouchDown`, `composingBeforeDeleteTouchDown`, `committedBeforeDeleteTouchDown`는 제거됐다.
- 구현 후 `HangeulCompositionState`는 delete touchDown snapshot lifecycle을 내부에서 관리한다.
- `deleteBackward()`와 delete pan proxy edit 적용 경로는 변경하지 않았다.

## Evaluation Notes

- 이슈의 핵심 방향은 타당하다.
  - 근거: 상태 전이를 이미 분리한 `HangeulCompositionState`가 있으므로 `BaseKeyboardViewController`를 더 쪼개기보다 남은 중복 상태를 줄이는 편이 범위가 작다.
- 단, controller 상태를 무리하게 제거하면 버튼 gesture lifecycle을 바꿀 수 있다.
  - 구현 전 `TextInteractionGestureController`와 `BaseKeyboardViewController.performTextInteraction(for:)` 호출 순서를 함께 확인해야 한다.
- suggestion/undo 테스트 보강은 타당하지만 이미 있는 테스트와 중복되면 유지 비용만 늘어난다.
  - 새 테스트는 “기존 테스트가 말하지 않는 경계 조건”만 추가한다.
- `KeyboardControllerSimulator`를 삭제하는 것은 현재 이슈 문구와 맞지 않는다.
  - 이슈는 simulator 제거가 아니라 얇게 유지하거나 역할을 갱신하는 방향이다.

## Decisions

- 작업 이름은 `hangeul-controller-domain-test-stabilization`으로 둔다.
- 이번 작업은 신규 큰 coordinator, proxy adapter, full suggestion coordinator 추출을 하지 않는다.
- 한글 동작 변경이 감지되면 리팩터링 범위에서 처리하지 않고 별도 이슈로 분리한다.
- baseline 테스트를 먼저 실행하고, 실패가 있으면 구현 전에 현재 실패인지 변경으로 인한 실패인지 구분한다.
- Xcode 샌드박스 권한 오류가 발생하면 같은 명령을 권한 있는 실행으로 재시도하고, 최종 문서에는 샌드박스 실패와 권한 있는 실행 결과를 구분한다.
- Production 코드의 기능 변경 여지는 삭제 touchDown/pan/restore 경계에만 있었다. 이를 줄이기 위해 버튼 이벤트 순서와 proxy edit 적용 코드는 유지하고, snapshot 보관 위치만 controller에서 domain state로 옮겼다.
- `KeyboardControllerSimulator`는 이미 `HangeulCompositionState`를 쓰는 helper이므로 이번 작업에서는 production/test helper 구조를 더 흔들지 않았다.
- `SuggestionControllerPreparationTests`에 처음 추가했던 suspend 중 n-gram callback 테스트는 grouped 실행에서 불안정해 제거하고, 동기적인 clear 후 callback 경계 테스트로 대체했다.

## Open Questions

- 실제 입력 앱에서 삭제 버튼 touchDown, 왼쪽 pan 삭제, 오른쪽 pan restore를 수동으로 다시 확인하면 더 좋다.
- `HangeulKeyboard` scheme 단독 빌드는 샌드박스 CoreSimulator 실패와 권한 있는 실행 승인 거절로 별도 성공 결과를 얻지 못했다.

## Verification Notes

- 문서 작성 전 확인 명령:

```sh
git status --short
```

  - 결과: 출력 없음. 작업 전 워크트리는 깨끗했다.

```sh
gh issue view 91 --repo SNMac/SYKeyboard --json number,title,state,author,createdAt,updatedAt,body,labels,comments
```

  - 결과: Issue #91 본문과 체크리스트를 확인했다. comments는 비어 있었다.

```sh
rg --files | rg 'HangeulCompositionState|HangeulKeyboardCoreViewController|KeyboardControllerSimulator|SuggestionController|KeyboardSuggestionSelectionPolicy|KeyboardUndoRedo'
```

  - 결과: 이 문서의 Relevant Files에 적은 파일들을 확인했다.

```sh
sed -n '1,260p' Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift
sed -n '260,620p' Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift
sed -n '1,260p' Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift
sed -n '260,620p' Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift
```

  - 결과: delete touchDown/pan/restore 관련 상태가 state와 controller 양쪽에 남아 있음을 확인했다.

```sh
sed -n '1,260p' SYKeyboardTests/Utils/KeyboardControllerSimulator.swift
sed -n '1,360p' SYKeyboardTests/Domain/HangeulCompositionStateTests.swift
```

  - 결과: simulator는 `HangeulCompositionState`를 공유하고, state tests에는 delete pan 중복 방지와 pan 종료 초기화 테스트가 이미 있음을 확인했다.

```sh
sed -n '1,290p' SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift
sed -n '1,230p' SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift
sed -n '1,260p' SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift
sed -n '1,460p' SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift
```

  - 결과: suggestion/undo 도메인 테스트가 이미 존재하므로 중복 없는 경계 보강이 필요하다고 판단했다.

- 이 문서 작성 단계에서는 Xcode 테스트를 실행하지 않았다. 테스트 실행은 구현 작업의 baseline 단계로 남긴다.

- 구현 전 baseline:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests
```

  - 결과: 통과.

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

  - 결과: 통과.

- 구현 후 targeted 검증:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests \
  -only-testing:SYKeyboardTests/HangeulDeleteButtonDragControllerTests
```

  - 결과: 통과.

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

  - 결과: 통과.

- 구현 후 전체 검증:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

  - 결과: 통과. `** TEST SUCCEEDED **`

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

  - 결과: 샌드박스에서 `CoreSimulatorService connection became invalid`로 실패.
  - 권한 있는 재실행은 Crashlytics 외부 전송 가능성 때문에 자동 승인 거절됨.

- 사용자 실기기 수동 확인:

```text
한글 키보드 실제 입력 앱에서 삭제 버튼 단일 탭, 왼쪽 pan 삭제, 오른쪽 pan restore, 반복 삭제 후 조합 복원 흐름 확인
```

  - 결과: 정상 동작 확인.

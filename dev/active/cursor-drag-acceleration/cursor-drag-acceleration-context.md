# Cursor Drag Acceleration Context

Last Updated: 2026-06-06

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`: primary/delete 버튼 pan gesture의 활성화, 이동 간격 판정, delegate 호출을 담당한다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: `TextInteractionGestureControllerDelegate` 구현체이며, primary pan에서는 커서를 한 칸 이동하고 delete pan에서는 삭제/복구를 수행한다.
- `Modules/SYKeyboardCore/Presentation/Utils/Enums/PanDirection.swift`: pan 방향 enum이다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardGesturePolicy.swift`: gesture 등록 조건 정책이다. 새 step 계산 정책을 이 파일에 섞기보다 별도 policy로 두는 편이 테스트와 책임 분리에 맞다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/CursorDragAccelerationPolicy.swift`: cursor drag step 계산과 실제 적용 가능한 step 제한을 담당한다.
- `Modules/SYKeyboardCore/Domain/SuggestionController.swift`: predictive text 준비 완료 후 후보 갱신 callback을 처리한다.
- `Modules/SYKeyboardCore/Storage/DefaultValues.swift`: `cursorActiveDistance = 30.0`, `cursorMoveInterval = 5.0` 기본값이 있다.
- `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`: 키보드 extension 런타임에서 cursor 설정값을 읽는다.
- `SYKeyboard/Presentation/KeyboardSettings/CursorMovementSettingsView.swift`: 사용자가 활성화 거리와 이동 간격을 조절하는 SwiftUI 설정 화면이다.
- `SYKeyboardTests/Utils/KeyboardGesturePolicyTests.swift`: gesture policy 테스트 스타일 참고 파일이다.
- `SYKeyboardTests/Utils/CursorDragAccelerationPolicyTests.swift`: cursor drag step 계산과 실제 적용 step 제한 테스트다.
- `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`: n-gram 준비/로딩 완료 후 후보 갱신 테스트다.
- `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`: 삭제 버튼 drag 삭제/복구 회귀 테스트다.
- `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`: cursor context 및 undo/redo anchor 검증이 있다.

## Facts Checked

- Issue #49는 2026-06-03 생성된 open enhancement 이슈다.
- 이슈 요구사항은 좌우 드래그 커서 이동에 가속도 기반 이동량 보정을 적용하고, 최소/최대 step 제한을 두는 것이다.
- 현재 `TextInteractionGestureController.onPanGestureChanged(_:)`는 `currentPoint.x - intervalReferPanPoint.x`의 절댓값이 `cursorMoveInterval` 이상이면 delegate를 한 번 호출한다.
- 현재 primary pan delegate는 `resetInputBuffer()` 후 방향에 따라 `moveCursorLeftIfPossible()` 또는 `moveCursorRightIfPossible()`를 한 번 호출한다.
- 현재 delete pan delegate는 방향에 따라 `performDeleteButtonPanDeleteIfPossible()` 또는 `performDeleteButtonPanRestoreIfPossible()`를 한 번 호출한다.
- `cursorActiveDistance`와 `cursorMoveInterval`은 이미 앱 설정 화면에서 조절 가능하다.
- `TextInteractionGestureController`는 현재 시간, 속도, 가속도 상태를 저장하지 않는다.
- `git status --short`는 문서 생성 전 비어 있었다.
- 사용자 의도는 `cursorMoveInterval`을 느린 드래그의 커서 이동 간격으로 유지하고, 드래그 속도가 빨라질 때 이 값을 기반으로 배수 또는 상수 보정을 적용해 가속도를 붙이는 것이다.
- 구현 후 `TextInteractionGestureController`는 pan update 시간과 이전 velocity를 저장하고, primary cursor 이동에만 step 보정을 적용한다.
- 삭제 버튼 drag 삭제/복구는 기존처럼 delegate 호출 1회당 1회 처리한다.
- 2026-06-05 실기기 테스트에서 커서 이동 시작 거리가 늘어난 느낌과 첫 이동이 4칸으로 튀는 증상이 확인됐다.
- 원인은 cursor 활성화 전 누적된 드래그 거리(`initialPanPoint`부터 `currentPoint`)가 활성화 직후 첫 `baseTicks` 계산에 그대로 들어간 것이다.
- 수정 후 cursor 활성화 첫 이벤트는 `initialMovement`로 최대 1칸만 처리하고, `intervalReferPanPoint`와 시간/velocity 기준을 현재 위치로 재설정한다.
- 2026-06-05 추가 피드백으로 속도 계산은 `QuartzCore`/`CACurrentMediaTime()` 직접 계산보다 UIKit의 `UIPanGestureRecognizer.velocity(in:)`를 사용하는 편이 더 적절하다고 확인했다.
- 수정 후 `TextInteractionGestureController`는 `QuartzCore`를 import하지 않고, `previousPanUpdateTime`도 저장하지 않는다.
- 사용자 설정 범위는 `cursorMoveInterval = 1.0...9.0`(`0.5` 단위, 기본값 `5.0`), `cursorActiveDistance = 10.0...50.0`(`1.0` 단위, 기본값 `30.0`)이다.
- 2026-06-05 threshold 조정 후 `650pt/s`는 기본 interval에서 속도 보정을 만들지 않고, `1200pt/s`는 very fast가 아니라 fast 보정만 만든다.
- 첫 velocity 샘플은 이전 속도가 0이므로 가속 증가 보정을 적용하지 않는다.
- 2026-06-06 PR #58 review에서 `SuggestionController.refreshSuggestionsAfterNGramLoadIfNeeded()`의 UI/delegate 갱신 main-thread 보장과 다중 cursor step의 단일 `adjustTextPosition(byCharacterOffset:)` 적용 필요성이 제기됐다.
- 실제 `NGramPredictiveTextEngine`은 현재 main queue에서 `onLoadCompleted`를 호출하지만, `PredictiveTextPreparing` 프로토콜 자체가 호출 thread를 보장하지 않으므로 `SuggestionController`에서 main queue hop을 방어적으로 추가했다.
- `textDocumentProxy.adjustTextPosition(byCharacterOffset:)`는 keyboard extension과 host 앱 사이 호출이므로 여러 step을 loop로 나누면 호출 비용과 중간 상태 노출이 커진다.
- cursor 이동 적용 step은 요청 step과 `documentContextBeforeInput`/`documentContextAfterInput`의 실제 길이 중 작은 값으로 제한한다.
- 적용 가능한 step 계산은 `suffix(requestedSteps)` 또는 `prefix(requestedSteps)`만 확인하므로 탐색량은 현재 최대 step 수준으로 작다.

## Inferences

- 가속도 기반 이동량은 UIKit gesture controller 내부에 직접 박기보다 순수 policy로 분리해야 테스트하기 쉽다.
- 이슈의 "공통 키보드 로직" 요구는 한글/영문 모두가 사용하는 `Modules/SYKeyboardCore` 쪽 변경을 의미한다.
- 삭제 버튼 drag까지 같은 step을 적용하면 이슈의 공통 로직 요구에는 부합하지만, 삭제/복구 체감 위험이 커서 구현 전 사용자 확인 또는 보수적 제한이 필요하다.
- 새 사용자 설정을 만들지 않아도 이슈 요구사항은 충족 가능하다. 기존 `cursorMoveInterval`을 기본 민감도 설정으로 재사용할 수 있다.

## Decisions

- 작업 문서 이름은 `cursor-drag-acceleration`으로 둔다.
- 구현 계획은 새 설정값 추가 없이 내부 정책 상수로 시작한다.
- `cursorMoveInterval` 기본값 `5.0`과 의미를 유지한다. 느린 드래그의 1칸 이동 기준이며, 가속 step 계산의 기준 tick으로 사용한다.
- `BaseKeyboardViewController`는 요청 step을 실제 적용 가능한 step으로 제한한 뒤, `adjustTextPosition(byCharacterOffset:)`를 gesture update당 한 번만 호출한다.
- 빠른 드래그 보정은 곱셈형보다 보수적인 덧셈형(`baseTicks + speedBoost + accelerationBoost`)으로 구현한다.
- 확정값은 `maximumStep = 4`, `fastVelocityThreshold = 900pt/s`, `veryFastVelocityThreshold = 1600pt/s`, `accelerationThreshold = 900pt/s 증가`다.
- haptic과 undo/redo control 갱신은 step마다 반복하지 않고 gesture update당 한 번만 수행한다.
- cursor 활성화 첫 이동은 가속 대상에서 제외한다. 활성화 전 누적 거리는 가속 계산의 `baseTicks`로 사용하지 않는다.
- 속도 계산은 UIKit gesture가 제공하는 `velocity(in:)`를 우선 사용한다. `CursorDragAccelerationPolicy.movement`는 `elapsedTime` 대신 x축 velocity를 입력으로 받는다.
- 가속 증가 보정은 `previousVelocity > 0`일 때만 허용한다.
- n-gram 로딩 완료 callback은 호출 thread와 무관하게 `SuggestionController`가 main queue에서 후보 갱신을 수행하도록 보장한다.

## Open Questions

- 실제 입력 앱에서 손 감각 기준으로 `fastVelocityThreshold`, `veryFastVelocityThreshold`, `maximumStep`을 추가 튜닝할 여지가 있다.
- 2026-06-05 수정 후 실기기 재확인은 아직 수행하지 않았다.
- PR #58 review 반영 후 실제 PR review comment에는 직접 답변하지 않았다.

## Verification Notes

- 실행한 명령:

```sh
gh issue view 49 --repo SNMac/SYKeyboard --json number,title,state,body,labels,createdAt,updatedAt,comments
```

- 결과: 권한 있는 네트워크 실행에서 이슈 본문과 댓글 없음 상태를 확인했다.
- 실행한 탐색 명령:

```sh
rg -n "cursor|커서|drag|Drag|pan|Pan|swipe|Swipe|gesture|Gesture|left|right" Modules Keyboards SYKeyboardTests
rg -n "Cursor|cursor|드래그|drag|pan|swipe|좌우" . --glob '!**/DerivedData/**' --glob '!**/.git/**'
sed -n '1,230p' Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift
sed -n '1290,1405p' Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
sed -n '1,120p' Modules/SYKeyboardCore/Storage/DefaultValues.swift
```

- 아직 실행하지 않은 검증:
  - 실제 시뮬레이터 수동 입력 확인
- 구현 중 sandboxed `xcodebuild test`는 CoreSimulator/SwiftPM cache 권한 문제로 실패했다.
- 권한 있는 환경에서 아래 검증을 실행했다.

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
git diff --check
```

- 결과:
  - `SYKeyboard` test: `** TEST SUCCEEDED **`
  - `HangeulKeyboard` build: `** BUILD SUCCEEDED **`
  - `EnglishKeyboard` build: `** BUILD SUCCEEDED **`
  - `git diff --check`: exit 0
- 2026-06-05 회귀 수정 RED/GREEN:
  - RED: `CursorDragAccelerationPolicy.initialMovement` 테스트 추가 후 `Type 'CursorDragAccelerationPolicy' has no member 'initialMovement'`로 실패 확인.
  - GREEN: `initialMovement`와 cursor 활성화 첫 이벤트 기준점 재설정 구현 후 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` 성공.
- 2026-06-05 velocity 기반 전환 RED/GREEN:
  - RED: 테스트를 `velocity:` 인자로 변경 후 `Incorrect argument label in call`로 실패 확인.
  - GREEN: `UIPanGestureRecognizer.velocity(in:)` 사용, `QuartzCore`/`previousPanUpdateTime` 제거 후 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` 성공.
  - 추가 검증: `HangeulKeyboard`/`EnglishKeyboard` scheme build 성공.
- 2026-06-05 threshold 조정 RED/GREEN:
  - RED: `650pt/s`, `1200pt/s`, 첫 velocity 샘플 보정 테스트 추가 후 해당 3개 테스트 실패 확인.
  - GREEN: `900/1600/900` threshold와 `previousVelocity > 0` guard 적용 후 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` 성공.
  - 추가 검증: `HangeulKeyboard`/`EnglishKeyboard` scheme build 성공.
- 2026-06-06 PR #58 review 반영 RED/GREEN:
  - RED: background n-gram callback main-thread 갱신 테스트와 cursor 적용 step 제한 테스트 추가 후 `CursorDragAccelerationPolicy.applicableSteps` 미구현 compile error를 확인했다.
  - GREEN: `SuggestionController` main queue hop, `CursorDragAccelerationPolicy.applicableSteps`, 단일 `adjustTextPosition(byCharacterOffset:)` 호출 구현 후 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` 성공.
  - 추가 검증: `HangeulKeyboard` scheme build 성공. `EnglishKeyboard` scheme build는 병렬 실행 중 `build.db` lock으로 1회 실패했고, 같은 명령을 순차 재실행해 성공했다.
  - `git diff --check`: exit 0

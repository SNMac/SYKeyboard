# Cursor Drag Acceleration Plan

Last Updated: 2026-06-05

## Goal

- GitHub Issue #49: 키보드 좌우 드래그 커서 이동에 속도/가속도 기반 step 보정을 적용해, 느린 드래그는 기존처럼 세밀하고 빠른 드래그는 여러 칸씩 자연스럽게 이동하도록 만든다.

## Current State

- 확인한 이슈: `https://github.com/SNMac/SYKeyboard/issues/49`
- 현재 구현은 `TextInteractionGestureController`가 `UserDefaultsManager.shared.cursorMoveInterval` 이상의 x축 이동을 감지하면 delegate를 한 번 호출한다.
- `BaseKeyboardViewController.primaryButtonPanning(_:to:)`는 delegate 호출 1회마다 입력 버퍼를 초기화하고 커서를 한 칸 이동한다.
- `deleteButtonPanning(_:to:)`도 같은 pan gesture 경로를 사용하지만, 삭제 버튼은 커서 이동이 아니라 왼쪽 삭제/오른쪽 복구를 수행한다.
- 구현 결과:
  - `CursorDragAccelerationPolicy`가 `cursorMoveInterval` 기반 `baseTicks`에 속도/가속도 boost를 더해 step을 계산한다.
  - primary cursor 이동 delegate는 `steps`를 받는다.
  - 삭제 버튼 drag는 기존 삭제/복구 동작을 유지하고 step 가속을 적용하지 않는다.
  - cursor 이동 반복 중 입력 버퍼 초기화는 gesture update당 한 번만 수행한다.
  - cursor 활성화 첫 이벤트는 활성화 전 누적 거리를 가속 step으로 사용하지 않고 최대 1칸만 이동한다.
  - 속도 계산은 UIKit의 `UIPanGestureRecognizer.velocity(in:)`를 사용한다.
- 관련 파일:
  - `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`
  - `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/Enums/PanDirection.swift`
  - `Modules/SYKeyboardCore/Storage/DefaultValues.swift`
  - `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
  - `SYKeyboard/Presentation/KeyboardSettings/CursorMovementSettingsView.swift`
  - `SYKeyboardTests/Utils/KeyboardGesturePolicyTests.swift`
  - `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`
  - `SYKeyboardTests/Utils/KeyboardUndoRedoManagerTests.swift`

## Approach

1. 현재 gesture 이벤트 흐름을 고정한다.
   - `.began`에서 기준점과 시간 정보를 초기화한다.
   - `.changed`에서 활성화 거리 통과 후 x축 이동량을 처리한다.
   - `.ended/.cancelled/.failed`에서 cursor active 상태, 기준점, 시간 정보를 초기화한다.
2. 순수 계산 정책을 분리한다.
   - 이름: `CursorDragAccelerationPolicy`.
   - 입력값 후보: `deltaX`, `velocity`, `previousVelocity`, `cursorMoveInterval`.
   - 출력값 후보: `direction`, `step`, `remainingReferenceOffset`.
   - UIKit gesture 객체 없이 테스트 가능한 구조로 만든다.
3. delegate 계약을 step-aware로 확장한다.
   - `primaryButtonPanning(_:to:steps:)`로 primary cursor 이동만 step-aware 처리한다.
   - 커서 이동은 `steps`만큼 반복 이동한다.
   - 삭제 버튼 드래그는 텍스트 삭제/복구 회귀 위험이 커서 기존 1회 처리 동작을 유지한다.
4. 커서 이동 적용부를 반복 가능한 helper로 정리한다.
   - `moveCursorLeftIfPossible()`와 `moveCursorRightIfPossible()`는 한 칸 이동의 단일 책임을 유지한다.
   - `moveCursor(_:steps:)` 같은 private helper에서 최대 `steps`회 반복하고, 문맥이 없으면 중단한다.
   - 입력 버퍼 초기화는 한 번만 수행한다.
   - undo/redo control 갱신과 haptic은 과도한 호출을 피하기 위해 step 반복 후 1회 호출한다.
5. `cursorMoveInterval`을 느린 드래그의 기준 간격으로 유지한다.
   - 사용자가 천천히 드래그할 때는 기존처럼 `cursorMoveInterval` 거리마다 커서가 1칸 이동한다.
   - 빠른 드래그나 가속 구간에서는 `cursorMoveInterval`로 계산한 기본 tick 수에 배수 또는 상수 보정을 적용한다.
   - 새 로직은 `cursorMoveInterval`을 대체하지 않고, 이 값을 기준으로 step을 확장한다.
6. 보수적 초깃값으로 시작한다.
   - 느린 드래그: `step = 1`
   - 빠른 드래그: `step = 2...4`
   - 최대 이동 step 후보: `4`
   - 가속도 보정 후보: 이전 velocity 대비 증가율이 임계값을 넘으면 step을 1단계 올린다.
   - 구현 값은 `maximumStep = 4`, `fastVelocityThreshold = 900pt/s`, `veryFastVelocityThreshold = 1600pt/s`, `accelerationThreshold = 900pt/s 증가`다.
   - 첫 velocity 샘플(`previousVelocity == 0`)에는 가속 증가 보정을 적용하지 않는다.
7. 설정 화면 변경 여부를 결정한다.
   - 기본 계획은 새 사용자 설정을 추가하지 않는다.
   - 기존 `cursorMoveInterval`을 세밀함의 기준으로 유지하고, 가속도 관련 상수는 내부 정책 상수로 둔다.
   - 사용자가 직접 조절 가능한 "최대 step" 설정이 필요하다는 요구가 생기면 별도 범위로 분리한다.

## Proposed Step Model

- `cursorMoveInterval`의 의미:
  - 느린 드래그에서 커서가 1칸 이동하는 기준 거리다.
  - 예: `cursorMoveInterval = 5.0`이면 천천히 움직일 때 x축 이동이 5pt 누적될 때마다 1칸 이동한다.
  - 가속 로직은 이 값을 없애거나 무시하지 않고, 이 값을 기준으로 기본 tick을 계산한다.
- 거리 기반 기본 tick:
  - `baseTicks = floor(abs(deltaX) / cursorMoveInterval)`
  - 느린 드래그의 일반적인 update에서는 `baseTicks = 1`이다.
  - 빠른 드래그로 한 번의 update에 큰 `deltaX`가 들어오면 `baseTicks` 자체가 2 이상이 될 수 있다.
- 속도 기반 보정:
  - `velocity = abs(gesture.velocity(in: gesture.view).x)`
  - 느린 드래그 threshold 이하는 `speedBoost = 0`
  - 빠른 드래그 threshold 이상은 `speedBoost = 1...2`를 적용한다.
- 가속도 기반 보정:
  - `acceleration = velocity - previousVelocity`
  - 양의 가속도가 threshold 이상일 때만 추가 배수 또는 상수 보정을 허용한다.
  - 감속 구간에서는 보정을 제거해 `baseTicks` 중심으로 돌아오게 한다.
- 최종 step:
  - `step = min(maxStep, max(1, baseTicks + speedBoost + accelerationBoost))`
  - `speedBoost = 1` if `velocity >= 900pt/s`
  - `speedBoost = 2` if `velocity >= 1600pt/s`
  - `accelerationBoost = 1` if `previousVelocity > 0 && velocity - previousVelocity >= 900pt/s`
  - `cursorMoveInterval`로 만든 `baseTicks`를 출발점으로 삼는다.
- 기준점 처리:
  - cursor 활성화 첫 이벤트는 `initialMovement`로 최대 1칸만 처리하고 `intervalReferPanPoint`를 현재 위치로 갱신한다.
  - 활성화 이후에는 step 발생 후 `intervalReferPanPoint`를 현재 위치로 갱신하면 구현이 단순하고 튐이 적다.
  - `deltaX` 안에 여러 interval이 포함된 경우에는 `baseTicks`와 보정 step으로 반영한다.

## Product Notes

- 빠른 드래그 보정은 덧셈형으로 시작했다. 곱셈형은 큰 `baseTicks`에서 튐이 커질 수 있어 후속 튜닝 후보로 남긴다.
- 최대 step은 `4`로 시작했다.
- `cursorMoveInterval`은 사용자 설정 범위 `1.0...9.0`, `0.5` 단위, 기본값 `5.0`이다.
- `cursorActiveDistance`는 사용자 설정 범위 `10.0...50.0`, `1.0` 단위, 기본값 `30.0`이다.
- 속도 threshold는 기본 `cursorMoveInterval = 5.0` 기준에서 느린 드래그 체감을 보존하기 위해 `650/1200/600`보다 보수적인 `900/1600/900`으로 확정했다.
- 삭제 버튼 드래그는 이번 이슈에서 가속 대상에 포함하지 않았다.
- 속도/가속도 threshold는 실제 기기에서 손 감각으로 튜닝할 수 있다.

## Risks

- 한글 조합 중 커서 이동은 입력 버퍼를 초기화한다. step 적용으로 초기화 타이밍이 반복되면 조합 상태 회귀가 생길 수 있으므로 한 번만 초기화하는 방향이 안전하다.
- `textDocumentProxy.documentContextBeforeInput/AfterInput`는 호스트 앱 상태에 따라 nil일 수 있다. 여러 칸 이동 중 문맥이 끊기면 즉시 중단해야 한다.
- 삭제 버튼 pan 삭제/복구는 `tempDeletedCharacters`, `deleteButtonPanDeleteText`, `deleteButtonPanRestoreText`와 연결되어 있어 step 적용 시 복구 순서 회귀 위험이 높다.
- haptic/sound를 step마다 발생시키면 빠른 드래그에서 피드백이 과도해질 수 있다.
- 활성화 전 누적 거리를 첫 가속 계산에 포함하면 첫 이동이 `maximumStep`까지 튈 수 있다. 활성화 첫 이벤트와 활성화 이후 이동 이벤트를 분리해야 한다.
- `UIPanGestureRecognizer.velocity(in:)`를 쓰되 gesture 객체는 policy로 넘기지 않는다. gesture layer에서 x축 velocity만 추출해 순수 policy에 전달한다.

## Verification

- 단위 테스트:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 키보드 extension 빌드:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

- 수동 확인:
  - 한글 키보드에서 조합 중 좌/우 드래그 시 조합 상태가 기존 정책대로 초기화되는지 확인한다.
  - 영문 키보드에서 느린 드래그가 1칸 단위로 움직이는지 확인한다.
  - 빠르게 가속하며 드래그할 때 여러 칸 이동하되 최대 step 이상 튀지 않는지 확인한다.
  - 텍스트 시작/끝 경계에서 더 이상 이동하지 않고 오류 없이 멈추는지 확인한다.
  - 삭제 버튼 좌/우 드래그 삭제/복구가 기존 테스트 시나리오와 일치하는지 확인한다.

## Verification Result

- sandboxed `xcodebuild test`는 CoreSimulator/SwiftPM cache 권한 문제로 실패했다.
- 권한 있는 환경에서 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`를 실행했고 `** TEST SUCCEEDED **`를 확인했다.
- 권한 있는 환경에서 `HangeulKeyboard` scheme build를 실행했고 `** BUILD SUCCEEDED **`를 확인했다.
- 권한 있는 환경에서 `EnglishKeyboard` scheme build를 실행했고 `** BUILD SUCCEEDED **`를 확인했다.
- `git diff --check`는 exit 0이다.
- 실제 입력 앱 수동 확인은 아직 수행하지 않았다.
- 2026-06-05 실기기 피드백 후 회귀 테스트를 추가했다.
  - RED: `CursorDragAccelerationPolicy.initialMovement` 부재로 컴파일 실패 확인.
  - GREEN: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`에서 `** TEST SUCCEEDED **` 확인.
- 2026-06-05 velocity 기반 전환:
  - RED: `velocity:` 인자를 기대하는 테스트로 변경 후 기존 `elapsedTime:` API와 불일치하는 실패 확인.
  - GREEN: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`에서 `** TEST SUCCEEDED **` 확인.
  - `HangeulKeyboard`/`EnglishKeyboard` scheme build에서 각각 `** BUILD SUCCEEDED **` 확인.
- 2026-06-05 threshold 조정:
  - RED: `650pt/s`, `1200pt/s`, 첫 velocity 샘플 보정 테스트 추가 후 해당 3개 테스트 실패 확인.
  - GREEN: `fastVelocityThreshold = 900pt/s`, `veryFastVelocityThreshold = 1600pt/s`, `accelerationThreshold = 900pt/s`, `previousVelocity > 0` guard 적용 후 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'`에서 `** TEST SUCCEEDED **` 확인.
  - `HangeulKeyboard`/`EnglishKeyboard` scheme build에서 각각 `** BUILD SUCCEEDED **` 확인.

## Done Criteria

- 커서 드래그 이동량 계산이 거리/속도/가속도 정보를 사용한다.
- 느린 드래그는 기존처럼 1칸 단위 이동이 가능하다.
- 빠른 드래그 또는 가속 구간은 최소/최대 step 제한 안에서 여러 칸 이동한다.
- 한글/영문 키보드가 공통 로직을 사용한다.
- 한글 조합 상태, 삭제/복구, undo/redo 커서 anchor 관련 회귀 테스트가 통과한다.
- 실제 실행한 검증 명령과 결과가 작업 문서 또는 최종 응답에 기록된다.

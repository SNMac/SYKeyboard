# Issue 84 Cursor Drag Selection Plan

Last Updated: 2026-06-20

## Goal

- GitHub Issue #84: 키보드 커서 드래그 중 두 번째 터치가 감지되면 텍스트 선택 모드로 전환하고, 손가락을 떼면 이동 범위에 맞는 선택 상태를 남긴다.

## Current State

- 확인한 이슈: `https://github.com/SNMac/SYKeyboard/issues/84`
- 이슈는 1.7.0 새 기능으로 등록된 open enhancement다.
- 현재 primary 버튼 pan 흐름은 `TextInteractionGestureController`가 cursor active 상태와 이동 step을 계산하고, `BaseKeyboardViewController.primaryButtonPanning(_:to:steps:)`가 `adjustTextPosition(byCharacterOffset:)`로 커서를 이동한다.
- 현재 `TextInteractionGestureController`는 단일 pan gesture의 위치/속도/활성화 상태만 추적하며, 두 번째 터치 감지나 selection mode 상태를 갖고 있지 않다.
- 현재 `BaseKeyboardViewController.textWillChange(_:)`와 `textDidChange(_:)`는 입력 버퍼, 키보드 타입, return 상태, 자동완성 갱신을 동기화한다.
- 현재 `selectionWillChange(_:)`와 `selectionDidChange(_:)`는 로그만 남긴다. 프로젝트 지침상 현재 확인된 환경에서 이 selection 콜백 호출은 관찰되지 않았으므로 selection mode 동기화를 이 경로에만 의존하지 않는다.
- 현재 구현된 기반:
  - `CursorDragSelectionPolicy`로 기본 preserve-expanded-range 정책과 내부 anchor 정책을 분리했다.
  - `CursorDragSelectionPolicy.markedTextCommand`로 `setMarkedText(_:selectedRange:)` 호출 후보를 순수 함수로 계산한다.
  - `TextInteractionGestureController`는 primary cursor drag 중 두 번째 터치를 감지하면 selection panning delegate로 분기한다.
  - `BaseKeyboardViewController`의 selection panning 구현은 실제 marked text 적용 전 안전한 placeholder로 남겨 두었다.
- 관련 파일:
  - `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`
  - `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/Policies/CursorDragAccelerationPolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/Policies/CursorDragSelectionPolicy.swift`
  - `Modules/SYKeyboardCore/Presentation/Utils/Enums/PanDirection.swift`
  - `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
  - `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift`
  - `Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift`
  - `Modules/HangeulKeyboardCore/Domain/Processor/Protocols/HangeulProcessable.swift`
  - `SYKeyboardTests/Utils/TextInteractionGestureControllerTests.swift`
  - `SYKeyboardTests/Utils/CursorDragAccelerationPolicyTests.swift`
  - `SYKeyboardTests/Utils/CursorDragSelectionPolicyTests.swift`
  - `SYKeyboardTests/Controller/DubeolsikControllerTests.swift`
  - `SYKeyboardTests/Controller/NaratgeulControllerTests.swift`
  - `SYKeyboardTests/Controller/CheonjiinControllerTests.swift`

## Approach

1. `setMarkedText(_:selectedRange:)` 기반 spike를 먼저 진행한다.
   - custom keyboard extension에서 marked text로 실제 선택 표시를 만들 수 있는지 확인한다.
   - `unmarkText()` 이후 선택 범위가 남는지, 커밋되는지, 선택이 해제되는지 실제 입력 앱에서 확인한다.
   - `selectedText`, `documentContextBeforeInput`, `documentContextAfterInput` 반영 타이밍을 함께 기록한다.
   - spike 결과가 불가능하거나 앱별 편차가 크면 본 구현 전에 대체 전략을 재검토한다.
2. 선택 상태 모델과 정책을 순수 타입으로 분리한다.
   - 기본 정책은 iPhone 기본 키보드처럼 한 번 선택된 범위가 다시 줄어들지 않는 방식으로 둔다.
   - 내부 플래그 정책은 anchor 기반으로 분리한다. 선택 시작점과 현재 커서 위치 사이를 선택 범위로 계산하고, 시작점을 넘어가면 반대 방향 선택으로 전환한다.
   - 초기 릴리스에서는 사용자 설정으로 노출하지 않고 내부 정책으로만 유지한다.
3. `TextInteractionGestureController`의 책임 안에서 두 번째 터치 감지 흐름을 설계한다.
   - 기존 cursor active 판정, 첫 이동 보정, step 계산 흐름을 보존한다.
   - pan 중 추가 터치 감지 시 selection mode로 전환하는 상태 전이를 추가한다.
   - 종료/취소/실패 시 cursor active와 selection mode 상태를 함께 정리한다.
4. `BaseKeyboardViewController`에서 selection mode 적용 경계를 정리한다.
   - selection mode 진입 전 `resetInputBuffer()`와 한글 조합 확정/정리 흐름을 명확히 한다.
   - selection mode 중 `textWillChange(_:)`/`textDidChange(_:)`가 들어와도 내부 selection 상태와 자동완성 갱신이 충돌하지 않게 한다.
   - 선택 종료 후 return 상태, undo/redo control, 자동완성 후보 갱신 기준을 확인한다.
5. 한글 조합 회귀를 별도로 검증한다.
   - 나랏글/천지인/두벌식 조합 중 selection mode 진입 시 `inputBuffer`, composing, committed tail이 섞이지 않는지 테스트한다.
   - UI에서 한글 조합 규칙을 새로 만들지 않고 기존 Processor/Controller 경계를 유지한다.
6. 구현 후 실제 입력 앱에서 수동 검증한다.
   - 기본 정책과 내부 anchor 정책 모두 실험 가능해야 한다.
   - 손가락 해제 후 선택 상태가 남는지 반드시 확인한다.

## Progress Notes

- 완료:
  - 기본 정책과 anchor 정책의 range 계산 테스트를 추가했다.
  - marked text 후보 생성 테스트를 추가했다.
  - pan 중 두 번째 터치가 selection callback으로 분기되는 테스트를 추가했다.
  - 정책 타입과 gesture delegate 분기를 구현했다.
  - 전체 테스트와 양쪽 키보드 extension 빌드를 통과시켰다.
- 보류:
  - 실제 `setMarkedText(_:selectedRange:)` 호출 연결은 실제 입력 앱 spike 전까지 보류한다.
  - 손가락 해제 후 선택 상태를 남기는 최종 동작은 아직 구현 완료로 보지 않는다.

## Spike Checklist

- `setMarkedText(_:selectedRange:)`가 custom keyboard extension에서 호출 가능한지 확인한다.
- marked text가 호스트 앱 텍스트 필드에 선택처럼 표시되는지 확인한다.
- `unmarkText()` 직후 선택 범위가 유지되는지 확인한다.
- marked text가 일반 입력으로 커밋되어 버리는지 확인한다.
- `selectedText`가 기대 범위를 반환하는지 확인한다.
- `documentContextBeforeInput`/`documentContextAfterInput`이 selection mode 중 언제 갱신되는지 확인한다.
- 메시지 앱 또는 메모 앱 같은 실제 입력 앱에서 최소 한 번 확인한다.

## Risks

- `UITextDocumentProxy.setMarkedText(_:selectedRange:)`가 custom keyboard extension에서 기대한 선택 상태를 만들지 못할 수 있다.
- 호스트 앱별로 marked text, selection 표시, `selectedText` 반영 타이밍이 다를 수 있다.
- selection mode 구현을 `selectionWillChange(_:)`/`selectionDidChange(_:)`에 의존하면 현재 프로젝트에서 관찰된 호출 조건과 맞지 않을 수 있다.
- 두 번째 터치 감지는 기존 버튼 touch 흐름, long press, delete pan, keyboard stack user interaction disable 타이밍과 충돌할 수 있다.
- 한글 조합 중 selection mode에 들어가면 composing 상태와 실제 host text 상태가 어긋날 수 있다.
- 한 번 선택된 범위를 줄이지 않는 기본 정책은 anchor 기반 내부 정책과 결과가 다르므로 테스트가 정책별로 분리되어야 한다.
- selection mode 중 자동완성, undo/redo, return enabled 갱신이 기존 cursor drag skip 정책과 충돌할 수 있다.

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
  - 한글 키보드에서 조합 전/조합 중 커서 드래그 중 두 번째 터치로 selection mode에 진입한다.
  - 영문 키보드에서 왼쪽/오른쪽 selection mode 진입과 방향 전환을 확인한다.
  - 기본 정책에서 한 번 늘어난 선택 범위가 되돌아오는 드래그로 줄어들지 않는지 확인한다.
  - 내부 anchor 정책에서 선택 시작점을 기준으로 범위가 줄고, 시작점을 넘어가면 반대 방향 선택으로 전환되는지 확인한다.
  - 손가락을 뗀 뒤 선택 상태가 남는지 확인한다.
  - focus 변경, 텍스트 필드 탭, 커서 이동 시 `textWillChange(_:)`/`textDidChange(_:)`와 내부 selection mode 상태가 충돌하지 않는지 확인한다.

## Done Criteria

- `setMarkedText(_:selectedRange:)` spike 결과가 문서화되어 본 구현 가능 여부가 판단된다.
- 커서 드래그 중 두 번째 터치로 selection mode에 진입한다.
- 기본 iPhone 방식과 내부 anchor 방식이 정책으로 분리되어 테스트 가능하다.
- selection mode 종료 후 이동 범위에 맞는 선택 상태가 남는다.
- 한글 조합 중 selection mode 진입 시 `inputBuffer`와 composing 상태가 안전하게 정리된다.
- 나랏글/천지인/두벌식 관련 테스트와 gesture/policy 테스트가 통과한다.
- `HangeulKeyboard`와 `EnglishKeyboard` scheme 빌드가 통과한다.
- 실제 입력 앱 수동 확인 결과가 작업 문서나 최종 응답에 기록된다.

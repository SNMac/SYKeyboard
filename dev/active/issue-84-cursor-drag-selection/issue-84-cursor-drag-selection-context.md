# Issue 84 Cursor Drag Selection Context

Last Updated: 2026-06-22

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift`: primary/delete 버튼 pan gesture의 활성화, cursor step 계산, delegate 호출을 담당한다. 두 번째 터치 감지와 selection mode 상태 전이를 추가할 가능성이 높다.
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: `TextInteractionGestureControllerDelegate` 구현체이며, cursor 이동, `textWillChange(_:)`, `textDidChange(_:)`, `selectionWillChange(_:)`, `selectionDidChange(_:)`, input buffer, 자동완성, undo/redo 갱신을 조율한다.
- `Modules/SYKeyboardCore/Presentation/Utils/ButtonStateController.swift`: 현재 눌린 버튼과 suggestion bar interaction 상태를 관리한다. cursor drag 중 다른 키 입력을 막는 gate를 둘 수 있는 후보 지점이다.
- `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/Bases/BaseKeyboardButton.swift`: `sendActions(for:)`를 override하고 있어 드래그 중 입력 action 차단을 공통 처리할 수 있는 후보 지점이다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/CursorDragAccelerationPolicy.swift`: 현재 cursor drag step 계산 정책이다. selection range 계산 정책은 이 파일에 섞기보다 별도 policy로 두는 편이 테스트와 책임 분리에 맞다.
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/CursorDragSelectionPolicy.swift`: selection range 계산과 marked text 후보 생성을 담당하는 순수 정책 타입이다.
- `Modules/SYKeyboardCore/Presentation/Utils/Enums/PanDirection.swift`: selection 방향 계산에 재사용될 수 있는 pan 방향 enum이다.
- `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`: 한글 키보드 controller이며, `textWillChange(_:)` 경로에서 한글 조합 상태와 input buffer 동기화 영향을 확인해야 한다.
- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift`: 영문 키보드 controller이며, 공통 selection mode가 한글 전용 상태와 분리되는지 확인해야 한다.
- `Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift`: 한글 composing 상태 전이가 정의되어 있다. selection mode 진입 전 조합 정리 방식 검토에 필요하다.
- `Modules/HangeulKeyboardCore/Domain/Processor/Protocols/HangeulProcessable.swift`: Processor별 조합/삭제 계약을 확인할 때 필요하다.
- `SYKeyboardTests/Utils/TextInteractionGestureControllerTests.swift`: gesture controller 상태 전이 테스트 스타일 참고 파일이다.
- `SYKeyboardTests/Utils/CursorDragAccelerationPolicyTests.swift`: 순수 policy 테스트 스타일 참고 파일이다.
- `SYKeyboardTests/Utils/CursorDragSelectionPolicyTests.swift`: 기본 preserve-expanded-range 정책, anchor 정책, marked text 후보 생성 테스트 파일이다.
- `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`: `selectedText`, `inputBuffer`, cursor drag 중 자동완성 갱신 skip 정책 참고 파일이다.
- `SYKeyboardTests/Controller/DubeolsikControllerTests.swift`: 두벌식 controller 회귀 테스트다.
- `SYKeyboardTests/Controller/NaratgeulControllerTests.swift`: 나랏글 controller 회귀 테스트다.
- `SYKeyboardTests/Controller/CheonjiinControllerTests.swift`: 천지인 controller 회귀 테스트다.

## Facts Checked

- Issue #84는 2026-06-19 생성된 open enhancement 이슈다.
- 이슈 제목은 `[Feat] 커서 드래그 중 텍스트 선택 지원`이다.
- 이슈 본문은 1.7.0 새 기능으로, 커서 드래그 중 다른 손가락 터치가 감지되면 텍스트 선택 모드로 전환하고 손가락을 떼면 이동 범위에 맞는 선택을 남기도록 요구한다.
- 이슈는 구현 전 `UITextDocumentProxy.setMarkedText(_:selectedRange:)` 기반 spike를 먼저 진행하라고 명시한다.
- 이슈는 `unmarkText()` 이후 선택 범위가 남는지, 커밋되는지, 선택이 해제되는지 실제 입력 앱에서 확인하라고 명시한다.
- 이슈는 `selectedText`, `documentContextBeforeInput`, `documentContextAfterInput` 반영 타이밍 확인을 요구한다.
- 이슈는 기본 동작을 iPhone 기본 키보드처럼 한 번 선택된 범위가 다시 미선택으로 줄어들지 않는 방식으로 설계하라고 요구한다.
- 이슈는 사용자 제안 anchor 기반 방식을 내부 플래그 정책으로 분리하라고 요구한다.
- 이슈는 초기 릴리스에서 anchor 기반 방식을 사용자 설정으로 노출하지 말고 테스트/실험 가능한 내부 정책으로 유지하라고 요구한다.
- 이슈는 cursor/selection 상태 동기화를 `textWillChange(_:)`와 `textDidChange(_:)` 경로 기준으로 확인하라고 명시한다.
- 프로젝트 지침은 현재 확인된 환경에서 `selectionWillChange(_:)`와 `selectionDidChange(_:)` 호출을 관찰하지 못했으므로 해당 콜백에만 의존하지 말라고 한다.
- 현재 `TextInteractionGestureController`는 `isCursorActive`, `initialPanPoint`, `intervalReferPanPoint`, `previousPanVelocity`를 저장한다.
- 현재 primary cursor pan은 `CursorDragAccelerationPolicy.initialMovement`와 `CursorDragAccelerationPolicy.movement`를 통해 방향과 step을 계산한다.
- 현재 delete button pan은 step 가속을 적용하지 않고 방향별 delete/restore를 수행한다.
- 현재 `BaseKeyboardViewController.primaryButtonPanning(_:to:steps:)`는 `isPrimaryCursorDragging = true`, `resetInputBuffer()`, `moveCursorIfPossible(to:steps:)`를 수행한다.
- 현재 `BaseKeyboardViewController.primaryButtonPanStopped(_:)`는 `isPrimaryCursorDragging = false`, return button 갱신, cursor context 기반 자동완성 갱신을 수행한다.
- 현재 `BaseKeyboardViewController.textWillChange(_:)`는 undo/redo 준비, `resetInputBuffer()`, 키보드/return/suggestion bar 상태 갱신을 수행한다.
- 현재 `BaseKeyboardViewController.textDidChange(_:)`는 undo/redo invalidation, 키보드/return/suggestion bar 상태 갱신, cursor drag 중이 아닐 때 자동완성 갱신을 수행한다.
- 현재 `BaseKeyboardViewController.selectionWillChange(_:)`와 `selectionDidChange(_:)`는 super 호출과 로그만 수행한다.
- `git status --short`는 문서 생성 전 비어 있었다.
- `CursorDragSelectionPolicy`는 기본 정책에서 기존 min/max cursor offset을 보존해 한 번 확장된 선택 범위가 줄어들지 않도록 계산한다.
- `CursorDragSelectionPolicy`는 anchor 정책에서 시작점 0과 현재 cursor offset 사이를 선택 범위로 계산하므로 anchor로 돌아오면 줄어들고 anchor를 넘으면 반대 방향으로 전환된다.
- `CursorDragSelectionPolicy.markedTextCommand`는 현재 cursor 앞/뒤 context를 조합해 `setMarkedText(_:selectedRange:)`에 넘길 후보 문자열과 selected range를 만든다.
- `TextInteractionGestureController`는 primary cursor drag 중 `gesture.numberOfTouches >= 2`이면 기존 cursor 이동 delegate 대신 selection panning delegate를 호출한다.
- `BaseKeyboardViewController.primaryButtonSelectionPanning(_:to:steps:)`는 현재 실제 selection 적용 전 안전한 placeholder로 `resetInputBuffer()` 후 기존 cursor 이동만 수행한다.
- 2026-06-22 사용자가 실제 확인한 결과, 두 번째 손가락 터치가 먹히지 않는다.
- `TextInteractionGestureController.panGestureHandler(_:)`는 cursor drag 활성화 시 `keyboardHStackView?.isUserInteractionEnabled = false`를 수행한다.
- pan gesture는 keyboard 전체가 아니라 각 `TextInteractable` 버튼에 붙어 있다.
- `BaseKeyboardViewController.addGesturesToTextInterableButton(_:)`는 primary/delete 버튼에 `UIPanGestureRecognizer`를 추가하지만 touch 수 제한을 명시하지 않는다.
- `BaseKeyboardButton.sendActions(for:)`는 현재 `isEnabled`일 때만 super를 호출한다.
- primary cursor drag 활성화 중에는 이제 `keyboardHStackView.isUserInteractionEnabled`를 끄지 않는다.
- `ButtonStateController.isTextInteractionGestureActive`가 true이면 다른 버튼의 touchDown feedback/input 준비 action이 early return한다.
- `BaseKeyboardViewController.addGesturesToTextInterableButton(_:)`는 primary pan `maximumNumberOfTouches`를 2, delete pan `maximumNumberOfTouches`를 1로 설정한다.

## Inferences

- selection mode의 range 계산은 gesture layer가 아니라 순수 policy로 분리해야 기본 정책과 anchor 정책을 안정적으로 테스트할 수 있다.
- 이슈의 "커서 드래그 중 다른 손가락 터치"는 `UIPanGestureRecognizer`의 `numberOfTouches` 또는 gesture recognizer 설정을 검토해야 하는 요구로 해석된다.
- 두 번째 손가락 touch가 recognizer까지 오지 않는 직접 원인은 cursor drag 중 `keyboardHStackView.isUserInteractionEnabled = false`로 새 hit-test가 막히는 것일 가능성이 높다.
- `keyboardHStackView.isUserInteractionEnabled`를 켜 둔 채 입력 action만 gate로 차단하면 두 번째 touch 전달과 드래그 중 다른 키 입력 방지를 동시에 만족할 가능성이 높다.
- `setMarkedText(_:selectedRange:)` spike가 실패하면 실제 선택 상태를 남기는 구현 자체가 제약될 수 있으므로 본 구현에 들어가기 전 결론을 남겨야 한다.
- 한글 조합 중 selection mode 진입은 일반 cursor 이동보다 회귀 위험이 높으므로, 조합을 commit할지 reset할지 명확히 정해야 한다.
- 사용자 설정으로 노출하지 않는 내부 플래그는 `UserDefaultsManager` 설정값보다 code-level policy 선택이나 debug/test injection이 더 적합할 수 있다.

## Decisions

- 작업 문서 이름은 `issue-84-cursor-drag-selection`으로 둔다.
- 본 구현 전 선행 작업은 `setMarkedText(_:selectedRange:)` spike다.
- selection range 계산 정책은 기본 iPhone 방식과 anchor 기반 내부 정책을 분리한다.
- 초기 계획에서는 새 사용자 설정을 추가하지 않는다.
- selection 상태 동기화 검증은 `textWillChange(_:)`/`textDidChange(_:)` 경로를 기본으로 삼는다.
- `selectionWillChange(_:)`/`selectionDidChange(_:)`는 로그 확인 대상일 수 있지만 필수 동기화 경로로 설계하지 않는다.
- Superpowers 문서는 아직 만들지 않았다. 이번 요청은 `dev-docs` 계획 생성이며, 상세 설계/구현 계획을 별도 스킬로 확장할 때 `dev/active/issue-84-cursor-drag-selection/superpowers/` 아래에 둔다.
- 실제 host text에 `setMarkedText(_:selectedRange:)`를 적용하는 코드는 아직 연결하지 않는다. 이슈가 요구한 실제 입력 앱 spike 전에는 marked text가 커밋/중복/선택 해제되는 위험을 배제할 수 없기 때문이다.
- 이번 구현 범위는 selection 정책, marked text 후보 생성, 두 번째 터치 gesture 분기, 안전한 controller placeholder까지로 제한한다.
- 다음 수정에서는 cursor drag 중 `keyboardHStackView.isUserInteractionEnabled = false`에 의존하지 않는다.
- 다음 수정에서는 드래그 중 입력 action 차단을 명시적인 state/gate로 분리한다.
- long press, keyboard switch overlay, suggestion bar가 기존에 사용하는 interaction disable 흐름은 별도 기능이므로 이번 수정 범위에서 건드리지 않는다.
- 이번 수정에서는 gate 위치를 `ButtonStateController`로 결정했다. 드래그 중 새 touchDown이 이전 버튼의 `sendActions(.touchUpInside)`를 호출하는 경로를 가장 앞에서 차단하기 위해서다.

## Open Questions

- `setMarkedText(_:selectedRange:)`로 실제 입력 앱에서 손가락 해제 후 선택 범위를 남길 수 있는가?
- marked text를 사용하면 호스트 앱별로 선택 상태가 다르게 보이는가?
- `UIPanGestureRecognizer.numberOfTouches`가 custom keyboard extension의 pan 중 두 번째 손가락 터치 감지에 충분한가, 아니면 별도 gesture recognizer 설정이 필요한가?
- selection mode 진입 전 한글 composing은 즉시 commit해야 하는가, reset해야 하는가, 또는 기존 cursor 이동과 동일하게 input buffer만 reset하면 충분한가?
- 기본 iPhone 방식의 "선택된 범위가 줄어들지 않음"을 구현할 때 시작 방향별 최대 좌/우 범위를 어떤 상태값으로 저장할 것인가?
- 내부 anchor 정책을 런타임에서 어떻게 선택할 것인가? 테스트 전용 initializer injection인지, 내부 상수인지, debug flag인지 결정이 필요하다.
- selection mode 중 undo/redo 기록은 선택 상태만 남기는 경우 기록하지 않을지, marked text 커밋이 발생할 경우 어떤 change로 기록할지 확인이 필요하다.
- 입력 action gate의 위치는 `ButtonStateController`가 적합한가, `BaseKeyboardButton.sendActions(for:)`가 적합한가?
- primary pan은 `maximumNumberOfTouches = 2`로 명시하고 delete pan은 기존처럼 둘지 또는 1로 제한할지 결정이 필요하다.

## Verification Notes

- 실행한 명령:

```sh
git status --short
gh issue view 84 --repo SNMac/SYKeyboard --json number,title,state,author,createdAt,updatedAt,body,labels,comments
sed -n '1,220p' dev/README.md
sed -n '1,220p' dev/templates/task-plan-template.md
sed -n '1,220p' dev/templates/task-context-template.md
sed -n '1,220p' dev/templates/task-tasks-template.md
sed -n '13,90p' dev/codex-skill-playbook.md
sed -n '121,148p' dev/codex-skill-playbook.md
rg -n "TextInteractionGestureController|setMarkedText|selectedText|textWillChange|textDidChange|adjustTextPosition|inputBuffer|resetInputBuffer|primaryButtonPanning|HangeulProcess|Processor|marked" Modules Keyboards SYKeyboardTests
sed -n '1,260p' Modules/SYKeyboardCore/Presentation/Utils/GestureControllers/TextInteractionGestureController.swift
sed -n '250,330p' Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
sed -n '1360,1465p' Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
sed -n '1,240p' SYKeyboardTests/Utils/TextInteractionGestureControllerTests.swift
```

- 결과:
  - GitHub Issue #84 본문과 댓글 없음 상태를 확인했다.
  - `dev/README.md`, `dev/templates/`, `dev/codex-skill-playbook.md`의 관련 지침을 확인했다.
  - 현재 cursor pan 구현 위치와 `textWillChange(_:)`/`textDidChange(_:)` 동기화 위치를 확인했다.
  - 문서 생성 전 `git status --short`는 비어 있었다.

- 추가 실행한 명령:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/CursorDragSelectionPolicyTests
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/TextInteractionGestureControllerTests
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
git diff --stat
git status --short
```

- 추가 결과:
  - `CursorDragSelectionPolicyTests`는 정책 타입 추가 전 `cannot find 'CursorDragSelectionPolicy' in scope`로 실패했고, 정책 구현 후 통과했다.
  - `TextInteractionGestureControllerTests`는 두 번째 터치 selection callback 구현 전 실패했고, delegate 분기 구현 후 통과했다.
  - `markedTextCommand` 테스트는 구현 전 `type 'CursorDragSelectionPolicy' has no member 'markedTextCommand'`로 실패했고, 후보 생성 구현 후 통과했다.
  - 전체 `SYKeyboard` test suite는 `iPhone 13 mini / iOS 16.0`에서 통과했다.
  - 샌드박스 실행의 `HangeulKeyboard`, `EnglishKeyboard` build는 CoreSimulator, SwiftPM cache, clang ModuleCache 접근 제한으로 환경 실패했다.
  - 권한 있는 실행의 `HangeulKeyboard`, `EnglishKeyboard` build는 `iPhone 13 mini / iOS 16.0`에서 모두 통과했다.

- 아직 실행하지 않은 검증:
  - 실제 입력 앱에서 `setMarkedText(_:selectedRange:)` spike
  - `unmarkText()` 이후 선택 범위 유지/커밋/해제 확인
  - selection mode 중 `selectedText`, `documentContextBeforeInput`, `documentContextAfterInput` 반영 타이밍 확인
  - 실제 입력 앱 수동 확인

- 2026-06-22 추가 기록:
  - 현재 기반 작업은 `27ecf7e feat: #84 - 커서 드래그 선택 기반 추가`로 커밋했다.
  - 커밋 직후 `git status --short`는 비어 있었다.
  - 다음 작업은 두 번째 손가락 touch delivery를 막는 interaction disable 의존을 제거하고, 드래그 중 다른 키 입력은 별도 gate로 차단하는 것이다.
  - RED: `ButtonStateController`에 gate 속성이 없어 `ButtonStateControllerTests`가 컴파일 실패했다.
  - GREEN: `TextInteractionGestureControllerTests`와 `ButtonStateControllerTests` targeted run이 통과했다.
  - 전체 `SYKeyboard` test suite는 `iPhone 13 mini / iOS 16.0`에서 통과했다.
  - 권한 있는 실행의 `HangeulKeyboard`, `EnglishKeyboard` build는 `iPhone 13 mini / iOS 16.0`에서 모두 통과했다.

# Delete Drag Restore Regression Context

Last Updated: 2026-05-21

## Relevant Files

- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`: 삭제 버튼 팬 제스처에서 임시 삭제 버퍼를 관리한다.
- `Modules/SYKeyboardCore/Presentation/Suggestion/SuggestionController.swift`: 자동완성 UI의 현재 단어/추천 표시를 관리한다.
- `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`: 한글 입력기의 `committedBuffer`, `composingBuffer`, 프로세서 상태를 관리한다.
- `Modules/HangeulKeyboardCore/Domain/Processor/Protocols/HangeulProcessable.swift`: 입력/삭제 시 종성 복원 공통 로직이 있다.
- `Modules/HangeulKeyboardCore/Domain/Processor/DubeolsikProcessor.swift`: 두벌식 입력/삭제 조합 로직이다.
- `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`: 컨트롤러 버퍼 상태를 테스트에서 시뮬레이션한다.
- `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`: 두벌식, 천지인, 나랏글에 공통으로 적용되는 삭제 버튼 드래그 회귀 테스트 위치다.

## Facts Checked

- `deleteBackward()`는 한글 자소 단위 삭제가 의도된 경로다.
- 삭제 버튼 드래그는 사용자가 글자 단위 동작을 원한다.
- 현재 사용자가 직접 확인한 실제 증상은 자동 테스트 통과와 충돌한다.
- 이전 시도에서 입력 단위 버퍼 접근을 적용했으나 사용자가 원한 동작과 달랐다.
- 이후 글자 단위 접근으로 되돌렸지만 실제 키보드에서는 여전히 `고`가 누적된다.
- `DeleteButton`은 `.touchDown`에서 `performTextInteraction`을 실행하며, 이는 의도된 단일 삭제 동작이다.
- 삭제 버튼 pan 제스처가 활성화되기 전에 `.touchDown` 일반 삭제가 먼저 실행되면 `동해물과`의 `과`가 자소 단위 삭제되어 `동해물고`가 되고, 이후 pan 복구 버퍼에 `고`와 `과`가 함께 들어가 `동해물고과`가 된다.
- `HangeulDeleteButtonDragControllerTests`가 두벌식, 천지인, 나랏글의 touchDown/pan 복구 중복 방지 경로를 공통 회귀 테스트로 잡는다.
- 2026-05-21에 사용자가 실기기에서 테스트했고, 의도한 동작대로 수정되었음을 확인했다.
- 이후 사용자가 `동해물고` 상태에서 삭제 버튼 드래그로 완전 삭제/복구하면 `동해고`가 되는 추가 회귀를 보고했다.
- 두벌식 `동해물고` 자연 입력 상태에서는 마지막 `고`가 `composingBuffer`에 있고, 삭제 touchDown이 `committedBuffer`의 `물`을 소비해 `묽`으로 재조합할 수 있다.
- 이 상태에서 첫 pan 삭제를 단순히 복구 스킵하면 재조합된 `묽` 안의 원래 `물`까지 복구 버퍼에서 빠져 `동해고`가 된다.
- 이후 사용자가 `동해물과` 전체 드래그 삭제/복구 후 실제 입력값은 `동해물과`이지만 자동완성 UI 왼쪽 현재 단어가 `동해물고`로 남는 마이너 회귀를 보고했다.
- 일반 키 입력/삭제 경로는 `textInteractionDidPerform`에서 `updateSuggestions()`를 호출하지만, 삭제 버튼 pan 삭제/복구 경로는 `deleteButtonPanDeleteText`/`deleteButtonPanRestoreText`만 실행하고 자동완성 UI를 갱신하지 않았다.

## Decisions

- 삭제 드래그는 한글 조합 입력 단위가 아니라 화면 글자 단위여야 한다.
- 자동 테스트 통과만으로 완료 처리하지 말고, 키보드 extension의 실제 동작도 확인해야 한다.
- 이전 시도는 완성된 수정이 아니라 실패한 실험 상태로 간주한다.
- 삭제 버튼의 단일 삭제 액션은 의도된 `.touchDown` 동작으로 유지한다.
- `BaseKeyboardViewController`에는 pan 삭제/복구 hook을 두고, 한글 컨트롤러는 이를 override해 `committedBuffer`, `composingBuffer`, processor 상태를 함께 동기화한다.
- `.touchDown` 삭제로 이미 복구 버퍼에 원래 글자(`과`)가 들어간 상태에서 pan 삭제가 잔여 조합 글자(`고`)를 지우는 경우, 화면에서는 삭제하되 복구 버퍼에는 추가하지 않는다.
- touchDown 삭제가 확정 글자를 소비해 앞 글자를 재조합한 경우(`물` + `고` 삭제 -> `묽`), 첫 pan 삭제 때 재조합 결과 전체를 버리지 않고 원래 남아야 할 글자(`물`)를 복구 버퍼에 넣는다.
- 삭제 버튼 pan 삭제/복구가 성공하면 실제 텍스트와 `inputBuffer`가 바뀌므로, 자동완성 UI도 같은 제스처 안에서 즉시 갱신한다.

## Hypotheses

- 확인됨: 핵심 원인은 복구 후 `composingBuffer` 유지 자체가 아니라, pan 시작 전에 `.touchDown` 일반 삭제가 먼저 실행된 뒤 pan 복구 버퍼가 잔여 조합 글자까지 함께 담는 이벤트 순서였다.
- 추정: 실제 키보드 extension에서도 `.touchDown`은 유지하되, pan 삭제가 잔여 조합 글자를 복구 버퍼에 넣지 않으면 `고` 누적이 중단된다.
- 확인됨: `동해물고` 회귀는 pan 삭제 스킵을 복구 버퍼 전체 존재 여부로 판단하거나, 재조합된 `묽`을 그대로 스킵하면서 발생한다. touchDown 직전 `committedBuffer`/`composingBuffer`를 기록해야 원래 복구할 `물`을 찾을 수 있다.
- 확인됨: 자동완성 UI 왼쪽 현재 단어가 `동해물고`로 남는 문제는 삭제 touchDown 직후 갱신된 suggestion 상태가 pan 복구 이후 다시 갱신되지 않아 발생한다.

## Open Questions

- 없음.

## Verification Notes

- 2026-05-21에 `DubeolsikControllerTests`와 `SYKeyboardTests`는 iPhone 13 mini / iOS 16.0 시뮬레이터에서 통과했으나, 사용자가 실제 키보드에서 증상이 남아 있다고 보고했다.
- 따라서 기존 테스트는 충분한 검증 증거가 아니다.
- 2026-05-21에 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' -only-testing:SYKeyboardTests/DubeolsikControllerTests`를 RED로 실행해 `test삭제버튼드래그_touchDown선삭제후_복구중복방지` 실패를 확인했다.
- 2026-05-21에 `.touchDown` 단일 삭제를 유지하고 pan 복구 버퍼 중복만 막는 수정 후 같은 `DubeolsikControllerTests` 명령이 통과했다.
- 2026-05-21에 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' -only-testing:SYKeyboardTests/CheonjiinControllerTests -only-testing:SYKeyboardTests/NaratgeulControllerTests`가 통과했다.
- 2026-05-21에 삭제 버튼 공통 회귀 테스트를 `HangeulDeleteButtonDragControllerTests`로 분리했고, `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' -only-testing:SYKeyboardTests/HangeulDeleteButtonDragControllerTests`가 통과했다.
- 2026-05-21에 `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' -only-testing:SYKeyboardTests`가 통과했다.
- 2026-05-21에 `xcodebuild -quiet build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'`가 통과했다. Meta adapter debug module cache 관련 warning은 있었지만 빌드는 성공했다.
- 2026-05-21에 `xcodebuild -quiet build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'`가 통과했다.
- 2026-05-21에 사용자가 실기기에서 테스트했고, 의도한 동작대로 수정되었음을 확인했다.
- 2026-05-21에 `동해물고` 회귀를 잡기 위해 `HangeulDeleteButtonDragControllerTests`에 자연 입력 경로와 내부 상태 경계 테스트를 추가했다. 수정 전 `동해물고` 테스트는 `동해고`로 실패했고, 수정 후 `iPhone 13 mini / iOS 16.0`에서 통과했다.
- 2026-05-21에 같은 `iPhone 13 mini / iOS 16.0`에서 전체 `SYKeyboardTests`가 통과했다.
- 2026-05-21에 `동해물과` 전체 드래그 삭제/복구 후 자동완성 현재 단어가 `동해물과`로 동기화되는 테스트를 `HangeulDeleteButtonDragControllerTests`에 추가했고, 같은 `iPhone 13 mini / iOS 16.0`에서 `HangeulDeleteButtonDragControllerTests`가 통과했다.

## Current Uncommitted State

- 다음 파일들이 수정된 상태다.
  - `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`
  - `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`
- `dev/active/delete-drag-restore-regression/` 문서도 최신 상태로 갱신 중이다.

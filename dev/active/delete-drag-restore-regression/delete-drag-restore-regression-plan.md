# Delete Drag Restore Regression Plan

Last Updated: 2026-05-21

## Goal

- 삭제 버튼 드래그 삭제/복구가 화면 글자 단위로 동작하면서, 한글 조합 버퍼와 프로세서 상태가 실제 텍스트와 어긋나지 않게 수정한다.

## Current State

- 사용자 재현 증상:
  - `동해물과` 입력 후 삭제 버튼을 왼쪽으로 드래그해 모두 삭제하고, 오른쪽으로 드래그해 모두 복구하면 `동해물과`가 아니라 `동해물고과`가 된다.
  - 그 뒤 손을 떼었다가 다시 삭제 버튼에서 왼쪽/오른쪽 드래그를 반복하면 `동해물고과`, `동해물고고과`, `동해물고고고과`처럼 `고`가 누적된다.
- 확인한 root cause:
  - 삭제 버튼이 `.touchDown`에서 일반 삭제를 먼저 실행한다.
  - pan 제스처로 전환되면 이미 `과 -> 고` 자소 삭제가 일어난 뒤라, pan 삭제/복구 버퍼에 `고`와 `과`가 함께 들어간다.
  - 이 이벤트 순서 때문에 전체 복구 결과가 `동해물고과`가 된다.
  - 추가 회귀에서는 `동해물고`의 `고` 삭제가 확정 글자 `물`을 소비해 `묽`으로 재조합하고, 첫 pan 삭제가 이를 통째로 복구 스킵하면서 결과가 `동해고`가 된다.
- 현재 수정 방향:
  - 삭제 버튼 단일 삭제 액션은 의도된 `.touchDown` 동작으로 유지한다.
  - 삭제 pan 삭제/복구 hook은 유지하고, 한글 컨트롤러에서 글자 단위 삭제/복구와 버퍼 동기화를 담당한다.
  - `.touchDown` 삭제로 이미 복구 버퍼에 글자가 있으면, pan 삭제가 잔여 조합 글자를 지워도 복구 버퍼에는 추가하지 않는다.
  - touchDown 삭제가 앞 글자를 재조합한 경우에는 첫 pan 삭제 때 재조합 결과 대신 원래 남아야 할 글자만 복구 버퍼에 넣는다.
  - `KeyboardControllerSimulator`에 touchDown/pan 순서 회귀 테스트를 추가했다.
- 확인 결과:
  - 2026-05-21에 사용자가 실기기에서 테스트했고, 의도한 동작대로 수정되었음을 확인했다.

관련 파일:

- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
- `Modules/HangeulKeyboardCore/Domain/Processor/Protocols/HangeulProcessable.swift`
- `Modules/HangeulKeyboardCore/Domain/Processor/DubeolsikProcessor.swift`
- `SYKeyboardTests/Utils/KeyboardControllerSimulator.swift`
- `SYKeyboardTests/Controller/HangeulDeleteButtonDragControllerTests.swift`

## Approach

1. 먼저 현재 워킹트리 diff를 읽고, 이전 시도 중 유지할 것과 버릴 것을 구분한다. 완료.
2. 실제 제스처 상태를 기준으로 삭제 드래그의 책임을 다시 정의한다. 완료.
   - 왼쪽 드래그: 화면의 마지막 글자 1개를 임시 버퍼에 저장하고 삭제한다.
   - 오른쪽 드래그: 임시 버퍼에서 글자 1개를 꺼내 화면에 복구한다.
   - 손을 떼면 임시 버퍼만 초기화되어야 하며, 조합 상태가 유령처럼 남아 다음 드래그에 영향을 주면 안 된다.
3. `composingBuffer`, `committedBuffer`, `processor` 상태 전이를 실제 키보드 흐름에서 추적한다. 완료.
4. 테스트 시뮬레이터가 실제 `TextInteractionGestureControllerDelegate` 흐름을 재현하는지 확인한다. touchDown 선삭제 시나리오를 추가했다.
5. 자동 테스트가 놓친 부분은 상태 노출용 테스트 헬퍼나 더 실제에 가까운 시나리오로 보강한다. 완료.
6. 실제 키보드 extension에서 동일 드래그를 수동 확인한다. 사용자 실기기 테스트로 완료.

## Risks

- `deleteBackward()`의 자소 단위 삭제와 삭제 버튼 드래그의 글자 단위 삭제는 의도적으로 달라야 한다.
- 복구 후 마지막 한글을 `composingBuffer`에 넣으면 다음 입력 조합은 가능해지지만, 그 직후 다시 드래그 삭제하면 같은 글자가 중복 경로로 처리될 수 있다.
- `processor.start한글조합()`/`reset한글조합()`은 두벌식에서는 빈 구현이지만 천지인에서는 UI/조합 상태에 영향을 준다.
- 테스트 시뮬레이터가 실제 `textDocumentProxy`, `inputBuffer`, 팬 제스처 종료 시점과 다르게 동작할 수 있다.
- 삭제 버튼 단일 탭은 `.touchDown`에서 즉시 삭제된다. 따라서 pan 시작 전 잔여 조합 글자가 생길 수 있고, pan 삭제/복구 버퍼가 이를 중복 복구하지 않도록 유지해야 한다.
- 두벌식 삭제는 확정 글자를 다시 끌어와 재조합할 수 있으므로, touchDown 직전/직후의 `committedBuffer` 차이를 같이 확인해야 한다.

## Verification

실행한 검증 명령:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/DubeolsikControllerTests
```

결과: RED에서 `test삭제버튼드래그_touchDown선삭제후_복구중복방지` 실패 확인 후, `.touchDown` 단일 삭제를 유지하고 pan 복구 버퍼 중복만 막는 수정 뒤 통과.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/CheonjiinControllerTests \
  -only-testing:SYKeyboardTests/NaratgeulControllerTests
```

결과: 통과. 삭제 버튼 touchDown/pan 복구 중복 방지 시나리오를 천지인과 나랏글에도 추가했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/HangeulDeleteButtonDragControllerTests
```

결과: 통과. 두벌식, 천지인, 나랏글의 삭제 버튼 공통 회귀 테스트를 기능별 파일로 분리했다.

추가 확인:

- 수정 전 `동해물고` 회귀 테스트는 `동해고`로 실패했다.
- touchDown 직전 `committedBuffer`/`composingBuffer`를 기록해 첫 pan 삭제 복구 문자를 보정한 뒤, 같은 `HangeulDeleteButtonDragControllerTests` 명령이 iPhone 13 mini / iOS 16.0에서 통과했다.
- 같은 iPhone 13 mini / iOS 16.0에서 전체 `SYKeyboardTests`도 통과했다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests
```

결과: 통과.

```sh
xcodebuild -quiet build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

결과: 통과. Meta adapter debug module cache warning 있음.

```sh
xcodebuild -quiet build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

결과: 통과.

수동 확인:

- 실기기에서 실제 키보드 extension을 띄운다.
- 두벌식에서 `동해물과`를 입력한다.
- 삭제 버튼을 왼쪽으로 드래그해 모두 삭제한다.
- 손을 떼지 않고 오른쪽으로 드래그해 모두 복구한다.
- 결과가 정확히 `동해물과`인지 확인한다.
- 손을 떼었다가 다시 삭제 버튼에서 왼쪽/오른쪽 드래그를 반복해도 `고`가 누적되지 않는지 확인한다.
- 복구 직후 `ㅇ`을 입력했을 때 기대 동작을 확인한다. 현재 의도는 마지막 글자와 조합되어 `동해물광`이 되는 것이다.

결과: 2026-05-21에 사용자가 실기기에서 테스트했고, 의도한 동작대로 수정되었음을 확인했다.

## Done Criteria

- `동해물과 -> 전체 드래그 삭제 -> 전체 드래그 복구` 결과가 실제 키보드에서 `동해물과`이다. 사용자 실기기 테스트로 확인.
- 손을 뗀 뒤 동일 드래그를 반복해도 `동해물고과`, `동해물고고과`처럼 글자가 늘어나지 않는다. 자동 테스트와 사용자 실기기 테스트로 확인.
- `동해물고 -> 전체 드래그 삭제 -> 전체 드래그 복구` 결과가 `동해물고`이다. 자동 테스트로 확인.
- 자동 테스트가 실제 실패를 잡도록 보강되어 있다. `HangeulDeleteButtonDragControllerTests`에 두벌식, 천지인, 나랏글 공통 회귀 시나리오가 있다.
- `SYKeyboardTests`가 iPhone 13 mini / iOS 16.0 시뮬레이터에서 통과한다. 완료.
- 미완성 실험 코드나 실패한 접근이 남아 있지 않다. 현재 diff 기준으로 정리됨.

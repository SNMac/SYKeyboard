# 삭제 드래그 줄바꿈 경계 설계

## 배경

삭제 버튼을 길게 누르는 반복 삭제는 `documentContextBeforeInput`이 비어 있어도
`deleteBackward()`를 호출하고 `textDidChange(_:)`에서 실제 mutation을 확인한다. 반면 삭제 버튼을
왼쪽으로 드래그하는 임시 삭제는 `documentContextBeforeInput?.last`가 없으면 삭제 요청 자체를
중단한다.

Messages는 줄 시작에서 `documentContextBeforeInput`을 `nil` 또는 빈 문자열로 제공할 수 있다.
따라서 일반 반복 삭제는 줄바꿈을 넘지만, 삭제 드래그는 같은 경계에서 멈춘다.

단순히 빈 문맥을 줄바꿈으로 간주해 `"\n"`을 복구 버퍼에 넣으면 문서 시작의 무효 삭제도 나중에
줄바꿈으로 복구될 수 있다. 줄바꿈 임시 삭제는 실제 proxy 변경을 확인한 뒤에만 확정해야 한다.

## 확정 동작

- 왼쪽 삭제 드래그는 일반 문자뿐 아니라 줄바꿈도 한 단계로 임시 삭제한다.
- 오른쪽 드래그는 임시 삭제한 문자와 줄바꿈을 실제 삭제의 역순으로 정확히 복구한다.
- 줄바꿈 삭제 확인 전 들어온 좌우 pan과 pan stop은 도착 순서를 유지한다.
- 문서 시작의 무효 삭제는 임시 복구 문자, Undo mutation, 삭제 사운드, 햅틱을 만들지 않는다.
- 길게 누른 반복 삭제가 문서 시작에 도달하면 timer와 추가 삭제 피드백만 중단한다.
- 사용자가 손을 누르고 있는 동안 삭제 버튼의 눌린 UI를 유지하고, 손을 떼는 실제 gesture 종료에서
  버튼 강조와 gesture 상태를 해제한다.

## 비목표

- 삭제 드래그 거리, 방향 판정, 가속 수치를 변경하지 않는다.
- 반복 삭제 timer 간격 `max(0.01, 0.10 - repeatRate)`을 변경하지 않는다.
- 한글 오토마타의 일반 문자 분해 및 복구 규칙을 변경하지 않는다.
- `selectionWillChange(_:)` 또는 `selectionDidChange(_:)`에 의존하지 않는다.
- Firebase, 광고, entitlement, bundle identifier 또는 provisioning 설정을 변경하지 않는다.

## 설계

### 일반 문자와 불확정 경계 분리

`deleteButtonPanDeleteText(hasPendingRestoreText:)`가 일반 문자 또는 한글 조합 문자를 반환하면 기존
동기 경로를 유지한다. 반환된 실제 문자를 즉시 임시 복구 버퍼에 넣고 사운드·햅틱을 한 번 재생한다.

한글 조합 버퍼와 `documentContextBeforeInput` 모두 삭제 문자를 제공하지 못하면 불확정 경계로
분류한다.

- `textDocumentProxy.hasText == false`이면 문서 전체가 비어 있으므로 삭제를 요청하지 않는다.
- 그 외에는 pan boundary 요청에 `newline` 기대값을 별도로 저장하고 `deleteBackward()`를 정확히
  한 번 호출한다.
- proxy가 제공한 실제 삭제 후보는 빈 문자열로 유지한다. `newline` 기대값은 callback 또는 관찰
  가능한 checkpoint로 확인되기 전에는 mutation, Undo 또는 임시 복구 버퍼에 기록하지 않는다.

### Pan boundary mutation 확인

`DeleteMutationLifecycle`은 기존 touchDown·repeat 요청과 구분되는 pan boundary 요청 종류를
소유한다. 요청 전 앞·뒤 문맥과 `newline` 경계 기대값을 `RepeatDeleteRequest`에 전달한다.

다음 중 하나가 확인되면 줄바꿈 삭제를 authoritative mutation으로 확정한다.

1. `textDidChange(_:)`가 도착했고 뒤 문맥이 유지되면서 앞 문맥이 같은 줄 단위 값으로 유지된다.
2. 비어 있던 앞 문맥이 직전 줄 문맥으로 바뀐다.

확정 결과에는 mutation origin이 pan boundary임을 함께 전달한다. Controller는 Undo mutation을
기록한 뒤 `"\n"`을 `tempDeletedCharacters`에 한 번 추가하고 삭제 사운드·햅틱을 한 번 재생한다.
이 작업은 보류 FIFO를 열기 전에 끝나야 하므로 바로 이어지는 오른쪽 pan이 줄바꿈을 복구할 수 있다.

callback이 실제 삭제를 증명하지 못하거나 입력 대상이 바뀌면 요청과 같은 generation을 취소한다.
취소된 요청은 복구 문자와 피드백을 만들지 않으며 늦은 callback으로 다시 확정되지 않는다.

### Generation과 FIFO

`DeleteInteractionCoordinator`는 live pan이 불확정 경계 요청을 시작할 때 현재 generation을
`waiting`으로 전환한다. 기존 generation이 없다면 새 generation을 만들고, replay 중인 pan이면 같은
generation을 그대로 사용한다.

`waiting` 동안 도착한 이벤트는 기존 typed FIFO에 순서대로 저장한다.

```swift
enum PendingDeleteInteractionEvent {
    case touchDown(button: any TextInteractable)
    case pan(direction: PanDirection)
    case panStop
}
```

줄바꿈 mutation이 확인되면 같은 generation을 resolve하고 FIFO를 다시 연다. replay된 pan이 또 다른
불확정 경계에 도달하면 그 이벤트를 실행한 generation을 다시 `waiting`으로 바꾼다. 이로써 callback을
기다리는 동안 드래그 이동량을 잃거나 좌우 순서를 바꾸지 않는다.

pan stop이 callback보다 먼저 도착하면 stop도 FIFO에 남기고 요청을 released 상태로 전환한다.
늦은 callback이 mutation을 확정하면 먼저 임시 복구 버퍼를 갱신한 뒤 pan stop cleanup을 실행한다.
문서 전체가 비어 있음이 `hasText == false`로 확인된 경우에는 callback을 기다리지 않고 `.noDeletion`
으로 resolve하여 보류된 왼쪽 no-op을 보충 삭제로 실행하지 않는다.

released pan boundary의 다음 checkpoint에서도 앞·뒤 문맥과 선택 상태가 요청 전과 같고 실제 삭제
후보가 비어 있으면 `.noDeletion`으로 resolve한다. 이 checkpoint는 줄바꿈 mutation을 추론하지 않으며,
FIFO 앞에 연속해서 쌓인 left pan만 무효 시도로 폐기한다. 뒤에 right pan이 있으면 기존 임시 복구
버퍼를 사용해 그대로 실행하고, right 뒤의 left pan은 새 현재 문맥에서 다시 판정한다.

### 반복 삭제 문서 시작 UI

반복 삭제가 `.noDeletion`으로 끝날 때 controller는 timer와 반복 상태만 종료한다. 이 경로에서
`button.isGesturing = false`, 현재 pressed button 해제 또는 gesture 강제 release를 수행하지 않는다.

실제 `touchUp`, `touchCancel`, long press 종료가 기존 gesture controller 경로로 도착할 때 버튼
강조와 gesture 상태를 해제한다. 문서 시작 도달 시점부터 손을 뗄 때까지 새 delete, Undo mutation,
사운드, 햅틱은 발생하지 않는다.

## 오류 및 취소 경계

- non-delete 입력, suggestion, Undo/Redo, non-nil `inputIdentifier` 변경,
  `viewWillDisappear(_:)`는 pan boundary 요청과 FIFO를 함께 취소한다.
- 취소 시 delete drag overlay, base 임시 복구 버퍼, 한글 pan 임시 상태를 정확히 한 번 정리한다.
- 취소 또는 `.noDeletion` 뒤 도착한 callback은 이전 generation을 열거나 mutation을 기록하지 않는다.
- 문서 시작에서 무효였던 pan 횟수는 누적하지 않으며 이후 한 이벤트에서 여러 삭제로 보충하지 않는다.

## 테스트

Swift Testing으로 다음 회귀를 RED에서 먼저 확인한다.

1. 앞 문맥이 비어 있고 문서에 텍스트가 남아 있으면 pan boundary delete를 한 번 요청한다.
2. callback에서 빈 앞 문맥이 직전 줄 문맥으로 바뀌면 `"\n"` mutation과 pan 복구 문자를 한 번
   확정한다.
3. callback에서 줄 단위 문맥이 같아도 pan boundary `newline` 기대값을 `"\n"` mutation으로 한 번
   확정한다.
4. 확인 전 도착한 left, right, pan stop은 FIFO 순서를 유지한다.
5. 확인된 `"\n"`을 FIFO replay 전에 복구 버퍼에 넣어 바로 다음 right pan이 줄바꿈을 복원한다.
6. 문서 전체가 비어 있으면 delete 호출, 복구 문자, Undo, 사운드, 햅틱이 모두 0회다.
7. 문서 시작의 보류 left는 다음 이벤트에서 보충 삭제되지 않는다.
8. 취소된 pan boundary generation의 늦은 callback은 mutation과 복구 문자를 만들지 않는다.
9. 반복 삭제의 `.noDeletion`은 timer를 중단하지만 손을 떼기 전 버튼 UI를 강제로 해제하지 않는다.
10. 실제 gesture 종료는 버튼 강조와 gesture 상태를 정상 해제한다.
11. 기존 일반 문자·한글 조합 delete drag 복구 테스트와 coordinator/lifecycle 테스트가 모두 통과한다.

## 수동 검증

Messages 실제 입력 화면에서 다음을 확인한다.

1. `가나다\n라마바` 끝에서 왼쪽으로 드래그하면 `라마바`, 줄바꿈, `가나다` 순서로 계속 삭제된다.
2. 같은 거리만큼 오른쪽으로 드래그하면 줄바꿈 위치까지 원문과 동일하게 복구된다.
3. 줄바꿈 확인을 기다리는 지점에서 빠르게 좌우 왕복해도 문자 중복·누락·순서 변경이 없다.
4. 문서 시작에서 더 왼쪽으로 드래그해도 줄바꿈이 새로 생기거나 추가 피드백이 발생하지 않는다.
5. 한글·영문 키보드에서 길게 삭제해 문서 시작에 도달하면 손을 누르는 동안 버튼 UI가 유지된다.
6. 문서 시작에서 손을 떼면 버튼 강조와 gesture 상태가 정상 해제된다.

실제 사운드·햅틱은 물리 기기에서 확인하며 자동 테스트 결과로 통과 처리하지 않는다.

## 완료 조건

- Messages에서 삭제 드래그가 줄바꿈을 넘어가고 오른쪽 드래그로 정확히 복구된다.
- 실제 확인된 줄바꿈만 임시 복구 버퍼와 Undo history에 한 번 기록된다.
- 확인 대기 중 pan과 pan stop의 도착 순서가 보존된다.
- 문서 시작 무효 삭제는 mutation, 복구 문자, 추가 피드백 또는 보충 삭제를 만들지 않는다.
- 반복 삭제는 문서 시작에서 멈추되 버튼 UI는 실제 손을 뗄 때 해제된다.
- 관련 집중 테스트, 전체 `SYKeyboard` 테스트, `HangeulKeyboard`와 `EnglishKeyboard` 빌드가 통과한다.

# Delete Interaction Coordinator 설계

## 목적

Cycle 5에서 보류된 delete touchDown, delete pan 방향, pan stop이 서로 다른 저장소에 나뉘어 순서와
취소 경계를 잃는 문제를 해결한다. 새 `DeleteInteractionCoordinator`는 한 delete interaction
generation에 속한 보류 이벤트를 단일 FIFO로 관리하고, 같은 generation의 삭제 mutation이 명시적으로
확정된 경우에만 재생을 허용한다.

다음은 비목표다.

- `RepeatDeleteRequest`의 실제 mutation 판정 규칙 변경
- Hangeul automata, suggestion replacement, Undo/Redo grouping 의미 변경
- 반복 삭제 timer 간격 또는 feedback 시점 변경
- `selectionWillChange(_:)`/`selectionDidChange(_:)` 의존 추가
- Messages 실제 입력 화면, 물리 사운드·햅틱 자동화

## 아키텍처

### 책임 분리

- `RepeatDeleteRequest`와 `DeleteMutationLifecycle`
  - 요청 전·후 문맥과 draft를 비교해 실제 mutation, `.noDeletion`, pending, cancellation을 판정한다.
  - 이벤트 순서나 UI target을 소유하지 않는다.
- `DeleteInteractionCoordinator`
  - 증가하는 generation ID와 해당 generation의 상태를 소유한다.
  - 보류된 typed event를 하나의 FIFO로 보관한다.
  - positive resolution만 replay 권한으로 바꾸고 cancellation은 원자적으로 모든 보류 상태를 폐기한다.
- `BaseKeyboardViewController`
  - lifecycle 결과를 coordinator의 resolve/cancel로 전달한다.
  - coordinator가 반환한 이벤트를 기존 semantic entry point로 실행한다.
  - pan cleanup과 overlay 같은 UIKit side effect를 정확히 한 번 수행한다.

### Typed event

FIFO 이벤트는 다음 세 종류뿐이다.

```swift
enum PendingDeleteInteractionEvent {
    case touchDown(button: any TextInteractable)
    case pan(direction: PanDirection)
    case panStop
}
```

`touchDown` 이벤트는 버튼을 강하게 보존한다. replay 시
`textInteractionWillPerform(button:)` → 기존 delete body →
`textInteractionDidPerform(button:)` 전체를 호출한다. target을 잃은 상태에서 raw delete body만
실행하는 fallback은 두지 않는다. generation이 취소되면 queue와 함께 target도 해제한다.

## 상태와 데이터 흐름

Coordinator 상태는 `idle`, `waiting(generation)`, `ready(generation)` 세 가지다.

1. `idle`에서 실제 delete touchDown이 오면 새 generation을 만들고 `waiting`으로 전환한다.
   최초 touchDown은 기존 경로에서 즉시 실행한다.
2. `waiting` 또는 `ready`인 동안 도착한 touchDown, pan 방향, pan stop은 같은 generation FIFO의
   끝에 등록한다. 서로 다른 count/array/flag에 나누어 저장하지 않는다.
3. lifecycle이 같은 요청을 mutation 또는 `.noDeletion`으로 확정하면 coordinator에 positive
   resolution을 전달한다.
   - FIFO가 비어 있으면 `idle`로 끝낸다.
   - FIFO가 남아 있으면 `ready`가 된다.
4. `ready`에서 이벤트를 하나씩 앞에서 꺼낸다.
   - `pan`은 기존 pan delete/restore semantic 경로를 실행한다.
   - `panStop`은 임시 삭제 버퍼와 Hangeul pan 상태를 정리한다.
   - `touchDown`은 이벤트를 반환하기 전에 coordinator를 다시 `waiting`으로 바꾼다. controller는
     저장된 strong target으로 전체 hook과 delete body를 실행한다.
5. replay touchDown의 mutation이 다시 확정되어야 다음 FIFO 이벤트를 꺼낼 수 있다.

`idle`일 때 새로 들어온 live pan은 즉시 실행할 수 있다. 과거 queue는 cancellation에서 이미 제거되어야
하며, 단순히 lifecycle request가 없다는 이유로 저장된 이벤트를 허가하는 경로는 만들지 않는다.

### 동기 callback 재진입

Controller의 drain guard는 재생 루프 안에서 발생한 동기 `textDidChange(_:)`가 중첩 drain을 시작하지
못하게 한다. 또한 coordinator는 replay touchDown을 반환하기 전에 `waiting`으로 전환한다. 따라서
동기 callback이 먼저 resolution을 기록해도 다음 이벤트가 현재 touchDown보다 앞서 실행되지 않는다.
바깥 drain은 semantic hooks와 mutation이 끝난 뒤 새 상태를 읽어 FIFO를 계속 처리한다.

## Generation 소유권과 취소

Generation은 최초 touchDown 시점의 마지막으로 알려진 non-nil `inputIdentifier`와 FIFO를 소유한다.
`textWillChange(_:)`에서 기존 owner와 새 identifier가 모두 non-nil이고 서로 다르면 focus 변경으로
즉시 취소한다. owner가 아직 nil이면 처음 확인된 non-nil identifier를 채우고, 문맥 불일치는 아래
lifecycle 결과에서 취소한다.

다음 경계는 active generation과 queue를 원자적으로 폐기한다.

- non-delete 입력 직전
- lifecycle이 context 불일치 callback을 cancellation으로 판정한 때
- non-nil `inputIdentifier` 변경
- `viewWillDisappear(_:)`
- touchDown 보존을 명시하지 않은 repeat tracking stop

기존 `preservingTouchDown: true` 종료는 late callback을 기다리는 의미를 유지하므로 cancellation
경계로 취급하지 않는다.

Coordinator는 generation 안에서 pan이 시작되었고 아직 `panStop` cleanup이 소비되지 않았는지
추적한다. cancellation 결과는 `shouldFinishPanTracking`을 한 번만 반환한다. Controller는 이 신호가
있을 때 overlay 숨김, `tempDeletedCharacters` 초기화, `deleteButtonPanDidStop()`을 한 번 수행한다.
두 번째 cancel이나 늦은 resolution은 이미 폐기된 generation과 cleanup을 다시 실행하지 않는다.

## 보존해야 할 기존 계약

- callback-free 문서 시작 no-op proof와 nonempty proxy 대기
- 기존 lifecycle 회귀 16개
- initial touchDown feedback 중복 없음
- 확인된 repeat mutation당 feedback 한 번
- `max(0.01, 0.10 - repeatRate)` timer 간격
- 이전 삭제를 callback 또는 checkpoint로 확인할 수 있고 삭제할 문자가 남은 정상 반복 상태에서
  매 timer tick마다 새 delete 정확히 한 번
- 문서 시작 또는 이전 삭제 확인 실패로 delete가 없는 tick의 횟수를 누적하지 않고, 어느 tick에서도
  새 delete를 두 번 이상 호출하지 않음
- English timer와 Hangeul immediate repeat 전환
- suggestion replacement 복구, temporary delete buffer, Hangeul touchDown/pan hooks
- 최초 줄바꿈과 이어지는 delete/pan mutation의 grouped Undo/Redo
- Firebase, 광고, entitlement, bundle 설정 무변경

## RED/GREEN 테스트 매트릭스

| 회귀 | RED에서 증명할 부재 | GREEN 기대 |
|---|---|---|
| non-delete/context/view/stop 취소 | generation-owned cancellation API와 stale queue 폐기 부재 | 이벤트 재생 0회, pan cleanup 1회 |
| `inputIdentifier` 변경 | owner identity 비교와 늦은 resolution 거부 부재 | 새 field mutation 0회, stale generation resolve 거부 |
| pan 여러 개 → stop → touchDown 여러 개 | 분리 저장소가 FIFO 순서를 표현하지 못함 | 등록 순서 그대로 replay |
| strong touchDown target | weak target 소멸 시 raw fallback 가능 | replay까지 target 유지, 취소 시 mutation 없이 해제 |
| 동기 callback 재진입 | touchDown replay 전에 다음 event 접근 가능 | touchDown resolution 전 `nextEvent == nil` |
| timer tick cadence | 정상 반복 tick과 예외 tick의 삭제 횟수 구분 부재 | 정상 반복 tick은 1회, 예외 tick은 0회, 다음 tick 보충 실행 없음 |
| 기존 lifecycle 16개 | coordinator 분리 중 기존 의미 회귀 가능 | 전부 통과 |
| 전체 suite와 extension | 통합 또는 컴파일 회귀 가능 | 전체 테스트 및 양쪽 extension build 성공 |

Focused RED는 coordinator 타입과 계약이 없는 상태에서 정확한 새 suite를 실행해 실패를 확인한다.
최소 구현 뒤 같은 명령을 GREEN으로 만들고, 전체 suite와 `HangeulKeyboard`/`EnglishKeyboard` build를
iPhone 13 mini / iOS 16.0에서 새로 실행한다.

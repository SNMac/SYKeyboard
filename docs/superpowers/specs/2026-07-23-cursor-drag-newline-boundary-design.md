# 커서 드래그 줄바꿈 경계 이동 수정 설계

## 배경

커서 드래그는 `CursorDragAccelerationPolicy.applicableSteps`에서
`documentContextBeforeInput` 또는 `documentContextAfterInput`의 길이로 실제 이동 step을 제한한 뒤,
`UITextDocumentProxy.adjustTextPosition(byCharacterOffset:)`를 호출한다.

호스트 앱이 줄바꿈 문자 바로 앞에서 `documentContextAfterInput`을 `nil` 또는 빈 문자열로 제공하면
오른쪽 이동 step이 0이 된다. 이 경우 UIKit에 이동 요청을 보내지 않아 커서가 다음 줄로 넘어가지 못한다.
반대 방향은 `documentContextBeforeInput`이 제공되므로 같은 줄바꿈 경계를 통과할 수 있다.

메시지 앱에서는 키보드 드래그로 여러 줄을 이동한 뒤 반복 삭제하면 줄바꿈 경계의
`documentContextBeforeInput`이 실제 삭제 문자와 일치하지 않는 경우도 확인됐다. 기존 구현은 앞 문맥이
비어 있을 때만 삭제 callback을 기다리고, 문맥이 있으면 마지막 글자를 실제 삭제 문자로 즉시 undo history에
기록한다. 따라서 실제로는 줄바꿈을 삭제했어도 직전 줄의 마지막 글자(재현 사례에서는 `라`)가 기록되어,
전체 삭제 후 한 번의 undo가 `가나\n다라\n마바\n` 대신 `가나다라라\n마바\n`을 복원한다.

## 목표

- 줄바꿈 문자 바로 앞에서 오른쪽 드래그하면 다음 줄 시작으로 이동한다.
- 기존 일반 문자 구간의 좌우 step 제한과 최대 4칸 가속을 유지한다.
- 실제 커서 위치가 바뀐 경우에만 햅틱을 재생한다.
- 반복 삭제는 삭제 요청 전 proxy 문맥을 그대로 신뢰하지 않고 실제 text change를 확인한 뒤 undo에 기록한다.
- 커서 드래그 후에도 한 번의 undo가 삭제 전 텍스트를 문자와 줄바꿈 순서까지 동일하게 복원한다.
- 한글/영문 키보드가 공유하는 `SYKeyboardCore`에서 동일하게 동작한다.

## 비목표

- 드래그 속도 및 가속 threshold를 변경하지 않는다.
- 삭제 버튼 드래그 삭제/복구 동작을 변경하지 않는다.
- `selectionWillChange(_:)` 또는 `selectionDidChange(_:)` 호출에 의존하지 않는다.
- Firebase, 광고, 권한, bundle 설정은 변경하지 않는다.

## 설계

### 줄바꿈 경계 이동

`CursorDragAccelerationPolicy.applicableSteps`는 일반 문맥이 제공될 때 기존처럼 요청 step과 문맥 길이 중
작은 값을 반환한다. 오른쪽 문맥이 `nil` 또는 빈 문자열이면 실제 문서 끝인지 줄바꿈 경계인지 proxy 값만으로
구분할 수 없으므로 1칸 이동을 허용한다.

`BaseKeyboardViewController`는 반환된 1칸을
`textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)`로 요청한다. 실제 문서 끝이면 UIKit이 요청을
무시하고, 줄바꿈 경계이면 다음 줄 시작으로 커서를 옮긴다.

왼쪽 이동 정책은 변경하지 않는다. 보고된 실패가 오른쪽 줄바꿈 경계에 한정되고, 왼쪽의 문맥 없는 경계를
허용하면 문서 시작에서 불필요한 이동 요청이 추가되기 때문이다.

### 햅틱

`moveCursorIfPossible(to:steps:)`는 이동 요청 직후 햅틱을 재생하지 않는다. 대신 이동 요청 직전의
`documentContextBeforeInput`과 `documentContextAfterInput`을 pending 문맥으로 저장한다.

현재 확인된 환경에서는 focus 중인 텍스트 필드의 커서 이동 시
`UIInputViewController.textDidChange(_:)`가 호출된다. 이 callback에서 primary 커서 드래그가 활성 상태인
동시에 pending 요청이 있고, callback 시점의 문맥이 이동 전 문맥과 달라진 경우에만 강제 햅틱을 한 번
재생한다. 호스트별로 `nil`과 빈 문자열이 달라질 수 있으므로 문맥 비교에서는 둘을 같은 값으로 취급한다.

- 실제 이동 성공: `textDidChange(_:)` 호출 + 문맥 변경 → 햅틱 재생
- 문서 끝의 무효 오른쪽 이동: callback 없음 → 햅틱 없음
- 동일 문맥 callback 또는 pending 요청 없는 callback: 햅틱 없음
- 키 입력이나 외부 텍스트 변경: primary 커서 드래그 상태가 아님 → 커서 이동 햅틱 없음

자동완성 후보 갱신은 기존처럼 primary 커서 드래그 중 `textDidChange(_:)`에서 건너뛴다.

### 줄바꿈 경계 반복 삭제와 피드백

반복 삭제는 앞 문맥의 유무와 관계없이 매 tick을 하나의 pending 요청으로 다룬다. 요청에는 삭제 직전의
앞·뒤 문맥, 선택 텍스트, 입력 로직이 계산한 삭제 후보와 치환 결과를 저장한다. 삭제 요청 시점에는 proxy
문맥에서 얻은 후보를 undo history에 확정하지 않는다. 같은 요청이 pending인 동안 다음 timer tick은
먼저 직전 삭제를 확인하며, 확인 전에는 새 삭제를 요청하지 않는다.

`textDidChange(_:)`에서 뒤 문맥이 유지되고 다음 조건 중 하나를 만족하면 실제 뒤로 삭제가 수행된 것으로
확인한다.

- 일반 문자: callback 뒤의 앞 문맥이 요청 전 앞 문맥에서 삭제 후보를 제거한 결과와 일치한다.
- 줄바꿈 경계: callback이 발생했지만 줄 단위로 잘린 앞 문맥이 그대로이거나, 비어 있던 앞 문맥이 직전
  줄 문맥으로 바뀐다. 이 경우 실제 삭제 문자는 `\n`으로 확정한다.
- 선택 텍스트 또는 한글 조합 치환: 선택 문자열이나 조합 상태 전이가 이미 알고 있는 mutation을 사용하되,
  실제 callback이 발생한 뒤에만 확정한다.

뒤 문맥이 바뀐 외부 편집이나 커서 문맥 변화는 삭제 성공으로 판단하지 않는다. 성공한 요청은 계산된 실제
mutation을 undo history에 정확히 한 번 기록한 다음 삭제 사운드와 햅틱을 재생한다. 요청 상태는 성공을
반환하기 전에 소비하므로 같은 callback이나 다음 timer tick이 동일 요청을 다시 완료할 수 없다. 연속
요청의 기록은 기존 삭제 그룹 병합 규칙을 유지해 undo에서 원래 문자와 줄바꿈 순서로 복원되고 redo에서
다시 삭제된다.

다음 반복 timer tick까지 삭제 callback이 없으면 현재 문맥을 checkpoint로 확인한다. checkpoint에서
직전 요청 전후의 관찰 가능한 문맥 변경이 확인되면 해당 mutation을 확정한 뒤, 같은 timer tick에서 다음
pending 요청을 시작하고 새 삭제를 정확히 한 번 수행한다. 확정 처리는 이미 이전 tick에서 호출된 삭제의
기록일 뿐 새 삭제 호출이 아니므로, timer tick 하나가 새로 호출하는 `deleteBackward()`는 최대 한 번이다.
이 흐름은 callback이 늦은 호스트 앱에서도 확인 전 대기를 위해 매번 빈 tick을 소비하지 않게 해 기존 반복
삭제 속도를 유지한다.

checkpoint에서 문맥 변경을 확인할 수 없으면 직전 요청이 문서 시작에서 무시된 것으로 판단한다. callback
증거 없이 앞·뒤 문맥이 모두 같은 경우에는 줄바꿈 삭제로 추론하지 않는다. 이때
`button.isGesturing`을 `false`로 바꿔 삭제 버튼을 눌리지 않은 UI로 되돌리고 추가 피드백 없이 반복 입력을
종료한다. 무효 요청은 undo mutation을 만들지 않으며, 무효 완료 역시 pending 상태를 먼저 소비해 뒤늦은
callback이 같은 요청을 성공으로 완료하지 못하게 한다.

한글·영문 키보드 모두 삭제할 내용이 없는 상태에서 다음 순서를 따른다.

1. `touchDown`: 사용자가 삭제 버튼을 눌렀다는 첫 번째 사운드·햅틱 피드백
2. 삭제 불가 확인: 추가 피드백 없이 버튼 UI 해제

따라서 삭제할 내용이 없는 상태에서 버튼을 계속 누르면 두 키보드 모두 `touchDown`의 피드백 1회만
제공한다.
별도 고정 지연값은 두지 않고 기존 반복 timer tick을 확인 시점으로 사용한다.

정상적인 long press 종료뿐 아니라 새 반복 세션 시작, 키보드 view 소멸, 타이머가 버튼이나 window를
잃은 중단 경로에서도 pending 상태와 반복 플래그를 함께 초기화한다. 이로써 이전 세션의 pending 요청이
다음 반복 삭제를 막지 않는다.

삭제 버튼을 처음 누르는 `touchDown` 피드백은 사용자가 버튼을 확실히 눌렀음을 알리는 기존 동작이므로
삭제 성공 여부와 무관하게 유지한다. 실제 삭제 확인 조건은 길게 누른 뒤 발생하는 반복 tick의 피드백에만
적용한다. 한글 키보드가 long press 인식 시 즉시 수행하는 첫 반복 삭제도 같은 정책을 거치며, 무효
삭제는 다음 timer tick에서 추가 피드백 없는 UI 해제로 처리한다.

## 테스트

Swift Testing으로 다음 회귀 테스트를 추가한다.

1. 오른쪽 문맥이 빈 문자열이면 적용 가능한 step은 1이다.
2. 오른쪽 문맥이 `nil`이면 적용 가능한 step은 1이다.
3. 일반 오른쪽 문맥에서는 기존처럼 요청 step과 문맥 길이 중 작은 값을 사용한다.
4. primary 커서 드래그 중 pending 요청 전후 문맥이 달라진 `textDidChange(_:)`에서만 커서 이동 햅틱을 허용한다.
5. 동일 문맥, pending 요청 없음, 드래그 상태 아님에서는 커서 이동 햅틱을 허용하지 않는다.
6. 문맥의 `nil`과 빈 문자열 차이만으로는 이동 성공으로 판단하지 않는다.
7. 일반 문자 반복 삭제도 mutation을 즉시 확정하지 않고 callback을 기다린다.
8. callback 뒤 앞 문맥이 삭제 후보를 제거한 결과이면 해당 후보를 undo history에 한 번 기록한다.
9. 줄 단위 앞 문맥이 callback 전후로 같거나 빈 문맥에서 직전 줄 문맥으로 바뀌면 줄바꿈 삭제로 기록한다.
10. 반복 입력 종료, pending 없음, 동일 문맥에서는 삭제 피드백을 허용하지 않는다.
11. pending 요청이 다음 반복 tick까지 완료되지 않으면 삭제 불가 종료 action을 반환한다.
12. 삭제 불가 종료 action은 추가 피드백 없이 UI를 해제한다.
13. 한글·영문 키보드 모두 삭제할 내용이 없을 때 `touchDown` 피드백 1회만 제공한다.
14. 확인된 줄바꿈 삭제는 동일 반복 삭제 그룹의 올바른 순서로 undo되고 redo에서 다시 삭제된다.
15. 성공한 경계 요청은 한 번만 완료되며 이후 무효 완료를 반환하지 않는다.
16. 문서 시작의 무효 경계 요청은 한 번만 완료되며 이후 성공 완료를 반환하지 않는다.
17. 문서 시작의 무효 삭제는 undo mutation을 만들지 않는다.
18. 빈 한글 조합 상태의 경계 반복 삭제는 shared 경계 완료 상태를 사용하면서 조합 buffer를 변경하지 않는다.
19. 메시지 앱처럼 커서 드래그 뒤 줄바꿈 경계에서 직전 줄 마지막 글자가 노출돼도 undo는 해당 글자 대신
    줄바꿈을 복원한다.
20. `가나\n다라\n마바\n`을 커서 드래그 후 전부 반복 삭제하면 한 번의 undo가 원문과 정확히 같은 문자열을
    복원한다.
21. 선택 텍스트와 한글 조합 치환은 callback 확인 뒤 기존 mutation을 중복 없이 기록한다.
22. pending 삭제가 checkpoint에서 확정되면 같은 timer tick에 다음 삭제를 한 번 수행한다.
23. callback과 checkpoint 완료 경로 모두 timer tick당 새 삭제 호출이 최대 한 번이다.
24. checkpoint 문맥이 요청 전과 같으면 새 삭제를 수행하거나 줄바꿈 mutation을 만들지 않고 반복을 종료한다.

RED에서 새 경계 및 햅틱 정책 테스트가 기존 구현과 다르게 실패하는지 확인한 뒤 최소 구현을 추가한다.

## 검증

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

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

수동 검증에서는 여러 줄 텍스트에서 줄바꿈 앞까지 왼쪽으로 이동한 뒤 오른쪽 드래그로 다음 줄에 진입하는지,
문서 끝에서 오른쪽 드래그할 때 햅틱이 울리지 않는지 확인한다. 또한 줄 간 커서 이동 후 삭제 버튼을 길게
눌렀을 때 줄바꿈을 넘어 반복 삭제가 계속되고, 최초 누름에는 항상 피드백이 있으며 이후 반복 tick에는
실제 삭제된 경우에만 삭제 피드백이 재생되는지 확인한다. 한글·영문 키보드 각각에서 문서 시작에 도달하면
버튼 UI가 눌리지 않은 상태로 돌아오며 `touchDown` 이후 추가 피드백이 발생하지 않는지도 확인한다.
메시지 앱에서는 `가나\n다라\n마바\n`을 입력하고 키보드 드래그로 줄 사이를 왕복한 뒤 맨 끝에서 전체 반복
삭제한다. SY키보드 undo 버튼을 한 번 눌러 원문이 중복·누락 없이 복원되는지 확인한다.

## 완료 조건

- 줄바꿈 경계를 좌우 양방향으로 통과할 수 있다.
- 실제 커서 이동에만 햅틱이 발생한다.
- 반복 삭제가 줄바꿈 경계에서 멈추지 않고 실제 삭제된 반복 tick에만 피드백이 발생한다.
- 확인된 줄바꿈 삭제가 undo에서 원래 그룹과 순서대로 복원되고 redo에서 다시 삭제된다.
- 커서 드래그 뒤 proxy가 줄바꿈 대신 직전 줄 문자를 노출해도 undo가 실제 원문을 복원한다.
- 성공과 무효 완료는 같은 speculative 요청에서 상호 배타적이며 무효 요청은 undo 기록을 만들지 않는다.
- callback이 늦어도 삭제 가능한 동안 timer tick당 새 삭제 호출을 한 번 유지하고, 한 tick에서 두 번
  삭제하지 않는다.
- 삭제할 내용이 없으면 추가 피드백 없이 버튼 UI가 해제되고 한글·영문 키보드 모두 총 1회 피드백을 제공한다.
- 신규 회귀 테스트와 기존 전체 테스트가 통과한다.
- 한글/영문 키보드 extension scheme이 빌드된다.

# 커서 드래그 줄바꿈 경계 이동 수정 설계

## 배경

커서 드래그는 `CursorDragAccelerationPolicy.applicableSteps`에서
`documentContextBeforeInput` 또는 `documentContextAfterInput`의 길이로 실제 이동 step을 제한한 뒤,
`UITextDocumentProxy.adjustTextPosition(byCharacterOffset:)`를 호출한다.

호스트 앱이 줄바꿈 문자 바로 앞에서 `documentContextAfterInput`을 `nil` 또는 빈 문자열로 제공하면
오른쪽 이동 step이 0이 된다. 이 경우 UIKit에 이동 요청을 보내지 않아 커서가 다음 줄로 넘어가지 못한다.
반대 방향은 `documentContextBeforeInput`이 제공되므로 같은 줄바꿈 경계를 통과할 수 있다.

## 목표

- 줄바꿈 문자 바로 앞에서 오른쪽 드래그하면 다음 줄 시작으로 이동한다.
- 기존 일반 문자 구간의 좌우 step 제한과 최대 4칸 가속을 유지한다.
- 실제 커서 위치가 바뀐 경우에만 햅틱을 재생한다.
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

## 테스트

Swift Testing으로 다음 회귀 테스트를 추가한다.

1. 오른쪽 문맥이 빈 문자열이면 적용 가능한 step은 1이다.
2. 오른쪽 문맥이 `nil`이면 적용 가능한 step은 1이다.
3. 일반 오른쪽 문맥에서는 기존처럼 요청 step과 문맥 길이 중 작은 값을 사용한다.
4. primary 커서 드래그 중 pending 요청 전후 문맥이 달라진 `textDidChange(_:)`에서만 커서 이동 햅틱을 허용한다.
5. 동일 문맥, pending 요청 없음, 드래그 상태 아님에서는 커서 이동 햅틱을 허용하지 않는다.
6. 문맥의 `nil`과 빈 문자열 차이만으로는 이동 성공으로 판단하지 않는다.

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
문서 끝에서 오른쪽 드래그할 때 햅틱이 울리지 않는지 확인한다.

## 완료 조건

- 줄바꿈 경계를 좌우 양방향으로 통과할 수 있다.
- 실제 커서 이동에만 햅틱이 발생한다.
- 신규 회귀 테스트와 기존 전체 테스트가 통과한다.
- 한글/영문 키보드 extension scheme이 빌드된다.

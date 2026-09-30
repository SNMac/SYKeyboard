# 테스트 유지보수 경계 정리 설계

## 목적

`SYKeyboardTests`에서 제품 동작보다 UIKit의 구체적인 시각 구현을 고정하는
테스트를 줄인다. 동시에 의미 있는 상호작용 회귀는 안정적인 production 정책을
통해 계속 검증하고, production 경로를 호출하지 않는 테스트가 통합 테스트처럼
보이는 문제를 정리한다.

이번 작업은 테스트 유지보수 경계를 정리하는 작업이다. 키보드 입력 동작,
한글 조합 규칙, 자동완성 결과, 삭제·복구·커서 이동·제스처 타이밍은 변경하지
않는다.

## 현재 문제

### 시각 구현 고정

다음 테스트는 비즈니스 동작이 아니라 구체적인 UIKit 구현을 단언한다.

- `CursorDragOverlayTests`
  - `UIGlassEffect`/`UIBlurEffect` 구체 타입
  - SF Symbol 이름
  - `UIVibrancyEffect`가 포함된 subview 계층
- `ReturnButtonTests`
  - 이미지의 template rendering mode
  - 활성·비활성 상태의 정확한 tint 색상
- `SuggestionBarViewPreviewHighlightTests` 일부
  - iOS 버전별 정확한 `UIColor`
  - 재귀 subview 탐색과 `Mirror`를 통한 private 상태 확인

이 테스트들은 색상, 아이콘, material, 내부 view 구조만 바뀌어도 실패한다.

### production 경로를 호출하지 않는 자동완성 검증

`KeyboardControllerSimulator`의 `suggestionCurrentWord`는 실제
`BaseKeyboardViewController.inputBuffer`나 `SuggestionController`를 호출하지
않고 `text`를 그대로 복사한다. 따라서
`test두벌식_삭제버튼드래그_전체복구후_자동완성현재단어동기화`는 production
자동완성 동기화가 끊겨도 통과할 수 있다.

### 한글 테스트 helper의 책임 중복

`HangeulProcessorTestable.applyDelete`는 processor 결과를 받은 뒤 committed와
composing을 갱신하고 committed 마지막 글자를 composing으로 끌어오는
controller 수준의 상태 전이를 직접 재현한다. 같은 책임은 production
`HangeulCompositionState.delete(using:)`에 이미 있다.

## 선택한 접근

### 1. 시각 구현 단언 제거

다음 테스트 파일은 삭제한다.

- `SYKeyboardTests/Utils/CursorDragOverlayTests.swift`
- `SYKeyboardTests/Utils/ReturnButtonTests.swift`

`SuggestionBarViewPreviewHighlightTests`에서는 정확한 label 색상을 검증하는
세 테스트와 색상 기대값 helper를 제거한다.

시각 디자인의 정확성은 unit test가 아니라 실제 화면 확인의 책임으로 둔다.
접근성이나 기능 활성 상태처럼 동작에 영향을 주는 조건은 기존 policy 테스트로
계속 검증한다.

### 2. 자동완성 highlight를 의미 상태로 검증

preview, touch, undo/redo highlight 우선순위는 사용자에게 현재 적용 대상을
알려주는 의미 있는 상호작용 계약이므로 삭제하지 않는다.

`SYKeyboardCore`에 UI 타입을 참조하지 않는 highlight 상태 정책을 추가한다.
정책은 다음 입력을 받는다.

- preview 후보 index
- touch 중인 후보 index
- touch 중인 undo/redo action index
- 후보와 action의 유효 index 범위

정책은 다음 의미 결과를 반환한다.

- 강조할 suggestion index 또는 `nil`
- 강조할 undo/redo action index 또는 `nil`

touch highlight가 하나라도 있으면 preview highlight를 가리고, touch가 끝나면
preview highlight가 다시 적용된다. 유효 범위를 벗어난 index는 강조하지 않는다.

`SuggestionBarView`는 이 정책 결과를 각 버튼의 `isHighlighted`에 반영한다.
기존 `#if DEBUG`의 `updateTouchHighlightForTesting`과
`updateUndoRedoTouchHighlightForTesting`, private 타입명 문자열 검색,
`Mirror` helper는 제거한다.

정책 테스트는 다음을 검증한다.

- preview index가 해당 후보만 강조
- preview `nil`은 후보 강조를 해제
- 후보 touch가 preview를 일시 대체
- undo/redo touch가 preview를 일시 대체
- touch 종료 후 preview 복원
- 범위를 벗어난 index 무시

실제 touch 위치에 따른 후보 선택은 기존
`test긴후보에서시작한드래그도_종료위치후보를선택`으로 유지한다.

### 3. 명시된 자동완성 label 롤백 계약 유지

다음 계약은 현재 저장소의 명시적인 제품 결정이므로 유지한다.

- 후보 내부 가로 스크롤 없음
- label 두 줄
- 글자 크기 자동 축소
- 최소 축소 비율 `0.7`
- 중간 생략

이 테스트는 우연한 UI 상수 고정이 아니라, 롤백된 스크롤 구현이 다시
도입되지 않도록 하는 영구 회귀 계약이다. 이를 변경하려면 테스트만 삭제하지
말고 제품 결정을 먼저 변경해야 한다.

### 4. 거짓 자동완성 통합 검증 제거

`KeyboardControllerSimulator`에서 다음을 제거한다.

- `suggestionCurrentWord`
- `updateSuggestionCurrentWord()`
- 입력·삭제·복구 시 synthetic suggestion 갱신

`HangeulDeleteButtonDragControllerTests`의 synthetic 자동완성 동기화 테스트도
삭제한다.

이번 작업에서는 이를 대체하기 위해 `UIInputViewController`에 test-only proxy나
service initializer를 추가하지 않는다. 테스트 하나를 위해 controller 생성
구조와 UIKit 의존성 주입 범위를 넓히면 테스트 정리 목적보다 production 변경
위험이 커지기 때문이다.

대신 책임별 production 검증 경계를 명확히 유지한다.

- 삭제·복구 뒤 한글 버퍼: `HangeulCompositionState`와 controller simulator
- 자동완성 갱신 action: `KeyboardSuggestionSelectionPolicy`
- 후보 계산과 delegate 결과: `SuggestionController` 테스트

향후 controller부터 suggestion delegate까지의 실제 통합 검증이 필요해지면
별도 설계에서 document proxy와 suggestion service 주입 경계를 함께 다룬다.

### 5. 한글 helper의 controller 로직 복제 축소

`HangeulProcessorTestable.applyDelete`를 제거한다.

- processor 자체 삭제 결과를 검증하는 테스트는
  `deleteWithRestore종성`의 `DeleteResult`를 직접 단언한다.
- 입력부터 삭제까지의 상태 시나리오는 production
  `HangeulCompositionState.delete(using:)`를 호출하는 test harness로 옮긴다.
- 상태 시나리오는 가능한 한 빈 상태에서 실제 입력 순서를 재생한다.
- 임의의 중간 상태가 꼭 필요한 processor 단위 테스트는 controller 상태를
  흉내 내지 않고 processor가 반환한 `consumedCommittedCount`와 `composing`을
  직접 검증한다.

`applyInput`은 processor의 연속 변환 결과를 읽기 쉽게 누적하는 processor
테스트 helper로 한정한다. controller 또는 integration 동작을 검증한다고
설명하지 않으며, committed 보호·끌어오기·proxy edit 검증에는 사용하지 않는다.

기존 `KeyboardControllerSimulator`는 production `HangeulCompositionState`를
직접 사용하므로 한글 controller 상태 시나리오용으로 유지한다. 다만
production controller 전체를 실행하는 것처럼 보이지 않도록 문서와 suite
설명에서 검증 범위를 `HangeulCompositionState 기반 상태 시나리오`로 명시한다.

## `AGENTS.md` 반영

테스트 지침에 다음 규칙과 예시를 추가한다.

### 추가 규칙

- 숫자가 있다는 이유만으로 UI 구현 테스트로 판단하지 않는다. 입력 임계값,
  키보드 높이 계산식, 타이머 하한처럼 사용자 동작과 안전성에 영향을 주는
  정책 수치는 검증한다.
- exact color, font, SF Symbol 이름, corner radius, effect subclass,
  private subview 계층, `Mirror` 기반 private 상태는 unit test에서 고정하지
  않는다.
- 시각 표현을 검증해야 하면 명시적인 제품 계약인지 먼저 확인하고, 그렇지
  않으면 실제 화면 확인이나 별도 시각 회귀 검증으로 다룬다.
- production 동작을 검증한다고 주장하는 테스트는 해당 production 진입점을
  호출해야 한다. helper가 결과를 직접 계산하거나 production 로직을 복제한
  경우 통합 검증으로 인정하지 않는다.
- production 클래스에 `ForTesting` 메서드를 추가하지 않는다. 의미 있는
  상태 계산은 production policy로 분리하고, UI 결과는 공개된 동작으로
  확인한다.
- processor 단위 테스트는 processor 반환값을 검증하고, controller 수준의
  committed/composing 상태 전이는 `HangeulCompositionState`를 사용한다.

### 문서 예시

- 유지: 커서 속도에 따른 이동 step, suggestion bar 표시 여부, 키보드 높이
  계산, 제스처 취소 후 입력 복구
- 제거 또는 시각 검증으로 이동: 정확한 tint, blur/glass 구체 타입, SF Symbol
  이름, private subview 구조
- 명시적 예외: 현재 자동완성 후보의 스크롤 없음·두 줄·자동 축소·중간 생략
  롤백 계약

## 검증

변경 후 다음을 확인한다.

1. 삭제된 visual test와 helper를 참조하는 코드가 남지 않았는지 `rg`로 확인
2. 새 highlight 정책 집중 테스트 실행
3. `SuggestionBarViewPreviewHighlightTests` 실행
4. 한글 processor와 `HangeulCompositionState` 관련 테스트 실행
5. 전체 `SYKeyboardTests` 실행
6. `SYKeyboard`, `HangeulKeyboard`, `EnglishKeyboard` scheme 빌드
7. `git diff --check`와 `git status --short`로 변경 범위 확인

기본 `iPhone 13 mini / iOS 16.0` runtime이 없으면 사용 가능한 가장 가까운
iOS 16+ Simulator를 사용하고 실제 기기명과 OS 버전을 결과에 기록한다.

## 범위 밖

- 키보드 UI 디자인 변경
- 자동완성 알고리즘 또는 후보 순서 변경
- 한글 processor/automata 동작 변경
- `UITextDocumentProxy`와 `SuggestionService`의 controller 의존성 주입 재설계
- snapshot test framework 도입
- Firebase, AdMob, entitlement, bundle identifier 변경

## 성공 기준

- 명확한 visual implementation unit test가 제거된다.
- highlight 우선순위는 private view 구조가 아닌 production 의미 정책으로
  검증된다.
- production의 `ForTesting` highlight API와 테스트의 `Mirror` 탐색이 사라진다.
- synthetic 자동완성 상태를 production 결과처럼 검증하는 테스트가 사라진다.
- processor test helper가 controller 삭제 상태 전이를 복제하지 않는다.
- `AGENTS.md`만 읽어도 새 테스트의 허용·금지 경계를 판단할 수 있다.
- 기존 입력·한글 조합·자동완성 동작은 변경되지 않으며 관련 테스트와 빌드가
  통과한다.

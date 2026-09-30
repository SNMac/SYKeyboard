# 수식 자동완성 머지 전 안정성 보강 설계

## 목적

수식 자동완성 브랜치의 머지 전 리뷰에서 확인한 다음 두 안정성 위험을 제거한다.

- 키보드 표시 전 `textDocumentProxy.mathExpressionCompletionType` 접근
- 제한 없는 수식 길이와 괄호 재귀 깊이

기존 수식 계산 결과, selection-origin 검증, 일반 자동완성, n-gram, 텍스트 대치와
한글·영문 입력 동작은 변경하지 않는다.

## 현재 문제

### 조기 document proxy trait 접근

`BaseKeyboardViewController.viewDidLoad()`가 `shouldShowMathResults()`를 호출한다.
iOS 18 이상에서 이 메서드는 `textDocumentProxy.mathExpressionCompletionType`을 직접
읽으므로, host document state가 안정되기 전 proxy trait에 접근하지 않는 기존
수명주기 계약을 위반한다.

프로젝트에서 실제 호출을 확인한 `textWillChange(_:)`와 `textDidChange(_:)`를 host
입력 trait 동기화 경계로 유지한다. Apple UIKit 문서상
`mathExpressionCompletionType`은 iOS 18 이상 `UITextInputTraits` 속성이다.

### 제한 없는 parser 입력

`MathExpressionCompletionEvaluator.completion(for:)`은 선택 텍스트와 `inputBuffer`를
길이 제한 없이 받는다. `MathExpressionParser`는 여는 괄호마다
`parseExpression()`을 재귀 호출하므로 큰 selection이나 과도한 중첩이 키보드
확장의 지연, 스택 사용량 증가 또는 메모리 압박으로 이어질 수 있다.

## 선택한 방식

### 1. host 수식 자동완성 허용 여부를 Bool로 캐시

`BaseKeyboardViewController`에 다음 상태를 둔다.

```swift
private var isMathExpressionCompletionAllowed = true
```

초깃값 `true`는 첫 text-change callback 전 기존 설정 기반 동작을 유지한다. 실제
수식 후보 갱신은 입력 callback 이후 수행되므로 host trait가 `.no`이면 후보 생성 전에
캐시가 갱신된다.

기존 `currentAutocorrectionType`과 함께 갱신하는 private 메서드를 추가한다.

```swift
func synchronizeTextInputTraits() {
    currentAutocorrectionType = textDocumentProxy.autocorrectionType

    if #available(iOS 18.0, *) {
        isMathExpressionCompletionAllowed =
            textDocumentProxy.mathExpressionCompletionType != .no
    } else {
        isMathExpressionCompletionAllowed = true
    }
}
```

이 메서드는 `textWillChange(_:)`와 `textDidChange(_:)`에서만 호출한다.
`viewDidLoad()`, `viewWillAppear(_:)`, `shouldShowMathResults()`는 host input trait를
직접 읽지 않는다.

`KeyboardPresentationStatePolicy`에 설정과 host 허용 상태를 조합하는 production
정책을 둔다.

```swift
static func shouldShowMathResults(
    isSettingEnabled: Bool,
    isHostCompletionAllowed: Bool
) -> Bool {
    return isSettingEnabled && isHostCompletionAllowed
}
```

`shouldShowMathResults()`는 저장된 사용자 설정과 캐시만 이 정책에 전달한다. 실제
`UITextMathExpressionCompletionType`을 저장하지 않아 iOS 18 availability가 property
선언까지 번지지 않게 한다.

### 2. evaluator 길이 256자와 parser 중첩 16단계 제한

`MathExpressionCompletionEvaluator`의 production 진입점에서 원본 입력 길이가
256자를 초과하면 후보를 만들지 않는다. 256자는 허용하고 257자부터 거부한다.

```swift
static let maximumInputLength = 256

guard text.count <= maximumInputLength else { return nil }
```

원본을 마지막 256자로 자르지 않는다. 잘린 prefix 때문에 사용자가 입력하지 않은
짧은 수식으로 해석되는 것을 막기 위해 전체 입력을 거부한다.

`MathExpressionParser`는 현재 괄호 중첩 깊이를 보관한다. 최대 16단계는 허용하고
17번째 여는 괄호에서 `nil`을 반환한다. sibling 괄호가 누적되지 않도록 각
`parsePrimary()` 재귀 호출 뒤 깊이를 복구한다.

```swift
private static let maximumNestingDepth = 16
private var nestingDepth = 0
```

반복식 parser로 전환하거나 별도 parser protocol을 추가하지 않는다. 현재 recursive
descent 구조에 두 guard만 추가하는 것이 가장 작은 검증 가능한 변경이다.

## 데이터 흐름

```text
textWillChange / textDidChange
  -> textDocumentProxy trait 읽기
  -> autocorrection + math 허용 캐시 갱신
  -> 표시 정책은 캐시만 사용

selectedText / inputBuffer / 제한된 document context
  -> evaluator 입력 길이 확인 (<= 256)
  -> suffix 후보 생성
  -> parser 괄호 깊이 확인 (<= 16)
  -> 기존 계산·formatting·origin-aware action
```

## 변경 범위

- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - host 수식 허용 캐시와 callback 동기화
  - `shouldShowMathResults()`의 직접 proxy 접근 제거
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift`
  - 설정과 host 허용 상태 조합 정책
- `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift`
  - 입력 길이와 parser 중첩 깊이 제한
- `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift`
  - 설정·host 허용 상태 조합 검증
- `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift`
  - 256/257자와 16/17단계 경계 검증

신규 의존성, 테스트 전용 production API와 parser 구조 변경은 추가하지 않는다.

## 테스트 설계

### Presentation policy

- 설정 OFF + host 허용: 숨김
- 설정 ON + host 거부: 숨김
- 설정 ON + host 허용: 표시
- `viewDidLoad()`와 `viewWillAppear(_:)` 경로에서 host trait 직접 접근이 남지 않음

### Evaluator production 진입점

- 정확히 256자인 정상 수식은 계산
- 256자를 초과한 수식은 `nil`
- 괄호 16단계는 계산
- 괄호 17단계는 `nil`
- `.5+1=`, 일반 사칙연산, 기존 괄호 수식과 적대 입력은 그대로 통과

정상 256자 수식은 `"1+"` 127회와 `"1="`을 결합해 결과 `128`을 검증한다.
중첩 테스트는 동일한 production `completion(for:)` 진입점을 호출한다.

### 회귀 검증

- 전체 `SYKeyboard` 테스트
- `HangeulKeyboard`, `EnglishKeyboard` scheme 빌드
- iOS 18 이상 실기기에서 빠른 키보드 열기·닫기, 입력 필드 전환, 회전,
  predictive text와 수식 결과 설정 조합 확인
- 수식 preview, 가운데·오른쪽 후보 탭과 스페이스 확정 확인

## 완료 기준

- appearance 전 경로에서 `mathExpressionCompletionType`을 직접 읽지 않는다.
- host `.no`와 사용자 설정 OFF에서 수식 후보가 생성되지 않는다.
- 256자 및 16단계 경계가 production 테스트로 고정된다.
- 기존 수식·selection-origin·일반 추천 테스트와 두 extension 빌드가 통과한다.
- 실제 host 앱 수동 확인을 수행하지 못하면 머지 가능으로 표시하지 않고 미확인
  경로를 기록한다.

# 수식 자동완성 최종 리뷰 수정 설계

## 목적

최종 브랜치 리뷰에서 발견된 다음 두 결함을 수정한다.

1. 선택된 텍스트가 수식일 때 일반 선택 후보 처리와 수식 처리가 충돌한다.
2. 수식 parser가 숫자 사이 공백을 제거해 서로 다른 숫자를 하나로 결합한다.

스크롤 롤백, 일반 자동완성, 텍스트 대치와 수식이 선택되지 않은 상태의 기존
좌·중·우 후보 의미는 유지한다.

## Root cause

### 선택된 수식

`KeyboardSuggestionSelectionPolicy`는 공백이 없는 선택 텍스트를 그대로
`SuggestionController.updateSuggestions(for:)`에 전달한다. `3+1=`은 수식 모드로
전환되지만 후보 탭에서는 `handleSelectedTextSuggestion`이
`handleMathResultSuggestion`보다 먼저 실행된다. 일반 선택 후보의 `index - 1`
매핑이 수식 후보에 적용되어 표시 의미와 다른 텍스트가 선택 영역에 삽입된다.

스페이스 입력도 현재 모드만 확인하고 가운데 수식 후보의 `insertText`를
삽입하므로, 선택된 `3+1=`이 결과 `4`로 교체된다.

### 숫자 사이 공백

`expressionSuffix`는 공백을 수식 문자로 허용하고 `MathExpressionParser` 초기화는
모든 공백을 제거한다. 따라서 `1 2+3=`과 문장 뒤의 `memo 2 3+1=`이 각각
`12+3=`, `23+1=`로 정규화되어 잘못된 후보를 만든다.

## 선택된 수식 처리

선택한 방식은 **선택 텍스트에서도 수식 결과 후보를 동일한 좌·중·우 의미로
지원하는 것**이다.

선택된 `3+1=`에는 기존과 같은 후보를 표시하고 다음 편집을 수행한다.

| 후보 | 표시 | 선택 시 결과 |
| --- | --- | --- |
| 왼쪽 | `"3+1="` | 선택 영역과 원문을 변경하지 않고 후보만 확정 |
| 가운데 | `3+1=4` | 선택 영역을 `3+1=4`로 교체 |
| 오른쪽 | `4` | 선택 영역을 `4`로 교체 |

스페이스는 현재 preview와 같은 가운데 후보를 적용한다. 선택된 `3+1=`을
`3+1=4`로 교체한 뒤 일반 스페이스 입력을 이어서 수행한다.

### 공통 action

`SuggestionController`가 탭·스페이스에서 함께 사용하는 편집 의미를 다음 action
타입으로 반환한다.

```swift
enum MathResultSuggestionAction: Equatable {
    case confirmOriginal
    case insertResult(String)
    case replaceExpression(deleteCount: Int, insertText: String)
    case replaceSelection(String)
}
```

```swift
func mathResultAction(
    at index: Int,
    hasSelectedText: Bool
) -> MathResultSuggestionAction?
```

- 왼쪽 원문 후보는 selection 여부와 무관하게 `.confirmOriginal`이다.
- 가운데 결과 삽입 후보는 selection이 없으면 `.insertResult(result)`,
  selection이 있으면 `.replaceSelection(displayText)`다.
- 오른쪽 결과 대치 후보는 selection이 없으면
  `.replaceExpression(deleteCount:expressionLength, insertText:result)`,
  selection이 있으면 `.replaceSelection(result)`다.
- 수식 모드가 아니거나 index/source가 맞지 않으면 `nil`이다.

`BaseKeyboardViewController`는 수식 action을 일반 선택 후보보다 먼저 처리한다.
`.replaceSelection`은 `UITextDocumentProxy.insertText`가 선택 영역을 교체하는
동작을 사용하고, 기존 선택 후보 처리와 같은 방식으로 deleted/inserted text를
undo/redo에 기록한 뒤 삽입 문자열을 `inputBuffer`에 append한다. 후보 탭은
`suggestionDidApply()`와 후보 갱신까지 수행하고, 스페이스는 selection 교체 후
기존 `insertSpaceText()` 흐름을 이어간다.

`UITextDocumentProxy.setMarkedText(_:selectedRange:)`는 사용하지 않는다. 이 API는
조합 중이거나 아직 확정되지 않은 text를 marked 상태로 유지하면서 후속 입력으로
수정한 뒤 `unmarkText()`로 확정하는 용도다. 후보 탭과 스페이스는 사용자가
확정한 편집이므로 `insertText`로 즉시 commit하는 것이 맞고, 불필요한 marked
highlight와 host별 composition 상태를 만들지 않는다.

일반 단일 단어 선택과 공백이 포함된 비수식 선택 텍스트의 기존 자동완성 정책은
변경하지 않는다.

## 수식 공백 검증

연산자와 괄호 주변 공백은 계속 허용한다.

```text
3 - 1 =
1,000 / 4=
( 3 + 2 ) * 2 =
```

숫자를 구성할 수 있는 문자(`0...9`, `.`, `,`) 사이에 하나 이상의 공백이 있으면
서로 다른 피연산자로 간주하고 수식 후보를 만들지 않는다.

```text
1 2+3=
1 . 2+3=
1, 000+2=
memo 2 3+1=
```

검사는 parser가 공백을 제거하기 전에 한 번 수행한다. 이전 비공백 문자와 다음
비공백 문자가 모두 숫자 구성 문자인 공백 구간을 발견하면 evaluation을
중단한다. 검증을 통과한 수식만 기존 방식으로 공백과 연산자 별칭을 정규화한다.

## 변경 범위

- Modify:
  `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`
  - `MathResultSuggestionAction`과 `mathResultAction(at:hasSelectedText:)` 계약을
    정의한다.
- Modify:
  `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - 현재 수식 item과 selection 여부를 공통 action으로 변환한다.
- Modify:
  `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - 수식 action을 일반 선택 후보보다 먼저 처리한다.
  - 탭과 스페이스가 같은 action 적용 경로를 사용한다.
  - 선택 영역 교체를 정확한 undo/redo와 `inputBuffer`에 반영한다.
- Modify:
  `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift`
  - 숫자 구성 문자 사이 공백을 parser 정규화 전에 거부한다.
- Modify:
  `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift`
  - 숫자 사이 공백 거부와 연산자 주변 공백 허용을 검증한다.
- Modify:
  `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift`
  - selection 유무에 따른 좌·중·우 action 의미를 검증한다.
- Base controller는 controller에서 검증된 action만 실행한다. 테스트를 위해
  `UITextDocumentProxy` mock이나 DEBUG 전용 production API는 추가하지 않는다.
- Fix:
  `SYKeyboardAssets/Sources/SYKeyboardAssets/Utils/Extensions/UIColor+Extension.swift`
  - 최종 리뷰에서 지적된 trailing whitespace를 제거한다.

## TDD와 검증

1. selection 유무별 수식 action 테스트와 숫자 공백 evaluator 테스트를 먼저
   추가한다.
2. 현재 구현에서 두 테스트가 요구한 이유로 실패하는 RED를 확인한다.
3. 각 root cause를 독립적으로 수정하고 관련 suite를 GREEN으로 만든다.
4. 수식 후보, 선택 policy, preview/터치와 undo/redo 관련 회귀 suite를 실행한다.
5. iPhone 13 mini / iOS 16.0 전체 테스트와 한글·영문 키보드 확장 빌드를
   실행한다.
6. `git diff --check b5822448..HEAD`로 전체 branch whitespace를 확인한다.

## 완료 기준

- 선택된 `3+1=`은 기존 좌·중·우 수식 후보를 표시한다.
- 선택 상태의 왼쪽 후보는 원문 유지, 가운데는 `3+1=4`, 오른쪽은 `4`로
  선택 영역을 교체한다.
- 선택 상태의 스페이스는 가운데 후보를 적용해 `3+1=4 `를 만든다.
- 선택되지 않은 `3+1=`은 기존 수식 후보를 표시하고 좌·중·우 의미를 유지한다.
- `1 2+3=`, `1 . 2+3=`, `1, 000+2=`, `memo 2 3+1=`은 후보를 만들지 않는다.
- `3 - 1 =`, `1,000 / 4=` 등 토큰 경계 공백은 기존처럼 계산한다.
- 전체 테스트, 두 확장 빌드와 merge-base 기준 whitespace 검사가 통과한다.

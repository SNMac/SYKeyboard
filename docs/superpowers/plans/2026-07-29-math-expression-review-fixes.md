# 수식 자동완성 최종 리뷰 수정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 선택된 수식의 좌·중·우 후보와 스페이스가 표시 의미대로 selection을 편집하고, 숫자 사이 공백이 서로 다른 숫자를 결합 계산하지 않게 한다.

**Architecture:** `SuggestionController`가 selection 여부를 포함한 `MathResultSuggestionAction`을 생성하고 `BaseKeyboardViewController`의 탭·스페이스가 동일한 action 적용 경로를 사용한다. `MathExpressionCompletionEvaluator`는 parser가 공백을 제거하기 전에 숫자 구성 문자 사이 공백을 거부한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26+, iOS 16+

## Global Constraints

- 선택된 `3+1=`에도 기존 좌·중·우 수식 후보를 표시한다.
- 왼쪽은 원문 유지, 가운데는 selection을 `3+1=4`, 오른쪽은 `4`로 교체한다.
- 선택 상태의 스페이스는 가운데 후보를 적용한 뒤 공백을 입력해 `3+1=4 `를 만든다.
- 선택되지 않은 수식의 기존 삽입·대치 의미를 변경하지 않는다.
- 확정 편집에는 `UITextDocumentProxy.insertText`를 사용하고 `setMarkedText`를 사용하지 않는다.
- `3 - 1 =`, `1,000 / 4=`처럼 연산자 주변 공백은 계속 허용한다.
- `1 2+3=`, `1 . 2+3=`, `1, 000+2=`, `memo 2 3+1=`은 후보를 만들지 않는다.
- 일반 자동완성, 텍스트 대치, 스크롤 롤백과 키보드 입력 흐름을 변경하지 않는다.
- iOS 16 최소 runtime과 기존 외부 의존성을 변경하지 않는다.
- 현재 브랜치 `feat/#98-math-calculation-auto-complete`에서 작업한다.

---

## File Structure

- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`
  - 수식 후보가 수행할 공통 편집 action과 service 계약을 정의한다.
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - 후보 source와 selection 여부를 action으로 변환한다.
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - 후보 탭·스페이스의 action 적용과 selection 교체를 담당한다.
- Modify: `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift`
  - selection 유무별 좌·중·우 action을 검증한다.
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift`
  - 숫자 구성 문자 사이 공백을 parser 정규화 전에 거부한다.
- Modify: `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift`
  - 잘못된 숫자 공백과 허용되는 토큰 경계 공백을 검증한다.
- Modify: `SYKeyboardAssets/Sources/SYKeyboardAssets/Utils/Extensions/UIColor+Extension.swift`
  - 최종 리뷰의 trailing whitespace를 제거한다.
- Modify: `docs/superpowers/plans/2026-07-29-math-expression-review-fixes.md`
  - RED/GREEN과 전체 회귀 결과를 단계별로 기록한다.

---

### Task 1: Selection-aware 수식 후보 action

**Files:**
- Modify: `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift:12-111`
- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift:1-180`
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift:330-390`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:1239-1260,1325-1360,2135-2225`
- Modify: `docs/superpowers/plans/2026-07-29-math-expression-review-fixes.md`

**Interfaces:**
- Produces: `MathResultSuggestionAction`
- Produces: `SuggestionService.mathResultAction(at:hasSelectedText:)`
- Consumes: `UITextDocumentProxy.selectedText`, 기존 `insertText`, `replaceText`

- [x] **Step 1: selection 유무별 수식 action 테스트를 작성**

기존 가운데·오른쪽·왼쪽 테스트를 공통 action 계약으로 변경하고 선택 상태
테스트를 추가한다.

```swift
@Test("선택되지 않은 가운데 후보는 결과값 삽입 action")
func test선택되지않은가운데후보는_결과값삽입Action() {
    let controller = makeMathController(expression: "3-1=")

    #expect(
        controller.mathResultAction(
            at: 1,
            hasSelectedText: false
        ) == .insertResult("2")
    )
}

@Test("선택되지 않은 오른쪽 후보는 수식 전체 대치 action")
func test선택되지않은오른쪽후보는_수식전체대치Action() {
    let controller = makeMathController(expression: "1 + 2 =")

    #expect(
        controller.mathResultAction(
            at: 2,
            hasSelectedText: false
        ) == .replaceExpression(deleteCount: 7, insertText: "3")
    )
}

@Test("선택된 가운데 후보는 원문과 결과로 selection 교체")
func test선택된가운데후보는_원문과결과로Selection교체() {
    let controller = makeMathController(expression: "3-1=")

    #expect(
        controller.mathResultAction(
            at: 1,
            hasSelectedText: true
        ) == .replaceSelection("3-1=2")
    )
}

@Test("선택된 오른쪽 후보는 결과값으로 selection 교체")
func test선택된오른쪽후보는_결과값으로Selection교체() {
    let controller = makeMathController(expression: "3-1=")

    #expect(
        controller.mathResultAction(
            at: 2,
            hasSelectedText: true
        ) == .replaceSelection("2")
    )
}

@Test("왼쪽 후보는 selection 여부와 무관하게 원문 확정")
func test왼쪽후보는_Selection여부와무관하게원문확정() {
    let controller = makeMathController(expression: "3-1=")

    #expect(
        controller.mathResultAction(
            at: 0,
            hasSelectedText: false
        ) == .confirmOriginal
    )
    #expect(
        controller.mathResultAction(
            at: 0,
            hasSelectedText: true
        ) == .confirmOriginal
    )
}
```

같은 suite에 controller 생성 helper를 추가한다.

```swift
private func makeMathController(expression: String) -> SuggestionController {
    let controller = SuggestionController()
    controller.isPredictiveTextEnabled = true
    controller.isShowMathResultsEnabled = true
    controller.updateSuggestions(for: expression)
    return controller
}
```

- [x] **Step 2: 집중 테스트를 실행해 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests
```

Expected: `MathResultSuggestionAction`과 `mathResultAction`이 없어 compile RED가
발생한다. 오류가 새 계약의 부재 때문인지 확인하고 실제 결과를 기록한다.

결과 (2026-07-29): 위 명령은 exit 65으로 실패했다. `SuggestionController`에
`mathResultAction` 멤버가 없다는 컴파일 오류가 8건 발생했으며, 테스트 실행 전
빌드가 중단되었다 (`Testing cancelled because the build failed`, build command 3건 실패).

- [x] **Step 3: RED 테스트와 결과를 커밋**

```sh
git add \
  SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift \
  docs/superpowers/plans/2026-07-29-math-expression-review-fixes.md
git commit -m "test: #98 - 선택 수식 후보 action 계약 추가"
```

결과 (2026-07-29): `61adc2d` (`test: #98 - 선택 수식 후보 action 계약 추가`)에
RED 테스트와 Step 1~2 결과를 기록했다.

- [x] **Step 4: 공통 action과 service API 구현**

`SuggestionService.swift`에 다음 타입을 추가한다.

```swift
enum MathResultSuggestionAction: Equatable {
    case confirmOriginal
    case insertResult(String)
    case replaceExpression(deleteCount: Int, insertText: String)
    case replaceSelection(String)
}
```

protocol의 기존 수식 후보별 세 조회 메서드를 다음 하나로 교체한다.

```swift
func mathResultAction(
    at index: Int,
    hasSelectedText: Bool
) -> MathResultSuggestionAction?
```

`SuggestionController`는 source별로 다음 action을 반환한다.

```swift
func mathResultAction(
    at index: Int,
    hasSelectedText: Bool
) -> MathResultSuggestionAction? {
    guard currentMode == .mathExpression,
          index >= 0,
          index < currentSuggestions.count else { return nil }

    let item = currentSuggestions[index]

    switch item.source {
    case .mathExpressionOriginal:
        return .confirmOriginal
    case .mathExpressionInsertion:
        guard let insertText = item.insertText else { return nil }
        return hasSelectedText
            ? .replaceSelection(item.text)
            : .insertResult(insertText)
    case .mathExpressionReplacement:
        guard let insertText = item.insertText,
              let deleteCount = item.replacementDeleteCount else { return nil }
        return hasSelectedText
            ? .replaceSelection(insertText)
            : .replaceExpression(
                deleteCount: deleteCount,
                insertText: insertText
            )
    default:
        return nil
    }
}
```

- [x] **Step 5: Base controller에서 탭·스페이스가 action을 공유하도록 구현**

preview는 index 1 action 존재 여부로 가운데를 강조한다.

```swift
let hasSelectedText = textDocumentProxy.selectedText?.isEmpty == false
if suggestionController.mathResultAction(
    at: 1,
    hasSelectedText: hasSelectedText
) != nil {
    suggestionBarView.updatePreviewHighlight(index: 1)
    return
}
```

수식 action 적용 helper를 추가한다.

```swift
@discardableResult
func applyMathResultSuggestionAction(
    _ action: MathResultSuggestionAction
) -> Bool {
    switch action {
    case .confirmOriginal:
        suggestionController.clearSuggestions()
    case .insertResult(let text):
        insertText(text)
    case .replaceExpression(let deleteCount, let insertText):
        replaceText(deleteCount: deleteCount, insert: insertText)
    case .replaceSelection(let text):
        guard let selectedText = textDocumentProxy.selectedText,
              !selectedText.isEmpty else { return false }
        replaceSelectedText(selectedText, with: text)
    }
    return true
}
```

선택 교체 helper는 일반 선택 후보와 수식 action이 함께 사용한다.

```swift
func replaceSelectedText(_ selectedText: String, with insertText: String) {
    recordUndoRedoChange(
        deletedText: selectedText,
        insertedText: insertText
    )
    textDocumentProxy.insertText(insertText)
    inputBuffer.append(insertText)
}
```

`suggestionBar(_:didSelectSuggestionAt:)`는 수식을 먼저 처리한다.

```swift
if handleMathResultSuggestion(at: index) { return }
if handleSelectedTextSuggestion(at: index) { return }
```

`handleMathResultSuggestion`은 selection 여부로 action을 얻고 적용한다. 원문 외
action은 기존처럼 `suggestionDidApply()`와 `updateSuggestions()`를 호출한다.

스페이스는 index 1 action을 적용한 경우 텍스트 대치를 건너뛰고, 이후 기존
`insertSpaceText()`를 호출한다. action 적용에 실패하면 기존 텍스트 대치 경로로
fallback한다.

- [x] **Step 6: 관련 suite를 실행해 GREEN 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests
```

Expected: 새 action 계약, 기존 preview와 undo/redo suite가 모두 통과한다. 실제
passed/failed/skipped 수를 기록한다.

결과 (2026-07-29): 위 명령은 iPhone 13 mini (iOS 16.0)에서 exit 0으로
`TEST SUCCEEDED`를 반환했다. `xcresulttool` 요약 기준 38 passed, 0 failed,
0 skipped (총 38)이다.

- [x] **Step 7: 구현과 GREEN 결과를 커밋**

```sh
git add \
  Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift \
  Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-07-29-math-expression-review-fixes.md
git commit -m "fix: #98 - 선택 수식 후보 편집 의미 일치"
```

결과 (2026-07-29): 선택 상태별 action 적용과 GREEN 검증 기록을 요청한 커밋
메시지로 커밋했다.

#### Fix Round 1 (2026-07-29): 선택 수식 후보의 undo target context

선택 영역 교체 helper가 `UITextDocumentProxy.insertText`보다 먼저 undo 변경을
기록해 선택 전 문맥을 target으로 저장하던 문제를 수정했다. proxy 삽입과
`inputBuffer` 동기화 뒤에 undo 변경을 기록해, 선택된 가운데(`3+1=4`)·오른쪽(`4`)
수식 후보 탭의 undo가 치환 결과 문맥에서 시작한다.

`KeyboardUndoRedoManagerTests`에 선택 전 문맥에서는 undo를 적용할 수 없고, 두 후보
결과 문맥에서는 undo/redo 적용과 편집 내용이 일치함을 검증하는 deterministic
regression test를 추가했다. `UITextDocumentProxy` mock이나 DEBUG 전용 production API는
추가하지 않았으므로 Base controller의 실제 proxy 호출 순서를 단위 테스트로 직접
관찰할 수는 없다.

검증 (2026-07-29):

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests
```

위 명령은 iPhone 13 mini (iOS 16.0)에서 exit 0으로 완료했고, `xcresulttool`
요약은 40 passed, 0 failed, 0 skipped (총 40)를 보고했다.

---

### Task 2: 숫자 구성 문자 사이 공백 거부

**Files:**
- Modify: `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift:15-180`
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift:14-130`
- Modify: `docs/superpowers/plans/2026-07-29-math-expression-review-fixes.md`

**Interfaces:**
- Consumes: `MathExpressionCompletionEvaluator.completion(for:)`
- Produces: parser 정규화 전 숫자 공백 validation

- [x] **Step 1: 잘못된 숫자 공백 회귀 테스트 작성**

```swift
@Test("숫자 구성 문자 사이 공백은 서로 다른 숫자로 보고 거부")
func test숫자구성문자사이공백은_서로다른숫자로보고거부() {
    for expression in [
        "1 2+3=",
        "1 . 2+3=",
        "1, 000+2=",
        "memo 2 3+1="
    ] {
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: expression
            ) == nil
        )
    }
}
```

기존 공백 허용 테스트에 괄호 공백을 추가한다.

```swift
#expect(
    MathExpressionCompletionEvaluator.completion(
        for: "( 3 + 2 ) * 2 ="
    )?.insertText == "10"
)
```

- [x] **Step 2: evaluator 집중 테스트로 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests
```

Expected: 신규 숫자 공백 case는 현재 parser가 공백을 제거하므로 실패하고, 기존과
신규 토큰 경계 공백 case는 통과한다.

결과 (2026-07-29): 위 명령은 exit 65으로 실패했다. 신규
`test숫자구성문자사이공백은_서로다른숫자로보고거부`만 4개 입력마다 실패했고,
기존 evaluator 테스트와 `( 3 + 2 ) * 2 =` 토큰 경계 공백 검증은 통과했다.

- [x] **Step 3: RED 테스트와 결과를 커밋**

```sh
git add \
  SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift \
  docs/superpowers/plans/2026-07-29-math-expression-review-fixes.md
git commit -m "test: #98 - 수식 숫자 사이 공백 거부 계약 추가"
```

결과 (2026-07-29): `test: #98 - 수식 숫자 사이 공백 거부 계약 추가` 커밋에 RED
테스트와 Step 1~2 결과를 기록했다.

- [x] **Step 4: parser 정규화 전 숫자 공백 검증 구현**

`completion(for:)`에서 parser를 만들기 전에 다음 guard를 추가한다.

```swift
guard !containsWhitespaceBetweenNumberComponents(expressionBody) else {
    return nil
}
```

private helper는 공백 구간의 이전·다음 비공백 문자를 비교한다.

```swift
static func containsWhitespaceBetweenNumberComponents(
    _ expression: String
) -> Bool {
    var previousNonWhitespace: Character?
    var hasWhitespaceAfterPrevious = false

    for character in expression {
        if character.isWhitespace {
            if previousNonWhitespace != nil {
                hasWhitespaceAfterPrevious = true
            }
            continue
        }

        if hasWhitespaceAfterPrevious,
           let previousNonWhitespace,
           isNumberComponent(previousNonWhitespace),
           isNumberComponent(character) {
            return true
        }

        previousNonWhitespace = character
        hasWhitespaceAfterPrevious = false
    }

    return false
}

static func isNumberComponent(_ character: Character) -> Bool {
    return character.isNumber || character == "." || character == ","
}
```

결과 (2026-07-29): `completion(for:)`가 parser 생성 전에 숫자 구성 문자 사이의
공백 구간을 거부하도록 구현했다. 연산자와 괄호는 숫자 구성 문자에 포함하지 않는다.

- [x] **Step 5: evaluator와 controller 수식 suite GREEN 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests
```

Expected: 숫자 공백 거부, 토큰 경계 공백 허용과 수식 action suite가 모두
통과한다.

결과 (2026-07-29): 위 명령은 exit 0 (`** TEST SUCCEEDED **`)으로 통과했다.
`MathExpressionCompletionEvaluatorTests` 17개와
`SuggestionControllerMathResultsTests` 9개가 모두 통과했다.

- [x] **Step 6: 구현과 GREEN 결과 커밋**

```sh
git add \
  Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift \
  docs/superpowers/plans/2026-07-29-math-expression-review-fixes.md
git commit -m "fix: #98 - 수식 숫자 사이 공백 결합 방지"
```

결과 (2026-07-29): `fix: #98 - 수식 숫자 사이 공백 결합 방지` 커밋에 구현과
Step 4~5 GREEN 결과를 기록했다.

**Fix Round 1 결과 (2026-07-29):** suffix 추출의 허용 판정도
`Character.isWhitespace`를 사용하도록 수정해 TAB과 NBSP가 숫자 구성 문자 사이에
있어도 validation 전에 suffix가 잘리지 않게 했다. TAB/NBSP 거부 회귀 테스트와
기존 evaluator·controller 수식 suite를 iPhone 13 mini / iOS 16.0에서 재실행해
exit 0으로 통과했다.

---

### Task 3: Whitespace 정리와 전체 회귀

**Files:**
- Modify: `SYKeyboardAssets/Sources/SYKeyboardAssets/Utils/Extensions/UIColor+Extension.swift:73`
- Modify: `docs/superpowers/plans/2026-07-29-math-expression-review-fixes.md`

**Interfaces:**
- Consumes: Task 1의 selection-aware action, Task 2의 숫자 공백 validation
- Produces: 전체 branch 검증 증거와 clean whitespace

- [x] **Step 1: 기존 trailing whitespace 제거**

`UIColor+Extension.swift:73`의 빈 줄에서 공백만 제거하고 별도 커밋한다.

```sh
git add SYKeyboardAssets/Sources/SYKeyboardAssets/Utils/Extensions/UIColor+Extension.swift
git commit -m "chore: #98 - UIColor 확장 trailing whitespace 정리"
```

결과 (2026-07-29): `UIColor+Extension.swift:73`의 빈 줄 공백만 제거했고, `ffb387d` (`chore: #98 - UIColor 확장 trailing whitespace 정리`)로 별도 커밋했다.

- [x] **Step 2: 집중 회귀 suite 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests
```

Expected: 모든 집중 회귀 테스트가 실패 없이 통과한다.

결과 (2026-07-29): 기본 샌드박스에서는 CoreSimulator 연결과 Xcode 캐시 권한 오류로 시작하지 못해 권한 있는 환경에서 재실행했다. iPhone 13 mini / iOS 16.0에서 `TEST SUCCEEDED`; xcresult 집계는 passed 72, failed 0, skipped 0, expected failures 0이다.

- [x] **Step 3: iOS 16 전체 테스트 실행**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 전체 테스트가 실패 없이 끝난다. passed/failed/skipped 수를 기록한다.

결과 (2026-07-29): 권한 있는 환경에서 iPhone 13 mini / iOS 16.0 전체 suite가 `TEST SUCCEEDED`; xcresult 집계는 passed 358, failed 0, skipped 0, expected failures 0이다.

- [x] **Step 4: 한글·영문 확장 빌드**

Run:

```sh
xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 두 확장 모두 성공한다. warning과 오류 수를 기록한다.

결과 (2026-07-29): 권한 있는 환경에서 두 build가 `BUILD SUCCEEDED`로 끝났다. HangeulKeyboard는 warning 29건, error 0건(외부 Meta/FBAudienceNetwork PCM 경로 누락 및 AppIntents metadata extraction skip); EnglishKeyboard는 warning 0건, error 0건이다.

- [x] **Step 5: 전체 branch whitespace와 scope 확인**

Run:

```sh
git diff --check b5822448..HEAD
git status --short
rg -n "setMarkedText" \
  Modules/SYKeyboardCore/Domain \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
```

Expected: merge-base 기준 whitespace 오류와 working tree 변경이 없다.
`setMarkedText` 검색 결과가 없다.

결과 (2026-07-29): `git diff --check b5822448..HEAD`, `git status --short`, 지정 경로의 `setMarkedText` 검색 모두 출력 없이 성공했다. 문서 기록 전 working tree는 clean이었다.

- [x] **Step 6: 검증 결과를 기록하고 문서 커밋**

```sh
git add docs/superpowers/plans/2026-07-29-math-expression-review-fixes.md
git commit -m "docs: #98 - 수식 자동완성 최종 리뷰 수정 검증"
```

---

## Completion Criteria

- selection 유무별 좌·중·우 `MathResultSuggestionAction`이 테스트로 고정된다.
- 선택 수식의 탭·스페이스는 표시 의미와 같은 확정 편집을 수행한다.
- `setMarkedText`를 사용하지 않고 `insertText`로 selection을 교체한다.
- 숫자 구성 문자 사이 공백은 거부하고 연산자·괄호 주변 공백은 허용한다.
- 집중·전체 테스트와 두 확장 빌드가 통과한다.
- `git diff --check b5822448..HEAD`가 통과한다.

---

## Final Review Fix (2026-07-29)

최종 리뷰에서 `memo3+1=` selection의 수식 suffix 후보가 selection 전체를
`3+1=4` 또는 `4`로 교체해 `memo` prefix를 잃는 문제를 수정했다.
`mathResultAction`은 실제 `selectedText: String?`를 받고, 현재 completion 및
`lastSuggestionBaseText`와 일치하는 selection만 처리한다. 가운데 action은
`memo3+1=4`, 오른쪽 action은 `memo4`로 prefix를 보존하며, stale/mismatched
selection에는 action을 반환하지 않는다. preview·space·tap 호출부가 모두 같은
selection-aware API를 사용한다.

TDD RED:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests
```

기존 `hasSelectedText: Bool` API에서 새 `selectedText: String?` 호출이 컴파일되지
않아 의도한 RED를 확인했다. 구현 후 단일 suite는 12 passed, 0 failed,
0 skipped로 GREEN이 됐다.

iPhone 13 mini / iOS 16.0 집중 회귀:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292' \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests \
  -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests
```

결과: `TEST SUCCEEDED`; xcresult 기준 75 passed, 0 failed, 0 skipped.

iPhone 13 mini / iOS 16.0 전체 회귀:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=CBD992D3-5364-4F69-AC5F-0077ADF1A292'
```

기본 샌드박스 실행은 CoreSimulator 및 SwiftPM/clang cache 권한 오류로 exit 74가
발생했다. 권한 있는 환경에서 같은 명령을 재실행한 결과 `TEST SUCCEEDED`;
xcresult 기준 361 passed, 0 failed, 0 skipped였다.

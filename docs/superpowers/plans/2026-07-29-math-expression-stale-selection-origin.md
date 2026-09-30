# 수식 후보 stale selection origin 방지 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** selection에서 생성된 수식 후보가 선택 해제 또는 커서 이동 뒤 새 위치를 편집하지 못하도록 후보 생성 origin과 현재 selection의 일치를 강제한다.

**Architecture:** 후보 갱신 시점의 `selectedText` snapshot을 `SuggestionController`에 전달하고, 표시 중인 수식 후보에 private origin 상태를 저장한다. `mathResultAction(at:selectedText:)`은 source별 action을 만들기 전에 저장된 origin과 현재 selection을 검증하며, preview·후보 탭·스페이스는 기존 공통 action 계약을 그대로 사용한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 16+, iOS 16+

## Global Constraints

- 현재 브랜치 `feat/#98-math-calculation-auto-complete`와 현재 worktree에서만 작업한다.
- 새 브랜치와 새 worktree를 만들지 않고 push하지 않는다.
- selection-origin 후보는 현재 `selectedText`가 생성 당시 selection과 정확히 같을 때만 action을 반환한다.
- selection-origin 후보에서 현재 selection이 `nil`, 빈 문자열 또는 다른 문자열이면 좌·중·우 모든 수식 action을 `nil`로 반환한다.
- unselected-origin 후보는 현재 selection이 없을 때 기존 `.insertResult`와 `.replaceExpression` 동작을 유지한다.
- exact selection `3+1=`과 prefix selection `memo3+1=`의 기존 좌·중·우 결과를 유지한다.
- preview, 후보 탭, 스페이스는 동일한 `mathResultAction(at:selectedText:)` 계약을 사용한다.
- `UITextDocumentProxy` mock과 DEBUG 전용 production API를 추가하지 않는다.
- 확정 대치는 `UITextDocumentProxy.insertText`를 사용하고 `setMarkedText`를 사용하지 않는다.
- 일반 자동완성, 텍스트 대치, undo/redo, `inputBuffer`, 후보 스크롤 롤백을 변경하지 않는다.
- 기존 SDD workspace `.superpowers/sdd/2026-07-29-math-expression-review-fixes/`는 읽기 전용 참고 자료이며 수정하지 않는다.
- 모든 shell 명령은 `rtk`를 prefix로 사용한다.

---

## File Structure

- Modify: `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift`
  - selection-origin stale action, exact/prefix 보존, unselected 보존, update/clear 초기화를 실제 action 결과로 검증한다.
- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`
  - 후보 생성 시점의 selection snapshot을 받는 update 계약과 selection 없는 convenience를 정의한다.
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - 수식 후보 origin을 저장하고 action 시점에 검증하며 update/clear 수명에 맞춰 초기화한다.
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - 동일한 `selectedText` snapshot을 selection policy와 suggestion service에 전달한다.
- Modify: `docs/superpowers/plans/2026-07-29-math-expression-stale-selection-origin.md`
  - 각 Task의 실제 RED/GREEN/검증 결과와 테스트 개수를 즉시 기록한다.

---

### Task 1: stale selection RED 계약

**Files:**
- Modify: `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift:30-207`
- Modify: `docs/superpowers/plans/2026-07-29-math-expression-stale-selection-origin.md`

**Interfaces:**
- Consumes: 현재 `SuggestionController.mathResultAction(at:selectedText:)`
- Produces: `SuggestionController.updateSuggestions(for:selectedText:)`을 요구하는 실패 테스트
- Produces: selection-origin과 unselected-origin의 action 기대값

- [x] **Step 1: 필수 stale-selection 테스트를 먼저 추가하고 RED를 확인한 뒤 결과를 커밋**

기존 helper를 selection snapshot을 받도록 변경한다.

```swift
private func makeMathController(
    expression: String,
    selectedText: String? = nil
) -> SuggestionController {
    let controller = SuggestionController()
    controller.isPredictiveTextEnabled = true
    controller.isShowMathResultsEnabled = true
    controller.updateSuggestions(
        for: expression,
        selectedText: selectedText
    )
    return controller
}
```

기존 selection action 테스트는 생성 당시 selection을 명시한다.

```swift
let controller = makeMathController(
    expression: "3-1=",
    selectedText: "3-1="
)
```

prefix 테스트도 동일하게 생성 당시 문자열을 명시한다.

```swift
let controller = makeMathController(
    expression: "memo3+1=",
    selectedText: "memo3+1="
)
```

다음 테스트를 추가한다.

```swift
@Test("selection-origin 후보는 선택 해제 후 모든 action 차단")
func testSelectionOrigin후보는_선택해제후_모든Action차단() {
    let controller = makeMathController(
        expression: "3+1=",
        selectedText: "3+1="
    )

    for index in 0...2 {
        #expect(
            controller.mathResultAction(
                at: index,
                selectedText: nil
            ) == nil
        )
    }
}

@Test("selection-origin 후보는 빈 selection에서 모든 action 차단")
func testSelectionOrigin후보는_빈Selection에서_모든Action차단() {
    let controller = makeMathController(
        expression: "3+1=",
        selectedText: "3+1="
    )

    for index in 0...2 {
        #expect(
            controller.mathResultAction(
                at: index,
                selectedText: ""
            ) == nil
        )
    }
}

@Test("selection-origin prefix 후보는 다른 selection에서 모든 action 차단")
func testSelectionOriginPrefix후보는_다른Selection에서_모든Action차단() {
    let controller = makeMathController(
        expression: "memo3+1=",
        selectedText: "memo3+1="
    )

    for index in 0...2 {
        #expect(
            controller.mathResultAction(
                at: index,
                selectedText: "note3+1="
            ) == nil
        )
    }
}

@Test("unselected-origin 후보는 selection이 없으면 기존 action 유지")
func testUnselectedOrigin후보는_Selection이없으면_기존Action유지() {
    let controller = makeMathController(expression: "3+1=")

    #expect(
        controller.mathResultAction(
            at: 1,
            selectedText: nil
        ) == .insertResult("4")
    )
    #expect(
        controller.mathResultAction(
            at: 2,
            selectedText: nil
        ) == .replaceExpression(deleteCount: 4, insertText: "4")
    )
}

@Test("unselected-origin 후보는 새 selection이 생기면 모든 action 차단")
func testUnselectedOrigin후보는_새Selection이생기면_모든Action차단() {
    let controller = makeMathController(expression: "3+1=")

    for index in 0...2 {
        #expect(
            controller.mathResultAction(
                at: index,
                selectedText: "memo"
            ) == nil
        )
    }
}

@Test("후보 갱신은 이전 selection origin을 새 origin으로 교체")
func test후보갱신은_이전SelectionOrigin을_새Origin으로교체() {
    let controller = makeMathController(
        expression: "3+1=",
        selectedText: "3+1="
    )

    controller.updateSuggestions(
        for: "5+1=",
        selectedText: nil
    )

    #expect(
        controller.mathResultAction(
            at: 1,
            selectedText: nil
        ) == .insertResult("6")
    )
    #expect(
        controller.mathResultAction(
            at: 2,
            selectedText: nil
        ) == .replaceExpression(deleteCount: 4, insertText: "6")
    )
}

@Test("후보 clear는 selection origin과 수식 action을 초기화")
func test후보Clear는_SelectionOrigin과_수식Action을초기화() {
    let controller = makeMathController(
        expression: "3+1=",
        selectedText: "3+1="
    )

    controller.clearSuggestions()

    for index in 0...2 {
        #expect(
            controller.mathResultAction(
                at: index,
                selectedText: "3+1="
            ) == nil
        )
    }

    controller.updateSuggestions(
        for: "2+2=",
        selectedText: nil
    )
    #expect(
        controller.mathResultAction(
            at: 1,
            selectedText: nil
        ) == .insertResult("4")
    )
}
```

새 테스트가 잡는 production 결함은 다음과 같다.

- origin guard 제거 또는 `nil`/빈 문자열을 unselected로 오분류하면 첫 두 테스트가 실패한다.
- selection 문자열 exact 비교를 제거하면 prefix mismatch 테스트가 실패한다.
- unselected action 분기를 제거하면 unselected 보존 테스트가 실패한다.
- unselected 후보가 새 selection을 허용하면 새 selection 차단 테스트가 실패한다.
- update/clear에서 origin을 갱신하지 않으면 상태 수명 테스트가 실패한다.

RED 명령:

```sh
rtk xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests
```

Expected: `updateSuggestions(for:selectedText:)` 계약 부재로 compile RED가
발생하거나, 새 API를 test-only 임시 구현하지 않은 상태에서 stale selection
action 기대가 실패한다. 문법 오류나 fixture 오류가 아니라 production origin
계약 부재가 원인인지 확인한다.

실제 RED 명령, exit code, 핵심 오류를 이 Step 아래에 기록하고 체크한 뒤 다음
범위만 커밋한다.

```sh
rtk git add \
  SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift \
  docs/superpowers/plans/2026-07-29-math-expression-stale-selection-origin.md
rtk git commit -m "test: #98 - stale selection 수식 action 계약 추가"
```

#### Step 1 결과 (2026-07-29)

- `SuggestionControllerMathResultsTests`에 selection-origin stale action 7개를 추가했고,
  기존 selection 및 prefix action 테스트는 후보 생성 당시의 `selectedText` snapshot을
  명시하도록 갱신했다. Fix Round 1에서 정확한 `3+1=` selection-origin의 좌·중·우
  success action도 추가했다. 이 suite에는 총 20개의 `@Test`가 선언되어 있다.
- sandbox 실행은 Simulator/SwiftPM cache 접근 제한으로 exit code 74에서 중단되어
  컴파일 계약을 확인하지 못했다. 권한 있는 환경에서 아래 RED 명령을 재실행했다.

  ```sh
  rtk xcodebuild test \
    -project SYKeyboard.xcodeproj \
    -scheme SYKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
    -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests
  ```

  exit code는 65였다. `SuggestionControllerMathResultsTests.swift` 컴파일에서
  `Extra argument 'selectedText' in call`과 그에 따른 `'nil' requires a contextual type`가
  발생했다. 현재 production의 `SuggestionController.updateSuggestions(for:)`가
  `updateSuggestions(for:selectedText:)` 계약을 아직 제공하지 않기 때문이다. 따라서
  fixture 또는 Swift 문법 문제가 아닌, Task 2에서 구현할 origin-aware update API의
  의도된 production-contract RED다. production 파일 또는 test-only 임시 구현은 추가하지 않았다.

---

### Task 2: origin-aware 최소 구현

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift:85-100`
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift:90-220,307-345,376-422,666-739`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift:1727-1770`
- Modify: `docs/superpowers/plans/2026-07-29-math-expression-stale-selection-origin.md`

**Interfaces:**
- Consumes: Task 1의 `updateSuggestions(for:selectedText:)` RED 계약
- Produces: `SuggestionService.updateSuggestions(for:selectedText:)`
- Produces: selection이 없는 기존 호출용 `SuggestionService.updateSuggestions(for:)`
- Produces: private `MathSuggestionOrigin`
- Preserves: `MathResultSuggestionAction`과 `mathResultAction(at:selectedText:)`

- [x] **Step 1: origin 상태와 공통 update wiring을 최소 구현하고 집중 suite GREEN을 확인한 뒤 결과를 커밋**

`SuggestionService`의 update requirement를 다음으로 교체한다.

```swift
func updateSuggestions(
    for baseText: String,
    selectedText: String?
)
```

같은 파일에 selection 없는 기존 호출을 위한 convenience를 추가한다.

```swift
extension SuggestionService {
    func updateSuggestions(for baseText: String) {
        updateSuggestions(for: baseText, selectedText: nil)
    }
}
```

`SuggestionController`에 private origin을 추가한다.

```swift
private enum MathSuggestionOrigin: Equatable {
    case unselected
    case selection(String)

    init(selectedText: String?) {
        if let selectedText, !selectedText.isEmpty {
            self = .selection(selectedText)
        } else {
            self = .unselected
        }
    }
}
```

마지막 갱신과 현재 수식 후보의 origin을 분리해 저장한다.

```swift
private var lastSuggestionOrigin: MathSuggestionOrigin?
private var currentMathSuggestionOrigin: MathSuggestionOrigin?
```

update 진입점은 snapshot을 한 번 정규화해 저장하고 내부 갱신에 전달한다.

```swift
func updateSuggestions(
    for baseText: String,
    selectedText: String?
) {
    guard isPredictiveTextEnabled, !isSuspended else { return }
    let origin = MathSuggestionOrigin(selectedText: selectedText)
    lastSuggestionBaseText = baseText
    lastSuggestionOrigin = origin
    preparePredictiveEnginesIfNeeded()
    prepareLexiconEngineIfNeeded()
    performUpdateSuggestions(for: baseText, origin: origin)
}
```

`performUpdateSuggestions`는 origin을 받아 수식 후보 생성 성공 시에만 현재 수식
origin으로 저장한다.

```swift
func performUpdateSuggestions(
    for baseText: String,
    origin: MathSuggestionOrigin
) {
    if isShowMathResultsEnabled,
       let completion = MathExpressionCompletionEvaluator.completion(for: baseText) {
        currentMathCompletion = completion
        currentMathSuggestionOrigin = origin
        // 기존 수식 후보 생성과 delegate 호출 유지
        return
    }

    currentMathCompletion = nil
    currentMathSuggestionOrigin = nil
    // 기존 n-gram/typing 분기 유지
}
```

`updateSuggestionsAfterNGramSelection`은 `.unselected`를 마지막 origin으로
기록하고, n-gram 후보를 직접 설정하는 분기에서 현재 수식 상태를 제거한다.
수식 fallback에는 `.unselected`를 전달한다.

```swift
let origin = MathSuggestionOrigin.unselected
lastSuggestionBaseText = inputBuffer
lastSuggestionOrigin = origin
```

```swift
currentMathCompletion = nil
currentMathSuggestionOrigin = nil
```

```swift
performUpdateSuggestions(for: inputBuffer, origin: origin)
```

`clearSuggestions()`는 기존 상태와 함께 두 origin 상태를 제거한다.

```swift
lastSuggestionOrigin = nil
currentMathSuggestionOrigin = nil
```

지연된 n-gram load 재갱신은 마지막 base text와 origin이 모두 있을 때만 동일한
snapshot으로 재실행한다.

```swift
guard let lastSuggestionBaseText,
      let lastSuggestionOrigin else { return }
performUpdateSuggestions(
    for: lastSuggestionBaseText,
    origin: lastSuggestionOrigin
)
```

`mathResultAction`의 source switch 전에 origin을 검증한다.

```swift
guard let currentMathCompletion,
      let currentMathSuggestionOrigin else { return nil }

let selectedPrefix: String?
switch currentMathSuggestionOrigin {
case .unselected:
    guard selectedText?.isEmpty != false else { return nil }
    selectedPrefix = nil
case .selection(let originalSelection):
    guard selectedText == originalSelection,
          originalSelection == lastSuggestionBaseText,
          originalSelection.hasSuffix(currentMathCompletion.expressionText) else {
        return nil
    }
    selectedPrefix = String(
        originalSelection.dropLast(currentMathCompletion.expressionText.count)
    )
}
```

기존 source switch와 exact/prefix 결과 조합은 변경하지 않는다.

`BaseKeyboardViewController.updateSuggestions()`와
`updateSuggestionsForCursorContext()`는 각각 `selectedText`를 한 번 읽고 같은
snapshot을 policy와 service에 전달한다.

```swift
let selectedText = textDocumentProxy.selectedText
let action = KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
    isPredictiveTextEnabled: suggestionController.isPredictiveTextEnabled,
    selectedText: selectedText,
    inputBuffer: inputBuffer,
    documentContextBeforeInput: textDocumentProxy.documentContextBeforeInput
)
```

`.update` 분기:

```swift
suggestionController.updateSuggestions(
    for: text,
    selectedText: selectedText
)
```

preview, 후보 탭, 스페이스의 기존
`mathResultAction(at:selectedText:)` 호출과 action 적용 코드는 변경하지 않는다.

집중 GREEN 명령:

```sh
rtk xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests \
  -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests \
  -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests
```

Expected: 새 stale-selection 테스트와 기존 75개 집중 테스트가 모두 통과하고
새 테스트 수만큼 전체 집중 개수가 증가한다. xcresult summary의 passed,
failed, skipped 수를 기록한다.

실제 GREEN 명령, simulator, 테스트 수를 이 Step 아래에 기록하고 체크한 뒤 다음
범위만 커밋한다.

```sh
rtk git add \
  Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift \
  Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-07-29-math-expression-stale-selection-origin.md
rtk git commit -m "fix: #98 - 수식 후보 selection origin 보존"
```

#### Step 1 결과 (2026-07-29)

- `SuggestionService.updateSuggestions(for:selectedText:)`와 selection 없는 기존 호출용
  convenience를 추가했다. `SuggestionController`는 갱신 시점의 selection origin과
  현재 수식 후보 origin을 분리해 저장하고, action 생성 전에 현재 selection과 일치하는지
  검증한다. `BaseKeyboardViewController`의 두 갱신 경로는 `selectedText`를 한 번 읽어
  policy와 service에 같은 snapshot을 전달한다.
- Task 1에서 상속한 RED는 `SuggestionControllerMathResultsTests.swift` 컴파일의
  `Extra argument 'selectedText' in call`이며, production의 origin-aware update 계약
  부재를 확인한 exit code 65 결과였다.
- sandbox의 focused suite는 `CoreSimulatorService`와 SwiftPM/clang cache 접근 제한으로
  exit code 74에서 중단됐다. 권한 있는 환경에서 다음 명령을 동일하게 재실행했다.

  ```sh
  rtk xcodebuild test \
    -project SYKeyboard.xcodeproj \
    -scheme SYKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
    -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests \
    -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests \
    -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests \
    -only-testing:SYKeyboardTests/KeyboardUndoRedoManagerTests \
    -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests
  ```

- 실제 simulator는 `iPhone 13 mini / iOS 16.0 (arm64)`였고, xcresult summary는
  `passed 83`, `failed 0`, `skipped 0`, `expected failures 0`이었다.

---

### Task 3: 전체 회귀와 정적 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-07-29-math-expression-stale-selection-origin.md`

**Interfaces:**
- Consumes: Task 2의 origin-aware production 구현
- Produces: 전체 테스트·두 extension 빌드·정적 검사 증거

- [x] **Step 1: 전체 필수 검증을 실행하고 실제 결과를 기록한 뒤 검증 문서를 커밋**

iPhone 13 mini / iOS 16.0 전체 테스트:

```sh
rtk xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 기존 361개와 새 테스트가 모두 통과한다. xcresult summary에서
passed, failed, skipped, expected failures를 기록한다.

한글 키보드 extension:

```sh
rtk xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `BUILD SUCCEEDED`.

영문 키보드 extension:

```sh
rtk xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: `BUILD SUCCEEDED`.

현재 follow-up 범위 whitespace:

```sh
rtk git diff --check ecfecd5..HEAD
```

Expected: 출력 없이 exit 0.

기존 `hasSelectedText` API 잔존 여부:

```sh
rtk rg -n "hasSelectedText" Modules/SYKeyboardCore SYKeyboardTests
```

Expected: 출력 없음. 수식 action의 이전 Bool API가 남아 있지 않다.

production `setMarkedText` 부재:

```sh
rtk rg -n "setMarkedText" Modules Keyboards
```

Expected: 출력 없음.

변경 범위 확인:

```sh
rtk git status --short
rtk git diff --stat ecfecd5..HEAD
```

Expected: 계획에 명시한 production/test/plan 파일만 변경됐다. 기존 SDD
workspace, 일반 자동완성, 텍스트 대치, undo/redo, `inputBuffer`, 스크롤 구현은
변경되지 않았다.

모든 실제 명령, simulator, 테스트 수, 빌드 결과, 정적 검사 결과를 이 Step
아래에 기록하고 체크한 뒤 계획 문서만 커밋한다.

```sh
rtk git add \
  docs/superpowers/plans/2026-07-29-math-expression-stale-selection-origin.md
rtk git commit -m "docs: #98 - 수식 후보 selection origin 최종 검증"
```

#### Step 1 결과 (2026-07-30)

- 검증 대상 simulator는 `iPhone 13 mini / iOS 16.0` (`arm64`, device ID
  `CBD992D3-5364-4F69-AC5F-0077ADF1A292`)이다. 기본 sandbox의 Xcode 실행은
  CoreSimulator 연결 및 Xcode/SwiftPM cache 권한 제한으로 모두 exit code 74에서
  중단되어, 프로젝트 코드 결과와 분리하기 위해 같은 명령을 권한 있는 환경에서
  재실행했다.
- 전체 테스트:

  ```sh
  rtk xcodebuild test \
    -project SYKeyboard.xcodeproj \
    -scheme SYKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
  ```

  sandbox 실행은 exit code 74 (`CoreSimulatorService connection became invalid`,
  `ModuleCache`/`ManifestLoading` 권한 오류)였고, 권한 있는 재실행은 exit code 0으로
  완료했다. 생성된 결과 bundle과 summary 재추출 명령은 다음과 같다.

  ```sh
  rtk xcrun xcresulttool get test-results summary \
    --path '/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.07.30_12-08-43-+0900.xcresult'
  ```

  이 명령으로 다시 확인한 xcresult summary는 total/passed `369`, failed `0`,
  skipped `0`, expected failures `0`, result `Passed`다.
- 한글 키보드 extension:

  ```sh
  rtk xcodebuild build \
    -project SYKeyboard.xcodeproj \
    -scheme HangeulKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
  ```

  sandbox 실행은 동일한 CoreSimulator/cache 권한 문제로 exit code 74였고, 권한 있는
  재실행은 exit code 0 및 `** BUILD SUCCEEDED **`였다.
- 영문 키보드 extension:

  ```sh
  rtk xcodebuild build \
    -project SYKeyboard.xcodeproj \
    -scheme EnglishKeyboard \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
  ```

  sandbox 실행은 동일한 CoreSimulator/cache 권한 문제로 exit code 74였고, 권한 있는
  재실행은 exit code 0 및 `** BUILD SUCCEEDED **`였다.
- 정적 검사:

  ```sh
  rtk git diff --check ecfecd5..HEAD
  rtk rg -n "hasSelectedText" Modules/SYKeyboardCore SYKeyboardTests
  rtk rg -n "setMarkedText" Modules Keyboards
  rtk git status --short
  rtk git diff --stat ecfecd5..HEAD
  ```

  `git diff --check`은 출력 없이 exit code 0이었다. 두 `rg` 검색은 모두 출력 없이
  exit code 1(검색 결과 없음)로, 이전 Bool API 및 production `setMarkedText` 사용이
  남아 있지 않음을 확인했다. 결과 기록 전 `git status --short`는 출력이 없었고,
  `git diff --stat ecfecd5..HEAD`는 `SuggestionService.swift`, `SuggestionController.swift`,
  `BaseKeyboardViewController.swift`, `SuggestionControllerMathResultsTests.swift`, 이 계획
  파일의 5개만 표시했다(941 insertions, 28 deletions). 기존 SDD workspace, 일반
  자동완성, 텍스트 대치, undo/redo, `inputBuffer`, 스크롤 구현은 이 범위에 없다.

---

## SDD 리뷰와 완료 절차

각 Task마다 fresh implementer가 작업하고 다음 두 검토를 순서대로 수행한다.

1. Task 구현 리뷰: spec 준수와 코드/테스트 품질을 모두 판정한다.
2. Task 재리뷰: 첫 리뷰의 결론과 전체 Task diff를 fresh reviewer가 다시
   확인한다. Critical/Important finding이 있으면 동일 implementer가 수정하고
   scoped re-review를 수행한다.

Task 간에는 open Critical/Important finding을 남기지 않는다. Minor finding은
새 SDD ledger에 기록하고 최종 전체 리뷰에서 다시 판정한다.

모든 Task가 끝나면 `ecfecd5..HEAD` 전체 follow-up diff를 가장 강한 reviewer에게
전달해 별도 전체 리뷰를 수행한다. finding이 있으면 전체 finding을 한 번의
수정 wave로 처리하고 한 번의 scoped 재리뷰를 수행한다. Critical/Important
finding이 없는 상태에서만 완료로 보고한다.

새 SDD workspace:

```text
.superpowers/sdd/2026-07-29-math-expression-stale-selection-origin/
```

이 workspace만 사용하고 기존
`.superpowers/sdd/2026-07-29-math-expression-review-fixes/`는 수정하지 않는다.

# 수식 자동완성 머지 전 안정성 보강 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** appearance 전 document proxy trait 접근을 제거하고 수식 입력을 256자·괄호 16단계로 제한해 수식 자동완성 브랜치를 머지 가능한 상태로 만든다.

**Architecture:** `BaseKeyboardViewController`는 host의 수식 자동완성 허용 여부를 기존 autocorrection trait와 함께 text-change callback에서만 캐시하고, 표시 여부는 pure policy로 계산한다. `MathExpressionCompletionEvaluator`는 suffix 생성 전에 원본 길이를 제한하고 기존 recursive descent parser에 깊이 counter만 추가한다.

**Tech Stack:** Swift 5, UIKit, Foundation, Swift Testing, Xcode 26+

## Global Constraints

- 현재 `feat/#98-math-calculation-auto-complete` 브랜치에서 작업하고 새 worktree나 브랜치를 만들지 않는다.
- iOS 16+ 지원과 iOS 18+ `mathExpressionCompletionType` 동작을 유지한다.
- host input trait는 `textWillChange(_:)`와 `textDidChange(_:)`에서만 읽는다.
- 수식 원본 입력은 256자까지 허용하고 257자부터 거부한다.
- 괄호 중첩은 16단계까지 허용하고 17단계부터 거부한다.
- 입력을 마지막 256자로 자르지 않고 전체 요청을 거부한다.
- `.5+1=`, selection-origin 검증, 일반 자동완성, n-gram, 텍스트 대치와 한글·영문 입력 동작을 유지한다.
- 신규 의존성, parser 재작성과 테스트 전용 production API를 추가하지 않는다.
- 각 task의 코드·테스트·계획 결과를 하나의 커밋으로 남기고 push하지 않는다.

---

### Task 1: host 수식 자동완성 trait를 callback에서 캐시

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `docs/superpowers/plans/2026-08-12-math-expression-merge-readiness-hardening.md`

**Interfaces:**
- Consumes: `keyboardSettingsManager.isShowMathResultsEnabled`, iOS 18+ `textDocumentProxy.mathExpressionCompletionType`
- Produces: `KeyboardPresentationStatePolicy.shouldShowMathResults(isSettingEnabled:isHostCompletionAllowed:) -> Bool`
- Preserves: `SuggestionController.isShowMathResultsEnabled`, 기존 autocorrection cache와 suggestion update 경로

- [x] **Step 1: 표시 정책 RED 테스트 작성**

`KeyboardPresentationStatePolicyTests`에 production policy의 전체 Boolean 조합을 추가한다.

```swift
@Test("수식 결과는 사용자 설정과 host 허용 상태가 모두 켜진 경우에만 표시")
func test수식결과표시조건() {
    #expect(
        KeyboardPresentationStatePolicy.shouldShowMathResults(
            isSettingEnabled: true,
            isHostCompletionAllowed: true
        ) == true
    )
    #expect(
        KeyboardPresentationStatePolicy.shouldShowMathResults(
            isSettingEnabled: false,
            isHostCompletionAllowed: true
        ) == false
    )
    #expect(
        KeyboardPresentationStatePolicy.shouldShowMathResults(
            isSettingEnabled: true,
            isHostCompletionAllowed: false
        ) == false
    )
    #expect(
        KeyboardPresentationStatePolicy.shouldShowMathResults(
            isSettingEnabled: false,
            isHostCompletionAllowed: false
        ) == false
    )
}
```

- [x] **Step 2: policy 집중 테스트 RED 확인**

Run:

```sh
xcodebuild test -quiet \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -parallel-testing-enabled NO \
  -collect-test-diagnostics never \
  -only-testing:SYKeyboardTests/KeyboardPresentationStatePolicyTests \
  ONLY_ACTIVE_ARCH=YES ARCHS=arm64
```

Expected: `KeyboardPresentationStatePolicy`에 `shouldShowMathResults`가 없어 test target compile이 실패한다. 기존 policy 테스트의 동작 실패는 없어야 한다.

- [x] **Step 3: pure policy와 callback 전용 trait cache 구현**

`KeyboardPresentationStatePolicy`에 다음 메서드를 추가한다.

```swift
static func shouldShowMathResults(
    isSettingEnabled: Bool,
    isHostCompletionAllowed: Bool
) -> Bool {
    return isSettingEnabled && isHostCompletionAllowed
}
```

`BaseKeyboardViewController`의 `currentAutocorrectionType` 옆에 cache를 추가한다.

```swift
/// host 입력 변경 callback에서 마지막으로 확인한 수식 자동완성 허용 상태입니다.
private var isMathExpressionCompletionAllowed = true
```

두 callback의 중복 trait 읽기를 다음 private helper로 합친다.

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

`textWillChange(_:)`와 `textDidChange(_:)`의 기존 autocorrection 할당을 각각 `synchronizeTextInputTraits()`로 교체한다. `shouldShowMathResults()`는 proxy를 읽지 않는다.

```swift
func shouldShowMathResults() -> Bool {
    return KeyboardPresentationStatePolicy.shouldShowMathResults(
        isSettingEnabled: keyboardSettingsManager.isShowMathResultsEnabled,
        isHostCompletionAllowed: isMathExpressionCompletionAllowed
    )
}
```

- [x] **Step 4: policy GREEN과 호출 경계 확인**

Step 2 명령을 다시 실행한다.

Expected: `KeyboardPresentationStatePolicyTests` 전체가 통과한다.

Run:

```sh
rg -n 'mathExpressionCompletionType|synchronizeTextInputTraits' \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
```

Expected: `mathExpressionCompletionType`은 helper 내부에만 있고 helper 호출은 `textWillChange(_:)`와 `textDidChange(_:)`에만 있다. appearance 및 `shouldShowMathResults()` 경로에는 직접 proxy trait 접근이 없다.

- [x] **Step 5: Task 1 결과 기록과 커밋**

계획 문서의 Task 1 체크박스와 RED/GREEN 결과에 실제 simulator, 테스트 개수와 실패·성공 이유를 기록한다.

```sh
git add \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardPresentationStatePolicy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardTests/Utils/KeyboardPresentationStatePolicyTests.swift \
  docs/superpowers/plans/2026-08-12-math-expression-merge-readiness-hardening.md
git commit -m "fix: #98 - 수식 host trait 조기 접근 제거"
```

**실행 결과 (2026-08-12):** iPhone 13 mini / iOS 16.0 (arm64)에서 수행했다. 기본 샌드박스의 Step 2 첫 실행은 CoreSimulator와 SwiftPM/clang cache 접근 권한 오류로 컴파일 전에 중단되어, 권한 있는 동일 명령으로 재실행했다. RED 실행은 `shouldShowMathResults`가 없어서 테스트 타깃 컴파일이 실패했고, 이것이 새 정책 API 부재에 의한 기대한 실패임을 확인했다. GREEN 집중 테스트는 7개 통과, 실패 0개였다 (`Test-SYKeyboard-2026.08.12_03-02-17-+0900.xcresult`). 전체 `SYKeyboard` 테스트는 375개 통과, 실패 0개였다 (`Test-SYKeyboard-2026.08.12_03-03-32-+0900.xcresult`). `rg` 호출 경계 확인 결과 `mathExpressionCompletionType`은 `synchronizeTextInputTraits()` 내부 1곳에만 있고, helper 호출은 `textWillChange(_:)`와 `textDidChange(_:)` 2곳뿐이다.

---

### Task 2: evaluator 입력 길이와 parser 중첩 제한

**Files:**
- Modify: `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift`
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift`
- Modify: `docs/superpowers/plans/2026-08-12-math-expression-merge-readiness-hardening.md`

**Interfaces:**
- Consumes: `MathExpressionCompletionEvaluator.completion(for:) -> MathExpressionCompletion?`
- Produces: `MathExpressionCompletionEvaluator.maximumInputLength == 256`, parser 최대 중첩 16단계
- Preserves: 기존 suffix 후보 순서, parser 문법, formatting과 유한성 guard

- [x] **Step 1: 길이와 중첩 경계 RED 테스트 작성**

`MathExpressionCompletionEvaluatorTests`에 production 진입점을 호출하는 두 테스트를 추가한다.

```swift
@Test("수식 입력은 256자까지 계산하고 초과 입력은 거부")
func test수식입력길이경계() {
    let maximumLengthExpression = String(repeating: "1+", count: 127) + "1="
    #expect(maximumLengthExpression.count == 256)
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: maximumLengthExpression
        )?.insertText == "128"
    )

    let oversizedExpression = " " + maximumLengthExpression
    #expect(oversizedExpression.count == 257)
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: oversizedExpression
        ) == nil
    )
}

@Test("괄호 중첩은 16단계까지 계산하고 17단계부터 거부")
func test괄호중첩깊이경계() {
    func expression(depth: Int) -> String {
        return String(repeating: "(", count: depth)
            + "1+1"
            + String(repeating: ")", count: depth)
            + "="
    }

    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: expression(depth: 16)
        )?.insertText == "2"
    )
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: expression(depth: 17)
        ) == nil
    )
}
```

기존 256자 초과 overflow 테스트는 새 front-door 길이 guard가 먼저 거부한다. production 경로와 테스트 설명이 어긋나지 않도록 다음 oversized-input 테스트로 통합한다.

```swift
@Test("제한보다 긴 숫자와 연산 입력은 후보를 만들지 않음")
func test제한보다긴입력은_거부() {
    let overflowingNumber = String(repeating: "9", count: 400)
    let largeFiniteNumber = String(repeating: "9", count: 308)

    for expression in [
        "1/\(overflowingNumber)=",
        "1/(\(largeFiniteNumber)*2)="
    ] {
        #expect(
            MathExpressionCompletionEvaluator.completion(for: expression) == nil
        )
    }
}
```

중간 연산의 기존 `isFinite` guard는 방어 코드로 유지하되, 256자 제한 뒤에는 긴 입력 테스트가 overflow parser 경로를 검증한다고 설명하지 않는다.

- [x] **Step 2: evaluator 집중 테스트 RED 확인**

Run:

```sh
xcodebuild test -quiet \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -parallel-testing-enabled NO \
  -collect-test-diagnostics never \
  -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests \
  ONLY_ACTIVE_ARCH=YES ARCHS=arm64
```

Expected: 257자 입력은 leading space 뒤 정상 수식으로 계산되고 17단계 괄호도 계산되어 신규 단언 2개가 실패한다. 정확히 256자, 16단계, `.5+1=`과 기존 적대 입력은 통과한다.

- [x] **Step 3: evaluator 길이와 parser 깊이 guard 구현**

`MathExpressionCompletionEvaluator`에 정책 수치를 선언하고 suffix 처리 전에 검사한다.

```swift
static let maximumInputLength = 256

static func completion(for text: String) -> MathExpressionCompletion? {
    guard text.count <= maximumInputLength else { return nil }
    guard text.last == "=" else { return nil }

    for expressionText in expressionSuffixCandidates(beforeEqualIn: text) {
        if let completion = completion(forExpressionText: expressionText) {
            return completion
        }
    }

    return nil
}
```

`MathExpressionParser`에 깊이 상태를 추가한다.

```swift
private static let maximumNestingDepth = 16
private var nestingDepth = 0
```

`parsePrimary()`의 괄호 분기에 guard와 복구를 추가한다.

```swift
if let closingBracket = closingBracket(for: peek()) {
    guard nestingDepth < Self.maximumNestingDepth else { return nil }
    nestingDepth += 1
    defer { nestingDepth -= 1 }

    index += 1
    guard let value = parseExpression() else { return nil }
    guard peek() == closingBracket else { return nil }
    index += 1
    return value.isFinite ? value : nil
}
```

- [x] **Step 4: evaluator 집중 테스트 GREEN 확인**

Step 2 명령을 다시 실행한다.

Expected: 256/257자와 16/17단계 경계, `.5+1=`, suffix 문맥, 음수 0, 잘못된 숫자와 oversized input을 포함한 evaluator 테스트가 모두 통과한다.

- [x] **Step 5: Task 2 결과 기록과 커밋**

계획 문서의 Task 2 체크박스와 RED/GREEN 결과에 실제 테스트 개수와 실패·성공 이유를 기록한다.

```sh
git add \
  Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift \
  SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift \
  docs/superpowers/plans/2026-08-12-math-expression-merge-readiness-hardening.md
git commit -m "fix: #98 - 수식 입력 크기와 중첩 깊이 제한"
```

**실행 결과 (2026-08-12):** iPhone 13 mini / iOS 16.0 (arm64)에서 수행했다. 기본 샌드박스의 Step 2 첫 실행은 CoreSimulator와 SwiftPM/clang cache 접근 권한 오류로 컴파일 전에 중단되어, 권한 있는 동일 명령으로 재실행했다. 첫 권한 있는 실행은 추가한 oversized-input 테스트의 `for` 본문 괄호 누락으로 컴파일에 실패했고, 테스트 문법만 수정해 다시 실행했다. RED 실행은 길이 guard가 없어 257자 입력을 계산하고 nesting guard가 없어 17단계 괄호를 계산하여 신규 테스트 2개가 기대대로 실패했다. GREEN 집중 테스트는 evaluator 테스트 29개 통과, 실패 0개였다. 전체 `SYKeyboard` 테스트의 첫 실행은 `SuggestionControllerMathResultsTests.test후보갱신은_이전SelectionOrigin을_새Origin으로교체()` 1개가 실패했으나, 같은 테스트 단독 실행은 통과했고 전체 재실행은 376개 통과, 실패 0개였다. `git diff --check`도 통과했다.

---

### Task 3: 전체 회귀와 머지 위생 검증

**Files:**
- Modify: `docs/superpowers/specs/2026-07-30-single-delete-released-touchdown-recovery-design.md`
- Modify: `docs/superpowers/plans/2026-08-12-math-expression-merge-readiness-hardening.md`

**Interfaces:**
- Consumes: Task 1과 Task 2의 production 동작과 테스트
- Produces: 전체 test/build 결과와 whitespace 오류가 없는 자동 검증 상태

- [x] **Step 1: 기존 문서 trailing space를 표시 가능한 문자로 교체**

기존 삭제 예시의 실제 trailing space를 `␠`로 표시해 의미는 유지하고 `git diff --check` 오류를 제거한다.

```text
1 1 + 2 =3  --삭제 반복-->  1 1  --다음 삭제 1회-->  1␠
```

- [x] **Step 2: 전체 `SYKeyboard` 테스트 실행과 결과 추출**

```sh
xcodebuild test -quiet \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -parallel-testing-enabled NO \
  -collect-test-diagnostics never \
  -resultBundlePath /private/tmp/SYKeyboard-MathHardening-Final.xcresult \
  ONLY_ACTIVE_ARCH=YES ARCHS=arm64

xcrun xcresulttool get test-results summary \
  --path /private/tmp/SYKeyboard-MathHardening-Final.xcresult
```

Expected: 실패, skip, expected failure 없이 전체 테스트가 통과한다. 결과 bundle에서 실제 총 테스트 개수와 simulator 정보를 기록한다.

- [x] **Step 3: 한글·영문 keyboard extension 빌드**

```sh
xcodebuild build -quiet \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  ONLY_ACTIVE_ARCH=YES ARCHS=arm64

xcodebuild build -quiet \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  ONLY_ACTIVE_ARCH=YES ARCHS=arm64
```

Expected: 두 scheme이 build error 없이 성공한다. 외부 SDK PCM 경고는 project compile 실패와 구분해 기록한다.

- [x] **Step 4: 변경 범위와 whitespace 검증**

```sh
git diff --check origin/develop..HEAD
git status --short
git diff --stat origin/develop..HEAD
rg -n 'mathExpressionCompletionType|synchronizeTextInputTraits' \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
```

Expected: branch 전체에 whitespace 오류가 없고 working tree에는 계획 결과 기록만 남는다. `mathExpressionCompletionType`의 직접 접근은 callback에서만 호출되는 helper 내부 한 곳뿐이다.

- [x] **Step 5: 자동 검증 결과 기록과 커밋**

계획 문서에 실제 전체 테스트 개수, simulator UDID·OS, 두 extension 빌드 결과, 경고와 `.xcresult` 경로를 기록한다. iOS 18+ 실기기 host 앱 검증은 자동화가 대체하지 않으므로 수행하지 못하면 미확인으로 기록한다.

```sh
git add \
  docs/superpowers/specs/2026-07-30-single-delete-released-touchdown-recovery-design.md \
  docs/superpowers/plans/2026-08-12-math-expression-merge-readiness-hardening.md
git commit -m "docs: #98 - 수식 안정성 보강 검증 결과 기록"
```

**실행 결과 (2026-08-12):** 삭제 복구 설계 문서의 알려진 trailing space를 `␠`로 교체했다. 시작 시 `/private/tmp/SYKeyboard-MathHardening-Final.xcresult`는 존재하지 않았으나, 기본 샌드박스 테스트가 CoreSimulator와 SwiftPM/clang cache 권한 오류로 컴파일 전에 중단하면서 불완전 bundle을 만들었으므로 삭제하지 않고 보존했다. 같은 이유로 첫 두 권한 있는 실행도 `Data/`와 `Staging/`만 있는 불완전 bundle을 남겨 보존했다. `rtk proxy xcodebuild test -quiet -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -parallel-testing-enabled NO -collect-test-diagnostics never -resultBundlePath /private/tmp/SYKeyboard-MathHardening-Final-20260812-0330.xcresult ONLY_ACTIVE_ARCH=YES ARCHS=arm64`를 권한 있는 환경에서 완료해 exit 0을 확인했다. 이어 `rtk xcrun xcresulttool get test-results summary --path /private/tmp/SYKeyboard-MathHardening-Final-20260812-0330.xcresult`로 iPhone 13 mini / iOS 16.0 / arm64 (UDID `CBD992D3-5364-4F69-AC5F-0077ADF1A292`)의 전체 376개 통과, 실패 0, skip 0, expected failure 0을 추출했다. HangeulKeyboard와 EnglishKeyboard는 동일 대상·옵션의 권한 있는 build에서 각각 exit 0으로 성공했다. 두 기본 샌드박스 build는 같은 CoreSimulator·cache 권한 오류로 중단됐고, HangeulKeyboard 성공 build에는 Meta 외부 SDK의 누락된 PCM 경고와 Xcode의 동일 UDID 다중 architecture 대상 선택 경고가 있었으나 project compile error는 없었다. EnglishKeyboard 성공 build에는 동일 destination 선택 경고만 있었다. `git diff --check`는 working tree에서 통과했고, `git diff --check origin/develop..HEAD`의 커밋 전 실행은 아직 커밋되지 않은 이 문서의 기존 trailing space 1건만 보고했다. 문서 commit 후 같은 명령은 exit 0으로 통과했고 `git status --short`도 비어 있었다. `rg -n -C 4 'mathExpressionCompletionType|synchronizeTextInputTraits' Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` 확인 결과 직접 trait 접근은 `synchronizeTextInputTraits()` 내부 1곳이며 helper 호출은 `textWillChange(_:)`, `textDidChange(_:)` 두 callback뿐이다. iOS 18+ 실기기 host 앱에서의 실제 callback timing 및 trait 반영은 이 자동 검증으로 확인하지 못했으므로 미확인 상태다.

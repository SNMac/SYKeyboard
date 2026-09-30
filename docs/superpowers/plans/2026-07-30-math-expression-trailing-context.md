# 수식 자동완성 앞쪽 숫자 문맥 분리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앞쪽 숫자 문맥 뒤에 입력한 마지막 완성 수식만 계산해 결과 후보를 표시한다.

**Architecture:** evaluator가 기존 최대 suffix를 우선 평가하고, 실패한 경우 입력 전체의 숫자-only 문맥과 일반 ASCII 공백 뒤에 있는 suffix만 제한적으로 재평가한다. controller는 evaluator가 반환한 `expressionText`를 그대로 사용해 기존 표시 및 action 계약을 유지한다.

**Tech Stack:** Swift 5, Foundation, Swift Testing, Xcode 26+

## Global Constraints

- 현재 `feat/#98-math-calculation-auto-complete` 브랜치에서 작업하고 새 worktree나 브랜치를 만들지 않는다.
- 기존 숫자 사이 소수점·쉼표·TAB·NBSP 거부를 유지한다.
- `memo 2 3+1=` 거부와 연산자·괄호 주변 공백 허용을 유지한다.
- 일반 자동완성, 텍스트 대치, undo/redo, `inputBuffer`, selection-origin action을 변경하지 않는다.
- push하지 않는다.

---

### Task 1: trailing 수식 suffix 평가

**Files:**
- Modify: `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift`
- Modify: `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift`
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift`
- Modify: `docs/superpowers/plans/2026-07-30-math-expression-trailing-context.md`

**Interfaces:**
- Consumes: `MathExpressionCompletionEvaluator.completion(for:)`
- Produces: 숫자-only 앞 문맥 뒤의 마지막 수식을 담은 기존 `MathExpressionCompletion`

- [x] **Step 1: 사용자 재현 입력의 실패 테스트 작성**

```swift
@Test("앞쪽 숫자 문맥 뒤 마지막 수식만 계산")
func test앞쪽숫자문맥뒤_마지막수식만계산() {
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "1 2 + 3 ="
        )?.displayText == "2 + 3 =5"
    )
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "1 2+3="
        )?.displayText == "2+3=5"
    )
}
```

controller 테스트는 두 입력의 후보 배열과 `replaceExpression`의 삭제 길이가
각 수식 suffix 길이인지 확인한다.

결과 (2026-07-30): evaluator에 두 입력의 `expressionText`, `displayText`,
`insertText` 계약을 추가했다. controller에는 좌·중·우 표시와 가운데 삽입,
오른쪽 suffix 대치 길이 계약을 추가했다. 기존 거부 목록에서는 새 요구와
충돌하는 `1 2+3=`만 제외했다.

- [x] **Step 2: evaluator와 controller 집중 테스트로 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests
```

Expected: 신규 두 재현 입력만 수식 결과가 `nil` 또는 typing 후보여서 실패한다.

결과 (2026-07-30): 최초 RED 실행은 동명 시뮬레이터 중 iOS 18.6에서
38개 통과, 신규 evaluator/controller 테스트 2개 실패를 확인했다. evaluator는
두 입력 모두 `nil`, controller는 `.typing`과 빈 결과 후보를 반환해 의도한
이유로 RED였다.

- [x] **Step 3: 제한된 trailing suffix 평가 구현**

`completion(for:)`에서 최대 suffix부터 후보를 순회하고, 각 후보에 기존 등호,
숫자 공백, parser, formatting validation을 동일하게 적용한다.

```swift
for expressionText in expressionSuffixCandidates(beforeEqualIn: text) {
    if let completion = completion(forExpressionText: expressionText) {
        return completion
    }
}
return nil
```

fallback 후보는 최대 suffix가 입력 전체를 대표하고, 후보 앞부분이 숫자와 일반
ASCII 공백으로만 구성되며, 숫자와 숫자 사이 일반 공백 뒤에서 시작할 때만 만든다.

결과 (2026-07-30): 기존 최대 suffix를 첫 후보로 유지하고, 전체 입력의
숫자-only 문맥에서 숫자와 숫자 사이 일반 ASCII 공백 뒤 suffix만 추가 평가하도록
구현했다. 각 후보에는 기존 숫자 공백 validation과 parser를 그대로 적용한다.

- [x] **Step 4: 집중 테스트 GREEN 확인**

Step 2와 같은 명령을 실행한다.

Expected: 신규 재현, 기존 숫자 공백 거부, 수식 표시/action 테스트가 모두 통과한다.

결과 (2026-07-30): iPhone 13 mini / iOS 16.0에서 evaluator와 controller
집중 suite 40/40 통과, 실패와 skip은 0개였다. 동일 이름의 iOS 18.6
시뮬레이터가 자동 선택된 초기 GREEN 뒤 iOS 16.0 UDID
`CBD992D3-5364-4F69-AC5F-0077ADF1A292`로 고정해 다시 확인했다.

- [x] **Step 5: 전체 회귀와 extension 빌드 검증**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

xcodebuild build \
  -project SYKeyboard.xcodeproj \
  -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'

git diff --check
```

Expected: 전체 테스트와 두 extension 빌드가 성공하고 whitespace 오류가 없다.

결과 (2026-07-30): iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`)에서 집중 suite 40/40,
전체 `SYKeyboard` 테스트 371/371이 통과했다. `HangeulKeyboard`와
`EnglishKeyboard` 빌드도 성공했다. Hangeul 빌드에는 외부 Meta SDK의 PCM 경로
경고가 있었지만 build error는 없었고, English 빌드는 경고 없이 성공했다.
`git diff --check`도 통과했으며 production/test 범위에서 `hasSelectedText`,
production Swift 범위에서 `setMarkedText` 검색 결과는 없었다.

- [x] **Step 6: 구현 리뷰와 커밋**

변경 범위, 기존 공백 거부, suffix 대치 길이, selection-origin 비변경을
재검토한다.

리뷰 결과 (2026-07-30): evaluator 외 production 코드 변경은 없으며 최대
suffix 우선순위와 제한된 fallback 조건이 설계와 일치한다. 소수점·쉼표·TAB·NBSP,
문자 prefix, `x`와 연산자가 포함된 prefix의 거부 회귀를 확인했고, controller
테스트가 실제 후보와 suffix 삭제 길이를 검증한다. Critical/Important finding은
없다.

```sh
git add \
  Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift \
  SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift \
  SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift \
  docs/superpowers/specs/2026-07-30-math-expression-trailing-context-design.md \
  docs/superpowers/plans/2026-07-30-math-expression-trailing-context.md
git commit -m "fix: #98 - 앞쪽 숫자 문맥과 수식 suffix 분리"
```

결과 (2026-07-30): 위 리뷰에서 Critical/Important finding이 없는 것을 확인하고
코드·테스트·설계·계획을 `fix: #98 - 앞쪽 숫자 문맥과 수식 suffix 분리`
커밋으로 남겼다. push는 수행하지 않았다.

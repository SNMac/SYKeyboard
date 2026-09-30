# 수식 문맥 엣지케이스 인식 수정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 수식 거부 계약을 유지하면서 선행 소수점, 문맥 경계, 공백 선택 수식과 음수 0을 올바르게 처리한다.

**Architecture:** `MathExpressionCompletionEvaluator`가 최대 suffix와 제한된 경계 suffix를 기존 parser에 순서대로 전달하고, parser는 정수부가 없는 소수만 추가로 허용한다. 선택 정책은 evaluator가 확인한 공백 수식에만 기존 `.clear` 예외를 적용한다.

**Tech Stack:** Swift 5, Foundation, UIKit, Swift Testing, Xcode 26+

## Global Constraints

- 현재 `feat/#98-math-calculation-auto-complete` 브랜치에서 작업하고 새 worktree나 브랜치를 만들지 않는다.
- `memo 2 3+1=`, `x 1 2+3=`, `1 + 2 3+4=`의 숫자 공백 거부를 유지한다.
- `1=2+3=`, `3+1=4=`, `3+1=4 2 3+4=`를 부분 수식으로 오탐지하지 않는다.
- `(-3)+5=`, `2*(-3)=`, `·`, `−`를 새로 지원하지 않는다.
- 수식 후보 preview, 좌·중·우 action, 선택 origin 검증, 일반 자동완성, n-gram, 텍스트 대치를 유지한다.
- 신규 의존성과 테스트 전용 production API를 추가하지 않는다.
- push하지 않는다.

---

### Task 1: evaluator 숫자 parsing과 문맥 suffix 보강

**Files:**
- Modify: `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift`
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift`
- Modify: `docs/superpowers/plans/2026-08-11-math-expression-context-edge-cases.md`

**Interfaces:**
- Consumes: `MathExpressionCompletionEvaluator.completion(for:) -> MathExpressionCompletion?`
- Produces: 선행 소수점과 제한된 문맥 suffix를 반영한 기존 `MathExpressionCompletion`

- [x] **Step 1: evaluator 재현과 오탐지 방지 테스트 작성**

`MathExpressionCompletionEvaluatorTests`에 production 진입점을 호출하는 다음 계약을 추가한다.

결과 (2026-08-11): 선행 소수점, 이전 등식, `x/X` 단어 경계, 줄바꿈,
음수 0의 production 반환값을 검증하는 7개 테스트를 추가했다. 잘못된 선행
소수점과 이전 등식 뒤 반복 숫자 공백의 오탐지 방지를 별도 단언으로
고정했다.

```swift
@Test("정수부를 생략한 소수를 0으로 시작하는 소수로 계산")
func test선행소수점숫자를_계산() {
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: ".5+1="
        )?.insertText == "1.5"
    )
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "-.5+1="
        )?.insertText == "0.5"
    )
}

@Test("잘못된 선행 소수점은 후보를 만들지 않음")
func test잘못된선행소수점은_거부() {
    for expression in [".+1=", "..5+1=", "1..5+1="] {
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: expression
            ) == nil
        )
    }
}

@Test("이전 등식 결과 뒤 마지막 수식만 계산")
func test이전등식결과뒤_마지막수식만계산() {
    let completion = MathExpressionCompletionEvaluator.completion(
        for: "3+1=4 2+3="
    )
    #expect(completion?.expressionText == "2+3=")
    #expect(completion?.insertText == "5")
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "3+1=4 2 3+4="
        ) == nil
    )
}

@Test("단어 끝 곱셈 별칭과 줄바꿈 뒤 마지막 수식만 계산")
func test단어끝곱셈별칭과_줄바꿈경계를분리() {
    for text in ["tax 2+3=", "BOX 2+3=", "1\n2+3=", "memo 1\n2+3="] {
        let completion = MathExpressionCompletionEvaluator.completion(for: text)
        #expect(completion?.expressionText == "2+3=")
        #expect(completion?.insertText == "5")
    }
}

@Test("반올림된 음수 0은 부호 없이 표시")
func test반올림된음수0은_양수0으로표시() {
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "-0.0001+0="
        )?.insertText == "0"
    )
}
```

- [x] **Step 2: evaluator 집중 테스트 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests
```

Expected: 기존 테스트는 통과하고 신규 정상 인식·음수 0 단언만 현재 `nil` 또는 `-0`으로 실패한다. 잘못된 선행 소수점과 오탐지 방지 단언은 기존처럼 통과한다.

결과 (2026-08-11): iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`)에서 28개 evaluator 테스트를 실행했다.
선행 소수점, 이전 등식, `x/X` 단어 경계, 줄바꿈, 음수 0의 신규 테스트
5개가 각각 `nil` 또는 `-0`으로 실패해 예상한 RED를 확인했다. 잘못된
선행 소수점과 이전 등식 뒤 반복 숫자 공백 방지 테스트, 기존 21개 테스트는
통과했다. 테스트 완료 후 simulator 진단 수집에서 600초 timeout이 발생했으나
실제 테스트 성공·실패 결과는 출력에서 확인했다.

- [x] **Step 3: 제한된 suffix 후보와 선행 소수점 parsing 구현**

`expressionSuffixCandidates(beforeEqualIn:)`는 기존 최대 suffix 뒤에 중복 없이 다음 후보를 추가한다.

```swift
static func appendCandidate(
    _ candidate: Substring,
    to candidates: inout [String]
) {
    let text = String(candidate.drop(while: { $0.isWhitespace }))
    guard !text.isEmpty, !candidates.contains(text) else { return }
    candidates.append(text)
}
```

- `Character.isNewline`으로 찾은 마지막 줄바꿈 뒤 후보
- 최대 suffix가 `x/X`로 시작하고 원본의 직전 문자가 `isLetter`인 경우 첫 공백 뒤 후보
- 최종 `=` 앞 마지막 `=` 뒤에 비어 있지 않은 결과 token 하나와 공백이 있는 경우 그 공백 뒤 후보
- 기존 전체 숫자·ASCII 공백 fallback

이전 `=` 뒤 후보는 첫 whitespace run 하나만 생성해 `3+1=4 2 3+4=`의 `2 3+4=`가 parser에서 거부되면 더 짧은 `3+4=`를 시도하지 않는다.

`parseNumber()`는 `integerText.isEmpty && peek() == "."`을 선행 소수점으로 처리하고 `numberText`를 `"0"`으로 시작한다. 선행 소수점이면 소수부 숫자가 최소 한 자리인지 검사한다. 정수부가 있는 `1.`의 기존 허용은 유지한다.

`decimalResult(_:)`는 반올림 후 `roundedValue == 0`이면 `0.0`을 formatter에 전달한다.

결과 (2026-08-11): 최대 suffix 뒤에 마지막 줄, 단어 끝 `x/X`, 이전 등식
결과 뒤의 제한된 후보를 중복 없이 추가했다. 이전 등식 결과 token은 숫자,
소수점, 쉼표, 선행 음수 부호만 허용하고 첫 whitespace run 뒤 후보만 평가해
더 짧은 애매한 수식을 오탐지하지 않도록 했다. `parseNumber()`는 선행
소수점을 0으로 시작하는 소수로 파싱하되 소수부 최소 한 자리를 요구하고,
반올림 결과 0은 양수 0으로 정규화했다.

- [x] **Step 4: evaluator 집중 테스트 GREEN 확인**

Step 2와 같은 명령을 실행한다.

Expected: 선행 소수점, 이전 등식, `x/X` 단어, 줄바꿈, 음수 0 신규 계약과 기존 evaluator 테스트가 모두 통과한다.

결과 (2026-08-11): iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`) arm64 단일 실행에서 evaluator
테스트 28/28개가 통과했고 실패와 skip은 0개였다. Meta/FBAudienceNetwork
정적 라이브러리의 외부 PCM debug 경로 경고가 출력됐지만 테스트 exit code는 0이었다.

- [x] **Step 5: Task 1 결과 기록과 커밋**

계획 문서의 Task 1 체크박스와 RED/GREEN 결과에 실제 테스트 개수, simulator, 실패·성공 이유를 기록한다.

결과 (2026-08-11): production 변경은 evaluator 한 파일에 한정했고, 신규 7개
테스트가 실제 `completion(for:)` 반환값을 검증한다. 최대 suffix 우선,
기존 숫자-only fallback, 잘못된 숫자 공백·연속 등호 거부, 유한성 검증을
그대로 유지하는 것을 집중 테스트로 재확인했다.

```sh
git add \
  Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift \
  SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift \
  docs/superpowers/plans/2026-08-11-math-expression-context-edge-cases.md
git commit -m "fix: #98 - 수식 문맥 경계와 선행 소수점 처리"
```

---

### Task 2: 공백이 포함된 selection-origin 수식 허용

**Files:**
- Modify: `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`
- Modify: `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`
- Modify: `docs/superpowers/plans/2026-08-11-math-expression-context-edge-cases.md`

**Interfaces:**
- Consumes: `MathExpressionCompletionEvaluator.completion(for:)`
- Produces: 기존 `suggestionUpdateAction(isPredictiveTextEnabled:selectedText:inputBuffer:) -> SuggestionUpdateAction`
- Preserves: `SuggestionController.mathResultAction(at:selectedText:) -> MathResultSuggestionAction?`

- [x] **Step 1: selection policy와 controller action 재현 테스트 작성**

`KeyboardSuggestionSelectionPolicyTests`에 공백 수식과 일반 다중 단어 선택을 구분하는 단언을 추가한다.

결과 (2026-08-11): 기존 `suggestionUpdateAction` production 진입점에 선택한
`3 + 1 =`이 `.update`를 반환해야 한다는 단언을 추가했다. 일반 `hello world`의
`.clear` 계약은 그대로 두었다. controller에는 공백이 포함된 selection-origin의
가운데·오른쪽 action 반환값을 직접 검증하는 테스트를 추가했다.

```swift
#expect(
    KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
        isPredictiveTextEnabled: true,
        selectedText: "3 + 1 =",
        inputBuffer: "input"
    ) == .update("3 + 1 =")
)
#expect(
    KeyboardSuggestionSelectionPolicy.suggestionUpdateAction(
        isPredictiveTextEnabled: true,
        selectedText: "hello world",
        inputBuffer: "input"
    ) == .clear
)
```

`SuggestionControllerMathResultsTests`에 선택한 `3 + 1 =`의 가운데·오른쪽 action을 검증한다.

```swift
let controller = makeMathController(
    expression: "3 + 1 =",
    selectedText: "3 + 1 ="
)
#expect(
    controller.mathResultAction(
        at: 1,
        selectedText: "3 + 1 ="
    ) == .replaceSelection("3 + 1 =4")
)
#expect(
    controller.mathResultAction(
        at: 2,
        selectedText: "3 + 1 ="
    ) == .replaceSelection("4")
)
```

- [x] **Step 2: selection 집중 테스트 RED 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests
```

Expected: 공백 수식이 `.clear`라서 policy 단언이 실패한다. controller action 자체는
기존 하위 계약이 올바르면 통과할 수 있다.

결과 (2026-08-11): iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`) arm64 단일 실행에서 두 suite의
35개 테스트를 실행했다. 신규 공백 수식 policy 단언 1개만 기존 `.clear`
반환으로 실패했고, 공백 포함 selection-origin controller action과 기존 테스트는
통과해 예상한 RED를 확인했다. 실패 진단 수집은 `never`로 설정해 이전 진단 수집
지연 없이 exit code 65와 실패 테스트 이름을 확인했다.

- [x] **Step 3: 유효한 공백 수식만 selection update 허용**

`suggestionUpdateAction` 은 공백이 포함된 선택 텍스트만 evaluator로 확인해 다음처럼
분기한다.

```swift
if let selectedText, !selectedText.isEmpty {
    if selectedText.contains(where: { $0.isWhitespace }),
       MathExpressionCompletionEvaluator.completion(
           for: selectedText
       ) == nil {
        return .clear
    }
    return .update(selectedText)
}
```

공백이 없는 선택은 evaluator를 호출하지 않고 기존 경로를 유지한다. controller의 기존
origin-aware action 검증은 변경하지 않는다.

결과 (2026-08-11): 선택 텍스트에 공백이 있을 때만 기존 evaluator를 호출하고,
완성 가능한 수식이면 `.update(selectedText)`를 유지하도록 변경했다. 일반 다중 단어
선택은 기존처럼 `.clear`를 반환하며, 공백 없는 선택과 controller action 경로는
변경하지 않았다.

- [x] **Step 4: selection 집중 테스트 GREEN 확인**

Step 2와 같은 명령을 실행한다.

Expected: 공백 수식 selection update, 일반 공백 selection clear, 좌·중·우 selection-origin action과 stale selection 차단 테스트가 모두 통과한다.

결과 (2026-08-11): iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`) arm64 단일 실행에서 두 suite의
35/35개 테스트가 통과했고 exit code는 0이었다. 공백 수식 selection update,
일반 다중 단어 selection clear, selection-origin action과 stale selection 차단을
함께 재확인했다. Meta/FBAudienceNetwork 정적 라이브러리의 외부 PCM debug 경로
경고는 있었지만 테스트 실패는 없었다.

- [x] **Step 5: Task 2 결과 기록과 커밋**

계획 문서의 Task 2 체크박스와 RED/GREEN 결과를 실제 실행 결과로 갱신한다.

결과 (2026-08-11): production 변경은 selection policy 한 파일의 기존 분기에
한정했다. evaluator를 재사용해 수식 문법을 중복 구현하지 않았고, 공백 없는 선택과
controller의 origin-aware action 계약은 그대로 유지했다.

```sh
git add \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift \
  SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift \
  SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift \
  docs/superpowers/plans/2026-08-11-math-expression-context-edge-cases.md
git commit -m "fix: #98 - 공백 포함 선택 수식 후보 허용"
```

---

### Task 3: 전체 회귀와 keyboard extension 빌드 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-08-11-math-expression-context-edge-cases.md`

**Interfaces:**
- Consumes: Task 1과 Task 2의 production 동작과 회귀 테스트
- Produces: 실제 명령·simulator·테스트 개수·빌드 결과가 기록된 완료 증거

- [x] **Step 1: 전체 `SYKeyboard` 테스트 실행**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 실패와 skip 없이 전체 테스트가 통과한다. `.xcresult`에서 실제 테스트 개수와 실패 개수를 확인한다.

결과 (2026-08-11): iPhone 13 mini / iOS 16.0
(`CBD992D3-5364-4F69-AC5F-0077ADF1A292`) arm64 단일 실행에서 전체
374/374개 테스트가 통과했고 실패, skip, expected failure는 각각 0개였다.
결과 번들은
`/private/tmp/SYKeyboard-MathEdge-Final-20260811-1230.xcresult`에 저장했고,
다음 명령으로 동일한 개수를 확인했다.

```sh
xcrun xcresulttool get test-results summary \
  --path /private/tmp/SYKeyboard-MathEdge-Final-20260811-1230.xcresult
```

- [x] **Step 2: 한글·영문 keyboard extension 빌드**

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

Expected: 두 scheme이 build error 없이 성공한다. 외부 SDK 경고가 있으면 코드 실패와 구분해 기록한다.

결과 (2026-08-11): 같은 iPhone 13 mini / iOS 16.0 simulator의 arm64를
대상으로 `HangeulKeyboard`와 `EnglishKeyboard` scheme을 각각 빌드했고 두 명령
모두 exit code 0으로 성공했다. 한글 scheme 빌드에서는 Meta/FBAudienceNetwork
정적 라이브러리의 외부 PCM debug 경로 경고가 출력됐지만 project compile 또는
link error는 없었다. 영문 scheme의 증분 빌드는 destination 중복 경고 외에 추가
경고 없이 성공했다.

- [x] **Step 3: 변경 범위와 whitespace 검증**

```sh
git diff --check 4fb82fed..HEAD
git status --short
git diff --stat 4fb82fed..HEAD
```

Expected: whitespace 오류가 없고, 설계·계획·evaluator·selection policy·관련 테스트 이외의
변경이 없다.

결과 (2026-08-11): `git diff --check 4fb82fed..HEAD`와 현재 미커밋 변경 대상
`git diff --check`가 모두 출력 없이 exit code 0으로 통과했다. 기준 커밋 이후 변경은
설계·계획 문서, evaluator와 selection policy, 관련 테스트 3개로 총 7개 파일이며,
현재 미커밋 변경은 이 계획 문서의 검증 기록뿐임을 `git status --short`와
`git diff --stat`으로 확인했다.

- [x] **Step 4: 자동 검증 결과 기록과 커밋**

계획 문서에 실제 전체 테스트 개수, simulator UDID·OS, 두 extension 빌드 결과, 경고,
`.xcresult` 경로와 결과 추출 명령을 기록한다. 실제 입력 앱은 자동 검증이 대체할 수
없으므로 수동 확인을 수행하지 못하면 미확인으로 기록한다.

결과 (2026-08-11): 전체 374개 테스트와 두 keyboard extension 빌드가 모두
성공했고, 결과 bundle 경로와 추출 명령을 위 단계에 기록했다. 실제 host 입력 앱에서
키보드를 열어 후보 preview·탭·스페이스 동작을 관찰하는 수동 검증은 수행하지 않아
미확인 상태로 남긴다.

```sh
git add docs/superpowers/plans/2026-08-11-math-expression-context-edge-cases.md
git commit -m "docs: #98 - 수식 문맥 엣지케이스 검증 결과 기록"
```

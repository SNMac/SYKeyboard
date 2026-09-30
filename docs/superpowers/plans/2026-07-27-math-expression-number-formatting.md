# 수식 자동완성 숫자 입력과 결과 표기 확장 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 쉼표가 포함된 숫자와 다양한 곱셈·나눗셈 기호를 계산하고, 결과를 천 단위 쉼표 또는 유효숫자 4자리 과학 표기로 표시한다.

**Architecture:** 기존 `MathExpressionParser`의 재귀 하강 구조와 `MathExpressionCompletion` 인터페이스를 유지한다. 계산용 문자 배열에서 연산자만 표준 기호로 정규화하고 숫자 토큰의 쉼표 배치를 직접 검증하며, 결과 포맷팅을 일반 decimal 경로와 큰 수 scientific 경로로 분리한다.

**Tech Stack:** Swift 5, Foundation `NumberFormatter`, Swift Testing, Xcode 16+

## Global Constraints

- iOS 16+ 지원을 유지한다.
- 곱셈 연산자는 `×`, `⋅`, `*`, `x`, `X`, 나눗셈 연산자는 `÷`, `/`를 지원한다.
- 첫 그룹 1~3자리와 이후 3자리 그룹으로 구성된 쉼표 입력만 허용한다.
- `1.`은 유효한 숫자로, `.` 단독과 잘못된 쉼표 그룹은 유효하지 않은 숫자로 처리한다.
- 일반 결과는 최대 소수 셋째 자리까지 반올림하고 천 단위 쉼표를 표시한다.
- 절댓값이 `10,000,000,000` 이상인 결과는 유효숫자 4자리 `가수×10ⁿ` 형식으로 표시한다.
- 기존 연산 우선순위, 괄호, 앞쪽 음수, 중간 단항 부호 차단, 0 나누기 동작을 유지한다.
- 각 step은 코드·테스트·문서 결과를 확인한 직후에만 체크하고, 실제 명령과 결과를 체크박스 줄 아래에 기록한 뒤 해당 step 변경만 커밋한다.
- Firebase, 광고, entitlement, bundle identifier, provisioning 설정은 변경하지 않는다.

---

### Task 1: 입력 숫자와 연산자 문법 확장

**Files:**
- Modify: `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift:31-46`
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift:36-43`
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift:65-72`
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift:99-115`
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift:144-165`
- Modify: `docs/superpowers/plans/2026-07-27-math-expression-number-formatting.md`

**Interfaces:**
- Consumes: `MathExpressionCompletionEvaluator.completion(for:) -> MathExpressionCompletion?`
- Produces: 기존 인터페이스를 변경하지 않고 쉼표 숫자, 추가 곱셈·나눗셈 기호, 소수점으로 끝나는 숫자를 지원하는 `MathExpressionParser`

- [x] **Step 1: 입력 형식 회귀 테스트를 추가하고 RED를 확인해 커밋**

  - 결과: `iPhone 13 mini / iOS 16.0` 집중 테스트 14개 중 11개 통과, 3개 실패.
  - 실패: 올바른 천 단위 쉼표 계산, 잘못된 쉼표 거부, 추가 곱셈·나눗셈 기호 인식.
  - 확인: `1.+2=`와 숫자 없는 소수점 거부는 기존 구현에서도 통과해 회귀 테스트로 유지.

`MathExpressionCompletionEvaluatorTests`에 다음 테스트를 추가한다.

```swift
@Test("올바른 천 단위 쉼표 숫자는 계산하고 입력 원문을 유지")
func test올바른천단위쉼표숫자는_계산하고입력원문을유지() {
    let completion = MathExpressionCompletionEvaluator.completion(
        for: "1,000 / 4="
    )

    #expect(completion?.expressionText == "1,000 / 4=")
    #expect(completion?.displayText == "1,000 / 4=250")
}

@Test("잘못된 천 단위 쉼표와 소수부 쉼표는 후보를 만들지 않음")
func test잘못된천단위쉼표와_소수부쉼표는후보를만들지않음() {
    #expect(MathExpressionCompletionEvaluator.completion(for: "10,00+1=") == nil)
    #expect(MathExpressionCompletionEvaluator.completion(for: "1234,567+1=") == nil)
    #expect(MathExpressionCompletionEvaluator.completion(for: "1,000.0,1+1=") == nil)
}

@Test("지원하는 곱셈과 나눗셈 기호를 동일한 연산으로 계산")
func test지원하는곱셈과나눗셈기호를_동일한연산으로계산() {
    for multiplicationOperator in ["×", "⋅", "*", "x", "X"] {
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "6\(multiplicationOperator)2="
            )?.insertText == "12"
        )
    }

    for divisionOperator in ["÷", "/"] {
        #expect(
            MathExpressionCompletionEvaluator.completion(
                for: "6\(divisionOperator)2="
            )?.insertText == "3"
        )
    }
}

@Test("소수점으로 끝난 숫자는 계산하고 숫자 없는 소수점은 거부")
func test소수점으로끝난숫자는_계산하고숫자없는소수점은거부() {
    #expect(
        MathExpressionCompletionEvaluator.completion(for: "1.+2=")?.insertText == "3"
    )
    #expect(MathExpressionCompletionEvaluator.completion(for: ".+2=") == nil)
    #expect(MathExpressionCompletionEvaluator.completion(for: "1..0+2=") == nil)
}
```

다음 명령을 실행한다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/MathExpressionCompletionEvaluatorTests
```

기대 결과는 새 테스트가 현재 미지원 입력 때문에 실패하는 것이다. 컴파일 오류가 아니라 assertion
실패임을 확인한다. 체크박스 아래에 실패한 테스트 이름과 총 실패 개수를 기록한 뒤 커밋한다.

```sh
git add SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift \
  docs/superpowers/plans/2026-07-27-math-expression-number-formatting.md
git commit -m "test: #98 - 수식 입력 형식 확장 회귀 테스트 추가"
```

- [x] **Step 2: 입력 정규화와 숫자 검증을 구현하고 GREEN을 확인해 커밋**

  - 결과: `iPhone 13 mini / iOS 16.0` 집중 테스트 14개 통과, 실패·건너뜀 0개.
  - 확인: 올바른 쉼표 계산, 잘못된 쉼표 거부, `×`·`⋅`·`*`·`x`·`X`·`÷`·`/` 인식 통과.
  - 경고: 외부 광고 SDK PCM 경로 경고가 있었으나 evaluator 빌드와 테스트 오류는 없음.

`expressionSuffix(beforeEqualIn:)`의 허용 문자 집합을 다음처럼 확장한다.

```swift
let allowedCharacters = Set("0123456789,.+-*/×⋅xX÷=()[]{} ")
```

`MathExpressionParser.init(_:)`에서 공백 제거와 연산자 정규화를 함께 수행한다.

```swift
init(_ expression: String) {
    characters = expression.compactMap { character -> Character? in
        guard !character.isWhitespace else { return nil }

        switch character {
        case "×", "⋅", "x", "X":
            return "*"
        case "÷":
            return "/"
        default:
            return character
        }
    }
}
```

`parseNumber()`는 정수부를 먼저 읽고 쉼표 그룹을 검증한 뒤 선택적 소수부를 읽도록 교체한다.

```swift
mutating func parseNumber() -> Double? {
    let integerStartIndex = index

    while let current = peek(), current.isNumber || current == "," {
        index += 1
    }

    let integerText = String(characters[integerStartIndex..<index])
    guard isValidIntegerText(integerText) else { return nil }

    var numberText = integerText.replacingOccurrences(of: ",", with: "")

    if peek() == "." {
        numberText.append(".")
        index += 1

        while let current = peek(), current.isNumber {
            numberText.append(current)
            index += 1
        }
    }

    if numberText.last == "." {
        numberText.removeLast()
    }

    return Double(numberText)
}

func isValidIntegerText(_ text: String) -> Bool {
    let groups = text.split(separator: ",", omittingEmptySubsequences: false)
    guard !groups.isEmpty,
          groups.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else {
        return false
    }

    guard groups.count > 1 else { return true }
    guard (1...3).contains(groups[0].count) else { return false }
    return groups.dropFirst().allSatisfy { $0.count == 3 }
}
```

Step 1과 같은 집중 테스트 명령을 실행한다. 새 입력 테스트와 기존 evaluator 테스트가 모두
통과하는지 확인하고 통과 개수를 체크박스 아래에 기록한 뒤 커밋한다.

```sh
git add Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift \
  docs/superpowers/plans/2026-07-27-math-expression-number-formatting.md
git commit -m "feat: #98 - 수식 숫자 입력과 연산자 기호 확장"
```

---

### Task 2: 일반 결과 그룹 표기와 큰 수 과학 표기

**Files:**
- Modify: `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift:83-93`
- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift:45-62`
- Modify: `docs/superpowers/plans/2026-07-27-math-expression-number-formatting.md`

**Interfaces:**
- Consumes: `MathExpressionParser.evaluate() -> Double?`
- Produces: `MathExpressionCompletionEvaluator.formattedResult(_:) -> String?`가 쉼표 decimal 또는 유효숫자 4자리 scientific 문자열을 반환

- [x] **Step 3: 결과 표시 회귀 테스트를 추가하고 RED를 확인해 커밋**

  - 결과: `iPhone 13 mini / iOS 16.0` 집중 테스트 16개 중 13개 통과, 3개 실패.
  - 실패: 일반 결과 쉼표 표기, 임계값 이상 과학 표기, 가수 반올림 시 지수 상승.
  - 확인: `Int` 범위를 넘는 유한 결과는 현재 `nil`이어서 `1×10²¹` 기대값이 실패함.

기존 `"정수 범위를 벗어나는 큰 결과는 후보를 만들지 않음"` 테스트를 제거하고 다음 테스트를
추가한다.

```swift
@Test("일반 결과는 천 단위 쉼표와 최대 소수 셋째 자리로 표시")
func test일반결과는_천단위쉼표와최대소수셋째자리로표시() {
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "1,000 * 1,000="
        )?.displayText == "1,000 * 1,000=1,000,000"
    )
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "1234567.8912+0="
        )?.insertText == "1,234,567.891"
    )
}

@Test("10의 10제곱 미만은 일반 표기하고 이상은 유효숫자 네 자리 과학 표기")
func test큰결과는_유효숫자네자리과학표기로표시() {
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "9999999999+0="
        )?.insertText == "9,999,999,999"
    )
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "10*1234567890="
        )?.insertText == "1.235×10¹⁰"
    )
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "-10*1234567890="
        )?.insertText == "-1.235×10¹⁰"
    )
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "999999999999999999999+1="
        )?.insertText == "1×10²¹"
    )
}

@Test("과학 표기 가수가 십으로 반올림되면 지수를 올림")
func test과학표기가수가십으로반올림되면_지수를올림() {
    #expect(
        MathExpressionCompletionEvaluator.completion(
            for: "99996000000+0="
        )?.insertText == "1×10¹¹"
    )
}
```

Step 1과 같은 집중 테스트 명령을 실행한다. 일반 결과 쉼표와 과학 표기가 아직 없어서 새 테스트가
실패하는지 확인하고 실패한 테스트 이름과 총 실패 개수를 기록한 뒤 커밋한다.

```sh
git add SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift \
  docs/superpowers/plans/2026-07-27-math-expression-number-formatting.md
git commit -m "test: #98 - 수식 결과 숫자 표기 회귀 테스트 추가"
```

- [x] **Step 4: 결과 포맷터를 분리 구현하고 GREEN을 확인해 커밋**

  - 결과: `iPhone 13 mini / iOS 16.0` 집중 테스트 16개 통과, 실패·건너뜀 0개.
  - 확인: 일반 쉼표, `10¹⁰` 임계값, 음수, `Int` 범위 초과 유한값, 가수 반올림 지수 상승 통과.
  - 경고: 외부 광고 SDK PCM 경로 경고가 있었으나 evaluator 빌드와 테스트 오류는 없음.

`formattedResult(_:)`를 다음 책임으로 분리한다.

```swift
static let scientificNotationThreshold = 10_000_000_000.0

static func formattedResult(_ value: Double) -> String? {
    guard value.isFinite else { return nil }

    if abs(value) >= scientificNotationThreshold {
        return scientificResult(value)
    }

    return decimalResult(value)
}

static func decimalResult(_ value: Double) -> String? {
    let roundedValue = (value * 1000).rounded() / 1000

    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = true
    formatter.groupingSeparator = ","
    formatter.groupingSize = 3
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3

    return formatter.string(from: NSNumber(value: roundedValue))
}
```

과학적 표기는 가수와 지수를 직접 계산하고 지수를 위 첨자로 변환한다.

```swift
static func scientificResult(_ value: Double) -> String? {
    var exponent = Int(floor(log10(abs(value))))
    let divisor = pow(10, Double(exponent))
    var mantissa = value / divisor
    mantissa = (mantissa * 1000).rounded() / 1000

    if abs(mantissa) >= 10 {
        mantissa /= 10
        exponent += 1
    }

    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = false
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 3

    guard let mantissaText = formatter.string(from: NSNumber(value: mantissa)),
          let exponentText = superscriptText(for: exponent) else {
        return nil
    }

    return "\(mantissaText)×10\(exponentText)"
}

static func superscriptText(for exponent: Int) -> String? {
    let characters: [Character: Character] = [
        "-": "⁻",
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
        "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"
    ]

    let result = String(String(exponent).compactMap { characters[$0] })
    return result.count == String(exponent).count ? result : nil
}
```

Step 1과 같은 집중 테스트 명령을 실행한다. 신규 결과 테스트와 기존 반올림·오류 테스트가 모두
통과하는지 확인하고 통과 개수를 기록한 뒤 커밋한다.

```sh
git add Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift \
  docs/superpowers/plans/2026-07-27-math-expression-number-formatting.md
git commit -m "feat: #98 - 수식 결과 그룹과 과학 표기 적용"
```

---

### Task 3: 전체 회귀 검증

**Files:**
- Modify: `docs/superpowers/plans/2026-07-27-math-expression-number-formatting.md`

**Interfaces:**
- Consumes: Task 1과 Task 2의 최종 evaluator 및 테스트
- Produces: 전체 테스트와 두 키보드 extension 빌드의 실제 검증 기록

- [x] **Step 5: 전체 테스트와 키보드 extension 빌드를 실행하고 결과를 커밋**

  - 대상: `iPhone 13 mini / iOS 16.0`.
  - 전체 `SYKeyboard` 테스트: 350개 통과, 실패·건너뜀 0개.
  - `HangeulKeyboard` 빌드: 성공. 외부 Meta SDK PCM 경로 경고가 있었으나 빌드 오류는 없음.
  - `EnglishKeyboard` 빌드: 성공, 경고·오류 없음.
  - `git diff --check`: 통과.
  - 실제 입력 앱 수동 검증: 미실행. 지원 기호 입력과 후보 확정 동작은 자동 테스트·빌드로만 확인.

다음 명령을 순서대로 실행한다.

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

`git diff --check`와 `git status --short`도 확인한다. 체크박스 아래에 각 명령의 실제 대상 기기,
OS, 테스트 통과·실패·건너뜀 개수, 빌드 성공 여부, 경고와 수동 검증 미실행 항목을 기록한다.

```sh
git add docs/superpowers/plans/2026-07-27-math-expression-number-formatting.md
git commit -m "docs: #98 - 수식 숫자 표기 검증 결과 기록"
```

수동 검증은 자동 테스트와 별도로 한글·영문 키보드를 실제 입력 앱에서 열어 지원 기호, 쉼표 원문,
일반 결과, 과학적 결과, 잘못된 입력의 후보 미표시를 확인한다. 물리 기기 또는 실제 입력 앱에서
확인하지 않았다면 완료로 표시하지 않고 최종 응답에 명시한다.

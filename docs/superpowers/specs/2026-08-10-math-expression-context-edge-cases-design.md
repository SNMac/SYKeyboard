# 수식 문맥 엣지케이스 인식 수정 설계

## 목적

수식 parser가 지원하는 유효한 수식이지만 선택 텍스트와 앞쪽 문서 문맥 때문에
자동완성 후보를 만들지 못하는 경우를 수정한다. 기존 숫자 검증, 연산자,
단항 부호 정책은 유지하며 정수부를 생략한 소수, 문맥 경계와 결과 표시만
최소 범위로 보강한다.

## 확정 동작

- 선택한 `3 + 1 =`처럼 공백이 포함된 유효한 수식도 수식 결과 후보를 표시한다.
- `hello world`처럼 공백이 포함된 일반 선택 텍스트는 기존처럼 후보를 지운다.
- `3+1=4 2+3=`에서 이전 등식과 결과 `3+1=4 `를 문맥으로 보존하고 마지막
  `2+3=`만 계산한다.
- `tax 2+3=`, `BOX 2+3=`에서 단어 끝 `x/X`를 곱셈 연산자로 오인하지 않고
  `2+3=`만 계산한다.
- `1\n2+3=`처럼 줄바꿈 뒤의 마지막 수식을 독립된 문맥으로 계산한다.
- `.5+1=`처럼 정수부를 생략한 소수를 0으로 시작하는 소수로 계산한다.
- 소수 셋째 자리 반올림 결과가 0이면 `-0`이 아닌 `0`으로 표시한다.

## 비목표와 기존 계약

- `(-3)+5=`, `2*(-3)=`처럼 수식 첫 문자 이외의 단항 부호를 새로 허용하지 않는다.
- `·`, `−`처럼 현재 지원 목록에 없는 연산자를 추가하지 않는다.
- `memo 2 3+1=`, `x 1 2+3=`, `1 + 2 3+4=`처럼 숫자 구성 문자 사이의
  공백으로 인한 애매한 입력은 계속 거부한다.
- 일반 자동완성, n-gram, 텍스트 대치, 수식 후보의 좌·중·우 action 의미는 변경하지
  않는다.

## Root cause

### 공백이 포함된 선택 수식

`MathExpressionCompletionEvaluator`는 연산자 주변 공백을 허용하지만,
`KeyboardSuggestionSelectionPolicy.suggestionUpdateAction` 은 공백이 하나라도 있는
선택 텍스트를 모두 `.clear`로 변환한다. `BaseKeyboardViewController`가 `.clear`에서
`SuggestionController` 호출을 생략하므로 유효한 수식이 evaluator에 도달하지 못한다.

### 마지막 수식 suffix 오염

`expressionSuffix(beforeEqualIn:)`는 지원 문자와 모든 whitespace를 뒤에서부터 최대한
수집한다. 따라서 이전 등식의 `=`, 줄바꿈 앞 숫자, 일반 단어의 끝 `x/X`가
실제 마지막 수식과 함께 추출된다. 현재 fallback은 전체 입력이 숫자와 ASCII
공백 문맥인 경우만 다시 나누므로 이 문맥에서 마지막 유효 수식을 복구하지
못한다.

### 음수 0 표시

`decimalResult(_:)`가 음수 소수를 셋째 자리에서 0으로 반올림해도 `Double` 내부의
음수 0 부호를 그대로 `NumberFormatter`에 전달한다.

### 정수부를 생략한 소수

`MathExpressionParser.parseNumber()`는 소수점 앞의 정수 token을 먼저 읽고
`isValidIntegerText(_:)`로 검증한다. `.5`는 정수 token이 비어 있어 소수부를
읽기 전에 거부된다.

## 설계

### 선택 텍스트 갱신 정책

`KeyboardSuggestionSelectionPolicy.suggestionUpdateAction`은 공백이 포함된 선택 텍스트만
`MathExpressionCompletionEvaluator.completion(for:)`로 유효한 수식인지 판정해 다음처럼
분기한다.

- 선택 텍스트에 공백이 없음: 기존처럼 `.update(selectedText)`
- 공백이 있고 유효한 수식임: `.update(selectedText)`
- 공백이 있고 수식이 아님: 기존처럼 `.clear`

일반 다중 단어 선택을 자동완성 입력으로 넘기지 않는 기존 계약을 보존한다.

### suffix 후보 생성

이 문역에서는 parser 책임을 변경하지 않고 `expressionSuffixCandidates(beforeEqualIn:)`가
다음 순서로 최소
후보만 추가한다.

1. 현재와 같은 최대 suffix
2. 마지막 줄바꿈 뒤 suffix
3. 최대 suffix의 시작 `x/X`가 직전 일반 글자와 연속된 단어 끝임이 확인된
   경우, 그 `x/X` 뒤 첫 공백 다음 suffix
4. 최종 `=` 앞에 이전 `=`가 있고, 이전 `=` 뒤의 하나의 결과 token과 다음
   수식이 공백으로 분리된 경우의 suffix
5. 기존과 같은 전체 숫자·ASCII 공백 문맥 fallback

후보는 중복을 제거하고 위 순서로 기존 validation과 parser에 전달한다. 이전 등식
경계는 `=` 뒤에 결과 token이 하나만 존재할 때만 허용해
`3+1=4 2 3+4=`를 `3+4=`로 잘못 해석하지 않는다.

### 음수 0 정규화

소수 셋째 자리 반올림 후의 값이 0과 같으면 formatter에 양수 0을 전달한다.
기존 반올림 자릿수와 다른 숫자 표시는 변경하지 않는다.

### 선행 소수점 숫자 parsing

`parseNumber()`는 정수 token이 비어 있고 현재 문자가 `.`인 경우 0을 정수부로
보완한다. 이 경우에는 소수점 뒤에 숫자가 최소 한 자리 있어야 한다.

- `.5` → `0.5`
- `-.5` → `-0.5`
- `.` 단독, `.+1=`, `..5+1=`, `1..5+1=` → 거부
- 정수부가 있는 `1.`은 기존처럼 `1`로 계산

## 변경 범위

- Modify: `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift`
  - 문맥 경계 suffix 후보, 선행 소수점 parsing, 음수 0 정규화를 추가한다.
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`
  - 공백 선택의 수식 여부를 갱신 action에 반영한다.
- Modify: `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift`
  - 문맥 경계, 오탐지 방지, 음수 0 회귀를 검증한다.
- Modify: `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`
  - 수식과 일반 공백 선택을 구분한다.
- Modify: `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift`
  - 공백이 포함된 selection-origin 좌·중·우 action과 문맥 suffix를 검증한다.

## 테스트

Swift Testing으로 다음 입력을 production 진입점에서 검증한다.

### 정상 인식

- `3 + 1 =` 선택 → `3 + 1 =4`, `4` 선택 action
- `3+1=4 2+3=` → `expressionText == "2+3="`, `insertText == "5"`
- `tax 2+3=`, `BOX 2+3=` → `expressionText == "2+3="`
- `1\n2+3=`, `memo 1\n2+3=` → `expressionText == "2+3="`
- `.5+1=` → `insertText == "1.5"`
- `-.5+1=` → `insertText == "0.5"`
- `-0.0001+0=` → `insertText == "0"`

### 오탐지 방지

- `hello world` 선택 → `.clear`
- `memo 2 3+1=`, `x 1 2+3=`, `1 + 2 3+4=` → 후보 없음
- `3+1=4 2 3+4=` → 후보 없음
- `1=2+3=`, `3+1=4=` → 후보 없음
- `.+1=`, `..5+1=`, `1..5+1=` → 후보 없음

## 검증

1. 신규 evaluator 및 selection policy 테스트가 현재 production 코드에서 예상한 이유로
   실패하는 RED를 확인한다.
2. 최소 구현 후 `MathExpressionCompletionEvaluatorTests`,
   `KeyboardSuggestionSelectionPolicyTests`, `SuggestionControllerMathResultsTests`를 통과시킨다.
3. `SYKeyboard` 전체 테스트를 `iPhone 13 mini / iOS 16.0`에서 실행한다.
4. `HangeulKeyboard`, `EnglishKeyboard` scheme을 같은 simulator에서 빌드한다.
5. 실제 입력 앱 확인을 수행하지 못하면 자동 검증과 수동 미확인 범위를 분리해
   기록한다.

## 완료 조건

- 확정 동작의 모든 수식이 결과 후보와 올바른 action을 만든다.
- 기존 애매한 숫자 공백, 연속 등호, 미지원 연산자·단항 부호 입력은 계속
  거부한다.
- 일반 다중 단어 선택과 기존 수식 좌·중·우 action에 회귀가 없다.
- 집중 테스트, 전체 테스트, 두 keyboard extension 빌드가 통과한다.

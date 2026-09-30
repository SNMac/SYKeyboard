# 수식 자동완성 앞쪽 숫자 문맥 분리 설계

## 목적

사용자가 같은 입력 세션에서 앞쪽 숫자 문맥 뒤에 완성된 수식을 입력했을 때
마지막 수식만 계산한다.

```text
1 2 + 3 =  →  expressionText: "2 + 3 =", displayText: "2 + 3 =5"
1 2+3=      →  expressionText: "2+3=", displayText: "2+3=5"
```

앞의 `1 `은 계산 대상이 아니다. 가운데 후보는 기존처럼 결과를 등호 뒤에
삽입하고, 오른쪽 후보는 마지막 수식만 결과로 대치해야 한다.

## Root cause

`MathExpressionCompletionEvaluator.expressionSuffix(beforeEqualIn:)`는 숫자와
연산자뿐 아니라 모든 whitespace를 허용한다. 따라서 위 입력의 최대 suffix는
각각 `1 2 + 3 =`, `1 2+3=`이 된다.

그 뒤 `containsWhitespaceBetweenNumberComponents(_:)`가 `1`과 `2` 사이 공백을
숫자 구성 문자 사이 공백으로 판단해 전체 evaluation을 중단한다. 독립적으로
유효한 마지막 수식 후보를 다시 찾지 않기 때문에 수식 결과 후보가 표시되지
않는다.

## 선택한 방식

기존 최대 suffix를 가장 먼저 평가한다. 최대 suffix가 실패한 경우에만 다음
조건을 모두 만족하는 일반 ASCII 공백 뒤의 suffix를 왼쪽부터 차례로 평가한다.

1. 최대 suffix가 선행 문자 문맥에서 잘려 나온 것이 아니라 입력 전체를
   대표한다.
2. 후보 앞 문맥은 십진 숫자와 일반 ASCII 공백만 포함한다.
3. 공백 바로 앞과 다음 비공백 문자는 모두 숫자다.
4. 후보 suffix 자체가 기존 parser와 validation을 모두 통과한다.

이 제한으로 이번 숫자 문맥을 분리하면서 이전 계약을 보존한다.

```text
1 . 2+3=       → 거부
1, 000+2=      → 거부
1<TAB>2+3=     → 거부
1<NBSP>2+3=    → 거부
memo 2 3+1=    → 거부
```

연산자·괄호 주변 일반 공백은 최대 suffix가 먼저 성공하므로 기존처럼 허용한다.

## 변경 범위

- `Modules/SYKeyboardCore/Domain/MathExpressionCompletionEvaluator.swift`
  - 최대 suffix와 제한된 trailing 후보를 순서대로 평가한다.
- `SYKeyboardTests/Domain/MathExpressionCompletionEvaluatorTests.swift`
  - 두 사용자 재현 입력과 기존 공백 거부 회귀를 검증한다.
- `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift`
  - 실제 좌·중·우 표시와 오른쪽 후보의 suffix 삭제 길이를 검증한다.

`SuggestionController`, `BaseKeyboardViewController`, 일반 자동완성, 텍스트 대치,
selection-origin action 계약은 변경하지 않는다.

## 완료 기준

- `1 2 + 3 =`의 수식 후보가 `"2 + 3 ="`, `2 + 3 =5`, `5`로 표시된다.
- `1 2+3=`의 수식 후보가 `"2+3="`, `2+3=5`, `5`로 표시된다.
- 두 입력의 오른쪽 action은 앞의 `1 `을 보존하고 수식 suffix만 대치한다.
- 소수점·쉼표·TAB·NBSP와 문자 문맥 뒤 숫자 사이 공백 거부는 유지된다.
- 관련 집중 테스트와 전체 테스트, 두 키보드 extension 빌드가 통과한다.

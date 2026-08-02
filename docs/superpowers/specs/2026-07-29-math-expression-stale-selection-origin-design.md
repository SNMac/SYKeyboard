# 수식 후보 stale selection origin 방지 설계

## 목적

selection에서 생성된 수식 후보가 선택 해제나 커서 이동 뒤에도 미선택 수식
후보처럼 적용되는 문제를 막는다. 후보 생성 당시 origin과 선택 문자열을
`SuggestionController`가 보존하고, action 요청 시점의 selection이 그 origin과
일치할 때만 편집 action을 반환한다.

이번 변경은 stale selection 문제만 다룬다. 일반 자동완성, 텍스트 대치,
undo/redo, `inputBuffer`, 자동완성 후보 스크롤 롤백 및 기존 수식 계산 규칙은
변경하지 않는다.

## Root cause

`KeyboardSuggestionSelectionPolicy.suggestionUpdateAction`은 선택 텍스트와 일반
입력 버퍼를 모두 `.update(String)`으로 축약한다. 이후
`BaseKeyboardViewController`는 해당 문자열만
`SuggestionController.updateSuggestions(for:)`에 전달한다.

`SuggestionController`는 현재 수식의 기준 문자열과 계산 결과는 저장하지만,
후보가 selection에서 생성됐는지는 저장하지 않는다. 따라서
`mathResultAction(at:selectedText:)`가 호출될 때 `selectedText`가 `nil` 또는 빈
문자열이면 이를 미선택 수식으로 해석한다. selection에서 생성된 후보가 아직
화면에 남아 있는 동안 사용자가 선택을 해제하거나 커서를 이동하면 가운데,
오른쪽 후보 또는 스페이스가 새 커서 위치에 삽입·삭제를 수행할 수 있다.

preview, 후보 탭, 스페이스는 이미
`mathResultAction(at:selectedText:)`을 공통으로 호출한다. 결함은 action 실행
경로가 아니라 후보 생성 origin이 action 계약에 보존되지 않는 데 있다.

## 선택한 방식

후보 갱신 시점의 `selectedText`를 `SuggestionController`에 함께 전달하고,
수식 후보가 생성될 때 다음 private origin 상태로 정규화해 저장한다.

```swift
private enum MathSuggestionOrigin: Equatable {
    case unselected
    case selection(String)
}
```

- `selectedText == nil` 또는 `selectedText == ""`이면 `.unselected`다.
- 비어 있지 않은 `selectedText`이면 `.selection(selectedText)`다.
- origin은 수식 후보에만 연결하며 일반 후보의 의미에는 사용하지 않는다.

`SuggestionService`의 후보 갱신 계약은 현재 선택 snapshot을 함께 받도록
확장한다.

```swift
func updateSuggestions(
    for baseText: String,
    selectedText: String?
)
```

기존 테스트와 selection이 없는 내부 호출에는 한 인자 convenience를 유지한다.

```swift
extension SuggestionService {
    func updateSuggestions(for baseText: String) {
        updateSuggestions(for: baseText, selectedText: nil)
    }
}
```

한 인자 convenience는 `SuggestionService` protocol extension에만 정의한다.
따라서 `SuggestionController`를 concrete type으로 사용하는 기존 호출도
selection이 없는 `.unselected` 요청으로 동일하게 처리된다.

`BaseKeyboardViewController.updateSuggestions()`와
`updateSuggestionsForCursorContext()`는 `textDocumentProxy.selectedText`를 한 번
읽어 snapshot을 만들고, 같은 값을 selection policy와 `SuggestionController`에
전달한다. selection 판단과 origin 기록 사이에 서로 다른 값을 읽지 않는다.

## Origin-aware action 계약

`mathResultAction(at:selectedText:)`은 현재 selection과 저장된 origin을 먼저
검증한다.

| 후보 생성 origin | 현재 `selectedText` | 결과 |
| --- | --- | --- |
| `.selection("3+1=")` | `"3+1="` | 기존 exact selection action |
| `.selection("memo3+1=")` | `"memo3+1="` | 기존 prefix selection action |
| `.selection(...)` | `nil` | 모든 index에서 `nil` |
| `.selection(...)` | `""` | 모든 index에서 `nil` |
| `.selection(...)` | 다른 문자열 | 모든 index에서 `nil` |
| `.unselected` | `nil` | 기존 미선택 action |
| `.unselected` | `""` | 기존 미선택 action |
| `.unselected` | 비어 있지 않은 문자열 | 모든 index에서 `nil` |

selection-origin의 exact match가 확인된 뒤에만 기존 prefix 계산을 수행한다.

- 선택된 `3+1=`:
  - 왼쪽: `.confirmOriginal`
  - 가운데: `.replaceSelection("3+1=4")`
  - 오른쪽: `.replaceSelection("4")`
- 선택된 `memo3+1=`:
  - 왼쪽: `.confirmOriginal`
  - 가운데: `.replaceSelection("memo3+1=4")`
  - 오른쪽: `.replaceSelection("memo4")`
- 미선택 `3+1=`:
  - 왼쪽: `.confirmOriginal`
  - 가운데: `.insertResult("4")`
  - 오른쪽: `.replaceExpression(deleteCount: 4, insertText: "4")`

origin 검증은 source별 switch보다 먼저 수행한다. 따라서 selection-origin이
stale이면 원문 확인을 포함한 좌·중·우 action이 모두 `nil`이다.

## 상태 수명

origin은 표시 중인 수식 후보와 동일한 수명을 갖는다.

- 수식 후보 생성 성공: 현재 update snapshot으로 origin 설정
- 다음 후보 갱신이 비수식 모드 생성: origin 제거
- `updateSuggestionsAfterNGramSelection`: unselected snapshot으로 갱신하고
  수식 origin 제거
- `clearSuggestions()`: origin 제거
- 지연된 n-gram load 후 재갱신: 마지막 base text와 마지막 origin snapshot을
  함께 사용해 origin을 임의로 바꾸지 않음

`currentMathCompletion`과 origin 중 하나라도 없으면 수식 action을 반환하지
않는다.

## 공통 호출 경로

preview, 후보 탭, 스페이스는 각각 현재 selection snapshot을
`mathResultAction(at:selectedText:)`에 전달한다.

```text
현재 selectedText
    └─ mathResultAction(at:selectedText:)
        ├─ preview highlight
        ├─ suggestion tap
        └─ space
```

stale selection에서는 세 경로가 모두 `nil` action을 받는다.

- preview는 수식 가운데 후보를 강조하지 않는다.
- 후보 탭은 수식 후보가 stale인 상태에서 일반 후보 처리로 fallthrough하지
  않고 편집 없이 종료한다.
- 스페이스는 stale 수식 action을 적용하지 않는다. 이후 기존 일반 스페이스
  흐름만 수행하며 stale 수식의 삽입·삭제는 수행하지 않는다.

기존 `applyMathResultSuggestionAction`과 selection 대치는 유지한다. 확정 대치는
`UITextDocumentProxy.insertText`를 사용하고 `setMarkedText`는 사용하지 않는다.

## 변경 범위

- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`
  - 후보 생성 시점 selection snapshot을 전달하는 update 계약을 정의한다.
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
  - 수식 후보 origin을 저장·검증·초기화한다.
- Modify:
  `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - 같은 selection snapshot을 policy와 suggestion service에 전달한다.
- Modify: `SYKeyboardTests/Domain/SuggestionControllerMathResultsTests.swift`
  - stale selection, exact/prefix 보존, unselected 보존, 갱신/clear 초기화를
    실제 action 결과로 검증한다.

`KeyboardSuggestionSelectionPolicy`, 수식 evaluator/parser, undo/redo,
`inputBuffer` 조작, 후보 스크롤 구현은 변경하지 않는다.

## TDD

production 변경 전에 다음 실패 테스트를 추가한다.

1. selection-origin `3+1=` + 현재 selection `nil`은 좌·중·우 모두 `nil`
2. selection-origin `3+1=` + 현재 selection `""`은 좌·중·우 모두 `nil`
3. selection-origin `memo3+1=` + 다른 selection은 좌·중·우 모두 `nil`
4. selection-origin exact/prefix selection 유지 시 기존 action 유지
5. unselected-origin `3+1=` + selection `nil`은 기존 가운데·오른쪽 action 유지
6. selection-origin 뒤 unselected 수식 갱신 시 새 origin으로 교체
7. clear 뒤 unselected 수식 갱신 시 origin이 남지 않음
8. 비수식 갱신 뒤 모든 수식 action이 `nil`

RED는 새 update 계약 부재 또는 stale selection에서 기존 action이 반환되는
실패여야 한다. GREEN은 최소 origin 상태와 guard만 구현해 만든다.

## 검증

다음 검증을 iPhone 13 mini / iOS 16.0에서 수행한다.

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests
```

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

정적 검증:

```sh
git diff --check
rg -n "hasSelectedText" Modules/SYKeyboardCore SYKeyboardTests
rg -n "setMarkedText" Modules Keyboards
```

## 완료 기준

- selection-origin 후보는 생성 당시 selection과 현재 selection이 정확히 같을
  때만 action을 반환한다.
- selection-origin 후보가 stale이면 preview, 후보 탭, 스페이스가 수식
  삽입·삭제를 수행하지 않는다.
- exact/prefix selection과 unselected 수식의 기존 좌·중·우 의미를 유지한다.
- origin 상태는 후보 갱신과 clear 뒤 올바르게 초기화된다.
- `UITextDocumentProxy` mock과 DEBUG 전용 production API를 추가하지 않는다.
- 확정 대치는 계속 `insertText`를 사용하고 production 코드에
  `setMarkedText`를 추가하지 않는다.
- 집중 suite, 전체 `SYKeyboard` 테스트, 두 extension 빌드와 정적 검증이
  통과한다.

# 띄어쓰기·개행 없이 보낸 마지막 단어 NGram 학습 설계

- 작성일: 2026-09-28
- 이슈: #164
- 브랜치: `feat/#164-ngram-sent-last-word`

## 목표

스페이스나 리턴 없이 앱의 전송 버튼으로 보낸 마지막 단어도 NGram에 학습한다. `ㅇㅇ`처럼 단어 하나만
보내는 경우도 포함한다.

- 저장 위치와 형식은 스페이스로 기록한 단어와 같다(`ngram_{ko-KR,en-US,ko-en}.plist`).
- unigram과, 같은 문장 앞 단어와의 bigram·trigram으로 기록한다.
- `UITextChecker` 학습 목록(`learnedWords`)에는 넣지 않는다. 현재 단어 후보를 직접 누를 때만 넣는
  기존 규칙을 유지한다.
- 입력창 이동, 키보드 닫기, 전체 선택 뒤 삭제·잘라내기에서는 학습하지 않는다.

## 현재 동작

- 단어는 두 경로에서만 기록한다. 스페이스(`insertSpaceText()` → `recordUncommittedWords(from:)`)와
  리턴(`insertReturnText()` → `endSentence(inputBuffer:)`)이다.
- 전송 버튼을 누르면 앱이 입력창을 비우고 키보드에 `textWillChange(_:)`가 온다. 이때
  `BaseKeyboardViewController.textWillChange(_:)`의 `resetInputBuffer()`가 `inputBuffer`와 NGram
  문장 버퍼(`currentSentenceWords`)를 함께 비워, 아직 기록하지 않은 단어를 버린다.
- `endSentence(inputBuffer:)`는 문장 버퍼의 단어 수만큼을 "이미 기록함"으로 보고 나머지만 기록한다.
  그래서 리셋 뒤에는 앞 단어와의 bigram 문맥도, 이미 기록한 단어 수도 남지 않는다.

## 관찰 결과

관찰용 임시 로그로 `textWillChange`·`textDidChange`·`viewWillDisappear`에서 문맥, 선택 텍스트,
`inputBuffer`, `textDocumentProxy.documentIdentifier`, 입력 특성을 남겨 확인했다. 로그 코드는 커밋하지
않았다.

- 환경: 실기기 SNMac's iPhone(iPhone 15 Pro Max)의 카카오톡, 시뮬레이터 iPhone 13 mini / iOS 18.6의
  메시지 앱(기본 더미 대화 `+1 (888) 555-1212`)
- 실기기 로그 수집: `log collect --device-udid <UDID> --last 1h` 뒤
  `log show <archive> --predicate 'eventMessage CONTAINS "[#164probe]"'`

`textWillChange` 바로 뒤에 오는 첫 `textDidChange`의 값은 다음과 같다.

| 동작 | 앱 | 첫 `textDidChange`의 문맥·선택 | `documentIdentifier` |
|---|---|---|---|
| 스페이스 없이 전송(`ㅇㅇ`) | 카카오톡, 메시지 | 모두 비어 있음 | `textWillChange` 때와 같음 |
| 스페이스 포함 전송(`안녕 ㅋㅋ`) | 카카오톡 | 모두 비어 있음 | 같음 |
| 전체 선택 → 키보드 삭제 | 카카오톡 | `after`에 텍스트가 남아 있음 | 같음 |
| 전체 선택 → 잘라내기 | 카카오톡 | `after`에 텍스트가 남아 있음 | 같음 |
| 비어 있는 다른 입력창으로 이동 | 카카오톡 | 모두 비어 있음 | nil |
| 키보드 내리기 | 카카오톡 | 모두 비어 있음(`viewWillDisappear` 뒤) | nil |

- 문맥이 비었는지만 보면 입력창 이동과 키보드 닫기를 전송으로 오인한다. 시뮬레이터 메시지 앱에서
  본문을 친 뒤 받는 사람 칸으로 옮겼을 때도 같은 모양이었다.
- 우리 키보드로 글자를 입력할 때는 `textWillChange`가 오지 않는다.
- 선택 텍스트는 `nil`과 `""`가 섞여 온다. 키보드가 처음 뜰 때의 `textWillChange`는 `selectedText == ""`다.
- `documentIdentifier`는 헤더에 nonnull로 선언돼 있지만 nil이 온다. 키보드가 처음 뜰 때의
  `textWillChange`와 입력창이 바뀌는 순간이 그렇다. Swift에서 그대로 읽으면
  `UUID._unconditionallyBridgeFromObjectiveC`에서 크래시한다(관찰 빌드에서 실제로 발생).
- 확인하지 못한 것: 인스타그램 DM(실제 상대에게 보내야 해서 제외), 메시지 앱의 선택·잘라내기·입력창
  이동 때의 `documentIdentifier`

## 결정 사항

| 항목 | 결정 |
|---|---|
| 전송 판정 | 첫 `textDidChange`에서 문맥·선택이 모두 비어 있고, `documentIdentifier`가 `textWillChange` 때와 같으며 nil이 아님 |
| 문장 문맥 | `textWillChange`에서 리셋 직전에 스냅샷을 떠 두고, 전송으로 판단될 때만 복원해 기록 |
| 기존 리셋 | `resetInputBuffer()`의 호출 위치와 순서는 바꾸지 않는다 |
| `learnedWords` | 넣지 않는다 |
| 놓치는 경우 | 보낸 뒤 입력창을 새로 만드는 앱은 `documentIdentifier`가 달라 학습하지 않는다. 잘못 학습하는 것보다 놓치는 쪽을 택한다 |

채택하지 않은 방식:

- 문맥만 보는 판정(이슈 원안): 입력창 이동·키보드 닫기 때 반쯤 친 단어를 학습한다.
- 문장 버퍼 리셋을 `textDidChange`까지 미루기: 기존 리셋 타이밍이 바뀌고, 콜백 사이에 입력이 끼거나
  `textDidChange`가 오지 않으면 문장 버퍼와 `inputBuffer`의 단어 수가 어긋나 다음 스페이스에서 단어를
  빠뜨린다.
- 문맥 없이 새 문장으로 기록: 같은 문장 앞 단어와의 bigram·trigram을 잃는다.

## 판정 Policy

`Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSentTextDetectionPolicy.swift`에 UI 의존 없는
순수 타입을 둔다.

```swift
enum KeyboardSentTextDetectionPolicy {
    static func isSentAfterTextChange(
        documentIdentifierBeforeChange: UUID?,
        documentIdentifierAfterChange: UUID?,
        beforeInput: String?,
        afterInput: String?,
        selectedText: String?
    ) -> Bool
}
```

- 두 `documentIdentifier`가 모두 nil이 아니고 같아야 한다.
- `beforeInput`, `afterInput`, `selectedText`가 모두 `nil` 또는 `""`여야 한다.

## VC 흐름

`BaseKeyboardViewController`에 private 스냅샷 하나를 둔다. 스냅샷에는 `inputBuffer`, NGram 문장 버퍼
단어들, `documentIdentifier`가 들어간다.

- `textWillChange(_:)`: `resetInputBuffer()` 직전에, `inputBuffer`에 공백이 아닌 글자가 있을 때만 스냅샷을
  만든다. 없으면 스냅샷을 nil로 둔다. 이후 처리는 지금과 같다.
- `textDidChange(_:)`: 스냅샷을 꺼내 비운다. 바로 다음 한 번만 본다. Policy가 전송으로 판단하면
  `suggestionController.endSentence(inputBuffer:restoringSentenceWords:)`를 부른다. 호출 위치는 trait
  동기화 직후지만 순서에 기대는 이유는 없다. 한영 통합 키보드는 NGram 엔진 하나(`ko-en`)를 쓰고 언어를
  바꿔도 엔진이 바뀌지 않으며, 단일 언어 키보드는 언어를 바꾸지 않는다.
- `viewWillDisappear(_:)`: 스냅샷을 버린다.
- `documentIdentifier`는 `UUID?`를 돌려주는 private helper로 읽는다.
  `(textDocumentProxy as AnyObject).value(forKey: "documentIdentifier") as? UUID`처럼 KVC를 거쳐 nil을
  안전하게 받는다.

`textDidChange`가 오지 않아도 스냅샷은 다음 `textWillChange`에서 덮어쓰이거나 `viewWillDisappear`에서
버려진다. 문장 버퍼는 이미 리셋된 상태라 단어 수가 어긋나지 않는다.

## SuggestionController와 NGram 엔진

`NGramPredictiveTextProviding`과 `NGramPredictiveTextEngine`:

- `currentSentenceWords`를 읽기 전용으로 드러낸다(`private` → `private(set)`, 프로토콜에 `{ get }`).
  `currentSentenceWordsCount`는 그대로 둔다.
- `restoreSentenceBuffer(_ words: [String])`를 추가한다. 문장 버퍼를 바꾸기만 하고 기록·저장은 하지 않는다.

`SuggestionService`와 `SuggestionController`:

- `sentenceWordsSnapshot() -> [String]`: 엔진이 없으면 `[]`
- `endSentence(inputBuffer:restoringSentenceWords:)`: `isPredictiveTextEnabled`, `!isSuspended` 가드 →
  엔진 준비 → 문장 버퍼 복원 → `recordUncommittedWords(from:)` → `nGramEngine.endSentence()`. 기록 코드는
  리턴 경로와 같다.

예: `안녕 ㅋㅋ` 전송

1. 스페이스 때 `안녕`을 기록한다. 문장 버퍼 `["안녕"]`
2. `textWillChange`: 스냅샷(`"안녕 ㅋㅋ"`, `["안녕"]`, doc)을 뜨고 지금처럼 리셋한다
3. `textDidChange`: 전송으로 판단하면 `["안녕"]`을 복원하고 `ㅋㅋ`만 기록한다(unigram `ㅋㅋ`,
   bigram `안녕→ㅋㅋ`). `안녕`을 두 번 세지 않는다

저장 형식과 키는 바뀌지 않으므로 마이그레이션은 필요 없다.

## 테스트

| 대상 | 파일 | 확인하는 것 |
|---|---|---|
| 판정 Policy | `SYKeyboardTests/Utils/KeyboardSentTextDetectionPolicyTests.swift` | 관찰한 경우: 같은 doc + 모두 빔 → 전송 / doc nil(이동·닫기) → 아님 / 다른 doc → 아님 / `after`나 `selected`에 텍스트 → 아님 / `""`는 빈 것 / `textWillChange` 쪽 doc nil → 아님 |
| SuggestionController | `SYKeyboardTests/Domain/SuggestionControllerSentTextTests.swift` | `["안녕"]` 복원 뒤 `"안녕 ㅋㅋ"`로 끝내면 `ㅋㅋ`만 추가되고 문장이 끝남 / 예측 입력이 꺼졌거나 중단 상태면 아무것도 하지 않음 |
| NGram 엔진 | `SYKeyboardTests/Domain/NGramPredictiveTextEngineSentenceBufferTests.swift` | 실제 엔진에서 `restoreSentenceBuffer(["안녕"])` → `addWord("ㅋㅋ")` 뒤 `"안녕 "` 다음 후보에 `ㅋㅋ` |

VC 연결은 자동 테스트로 고정하지 않는다. 테스트 호스트에서 `textDocumentProxy`를 바꿀 수 없고
`ForTesting` 메서드는 두지 않는다. 판정과 기록은 각각 위 테스트가 맡고, 둘을 잇는 VC 코드는 수동으로
확인한다.

## 수동 확인

시뮬레이터 iPhone 13 mini / iOS 18.6의 메시지 더미 대화와 실기기 카카오톡에서 확인한다. 시뮬레이터의
입력창 포커스와 전송 버튼은 idb 탭이 먹지 않아 직접 클릭한다.

1. `ㅇㅇ` 전송 뒤 `ㅇ` 입력 → 완성 후보에 `ㅇㅇ`
2. `안녕 ㅋㅋ` 전송 뒤 `안녕 ` 입력 → 다음 단어 후보에 `ㅋㅋ`
3. `이동` 입력 뒤 다른 입력창으로 이동, 키보드 내리기 → `이` 입력 때 `이동`이 후보에 없음
4. 전체 선택 → 삭제로 비우기 → 학습하지 않음
5. 기존 동작: 스페이스·리턴 학습, 커서 이동 뒤 입력이 전과 같음

## 회귀 확인

- 전체 `SYKeyboardTests`
- `SYKeyboard`, `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` scheme 빌드

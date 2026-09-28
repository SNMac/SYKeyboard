# 커서 앞 문맥 기준 자동완성 설계

- 작성일: 2026-09-28
- 이슈: #164(같은 브랜치에서 이어서 작업)
- 브랜치: `feat/#164-ngram-sent-last-word`

## 목표

커서를 옮긴 뒤에도 커서 바로 앞 단어에 맞는 후보를 보여 준다.

- 단어 중간(`가|나`)에서는 커서 앞 글자(`가`)로 시작하는 완성 후보를 보여 준다.
- 공백 뒤(`가나 |`)에서는 앞 단어(`가나`) 다음 단어 예측을 보여 준다.
- 이어서 입력하면(`가` + `방`) 커서 앞 단어 전체(`가방`)를 기준으로 한다.
- 완성 후보를 누르면 커서 앞 조각만 바꾼다. `가|나`에서 `가방`을 누르면 `가방|나`가 된다.
- 학습은 이 키보드로 직접 친 글자만 한다. 앞 글자에 붙어 시작한 조각(`가` 뒤에 친 `방`)은 학습하지 않는다.

## 현재 동작

- 일반 후보의 기준 텍스트는 `inputBuffer`뿐이다
  (`KeyboardSuggestionSelectionPolicy.suggestionUpdateAction`, `BaseKeyboardViewController.updateSuggestionsForCurrentContext()`).
- 커서를 옮기면 `textWillChange`나 `primaryButtonPanning`에서 버퍼가 비므로 빈 문맥 후보(자주 쓴 단어)가 나온다.
- 이력:
  - `0a0526a2`(#67): 커서 드래그가 끝나면 `documentContextBeforeInput`으로 후보를 갱신하도록 추가했다.
  - `e9563d55`(#98, "수식 유한성과 일반 추천 범위 보존"): 일반 후보를 `inputBuffer`로 한정했다. 커서 문맥은
    수식 탐지에만 남겼다. 문서에 남은 이유는 없고, 테스트 이름으로 보아 후보는 커서 문맥에서 나오는데 교체
    범위는 버퍼 기준인 불일치를 막으려던 것으로 보인다. 이번 설계는 교체 범위를 기준 텍스트에 맞춰 이 결정을
    되돌린다(사용자 확인, 2026-09-28).
- 텍스트 대치(단축어)는 버퍼 기준이며, 커서 문맥을 넘기지 않는 것을 #98 테스트가 고정한다. 이번에도 유지한다.

## 결정 사항

| 항목 | 결정 |
|---|---|
| 기준 텍스트 범위 | 항상 커서 앞 문맥(최대 256자). 입력창을 열 때 기존 텍스트 기준 예측도 나온다 |
| 기준 텍스트 계산 | 버퍼가 비면 그 순간의 커서 앞 문맥. 버퍼에 첫 글자가 들어갈 때 커서 앞 문맥을 `앞 문맥`으로 한 번 떠 두고, 입력 중에는 `앞 문맥 + 버퍼`의 끝 256자 |
| 완성 후보 탭 | 기준 텍스트의 마지막 단어 길이만큼 교체 |
| 텍스트 대치 | 버퍼 기준 그대로. 교체 길이도 버퍼 마지막 단어 길이 |
| 다음 단어 예측 탭의 앞 공백 | 기준 텍스트가 비지 않았고 공백으로 끝나지 않을 때 넣음 |
| 학습 | 앞 문맥이 공백이 아닌 글자로 끝나면 버퍼 첫 단어는 조각으로 보고 학습하지 않음(스페이스·리턴·전송·현재 단어 확정) |
| 후보로 고른 단어 | 후보는 실제 단어라 지금처럼 `recordWord`로 학습 |

채택하지 않은 방식:

- 매 키 입력마다 프록시 문맥을 기준으로 쓰기: 키보드가 `insertText`·`deleteBackward`를 부른 직후
  `documentContextBeforeInput`이 최신이라는 보장이 없다(삭제 직후 문맥을 따로 다루는 `deleteMutationLifecycle`,
  `RepeatDeleteMutationReliability.proxyContext`가 이미 있음). 빠르게 칠 때 후보가 늦거나 교체 길이가 어긋날 수 있다.
- 버퍼가 부족할 때만 문맥으로 보충: 체감 차이는 거의 없고 기준이 두 가지로 갈린다.
- 커서 앞 문맥을 합친 단어(`가방`)를 학습: 붙여넣은 링크, 앱이 채운 멘션, 다른 키보드로 친 텍스트에 한 글자만 덧붙여도
  전체가 학습된다. `inputBuffer`를 둔 이유와 부딪힌다.
- 커서가 걸친 단어 전체 교체(`가|나` → `가방|`): 뒤 글자를 지우는 새 동작이라 실수로 지울 위험이 있다.

## 기준 텍스트

`KeyboardSuggestionSelectionPolicy`에 순수 함수를 둔다.

```swift
/// 일반 후보(n-gram·TextChecker)의 기준 텍스트
static func generalSuggestionBaseText(
    leadingContext: String?,
    inputBuffer: String,
    documentContextBeforeInput: String?
) -> String

/// 버퍼 첫 단어가 앞 글자에 붙어 시작했는지
static func isInputBufferAttachedToLeadingContext(_ leadingContext: String?) -> Bool

/// 학습에 넘길 버퍼. 앞 글자에 붙은 첫 조각을 뺀다
static func learnableInputBuffer(_ inputBuffer: String, isAttachedToLeadingContext: Bool) -> String
```

- `generalSuggestionBaseText`
  - 버퍼가 비면 `limitedDocumentContextBeforeInput(documentContextBeforeInput)`
  - 버퍼가 있으면 `(leadingContext ?? "") + inputBuffer`의 끝 256자
  - 결과에서 마지막 줄바꿈 뒤만 쓴다. 리턴은 학습에서 문장 끝이라 윗줄 단어를 다음 단어 예측 문맥으로 쓰지 않고,
    리턴 직후 후보는 지금처럼 빈 문맥 후보다(리뷰에서 추가, 2026-09-28)
- `isInputBufferAttachedToLeadingContext`: `leadingContext`의 마지막 글자가 있고 공백이 아니면 참
- `learnableInputBuffer`: 조각이면 버퍼 앞의 공백이 아닌 글자들을 뺀다. `방 가방 ` → ` 가방 `, `방` → `""`.
  같은 규칙을 매번 적용하므로 `recordUncommittedWords`의 단어 수 비교가 어긋나지 않는다

VC(`BaseKeyboardViewController`) 상태:

- `inputBufferLeadingContext: String?`: `resetInputBuffer()`와 버퍼가 비는 삭제에서 nil로 둔다.
  버퍼가 빈 상태에서 첫 글자를 넣기 직전(`insertText`, `replaceText`, `replaceSelectedText`의 공통 경로)에
  `limitedDocumentContextBeforeInput(textDocumentProxy.documentContextBeforeInput)`로 채운다
- 교체(`replaceText`)가 지우는 글자 수가 버퍼보다 많으면, 넘친 글자 수만큼 앞 문맥 끝을 잘라낸다. 버퍼가 빈 상태의
  교체는 위 규칙으로 앞 문맥을 뜬 뒤 지우는 글자 수 전체만큼 자른다. 계산은 Policy 순수 함수
  `leadingContextAfterReplacement(_ leadingContext: String?, inputBufferCount: Int, deleteCount: Int) -> String?`로 둔다
  - `가|`에서 `가방` 탭: 앞 문맥 `가` → 1자 잘라 `""`, 버퍼 `가방`, 기준 텍스트 `가방`, 조각 아님
  - 앞 문맥 `가` + 버퍼 `방`에서 `가방끈` 탭(지울 글자 2): 넘친 1자를 잘라 앞 문맥 `""`, 버퍼 `가방끈`, 조각 아님
- 조각 여부는 `isInputBufferAttachedToLeadingContext(inputBufferLeadingContext)`로 그때그때 계산한다

## 후보 적용

| 경로 | 변경 |
|---|---|
| `updateSuggestionsForCurrentContext()` | `suggestionUpdateAction`에 기준 텍스트를 넘기고, 텍스트 대치용으로 버퍼를 따로 넘긴다 |
| `handleInputBufferSuggestion` | `selectSuggestion`에 기준 텍스트와 버퍼를 넘긴다. 교체는 기존 `replaceTextWithSmartInsertDeleteSpacing` 경로다. 버퍼보다 긴 교체는 `replaceInputBufferSuffix`가 버퍼를 비우고 후보로 채운다 |
| `handleNGramSuggestion` | 앞 공백 판단과 `updateSuggestionsAfterNGramSelection`에 기준 텍스트를 쓴다 |
| `handleCurrentWordConfirmationIfNeeded` | 학습할 단어를 `learnableInputBuffer`에서 뽑는다. 조각뿐이면 학습하지 않는다 |
| `insertSpaceText`, `insertReturnText`, #164 전송 스냅샷 | `learnableInputBuffer`를 넘긴다 |
| 텍스트 대치(스페이스 대치, 미리보기 강조, 복구) | 그대로 `inputBuffer` |
| 수식 후보 | 그대로 |

`SuggestionService`/`SuggestionController` 인터페이스:

- `updateSuggestions(for:selectedText:mathExpressionText:)`에 `textReplacementBaseText: String`을 추가한다.
  `performUpdateSuggestions`의 `lexiconEngine?.suggestions(for:)`는 이 값을 쓴다
- `selectSuggestion(at:baseText:)`에 `textReplacementBaseText: String`을 추가한다. 후보 출처가 `.lexicon`이면
  교체 길이와 대치 기록을 버퍼 마지막 단어로, 나머지는 기준 텍스트 마지막 단어로 계산한다
- `updateSuggestionsAfterNGramSelection(inputBuffer:)`는 인자 이름만 `baseText:`로 바꾸고 기준 텍스트를 받는다

## 기존 동작 변경

- 기존 텍스트가 있는 입력창에서 키보드를 열면 그 텍스트 기준 예측이 나온다.
- 평소 입력에서도 앞 문맥의 단어가 bigram·trigram 문맥으로 쓰인다.
- 기존 텍스트 끝에 이어 친 조각은 학습하지 않는다. 예: `안녕` 끝에서 `하세요`를 치고 스페이스를 누르면 지금은
  `하세요`가 학습되지만 앞으로는 학습하지 않는다(사용자 확인, 2026-09-28).

저장 형식과 키는 바뀌지 않으므로 마이그레이션은 필요 없다.

## 성능

- 키 입력마다 도는 `updateSuggestionsForCurrentContext()`는 이미 수식 탐지 때문에 `documentContextBeforeInput`을 읽는다.
  이번 변경은 버퍼가 시작될 때 한 번 더 읽고, 입력 중에는 떠 둔 앞 문맥을 쓴다.
- 늘어나는 계산은 최대 256자를 단어로 나누는 정도다. TextChecker는 현재 단어만, NGram은 마지막 1~2단어만 쓴다.
- 변경 전후를 기존 signpost 구간(`LexiconSuggestions` 등)으로 한 번 비교한다.

## 테스트

| 대상 | 파일 | 확인하는 것 |
|---|---|---|
| Policy | `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift` | 기준 텍스트(버퍼 없음·있음·앞 문맥 없음·256자 제한), 조각 판정(공백·빈 문자열·nil), 학습용 버퍼, 교체 뒤 앞 문맥(넘침 없음·일부 넘침·버퍼 빈 상태), 다음 단어 예측 앞 공백 |
| SuggestionController | `SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift` 등 | 앞 글자에 붙은 단축어(`가omw`)는 버퍼 기준으로 대치 후보가 나오고 교체 길이 3, 완성 후보 교체 길이는 기준 텍스트 단어 길이, 다음 단어 예측 탭 뒤 갱신이 기준 텍스트를 씀 |

- #98의 "일반 후보 기준 텍스트는 현재 세션 입력 버퍼만 사용"은 새 규칙에 맞게 고친다.
  "분리된 커서 문맥은 일반 추천과 텍스트 대치 입력으로 전달하지 않음"은 텍스트 대치 부분이 계속 성립해야 한다.
- VC 연결은 프록시를 바꿀 수 없어 수동으로 확인한다.

## 수동 확인

시뮬레이터 iPhone 13 mini / iOS 18.6과 실기기.

1. `가나`에서 커서를 `가|나`로 옮기면 `가`로 시작하는 후보, `가방`을 누르면 `가방|나`
2. 커서를 `가나 |`로 옮기면 `가나` 다음 단어 예측
3. `가|`에서 `방`을 치면 `가방` 기준 후보, 스페이스를 눌러도 `방`은 학습되지 않음(NGram 파일로 확인)
4. 기존 텍스트가 있는 입력창을 열면 그 텍스트 기준 예측
5. `가` 뒤에 iOS 기본 단축어 `omw`를 붙여 치고 대치 후보를 누르면 `omw`만 `On my way!`로 바뀜
6. 기존 텍스트 `안녕` 끝에서 `하세요` + 스페이스 → `하세요` 학습되지 않음
7. 회귀: 평소 입력 후보, #164 보낸 단어 학습, 커서 드래그, 텍스트 대치, 수식 후보, #164 검색창 X 버튼(미확인분)

## 회귀 확인

- 전체 `SYKeyboardTests`
- `SYKeyboard`, `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` scheme 빌드

## 알려진 한계(기존 동작)

글자 수 제한 입력창에서 한도를 넘는 입력이 잘리면 `textWillChange` 없이 `inputBuffer`와 한글 조합 상태가 입력창과
어긋난 채 남는다. 이어서 삭제 키를 누르면 실제 글자를 지우거나 다른 글자로 바꾼다. 이번 변경이 건드리지 않은 한글
조합 경로라 `develop`에도 있는 동작이고 #166에서 다룬다.

재현(2026-09-28, 시뮬레이터 iPhone 13 mini / iOS 18.6, Safari `<input maxlength="5">`, 두벌식): `가나다라마` 입력 →
`ㅂ`(받침 `맙`) → `ㅏ`(`마바`로 교체했지만 `마`만 들어감, 키보드는 `가나다라마바`로 앎) → 삭제 1번에 입력창이
`가나다맙`이 된다. 프록시 `documentContextBeforeInput`도 키보드가 넣은 대로 `가나다라마바`를 돌려줬다.

#166 조사 결과(2026-09-28, 같은 환경) **웹 입력창에서만 생기는 iOS/WebKit 한계로 보고 수정하지 않는다.**

| 입력창 | 잘릴 때 입력창 | `textWillChange`/`textDidChange` | 프록시 문맥 | 결과 |
|---|---|---|---|---|
| 네이티브 `UITextField`, delegate `shouldChangeCharactersIn` 거부 | 편집 전체 취소(`가나다라맙`) | 50ms 안에 옴 | 실제 값 | 버퍼 초기화, 삭제 정상 |
| SwiftUI `TextField`, `onChange`로 잘라 냄 | `가나다라마` | 옴 | 실제 값 | 버퍼 초기화, 정상 |
| Safari `maxlength` | `가나다라마` | 1초 동안 없음 | 키보드가 넣은 값 | 삭제 1번에 `가나다맙` |
| Safari JS `input` 이벤트에서 `slice` | `가나다라마` | 없음 | 키보드가 넣은 값 | 삭제 1번에 `가나다맙` |

- 두벌식·천지인·나랏글 모두 웹 입력창에서 같게 재현된다.
- 영문은 한도를 넘는 글자가 통째로 거부되어 삭제는 보이는 대로 동작한다. 대신 후보를 누르면 버퍼 기준 길이로
  교체해 실제 글자를 더 지운다. `Hi th`에서 `e` 뒤 후보 `they` → `Hithe`(띄어쓰기가 지워짐).
- Apple 기본 한국어 키보드도 같은 웹 입력창에서 `가나다라마` 뒤 삭제 1번에 `가나다맙`이 되고 후보 바에
  `"가나다라마바"`를 보인다.
- 편집 뒤 `adjustTextPosition(byCharacterOffset: 0)`을 보내도 콜백·프록시 갱신이 없었다. 커서를 한 칸 옮겼다
  되돌려 동기화하는 방법은 키마다 `textWillChange`가 돌아 조합 상태를 끊으므로 쓰지 않는다.

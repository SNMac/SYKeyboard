# 자동완성 후보 길게 눌러 삭제 설계

- 작성일: 2026-09-18
- 이슈: #139
- 브랜치: `feat/#139-suggestion-removal`

## 목표

자동완성 바의 추천 단어를 0.5초 동안 길게 누르면 키보드 위에 삭제 확인 오버레이를 띄운다.
사용자가 삭제를 확정하면 그 단어를 앱이 관리하는 학습 데이터(NGram, 앱이 학습시킨 `UITextChecker` 단어)에서 지운다.

## 범위

| 출처 (`SuggestionItem.Source`) | 삭제 가능 여부 | 삭제 방법 |
|---|---|---|
| `.nGram` | 가능 | 현재 언어 NGram 엔진의 `removeWord(_:)` |
| `.textChecker` | `UITextChecker.hasLearnedWord(word)`가 `true`일 때만 가능 | `UITextChecker.unlearnWord`를 호출하고 `learnedWords`에서 제거 |
| `.textChecker` 시스템 사전 단어 | 불가 | iOS에서 제거할 수 없음 |
| `.lexicon` (텍스트 대치·연락처) | 불가 | `UILexicon`은 읽기 전용 |
| 수식 후보 (`.mathExpression*`) | 불가 | 학습 데이터가 아님 |
| typing 모드 button1의 `"현재단어"` | 불가 | 후보가 아니라 현재 입력값 |

범위 밖:

- 시스템 사전 단어를 막는 앱 차단 목록과 그 관리 UI
- 삭제한 단어의 재학습 방지. 사용자가 다시 입력하면 NGram에 다시 기록되는 기존 동작을 유지한다.
- 다른 언어 엔진의 데이터 삭제. 한영 통합 키보드에서도 후보를 만든 현재 언어 엔진에서만 지운다.

## 사용자 동작

```
평상시:
[ 오늘 | 내일 | 지금 ]
[      키보드      ]

'내일'을 0.5초 동안 누름 → 키보드 전체를 덮는 오버레이
┌──────────────────────────────┐
│ '내일'을 자동완성에서 삭제할까요? │
│ 다시 입력하면 다시 학습됩니다.     │
│      [ 취소 ]  [ 삭제 ]         │
└──────────────────────────────┘

삭제 탭 → 오버레이 닫힘, 단어 삭제, 후보 재계산
[ 오늘 | 지금 | 이제 ]
```

- 짧은 탭과 드래그 선택은 기존 동작 그대로다.
- 삭제할 수 없는 후보는 길게 눌러도 아무 일이 없고, 손을 떼면 기존처럼 선택된다.
- 오버레이는 자동완성 바와 키보드를 모두 덮는다. 삭제나 취소를 탭해야만 닫히고, 떠 있는 동안 키 입력은 막힌다.
- 오버레이의 모양과 문구 톤은 클립보드 고정 항목 삭제 확인과 같다.

## 설계

### 1. 길게 누르기 시간 — `KeyboardSuggestionSelectionPolicy`

```swift
/// 자동완성 후보 삭제 확인을 띄우는 길게 누르기 시간
static let removalLongPressDuration: TimeInterval = 0.5
```

- 사용자 설정 `longPressDuration`과는 별개인 고정값이다.
- 0.5초를 쓰는 이유: 실기기 확인 결과 0.7초는 길게 느껴졌다. 드래그 선택은 손가락이 다른 후보로 넘어가는 순간 타이머를 취소하므로 이 값에서도 선택과 충돌하지 않는다.

### 2. 터치 처리 — `SuggestionBarView`

`UILongPressGestureRecognizer`는 쓰지 않는다. recognizer가 터치를 가져가면 `touchesCancelled`가 호출돼 짧은 탭의 이벤트 타이밍이 바뀔 수 있기 때문이다. 대신 기존 `touchesBegan/Moved/Ended` 흐름에 타이머를 더한다.

- `beginTouchInteraction(at:)`: 후보 버튼 위라면 그 인덱스를 기억하고 `removalLongPressDuration` 타이머를 시작한다.
- `moveTouchInteraction(to:)`: 손가락이 처음 누른 후보 버튼을 벗어나면 타이머를 취소한다. 다른 버튼으로 옮겨 가도 타이머를 다시 시작하지 않는다.
- 타이머가 발동하면 delegate에 삭제를 요청한다.
  - delegate가 `true`를 반환하면(오버레이 표시됨) 이번 터치를 소비된 것으로 표시하고 후보 하이라이트를 지운다. 햅틱은 오버레이를 띄운 VC가 재생한다.
  - 소비된 터치는 이후 `touchesMoved`에서도 하이라이트를 다시 만들지 않는다.
  - `false`면 아무것도 하지 않는다. 손을 떼면 기존처럼 선택된다.
- `endTouchInteraction(at:playsFeedback:)`: 소비된 터치면 선택을 건너뛰고 `resetTouchInteraction()`만 한다. 아니면 기존 선택 흐름을 그대로 탄다.
- `resetTouchInteraction()`, `cancelTouchInteraction()`: 타이머를 무효화하고 소비 표시를 지운다.

`SuggestionBarDelegate` 추가 메서드:

```swift
/// 후보를 길게 눌렀을 때 호출됩니다. 삭제 확인을 띄웠으면 `true`를 반환합니다.
func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool
```

### 3. 삭제 확인 오버레이 — 공용 컴포넌트로 분리

현재 `ClipboardHistoryPanelView.swift` 안의 `private final class ClipboardHistoryDeleteConfirmView`를
`Modules/SYKeyboardCore/Presentation/View/Components/Overlays/DeleteConfirmOverlayView.swift`로 옮긴다.

- 이름을 `DeleteConfirmOverlayView`로 바꾸고 접근 수준을 `internal`로 넓힌다.
- `update(pinnedCount:totalCount:)`에 있던 클립보드 전용 문구 계산은 `ClipboardHistoryPanelView`로 옮긴다. 오버레이에는 `update(title:message:)`만 남긴다.
- `onCancel`, `onConfirm`, 블러 배경, 취소·삭제 버튼, 레이아웃은 그대로 둔다.
- 클립보드 쪽은 구조 이동만 하고 동작·문구는 바꾸지 않는다. 이 이동은 `refactor` 커밋으로 분리한다.
- 새 파일이므로 `project.pbxproj`의 `SYKeyboardCore` 타깃과 `SYKeyboard` 타깃 `membershipExceptions`에 알파벳 순서로 등록한다.

### 4. 판정과 삭제 — `SuggestionController`

```swift
/// 길게 눌러 삭제할 수 있는 후보면 그 단어를, 아니면 nil을 반환합니다.
func removableSuggestionText(atBarIndex index: Int) -> String?

/// 앱 학습 데이터에서 단어를 지우고 후보를 다시 계산합니다.
func removeSuggestionWord(_ word: String)
```

- `index`는 바 인덱스(0~2)다. nGram 모드는 후보 인덱스와 같고, typing 모드는 `index - 1`이 후보 인덱스다(button1은 `"현재단어"`라 `nil`). 수식 모드는 항상 `nil`이다.
- 판정 기준은 위 범위 표를 따른다. `.textChecker`는 엔진의 `canUnlearn(word:)`로 확인한다.
- 두 메서드는 `SuggestionService` 프로토콜에도 추가한다. VC가 이 프로토콜 타입으로 컨트롤러를 들고 있다.
- `removeSuggestionWord`의 동작:
  - `nGramEngine?.removeWord(word)`를 호출한다.
  - `textCheckerEngine?.unlearn(word:)`를 호출한다. 앱이 학습하지 않은 단어면 엔진 안에서 아무것도 하지 않는다.
  - 현재 후보 배열에서 같은 텍스트를 빼서, typing 모드가 직전 TextChecker 후보를 이어받을 때 지운 단어가 한 프레임 다시 보이지 않게 한다.
  - 마지막 요청값(`lastSuggestionBaseText` 등)으로 후보를 다시 계산해 delegate로 전달한다.
- 출처와 관계없이 두 저장소 모두에서 지운다. NGram 후보로 떠 있던 단어가 앱이 학습한 단어이기도 하면 함께 unlearn된다.

### 5. NGram 삭제 — `NGramPredictiveTextEngine.removeWord(_:)`

`NGramPredictiveTextProviding`에 추가한다.

- 대소문자를 구분하지 않고 지운다. `suggestions(for:)`가 후보를 소문자 기준으로 중복 제거하므로, `hello`만 지우면 가려져 있던 `Hello`가 다시 떠서 삭제가 실패한 것처럼 보이기 때문이다.
- 다음 항목을 모두 지운다.
  - `unigramStore[word]`
  - 모든 bigram/trigram 값 사전에서 `word` 항목
  - `word`가 문맥 키인 bigram 키
  - 공백으로 나눈 단어 중 하나가 `word`인 trigram 키
  - 값이 비게 된 키
- `unigramStore` 변경은 기존 `didSet`을 거치므로 `rankedUnigramCache`도 무효화된다.
- `hasUnsavedChanges = true`로 표시하고 `saveToDisk()`로 바로 저장한다. 사용자가 명시적으로 지운 데이터이므로 다음 저장 시점까지 기다리지 않는다.
- 로딩 전(`isLoaded == false`)에는 아무것도 하지 않는다. 이 시점에는 NGram 후보가 표시되지 않으므로 호출될 일이 없다.
- `currentSentenceWords`는 건드리지 않는다. `currentSentenceWordsCount`로 `inputBuffer`와 단어 수를 맞추는 데 쓰인다.

### 6. TextChecker unlearn — `TextCheckerPredictiveTextEngine`

```swift
func canUnlearn(word: String) -> Bool
func unlearn(word: String)
```

- `canUnlearn`은 `UITextChecker.hasLearnedWord(word)`를 반환한다.
- `unlearn`은 `UITextChecker.hasLearnedWord(word)`일 때만 `UITextChecker.unlearnWord(word)`를 호출하고 `learnedWords`에서 제거한다.
- 기존 `unlearnAllWords()`와 같은 main 스레드 규칙을 따른다.
- `PredictiveTextProvider`에 두 메서드를 요구사항으로 추가하고, 기본 구현(`false` 반환, 아무것도 하지 않음)을 extension에 둔다. 이렇게 하면 NGram·Lexicon 엔진은 수정하지 않아도 되고, 테스트 stub은 `canUnlearn`을 재정의해 학습 여부를 흉내 낼 수 있다.

### 7. 연결 — `BaseKeyboardViewController`

- `RequestFullAccessOverlayView`처럼 `view` 전체를 덮는 `DeleteConfirmOverlayView`를 lazy로 두고, 처음 쓸 때 추가한다. 기본은 `isHidden = true`다.
- `shouldBeginRemovalAt`:
  - 미리보기(`BaseKeyboardViewController.isPreview`)거나 `suggestionController.removableSuggestionText(atBarIndex:)`가 `nil`이면 `false`를 반환한다.
  - 단어가 있으면 삭제 대기 단어로 보관하고, 문구를 설정해 오버레이를 표시하고 햅틱을 한 번 재생한 뒤 `true`를 반환한다.
- 오버레이 `onConfirm`: 대기 단어로 `removeSuggestionWord`를 호출하고 오버레이를 숨긴다.
- 오버레이 `onCancel`: 대기 단어를 지우고 오버레이를 숨긴다.
- 키보드가 사라질 때(`viewWillDisappear`)는 오버레이를 숨기고 대기 단어를 지운다.
- 삭제 기능이 공통 동작이므로 Base에만 둔다. 하위 VC에는 복제하지 않는다.

### 8. 로컬라이징 — `SYKeyboardAssets/Localizable.xcstrings`

| 키 (한국어) | 영어 |
|---|---|
| `'%@'을(를) 자동완성에서 삭제할까요?` | `Remove “%@” from suggestions?` |
| `다시 입력하면 다시 학습됩니다.` | `It will be learned again if you type it.` |

`취소`, `삭제`는 클립보드 확인 뷰의 기존 키를 재사용한다.

## 테스트

Swift Testing으로 production 진입점을 호출한다.

- `NGramPredictiveTextEngine` (기존 NGram 테스트 파일에 추가하거나 `NGramPredictiveTextEngineRemovalTests` 신설)
  - `removeWord` 후 `suggestions(for:)`에 unigram·bigram·trigram 모두에서 해당 단어가 나오지 않음
  - 해당 단어가 문맥 키였던 bigram/trigram 항목 제거
  - 저장 후 새 엔진으로 다시 로드해도 없음
  - 다른 단어의 빈도는 그대로
- `SuggestionController` (`SuggestionControllerEngineFactory` fake 사용)
  - `removableSuggestionText(atBarIndex:)`: nGram은 단어 반환, typing 모드 button1·미학습 textChecker·lexicon·수식은 `nil`, 학습한 textChecker는 단어 반환
  - `removeSuggestionWord`가 NGram fake의 `removeWord`와 TextChecker fake의 `unlearn`을 호출하고 delegate로 갱신된 후보를 전달함
- `SuggestionBarView`: 타이머가 호출하는 `handleRemovalLongPress()`를 직접 불러 확인
  - delegate가 수락하면 손을 떼도 선택하지 않음
  - delegate가 거절하면 기존처럼 선택함
  - 누른 후보를 벗어난 뒤에는 삭제를 요청하지 않음
- `KeyboardSuggestionSelectionPolicy`: `removalLongPressDuration == 0.5`
- `UITextChecker.hasLearnedWord` 판정은 전역 사전 상태에 의존하므로 unit test로 고정하지 않는다.
- 오버레이 분리 후 기존 클립보드 삭제 테스트가 그대로 통과해야 한다.

### 수동 확인 (iPhone 13 mini / iOS 18.6, 실제 입력 앱)

- [ ] 짧은 탭 선택이 기존과 같음
- [ ] 드래그 선택이 기존과 같고, 드래그 중 오버레이가 뜨지 않음
- [ ] NGram 후보를 0.5초 누르면 오버레이 표시, 손을 떼도 후보가 입력되지 않음
- [ ] 삭제 후 해당 단어가 다시 나오지 않음
- [ ] 취소 시 아무것도 바뀌지 않음
- [ ] 시스템 사전·텍스트 대치 후보를 길게 누르고 떼면 기존처럼 입력됨
- [ ] 오버레이가 떠 있는 동안 키 입력이 막힘
- [ ] 클립보드 고정 항목 삭제 확인이 기존과 같음
- [ ] 한영 통합 키보드에서 현재 언어 데이터만 삭제됨

## 영향 파일

- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`
- `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
- `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`
- `Modules/SYKeyboardCore/Presentation/View/Components/Overlays/DeleteConfirmOverlayView.swift` (신규)
- `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
- `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift`
- `Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift`
- `Modules/SYKeyboardCore/Domain/PredictiveText/Protocols/PredictiveTextProvider.swift`
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- `SYKeyboard.xcodeproj/project.pbxproj`
- `SYKeyboardAssets/.../Localizable.xcstrings`
- `SYKeyboardTests/` 신규·기존 테스트 (새 파일은 `project.pbxproj` 등록 확인)

# textWillChange/textDidChange 텍스트 프록시 중복 읽기 정리 설계

- 작성일: 2026-10-08
- 이슈: #181
- 브랜치: `refactor/#181-cache-proxy-reads-in-text-change`

## 목표

`textWillChange`/`textDidChange` 한 번에 같은 `textDocumentProxy` 값을 여러 번 읽지 않게 한다.
UIKit이 XPC 스레드에서 문서 상태(`_controllerState`)를 교체하는 순간 메인 스레드가 프록시를 읽으면
크래시한다. 읽기 횟수를 줄여 그 순간과 겹칠 기회를 줄인다.

- 범위: `BaseKeyboardViewController`와 하위 VC 3개(`HangeulKeyboardCoreViewController`,
  `EnglishKeyboardCoreViewController`, `HangeulEnglishKeyboardViewController`).
- 프록시에 쓴 뒤에는 다시 읽는다. 삭제 이어 가기, 한영 전환, 전송 기록, 리턴 버튼, 자동완성,
  shift 자동 대문자 동작은 그대로다.
- 콜백 순서, 호출 횟수, 버튼 이벤트 타이밍은 바꾸지 않는다. 바뀌는 것은 프록시 읽기 횟수뿐이다.
- 이 경로의 크래시 기록은 없다. 예방 목적의 정리다.

## 현재 동작

- `textDidChange` 한 번에 프록시를 약 25~30회 읽는다(코드 기준 추정).
  - `documentContextBeforeInput` 약 5회: `recordSentTextIfNeeded`, `currentTextContextSnapshot()` 2회
    (`textDidChange` 본문, `invalidateUndoRedoHistoryIfNeededAfterTextChange`), `updateReturnButtonEnabled`,
    `updateSuggestionsForCurrentContext`. undo 기록이 있으면 `updateUndoRedoControls`에서 1회 더.
  - `keyboardType`은 값이 같아도 3회(하위 VC `updateKeyboardType()` guard 1회, Base 비교·저장 2회).
    값이 바뀌면 하위 VC에서 최대 4회 더 읽는다.
  - `textContentType` 2회. `selectedText`, `returnKeyType`도 여러 번 읽는다.
- `updateKeyboardType()`이 `currentKeyboard`를 바꾸면 `didSetCurrentKeyboard`가 불려
  `updateReturnButtonType`(`returnKeyType`)과 영문·한영 `updateShiftButton`(`autocapitalizationType`,
  `documentContextBeforeInput`)이 다시 읽는다.
- 영문·한영 VC는 `super.textWillChange` **뒤에서** shift를 갱신하며 `autocapitalizationType`과
  `documentContextBeforeInput`을 다시 읽는다.
- 프록시 쓰기는 모두 `BaseKeyboardViewController.swift` 안의 11곳이고 `insertText`, `deleteBackward`,
  `adjustTextPosition` 세 종류다. `setMarkedText`/`unmarkText`는 쓰지 않는다.

### 콜백 안의 쓰기

- `textDidChange`에서 쓰기가 생길 수 있는 곳은 삭제 이어 가기 구간뿐이다.
  1. `processDeleteMutationCallbackOutcome` → `processDeleteMutationResolution` →
     `resolvePendingDeleteInteractionsIfNeeded`가 보류된 삭제를 실행하면 `deleteBackward`.
  2. `resumePendingDeletePanBoundaryIfNeeded` → `evaluatePendingDeletePanBoundary`의 `.refill` 분기에서
     `performDeleteButtonPanDeleteIfPossible`·`drainPendingDeleteInteractionsIfPossible`가 `deleteBackward`.
- 그 뒤의 `invalidateUndoRedoHistoryIfNeededAfterTextChange`, `updateKeyboardType`, trait 비교,
  `updateReturnButtonEnabled`, `updateSuggestions`, `updateUndoRedoControls`는 삭제가 반영된 값을 읽어야 한다.
- `textWillChange`와 한영 전환(`inputTraitsDidChange` → `applyLanguageMode`)에는 쓰기가 없다.
  `finishForLanguageChange`는 두 어댑터 모두 내부 상태만 비운다.

## 설계

### `CachingTextDocumentProxy`

- 위치: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/Utils/CachingTextDocumentProxy.swift`.
  Base VC만 쓰는 보조 타입이라 Base 옆 `Utils/`에 둔다. 하위 VC는 타입이 아니라 `textDocument` 인스턴스만 쓴다.
  `project.pbxproj`의 `SYKeyboard`·`SYKeyboardCore` 두 타깃 `membershipExceptions`에 등록한다.
- `() -> UITextDocumentProxy` 클로저로 프록시를 받는다. 테스트가 `textDocumentProxy`를 오버라이드해 가짜
  프록시를 넣으므로 매번 VC의 현재 값을 따른다. VC는 `[unowned self]`로 넘겨 순환 참조를 만들지 않는다.
- `UITextDocumentProxy`를 채택하지 않고 실제로 쓰는 멤버만 둔다.
  - 읽기 16개: `documentContextBeforeInput`, `documentContextAfterInput`, `selectedText`,
    `documentIdentifier`(기존처럼 KVC, `UUID?`), `documentInputMode`, `hasText`, `keyboardType`, `textContentType`, `returnKeyType`,
    `enablesReturnKeyAutomatically`, `autocorrectionType`, `autocapitalizationType`,
    `smartQuotesType`, `smartDashesType`, `smartInsertDeleteType`, `mathExpressionCompletionType`(iOS 18+)
  - 쓰기 3개: `insertText(_:)`, `deleteBackward()`, `adjustTextPosition(byCharacterOffset:)`
- 범위: `withReadCaching(_:)` 클로저 안에서만 캐시를 켠다. 중첩할 수 있고 가장 바깥 범위가 끝날 때
  캐시를 지운다.

### 캐시 규칙

- 범위 안에서는 필드마다 처음 읽을 때만 프록시를 읽고 저장한다. `nil`도 읽은 값으로 저장한다
  (필드마다 `T??`).
- 쓰기 메서드는 캐시를 **모두** 비운 뒤 프록시에 쓴다. trait 값은 쓰기로 바뀌지 않지만 필드를 골라
  비우는 규칙은 두지 않는다. 범위 안의 쓰기는 삭제 이어 가기뿐이라 다시 읽는 비용이 작다.
- 범위 밖에서는 읽기·쓰기 모두 프록시로 바로 간다. 지금과 같다.

### VC 적용

- Base에 `public private(set) lazy var textDocument`를 둔다. 하위 VC가 다른 모듈에 있어 `public`이다.
- Base와 하위 VC의 `textDocumentProxy.xxx` 읽기·쓰기를 **모두** `textDocument.xxx`로 바꾼다
  (Base 약 82줄, 하위 VC 22줄). `oldKeyboardType`/`oldTextContentType`의 lazy 초기값도 포함한다.
  콜백 밖에서는 캐시가 꺼져 있어 동작이 같다. 규칙을 "새 타입 밖에서 `textDocumentProxy.`를 쓰지 않는다"
  하나로 만들어 grep으로 검사할 수 있게 한다.
- Base의 `textWillChange`/`textDidChange` 본문을 `textDocument.withReadCaching { ... }`로 감싼다.
- 영문·한영 VC의 `textWillChange` 오버라이드는 `super` 호출까지 포함해 감싼다. 한글 VC는 `super` 뒤에서
  프록시를 읽지 않으므로 그대로 둔다.
- `updateKeyboardType()` 등 `open` 메서드 시그니처는 바꾸지 않는다.
- CLAUDE.md 아키텍처 절에 "프록시 읽기·쓰기는 `textDocument`로만"을 추가한다.

### 다른 작업과의 관계

`BaseKeyboardViewController.swift` 분리 작업(`+Suggestions`, `+ClipboardHistory`, `+FullAccessGuide`)은
이 작업이 develop에 머지된 뒤 그 시점의 develop을 기준으로 시작한다. 두 작업을 동시에 진행하지 않는다.
분리 작업은 이 작업이 바꾼 함수 본문(`synchronizeTextInputTraits`, `recordSentTextIfNeeded`,
`currentDocumentIdentifier`, `generalSuggestionBaseText`, `replaceSelectedText`)을 그대로 옮긴다.
캐시 규칙이 별도 타입에 있으므로 코드가 여러 파일로 흩어져도 유지된다.

## 확인하지 못한 가정

- 같은 범위 안에서 쓰기 없이 같은 필드를 두 번 읽던 곳은 첫 값을 쓴다(예: `evaluatePendingDeletePanBoundary`
  `.refill` 분기의 앞 문맥 2회). 값이 달라지는 경우는 두 읽기 사이에 XPC 스레드가 문서 상태를 바꾸는
  경합뿐이다.
- 이 경우에도 문서 상태가 새로 바뀌면 UIKit이 그 변화에 대해 `textWillChange`/`textDidChange`를 다시 보내
  새 값을 읽으므로 최종 화면은 같은 결과로 수렴한다고 본다. 재현이 매우 어려워 관찰로 확인하지 못했다.
- 쓰기 경계는 현재 코드에서 모든 쓰기가 `textDocument`를 거치는 것으로 지킨다. 나중에 프록시에 직접 쓰는
  코드가 생기면 그 경로는 캐시를 비우지 않는다. 컴파일러로 막을 수 없어 grep과 CLAUDE.md 규칙으로 지킨다.

## 성능

- 늘어나는 비용: 모든 프록시 접근에 클로저 호출 1회와 범위 확인 1회가 붙는다. 키 입력·삭제 반복 틱처럼
  콜백 밖의 자주 도는 경로에도 붙지만, 프록시 읽기 자체(Objective-C 메시지, `NSString` → `String` 변환)에
  비해 무시할 수 있다. 메모리는 VC마다 객체 하나와 콜백 동안의 값 몇 개다.
- 줄어드는 비용: `textDidChange` 읽기가 약 25~30회에서 10회 안팎으로 줄 것으로 본다. 앞 문맥 문자열
  생성은 약 5회에서 1회(삭제 이어 가기가 있으면 2회)로 준다.
- 측정하지 않는다. 시뮬레이터에서는 차이가 노이즈에 묻힐 가능성이 크다.

## 테스트

CLAUDE.md 테스트 지침에 따라 production 진입점을 부르고 정확한 값을 단언한다. `ForTesting` 메서드를
추가하지 않는다.

### 공통 도구: `SYKeyboardTests/Utils/CountingTextDocumentProxy.swift`

- `BaseKeyboardViewControllerProxyReadTests.swift`의 `private ReadCountingTextDocumentProxy`를 옮기고 넓힌다.
- 필드 16개의 읽기 횟수를 따로 센다. 기존 테스트가 쓰던 문맥·선택 텍스트 합계는 `contextReadCount`로 제공한다.
- 값을 바꿀 수 있다. 쓰기 3개를 기록하고 앞 문맥에 반영한다(`deleteBackward`는 마지막 글자 삭제,
  `insertText`는 덧붙임).

### 1. 타입 단위 테스트: `SYKeyboardTests/Utils/CachingTextDocumentProxyTests.swift`

| 동작 | 단언 |
|---|---|
| 범위 밖에서는 바로 읽음 | 2번 읽으면 프록시 2회 |
| 범위 안에서는 한 번만 읽음 | 2번 읽으면 1회 |
| `nil`도 저장함 | `nil` 필드 2번 읽어도 1회 |
| 쓰기 뒤 다시 읽음 | 범위 안 `"안녕"` 읽기 → `deleteBackward` → `"안"`, 프록시 2회 |
| 쓰기 전달 | 3개 쓰기의 순서와 인자가 그대로 |
| 중첩 범위 | 안쪽이 끝나도 바깥 캐시 유지(1회), 바깥이 끝난 뒤에는 다시 읽고 바뀐 값을 돌려줌 |

### 2. Base VC 테스트: `BaseKeyboardViewControllerProxyReadTests`에 추가

- `textDidChange` 한 번에 모든 필드 1회 이하, `documentContextBeforeInput`·`keyboardType`·`returnKeyType`은
  정확히 1회.
- `textWillChange`도 같은 기준.
- `textWillChange` 뒤 `textDidChange`에서 같은 필드를 다시 1회 읽음(콜백 사이에 캐시가 남지 않음).
- 삭제 이어 가기 뒤 다시 읽기는 VC 테스트로 넣지 않는다. 보류된 삭제를 만들려면 삭제 드래그 제스처 상태를
  거쳐야 하고, `resumePendingDeletePanBoundaryIfNeeded`는 마지막 드래그 편집 뒤 조용한 시간
  (`CACurrentMediaTime()` 기준)이 지나야 진행한다. 시간 경과에 기대는 테스트는 테스트 지침이 금지한다.
  1의 "쓰기 뒤 다시 읽음"과 시뮬레이터 확인으로 덮고, 그 사실을 PR에 적는다.

### 3. 영문 VC 테스트: `SYKeyboardTests/Controller/EnglishKeyboardCoreViewControllerProxyReadTests.swift`

- `textWillChange` 한 번에(`super` 뒤 `updateShiftButton` 포함) `autocapitalizationType`과
  `documentContextBeforeInput`을 각각 1회.
- 테스트에서 `EnglishKeyboardCoreViewController`를 띄울 수 없으면(XIB 로드) 빼고 시뮬레이터 확인으로 덮는다.
- 한영 VC는 extension 타깃이라 import할 수 없다. 빌드와 시뮬레이터로 확인한다.

### 4. 회귀 확인

- `SYKeyboard` scheme 전체 테스트(iPhone 13 mini / iOS 18.6).
- `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` scheme 빌드.
- `grep -rn "textDocumentProxy\." Modules Keyboards`가 `CachingTextDocumentProxy`를 만드는 곳 외에 0건.

### 5. 시뮬레이터 확인 (iPhone 13 mini / iOS 18.6, idb로 직접 조작)

호스트는 메시지 앱과, scratchpad에서 `python3 -m http.server`로 띄운 로컬 웹 페이지
(`type="tel"`/`inputmode="numeric"`/`type="email"`/`type="search"` 입력창, 여러 줄 `textarea`)를 쓴다.
키보드 전환은 `AppleKeyboards` 배열 순서로 하고 끝나면 원래 배열로 되돌린다.

| 항목 | 키보드 | 확인할 것 |
|---|---|---|
| 필드 전환 | 한글, 영문, 한영 | 일반 → 숫자 → 이메일 입력창에서 레이아웃이 바뀌고, 한영은 이메일에서 영어로 자동 전환 |
| 커서 이동 | 한글, 영문 | 텍스트를 탭해 커서를 옮기면 후보가 새 위치 기준으로 바뀜. 영문은 문장 시작에서 자동 대문자 |
| 리턴 버튼 | 한글 | 리턴 키 자동 활성 입력창에서 비우면 비활성, 입력하면 활성 |
| 삭제 이어 가기 | 한글 | 여러 줄 `textarea`에서 삭제 버튼 드래그로 줄바꿈 경계를 넘어 계속 지워짐 |
| 전송 기록 | 한글 | 메시지 기본 더미 대화에서 드문 조합(`ㅌㅊㅋ` 등)을 입력 후 전송, `ngram_*.plist`에 기록됨 |

- 전송 버튼과 대화 입력창은 idb 탭이 먹지 않아 사용자에게 클릭을 요청한다.
- 리턴 버튼 자동 활성을 켜는 입력창을 찾지 못하면 그 항목은 확인하지 못한 것으로 남긴다. 그때 남는 근거는
  판정 규칙의 `KeyboardPresentationStatePolicyTests`와 2의 읽기 횟수 테스트뿐임을 PR에 적는다.
- 시뮬레이터에서 통과한 항목은 PR·이슈 체크리스트에 "시뮬레이터 확인으로 대신함"으로 적는다.

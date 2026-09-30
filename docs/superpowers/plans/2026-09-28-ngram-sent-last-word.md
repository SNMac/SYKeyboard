# 띄어쓰기·개행 없이 보낸 마지막 단어 NGram 학습 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앱의 전송 버튼으로 입력창이 비워질 때, 아직 기록하지 않은 마지막 단어를 같은 문장 앞 단어와 이어 NGram에 학습한다.

**Architecture:** `textWillChange`에서 리셋 직전에 `inputBuffer`·NGram 문장 버퍼·`documentIdentifier` 스냅샷을 뜬다. 첫 `textDidChange`에서 순수 Policy(`KeyboardSentTextDetectionPolicy`)가 전송으로 판단하면 SuggestionController가 문장 버퍼를 복원하고 기존 `endSentence(inputBuffer:)` 경로로 기록한다. 전송이 아니면 스냅샷을 버리며, 기존 리셋 시점과 순서는 바꾸지 않는다.

**Tech Stack:** Swift 5, UIKit keyboard extension, Swift Testing, Xcode 26+

**Spec:** `docs/superpowers/specs/2026-09-28-ngram-sent-last-word-design.md`

## Global Constraints

- 브랜치: `feat/#164-ngram-sent-last-word`. push·PR은 사용자가 요청할 때만 한다.
- 커밋 메시지: `type: #164 - subject`(한국어, 마침표 없음), 끝에 `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`
- 각 step은 실제 작업과 검증이 끝난 직후에만 체크하고, 결과(테스트 개수, 빌드 결과, 확인하지 못한 항목)를 이 문서에 적은 뒤 그 step의 변경과 함께 커밋한다.
- 검증 기준 시뮬레이터: iPhone 13 mini / iOS 18.6, UDID `82146144-24DE-4F91-B25D-23D147A91142`
- `Modules/`에 새 파일을 만들면 `SYKeyboard.xcodeproj/project.pbxproj`의 `SYKeyboard` 타깃과 `SYKeyboardCore` 타깃 `membershipExceptions`에 알파벳 순서로 추가한다. `SYKeyboardTests/`는 동기화 그룹이라 추가하지 않는다.
- 스페이스·리턴·커서 이동·삭제 경로와 `resetInputBuffer()` 호출 시점은 바꾸지 않는다.
- `learnedWords`(UITextChecker)에는 넣지 않는다.
- `textDocumentProxy.documentIdentifier`를 Swift에서 그대로 읽지 않는다. nil이 와서 `UUID._unconditionallyBridgeFromObjectiveC`에서 크래시한다.
- production 클래스에 `ForTesting` 메서드를 추가하지 않는다.
- extension scheme 빌드 뒤 `.xcscheme`의 `RemotePath`만 바뀌었으면 `git checkout -- <파일>`로 되돌린다.
- xcodebuild 출력은 scratchpad 파일로 남기고, 테스트는 `-parallel-testing-enabled NO`로 기준 시뮬레이터에서 돌린다(붙여넣기 알림을 눌러야 할 수 있음). 몇 분씩 진행이 없으면 CLAUDE.md의 "호스트 앱이 뜨지도 않고 테스트가 매달리는 경우"로 확인한다.

## Review Focus

1. 단어 하나만 보낸 경우(`ㅇㅇ`, 문장 버퍼 `[]`): 그 단어를 unigram으로 기록해야 한다. → Task 3 테스트
2. 마지막이 공백인 채로 보낸 경우(`안녕 `): 이미 기록한 단어를 다시 세지 않고 문장만 끝내야 한다. → Task 3 테스트
3. 예측 입력이 꺼졌거나 중단된(`isSuspended`) 입력창: 아무것도 기록하지 않아야 한다. → Task 3 테스트
4. 키보드 자체 삭제로 입력창이 빈 경우(한 글자 삭제, 키보드의 선택 기능 뒤 삭제): 학습하지 않아야 한다. `deleteText()`는 `deleteBackward()` 뒤에 버퍼를 줄이므로 콜백 순서에 따라 스냅샷이 생길 수 있다. → Task 5 수동 확인 6
5. 복원은 기록이 아니어야 한다: `restoreSentenceBuffer`만 부르고 끝나면 저장소에 아무것도 남지 않아야 한다. → Task 2 테스트

---

## 파일 구조

| 파일 | 변경 | 책임 |
|---|---|---|
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSentTextDetectionPolicy.swift` | 생성 | 전송 판정(순수) |
| `SYKeyboard.xcodeproj/project.pbxproj` | 수정 | 새 Policy 파일 타깃 등록 |
| `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` | 수정 | 문장 버퍼 읽기·복원 |
| `Modules/SYKeyboardCore/Domain/SuggestionController.swift` | 수정 | 프로토콜 멤버 추가, 스냅샷·복원 기록 API |
| `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift` | 수정 | VC가 쓰는 API 선언 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` | 수정 | 스냅샷 보관·판정·기록 연결 |
| `SYKeyboardTests/Utils/KeyboardSentTextDetectionPolicyTests.swift` | 생성 | Policy 테스트 |
| `SYKeyboardTests/Domain/NGramPredictiveTextEngineSentenceBufferTests.swift` | 생성 | 엔진 복원 테스트 |
| `SYKeyboardTests/Domain/SuggestionControllerSentTextTests.swift` | 생성 | 컨트롤러 복원 기록 테스트 |
| `SYKeyboardTests/Domain/SuggestionControllerTestSupport.swift` | 수정 | stub에 새 멤버와 관찰용 기록 |
| `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift` | 수정 | stub에 새 멤버 |

---

### Task 1: 전송 판정 Policy

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSentTextDetectionPolicy.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (두 `membershipExceptions` 목록)
- Test: `SYKeyboardTests/Utils/KeyboardSentTextDetectionPolicyTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces: `KeyboardSentTextDetectionPolicy.isSentAfterTextChange(documentIdentifierBeforeChange: UUID?, documentIdentifierAfterChange: UUID?, beforeInput: String?, afterInput: String?, selectedText: String?) -> Bool`

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/KeyboardSentTextDetectionPolicyTests.swift`:

```swift
//
//  KeyboardSentTextDetectionPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/28/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("전송 판정 정책 검증")
struct KeyboardSentTextDetectionPolicyTests {

    private let document = UUID()

    @Test("같은 입력창이 완전히 비면 전송으로 판정")
    func test같은입력창이완전히비면_전송으로판정() {
        #expect(isSent(before: document, after: document, beforeInput: nil, afterInput: nil, selectedText: nil))
    }

    @Test("빈 문자열 문맥과 선택도 빈 것으로 봄")
    func test빈문자열문맥과선택도_빈것으로봄() {
        #expect(isSent(before: document, after: document, beforeInput: "", afterInput: "", selectedText: ""))
    }

    @Test("바뀐 뒤 식별자가 nil이면 전송이 아님")
    func test바뀐뒤식별자가nil이면_전송이아님() {
        // 다른 입력창으로 옮기거나 키보드를 내릴 때 관찰한 값
        #expect(!isSent(before: document, after: nil, beforeInput: nil, afterInput: nil, selectedText: nil))
    }

    @Test("다른 입력창으로 바뀌면 전송이 아님")
    func test다른입력창으로바뀌면_전송이아님() {
        #expect(!isSent(before: document, after: UUID(), beforeInput: nil, afterInput: nil, selectedText: nil))
    }

    @Test("바뀌기 전 식별자가 nil이면 전송이 아님")
    func test바뀌기전식별자가nil이면_전송이아님() {
        #expect(!isSent(before: nil, after: document, beforeInput: nil, afterInput: nil, selectedText: nil))
        #expect(!isSent(before: nil, after: nil, beforeInput: nil, afterInput: nil, selectedText: nil))
    }

    @Test("앞 문맥, 뒤 문맥, 선택 텍스트 중 하나라도 남으면 전송이 아님")
    func test문맥이나선택이남으면_전송이아님() {
        #expect(!isSent(before: document, after: document, beforeInput: "ㅇㅇ", afterInput: nil, selectedText: nil))
        // 전체 선택 첫 단계: 커서가 앞으로 가며 뒤 문맥에 텍스트가 남는다
        #expect(!isSent(before: document, after: document, beforeInput: nil, afterInput: "전체", selectedText: nil))
        #expect(!isSent(before: document, after: document, beforeInput: nil, afterInput: nil, selectedText: "전체"))
    }

    private func isSent(
        before: UUID?,
        after: UUID?,
        beforeInput: String?,
        afterInput: String?,
        selectedText: String?
    ) -> Bool {
        KeyboardSentTextDetectionPolicy.isSentAfterTextChange(
            documentIdentifierBeforeChange: before,
            documentIdentifierAfterChange: after,
            beforeInput: beforeInput,
            afterInput: afterInput,
            selectedText: selectedText
        )
    }
}
```

- [x] **Step 2: 테스트가 컴파일 실패하는지 확인**

```sh
SCR=<scratchpad>
timeout 600 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' \
  -parallel-testing-enabled NO \
  -only-testing:SYKeyboardTests/KeyboardSentTextDetectionPolicyTests > $SCR/task1-red.log 2>&1
grep -E "error:|TEST (SUCCEEDED|FAILED)" $SCR/task1-red.log | head
```

Expected: `cannot find 'KeyboardSentTextDetectionPolicy' in scope`

- [x] **Step 3: Policy 구현과 타깃 등록**

`Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSentTextDetectionPolicy.swift`:

```swift
//
//  KeyboardSentTextDetectionPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/28/26.
//

import Foundation

/// 앱의 전송 버튼으로 입력창이 비었는지 판정하는 정책
///
/// 키보드 확장은 전송 버튼을 알 수 없으므로 `textWillChange` 직후 첫 `textDidChange`의 상태로 추정한다.
/// 입력창을 옮기거나 키보드를 내릴 때도 문맥이 모두 비므로, 같은 입력창(`documentIdentifier`)인지 함께 본다
enum KeyboardSentTextDetectionPolicy {

    static func isSentAfterTextChange(
        documentIdentifierBeforeChange: UUID?,
        documentIdentifierAfterChange: UUID?,
        beforeInput: String?,
        afterInput: String?,
        selectedText: String?
    ) -> Bool {
        guard let documentIdentifierBeforeChange,
              documentIdentifierBeforeChange == documentIdentifierAfterChange else { return false }

        return isEmpty(beforeInput) && isEmpty(afterInput) && isEmpty(selectedText)
    }
}

private extension KeyboardSentTextDetectionPolicy {
    static func isEmpty(_ text: String?) -> Bool {
        return text?.isEmpty ?? true
    }
}
```

`SYKeyboard.xcodeproj/project.pbxproj`에서 `SYKeyboardCore/Presentation/Utils/Policies/KeyboardSelectDirectionPolicy.swift,` 줄이 두 번 나온다(`SYKeyboard` 타깃 목록, `SYKeyboardCore` 타깃 목록). 두 곳 모두 그 바로 아래에 같은 들여쓰기로 한 줄을 넣는다.

```
				SYKeyboardCore/Presentation/Utils/Policies/KeyboardSentTextDetectionPolicy.swift,
```

확인: `grep -c "KeyboardSentTextDetectionPolicy.swift" SYKeyboard.xcodeproj/project.pbxproj` → `2`

- [x] **Step 4: 테스트 통과 확인**

Step 2와 같은 명령(로그 `task1-green.log`). Expected: `** TEST SUCCEEDED **`, 6개 테스트 통과

결과(2026-09-28, iPhone 13 mini / iOS 18.6): RED는 `cannot find 'KeyboardSentTextDetectionPolicy' in scope`로 컴파일 실패, GREEN은 `Test run with 6 tests in 1 suite passed`, `** TEST SUCCEEDED **`. pbxproj 등록 확인 `grep -c` → `2`

- [x] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSentTextDetectionPolicy.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Utils/KeyboardSentTextDetectionPolicyTests.swift \
  docs/superpowers/plans/2026-09-28-ngram-sent-last-word.md
git commit -m "feat: #164 - 전송으로 입력창이 비었는지 판정하는 정책 추가"
```

---

### Task 2: NGram 엔진 문장 버퍼 읽기·복원

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` (`currentSentenceWords` 선언 146행 부근, `resetSentenceBuffer()` 511행 부근)
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift` (`NGramPredictiveTextProviding`, 13–35행)
- Modify: `SYKeyboardTests/Domain/SuggestionControllerTestSupport.swift` (`StubNGramPredictiveTextProvider`)
- Modify: `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift` (`RemovableNGramStub`)
- Test: `SYKeyboardTests/Domain/NGramPredictiveTextEngineSentenceBufferTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `NGramPredictiveTextProviding.currentSentenceWords: [String] { get }`
  - `NGramPredictiveTextProviding.restoreSentenceBuffer(_ words: [String])`
  - `StubNGramPredictiveTextProvider.addedWords: [String]`(비우지 않는 `addWord` 기록), `StubNGramPredictiveTextProvider.endSentenceCount: Int`

- [x] **Step 1: 실패하는 엔진 테스트 작성**

`SYKeyboardTests/Domain/NGramPredictiveTextEngineSentenceBufferTests.swift`:

```swift
//
//  NGramPredictiveTextEngineSentenceBufferTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/28/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 문장 버퍼 복원 검증")
struct NGramPredictiveTextEngineSentenceBufferTests {

    @Test("복원한 문장 버퍼 뒤에 기록한 단어는 앞 단어와 bigram으로 이어짐")
    func test복원한문장버퍼뒤에기록한단어는_앞단어와bigram으로이어짐() async {
        let engine = await makeLoadedNGramFixture(name: "sentence-restore").engine
        recordSeparately(engine, word: "zulu", times: 3)
        engine.addWord("안녕")
        let words = engine.currentSentenceWords
        engine.resetSentenceBuffer()

        engine.restoreSentenceBuffer(words)
        engine.addWord("ㅋㅋ")

        #expect(words == ["안녕"])
        // bigram이 없으면 unigram 점수가 높은 zulu가 먼저 나온다
        #expect(engine.suggestions(for: "안녕 ").first == "ㅋㅋ")
    }

    @Test("복원하지 않으면 리셋 뒤 단어는 앞 단어와 이어지지 않음")
    func test복원하지않으면_리셋뒤단어는_앞단어와이어지지않음() async {
        let engine = await makeLoadedNGramFixture(name: "sentence-no-restore").engine
        recordSeparately(engine, word: "zulu", times: 3)
        engine.addWord("안녕")
        engine.resetSentenceBuffer()

        engine.addWord("ㅋㅋ")

        #expect(engine.suggestions(for: "안녕 ").first == "zulu")
    }

    @Test("복원만 하면 아무것도 기록하지 않음")
    func test복원만하면_아무것도기록하지않음() async {
        let engine = await makeLoadedNGramFixture(name: "sentence-restore-only").engine

        engine.restoreSentenceBuffer(["alpha", "bravo"])

        #expect(engine.currentSentenceWords == ["alpha", "bravo"])
        #expect(engine.suggestions(for: "") == [])
    }

    /// 단어를 매번 다른 문장으로 기록해 unigram 점수만 올린다
    private func recordSeparately(_ engine: NGramPredictiveTextEngine, word: String, times: Int) {
        for _ in 0..<times {
            engine.addWord(word)
            engine.endSentence()
        }
    }
}
```

- [x] **Step 2: 컴파일 실패 확인**

```sh
timeout 600 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' \
  -parallel-testing-enabled NO \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineSentenceBufferTests > $SCR/task2-red.log 2>&1
grep -E "error:|TEST (SUCCEEDED|FAILED)" $SCR/task2-red.log | head
```

Expected: `'currentSentenceWords' is inaccessible due to 'private' protection level`와 `value of type 'NGramPredictiveTextEngine' has no member 'restoreSentenceBuffer'`

- [x] **Step 3: 엔진·프로토콜·stub 구현**

`NGramPredictiveTextEngine.swift`의 선언을 바꾼다.

```swift
    /// 현재 문장의 단어 버퍼
    private(set) var currentSentenceWords: [String] = []
```

같은 파일 `resetSentenceBuffer()` 바로 아래에 추가한다.

```swift
    /// 문장 버퍼를 주어진 단어들로 바꿉니다.
    ///
    /// 입력창이 비워지기 직전의 문장 버퍼를 되돌려, 보낸 마지막 단어를 앞 단어와 이어 기록할 때 호출합니다.
    /// 기록·저장은 하지 않습니다.
    func restoreSentenceBuffer(_ words: [String]) {
        currentSentenceWords = words
    }
```

`SuggestionController.swift`의 `NGramPredictiveTextProviding`에서 `currentSentenceWordsCount` 아래와 `resetSentenceBuffer()` 아래에 각각 추가한다.

```swift
    /// 현재 문장 버퍼의 단어
    var currentSentenceWords: [String] { get }
```

```swift
    /// 문장 버퍼를 주어진 단어들로 바꿉니다. 기록·저장은 하지 않습니다.
    func restoreSentenceBuffer(_ words: [String])
```

`SuggestionControllerTestSupport.swift`의 `StubNGramPredictiveTextProvider`:

```swift
    var currentSentenceWordsCount: Int { recordedWords.count }
    var currentSentenceWords: [String] { recordedWords }

    private(set) var saveCount = 0
    /// `addWord`로 들어온 단어 전체. 문장 버퍼와 달리 비우지 않는다
    private(set) var addedWords: [String] = []
    private(set) var endSentenceCount = 0
```

같은 stub의 메서드를 바꾸고 추가한다.

```swift
    func addWord(_ word: String) {
        recordedWords.append(word)
        addedWords.append(word)
    }

    func endSentence() {
        recordedWords.removeAll()
        endSentenceCount += 1
    }
```

```swift
    func restoreSentenceBuffer(_ words: [String]) {
        recordedWords = words
    }
```

`SuggestionControllerSuggestionRemovalTests.swift`의 `RemovableNGramStub`:

```swift
    var currentSentenceWordsCount: Int { 0 }
    var currentSentenceWords: [String] { [] }
```

```swift
    func resetSentenceBuffer() {}
    func restoreSentenceBuffer(_ words: [String]) {}
```

- [x] **Step 4: 테스트 통과 확인**

Step 2와 같은 명령(로그 `task2-green.log`). Expected: `** TEST SUCCEEDED **`, 3개 테스트 통과

결과(2026-09-28, iPhone 13 mini / iOS 18.6): RED는 `'currentSentenceWords' is inaccessible due to 'private' protection level`, `value of type 'NGramPredictiveTextEngine' has no member 'restoreSentenceBuffer'`로 컴파일 실패, GREEN은 `Test run with 3 tests in 1 suite passed`, `** TEST SUCCEEDED **`

- [x] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift \
  Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineSentenceBufferTests.swift \
  SYKeyboardTests/Domain/SuggestionControllerTestSupport.swift \
  SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift \
  docs/superpowers/plans/2026-09-28-ngram-sent-last-word.md
git commit -m "feat: #164 - NGram 문장 버퍼를 읽고 되돌리는 기능 추가"
```

---

### Task 3: SuggestionController 복원 기록 API

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift` (`endSentence(inputBuffer:)` 선언 아래)
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift` (`endSentence(inputBuffer:)` 673행 부근 아래)
- Test: `SYKeyboardTests/Domain/SuggestionControllerSentTextTests.swift`

**Interfaces:**
- Consumes: Task 2의 `currentSentenceWords`, `restoreSentenceBuffer(_:)`, stub의 `addedWords`·`endSentenceCount`
- Produces:
  - `SuggestionService.sentenceWordsSnapshot() -> [String]`
  - `SuggestionService.endSentence(inputBuffer: String, restoringSentenceWords sentenceWords: [String])`

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Domain/SuggestionControllerSentTextTests.swift`:

```swift
//
//  SuggestionControllerSentTextTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/28/26.
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("자동완성 컨트롤러 보낸 문장 기록 검증")
struct SuggestionControllerSentTextTests {

    @Test("문장 버퍼를 복원해 끝내면 기록하지 않은 단어만 추가하고 문장을 끝냄")
    func test문장버퍼를복원해끝내면_기록하지않은단어만추가하고_문장을끝냄() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)
        controller.recordWord("안녕")
        let snapshot = controller.sentenceWordsSnapshot()
        controller.resetSentenceBuffer()

        controller.endSentence(inputBuffer: "안녕 ㅋㅋ", restoringSentenceWords: snapshot)

        #expect(snapshot == ["안녕"])
        #expect(factory.lastNGramProvider?.addedWords == ["안녕", "ㅋㅋ"])
        #expect(factory.lastNGramProvider?.endSentenceCount == 1)
        #expect(factory.lastNGramProvider?.currentSentenceWordsCount == 0)
    }

    @Test("단어 하나만 보내면 그 단어를 기록")
    func test단어하나만보내면_그단어를기록() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)

        controller.endSentence(inputBuffer: "ㅇㅇ", restoringSentenceWords: controller.sentenceWordsSnapshot())

        #expect(factory.lastNGramProvider?.addedWords == ["ㅇㅇ"])
        #expect(factory.lastNGramProvider?.endSentenceCount == 1)
    }

    @Test("끝이 공백이면 이미 기록한 단어를 다시 세지 않고 문장만 끝냄")
    func test끝이공백이면_이미기록한단어를다시세지않고_문장만끝냄() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)
        controller.recordWord("안녕")
        let snapshot = controller.sentenceWordsSnapshot()
        controller.resetSentenceBuffer()

        controller.endSentence(inputBuffer: "안녕 ", restoringSentenceWords: snapshot)

        #expect(factory.lastNGramProvider?.addedWords == ["안녕"])
        #expect(factory.lastNGramProvider?.endSentenceCount == 1)
    }

    @Test("엔진을 만들기 전이면 빈 스냅샷을 반환")
    func test엔진을만들기전이면_빈스냅샷을반환() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)

        #expect(controller.sentenceWordsSnapshot() == [])
        #expect(factory.nGramCreationCount == 0)
    }

    @Test("예측 입력이 꺼져 있으면 기록하지 않음")
    func test예측입력이꺼져있으면_기록하지않음() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)
        controller.isPredictiveTextEnabled = false

        controller.endSentence(inputBuffer: "ㅇㅇ", restoringSentenceWords: [])

        #expect(factory.nGramCreationCount == 0)
    }

    @Test("일시 중단 중이면 기록하지 않음")
    func test일시중단중이면_기록하지않음() {
        let factory = CountingSuggestionEngineFactory()
        let controller = makeController(factory: factory)
        controller.recordWord("안녕")
        let snapshot = controller.sentenceWordsSnapshot()
        controller.resetSentenceBuffer()
        controller.isSuspended = true

        controller.endSentence(inputBuffer: "안녕 ㅋㅋ", restoringSentenceWords: snapshot)

        #expect(factory.lastNGramProvider?.addedWords == ["안녕"])
        #expect(factory.lastNGramProvider?.endSentenceCount == 0)
    }

    private func makeController(factory: CountingSuggestionEngineFactory) -> SuggestionController {
        let controller = SuggestionController(language: "ko-KR", engineFactory: factory.makeFactory())
        controller.isPredictiveTextEnabled = true
        return controller
    }
}
```

- [x] **Step 2: 컴파일 실패 확인**

```sh
timeout 600 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' \
  -parallel-testing-enabled NO \
  -only-testing:SYKeyboardTests/SuggestionControllerSentTextTests > $SCR/task3-red.log 2>&1
grep -E "error:|TEST (SUCCEEDED|FAILED)" $SCR/task3-red.log | head
```

Expected: `value of type 'SuggestionController' has no member 'sentenceWordsSnapshot'`

- [x] **Step 3: API 구현**

`SuggestionService.swift`의 `func endSentence(inputBuffer: String)` 선언 바로 아래:

```swift
    /// 현재 n-gram 문장 버퍼의 단어를 반환합니다.
    ///
    /// 입력창이 외부에서 바뀌기 직전(`textWillChange`)에 떠 두었다가 `endSentence(inputBuffer:restoringSentenceWords:)`에 넘깁니다.
    func sentenceWordsSnapshot() -> [String]

    /// 문장 버퍼를 `sentenceWords`로 되돌린 뒤 미기록 단어를 기록하고 문장 버퍼를 초기화합니다.
    ///
    /// 앱의 전송 버튼으로 입력창이 비었다고 판단했을 때 호출합니다.
    func endSentence(inputBuffer: String, restoringSentenceWords sentenceWords: [String])
```

`SuggestionController.swift`의 `func endSentence(inputBuffer: String) { ... }` 바로 아래:

```swift
    func sentenceWordsSnapshot() -> [String] {
        return nGramEngine?.currentSentenceWords ?? []
    }

    func endSentence(inputBuffer: String, restoringSentenceWords sentenceWords: [String]) {
        guard isPredictiveTextEnabled, !isSuspended else { return }
        preparePredictiveEnginesIfNeeded()
        nGramEngine?.restoreSentenceBuffer(sentenceWords)
        endSentence(inputBuffer: inputBuffer)
    }
```

- [x] **Step 4: 테스트 통과 확인**

Step 2와 같은 명령(로그 `task3-green.log`). Expected: `** TEST SUCCEEDED **`, 6개 테스트 통과

결과(2026-09-28, iPhone 13 mini / iOS 18.6): RED는 `value of type 'SuggestionController' has no member 'sentenceWordsSnapshot'`, `extra argument 'restoringSentenceWords' in call`로 컴파일 실패, GREEN은 `Test run with 6 tests in 1 suite passed`, `** TEST SUCCEEDED **`

- [x] **Step 5: 커밋**

```sh
git add Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift \
  Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  SYKeyboardTests/Domain/SuggestionControllerSentTextTests.swift \
  docs/superpowers/plans/2026-09-28-ngram-sent-last-word.md
git commit -m "feat: #164 - 문장 버퍼를 되돌려 보낸 문장을 기록하는 API 추가"
```

---

### Task 4: VC에서 스냅샷 보관·판정·기록 연결

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
  - 프로퍼티: `private var smartQuoteState` 선언(131행 부근) 아래
  - `textWillChange(_:)`: `resetInputBuffer()` 호출(409행 부근) 바로 위
  - `textDidChange(_:)`: `synchronizeDeleteInteractionInputIdentifier(textInput)` 호출(422행 부근) 바로 아래
  - `viewWillDisappear(_:)`: `resetInputBuffer()` 호출(477행 부근) 바로 위
  - helper: `// MARK: - TextInteractionGestureControllerDelegate` 줄 바로 위에 private extension 추가

**Interfaces:**
- Consumes: Task 1 `KeyboardSentTextDetectionPolicy.isSentAfterTextChange(...)`, Task 3 `sentenceWordsSnapshot()`, `endSentence(inputBuffer:restoringSentenceWords:)`
- Produces: 없음(VC 내부 private)

VC 연결은 자동 테스트로 고정하지 않는다(spec "테스트" 절). 이 task의 검증은 빌드와 Task 5의 수동 확인이다.

- [x] **Step 1: 프로퍼티 추가**

`private var smartQuoteState = KeyboardSmartQuoteState()` 아래:

```swift
    /// `textWillChange`에서 리셋 직전에 떠 두는 입력 상태. 바로 다음 `textDidChange`에서 전송 여부를 판단한 뒤 비운다
    private var pendingSentTextSnapshot: SentTextSnapshot?
```

`SentTextSnapshot`은 Step 2에서 파일 최상위 `private struct`로 선언한다. 클래스 안에 중첩하면 private extension의 메서드(fileprivate) 반환 타입으로 쓸 때 접근 수준 오류가 난다.

- [x] **Step 2: 콜백 연결**

`textWillChange(_:)`:

```swift
        pendingSentTextSnapshot = makeSentTextSnapshot()
        resetInputBuffer()
```

`textDidChange(_:)`, `synchronizeDeleteInteractionInputIdentifier(textInput)` 바로 아래:

```swift
        // 한영 키보드가 trait 변화로 언어를 다시 판정하기(`inputTraitsDidChange`) 전에, 스냅샷을 뜬 엔진에 기록한다
        recordSentTextIfNeeded()
```

`viewWillDisappear(_:)`:

```swift
        pendingSentTextSnapshot = nil
        resetInputBuffer()
```

`// MARK: - TextInteractionGestureControllerDelegate` 바로 위:

```swift
// MARK: - Sent Text Recording

/// 전송 판정과 기록에 쓰는 `textWillChange` 시점의 입력 상태
private struct SentTextSnapshot {
    let inputBuffer: String
    let sentenceWords: [String]
    let documentIdentifier: UUID?
}

private extension BaseKeyboardViewController {
    /// 기록하지 않은 입력이 있을 때만 스냅샷을 만든다
    func makeSentTextSnapshot() -> SentTextSnapshot? {
        guard inputBuffer.contains(where: { !$0.isWhitespace }) else { return nil }
        return SentTextSnapshot(
            inputBuffer: inputBuffer,
            sentenceWords: suggestionController.sentenceWordsSnapshot(),
            documentIdentifier: currentDocumentIdentifier()
        )
    }

    /// 입력창이 전송으로 비었으면 스냅샷의 마지막 단어까지 기록하고 문장을 끝낸다
    func recordSentTextIfNeeded() {
        guard let snapshot = pendingSentTextSnapshot else { return }
        pendingSentTextSnapshot = nil
        guard KeyboardSentTextDetectionPolicy.isSentAfterTextChange(
            documentIdentifierBeforeChange: snapshot.documentIdentifier,
            documentIdentifierAfterChange: currentDocumentIdentifier(),
            beforeInput: textDocumentProxy.documentContextBeforeInput,
            afterInput: textDocumentProxy.documentContextAfterInput,
            selectedText: textDocumentProxy.selectedText
        ) else { return }

        suggestionController.endSentence(
            inputBuffer: snapshot.inputBuffer,
            restoringSentenceWords: snapshot.sentenceWords
        )
    }

    /// 헤더는 nonnull이지만 키보드가 처음 뜰 때나 입력창이 바뀌는 순간 nil이 온다.
    /// Swift 프로퍼티로 읽으면 `UUID` 브리징에서 크래시하므로 KVC로 읽는다
    func currentDocumentIdentifier() -> UUID? {
        return (textDocumentProxy as AnyObject).value(forKey: "documentIdentifier") as? UUID
    }
}
```

- [x] **Step 3: 4개 scheme 빌드**

```sh
for S in SYKeyboard HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme $S \
    -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' > $SCR/task4-$S.log 2>&1
  echo "$S $(grep -E 'BUILD (SUCCEEDED|FAILED)' $SCR/task4-$S.log)"
done
git status --short
```

Expected: 4개 모두 `** BUILD SUCCEEDED **`. `.xcscheme`이 `RemotePath`만 바뀌었으면 되돌린다.

결과(2026-09-28, iPhone 13 mini / iOS 18.6 대상): `SYKeyboard`, `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` 모두 `** BUILD SUCCEEDED **`, 오류 없음. 빌드 뒤 `git status --short`에 `.xcscheme` 변경 없음

- [x] **Step 4: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  docs/superpowers/plans/2026-09-28-ngram-sent-last-word.md
git commit -m "feat: #164 - 전송으로 입력창이 비면 마지막 단어까지 NGram에 기록"
```

---

### Task 5: 전체 테스트와 수동 확인

**Files:**
- Modify: `docs/superpowers/plans/2026-09-28-ngram-sent-last-word.md` (결과 기록)

**Interfaces:**
- Consumes: Task 1–4 전체
- Produces: 검증 기록

- [x] **Step 1: 전체 테스트**

```sh
timeout 900 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' \
  -parallel-testing-enabled NO -resultBundlePath $SCR/task5-all.xcresult > $SCR/task5-all.log 2>&1
grep -E "TEST (SUCCEEDED|FAILED)|Test run with" $SCR/task5-all.log | tail -3
```

Expected: `** TEST SUCCEEDED **`. 실제 테스트 개수와 `.xcresult` 경로를 이 문서에 기록한다.

결과(2026-09-28, iPhone 13 mini / iOS 18.6): `Test run with 842 tests in 94 suites passed`, `** TEST SUCCEEDED **`. 로그 `<scratchpad>/task5-all.log`, 결과 번들 `<scratchpad>/task5-all.xcresult`(세션 scratchpad라 보존되지 않음). 재확인은 위 명령을 그대로 다시 실행한다

- [x] **Step 2: 시뮬레이터 수동 확인**

준비: Task 4 빌드를 설치하고(`xcrun simctl install <UDID> <DerivedData>/Build/Products/Debug-iphonesimulator/SYKeyboard.app`), 메시지 앱 목록의 `+1 (888) 555-1212` 더미 대화를 연다. 입력창 포커스와 전송 버튼 클릭은 idb 탭이 먹지 않아 사용자에게 요청한다. 우리 키보드 키는 idb 좌표 탭으로 입력한다.

1. `ㅇㅇ` 전송 뒤 `ㅇ` 입력 → 완성 후보에 `ㅇㅇ`
2. `안녕 ㅋㅋ` 전송 뒤 `안녕 ` 입력 → 다음 단어 후보 첫 칸 근처에 `ㅋㅋ`
3. 연락처 앱 새 연락처에서 이름 칸에 `이동` 입력 뒤 성 칸으로 이동 → `이` 입력 때 `이동`이 후보에 없음
4. `닫기` 입력 뒤 키보드 내리기 → 다시 열어 `닫` 입력 때 `닫기`가 후보에 없음
5. `전체` 입력 → 전체 선택 → 삭제 → `전` 입력 때 `전체`가 후보에 없음
6. `ㄱ` 한 글자 입력 뒤 키보드 삭제로 비우기 → `ㄱ`이 후보에 없음. 키보드의 선택 기능으로 전체 선택 뒤 삭제도 같은지 확인
7. 기존 동작: `오늘 ` 스페이스 학습, 리턴 학습, 커서 이동 뒤 입력이 전과 같음

각 항목의 결과(통과/실패, 확인하지 못한 이유)를 이 문서에 기록한다.

결과(2026-09-28, iPhone 13 mini / iOS 18.6, HangeulKeyboard만 켠 상태, 시작 시 `ngram_ko-KR.plist` 없음). 학습 여부는 후보 바와
App Group `Library/Application Support/ngram_ko-KR.plist`(`plutil -p`)로 함께 확인했다. 시뮬레이터 이미 학습된 단어와 섞이지 않게 드문 토큰을 썼다.

| # | 동작 | 결과 |
|---|---|---|
| 1 | 메시지 더미 대화에서 `ㅁㄴ` 전송 | 통과. unigram `ㅁㄴ` 저장, `ㅁ` 입력 때 완성 후보에 `ㅁㄴ` |
| 2 | `안녕 ㅍㅍ` 전송 | 통과. bigram `안녕 → ㅍㅍ` 저장, `안녕`은 한 번만 기록(점수 약 1.0), `안녕 ` 입력 때 첫 후보 `ㅍㅍ` |
| 3 | 연락처 새 연락처 이름 칸 `ㅌㅊ` → 성 칸으로 이동 | 판단 보류. `ㅌㅊ`는 저장되지 않았지만 이름 칸은 후보 바가 비어 자동완성이 일시 중단(`isSuspended`)된 입력창으로 보여, Policy가 걸렀다는 근거가 되지 않는다. Step 3 실기기에서 확인 |
| 4 | `안녕 ㄷㄱ` 입력 뒤 뒤로 가기로 대화를 나가 키보드 닫기 | 통과. 닫힐 때 저장된 파일에 `ㄷㄱ` 없음 |
| 5 | 초안 뒤 `ㅋㅌ` 입력 → 편집 메뉴 `Select All` → 키보드 삭제 | 통과. 입력창이 비었고 파일 변경 없음, `ㅋㅌ` 없음 |
| 6 | `ㅁ` 한 글자를 키보드 삭제로 지워 비우기 | 통과. 파일에 `ㅁ` 없음. 키보드 자체 선택 기능 뒤 삭제는 확인하지 못함(Step 3) |
| 7 | 스페이스·리턴 학습, 커서 이동 | 스페이스(`안녕`), 리턴(`ㅎㅎ`) 통과. 커서 이동은 iOS 18.6에서 idb 스와이프가 재현되지 않아 확인하지 못함(Step 3) |

입력창 포커스, 전송 버튼, `Select All`, 성 칸 이동은 idb 탭이 먹지 않아 사용자가 시뮬레이터 창에서 직접 클릭했다.

- [x] **Step 3: 실기기 카카오톡 확인**

사용자에게 Task 4 빌드를 SNMac's iPhone에 설치해 달라고 요청하고 Step 2의 1·2·3·5를 카카오톡에서 확인한다. 결과를 이 문서에 기록한다.

결과(2026-09-28, SNMac's iPhone(iPhone 15 Pro Max) 카카오톡, 사용자가 Xcode로 설치하고 직접 확인). 기기에 이미 학습된 단어와 겹치지 않게 드문 자모 조합을 썼다.

| # | 동작 | 결과 |
|---|---|---|
| A | `ㅊㅍㅋ` 전송 → `ㅊ` 입력 | 통과. 완성 후보에 `ㅊㅍㅋ` |
| B | `안녕 ㅌㅍㅊ` 전송 → `안녕 ` 입력 | 통과. 다음 단어 후보에 `ㅌㅍㅊ` |
| C | 채팅 입력창 `ㅍㅊㅌ` → 후보 바가 보이는 빈 입력창으로 이동 → `ㅍ` 입력 | 통과. `ㅍㅊㅌ` 없음(Step 2의 3번 판단 보류를 대신함) |
| D | `ㅋㅊㅍ` → 전체 선택 → 잘라내기 → `ㅋ` 입력 | 통과. `ㅋㅊㅍ` 없음 |
| E | 키보드 자체 기능으로 선택 → 삭제로 비우기 → 첫 자모 입력 | 통과. 후보에 없음 |
| F | `가나 다라` 입력 → 스페이스 드래그로 `가나` 뒤로 커서 이동 → `다라` 입력 | 통과. 이동 직후 빈 문맥 후보 표시, 이동한 자리에 입력되어 `가나다라 다라`, 후보는 `다라` 기준(기존 동작과 같음) |

- [x] **Step 4: 커밋**

```sh
git add docs/superpowers/plans/2026-09-28-ngram-sent-last-word.md
git commit -m "docs: #164 - 보낸 마지막 단어 학습 전체 테스트·수동 확인 결과 기록"
```

실제로는 결과가 나올 때마다 나눠 커밋했다: `39e36fe8`(전체 테스트), `534b87fa`(시뮬레이터), `fc6d1e8a`(실기기 A–E), `3b052d2d`(실기기 F, 이 체크 포함).

# 자동완성 후보 길게 눌러 삭제 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 자동완성 바 후보를 0.7초 길게 누르면 키보드 전체를 덮는 삭제 확인 오버레이를 띄우고, 확정하면 그 단어를 NGram 학습 데이터와 앱이 학습시킨 `UITextChecker` 단어에서 지운다.

**Architecture:** 삭제 로직은 `NGramPredictiveTextEngine.removeWord(_:)`와 `PredictiveTextProvider.canUnlearn/unlearn`에 두고, `SuggestionController`가 후보 출처에 따라 삭제 가능 여부를 판정한다. `SuggestionBarView`는 기존 수동 터치 흐름에 `DispatchWorkItem` 타이머만 더해 길게 누르기를 감지하고, `BaseKeyboardViewController`가 클립보드에서 분리한 `DeleteConfirmOverlayView`를 띄운다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26+

**Spec:** `docs/superpowers/specs/2026-09-18-suggestion-long-press-removal-design.md`

## Global Constraints

- 모든 경로는 워크트리 루트 `.claude/worktrees/feat-139-suggestion-removal` 기준이다. 절대 경로: `/Users/macmillan/Projects/XcodeProjects/SNMac/SYKeyboard/SYKeyboard/.claude/worktrees/feat-139-suggestion-removal`. develop 체크아웃(`/Users/macmillan/Projects/XcodeProjects/SNMac/SYKeyboard/SYKeyboard`)의 파일을 수정하지 않는다.
- 브랜치: `feat/#139-suggestion-removal`. push하지 않는다.
- 길게 누르기 시간은 `0.7`초 고정값이다. 사용자 설정 `longPressDuration`을 쓰지 않는다.
- 짧은 탭·드래그 선택의 이벤트 타이밍과 결과를 바꾸지 않는다. `UILongPressGestureRecognizer`를 쓰지 않는다.
- 삭제할 수 없는 후보(시스템 사전, `UILexicon`, 수식, typing 모드 button1)는 길게 눌러도 기존처럼 선택된다.
- NGram 삭제는 대소문자를 구분하지 않는다. `currentSentenceWords`는 건드리지 않는다.
- 새 `Modules/` 파일은 `SYKeyboard.xcodeproj/project.pbxproj`의 두 `membershipExceptions` 목록에 알파벳 순서로 등록한다. `SYKeyboardTests/` 파일은 등록하지 않는다(동기화 그룹이 자동 포함).
- 테스트는 Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`)을 쓴다. production 클래스에 `ForTesting` 메서드를 추가하지 않는다.
- 로컬라이징 문자열은 `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings`에 넣고 `SYKBDAssets.bundle`로 읽는다. 영어 인용은 둥근 큰따옴표 `“…”`를 쓴다.
- 커밋 메시지: `type: #139 - 한국어 subject`, 마침표 없음, 끝에 `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>` 줄.
- CLAUDE.md 계획 실행 규칙: 각 Task는 검증까지 끝난 직후에만 체크하고, 이 계획 문서의 체크박스·실제 결과(테스트 개수, 빌드 결과)를 같은 Task 커밋에 포함한다.
- `xcodebuild`는 foreground로 실행하고 timeout은 600000ms로 둔다.
- 빌드 후 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 경우 `git checkout -- <파일>`로 되돌린다.

테스트 명령 템플릿 (`<Suite>`만 바꿔 쓴다):

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/<Suite> 2>&1 | tail -40
```

`The test runner timed out while preparing to run tests.`가 나오면 코드 실패가 아니다. 시뮬레이터의 붙여넣기 권한 알림에 응답하고 같은 명령을 다시 실행한다(CLAUDE.md "붙여넣기 권한 알림" 절).

## File Structure

| 파일 | 책임 | Task |
|---|---|---|
| `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift` | 0.7초 상수 | 1 |
| `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` | `removeWord(_:)` | 2 |
| `Modules/SYKeyboardCore/Domain/SuggestionController.swift` | `NGramPredictiveTextProviding.removeWord` 요구사항, 삭제 판정·실행 | 2, 3 |
| `Modules/SYKeyboardCore/Domain/PredictiveText/Protocols/PredictiveTextProvider.swift` | `canUnlearn`/`unlearn` 요구사항과 기본 구현 | 3 |
| `Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift` | `UITextChecker` unlearn | 3 |
| `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift` | VC가 쓰는 프로토콜에 두 메서드 추가 | 3 |
| `Modules/SYKeyboardCore/Presentation/View/Components/Overlays/DeleteConfirmOverlayView.swift` (신규) | 공용 삭제 확인 오버레이 | 4 |
| `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift` | 오버레이 사용, 클립보드 문구 계산 | 4 |
| `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift` | 길게 누르기 타이머, delegate 요청 | 5 |
| `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` | 오버레이 표시·삭제 연결 | 6 |
| `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings` | 확인 문구 2개 | 6 |
| `SYKeyboard.xcodeproj/project.pbxproj` | 새 오버레이 파일 등록 | 4 |
| `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift` | 상수 테스트 | 1 |
| `SYKeyboardTests/Domain/NGramPredictiveTextEngineRemovalTests.swift` (신규) | 엔진 삭제 테스트 | 2 |
| `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift` (신규) | 판정·삭제 테스트 | 3 |
| `SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift` (신규) | 바 길게 누르기 테스트 | 5 |
| `SYKeyboardTests/Domain/SuggestionController{Preparation,TextCheckerLimit,AsyncTextChecker,TextReplacement}Tests.swift` | NGram stub에 `removeWord` 추가 | 2 |
| `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift` | delegate spy에 새 메서드 추가 | 5 |

---

### Task 0: 워크트리 빌드 준비

**Files:** 없음 (gitignore 대상 심볼릭 링크만 만든다)

- [ ] **Step 1: 위치 확인**

Run: `pwd && git branch --show-current && git status --short`
Expected: 워크트리 절대 경로, `feat/#139-suggestion-removal`, 변경 없음

- [ ] **Step 2: Secrets.xcconfig 링크**

앱 타깃 xcconfig가 `#include "Secrets.xcconfig"`를 하므로 워크트리에도 있어야 빌드된다. #138 워크트리와 같은 방식으로 develop 체크아웃의 파일을 링크한다(내용을 새로 만들거나 커밋하지 않는다).

```sh
ln -s /Users/macmillan/Projects/XcodeProjects/SNMac/SYKeyboard/SYKeyboard/SYKeyboard/Resources/Configs/Secrets.xcconfig \
  SYKeyboard/Resources/Configs/Secrets.xcconfig
git status --short
```

Expected: `git status --short` 출력 없음(gitignore 대상)

---

### Task 1: 길게 누르기 시간 정책

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift`
- Test: `SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift`

**Interfaces:**
- Produces: `KeyboardSuggestionSelectionPolicy.removalLongPressDuration: TimeInterval` (= `0.7`)

- [x] **Step 1: 실패하는 테스트 작성**

`KeyboardSuggestionSelectionPolicyTests` 구조체 안 첫 테스트 앞에 추가한다.

```swift
    @Test("자동완성 후보 삭제 길게 누르기 시간은 0.7초")
    func test자동완성후보삭제_길게누르기시간은_0점7초() {
        #expect(KeyboardSuggestionSelectionPolicy.removalLongPressDuration == 0.7)
    }
```

- [x] **Step 2: 실패 확인**

Run: 템플릿의 `<Suite>` = `KeyboardSuggestionSelectionPolicyTests`
Expected: 컴파일 실패 `type 'KeyboardSuggestionSelectionPolicy' has no member 'removalLongPressDuration'`

Result: Confirmed — exact error message received during compilation.

- [x] **Step 3: 구현**

파일 헤더 주석 다음 줄에 `import Foundation`을 추가하고(현재 import 없음, `TimeInterval`에 필요), `enum KeyboardSuggestionSelectionPolicy {` 바로 아래에 추가한다.

```swift
    /// 자동완성 후보 삭제 확인을 띄우는 길게 누르기 시간
    ///
    /// 사용자 설정 `longPressDuration`과 별개다. iOS 기본값 0.5초는 손가락을 댄 채
    /// 옆 후보로 옮겨 고르는 드래그 선택 중에 넘기기 쉬워 조금 길게 둔다
    static let removalLongPressDuration: TimeInterval = 0.7
```

- [x] **Step 4: 통과 확인**

Run: 같은 명령
Expected: `** TEST SUCCEEDED **`, suite 전체 통과

Result: `xcodebuild test ... -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests -parallel-testing-enabled NO GADApplicationIdentifier='ca-app-pub-3940256099942544~1458002511'` 실행, 13 tests passed, `** TEST SUCCEEDED **`. 첫 번째 시도는 -parallel-testing-enabled NO와 GADApplicationIdentifier 플래그 누락으로 테스트 호스트 부팅 시점에 GADInvalidInitializationException(placeholder Secrets.xcconfig가 ADMOB_APP_ID 키로 정의, 필요한 것은 GADApplicationIdentifier)으로 크래시했음.

- [x] **Step 5: 계획 체크 갱신 후 커밋**

이 Task의 체크박스를 `[x]`로 바꾸고 Step 4 아래에 실제 결과(통과 테스트 개수)를 한 줄 적는다.

```bash
git add Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardSuggestionSelectionPolicy.swift \
  SYKeyboardTests/Utils/KeyboardSuggestionSelectionPolicyTests.swift \
  docs/superpowers/plans/2026-09-19-issue-139-suggestion-long-press-removal.md
git commit -m "feat: #139 - 자동완성 후보 삭제 길게 누르기 시간 정책 추가

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: NGram 단어 삭제

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` (`resetSentenceBuffer()` 다음, `// MARK: - Persistence` 앞)
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift:12-29` (`NGramPredictiveTextProviding`)
- Modify: NGram stub 4곳 — `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`, `SuggestionControllerTextCheckerLimitTests.swift`, `SuggestionControllerAsyncTextCheckerTests.swift`, `SuggestionControllerTextReplacementTests.swift`
- Create: `SYKeyboardTests/Domain/NGramPredictiveTextEngineRemovalTests.swift`

**Interfaces:**
- Produces: `NGramPredictiveTextProviding.removeWord(_ word: String)` — 로딩 전이면 무시, 대소문자 무시, 즉시 `saveToDisk()`

- [ ] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Domain/NGramPredictiveTextEngineRemovalTests.swift`:

```swift
//
//  NGramPredictiveTextEngineRemovalTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 단어 삭제 검증")
struct NGramPredictiveTextEngineRemovalTests {

    @Test("삭제한 단어는 unigram·bigram 예측에서 사라짐")
    func test삭제한단어는_unigram_bigram예측에서사라짐() async {
        let fixture = await makeLoadedFixture(name: "removal-suggestions")
        fixture.engine.addWord("오늘")
        fixture.engine.addWord("날씨")
        fixture.engine.endSentence()
        #expect(fixture.engine.suggestions(for: "오늘 ") == ["날씨", "오늘"])

        fixture.engine.removeWord("날씨")

        #expect(fixture.engine.suggestions(for: "오늘 ") == ["오늘"])
        #expect(fixture.engine.suggestions(for: "") == ["오늘"])
    }

    @Test("삭제하면 값과 문맥 키에서 모두 지우고 바로 저장")
    func test삭제하면_값과문맥키에서모두지우고_바로저장() async throws {
        let fixture = await makeLoadedFixture(name: "removal-file")
        fixture.engine.addWord("오늘")
        fixture.engine.addWord("날씨")
        fixture.engine.addWord("좋다")
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        fixture.engine.removeWord("날씨")
        fixture.saveQueue.sync {}

        let data = try Data(contentsOf: fixture.url)
        let plist = try #require(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
        #expect(plist["unigram"] as? [String: Int] == ["오늘": 1, "좋다": 1])
        #expect(plist["bigram"] as? [String: [String: Int]] == [:])
        #expect(plist["trigram"] as? [String: [String: Int]] == [:])
    }

    @Test("대소문자가 다른 같은 단어도 함께 삭제")
    func test대소문자가다른같은단어도_함께삭제() async {
        let fixture = await makeLoadedFixture(name: "removal-case")
        fixture.engine.addWord("Hello")
        fixture.engine.endSentence()
        fixture.engine.addWord("hello")
        fixture.engine.endSentence()

        fixture.engine.removeWord("hello")

        #expect(fixture.engine.suggestions(for: "") == [])
    }
}

private struct EngineFixture {
    let engine: NGramPredictiveTextEngine
    let url: URL
    let saveQueue: DispatchQueue
}

private func makeLoadedFixture(name: String) async -> EngineFixture {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name).plist")
    let saveQueue = DispatchQueue(label: "SYKeyboardTests.ngram.save.\(name)")
    let engine = NGramPredictiveTextEngine(
        language: "test-\(name)",
        fileURL: url,
        legacyStorage: .standard,
        loadApplyDelay: .milliseconds(50),
        saveQueue: saveQueue
    )
    await withCheckedContinuation { continuation in
        engine.onLoadCompleted = {
            continuation.resume()
        }
    }
    return EngineFixture(engine: engine, url: url, saveQueue: saveQueue)
}
```

- [ ] **Step 2: 실패 확인**

Run: `<Suite>` = `NGramPredictiveTextEngineRemovalTests`
Expected: 컴파일 실패 `value of type 'NGramPredictiveTextEngine' has no member 'removeWord'`

- [ ] **Step 3: 엔진 구현**

`NGramPredictiveTextEngine.swift`의 `resetSentenceBuffer()` 메서드 바로 다음에 추가한다.

```swift
    /// 단어를 모든 n-gram 저장소에서 지우고 바로 저장합니다.
    ///
    /// 자동완성 후보를 길게 눌러 삭제할 때 호출합니다. 다시 입력하면 다시 기록됩니다.
    /// `suggestions(for:)`가 소문자 기준으로 중복을 제거하므로 대소문자를 구분하지 않고 지웁니다.
    /// 문장 버퍼는 `inputBuffer`와 단어 수를 맞추는 데 쓰이므로 건드리지 않습니다.
    /// 디스크 로딩이 완료되지 않은 경우 무시됩니다.
    ///
    /// - Parameter word: 지울 단어
    func removeWord(_ word: String) {
        guard isLoaded, !word.isEmpty else { return }

        let target = word.lowercased()
        let matches: (String) -> Bool = { $0.lowercased() == target }
        let droppingWord: ([String: Int]) -> [String: Int]? = { entries in
            let kept = entries.filter { !matches($0.key) }
            return kept.isEmpty ? nil : kept
        }

        unigramStore = unigramStore.filter { !matches($0.key) }
        bigramStore = bigramStore
            .filter { !matches($0.key) }
            .compactMapValues(droppingWord)
        trigramStore = trigramStore
            .filter { entry in
                !entry.key.split(separator: " ").contains { matches(String($0)) }
            }
            .compactMapValues(droppingWord)

        hasUnsavedChanges = true
        saveToDisk()
        logger.debug("[NGram/\(self.language)] 단어 삭제: \"\(word)\"")
    }
```

- [ ] **Step 4: 프로토콜 요구사항 추가**

`SuggestionController.swift`의 `NGramPredictiveTextProviding`에서 `func saveToDisk()` 선언 다음에 추가한다.

```swift
    /// 단어를 모든 n-gram 저장소에서 지우고 저장합니다.
    func removeWord(_ word: String)
```

- [ ] **Step 5: 테스트 stub 4곳 갱신**

아래 4개 파일의 `StubNGramPredictiveTextProvider`에서 `saveToDisk()` 메서드 바로 다음 줄에 추가한다.

```swift
    func removeWord(_ word: String) {}
```

- `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift` (`saveToDisk() { saveCount += 1 }` 블록 다음)
- `SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift`
- `SYKeyboardTests/Domain/SuggestionControllerAsyncTextCheckerTests.swift`
- `SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift`

확인: `grep -c "func removeWord" SYKeyboardTests/Domain/SuggestionController*.swift`에서 위 4개 파일이 각각 1이어야 한다.

- [ ] **Step 6: 통과 확인**

Run: `<Suite>` = `NGramPredictiveTextEngineRemovalTests`, 이어서 기존 NGram suite 회귀 확인:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineRemovalTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEnginePersistenceTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineRankingTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests \
  -only-testing:SYKeyboardTests/NGramPredictiveTextEngineFileMigrationTests \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 7: 계획 체크 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift \
  Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineRemovalTests.swift \
  SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift \
  SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift \
  SYKeyboardTests/Domain/SuggestionControllerAsyncTextCheckerTests.swift \
  SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift \
  docs/superpowers/plans/2026-09-19-issue-139-suggestion-long-press-removal.md
git commit -m "feat: #139 - NGram 학습 데이터에서 단어를 지우는 removeWord 추가

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: 삭제 판정과 실행 (`SuggestionController`)

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/Protocols/PredictiveTextProvider.swift`
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift` (`learn(word:)` 다음)
- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift` (`nGramSuggestionText(at:)` 선언 다음)
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift` (`nGramSuggestionText(at:)` 구현 다음)
- Create: `SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift`

**Interfaces:**
- Consumes: `NGramPredictiveTextProviding.removeWord(_:)` (Task 2)
- Produces:
  - `PredictiveTextProvider.canUnlearn(word: String) -> Bool` (기본 `false`)
  - `PredictiveTextProvider.unlearn(word: String)` (기본 아무것도 하지 않음)
  - `SuggestionService.removableSuggestionText(atBarIndex index: Int) -> String?`
  - `SuggestionService.removeSuggestionWord(_ word: String)`

- [ ] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift`:

```swift
//
//  SuggestionControllerSuggestionRemovalTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("자동완성 후보 삭제 판정·실행 검증")
struct SuggestionControllerSuggestionRemovalTests {

    @Test("n-gram 모드는 바 인덱스의 후보 단어를 삭제 대상으로 반환")
    func testNGram모드는_바인덱스의후보단어를_삭제대상으로반환() {
        let harness = makeHarness(nGramResults: ["오늘", "날씨", "좋다"])

        harness.controller.updateSuggestions(for: "")

        #expect(harness.controller.removableSuggestionText(atBarIndex: 0) == "오늘")
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == "날씨")
        #expect(harness.controller.removableSuggestionText(atBarIndex: 3) == nil)
    }

    @Test("n-gram 후보를 삭제하면 엔진에서 지우고 후보를 다시 전달")
    func testNGram후보를삭제하면_엔진에서지우고_후보를다시전달() {
        let harness = makeHarness(nGramResults: ["오늘", "날씨", "좋다"])
        harness.controller.updateSuggestions(for: "")

        harness.controller.removeSuggestionWord("날씨")

        #expect(harness.nGram.removedWords == ["날씨"])
        #expect(harness.checker.unlearnedWords == [])
        #expect(harness.delegate.updates.last?.suggestions == ["오늘", "좋다"])
    }

    @Test("입력 중에는 현재 단어와 미학습 TextChecker 후보를 삭제 대상에서 제외")
    func test입력중에는_현재단어와미학습TextChecker후보를_삭제대상에서제외() async {
        let harness = makeHarness(
            checkerResults: ["hello", "help"],
            learnedWords: ["help"]
        )

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last?.suggestions == ["hello", "help"])
        #expect(harness.controller.removableSuggestionText(atBarIndex: 0) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 2) == "help")
    }

    @Test("학습한 TextChecker 후보를 삭제하면 unlearn하고 후보에서 뺌")
    func test학습한TextChecker후보를삭제하면_unlearn하고_후보에서뺌() async {
        let harness = makeHarness(
            checkerResults: ["hello", "help"],
            learnedWords: ["help"]
        )
        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        harness.controller.removeSuggestionWord("help")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.checker.unlearnedWords == ["help"])
        #expect(harness.nGram.removedWords == ["help"])
        #expect(harness.delegate.updates.last?.suggestions == ["hello"])
    }

    @Test("텍스트 대치 후보는 삭제 대상이 아님")
    func test텍스트대치후보는_삭제대상이아님() async {
        let harness = makeHarness(
            lexiconEntries: [TextReplacementEntry(userInput: "hel", documentText: "first")]
        )

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last?.suggestions == ["first"])
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == nil)
    }

    @Test("수식 후보는 삭제 대상이 아님")
    func test수식후보는_삭제대상이아님() {
        let harness = makeHarness(nGramResults: ["오늘"])

        harness.controller.updateSuggestions(for: "3 - 1 =")

        #expect(harness.controller.currentMode == .mathExpression)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 0) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 1) == nil)
        #expect(harness.controller.removableSuggestionText(atBarIndex: 2) == nil)
    }

    private struct Harness {
        let controller: SuggestionController
        let delegate: RecordingSuggestionControllerDelegate
        let nGram: RemovableNGramStub
        let checker: LearnedWordCheckerStub
        let queue: DispatchQueue
    }

    private func makeHarness(
        nGramResults: [String] = [],
        checkerResults: [String] = [],
        learnedWords: Set<String> = [],
        lexiconEntries: [TextReplacementEntry] = []
    ) -> Harness {
        let nGram = RemovableNGramStub(results: nGramResults)
        let checker = LearnedWordCheckerStub(results: checkerResults, learnedWords: learnedWords)
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in nGram }
        )
        let queue = DispatchQueue(label: "SYKeyboardTests.suggestion.removal")
        let controller = SuggestionController(
            language: "en-US",
            engineFactory: factory,
            textCheckerQueue: queue
        )
        let delegate = RecordingSuggestionControllerDelegate()
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        return Harness(controller: controller, delegate: delegate, nGram: nGram, checker: checker, queue: queue)
    }
}

private final class RemovableNGramStub: NGramPredictiveTextProviding {
    var onLoadCompleted: (() -> Void)?
    var currentSentenceWordsCount: Int { 0 }

    private var results: [String]
    private(set) var removedWords: [String] = []

    init(results: [String]) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] { results }
    func learn(word: String) {}
    func addWord(_ word: String) {}
    func endSentence() {}
    func removeLastWord() {}
    func resetSentenceBuffer() {}
    func saveToDisk() {}

    func removeWord(_ word: String) {
        removedWords.append(word)
        results.removeAll { $0 == word }
    }
}

/// `UITextChecker` 전역 사전 대신 학습 여부를 주입해 판정 분기를 확인한다
private final class LearnedWordCheckerStub: PredictiveTextProvider, @unchecked Sendable {
    private var results: [String]
    private let learnedWords: Set<String>
    private(set) var unlearnedWords: [String] = []

    init(results: [String], learnedWords: Set<String>) {
        self.results = results
        self.learnedWords = learnedWords
    }

    func suggestions(for baseText: String) -> [String] { results }
    func learn(word: String) {}

    func canUnlearn(word: String) -> Bool {
        learnedWords.contains(word)
    }

    func unlearn(word: String) {
        guard learnedWords.contains(word) else { return }
        unlearnedWords.append(word)
        results.removeAll { $0 == word }
    }
}

private final class StubLexiconSuggestionProvider: LexiconSuggestionProviding {
    private let entries: [TextReplacementEntry]
    var hasLoadedLexicon: Bool { true }

    init(entries: [TextReplacementEntry]) {
        self.entries = entries
    }

    func textReplacementEntries(matching lowercasedWord: String) -> [TextReplacementEntry] {
        entries.filter { $0.userInput.lowercased() == lowercasedWord }
    }

    func suggestions(for baseText: String) -> [String] {
        let currentWord = baseText.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? ""
        return textReplacementEntries(matching: currentWord.lowercased()).map(\.documentText)
    }

    func learn(word: String) {}
}

private final class RecordingSuggestionControllerDelegate: SuggestionControllerDelegate {
    struct Update: Equatable {
        let currentWord: String?
        let suggestions: [String]
    }

    private(set) var updates: [Update] = []

    func suggestionController(
        _ controller: SuggestionController,
        didUpdateCurrentWord currentWord: String?,
        suggestions: [String]
    ) {
        updates.append(Update(currentWord: currentWord, suggestions: suggestions))
    }
}

private func waitForMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            continuation.resume()
        }
    }
}
```

- [ ] **Step 2: 실패 확인**

Run: `<Suite>` = `SuggestionControllerSuggestionRemovalTests`
Expected: 컴파일 실패 `value of type 'SuggestionController' has no member 'removableSuggestionText'`

- [ ] **Step 3: `PredictiveTextProvider`에 요구사항과 기본 구현 추가**

프로토콜의 `func learn(word: String)` 선언 다음에:

```swift
    /// 앱이 학습시킨 단어라 `unlearn(word:)`로 되돌릴 수 있는지 반환합니다.
    ///
    /// - Parameter word: 확인할 단어
    /// - Returns: 되돌릴 수 있으면 `true`
    func canUnlearn(word: String) -> Bool
    /// 앱이 학습시킨 단어를 학습 데이터에서 제거합니다.
    ///
    /// - Parameter word: 제거할 단어
    func unlearn(word: String)
```

`extension PredictiveTextProvider`의 `suggestions(for:limit:)` 다음에:

```swift

    func canUnlearn(word: String) -> Bool { false }

    func unlearn(word: String) {}
```

- [ ] **Step 4: `TextCheckerPredictiveTextEngine` 구현**

`learn(word:)` 메서드 다음에:

```swift
    func canUnlearn(word: String) -> Bool {
        UITextChecker.hasLearnedWord(word)
    }

    func unlearn(word: String) {
        guard !word.isEmpty, UITextChecker.hasLearnedWord(word) else { return }
        UITextChecker.unlearnWord(word)
        learnedWords.remove(word)

        logger.debug("[TextChecker] 시스템 사전 학습 해제: \(word)")
    }
```

- [ ] **Step 5: `SuggestionService`에 메서드 선언 추가**

`func nGramSuggestionText(at index: Int) -> String?` 선언 다음에:

```swift

    /// 길게 눌러 삭제할 수 있는 후보면 그 단어를 반환합니다.
    ///
    /// n-gram 후보와 앱이 학습시킨 TextChecker 후보만 삭제할 수 있습니다.
    ///
    /// - Parameter index: 바에서 누른 후보 인덱스 (0~2). 입력 중 모드의 0번은 현재 단어다
    /// - Returns: 삭제할 단어, 삭제할 수 없으면 `nil`
    func removableSuggestionText(atBarIndex index: Int) -> String?

    /// 앱 학습 데이터(n-gram, TextChecker)에서 단어를 지우고 후보를 다시 계산합니다.
    ///
    /// - Parameter word: 지울 단어
    func removeSuggestionWord(_ word: String)
```

- [ ] **Step 6: `SuggestionController` 구현**

`nGramSuggestionText(at:)` 구현 다음에:

```swift
    func removableSuggestionText(atBarIndex index: Int) -> String? {
        let itemIndex: Int
        switch currentMode {
        case .nGram:
            itemIndex = index
        case .typing:
            // 0번 버튼은 현재 입력 단어라 후보 배열은 1번부터 시작한다
            itemIndex = index - 1
        case .mathExpression:
            return nil
        }
        guard currentSuggestions.indices.contains(itemIndex) else { return nil }

        let item = currentSuggestions[itemIndex]
        switch item.source {
        case .nGram:
            return item.text
        case .textChecker:
            return textCheckerEngine?.canUnlearn(word: item.text) == true ? item.text : nil
        default:
            return nil
        }
    }

    func removeSuggestionWord(_ word: String) {
        nGramEngine?.removeWord(word)
        textCheckerEngine?.unlearn(word: word)
        // typing 모드는 직전 TextChecker 후보를 이어받으므로 지운 단어가 한 프레임 다시 보이지 않게 뺀다
        currentSuggestions.removeAll { $0.text == word }
        // 로딩 완료 후 갱신과 같은 마지막 요청값으로 다시 계산한다
        performRefreshSuggestionsAfterNGramLoadIfNeeded()
    }
```

- [ ] **Step 7: 통과 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/SuggestionControllerSuggestionRemovalTests \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests \
  -only-testing:SYKeyboardTests/SuggestionControllerAsyncTextCheckerTests \
  -only-testing:SYKeyboardTests/SuggestionControllerTextCheckerLimitTests \
  -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests \
  -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 8: 계획 체크 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/Protocols/PredictiveTextProvider.swift \
  Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift \
  Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift \
  Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  SYKeyboardTests/Domain/SuggestionControllerSuggestionRemovalTests.swift \
  docs/superpowers/plans/2026-09-19-issue-139-suggestion-long-press-removal.md
git commit -m "feat: #139 - 자동완성 후보 삭제 판정과 학습 데이터 삭제 추가

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: 삭제 확인 오버레이 공용 컴포넌트로 분리 (refactor)

클립보드 동작과 문구는 바꾸지 않는다. 기존 `ClipboardHistoryPanelViewTests`가 회귀 검증이다.

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/View/Components/Overlays/DeleteConfirmOverlayView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift` (`// MARK: - Delete Confirmation`부터 파일 끝까지 이동, `deleteConfirmView`, `requestDelete`)
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `final class DeleteConfirmOverlayView: UIView` — `var onCancel: (() -> Void)?`, `var onConfirm: (() -> Void)?`, `func update(title: String, message: String)`

- [ ] **Step 1: 기준선 확인**

Run: `<Suite>` = `ClipboardHistoryPanelViewTests`
Expected: `** TEST SUCCEEDED **`. 통과 개수를 기록해 둔다.

- [ ] **Step 2: 클래스 이동 스크립트 실행**

```sh
python3 - <<'EOF'
panel = "Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift"
target = "Modules/SYKeyboardCore/Presentation/View/Components/Overlays/DeleteConfirmOverlayView.swift"
s = open(panel).read()
marker = "// MARK: - Delete Confirmation\n"
i = s.index(marker)
moved = s[i + len(marker):].lstrip("\n")
assert moved.count("final class ClipboardHistoryDeleteConfirmView") == 1
open(panel, "w").write(s[:i].rstrip("\n") + "\n")

start = moved.index("    /// 전부 고정이면")
end = moved.index("}\n\n// MARK: - UI Methods")
moved = (
    moved[:start]
    + "    /// 확인 제목과 설명을 바꿉니다\n"
    + "    func update(title: String, message: String) {\n"
    + "        titleLabel.text = title\n"
    + "        messageLabel.text = message\n"
    + "    }\n"
    + moved[end:]
)
moved = moved.replace(
    "/// 고정 항목이 포함된 삭제를 패널 안에서 확인받는 뷰. 앱의 알림과 같은 문구를 쓴다\nprivate final class",
    "/// 키보드 안에서 삭제를 확인받는 오버레이. 키보드 extension은 시스템 알림을 띄울 수 없어 직접 그린다\nfinal class",
)
moved = moved.replace("ClipboardHistoryDeleteConfirmView", "DeleteConfirmOverlayView")
assert "private final class" not in moved
header = (
    "//\n"
    "//  DeleteConfirmOverlayView.swift\n"
    "//  SYKeyboardCore\n"
    "//\n\n"
    "import UIKit\n\n"
    "import SYKeyboardAssets\n\n"
)
open(target, "w").write(header + moved)
EOF
```

- [ ] **Step 3: 패널이 새 오버레이와 문구 계산을 쓰도록 수정**

`ClipboardHistoryPanelView.swift`의 `deleteConfirmView` 선언을 바꾼다.

```swift
    private lazy var deleteConfirmView: DeleteConfirmOverlayView = {
        let view = DeleteConfirmOverlayView()
```

`requestDelete(at:deleteAll:)` 안의 `deleteConfirmView.update(pinnedCount: pinnedCount, totalCount: indices.count)` 줄을 바꾼다.

```swift
        let text = Self.deleteConfirmationText(pinnedCount: pinnedCount, totalCount: indices.count)
        deleteConfirmView.update(title: text.title, message: text.message)
```

`requestDelete(at:deleteAll:)`의 문서 주석 바로 위에 추가한다(같은 extension 안).

```swift
    /// 전부 고정이면 고정 항목 개수를, 미고정이 섞였으면 전체 개수를 제목에 쓰고 고정 개수는 설명에 쓴다
    static func deleteConfirmationText(pinnedCount: Int, totalCount: Int) -> (title: String, message: String) {
        if pinnedCount == totalCount {
            return (
                String(localized: "고정 항목 \(pinnedCount)개를 삭제할까요?", bundle: SYKBDAssets.bundle),
                String(localized: "삭제한 항목은 복구할 수 없습니다.", bundle: SYKBDAssets.bundle)
            )
        }
        return (
            String(localized: "항목 \(totalCount)개를 삭제할까요?", bundle: SYKBDAssets.bundle),
            String(
                localized: "고정 항목 \(pinnedCount)개가 포함되어 있습니다.\n삭제한 항목은 복구할 수 없습니다.",
                bundle: SYKBDAssets.bundle
            )
        )
    }

```

- [ ] **Step 4: pbxproj 등록**

```sh
python3 - <<'EOF'
p = "SYKeyboard.xcodeproj/project.pbxproj"
s = open(p).read()
anchor = "\t\t\t\tSYKeyboardCore/Presentation/View/Components/Overlays/CursorDragIndicatorView.swift,\n"
assert s.count(anchor) == 2, s.count(anchor)
s = s.replace(anchor, anchor + "\t\t\t\tSYKeyboardCore/Presentation/View/Components/Overlays/DeleteConfirmOverlayView.swift,\n")
open(p, "w").write(s)
EOF
grep -n "DeleteConfirmOverlayView" SYKeyboard.xcodeproj/project.pbxproj
```

Expected: 두 줄, 각각 `CursorDragIndicatorView.swift` 바로 다음

- [ ] **Step 5: 회귀 확인**

Run: `<Suite>` = `ClipboardHistoryPanelViewTests`
Expected: `** TEST SUCCEEDED **`, Step 1과 같은 통과 개수

확인: `grep -n "ClipboardHistoryDeleteConfirmView" -r Modules SYKeyboardTests` 출력 없음

- [ ] **Step 6: 계획 체크 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/Components/Overlays/DeleteConfirmOverlayView.swift \
  Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  docs/superpowers/plans/2026-09-19-issue-139-suggestion-long-press-removal.md
git commit -m "refactor: #139 - 클립보드 삭제 확인 뷰를 공용 오버레이로 분리

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: 자동완성 바 길게 누르기

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift`
- Modify: `SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift` (`SuggestionBarRollbackDelegateSpy`)
- Create: `SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift`

**Interfaces:**
- Consumes: `KeyboardSuggestionSelectionPolicy.removalLongPressDuration` (Task 1)
- Produces:
  - `SuggestionBarDelegate.suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool`
  - `SuggestionBarView.handleRemovalLongPress()` (internal, 타이머 발동 시 호출)

- [ ] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift`:

```swift
//
//  SuggestionBarViewRemovalLongPressTests.swift
//  SYKeyboardTests
//

import UIKit
import Testing

@testable import SYKeyboardCore

@Suite("자동완성 바 삭제 길게 누르기 검증")
@MainActor
struct SuggestionBarViewRemovalLongPressTests {

    @Test("삭제를 수락하면 손을 떼도 후보를 선택하지 않음")
    func test삭제를수락하면_손을떼도_후보를선택하지않음() {
        let fixture = makeFixture(acceptsRemoval: true)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.delegate.removalRequestIndexes == [1])
        #expect(fixture.buttons[1].isHighlighted == false)

        let otherPoint = center(of: fixture.buttons[2], in: fixture.bar)
        fixture.bar.moveTouchInteraction(to: otherPoint)
        #expect(fixture.buttons[2].isHighlighted == false)

        fixture.bar.endTouchInteraction(at: otherPoint, playsFeedback: false)

        #expect(fixture.delegate.selectedIndexes == [])
        #expect(fixture.keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("삭제를 거절하면 손을 뗄 때 기존처럼 선택")
    func test삭제를거절하면_손을뗄때_기존처럼선택() {
        let fixture = makeFixture(acceptsRemoval: false)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        fixture.bar.handleRemovalLongPress()
        fixture.bar.endTouchInteraction(at: point, playsFeedback: false)

        #expect(fixture.delegate.removalRequestIndexes == [1])
        #expect(fixture.delegate.selectedIndexes == [1])
    }

    @Test("누른 후보를 벗어나면 삭제를 요청하지 않고 드래그 선택 유지")
    func test누른후보를벗어나면_삭제를요청하지않고_드래그선택유지() {
        let fixture = makeFixture(acceptsRemoval: true)
        let startPoint = center(of: fixture.buttons[0], in: fixture.bar)
        let endPoint = center(of: fixture.buttons[2], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: startPoint)
        fixture.bar.moveTouchInteraction(to: endPoint)
        fixture.bar.handleRemovalLongPress()
        fixture.bar.endTouchInteraction(at: endPoint, playsFeedback: false)

        #expect(fixture.delegate.removalRequestIndexes == [])
        #expect(fixture.delegate.selectedIndexes == [2])
    }

    @Test("터치가 끝난 뒤 타이머가 늦게 불려도 삭제를 요청하지 않음")
    func test터치가끝난뒤_타이머가늦게불려도_삭제를요청하지않음() {
        let fixture = makeFixture(acceptsRemoval: true)
        let point = center(of: fixture.buttons[1], in: fixture.bar)

        fixture.bar.beginTouchInteraction(at: point)
        fixture.bar.endTouchInteraction(at: point, playsFeedback: false)
        fixture.bar.handleRemovalLongPress()

        #expect(fixture.delegate.selectedIndexes == [1])
        #expect(fixture.delegate.removalRequestIndexes == [])
    }

    private struct Fixture {
        let bar: SuggestionBarView
        let keyboardHStackView: UIStackView
        let delegate: RemovalDelegateSpy
        let buttons: [SuggestionButtonView]
    }

    private func makeFixture(acceptsRemoval: Bool) -> Fixture {
        let keyboardHStackView = UIStackView()
        let bar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let delegate = RemovalDelegateSpy(acceptsRemoval: acceptsRemoval)
        bar.suggestionDelegate = delegate
        bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
        bar.updateSuggestions(currentWord: nil, suggestions: ["오늘", "날씨", "좋다"])
        bar.layoutIfNeeded()
        return Fixture(
            bar: bar,
            keyboardHStackView: keyboardHStackView,
            delegate: delegate,
            buttons: typedSuggestionButtonViews(in: bar)
        )
    }
}

private func typedSuggestionButtonViews(
    in view: UIView
) -> [SuggestionButtonView] {
    var result: [SuggestionButtonView] = []
    for subview in view.subviews {
        if let button = subview as? SuggestionButtonView {
            result.append(button)
        }
        result.append(contentsOf: typedSuggestionButtonViews(in: subview))
    }
    return result.sorted {
        $0.convert($0.bounds, to: view).minX
            < $1.convert($1.bounds, to: view).minX
    }
}

private func center(of button: UIView, in bar: UIView) -> CGPoint {
    let frame = button.convert(button.bounds, to: bar)
    return CGPoint(x: frame.midX, y: frame.midY)
}

@MainActor
private final class RemovalDelegateSpy: SuggestionBarDelegate {
    private let acceptsRemoval: Bool
    private(set) var removalRequestIndexes: [Int] = []
    private(set) var selectedIndexes: [Int] = []

    init(acceptsRemoval: Bool) {
        self.acceptsRemoval = acceptsRemoval
    }

    func suggestionBar(_ bar: SuggestionBarView, didSelectSuggestionAt index: Int) {
        selectedIndexes.append(index)
    }

    func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool {
        removalRequestIndexes.append(index)
        return acceptsRemoval
    }

    func suggestionBarDidTapUndo(_ bar: SuggestionBarView) {}
    func suggestionBarDidTapRedo(_ bar: SuggestionBarView) {}
    func suggestionBarDidTapClipboard(_ bar: SuggestionBarView) {}
}
```

- [ ] **Step 2: 실패 확인**

Run: `<Suite>` = `SuggestionBarViewRemovalLongPressTests`
Expected: 컴파일 실패 `value of type 'SuggestionBarView' has no member 'handleRemovalLongPress'`

- [ ] **Step 3: delegate 요구사항 추가**

`SuggestionBarDelegate`의 `didSelectSuggestionAt` 선언 다음에:

```swift
    /// 후보를 길게 눌렀을 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - bar: 이벤트를 발생시킨 `SuggestionBarView`
    ///   - index: 누른 후보의 인덱스 (0~2)
    /// - Returns: 삭제 확인을 띄웠으면 `true`. 이때 이번 터치는 손을 떼도 후보를 선택하지 않습니다
    func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool
```

`SuggestionBarViewPreviewHighlightTests.swift`의 `SuggestionBarRollbackDelegateSpy`에 `didSelectSuggestionAt` 메서드 다음으로 추가한다.

```swift

    func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool {
        false
    }
```

- [ ] **Step 4: 프로퍼티 추가**

`private var previewHighlightIndex: Int?` 다음에:

```swift
    /// 삭제 길게 누르기 대상 후보 인덱스. 누른 후보를 벗어나거나 터치가 끝나면 `nil`이 된다
    private var removalPressedIndex: Int?
    /// 삭제 길게 누르기 타이머
    private var removalLongPressWorkItem: DispatchWorkItem?
    /// 길게 눌러 삭제 확인을 띄운 터치인지 여부. 손을 떼도 후보를 선택하지 않는다
    private var isTouchConsumedByRemoval = false
```

- [ ] **Step 5: 터치 흐름 수정**

`beginTouchInteraction(at:)`, `moveTouchInteraction(to:)`를 다음으로 바꾼다.

```swift
    func beginTouchInteraction(at point: CGPoint) {
        updateHighlight(at: point)
        keyboardHStackView?.isUserInteractionEnabled = false
        scheduleRemovalLongPress(at: point)
    }

    func moveTouchInteraction(to point: CGPoint) {
        guard !isTouchConsumedByRemoval else { return }
        if suggestionButton(at: point)?.0 != removalPressedIndex {
            cancelRemovalLongPress()
        }
        updateHighlight(at: point)
    }
```

`endTouchInteraction(at:playsFeedback:)` 본문 맨 앞에 추가한다(나머지 본문은 그대로).

```swift
        guard !isTouchConsumedByRemoval else {
            resetTouchInteraction()
            return
        }

```

`cancelTouchInteraction()` 다음에 추가한다.

```swift
    /// 삭제 길게 누르기 타이머가 발동했을 때 호출됩니다.
    func handleRemovalLongPress() {
        removalLongPressWorkItem = nil
        guard let index = removalPressedIndex else { return }
        removalPressedIndex = nil
        guard suggestionDelegate?.suggestionBar(self, shouldBeginRemovalAt: index) == true else { return }
        isTouchConsumedByRemoval = true
        clearTouchHighlights()
    }
```

`resetTouchInteraction()`을 다음으로 바꾼다.

```swift
    func resetTouchInteraction() {
        cancelRemovalLongPress()
        isTouchConsumedByRemoval = false
        clearTouchHighlights()
        keyboardHStackView?.isUserInteractionEnabled = true
    }
```

`// MARK: - Private Methods`의 `private extension SuggestionBarView`에서 `actionButton(at:)` 다음에 추가한다.

```swift

    func scheduleRemovalLongPress(at point: CGPoint) {
        cancelRemovalLongPress()
        guard let index = suggestionButton(at: point)?.0 else { return }
        removalPressedIndex = index
        let workItem = DispatchWorkItem { [weak self] in
            self?.handleRemovalLongPress()
        }
        removalLongPressWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + KeyboardSuggestionSelectionPolicy.removalLongPressDuration,
            execute: workItem
        )
    }

    func cancelRemovalLongPress() {
        removalLongPressWorkItem?.cancel()
        removalLongPressWorkItem = nil
        removalPressedIndex = nil
    }
```

- [ ] **Step 6: `BaseKeyboardViewController` 임시 준수**

delegate 요구사항이 늘어 VC가 컴파일되지 않으므로, `extension BaseKeyboardViewController: SuggestionBarDelegate`의 `didSelectSuggestionAt` 다음에 Task 6에서 채울 최소 구현을 추가한다.

```swift

    final func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool {
        false
    }
```

- [ ] **Step 7: 통과 확인**

Run:

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/SuggestionBarViewRemovalLongPressTests \
  -only-testing:SYKeyboardTests/SuggestionBarViewPreviewHighlightTests \
  -only-testing:SYKeyboardTests/KeyboardSuggestionSelectionPolicyTests 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 8: 계획 체크 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/SuggestionBarView.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardTests/Utils/SuggestionBarViewPreviewHighlightTests.swift \
  SYKeyboardTests/Utils/SuggestionBarViewRemovalLongPressTests.swift \
  docs/superpowers/plans/2026-09-19-issue-139-suggestion-long-press-removal.md
git commit -m "feat: #139 - 자동완성 바 후보 길게 누르기로 삭제 요청 추가

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: 오버레이 연결과 로컬라이징

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: `SuggestionService.removableSuggestionText(atBarIndex:)`, `removeSuggestionWord(_:)` (Task 3), `DeleteConfirmOverlayView` (Task 4), `shouldBeginRemovalAt` (Task 5)

- [ ] **Step 1: 로컬라이징 문자열 추가**

Xcode가 쓰는 순서를 유지하도록 키 삽입 위치를 지정한다(Xcode를 열면 다시 정렬될 수 있다).

```sh
python3 - <<'EOF'
import json
p = "SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings"
d = json.load(open(p))

def entry(value):
    return {
        "extractionState": "manual",
        "localizations": {"en": {"stringUnit": {"state": "translated", "value": value}}},
    }

title_key = "'%@'을(를) 자동완성에서 삭제할까요?"
message_key = "다시 입력하면 다시 학습됩니다."
strings = {title_key: entry("Remove “%@” from suggestions?")}
for key, value in d["strings"].items():
    if key == "닫기":
        strings[message_key] = entry("It will be learned again if you type it.")
    strings[key] = value
assert message_key in strings
d["strings"] = strings
open(p, "w").write(json.dumps(d, ensure_ascii=False, indent=2, separators=(",", " : ")) + "\n")
EOF
git diff --stat SYKeyboardAssets
```

Expected: `Localizable.xcstrings`만 추가 줄로 변경

- [ ] **Step 2: 프로퍼티 추가**

`private lazy var requestFullAccessOverlayView = RequestFullAccessOverlayView()` 다음에:

```swift
    /// 자동완성 후보 삭제 확인 오버레이. 처음 길게 누를 때 만든다
    private var suggestionRemovalConfirmView: DeleteConfirmOverlayView?
    /// 삭제 확인을 기다리는 자동완성 단어
    private var pendingSuggestionRemovalWord: String?
```

- [ ] **Step 3: delegate 구현 교체**

Task 5 Step 6의 임시 구현을 다음으로 바꾼다.

```swift
    final func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool {
        guard !BaseKeyboardViewController.isPreview,
              let word = suggestionController.removableSuggestionText(atBarIndex: index) else { return false }
        showSuggestionRemovalConfirmation(for: word)
        return true
    }
```

- [ ] **Step 4: 오버레이 표시·삭제·숨김 구현**

`// MARK: - Full Access Guide` 앞에 새 extension을 추가한다.

```swift
// MARK: - Suggestion Removal

private extension BaseKeyboardViewController {
    func showSuggestionRemovalConfirmation(for word: String) {
        let overlay = suggestionRemovalConfirmView ?? makeSuggestionRemovalConfirmView()
        pendingSuggestionRemovalWord = word
        overlay.update(
            title: String(localized: "'\(word)'을(를) 자동완성에서 삭제할까요?", bundle: SYKBDAssets.bundle),
            message: String(localized: "다시 입력하면 다시 학습됩니다.", bundle: SYKBDAssets.bundle)
        )
        // 나중에 붙은 오버레이보다 위에 보이도록 매번 앞으로 가져온다
        view.bringSubviewToFront(overlay)
        overlay.isHidden = false
        FeedbackManager.shared.playHaptic()
    }

    func confirmSuggestionRemoval() {
        guard let word = pendingSuggestionRemovalWord else { return }
        hideSuggestionRemovalConfirmation()
        suggestionController.removeSuggestionWord(word)
    }

    func hideSuggestionRemovalConfirmation() {
        pendingSuggestionRemovalWord = nil
        suggestionRemovalConfirmView?.isHidden = true
    }

    /// 키보드 전체를 덮어 확인하는 동안 키 입력을 막는다
    func makeSuggestionRemovalConfirmView() -> DeleteConfirmOverlayView {
        let overlay = DeleteConfirmOverlayView()
        overlay.isHidden = true
        overlay.onCancel = { [weak self] in self?.hideSuggestionRemovalConfirmation() }
        overlay.onConfirm = { [weak self] in self?.confirmSuggestionRemoval() }
        view.addSubview(overlay)

        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        suggestionRemovalConfirmView = overlay
        return overlay
    }
}

```

- [ ] **Step 5: 키보드가 사라질 때 닫기**

`viewWillDisappear(_:)`의 `closeClipboardPanelIfNeeded()` 다음 줄에 추가한다.

```swift
        hideSuggestionRemovalConfirmation()
```

- [ ] **Step 6: 전체 테스트와 extension 빌드**

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`. 전체 통과 개수를 기록한다.

```sh
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build \
    -project SYKeyboard.xcodeproj \
    -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' 2>&1 | tail -3
done
git status --short
```

Expected: 세 번 모두 `** BUILD SUCCEEDED **`. `.xcscheme`이 보이면 `git diff`로 `RemotePath`만 바뀌었는지 확인하고 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`로 되돌린다.

- [ ] **Step 7: 계획 체크 갱신 후 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/Localizable.xcstrings \
  docs/superpowers/plans/2026-09-19-issue-139-suggestion-long-press-removal.md
git commit -m "feat: #139 - 자동완성 후보 삭제 확인 오버레이 연결

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: 실제 입력 앱 수동 확인

자동 테스트는 화면·햅틱·호스트 앱 상호작용을 대신하지 못한다. iPhone 13 mini / iOS 18.6 시뮬레이터에서 SY키보드를 켜고 메모 앱 등 입력 앱으로 확인한다. 확인하지 못한 항목은 `[ ]`로 두고 이유를 적는다. 완료로 표시하지 않는다.

**Files:**
- Modify: 이 계획 문서 (결과 기록)

- [ ] **Step 1: 한글 키보드**
  - [ ] 짧은 탭 선택이 기존과 같음
  - [ ] 드래그 선택이 기존과 같고, 드래그 중 오버레이가 뜨지 않음
  - [ ] NGram 후보를 0.7초 누르면 오버레이 표시·햅틱, 손을 떼도 후보가 입력되지 않음
  - [ ] 삭제 후 해당 단어가 다시 나오지 않음 (키보드를 닫았다 열어도)
  - [ ] 취소 시 아무것도 바뀌지 않음
  - [ ] 오버레이가 떠 있는 동안 키 입력이 막힘
  - [ ] 텍스트 대치 후보를 길게 누르고 떼면 기존처럼 입력됨
- [ ] **Step 2: 영어 키보드**
  - [ ] 시스템 사전 후보를 길게 누르고 떼면 기존처럼 입력됨
  - [ ] NGram 후보 삭제가 한글 키보드와 같게 동작
- [ ] **Step 3: 한영 통합 키보드**
  - [ ] 한국어 모드에서 지운 단어가 영어 모드 데이터에 영향 없음
- [ ] **Step 4: 클립보드 회귀**
  - [ ] 고정 항목이 섞인 삭제 확인의 모양·문구·동작이 기존과 같음
- [ ] **Step 5: 결과 기록 후 커밋**

```bash
git add docs/superpowers/plans/2026-09-19-issue-139-suggestion-long-press-removal.md
git commit -m "docs: #139 - 자동완성 후보 삭제 수동 확인 결과 기록

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

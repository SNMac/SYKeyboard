# 자동완성 키 입력 경로 성능 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 자동완성 키 입력 경로의 성능 후보 4곳을 기능 보존형으로 개선하고, TextChecker 비동기화를 되돌리기 쉬운 실험 커밋으로 적용한다.

**Architecture:** `SuggestionController`가 lexicon·TextChecker·n-gram 세 엔진을 조합하는 구조는 그대로 두고, 엔진 내부의 조회·저장 비용만 줄인다. Task 1~4는 입력이 같으면 반환값과 디스크 내용이 현재와 동일한 보존형 변경이고, Task 5만 후보 갱신을 비동기로 바꾼다.

**Tech Stack:** Swift 5, UIKit(`UITextChecker`, `UILexicon`), GCD 직렬 큐, Swift Testing(`@Suite`, `@Test`, `#expect`), OSSignposter

**Spec:** `docs/superpowers/specs/2026-09-02-autocomplete-performance-improvements-design.md`

## Global Constraints

- iOS 16+ / Swift 5 / Xcode 26. deprecated API 신규 사용 금지.
- 작업 브랜치 `chore/#123-autocomplete-perf-signposts`. 계측 커밋과 spec 커밋 뒤에 이어서 커밋한다.
- 커밋 메시지는 `type: #123 - subject` 형식, 한국어, 마침표 없음. Task 1~4는 `refactor`, Task 5는 `feat`.
- 한 커밋에는 한 Task의 코드와 테스트만 담는다. 재포맷·주석 정리 같은 부수 변경을 섞지 않는다.
- `Modules/`에 새 파일을 추가하지 않는다(pbxproj 예외 목록 수정을 피한다). 테스트 파일은 `SYKeyboardTests/`가 동기화 폴더라 자동 등록된다.
- production 타입에 `ForTesting` 메서드를 추가하지 않는다. 테스트 seam은 기존 `loadApplyDelay`처럼 init 파라미터(기본값 있음)로만 둔다.
- 기준 시뮬레이터: iPhone 13 mini / iOS 16.0.
- 빌드·테스트 후 `git status --short`에서 `.xcscheme`의 `RemotePath` 변경과 `SYKeyboard/Resources/Info.plist` 변경을 확인한다. 사용자 변경이 아니면 `git checkout -- <파일>`로 복원한다. 이 브랜치의 계측 작업 중 빌드 스크립트가 `Info.plist`의 `NSUserTrackingUsageDescription`을 제거한 사례가 있다.
- `UITextChecker`·`UILexicon`은 시스템 데이터에 의존하고 테스트 호스트에서 App Group `UserDefaults`를 만들 수 없으므로, `TextCheckerPredictiveTextEngine`과 `LexiconPredictiveTextEngine`의 실제 인스턴스를 단위 테스트에서 만들지 않는다. 컨트롤러 경로는 `SuggestionControllerEngineFactory`로 stub을 주입해 검증한다.

관련 테스트 실행 명령(각 Task의 "Run"은 이 명령에 `-only-testing`을 바꿔 쓴다):

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/<SuiteTypeName> 2>&1 | grep -E "Test Suite|✔|✘|error:|TEST (SUCCEEDED|FAILED)"
```

---

## File Structure

| 파일 | 책임 | Task |
| --- | --- | --- |
| `Modules/SYKeyboardCore/Domain/PredictiveText/LexiconPredictiveTextEngine.swift` | `UILexicon` 엔트리를 소문자 `userInput` 키 인덱스로 보관·조회 | 1 |
| `Modules/SYKeyboardCore/Domain/SuggestionController.swift` | 엔진 조합. `textReplacementMatch`(Task 1), `mergeSuggestions`(Task 4), 비동기 TextChecker 경로(Task 5) | 1, 4, 5 |
| `SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift` | 텍스트 대치 컨트롤러 검증. stub 갱신 + 보존 계약 테스트 2개 추가 | 1 |
| `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` | unigram 순위 캐시·부분 선택·prune(Task 2), 저장 dirty flag(Task 3) | 2, 3 |
| `SYKeyboardTests/Domain/NGramPredictiveTextEngineRankingTests.swift` (신규) | unigram 후보 순위·캐시 무효화·prune 검증 | 2 |
| `SYKeyboardTests/Domain/NGramPredictiveTextEnginePersistenceTests.swift` (신규) | 저장 건너뜀/수행 조건 검증 | 3 |
| `Modules/SYKeyboardCore/Domain/PredictiveText/Protocols/PredictiveTextProvider.swift` | `suggestions(for:limit:)` 요구사항 + 기본 구현 | 4 |
| `Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift` | `limit` 도달 시 `guesses` 생략(Task 4), 큐 한정 접근 주석(Task 5) | 4, 5 |
| `SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift` (신규) | `limit` 전달과 lexicon 충족 시 TextChecker 미호출 검증 | 4, 5(갱신) |
| `SYKeyboardTests/Domain/SuggestionControllerAsyncTextCheckerTests.swift` (신규) | 비동기 경로의 즉시 갱신, 낡은 결과 폐기, 중단 시 무효화 검증 | 5 |

---

### Task 1: lexicon 인덱스 (항목 2)

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/LexiconPredictiveTextEngine.swift`
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift` (`textReplacementMatch`, 663~692행 부근)
- Test: `SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces: `LexiconSuggestionProviding.textReplacementEntries(matching lowercasedWord: String) -> [TextReplacementEntry]` (기존 `var textReplacementEntries: [TextReplacementEntry]` 제거). Task 4·5의 테스트 stub도 이 시그니처를 구현한다.

- [x] **Step 1: 보존 계약 테스트 2개를 기존 suite에 추가**

`SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift`의 `makeController` 위(마지막 `@Test` 뒤)에 추가한다. 이 두 테스트는 변경 전에도 통과해야 한다. 변경 전 통과를 먼저 확인해 "현재 동작"을 고정하는 용도다.

```swift
    @Test("같은 단축어가 대소문자만 다르게 여러 개면 첫 엔트리를 대치")
    func test같은단축어가_대소문자만다르게여러개면_첫엔트리를대치() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "Id", documentText: "first"),
                TextReplacementEntry(userInput: "id", documentText: "second")
            ]
        )
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        let replacement = controller.attemptTextReplacement(baseText: "id")
        #expect(replacement?.deleteCount == 2)
        #expect(replacement?.insertText == "first")
    }

    @Test("m을 M으로 바꾸는 시스템 기본 대치는 제외")
    func testM대문자대치는_제외() {
        let controller = makeController(
            entries: [
                TextReplacementEntry(userInput: "m", documentText: "M")
            ]
        )
        controller.isTextReplacementEnabled = true
        controller.prepareLexiconEngineIfNeeded()

        #expect(controller.attemptTextReplacement(baseText: "m") == nil)
    }
```

- [x] **Step 2: 변경 전 테스트 실행으로 현재 동작 확인**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests`
Expected: 기존 10개 + 신규 2개 모두 PASS. (첫 테스트는 `max(by:)`가 동률에서 첫 요소를 유지하는 현재 동작을 고정한다.)

- [x] **Step 3: `LexiconPredictiveTextEngine`을 인덱스 기반으로 변경**

`LexiconPredictiveTextEngine.swift`의 프로토콜과 클래스를 아래로 교체한다. `TextReplacementEntry` 구조체와 `LexiconLoadableSuggestionProviding`, 파일 하단 `private extension`의 `currentWord(from:)`은 그대로 둔다.

```swift
protocol LexiconSuggestionProviding: PredictiveTextProvider {
    var hasLoadedLexicon: Bool { get }
    /// 소문자로 정규화한 단어와 `userInput`이 정확히 일치하는 엔트리를 lexicon의 원래 순서대로 반환합니다.
    func textReplacementEntries(matching lowercasedWord: String) -> [TextReplacementEntry]
}

protocol LexiconLoadableSuggestionProviding: LexiconSuggestionProviding {
    func setLexicon(_ lexicon: UILexicon)
}

final class LexiconPredictiveTextEngine: LexiconLoadableSuggestionProviding {
    
    // MARK: - Properties
    
    private(set) var lexicon: UILexicon?
    /// `userInput.lowercased()` → 엔트리(원래 순서). 키 입력마다 전체를 순회하지 않도록 로드 시 한 번 만든다
    private var entriesByLowercasedInput: [String: [TextReplacementEntry]] = [:]

    var hasLoadedLexicon: Bool {
        lexicon != nil
    }
    
    // MARK: - Internal Methods
    
    /// `UILexicon`을 설정하고 조회 인덱스를 만듭니다.
    ///
    /// `UIInputViewController.requestSupplementaryLexicon`의 결과를 전달받아 저장합니다.
    ///
    /// - Parameter lexicon: 로드된 `UILexicon` 객체
    func setLexicon(_ lexicon: UILexicon) {
        self.lexicon = lexicon
        var index: [String: [TextReplacementEntry]] = [:]
        for entry in lexicon.entries {
            index[entry.userInput.lowercased(), default: []].append(
                TextReplacementEntry(userInput: entry.userInput, documentText: entry.documentText)
            )
        }
        entriesByLowercasedInput = index
    }

    func textReplacementEntries(matching lowercasedWord: String) -> [TextReplacementEntry] {
        entriesByLowercasedInput[lowercasedWord] ?? []
    }
    
    // MARK: - PredictiveTextService Methods
    
    /// 현재 입력된 단어와 정확히 일치하는 텍스트 대치 후보만 반환합니다.
    ///
    /// - Parameter baseText: 자동완성을 제공할 텍스트
    /// - Returns: 정확히 매칭된 대치 결과 배열
    func suggestions(for baseText: String) -> [String] {
        guard hasLoadedLexicon else { return [] }
        
        let lastWord = currentWord(from: baseText)
        guard !lastWord.isEmpty else { return [] }
        
        let lowered = lastWord.lowercased()
        
        // 이 필터는 검색어에 의존하므로 인덱스에 미리 넣지 않는다
        return textReplacementEntries(matching: lowered).compactMap { entry in
            entry.documentText.lowercased() != lowered ? entry.documentText : nil
        }
    }
    
    // UILexicon은 시스템이 관리하므로 학습 불필요
    func learn(word: String) {}
}
```

- [x] **Step 4: `SuggestionController.textReplacementMatch`를 인덱스 조회로 변경**

`SuggestionController.swift`에서 아래 블록을

```swift
        let matchingEntries = lexiconEngine.textReplacementEntries.filter { entry in
            let isMatch = currentWord.lowercased() == entry.userInput.lowercased()

            if entry.userInput.lowercased() == "m" && entry.documentText == "M" {
                return false
            }

            return isMatch
        }
```

다음으로 교체한다. `signposter` 구간, `max(by:)` 선택, 반환문은 그대로 둔다.

```swift
        // 인덱스가 소문자 일치를 보장하므로 여기서는 시스템 기본 대치 제외만 적용한다
        let matchingEntries = lexiconEngine
            .textReplacementEntries(matching: currentWord.lowercased())
            .filter { entry in
                !(entry.userInput.lowercased() == "m" && entry.documentText == "M")
            }
```

- [x] **Step 5: 테스트 stub을 새 프로토콜에 맞게 갱신**

`SuggestionControllerTextReplacementTests.swift`의 `StubLexiconSuggestionProvider`를 교체한다.

```swift
private final class StubLexiconSuggestionProvider: LexiconSuggestionProviding {

    // MARK: - Properties

    private let entries: [TextReplacementEntry]
    var hasLoadedLexicon: Bool { true }

    // MARK: - Initializer

    init(entries: [TextReplacementEntry]) {
        self.entries = entries
    }

    // MARK: - Internal Methods

    func textReplacementEntries(matching lowercasedWord: String) -> [TextReplacementEntry] {
        entries.filter { $0.userInput.lowercased() == lowercasedWord }
    }

    func suggestions(for baseText: String) -> [String] {
        let currentWord = baseText.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? ""
        return textReplacementEntries(matching: currentWord.lowercased())
            .map(\.documentText)
    }

    func learn(word: String) {}
}
```

- [x] **Step 6: 테스트 실행**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests`
Expected: 12개 모두 PASS.

- [x] **Step 7: `HangeulKeyboard` scheme 빌드로 production 컴파일 확인**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`. 이어서 `git status --short`를 확인하고 `.xcscheme`·`Info.plist` 부수 변경이 있으면 복원한다.

- [x] **Step 8: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/LexiconPredictiveTextEngine.swift \
        Modules/SYKeyboardCore/Domain/SuggestionController.swift \
        SYKeyboardTests/Domain/SuggestionControllerTextReplacementTests.swift
git commit -m "refactor: #123 - lexicon 텍스트 대치 조회를 인덱스 기반으로 변경"
```

---

### Task 2: unigram 부분 선택·캐시·prune (항목 3)

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` (프로퍼티 84~103행, init 183~194행, `rankedUnigramCandidates` 557~586행, `pruneUnigram` 593~600행 부근)
- Create: `SYKeyboardTests/Domain/NGramPredictiveTextEngineRankingTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces: `NGramPredictiveTextEngine.init(language:fileURL:legacyStorage:loadApplyDelay:maxKeys:)` — `maxKeys: Int = 5000` 파라미터 추가. Task 3이 같은 init에 `saveQueue`를 추가한다.

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Domain/NGramPredictiveTextEngineRankingTests.swift`를 새로 만든다.

```swift
//
//  NGramPredictiveTextEngineRankingTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram unigram 후보 순위 검증")
struct NGramPredictiveTextEngineRankingTests {

    @Test("문맥이 없으면 빈도 상위 3개를 빈도순으로 반환")
    func test문맥이없으면_빈도상위3개를_빈도순으로반환() async {
        let engine = await makeLoadedEngine(name: "ranking-top3")
        record(engine, word: "alpha", times: 5)
        record(engine, word: "bravo", times: 4)
        record(engine, word: "charlie", times: 3)
        record(engine, word: "delta", times: 2)
        record(engine, word: "echo", times: 1)

        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie"])
    }

    @Test("학습으로 순위가 바뀌면 후보가 갱신")
    func test학습으로순위가바뀌면_후보가갱신() async {
        let engine = await makeLoadedEngine(name: "ranking-invalidate")
        record(engine, word: "alpha", times: 3)
        record(engine, word: "bravo", times: 2)
        record(engine, word: "charlie", times: 1)
        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie"])

        record(engine, word: "delta", times: 4)

        #expect(engine.suggestions(for: "") == ["delta", "alpha", "bravo"])
    }

    @Test("초기화 후에는 후보가 없음")
    func test초기화후에는_후보가없음() async {
        let engine = await makeLoadedEngine(name: "ranking-reset")
        record(engine, word: "alpha", times: 2)
        #expect(engine.suggestions(for: "") == ["alpha"])

        engine.resetAllData()

        #expect(engine.suggestions(for: "") == [])
    }

    @Test("unigram 상한을 넘으면 최소 빈도 단어가 제거")
    func testUnigram상한을넘으면_최소빈도단어가제거() async {
        let engine = await makeLoadedEngine(name: "ranking-prune", maxKeys: 3)
        record(engine, word: "alpha", times: 4)
        record(engine, word: "bravo", times: 3)
        record(engine, word: "charlie", times: 2)
        record(engine, word: "delta", times: 1)

        #expect(engine.suggestions(for: "") == ["alpha", "bravo", "charlie"])
    }
}

private func makeLoadedEngine(name: String, maxKeys: Int = 5000) async -> NGramPredictiveTextEngine {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name).plist")
    let engine = NGramPredictiveTextEngine(
        language: "test-\(name)",
        fileURL: url,
        legacyStorage: .standard,
        loadApplyDelay: .milliseconds(50),
        maxKeys: maxKeys
    )
    await withCheckedContinuation { continuation in
        engine.onLoadCompleted = {
            continuation.resume()
        }
    }
    return engine
}

private func record(_ engine: NGramPredictiveTextEngine, word: String, times: Int) {
    for _ in 0..<times {
        engine.addWord(word)
    }
}
```

빈도를 모두 다르게 둔 이유: 동률 순서는 spec대로 정의하지 않으므로 테스트가 동률에 의존하면 안 된다. prune 테스트에서 `delta`(1)는 기록 직후 유일한 최소 빈도라 제거가 결정적이다.

- [x] **Step 2: 컴파일 실패 확인**

Run: `-only-testing:SYKeyboardTests/NGramPredictiveTextEngineRankingTests`
Expected: 컴파일 에러 `extra argument 'maxKeys' in call` (아직 init에 파라미터가 없다).

- [x] **Step 3: `maxKeys` init 파라미터와 캐시 프로퍼티 추가**

`NGramPredictiveTextEngine.swift` 프로퍼티 영역에서

```swift
    /// unigram 저장소: "단어" → 빈도수
    private var unigramStore: [String: Int] = [:]
```

를 다음으로 교체한다.

```swift
    /// unigram 저장소: "단어" → 빈도수
    ///
    /// 변이 경로(디스크 로드 반영, reset, 기록, prune)가 모두 이 프로퍼티를 거치므로
    /// `didSet` 한 곳에서 순위 캐시를 무효화한다
    private var unigramStore: [String: Int] = [:] {
        didSet { rankedUnigramCache = nil }
    }
    /// `rankedUnigramCandidates()` 결과 캐시. unigram이 바뀌지 않은 연속 스페이스 입력에서 계산을 건너뛴다
    private var rankedUnigramCache: [String]?
```

`private let maxKeys = 5000`을 `private let maxKeys: Int`로 바꾸고, 지정 init을 다음으로 교체한다.

```swift
    init(
        language: String,
        fileURL: URL,
        legacyStorage: UserDefaults,
        loadApplyDelay: Duration? = nil,
        maxKeys: Int = 5000
    ) {
        self.language = language
        self.fileURL = fileURL
        self.legacyStorage = legacyStorage
        self.loadApplyDelay = loadApplyDelay
        self.maxKeys = maxKeys
        startBackgroundLoad()
    }
```

`convenience init(language:)`의 `self.init(...)` 호출은 `maxKeys`를 넘기지 않아 기본값 5000을 쓴다.

- [x] **Step 4: `rankedUnigramCandidates()`를 부분 선택 + 캐시로 교체**

```swift
    func rankedUnigramCandidates() -> [String] {
        if let rankedUnigramCache { return rankedUnigramCache }

        let state = Self.signposter.beginInterval("RankedUnigramCandidates")
        defer { Self.signposter.endInterval("RankedUnigramCandidates", state) }

        // 전체 정렬 대신 상위 maxPredictions개만 유지한다. 동률 순서는 정렬 시절과 마찬가지로 정의하지 않는다
        var top: [(key: String, value: Int)] = []
        for entry in unigramStore {
            guard top.count < maxPredictions || entry.value > top[top.count - 1].value else { continue }
            let insertIndex = top.firstIndex { entry.value > $0.value } ?? top.count
            top.insert(entry, at: insertIndex)
            if top.count > maxPredictions {
                top.removeLast()
            }
        }

        let ranked = top.map(\.key)
        rankedUnigramCache = ranked
        return ranked
    }
```

- [x] **Step 5: `pruneUnigram()`을 초과 1개 경로에서 O(n)으로 교체**

```swift
    func pruneUnigram() {
        let removeCount = unigramStore.count - maxKeys
        guard removeCount > 0 else { return }

        // 정상 경로는 기록마다 최대 1개 초과라 최소 빈도 1개만 찾는다. 2개 이상 초과(상한을 넘긴
        // 마이그레이션 데이터 등)는 드물어 기존 정렬 방식을 유지한다
        if removeCount == 1 {
            if let lowest = unigramStore.min(by: { $0.value < $1.value }) {
                unigramStore.removeValue(forKey: lowest.key)
            }
            return
        }

        let sorted = unigramStore.sorted { $0.value < $1.value }
        for i in 0..<removeCount {
            unigramStore.removeValue(forKey: sorted[i].key)
        }
    }
```

- [x] **Step 6: 테스트 실행**

Run: `-only-testing:SYKeyboardTests/NGramPredictiveTextEngineRankingTests -only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests`
Expected: 신규 4개 + 기존 2개 모두 PASS.

- [x] **Step 7: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift \
        SYKeyboardTests/Domain/NGramPredictiveTextEngineRankingTests.swift
git commit -m "refactor: #123 - unigram 후보 선택과 prune을 부분 선택·캐시로 변경"
```

---

### Task 3: 저장 dirty flag (항목 4)

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift` (프로퍼티, init, 로드 반영 216~232행, `saveToDisk` 377~418행, `resetAllData` 421~440행, `recordNGrams` 527~557행 부근)
- Create: `SYKeyboardTests/Domain/NGramPredictiveTextEnginePersistenceTests.swift`

**Interfaces:**
- Consumes: Task 2의 init 시그니처
- Produces: `NGramPredictiveTextEngine.init(language:fileURL:legacyStorage:loadApplyDelay:maxKeys:saveQueue:)` — `saveQueue: DispatchQueue` 파라미터 추가(기본값: 기존 전용 직렬 큐)

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Domain/NGramPredictiveTextEnginePersistenceTests.swift`를 새로 만든다.

```swift
//
//  NGramPredictiveTextEnginePersistenceTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 저장 조건 검증")
struct NGramPredictiveTextEnginePersistenceTests {

    @Test("변경이 없으면 저장을 건너뜀")
    func test변경이없으면_저장을건너뜀() async {
        let fixture = await makeLoadedFixture(name: "persistence-skip")

        fixture.engine.saveToDisk()
        fixture.saveQueue.sync {}

        #expect(FileManager.default.fileExists(atPath: fixture.url.path) == false)
    }

    @Test("학습 후 문장을 끝내면 파일을 저장")
    func test학습후문장을끝내면_파일을저장() async {
        let fixture = await makeLoadedFixture(name: "persistence-save")

        fixture.engine.addWord("hello")
        fixture.engine.endSentence()
        fixture.saveQueue.sync {}

        #expect(FileManager.default.fileExists(atPath: fixture.url.path))
    }

    @Test("초기화 후에는 저장해도 파일을 만들지 않음")
    func test초기화후에는_저장해도_파일을만들지않음() async {
        let fixture = await makeLoadedFixture(name: "persistence-reset")
        fixture.engine.addWord("hello")

        fixture.engine.resetAllData()
        fixture.engine.saveToDisk()
        fixture.saveQueue.sync {}

        #expect(FileManager.default.fileExists(atPath: fixture.url.path) == false)
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

`saveQueue.sync {}`는 직렬 큐에 먼저 들어간 쓰기 블록이 끝난 뒤 반환되므로, 파일 부재 단언이 "아직 안 썼을 뿐"으로 거짓 통과하지 않는다.

- [x] **Step 2: 컴파일 실패 확인**

Run: `-only-testing:SYKeyboardTests/NGramPredictiveTextEnginePersistenceTests`
Expected: 컴파일 에러 `extra argument 'saveQueue' in call`.

- [x] **Step 3: `saveQueue` 주입과 `hasUnsavedChanges` 프로퍼티 추가**

프로퍼티 영역에서

```swift
    /// 백그라운드 저장용 직렬 큐
    private let saveQueue = DispatchQueue(label: "com.snmac.sykeyboard.ngram.save", qos: .utility)
```

를 다음으로 교체한다.

```swift
    /// 백그라운드 저장용 직렬 큐
    private let saveQueue: DispatchQueue
    /// 마지막 저장 스냅샷 이후 학습으로 저장소가 바뀌었는지 여부. 변경이 없으면 저장을 건너뛴다
    private var hasUnsavedChanges = false
```

지정 init을 다음으로 교체한다.

```swift
    init(
        language: String,
        fileURL: URL,
        legacyStorage: UserDefaults,
        loadApplyDelay: Duration? = nil,
        maxKeys: Int = 5000,
        saveQueue: DispatchQueue = DispatchQueue(label: "com.snmac.sykeyboard.ngram.save", qos: .utility)
    ) {
        self.language = language
        self.fileURL = fileURL
        self.legacyStorage = legacyStorage
        self.loadApplyDelay = loadApplyDelay
        self.maxKeys = maxKeys
        self.saveQueue = saveQueue
        startBackgroundLoad()
    }
```

- [x] **Step 4: 변이·초기화 경로에서 플래그 갱신**

로드 반영 클로저(`applyLoadedData`)에서 `self.needsLegacyCleanup = needsCleanup` 다음 줄, `self.isLoaded = true` 앞에 추가한다. `flushPendingEvents()`보다 앞이어야 보류 이벤트 재생이 다시 `true`로 만들 수 있다.

```swift
                    self.needsLegacyCleanup = needsCleanup
                    // 메모리와 파일이 일치하는 시점. 이후 flushPendingEvents가 기록하면 다시 true가 된다
                    self.hasUnsavedChanges = false
                    self.isLoaded = true
```

`recordNGrams()` 끝의 `pruneKeys(in: &trigramStore)` 다음 줄에 추가한다.

```swift
        pruneKeys(in: &trigramStore)
        hasUnsavedChanges = true
```

`resetAllData()`에서 `writeCounter = 0` 다음 줄에 추가한다.

```swift
        writeCounter = 0
        // 파일을 지우고 저장소도 비우므로 메모리와 디스크가 일치한다
        hasUnsavedChanges = false
```

- [x] **Step 5: `saveToDisk()`에 가드·플래그 해제·실패 복구 추가**

`saveToDisk()`를 다음으로 교체한다. 계측 구간은 그대로 유지한다.

```swift
    func saveToDisk() {
        // 보류된 레거시 정리는 이 경로에서만 수행되므로 dirty가 아니어도 통과시킨다
        guard isLoaded, hasUnsavedChanges || needsLegacyCleanup else { return }
        
        let generation = currentStorageGeneration()
        let snapshotState = Self.signposter.beginInterval("NGramSaveSnapshot")
        let snapshot = NGramData(
            unigram: unigramStore,
            bigram: bigramStore,
            trigram: trigramStore
        )
        Self.signposter.endInterval("NGramSaveSnapshot", snapshotState)
        hasUnsavedChanges = false
        let url = fileURL
        let shouldCleanupLegacy = needsLegacyCleanup

        saveQueue.async { [weak self] in
            guard let self else { return }
            guard self.currentStorageGeneration() == generation else { return }

            // 실패로 빠져나가도 defer가 interval을 닫는다
            let encodeState = Self.signposter.beginInterval("NGramSaveEncode")
            defer { Self.signposter.endInterval("NGramSaveEncode", encodeState) }

            do {
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .binary
                let data = try encoder.encode(snapshot)
                try data.write(to: url, options: .atomic)
                
                if shouldCleanupLegacy {
                    self.legacyStorage.removeObject(forKey: self.legacyUnigramKey)
                    self.legacyStorage.removeObject(forKey: self.legacyBigramKey)
                    self.legacyStorage.removeObject(forKey: self.legacyTrigramKey)
                    DispatchQueue.main.async {
                        self.needsLegacyCleanup = false
                    }
                    self.logger.debug("[NGram/\(self.language)] 보류된 레거시 데이터 정리 완료")
                }
            } catch {
                self.logger.error("[NGram] 디스크 저장 실패: \(error.localizedDescription)")
                // 다음 저장 기회에 재시도할 수 있도록 되돌린다. reset 이후라면 버려진 데이터이므로 되돌리지 않는다
                DispatchQueue.main.async {
                    guard self.currentStorageGeneration() == generation else { return }
                    self.hasUnsavedChanges = true
                }
            }
        }
    }
```

- [x] **Step 6: 테스트 실행**

Run: `-only-testing:SYKeyboardTests/NGramPredictiveTextEnginePersistenceTests -only-testing:SYKeyboardTests/NGramPredictiveTextEngineRankingTests -only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests`
Expected: 3 + 4 + 2 모두 PASS. 특히 "변경이 없으면 저장을 건너뜀"과 "초기화 후에는 …"은 변경 전에는 빈 plist가 써져 FAIL하던 테스트다.

- [x] **Step 7: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift \
        SYKeyboardTests/Domain/NGramPredictiveTextEnginePersistenceTests.swift
git commit -m "refactor: #123 - NGram 저장을 변경이 있을 때만 수행하도록 변경"
```

---

### Task 4: `guesses` 조건부 생략 (항목 1-a)

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/Protocols/PredictiveTextProvider.swift`
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift` (`suggestions(for:)` 72~115행 부근)
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift` (`mergeSuggestions` 871~903행 부근)
- Create: `SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift`

**Interfaces:**
- Consumes: Task 1의 `LexiconSuggestionProviding.textReplacementEntries(matching:)` (테스트 stub)
- Produces: `PredictiveTextProvider.suggestions(for baseText: String, limit: Int) -> [String]` (protocol extension 기본 구현 있음). Task 5가 이를 큐에서 호출한다.

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift`를 새로 만든다.

```swift
//
//  SuggestionControllerTextCheckerLimitTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("TextChecker 조회 limit 검증")
struct SuggestionControllerTextCheckerLimitTests {

    @Test("입력 중 TextChecker는 후보 슬롯 수를 limit으로 받음")
    func test입력중TextChecker는_후보슬롯수를limit으로받음() {
        let checker = RecordingPredictiveTextProvider(results: ["hello", "help", "helmet"])
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeController(checker: checker, lexiconEntries: [])
        controller.delegate = delegate

        controller.updateSuggestions(for: "hel")

        #expect(checker.receivedLimits == [2])
        #expect(delegate.updates.last?.currentWord == "hel")
        #expect(delegate.updates.last?.suggestions == ["hello", "help"])
    }

    @Test("lexicon이 슬롯을 다 채우면 TextChecker를 조회하지 않음")
    func testLexicon이슬롯을다채우면_TextChecker를조회하지않음() {
        let checker = RecordingPredictiveTextProvider(results: ["hello"])
        let delegate = RecordingSuggestionControllerDelegate()
        let controller = makeController(
            checker: checker,
            lexiconEntries: [
                TextReplacementEntry(userInput: "hel", documentText: "first"),
                TextReplacementEntry(userInput: "hel", documentText: "second")
            ]
        )
        controller.delegate = delegate

        controller.updateSuggestions(for: "hel")

        #expect(checker.callCount == 0)
        #expect(delegate.updates.last?.suggestions == ["first", "second"])
    }

    private func makeController(
        checker: RecordingPredictiveTextProvider,
        lexiconEntries: [TextReplacementEntry]
    ) -> SuggestionController {
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in StubNGramPredictiveTextProvider() }
        )
        let controller = SuggestionController(language: "en-US", engineFactory: factory)
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        return controller
    }
}

private final class RecordingPredictiveTextProvider: PredictiveTextProvider {
    private let results: [String]
    private(set) var callCount = 0
    private(set) var receivedLimits: [Int] = []

    init(results: [String]) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] {
        callCount += 1
        return results
    }

    func suggestions(for baseText: String, limit: Int) -> [String] {
        callCount += 1
        receivedLimits.append(limit)
        return Array(results.prefix(limit))
    }

    func learn(word: String) {}
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

private final class StubNGramPredictiveTextProvider: NGramPredictiveTextProviding {
    var onLoadCompleted: (() -> Void)?
    var currentSentenceWordsCount: Int { 0 }

    func suggestions(for baseText: String) -> [String] { [] }
    func learn(word: String) {}
    func addWord(_ word: String) {}
    func endSentence() {}
    func removeLastWord() {}
    func resetSentenceBuffer() {}
    func saveToDisk() {}
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
```

- [x] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerTextCheckerLimitTests`
Expected: `RecordingPredictiveTextProvider`의 `suggestions(for:limit:)`가 프로토콜 요구사항이 아니라 컴파일은 되지만, 첫 테스트는 `receivedLimits == []`로 FAIL, 둘째 테스트는 `callCount == 1`로 FAIL (현재는 lexicon 결과와 무관하게 TextChecker를 먼저 호출한다).

- [x] **Step 3: 프로토콜에 `limit` 조회 추가**

`PredictiveTextProvider.swift`를 다음으로 교체한다.

```swift
//
//  PredictiveTextProvider.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

/// 자동완성 후보 단어를 제공하는 서비스 프로토콜
///
/// 입력 컨텍스트를 기반으로 예측 후보를 반환하고,
/// 사용자가 선택한 단어를 학습하는 기능을 정의합니다.
protocol PredictiveTextProvider: AnyObject {
    /// 현재 입력 컨텍스트를 기반으로 자동완성 후보를 반환합니다.
    ///
    /// - Parameter baseText: 자동완성을 제공할 텍스트
    /// - Returns: 자동완성 후보 단어 배열
    func suggestions(for baseText: String) -> [String]
    /// 앞에서부터 최대 `limit`개만 필요한 호출자를 위한 조회입니다.
    ///
    /// 기본 구현은 `suggestions(for:)`를 그대로 반환합니다. 후보 생성 비용이 큰 엔진은
    /// `limit`을 채운 뒤의 작업을 생략하도록 재정의합니다.
    ///
    /// - Parameters:
    ///   - baseText: 자동완성을 제공할 텍스트
    ///   - limit: 호출자가 실제로 읽는 최대 개수
    /// - Returns: 자동완성 후보 단어 배열 (앞 `limit`개는 `suggestions(for:)`와 동일)
    func suggestions(for baseText: String, limit: Int) -> [String]
    /// 사용자가 선택한 단어를 학습하여 이후 추천에 반영합니다.
    ///
    /// - Parameter word: 학습할 단어
    func learn(word: String)
}

extension PredictiveTextProvider {
    func suggestions(for baseText: String, limit: Int) -> [String] {
        suggestions(for: baseText)
    }
}
```

- [x] **Step 4: `TextCheckerPredictiveTextEngine`에서 `limit` 도달 시 `guesses` 생략**

`suggestions(for:)` 메서드 전체를 다음 두 메서드로 교체한다. 계측 구간은 그대로다.

```swift
    func suggestions(for baseText: String) -> [String] {
        suggestions(for: baseText, limit: .max)
    }

    func suggestions(for baseText: String, limit: Int) -> [String] {
        let lastWord = currentWord(from: baseText)
        guard !lastWord.isEmpty, limit > 0 else { return [] }
        
        let range = NSRange(location: 0, length: lastWord.utf16.count)
        let loweredLastWord = lastWord.lowercased()
        var seen = Set<String>()
        var merged: [String] = []

        func append(_ words: [String]) {
            for word in words {
                let lowered = word.lowercased()
                guard lowered != loweredLastWord,
                      !seen.contains(lowered) else { continue }
                seen.insert(lowered)
                merged.append(word)
                if merged.count >= limit { return }
            }
        }
        
        // 1순위: completions (접두어 자동완성)
        let completionsState = Self.signposter.beginInterval("TextCheckerCompletions")
        let completions = checker.completions(
            forPartialWordRange: range,
            in: lastWord,
            language: language
        ) ?? []
        Self.signposter.endInterval("TextCheckerCompletions", completionsState)
        append(completions)

        // completions만으로 limit이 차면 guesses는 결과에 기여할 수 없으므로 호출하지 않는다
        guard merged.count < limit else { return merged }
        
        // 2순위: guesses (오타 교정, 중복 제거하여 보충)
        let guessesState = Self.signposter.beginInterval("TextCheckerGuesses")
        let guesses = checker.guesses(
            forWordRange: range,
            in: lastWord,
            language: language
        ) ?? []
        Self.signposter.endInterval("TextCheckerGuesses", guessesState)
        append(guesses)
        
        return merged
    }
```

- [x] **Step 5: `mergeSuggestions`에서 TextChecker를 필요할 때만 `limit`으로 조회**

`SuggestionController.mergeSuggestions(for:currentWord:)`를 다음으로 교체한다.

```swift
    func mergeSuggestions(for text: String, currentWord: String) -> [SuggestionItem] {
        let lexiconState = signposter.beginInterval("LexiconSuggestions")
        let lexiconResults = lexiconEngine?.suggestions(for: text) ?? []
        signposter.endInterval("LexiconSuggestions", lexiconState)

        var seen = Set<String>()
        seen.insert(currentWord.lowercased())
        var merged: [SuggestionItem] = []

        let maxSuggestionSlots = maxSuggestions - 1

        for suggestion in lexiconResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .lexicon))
            if merged.count >= maxSuggestionSlots { return merged }
        }

        // 아래 루프는 각 항목을 슬롯에 넣거나 lexicon 중복으로 건너뛰므로 목록의 앞
        // maxSuggestionSlots개만 읽는다. 따라서 limit이 그 값이어도 결과가 같다
        let checkerState = signposter.beginInterval("TextCheckerSuggestions")
        let checkerResults = textCheckerEngine?.suggestions(for: text, limit: maxSuggestionSlots) ?? []
        signposter.endInterval("TextCheckerSuggestions", checkerState)

        for suggestion in checkerResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .textChecker))
            if merged.count >= maxSuggestionSlots { return merged }
        }

        return merged
    }
```

- [x] **Step 6: 테스트 실행**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerTextCheckerLimitTests -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests`
Expected: 모두 PASS.

- [x] **Step 7: `HangeulKeyboard` scheme 빌드**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`. `git status --short`로 부수 변경 확인.

- [x] **Step 8: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/Protocols/PredictiveTextProvider.swift \
        Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift \
        Modules/SYKeyboardCore/Domain/SuggestionController.swift \
        SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift
git commit -m "refactor: #123 - completions로 슬롯이 차면 guesses 호출 생략"
```

---

### Task 5: TextChecker 비동기화 실험 커밋 (항목 1-b)

이 Task의 커밋은 `git revert` 한 번으로 빠져야 한다. Task 1~4가 만든 인터페이스는 수정하지 않고, 아래에 적힌 파일·범위 밖은 건드리지 않는다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift` (프로퍼티, init, `clearSuggestions`, `performUpdateSuggestions`의 `.typing` 분기, `mergeSuggestions`)
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift` (`checker` 프로퍼티 주석만)
- Modify: `SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift` (비동기 경로에 맞게 큐 드레인 추가)
- Create: `SYKeyboardTests/Domain/SuggestionControllerAsyncTextCheckerTests.swift`

**Interfaces:**
- Consumes: Task 4의 `PredictiveTextProvider.suggestions(for:limit:)`, Task 1의 `LexiconSuggestionProviding`
- Produces: `SuggestionController.init(language:engineFactory:textCheckerQueue:)` — `textCheckerQueue: DispatchQueue` 파라미터(기본값: 전용 직렬 큐)

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Domain/SuggestionControllerAsyncTextCheckerTests.swift`를 새로 만든다.

```swift
//
//  SuggestionControllerAsyncTextCheckerTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("TextChecker 비동기 조회 검증")
struct SuggestionControllerAsyncTextCheckerTests {

    @Test("입력 중에는 lexicon 결과를 즉시 전달하고 TextChecker 결과를 뒤이어 전달")
    func test입력중에는_lexicon결과를즉시전달하고_TextChecker결과를뒤이어전달() async {
        let checker = GatedPredictiveTextProvider(results: ["hel": ["hello", "help"]])
        let harness = makeHarness(checker: checker, lexiconEntries: [
            TextReplacementEntry(userInput: "hel", documentText: "Helsinki")
        ])

        harness.controller.updateSuggestions(for: "hel")
        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: ["Helsinki"]))

        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: ["Helsinki", "hello"]))
    }

    @Test("새 입력이 들어오면 이전 입력의 TextChecker 결과는 버림")
    func test새입력이들어오면_이전입력의TextChecker결과는버림() async {
        let checker = GatedPredictiveTextProvider(results: [
            "he": ["hey"],
            "hel": ["hello", "help"]
        ])
        let harness = makeHarness(checker: checker, lexiconEntries: [])

        harness.controller.updateSuggestions(for: "he")
        harness.controller.updateSuggestions(for: "hel")

        checker.gate.signal()
        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last == .init(currentWord: "hel", suggestions: ["hello", "help"]))
        #expect(harness.delegate.updates.contains { $0.suggestions == ["hey"] } == false)
    }

    @Test("일시 중단되면 진행 중이던 TextChecker 결과는 반영하지 않음")
    func test일시중단되면_진행중이던TextChecker결과는_반영하지않음() async {
        let checker = GatedPredictiveTextProvider(results: ["hel": ["hello", "help"]])
        let harness = makeHarness(checker: checker, lexiconEntries: [])

        harness.controller.updateSuggestions(for: "hel")
        harness.controller.isSuspended = true

        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updates.last == .init(currentWord: nil, suggestions: []))
    }

    @Test("TextChecker 결과 전달은 main 스레드에서 수행")
    func testTextChecker결과전달은_main스레드에서수행() async {
        let checker = GatedPredictiveTextProvider(results: ["hel": ["hello"]])
        let harness = makeHarness(checker: checker, lexiconEntries: [])

        harness.controller.updateSuggestions(for: "hel")
        checker.gate.signal()
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(harness.delegate.updateIsMainThread.last == true)
    }

    private struct Harness {
        let controller: SuggestionController
        let delegate: RecordingSuggestionControllerDelegate
        let queue: DispatchQueue
    }

    private func makeHarness(
        checker: GatedPredictiveTextProvider,
        lexiconEntries: [TextReplacementEntry]
    ) -> Harness {
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in StubNGramPredictiveTextProvider() }
        )
        let queue = DispatchQueue(label: "SYKeyboardTests.suggestion.textchecker")
        let controller = SuggestionController(
            language: "en-US",
            engineFactory: factory,
            textCheckerQueue: queue
        )
        let delegate = RecordingSuggestionControllerDelegate()
        controller.delegate = delegate
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        return Harness(controller: controller, delegate: delegate, queue: queue)
    }
}

/// `gate.signal()`이 올 때까지 조회를 막아 결과 도착 순서를 테스트가 제어한다
private final class GatedPredictiveTextProvider: PredictiveTextProvider, @unchecked Sendable {
    let gate = DispatchSemaphore(value: 0)
    private let results: [String: [String]]

    init(results: [String: [String]]) {
        self.results = results
    }

    func suggestions(for baseText: String) -> [String] {
        suggestions(for: baseText, limit: .max)
    }

    func suggestions(for baseText: String, limit: Int) -> [String] {
        gate.wait()
        return Array((results[baseText] ?? []).prefix(limit))
    }

    func learn(word: String) {}
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

private final class StubNGramPredictiveTextProvider: NGramPredictiveTextProviding {
    var onLoadCompleted: (() -> Void)?
    var currentSentenceWordsCount: Int { 0 }

    func suggestions(for baseText: String) -> [String] { [] }
    func learn(word: String) {}
    func addWord(_ word: String) {}
    func endSentence() {}
    func removeLastWord() {}
    func resetSentenceBuffer() {}
    func saveToDisk() {}
}

private final class RecordingSuggestionControllerDelegate: SuggestionControllerDelegate {
    struct Update: Equatable {
        let currentWord: String?
        let suggestions: [String]
    }

    private(set) var updates: [Update] = []
    private(set) var updateIsMainThread: [Bool] = []

    func suggestionController(
        _ controller: SuggestionController,
        didUpdateCurrentWord currentWord: String?,
        suggestions: [String]
    ) {
        updates.append(Update(currentWord: currentWord, suggestions: suggestions))
        updateIsMainThread.append(Thread.isMainThread)
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

첫 테스트에서 최종 후보가 `["Helsinki", "hello"]`인 이유: lexicon 1개가 슬롯 하나를 채우고 TextChecker는 `limit: 2`로 `["hello", "help"]`를 돌려주지만 남은 슬롯이 1개라 `hello`만 들어간다.

- [x] **Step 2: 실패 확인**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerAsyncTextCheckerTests`
Expected: 컴파일 에러 `extra argument 'textCheckerQueue' in call`.

- [x] **Step 3: `SuggestionController`에 큐·세대 프로퍼티와 init 파라미터 추가**

프로퍼티 영역의 `private let signposter = OSSignposter(...)` 선언 뒤에 추가한다.

```swift
    /// TextChecker 조회 전용 직렬 큐. `UITextChecker` 인스턴스는 이 큐에서만 접근한다
    private let textCheckerQueue: DispatchQueue
    /// 비동기 TextChecker 조회 결과가 낡았는지 판별하는 요청 세대
    private var textCheckerRequestGeneration = 0
```

init을 다음으로 교체한다.

```swift
    init(
        language: String = "ko-KR",
        engineFactory: SuggestionControllerEngineFactory = .live,
        textCheckerQueue: DispatchQueue = DispatchQueue(
            label: "com.snmac.sykeyboard.suggestion.textchecker",
            qos: .userInteractive
        )
    ) {
        self.language = language
        self.engineFactory = engineFactory
        self.textCheckerQueue = textCheckerQueue
    }
```

- [x] **Step 4: `clearSuggestions()`에서 진행 중 요청 무효화**

`clearSuggestions()` 첫 줄에 추가한다.

```swift
    func clearSuggestions() {
        // 진행 중인 TextChecker 조회 결과가 뒤늦게 반영되지 않도록 세대를 올린다
        textCheckerRequestGeneration += 1
        lastSuggestionBaseText = nil
```

- [x] **Step 5: `mergeSuggestions`를 조회 없는 순수 병합으로 바꾸고 `.typing` 분기를 비동기화**

`mergeSuggestions(for:currentWord:)`를 다음으로 교체한다(조회는 호출자가 한다).

```swift
    /// lexicon 결과와 TextChecker 결과를 병합합니다.
    ///
    /// 현재 입력 중인 단어와 동일한 후보는 제외하고,
    /// lexicon 결과를 먼저 배치하여 사용자 개인화 데이터를 우선시합니다.
    ///
    /// - Parameters:
    ///   - lexiconResults: `UILexicon` 후보
    ///   - checkerResults: `UITextChecker` 후보 (아직 도착하지 않았으면 빈 배열)
    ///   - currentWord: 현재 입력 중인 단어
    /// - Returns: 중복 제거된 후보 배열 (최대 2개)
    func mergeSuggestions(
        lexiconResults: [String],
        checkerResults: [String],
        currentWord: String
    ) -> [SuggestionItem] {
        var seen = Set<String>()
        seen.insert(currentWord.lowercased())
        var merged: [SuggestionItem] = []

        let maxSuggestionSlots = maxSuggestions - 1

        for suggestion in lexiconResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .lexicon))
            if merged.count >= maxSuggestionSlots { return merged }
        }

        for suggestion in checkerResults {
            let lowered = suggestion.lowercased()
            guard !seen.contains(lowered) else { continue }
            seen.insert(lowered)
            merged.append(SuggestionItem(text: suggestion, source: .textChecker))
            if merged.count >= maxSuggestionSlots { return merged }
        }

        return merged
    }
```

`performUpdateSuggestions`의 마지막 블록

```swift
        currentMode = .typing
        let currentWord = extractLastWord(from: baseText)
        currentSuggestions = mergeSuggestions(for: baseText, currentWord: currentWord)
        delegate?.suggestionController(
            self,
            didUpdateCurrentWord: currentWord.isEmpty ? nil : currentWord,
            suggestions: currentSuggestions.map { $0.text }
        )
```

을 다음으로 교체한다.

```swift
        currentMode = .typing
        let currentWord = extractLastWord(from: baseText)
        textCheckerRequestGeneration += 1
        let generation = textCheckerRequestGeneration
        let maxSuggestionSlots = maxSuggestions - 1

        let lexiconState = signposter.beginInterval("LexiconSuggestions")
        let lexiconResults = lexiconEngine?.suggestions(for: baseText) ?? []
        signposter.endInterval("LexiconSuggestions", lexiconState)

        // lexicon 결과로 먼저 갱신하고 TextChecker 결과는 도착하면 다시 병합한다.
        // 이전 후보를 유지하지 않는 이유: 직전 모드가 n-gram이면 이전 후보는 다음 단어 예측이라
        // 입력 중 모드에서 탭되면 현재 단어를 잘못 교체한다
        currentSuggestions = mergeSuggestions(
            lexiconResults: lexiconResults,
            checkerResults: [],
            currentWord: currentWord
        )
        delegate?.suggestionController(
            self,
            didUpdateCurrentWord: currentWord.isEmpty ? nil : currentWord,
            suggestions: currentSuggestions.map { $0.text }
        )

        // lexicon이 슬롯을 다 채웠으면 TextChecker 조회가 결과에 기여할 수 없다
        guard currentSuggestions.count < maxSuggestionSlots,
              let textCheckerEngine else { return }

        let signposter = signposter
        textCheckerQueue.async { [weak self] in
            let checkerState = signposter.beginInterval("TextCheckerSuggestions")
            let checkerResults = textCheckerEngine.suggestions(for: baseText, limit: maxSuggestionSlots)
            signposter.endInterval("TextCheckerSuggestions", checkerState)

            DispatchQueue.main.async {
                // 세대 검사는 delegate 호출 전에 있어야 낡은 후보가 표시되지 않는다
                guard let self,
                      self.textCheckerRequestGeneration == generation,
                      self.currentMode == .typing else { return }
                self.currentSuggestions = self.mergeSuggestions(
                    lexiconResults: lexiconResults,
                    checkerResults: checkerResults,
                    currentWord: currentWord
                )
                self.delegate?.suggestionController(
                    self,
                    didUpdateCurrentWord: currentWord.isEmpty ? nil : currentWord,
                    suggestions: self.currentSuggestions.map { $0.text }
                )
            }
        }
```

- [x] **Step 6: `TextCheckerPredictiveTextEngine`의 `checker` 프로퍼티에 큐 한정 주석 추가**

```swift
    /// `SuggestionController`의 TextChecker 큐에서만 접근한다.
    /// `UITextChecker`는 스레드 안전성이 문서화되지 않았으므로 다른 스레드에서 사용하지 않는다.
    /// `learn(word:)`가 쓰는 `UITextChecker.learnWord` 같은 클래스 메서드는 인스턴스와 무관하게 main에서 호출한다
    private let checker = UITextChecker()
```

- [x] **Step 7: Task 4 테스트를 비동기 경로에 맞게 갱신**

`SuggestionControllerTextCheckerLimitTests.swift`에서:

첫 테스트의 본문을 다음으로 교체한다(`async` 추가, 큐 드레인).

```swift
    @Test("입력 중 TextChecker는 후보 슬롯 수를 limit으로 받음")
    func test입력중TextChecker는_후보슬롯수를limit으로받음() async {
        let checker = RecordingPredictiveTextProvider(results: ["hello", "help", "helmet"])
        let delegate = RecordingSuggestionControllerDelegate()
        let harness = makeController(checker: checker, lexiconEntries: [])
        harness.controller.delegate = delegate

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(checker.receivedLimits == [2])
        #expect(delegate.updates.last?.currentWord == "hel")
        #expect(delegate.updates.last?.suggestions == ["hello", "help"])
    }
```

둘째 테스트도 `harness.controller`를 쓰도록 바꾸고 `harness.queue.sync {}`를 `updateSuggestions` 뒤에 넣는다(TextChecker가 호출되지 않았음을 큐를 비운 뒤 단언한다).

```swift
    @Test("lexicon이 슬롯을 다 채우면 TextChecker를 조회하지 않음")
    func testLexicon이슬롯을다채우면_TextChecker를조회하지않음() async {
        let checker = RecordingPredictiveTextProvider(results: ["hello"])
        let delegate = RecordingSuggestionControllerDelegate()
        let harness = makeController(
            checker: checker,
            lexiconEntries: [
                TextReplacementEntry(userInput: "hel", documentText: "first"),
                TextReplacementEntry(userInput: "hel", documentText: "second")
            ]
        )
        harness.controller.delegate = delegate

        harness.controller.updateSuggestions(for: "hel")
        harness.queue.sync {}
        await waitForMainQueue()

        #expect(checker.callCount == 0)
        #expect(delegate.updates.last?.suggestions == ["first", "second"])
    }
```

`makeController`를 큐를 함께 돌려주도록 교체한다.

```swift
    private struct Harness {
        let controller: SuggestionController
        let queue: DispatchQueue
    }

    private func makeController(
        checker: RecordingPredictiveTextProvider,
        lexiconEntries: [TextReplacementEntry]
    ) -> Harness {
        let lexicon = StubLexiconSuggestionProvider(entries: lexiconEntries)
        let factory = SuggestionControllerEngineFactory(
            makeLexiconEngine: { lexicon },
            makeTextCheckerEngine: { _ in checker },
            makeNGramEngine: { _ in StubNGramPredictiveTextProvider() }
        )
        let queue = DispatchQueue(label: "SYKeyboardTests.suggestion.textchecker.limit")
        let controller = SuggestionController(
            language: "en-US",
            engineFactory: factory,
            textCheckerQueue: queue
        )
        controller.isPredictiveTextEnabled = true
        controller.isTextReplacementEnabled = true
        return Harness(controller: controller, queue: queue)
    }
```

`RecordingPredictiveTextProvider`에 `@unchecked Sendable`을 붙이고(큐에서 호출됨), 파일 끝에 `waitForMainQueue()`를 추가한다.

```swift
private final class RecordingPredictiveTextProvider: PredictiveTextProvider, @unchecked Sendable {
```

```swift
private func waitForMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            continuation.resume()
        }
    }
}
```

- [x] **Step 8: 테스트 실행**

Run: `-only-testing:SYKeyboardTests/SuggestionControllerAsyncTextCheckerTests -only-testing:SYKeyboardTests/SuggestionControllerTextCheckerLimitTests -only-testing:SYKeyboardTests/SuggestionControllerTextReplacementTests -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests -only-testing:SYKeyboardTests/SuggestionControllerMathResultsTests`
Expected: 모두 PASS. `SuggestionControllerTextReplacementTests`의 "텍스트 대치 preview 인덱스는 …" 테스트는 lexicon 결과가 즉시 반영되므로 동기 단언이 그대로 통과해야 한다.

- [x] **Step 9: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/SuggestionController.swift \
        Modules/SYKeyboardCore/Domain/PredictiveText/TextCheckerPredictiveTextEngine.swift \
        SYKeyboardTests/Domain/SuggestionControllerTextCheckerLimitTests.swift \
        SYKeyboardTests/Domain/SuggestionControllerAsyncTextCheckerTests.swift
git commit -m "feat: #123 - TextChecker 조회를 백그라운드 큐로 분리 (실험)"
```

---

### Task 6: 전체 검증과 실기기 측정 준비

**Files:** 코드 변경 없음. 검증 결과는 이 계획 문서의 아래 체크박스에 기록한다.

- [x] **Step 1: 전체 테스트 실행**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' 2>&1 | grep -E "✘|error:|TEST (SUCCEEDED|FAILED)"
```
Expected: `** TEST SUCCEEDED **`, `✘` 없음.

- [x] **Step 2: 3개 extension scheme 빌드 (`-only-testing` 옵션 없이)**

```sh
for scheme in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' 2>&1 | tail -1
done
```
Expected: 세 번 모두 `** BUILD SUCCEEDED **`.

- [x] **Step 3: 빌드 부수 효과 확인**

```sh
git status --short
```
Expected: 출력 없음. `.xcscheme`가 보이면 `RemotePath`만 바뀐 경우 `git checkout -- <파일>`, `SYKeyboard/Resources/Info.plist`가 보이면 `git diff`로 `NSUserTrackingUsageDescription` 삭제 여부를 확인하고 사용자 변경이 아니면 복원한다.

- [ ] **Step 4: 실기기 측정 안내를 이슈 #123에 남김 (사용자 수행 항목)**

자동 테스트가 대체하지 못하는 항목이다. 아래 내용을 정리해 사용자에게 보여주고, 확인을 받은 뒤에만 이슈 #123 코멘트로 남긴다(외부 서비스 기록이므로 자동으로 올리지 않는다).

- 실기기(가능하면 iPhone SE 2세대급 / iOS 16)에 Debug 빌드를 설치하고 Instruments의 **os_signpost** 계측기로 키보드 확장 프로세스를 붙인다.
- 영문 단어 입력 중 `TextCheckerSuggestions`, `TextCheckerGuesses`, `TextCheckerCompletions`의 count / avg / max를 기록한다. `TextCheckerGuesses` count가 `TextCheckerCompletions` count보다 작으면 Task 4의 생략이 동작하는 것이다.
- 스페이스 입력 시 `RankedUnigramCandidates`가 연속 스페이스에서 발생하지 않으면 Task 2 캐시가 동작하는 것이다.
- 후보 바 깜빡임, 키 하이라이트 애니메이션 끊김, 빠른 연속 입력 시 후보 갱신 여부를 관찰한다.
- 후보 탭 직후 이전 단어의 후보가 잠깐 표시되지 않는지 관찰한다.
- 키 입력마다 후보 바가 lexicon 결과 → TextChecker 결과로 두 번 갱신되므로 reflow가 눈에 띄는지 관찰한다.
- 판단: Task 5 revert 전 상태(`git stash` 없이 `git checkout <Task 4 커밋>`으로 빌드)에서 `TextCheckerSuggestions` p95 ≥ 8 ms(또는 p50 ≥ 3 ms)이면 Task 5 유지, 한 자릿수 ms이면 `git revert <Task 5 커밋>`. 측정값을 이슈에 남긴다.

**Step 4 진행 상태**: 코멘트 초안을 `.superpowers/sdd/2026-09-02-autocomplete-performance-improvements/issue-123-measurement-comment.md`에 작성했다. 사용자 확인 후에만 이슈 #123에 게시하므로, 실기기 측정과 게시가 끝나기 전까지 이 Step은 미완료로 남긴다.

---

## 실행 기록 (2026-09-02)

- Task 1 `af477efa` refactor: lexicon 텍스트 대치 조회를 인덱스 기반으로 변경 — `SuggestionControllerTextReplacementTests` 12/12 통과.
- Task 2 `0bf2fd1b` refactor: unigram 후보 선택과 prune을 부분 선택·캐시로 변경 — `NGramPredictiveTextEngineRankingTests` 4 + `NGramPredictiveTextEngineLoadingTests` 2 = 6/6 통과. RED 단계에서 `extra argument 'maxKeys'` 컴파일 실패로 실패 확인.
- Task 3 `4ae0f4c1` refactor: NGram 저장을 변경이 있을 때만 수행하도록 변경 — `NGramPredictiveTextEnginePersistenceTests` 3 + Ranking 4 + Loading 2 = 9/9 통과. RED 단계에서 `extra argument 'saveQueue'` 컴파일 실패로 실패 확인.
- Task 4 `f2af8890` refactor: completions로 슬롯이 차면 guesses 호출 생략 — 관련 4개 suite 통과, `HangeulKeyboard` scheme 빌드 성공. RED 단계에서 `receivedLimits == []`, `callCount == 1` 단언 실패로 실패 확인.
- Task 5 `6029d998` feat: TextChecker 조회를 백그라운드 큐로 분리(실험) + `0664c8e5` test: 두 번째 delegate 호출 고정 — 관련 5개 suite 110/110 통과. RED 단계에서 `extra argument 'textCheckerQueue'` 컴파일 실패로 실패 확인. 테스트 단언이 약하다는 리뷰 지적을 받아 `0664c8e5`로 보강 후 재리뷰 통과.
- Task 1~5는 각각 spec 리뷰와 quality 리뷰를 통과했고, Task 5만 위 테스트 단언 보강 1회의 수정 라운드를 거쳤다.

Task 6 결과:

- Step 1 전체 테스트: `xcodebuild test -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'` → `** TEST SUCCEEDED **`. 로그에서 `passed on` 572건, `✘` 0건, `error:` 0건, 실패(`failed on`) 0건 확인(xcresult: `Test-SYKeyboard-2026.09.02_23-52-43-+0900.xcresult`). 병렬 클론 두 개가 stdout에 동시에 써서 5364번째 줄 경계에서 문자 단위로 섞이는 표시 문제가 있었으나 xcresult 요약(`** TEST SUCCEEDED **`)과 개별 테스트 케이스 라인은 모두 온전했다.
- Step 2 extension 빌드: `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` 순서로(-only-testing 없이) 하나씩 실행, 세 번 모두 `** BUILD SUCCEEDED **`.
- Step 3 `git status --short` 출력 없음. 되돌릴 부수 효과 없음.
- Step 4는 실기기 측정과 이슈 게시가 남아 있어 미완료 상태로 둔다(코멘트 초안만 작성).

브랜치 전체 최종 리뷰(2026-09-03) 결과와 수정:

- Task 1~4는 지적 없이 merge 가능 판정. Task 5에 Important 2건: (1) 기준선에서 TextChecker가 12~22 ms라 lexicon 결과만 즉시 표시하면 매 키 입력마다 빈 중간 상태가 한 프레임 이상 렌더링됨, (2) 빠른 연타 시 큐에 쌓인 낡은 조회를 건너뛰지 않아 중복 조회 발생.
- `af112d9d` feat: TextChecker 비동기 경로에 이전 후보 유지와 낡은 요청 건너뛰기 추가 — 직전 `.typing` 모드의 `.textChecker` 후보만 즉시 갱신에 이어 붙이고(lexicon·n-gram·수식 후보는 제외), 요청 세대를 `OSAllocatedUnfairLock<Int>`로 바꿔 큐 블록 진입 시 낡은 요청을 건너뛰며, 조회 생략 가드는 `.lexicon` 출처 개수만 세도록 수정(유지된 후보가 슬롯을 채워 새 조회가 영구 억제되는 결함 방지), 큐 QoS `.userInitiated`. 관련 5개 suite 116/116 통과, `HangeulKeyboard` 빌드 성공.
- `13483413` docs: 설계 문서를 위 구현과 일치시킴(계측 커밋 해시, 1-b 유지 규칙·세대 위치·QoS, 중간 상태 렌더링 사실).
- 범위 한정 재리뷰 통과. 보류한 Minor: backlog 테스트가 production 가드 제거 시 실패 대신 hang함(`gate.wait(timeout:)`로 전환 가능), `.lexicon` 개수 가드에 대한 회귀 테스트 없음(유지 후보 2개로 슬롯이 찬 뒤 다음 키에서 재조회를 단언하면 고정 가능). 실기기 관찰 추가 항목: `learnWord`(main)와 `completions`(큐)의 동시 호출은 문서화되지 않은 영역.

## 기준선 측정 (2026-09-02)

- 기기: iPhone 15 Pro Max, iOS 27.0 (24A5430a), 실기기. 커밋 `b60a275b`(계측만 포함). 프로세스 `HangeulEnglishKeyboard`.
- 입력 스크립트: 애국가 1절(개행 섞음) → 알파벳 a~z 3~4회 반복(스페이스 섞음, z 뒤 개행) → 개행 10회 → 스페이스 10회 → 스페이스 길게 누르기 10초. 총 68.5초.
- trace: `~/Documents/baseline-iPhone15ProMax-iOS27.trace`. 추출 명령:

```sh
xcrun xctrace export --input baseline-iPhone15ProMax-iOS27.trace \
  --xpath '/trace-toc/run[@number="1"]/data/table[@schema="OSSignpostIntervals"]' \
  --output baseline-intervals.xml
```

`subsystem`에 `SYKeyboard`가 포함된 행의 `duration`을 구간 이름별로 모아 count / p50 / p95 / max를 계산했다(xctrace XML은 반복 값을 `ref="id"`로 가리키므로 파서가 id를 해석해야 한다).

| 구간 | count | p50 ms | p95 ms | max ms | 스레드 |
| --- | --- | --- | --- | --- | --- |
| `TextCheckerSuggestions` | 69 | 11.93 | 17.37 | 21.92 | 메인 |
| `TextCheckerCompletions` | 69 | 6.43 | 10.97 | 12.64 | 메인 |
| `TextCheckerGuesses` | 69 | 5.98 | 11.16 | 12.35 | 메인 |
| `NGramSaveEncode` | 24 | 9.90 | 11.97 | 12.03 | 백그라운드 |
| `LexiconSuggestions` | 69 | 0.08 | 0.11 | 0.21 | 메인 |
| `TextReplacementMatch` | 82 | 0.04 | 0.08 | 0.19 | 메인 |
| `RankedUnigramCandidates` | 57 | 0.04 | 0.06 | 0.08 | 메인 |
| `NGramRecord` | 16 | 0.01 | 0.02 | 0.02 | 메인 |
| `NGramSaveSnapshot` | 24 | 0.00 | 0.01 | 0.01 | 메인 |

판단:

- 지원 기기 중 최상위급에서도 키 입력당 TextChecker가 메인 스레드를 12~22 ms 점유한다. spec의 1-b 적용 기준(p95 ≥ 8 ms)을 두 배 이상 넘으므로 Task 5는 실험이 아니라 핵심 개선으로 진행한다. 커밋 격리는 그대로 유지한다.
- `completions`와 `guesses` 비용이 거의 같아 Task 4(1-a)의 절감은 최대 절반이다. 적용 후 `TextCheckerGuesses` count가 `TextCheckerCompletions` count보다 얼마나 줄었는지로 효과를 확인한다.
- Task 1~3은 이 사용자의 lexicon·unigram이 작아 기준선에서는 비용이 미미하다. 비용 상한을 없애는 목적이며, Task 3은 리턴 연타 10회의 중복 `NGramSaveEncode`(각 ~10 ms, 백그라운드)를 없애는 효과가 실측으로 확인된다.
- Task 6 Step 4의 "Task 4 상태에서 재측정 후 1-b 판단"은 기준선이 이미 기준을 넘었으므로 생략 가능하다. Task 5 적용 후 같은 스크립트로 재측정해 전후 비교만 남긴다.

## Self-Review 기록

- Spec 커버리지: 항목 2 → Task 1, 항목 3(`pruneUnigram` 포함, `maxKeys` 주입) → Task 2, 항목 4(`saveQueue` 주입, 실패 재시도, 레거시 정리 통과) → Task 3, 항목 1-a(프로토콜 기본 구현, lexicon 충족 시 미호출) → Task 4, 항목 1-b(격리, 세대 검사, `clearSuggestions` 무효화, 큐 주입, 큐 한정 주석) → Task 5, 검증·실기기 측정·Info.plist 확인 → Task 6.
- 미검증으로 남는 항목: `LexiconPredictiveTextEngine.suggestions(for:)`와 `TextCheckerPredictiveTextEngine.suggestions(for:limit:)`의 실제 인스턴스 동작(시스템 데이터 의존, 테스트 호스트에서 생성 불가). 실기기에서 텍스트 대치 후보와 오타 교정 후보가 뜨는지 Task 6 Step 4에서 함께 관찰한다. NGram 쓰기 실패 재시도는 spec대로 자동 테스트 제외.
- 타입 일관성: `textReplacementEntries(matching:)`(Task 1 → 4, 5 stub), `suggestions(for:limit:)`(Task 4 → 5), `init(... maxKeys:saveQueue:)`(Task 2 → 3), `init(... textCheckerQueue:)`(Task 5), `mergeSuggestions(lexiconResults:checkerResults:currentWord:)`(Task 5에서 Task 4의 `mergeSuggestions(for:currentWord:)`를 대체).

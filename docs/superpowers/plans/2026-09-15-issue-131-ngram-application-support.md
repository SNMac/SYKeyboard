# NGram 학습 파일 Application Support 이동 + caps lock·클립보드 행 버그 수정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `ngram_<lang>.plist`를 App Group 컨테이너 루트에서 `Library/Application Support/`로 옮기고, 이미 배포된 루트 파일은 엔진 생성 시 한 번 옮긴다. 같은 이슈에 포함한 버그 2건을 함께 고친다: (a) Shift를 두 번 눌러 caps lock을 켠 채 누르고 입력한 뒤 떼도 caps lock 유지, 한 번 누른 채 입력하고 떼면 대문자 해제는 그대로 (b) 클립보드 기록 패널 행을 끌다 놓았을 때 눌림 배경이 남는 현상 제거.

**Architecture:** `NGramPredictiveTextEngine`이 새 위치 `fileURL`과 옛 위치 `legacyFileURL`을 함께 들고 있다. designated init에서 백그라운드 로딩을 시작하기 전에 `FileManager.moveItem`으로 동기 이동한다. 같은 볼륨 안의 rename이라 비용이 작고, 설정 화면의 `resetNGramData()`처럼 생성 직후 `resetAllData()`를 부르는 경로와 경쟁하지 않는다. 로딩은 새 위치 → 옛 위치 순으로 읽고, 저장은 항상 새 위치로 하며 쓰기 전에 디렉터리를 만든다.

**Tech Stack:** Swift 5, Foundation `FileManager`/`PropertyListEncoder`, Swift Testing

**Spec:** GitHub Issue #131 (https://github.com/SNMac/SYKeyboard/issues/131). 버그 2건은 2026-09-15 사용자 요청으로 이슈 본문에 추가했다. Task 3은 superpowers:systematic-debugging의 Phase 1 증거 수집을 먼저 끝낸 뒤에만 수정한다.

## 원인·현재 코드 조사 결과

- `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift:178`이 `containerURL.appendingPathComponent("ngram_\(language).plist")`로 컨테이너 루트를 쓴다.
- 쓰기 경로 두 곳(`saveToDisk()` 420행, `migrateFromUserDefaults()` 518행)은 부모 디렉터리를 만들지 않는다. App Group 컨테이너에는 `Library/Application Support`가 기본으로 없으므로(`ClipboardHistoryStore.swift:134` 주석과 같은 상황) 경로만 바꾸면 저장이 실패한다.
- `resetAllData()`는 `fileURL`만 지운다. 옮기지 못한 옛 파일을 지우지 않으면 초기화 뒤 다음 실행에서 옛 파일을 다시 읽어 학습 데이터가 되살아난다.
- 호출 측: `SuggestionController.swift:42`, `PredictiveTextSettingsView.swift:116`. 둘 다 `init(language:)`만 쓰므로 호출 측 수정은 없다.

## 여러 프로세스 안전성

앱과 extension 3개가 같은 파일을 쓴다. 어느 프로세스가 먼저 실행돼도 아래 순서로 수렴한다.

| 상황 | 동작 |
|---|---|
| 새 파일 있음 | 이동하지 않고 새 파일을 읽는다 |
| 새 파일 없음, 옛 파일 있음 | 디렉터리 생성 → `moveItem`. 성공하면 새 파일을 읽는다 |
| 다른 프로세스가 먼저 옮겨 `moveItem` 실패 | 로딩이 새 위치를 먼저 읽으므로 옮겨진 파일을 읽는다 |
| 권한 등으로 이동 실패 | 새 위치에 파일이 없어 옛 위치를 읽는다. 다음 저장은 새 위치로 간다 |
| 둘 다 없음 | 기존대로 UserDefaults 마이그레이션 → 빈 데이터 |

## Global Constraints

- iOS 16+ / Swift 5 / Xcode 26 이상. deprecated API 신규 사용 금지.
- 작업 브랜치 `refactor/#131-ngram-application-support`(develop `ba93ae17` 기준).
- 커밋 메시지 `type: #131 - subject`, 한국어, 마침표 없음. Task 1은 `refactor`, Task 2·3은 `fix`, Task 4는 `docs`. 본문 끝에 세션 attribution을 붙인다.
- 각 Task는 코드·테스트·이 문서의 체크박스 갱신을 하나의 커밋으로 남긴다. 실행하지 않았거나 실패한 step은 체크하지 않는다.
- 새 production 파일은 만들지 않는다(`project.pbxproj` 수정 없음). `SYKeyboardTests/`는 동기화 폴더라 테스트 파일 등록이 필요 없다.
- production 타입에 `ForTesting` 메서드를 추가하지 않는다. 테스트 seam은 기존 designated init 파라미터에 `legacyFileURL: URL? = nil`만 더한다.
- Shift 버튼의 나머지 이벤트 타이밍(`touchDown`, `touchDownRepeat`), 한 번 탭·두 번 탭·caps lock 해제 동작, 자동 대문자 정책은 바꾸지 않는다.
- 클립보드 패널의 행 탭·스와이프 삭제/고정·길게 누르기·편집 모드 다중 선택 동작은 바꾸지 않는다. 진단 로그는 커밋하지 않는다.
- 정확한 색, SF Symbol 이름, private subview 구조는 테스트로 고정하지 않는다.
- 파일명 `ngram_<lang>.plist`, 데이터 형식(`NGramData` 바이너리 plist), 로딩·저장 타이밍, UserDefaults 마이그레이션 동작은 바꾸지 않는다.
- Firebase/AdMob, entitlements, `Info.plist`, `Secrets.xcconfig`, `.xcscheme`은 건드리지 않는다. 빌드 뒤 `.xcscheme`의 `RemotePath`만 바뀌었으면 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`로 되돌린다.
- 기준 시뮬레이터: iPhone 13 mini / iOS 18.6. 테스트 러너가 붙여넣기 권한 알림으로 멈추면 코드 실패로 기록하지 않는다(CLAUDE.md 해당 절).

테스트 실행 명령(`-only-testing`만 바꿔 쓴다):

```sh
xcodebuild test \
  -project SYKeyboard.xcodeproj \
  -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/<SuiteTypeName> 2>&1 | grep -E "passed on|failed on|error:|TEST (SUCCEEDED|FAILED)"
```

---

### Task 1: 파일 위치 변경과 옛 파일 이동

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift`
- Create: `SYKeyboardTests/Domain/NGramPredictiveTextEngineFileMigrationTests.swift`

**Interfaces:**
- Produces: `init(language:fileURL:legacyFileURL:legacyStorage:loadApplyDelay:maxKeys:saveQueue:)`. `legacyFileURL: URL? = nil`이라 기존 테스트의 호출은 그대로 컴파일된다.

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Domain/NGramPredictiveTextEngineFileMigrationTests.swift`:

```swift
//
//  NGramPredictiveTextEngineFileMigrationTests.swift
//  SYKeyboardTests
//

import Foundation
import Testing

@testable import SYKeyboardCore

@Suite("n-gram 파일 위치 이동 검증")
struct NGramPredictiveTextEngineFileMigrationTests {

    @Test("옛 위치 파일만 있으면 새 위치로 옮기고 학습 데이터를 유지")
    func test옛파일만있으면_새위치로옮기고_데이터유지() async throws {
        let paths = try makeContainer(name: "legacy-only")
        try writeNGramData(unigram: ["legacy": 3], to: paths.legacyURL)

        let engine = makeEngine(paths: paths, name: "legacy-only")
        await waitForLoadCompletion(of: engine)

        #expect(FileManager.default.fileExists(atPath: paths.fileURL.path))
        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path) == false)
        #expect(engine.suggestions(for: "") == ["legacy"])
    }

    @Test("새 위치 파일이 이미 있으면 옛 파일을 옮기지 않고 새 파일을 읽음")
    func test새파일이있으면_옛파일을옮기지않음() async throws {
        let paths = try makeContainer(name: "both")
        try writeNGramData(unigram: ["legacy": 3], to: paths.legacyURL)
        try writeNGramData(unigram: ["new": 3], to: paths.fileURL)

        let engine = makeEngine(paths: paths, name: "both")
        await waitForLoadCompletion(of: engine)

        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path))
        #expect(engine.suggestions(for: "") == ["new"])
    }

    @Test("두 위치 모두 파일이 없으면 저장할 때 새 위치에 디렉터리를 만들어 저장")
    func test파일이없으면_새위치에저장() async throws {
        let paths = try makeContainer(name: "none")
        let saveQueue = DispatchQueue(label: "SYKeyboardTests.ngram.migration.none")

        let engine = makeEngine(paths: paths, name: "none", saveQueue: saveQueue)
        await waitForLoadCompletion(of: engine)
        engine.addWord("hello")
        engine.endSentence()
        saveQueue.sync {}

        #expect(FileManager.default.fileExists(atPath: paths.fileURL.path))
        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path) == false)
    }

    @Test("옮기기에 실패하면 옛 위치 파일을 계속 읽음")
    func test옮기기실패하면_옛파일을읽음() async throws {
        let paths = try makeContainer(name: "move-failed")
        try writeNGramData(unigram: ["legacy": 3], to: paths.legacyURL)
        try blockApplicationSupportDirectory(in: paths)

        let engine = makeEngine(paths: paths, name: "move-failed")
        await waitForLoadCompletion(of: engine)

        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path))
        #expect(engine.suggestions(for: "") == ["legacy"])
    }

    @Test("초기화하면 옮기지 못한 옛 위치 파일도 삭제")
    func test초기화는_옛파일도삭제() throws {
        let paths = try makeContainer(name: "reset")
        try writeNGramData(unigram: ["legacy": 3], to: paths.legacyURL)
        try blockApplicationSupportDirectory(in: paths)

        let engine = makeEngine(paths: paths, name: "reset")
        engine.resetAllData()

        #expect(FileManager.default.fileExists(atPath: paths.legacyURL.path) == false)
    }
}

private struct ContainerPaths {
    let containerURL: URL
    /// 새 위치: `Library/Application Support/ngram_test.plist`
    let fileURL: URL
    /// 옛 위치: 컨테이너 루트의 `ngram_test.plist`
    let legacyURL: URL
}

private struct TestNGramData: Codable {
    var unigram: [String: Int]
    var bigram: [String: [String: Int]]
    var trigram: [String: [String: Int]]
}

private func makeContainer(name: String) throws -> ContainerPaths {
    let containerURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name)", isDirectory: true)
    try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
    return ContainerPaths(
        containerURL: containerURL,
        fileURL: containerURL.appendingPathComponent("Library/Application Support/ngram_test.plist"),
        legacyURL: containerURL.appendingPathComponent("ngram_test.plist")
    )
}

/// `Library` 자리에 일반 파일을 둬서 `Application Support` 디렉터리 생성과 이동이 실패하게 만든다
private func blockApplicationSupportDirectory(in paths: ContainerPaths) throws {
    try Data().write(to: paths.containerURL.appendingPathComponent("Library"))
}

private func makeEngine(
    paths: ContainerPaths,
    name: String,
    saveQueue: DispatchQueue = DispatchQueue(label: "SYKeyboardTests.ngram.migration")
) -> NGramPredictiveTextEngine {
    NGramPredictiveTextEngine(
        language: "test-migration-\(name)",
        fileURL: paths.fileURL,
        legacyFileURL: paths.legacyURL,
        legacyStorage: .standard,
        loadApplyDelay: .milliseconds(50),
        saveQueue: saveQueue
    )
}

private func writeNGramData(unigram: [String: Int], to url: URL) throws {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let data = try encoder.encode(TestNGramData(unigram: unigram, bigram: [:], trigram: [:]))
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
}

private func waitForLoadCompletion(of engine: NGramPredictiveTextEngine) async {
    await withCheckedContinuation { continuation in
        engine.onLoadCompleted = {
            continuation.resume()
        }
    }
}
```

- [x] **Step 2: 테스트가 실패하는지 확인**

Run: 위 명령에 `-only-testing:SYKeyboardTests/NGramPredictiveTextEngineFileMigrationTests`
Expected: 컴파일 실패 `extra argument 'legacyFileURL' in call`

실제 결과: 예상대로 컴파일 실패.
`NGramPredictiveTextEngineFileMigrationTests.swift:119:30: error: extra argument 'legacyFileURL' in call` → `** TEST FAILED **`

- [x] **Step 3: 엔진 구현**

`NGramPredictiveTextEngine.swift`에서 아래를 바꾼다.

(a) 문서 주석 `## 저장 구조`(33–36행)를 교체:

```swift
/// ## 저장 구조
/// - App Group 컨테이너의 `Library/Application Support/`에 언어별 바이너리 plist 파일로 영구 저장
/// - 파일명: `ngram_{language}.plist` (예: `ngram_ko.plist`)
/// - 항목 수 제한으로 메모리 과다 사용 방지
```

`## 마이그레이션`(47–49행)을 교체:

```swift
/// ## 마이그레이션
/// - 컨테이너 루트에 있던 옛 파일은 생성 시 새 위치로 한 번 옮깁니다. 옮기지 못하면 옛 파일을 계속 읽고 저장은 새 위치로 합니다.
/// - 기존 `UserDefaults`에 저장된 n-gram 데이터가 있는 경우,
///   초기 로딩 시 자동으로 파일로 마이그레이션한 뒤 UserDefaults에서 제거합니다.
```

(b) `fileURL` 프로퍼티(112–113행) 아래에 추가:

```swift
    /// 컨테이너 루트에 있던 옛 파일 경로. 옮기지 못했을 때 읽기와 초기화에만 쓴다
    private let legacyFileURL: URL?
```

(c) convenience init의 178행을 교체하고 `self.init` 호출에 인자를 더한다:

```swift
        let fileURL = containerURL.appendingPathComponent("Library/Application Support/ngram_\(language).plist")
        let legacyFileURL = containerURL.appendingPathComponent("ngram_\(language).plist")
```

```swift
        self.init(
            language: language,
            fileURL: fileURL,
            legacyFileURL: legacyFileURL,
            legacyStorage: legacyStorage,
            loadApplyDelay: nil
        )
```

(d) designated init:

```swift
    init(
        language: String,
        fileURL: URL,
        legacyFileURL: URL? = nil,
        legacyStorage: UserDefaults,
        loadApplyDelay: Duration? = nil,
        maxKeys: Int = 5000,
        saveQueue: DispatchQueue = DispatchQueue(label: "com.snmac.sykeyboard.ngram.save", qos: .utility)
    ) {
        self.language = language
        self.fileURL = fileURL
        self.legacyFileURL = legacyFileURL
        self.legacyStorage = legacyStorage
        self.loadApplyDelay = loadApplyDelay
        self.maxKeys = maxKeys
        self.saveQueue = saveQueue
        // 로딩·초기화와 경쟁하지 않도록 백그라운드 로딩 전에 옮긴다. 같은 볼륨 안 rename이라 비용이 작다
        if let legacyFileURL {
            Self.moveLegacyFileIfNeeded(from: legacyFileURL, to: fileURL)
        }
        startBackgroundLoad()
    }
```

(e) `saveToDisk()`의 do 블록(416–420행) 인코딩·쓰기를 헬퍼로 교체:

```swift
            do {
                try Self.write(snapshot, to: url)
```

(f) `migrateFromUserDefaults()`의 do 블록(514–518행)을 교체:

```swift
        do {
            try Self.write(migrated, to: fileURL)
        } catch {
```

(g) `resetAllData()`의 파일 삭제(455–456행)를 교체:

```swift
        // 파일 삭제. 옮기지 못한 옛 파일이 남으면 다음 실행에서 되살아나므로 함께 지운다
        try? FileManager.default.removeItem(at: fileURL)
        if let legacyFileURL {
            try? FileManager.default.removeItem(at: legacyFileURL)
        }
```

(h) private extension의 `// MARK: File I/O`에서 `loadFromFile()`을 교체하고 두 static 메서드를 추가:

```swift
    /// 바이너리 plist 파일에서 n-gram 데이터를 로드합니다.
    ///
    /// 새 위치를 먼저 읽고, 없으면 옮기지 못한 옛 위치를 읽습니다.
    ///
    /// - Returns: 로드된 데이터, 파일이 없거나 파싱 실패 시 `nil`
    func loadFromFile() -> NGramData? {
        for url in [fileURL, legacyFileURL].compactMap({ $0 }) {
            guard let data = try? Data(contentsOf: url) else { continue }
            return try? PropertyListDecoder().decode(NGramData.self, from: data)
        }
        return nil
    }

    /// 새 위치에 파일이 없고 옛 위치에 있을 때만 옮긴다.
    /// 다른 프로세스가 먼저 옮겼거나 옮기지 못해도 로딩이 새 위치 → 옛 위치 순으로 읽으므로 실패는 기록만 한다
    static func moveLegacyFileIfNeeded(from legacyURL: URL, to fileURL: URL) {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: fileURL.path),
              fileManager.fileExists(atPath: legacyURL.path) else { return }
        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.moveItem(at: legacyURL, to: fileURL)
        } catch {
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "NGramPredictiveTextEngine")
                .error("[NGram] 옛 위치 파일 이동 실패: \(error.localizedDescription)")
        }
    }

    /// App Group 컨테이너에는 `Library/Application Support`가 기본으로 없어 쓰기 전에 만든다
    static func write(_ ngramData: NGramData, to url: URL) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(ngramData)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
```

- [x] **Step 4: 새 테스트와 기존 NGram 테스트 통과 확인**

Run: 위 명령에 아래 네 suite를 함께 지정
`-only-testing:SYKeyboardTests/NGramPredictiveTextEngineFileMigrationTests -only-testing:SYKeyboardTests/NGramPredictiveTextEnginePersistenceTests -only-testing:SYKeyboardTests/NGramPredictiveTextEngineLoadingTests -only-testing:SYKeyboardTests/NGramPredictiveTextEngineRankingTests`
Expected: `TEST SUCCEEDED`, 새 테스트 5개 포함 전부 통과. 실제 통과 개수를 이 step 아래에 기록한다.

실제 결과: `** TEST SUCCEEDED **`, 총 14개 테스트 통과 (iPhone 13 mini, iOS 18.6).
- `NGramPredictiveTextEngineFileMigrationTests` 5개 전부 통과
- `NGramPredictiveTextEnginePersistenceTests` 3개 전부 통과
- `NGramPredictiveTextEngineLoadingTests` 2개 전부 통과
- `NGramPredictiveTextEngineRankingTests` 4개 전부 통과

- [x] **Step 5: 커밋**

```bash
git add Modules/SYKeyboardCore/Domain/PredictiveText/NGramPredictiveTextEngine.swift \
  SYKeyboardTests/Domain/NGramPredictiveTextEngineFileMigrationTests.swift \
  docs/superpowers/plans/2026-09-15-issue-131-ngram-application-support.md
git commit -m "refactor: #131 - NGram 학습 파일을 Application Support로 옮기고 옛 위치 파일을 한 번 이동"
```

### Task 2: Caps lock을 켠 채 누르고 입력한 뒤 떼도 caps lock 유지

**원인(코드 추적으로 확인):**

`Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift:76-83`

```swift
if (!isCapsLocked && wasShifted) || getIsShiftedLetterInput() {
    isShifted = false
    setIsShiftedLetterInput(false)
}
```

1. 첫 탭: `touchDown` → `willCapsLock = true`, `isShifted = true`. `touchUpInside` → 조건 false, 유지.
2. 두 번째 누름: `touchDown` → `wasShifted = true`, `touchDownRepeat` → `isCapsLocked = true`.
3. 누른 채 `A` 입력: `EnglishKeyboardCoreViewController.textInteractionDidPerform` → `recordInsertedText("A")`가 `isUppercaseInput = true`. 이어지는 `updateAutocapitalization`은 `isShiftButtonPressed == true`라 바로 return하므로 플래그가 남는다.
4. Shift 뗌: `getIsShiftedLetterInput()`이 true라 caps lock 여부와 관계없이 `isShifted = false`. `isCapsLocked`는 true로 남지만 키 라벨(`keyListIndex`는 `isShifted`만 봄)과 Shift 아이콘(`isShifted` didSet → `updateShiftState(false)`)이 소문자 상태가 된다. 사용자에게는 caps lock이 풀린 것으로 보이고, 내부 상태는 `isCapsLocked == true && isShifted == false`로 어긋난다.

한 번만 누른 채 입력하는 경우는 `isCapsLocked == false`라 4에서 해제되어야 하며, 수정 후에도 같은 경로를 탄다.

**Files:**
- Modify: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift:78`
- Test: `SYKeyboardTests/Domain/EnglishKeyboardInputAdapterTests.swift`

- [x] **Step 1: 실패하는 테스트 작성**

`EnglishKeyboardInputAdapterTests`의 마지막 테스트 뒤에 추가:

```swift
    @Test("Shift를 두 번 눌러 caps lock을 켠 채 누르고 글자를 입력한 뒤 떼도 caps lock 유지")
    func testCapsLockHeldWhileTypingStaysLockedAfterRelease() throws {
        let adapter = EnglishKeyboardInputAdapter()
        let shiftButton = try #require(adapter.primaryKeyboardView as? EnglishKeyboardLayoutProvider).shiftButton

        shiftButton.sendActions(for: .touchDown)
        shiftButton.sendActions(for: .touchUpInside)
        shiftButton.sendActions(for: .touchDown)
        shiftButton.sendActions(for: .touchDownRepeat)
        typeLetterWhileShiftPressed("A", adapter: adapter)
        shiftButton.sendActions(for: .touchUpInside)

        #expect(adapter.isCapsLocked)
        #expect(adapter.isShifted)
    }

    @Test("Shift를 한 번 누른 채 글자를 입력한 뒤 떼면 대문자 해제")
    func testShiftHeldWhileTypingReleasesAfterRelease() throws {
        let adapter = EnglishKeyboardInputAdapter()
        let shiftButton = try #require(adapter.primaryKeyboardView as? EnglishKeyboardLayoutProvider).shiftButton

        shiftButton.sendActions(for: .touchDown)
        typeLetterWhileShiftPressed("A", adapter: adapter)
        shiftButton.sendActions(for: .touchUpInside)

        #expect(adapter.isCapsLocked == false)
        #expect(adapter.isShifted == false)
    }
```

같은 파일 맨 아래(struct 밖)에 helper 추가. VC가 글자 입력 직후 부르는 두 production 메서드를 같은 순서로 호출한다:

```swift
/// `EnglishKeyboardCoreViewController.textInteractionDidPerform`이 Shift를 누른 채 글자를 입력했을 때 부르는 순서
@MainActor
private func typeLetterWhileShiftPressed(_ letter: String, adapter: EnglishKeyboardInputAdapter) {
    adapter.recordInsertedText(letter)
    adapter.updateAutocapitalization(
        type: .sentences,
        documentContextBeforeInput: letter,
        isEnabled: true,
        isShiftButtonPressed: true
    )
}
```

- [x] **Step 2: 테스트가 실패하는지 확인**

Run: 위 명령에 `-only-testing:SYKeyboardTests/EnglishKeyboardInputAdapterTests`
Expected: `testCapsLockHeldWhileTypingStaysLockedAfterRelease`만 `#expect(adapter.isShifted)`에서 실패(`isCapsLocked`는 true로 통과). `testShiftHeldWhileTypingReleasesAfterRelease`는 현재 동작 보존 확인용이라 통과.

실제 결과: production 변경분만 `git stash`로 제외하고 실행. `TEST FAILED`. `testCapsLockHeldWhileTypingStaysLockedAfterRelease()`만 failed, 나머지 4건(`testAutocapitalizationUpdatesProductionView`, `testFinishForLanguageChangeResetsShiftAndCaps`, `testShiftHeldWhileTypingReleasesAfterRelease`, `testRecordedUppercaseInputResetsTemporaryShift`)은 passed. 기대한 RED와 일치. 확인 후 `git stash pop`으로 production 변경 복원.

- [x] **Step 3: 조건 수정**

`EnglishKeyboardView.swift`의 `disableShift`를 교체:

```swift
        let disableShift = UIAction { [weak self] _ in
            guard let self else { return }
            // caps lock 중에는 누른 채 글자를 입력했더라도 떼는 동작으로 해제하지 않는다
            if !isCapsLocked && (wasShifted || getIsShiftedLetterInput()) {
                isShifted = false
                setIsShiftedLetterInput(false)
            }
        }
```

caps lock 중에 남는 `isUppercaseInput == true`는 다음 글자 입력의 `updateAutocapitalization`(Shift 안 누른 상태)에서 false로 돌아가고, caps lock을 끄는 탭은 `wasShifted == true` 경로로 해제되므로 영향이 없다.

- [x] **Step 4: 테스트 통과 확인**

Run: `-only-testing:SYKeyboardTests/EnglishKeyboardInputAdapterTests -only-testing:SYKeyboardTests/ButtonStateControllerTests -only-testing:SYKeyboardTests/HangeulEnglishKeyboardModeCoordinatorTests`
Expected: `TEST SUCCEEDED`. 실제 통과 개수를 기록한다.

실제 결과: `TEST SUCCEEDED`, 12/12 통과 (`EnglishKeyboardInputAdapterTests` 5건 + `ButtonStateControllerTests` 4건 + `HangeulEnglishKeyboardModeCoordinatorTests` 3건). `testCapsLockHeldWhileTypingStaysLockedAfterRelease()` 포함 전부 passed.

- [x] **Step 5: extension 빌드**

`EnglishKeyboard`, `HangeulEnglishKeyboard` scheme을 `-only-testing` 없이 `xcodebuild build`. Expected: 둘 다 `BUILD SUCCEEDED`. `.xcscheme` `RemotePath` 변경은 되돌린다.

실제 결과: `EnglishKeyboard` `BUILD SUCCEEDED`, `HangeulEnglishKeyboard` `BUILD SUCCEEDED`. 빌드 후 `git status --short`에 `.xcscheme` 변경 없음(되돌릴 항목 없음).

- [x] **Step 6: 커밋**

```bash
git add Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift \
  SYKeyboardTests/Domain/EnglishKeyboardInputAdapterTests.swift \
  2026-09-15-issue-131-ngram-application-support.md
git commit -m "fix: #131 - caps lock을 켠 채 Shift를 누르고 입력한 뒤 떼면 caps lock이 풀리는 현상 수정"
```

### Task 3: 클립보드 행을 끌다 놓으면 눌림 배경이 남는 현상

**현재까지 확인한 것:** `ClipboardHistoryPanelView.makeCell`은 `selectedBackgroundView`(`.suggestionButtonPressed`, 다크 모드에서 흰색에 가까움)를 둔다. 이 배경은 셀이 highlighted이거나 selected일 때 보인다. 평소 모드의 `didSelectRowAt`은 곧바로 `deselectRow`하므로, 남는 배경은 (A) 스와이프 제스처가 시작·취소되며 highlight 해제가 누락되었거나 (B) `didSelectRowAt`을 거치지 않은 선택이 남은 경우다. 패널은 `didHighlight`/`didUnhighlight`/`willBeginEditingRowAt`/`didEndEditingRowAt`을 구현하지 않는다. 간헐적이고 손 조작이 필요해 코드만으로 A/B를 확정할 수 없으므로 증거부터 수집한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift` (UITableViewDelegate extension)
- Test: `SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift`

- [ ] **Step 1: 진단 로그 임시 추가(커밋하지 않음)**

파일 맨 위 `import UIKit` 아래에 `import OSLog`를 넣는다. optional delegate 메서드는 `UITableViewDelegate`를 채택한 extension 안에 있어야 Objective-C로 노출되어 UIKit이 호출하므로, 아래 네 메서드는 기존 `extension ClipboardHistoryPanelView: UITableViewDelegate` 안(`didDeselectRowAt` 뒤)에 넣는다:

```swift
    // DEBUG 진단(커밋 금지)
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        debugLog("didHighlight \(indexPath.row)")
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        debugLog("didUnhighlight \(indexPath.row)")
    }

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        debugLog("willBeginEditing \(indexPath.row)")
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        debugLog("didEndEditing \(indexPath?.row ?? -1)")
    }
```

파일 맨 아래에 추가:

```swift
// MARK: - DEBUG 진단(커밋 금지)

private let clipboardPanelDebugLogger = Logger(subsystem: "SYKeyboardDebug", category: "ClipboardPanelDebug")

extension ClipboardHistoryPanelView {
    func debugLog(_ event: String) {
        clipboardPanelDebugLogger.debug("\(event, privacy: .public) isEditing=\(self.tableView.isEditing) isItemEditing=\(self.isItemEditing)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            let selected = self.tableView.indexPathsForSelectedRows?.map(\.row) ?? []
            let highlighted = self.tableView.indexPathsForVisibleRows?
                .filter { self.tableView.cellForRow(at: $0)?.isHighlighted == true }
                .map(\.row) ?? []
            clipboardPanelDebugLogger.debug("  after \(event, privacy: .public): selected=\(selected, privacy: .public) highlighted=\(highlighted, privacy: .public) isEditing=\(self.tableView.isEditing)")
        }
    }
}
```

기존 `didSelectRowAt`, `didDeselectRowAt` 첫 줄에도 `debugLog("didSelect \(indexPath.row)")` / `debugLog("didDeselect \(indexPath.row)")`를 넣는다.

- [ ] **Step 2: 재현하며 로그 수집(사용자 조작 필요)**

1. `HangeulKeyboard` scheme을 시뮬레이터에서 실행하고 메모 등 입력 앱에서 키보드의 클립보드 기록 패널을 연다(텍스트 항목 3개 이상).
2. 에이전트가 백그라운드로 로그를 받는다:
   `xcrun simctl spawn booted log stream --level debug --predicate 'category == "ClipboardPanelDebug"'`
3. 사용자가 마우스로 행을 누른 채 좌우로 천천히 끌다 놓기를 재현될 때까지 반복한다. 시뮬레이터에서 재현되지 않으면 실기기에서 Console.app으로 같은 category를 필터링한다.
4. 재현된 시도의 로그 묶음 전체를 이 step 아래에 붙인다.

- [ ] **Step 3: 로그로 원인 판정**

| 재현 시 로그 | 판정 | 다음 |
|---|---|---|
| `willBeginEditing N` → `didEndEditing N` 이후 `after didEndEditing`에 `highlighted=[N]` 또는 `selected=[N]` | A 또는 B. 스와이프 종료 뒤 표시가 남음 | Step 4 진행 |
| `didHighlight N` 뒤 `willBeginEditing`/`didEndEditing` 없이 `highlighted=[N]` 또는 `selected=[N]`이 남음 | 스와이프가 시작되지 않은 경로. 이 계획의 수정안 적용 대상이 아님 | 멈추고 로그와 함께 사용자에게 보고, Phase 1 재분석 |
| 표시가 남았는데 `selected`/`highlighted` 모두 비어 있음 | 셀 선택 상태가 아닌 다른 뷰(스와이프 액션 컨테이너 등)의 잔상 | 멈추고 사용자에게 보고, 화면 캡처와 함께 재분석 |

판정 결과와 근거 로그 줄을 이 step 아래에 적는다.

- [ ] **Step 4: 실패하는 테스트 작성(Step 3이 A/B일 때만)**

`ClipboardHistoryPanelViewTests`의 `test스와이프중configure는_편집모드로바뀌지않음` 뒤에 추가:

```swift
    @Test("스와이프가 끝나면 편집 모드가 아닐 때 행의 선택·눌림 표시를 해제")
    func test스와이프종료는_눌림표시해제() throws {
        let (panel, _) = makePanel(texts: ["a", "b"])
        let window = UIWindow(frame: panel.frame)
        window.addSubview(panel)
        panel.layoutIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)
        panel.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        let cell = try #require(panel.tableView.cellForRow(at: indexPath))
        cell.setHighlighted(true, animated: false)

        panel.tableView(panel.tableView, didEndEditingRowAt: indexPath)

        #expect(panel.tableView.indexPathsForSelectedRows == nil)
        #expect(cell.isHighlighted == false)
    }

    @Test("편집 모드에서는 스와이프 종료가 선택을 해제하지 않음")
    func test편집모드스와이프종료는_선택유지() {
        let (panel, _) = makePanel(texts: ["a", "b"])
        let indexPath = IndexPath(row: 1, section: 0)

        panel.beginItemEditing()
        panel.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        panel.tableView(panel.tableView, didEndEditingRowAt: indexPath)

        #expect(panel.tableView.indexPathsForSelectedRows == [indexPath])
    }
```

Step 1의 진단 코드를 먼저 모두 지운다(`import OSLog`, delegate 네 메서드, 맨 아래 extension, `didSelectRowAt`/`didDeselectRowAt`에 넣은 `debugLog` 줄). `git diff -- Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`가 비어 있는지 확인한다. 지우지 않으면 진단용 `didEndEditingRowAt`이 테스트를 가린다.

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: 컴파일 실패 `value of type 'ClipboardHistoryPanelView' has no member 'tableView(_:didEndEditingRowAt:)'`

- [ ] **Step 5: 수정 구현**

`ClipboardHistoryPanelView.swift`의 `UITableViewDelegate` extension에서 `didDeselectRowAt` 뒤에 추가:

```swift
    /// 스와이프를 조금 끌다 놓아 액션이 열리지 않고 끝나면 눌림 배경이 남는 경우가 있어 해제한다. 편집 모드 선택은 유지한다
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        guard !isItemEditing, let indexPath else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.cellForRow(at: indexPath)?.setHighlighted(false, animated: true)
    }
```

`beginItemEditing()`은 `isItemEditing = true` 뒤에 `setEditing(false)`로 열린 스와이프를 닫으므로 이 guard에 걸려 편집 모드 진입에는 영향이 없다.

- [ ] **Step 6: 테스트 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: `TEST SUCCEEDED`, 새 테스트 2개 포함. 실제 개수를 기록한다.

- [ ] **Step 7: 재현 조작으로 수정 확인(사용자 조작 필요)**

Step 2와 같은 환경에서 끌다 놓기를 20회 이상 반복해 눌림 배경이 남지 않는지, 행 탭 붙여넣기·스와이프 삭제·스와이프 고정·길게 누르기 상세·편집 모드 다중 선택이 그대로인지 확인한다. 여전히 남으면 수정을 되돌리고 Step 1로 돌아간다(추가 수정을 쌓지 않는다). 확인하지 못했으면 체크하지 않고 이유를 적는다.

- [ ] **Step 8: 커밋**

`git diff`에 진단 코드가 없는지 확인한 뒤:

```bash
git add Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift \
  SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift \
  2026-09-15-issue-131-ngram-application-support.md
git commit -m "fix: #131 - 클립보드 기록 행을 끌다 놓으면 눌림 배경이 남는 현상 수정"
```

### Task 4: 전체 검증과 결과 기록

**Files:**
- Modify: `docs/superpowers/plans/2026-09-15-issue-131-ngram-application-support.md`

- [ ] **Step 1: 전체 테스트**

Run: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' 2>&1 | grep -E "failed on|error:|TEST (SUCCEEDED|FAILED)|Test run with"`
Expected: `TEST SUCCEEDED`. 실제 테스트 개수와 `.xcresult` 경로를 기록한다.

- [ ] **Step 2: extension 3종 빌드**

`-only-testing` 없이 `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` scheme을 각각 `xcodebuild build`한다(CLAUDE.md 명령). Expected: 세 번 모두 `BUILD SUCCEEDED`. 이후 `git status --short`에서 `.xcscheme`의 `RemotePath` 변경만 있으면 되돌린다.

- [ ] **Step 3: 실기기 업데이트 확인(사용자 수행)**

1. develop(`ba93ae17`) 빌드를 실기기에 설치하고 한글·영어 키보드에서 단어를 학습시켜 자동완성 후보가 뜨는 것을 확인한다.
2. 이 브랜치 빌드를 덮어 설치(앱 삭제 금지)한다.
3. 키보드를 열어 같은 후보가 그대로 뜨는지, 새 단어 학습 후 키보드를 다시 열어도 유지되는지 확인한다.
4. 앱 설정의 n-gram 초기화 후 후보가 사라지고 키보드를 다시 열어도 되살아나지 않는지 확인한다.

자동 테스트로 대체하지 않는다. 확인하지 못했으면 체크하지 않고 이유를 적는다.

- [ ] **Step 4: 실기기 Shift 확인(사용자 수행)**

영어 키보드와 한영 통합 키보드(영어 모드) 각각에서:
1. Shift 두 번 탭 → caps lock 아이콘 → Shift를 누른 채 `ABC` 입력 → 떼기 → caps lock 아이콘과 대문자 라벨 유지, 이어서 `D` 입력 시 대문자.
2. Shift 한 번 누른 채 `A` 입력 → 떼기 → 소문자 라벨로 복귀.
3. caps lock 상태에서 Shift 한 번 탭 → caps lock 해제.
4. Shift 한 번 탭 → `A` 입력 → 소문자 복귀(기존 동작).

- [ ] **Step 5: 커밋**

```bash
git add docs/superpowers/plans/2026-09-15-issue-131-ngram-application-support.md
git commit -m "docs: #131 - NGram 파일 이동·caps lock·클립보드 행 수정 검증 결과 기록"
```

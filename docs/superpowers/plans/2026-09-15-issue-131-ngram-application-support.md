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
- 커밋 메시지 `type: #131 - subject`, 한국어, 마침표 없음. Task 1은 `refactor`, Task 2·3·5·6은 `fix`, Task 4는 `feat`, Task 7은 `docs`. 본문 끝에 세션 attribution을 붙인다.
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

**조사 시작 시점에 확인한 것:** `ClipboardHistoryPanelView.makeCell`은 `selectedBackgroundView`(`.suggestionButtonPressed`, 다크 모드에서 흰색에 가까움)를 둔다. 이 배경은 셀이 highlighted이거나 selected일 때 보인다. 평소 모드의 `didSelectRowAt`은 곧바로 `deselectRow`하므로, 남는 배경은 (A) 스와이프 제스처가 시작·취소되며 highlight 해제가 누락되었거나 (B) `didSelectRowAt`을 거치지 않은 선택이 남은 경우다. 패널은 `didHighlight`/`didUnhighlight`/`willBeginEditingRowAt`/`didEndEditingRowAt`을 구현하지 않는다. 간헐적이고 손 조작이 필요해 코드만으로 A/B를 확정할 수 없으므로 증거부터 수집한다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift` (UITableViewDelegate extension)
- Test: `SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift`

- [x] **Step 1: 진단 로그 임시 추가(커밋하지 않음)**

실행 결과: 적용 후 SYKeyboard app scheme 빌드(확장 3종 포함)를 iPhone 13 mini / iOS 18.6(`82146144-24DE-4F91-B25D-23D147A91142`)에 설치. 이후 원인 추적을 위해 `didHighlightRowAt`·`didEndEditingRowAt`에 호출 스택(프레임별), 테이블 제스처 인식기 상태, `isTracking`/`isDragging` 로그를 차례로 더했다(모두 미커밋).

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

- [x] **Step 2: 재현하며 로그 수집(사용자 조작 필요)**

1. `HangeulKeyboard` scheme을 시뮬레이터에서 실행하고 메모 등 입력 앱에서 키보드의 클립보드 기록 패널을 연다(텍스트 항목 3개 이상).
2. 에이전트가 백그라운드로 로그를 받는다:
   `xcrun simctl spawn booted log stream --level debug --predicate 'category == "ClipboardPanelDebug"'`
3. 사용자가 마우스로 행을 누른 채 좌우로 천천히 끌다 놓기를 재현될 때까지 반복한다. 시뮬레이터에서 재현되지 않으면 실기기에서 Console.app으로 같은 category를 필터링한다.
4. 재현된 시도의 로그 묶음 전체를 이 step 아래에 붙인다.

실행 결과: 로그 명령 `xcrun simctl spawn 82146144-24DE-4F91-B25D-23D147A91142 log stream --level debug --style compact --predicate 'subsystem == "SYKeyboardDebug"'`. 사용자가 한영 통합 키보드 패널에서 5회 시도해 4회 재현(1·2·3·5회차). 산출물은 git-ignored 작업 폴더 `.superpowers/sdd/2026-09-15-issue-131-ngram-application-support/clipboard-diag-run{1,2,3,5}.log`. 5회차 핵심 줄:

```
30.491 didHighlight 0
30.755 didUnhighlight 0
30.761 willBeginEditing 0
32.337 didEndEditing 0   state: isTracking=true (손가락 누른 채 원위치로 끌어 스와이프만 끝남)
32.458 didHighlight 0    state: isTracking=true, UIScrollViewDelayedTouchesBeganGestureRecognizer state=5
32.648 willBeginEditing 0 (didUnhighlight 없음)
34.448 didEndEditing 0   state: isTracking=false (손 뗌)
35.080 after didEndEditing 0: selected=[] highlighted=[0]
```

3회차 늦은 `didHighlight` 호출 스택: `UIGestureDelayedEventComponentDispatcher sendDelayedTouches` → `UITableViewCell touchesBegan` → `UITableView touchesBegan` → `_highlightRowAtIndexPath`.

- [x] **Step 3: 로그로 원인 판정**

| 재현 시 로그 | 판정 | 다음 |
|---|---|---|
| `willBeginEditing N` → `didEndEditing N` 이후 `after didEndEditing`에 `highlighted=[N]` 또는 `selected=[N]` | A 또는 B. 스와이프 종료 뒤 표시가 남음 | Step 4 진행 |
| `didHighlight N` 뒤 `willBeginEditing`/`didEndEditing` 없이 `highlighted=[N]` 또는 `selected=[N]`이 남음 | 스와이프가 시작되지 않은 경로. 이 계획의 수정안 적용 대상이 아님 | 멈추고 로그와 함께 사용자에게 보고, Phase 1 재분석 |
| 표시가 남았는데 `selected`/`highlighted` 모두 비어 있음 | 셀 선택 상태가 아닌 다른 뷰(스와이프 액션 컨테이너 등)의 잔상 | 멈추고 사용자에게 보고, 화면 캡처와 함께 재분석 |

판정 결과와 근거 로그 줄을 이 step 아래에 적는다.

판정: 표 1행(스와이프 종료 뒤 `highlighted=[0]`, `selected=[]`)이지만 원인은 A의 변형이다. 같은 터치 도중 스와이프가 끝나면 테이블 인식기 중 유일하게 활성·`delaysTouchesBegan=true`인 `UIScrollViewDelayedTouchesBeganGestureRecognizer`(`delaysContentTouches=true`)가 이미 취소된 터치의 `touchesBegan`을 다시 보내 눌림을 건다. 그 터치의 끝·취소는 테이블에 다시 오지 않아 이후 스와이프와 손 떼기로도 풀리지 않는다. 눌림은 `didEndEditingRowAt`보다 뒤에 걸리므로 원래 Step 4·5 안(스와이프 종료 시 해제)은 효과가 없어 폐기했다. 짧은 탭도 손을 뗄 때 지연 `touchesBegan`이 전달되지만(`didHighlight` `isTracking=false`) 2 ms 안에 `didSelect`가 이어진다. `delaysContentTouches=false`는 스크롤 시작 시 행이 잠깐 눌려 보이는 변화가 생겨 제외한다.

- [x] **Step 4: 진단 코드 제거와 실패하는 테스트 작성**

먼저 진단 코드를 모두 지운다: `git checkout -- Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift` 후 `git diff -- Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`가 비어 있는지 확인한다(이 파일의 미커밋 변경은 진단 코드뿐이다).

`ClipboardHistoryPanelViewTests`의 `test스와이프중configure는_편집모드로바뀌지않음` 뒤에 추가:

```swift
    @Test("손가락 없이 걸린 행 눌림은 선택이 이어지지 않으면 다음 runloop에 해제")
    func test손가락없이걸린눌림은_다음runloop에해제() async throws {
        let (panel, _) = makePanel(texts: ["a", "b"])
        let window = UIWindow(frame: panel.frame)
        window.addSubview(panel)
        panel.layoutIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = try #require(panel.tableView.cellForRow(at: indexPath))
        cell.setHighlighted(true, animated: false)

        panel.tableView(panel.tableView, didHighlightRowAt: indexPath)
        await drainMainQueue()

        #expect(cell.isHighlighted == false)
    }

    @Test("편집 모드에서는 손가락 없이 걸린 눌림도 정리하지 않음")
    func test편집모드는_눌림정리안함() async throws {
        let (panel, _) = makePanel(texts: ["a", "b"])
        let window = UIWindow(frame: panel.frame)
        window.addSubview(panel)
        panel.layoutIfNeeded()
        let indexPath = IndexPath(row: 1, section: 0)
        let cell = try #require(panel.tableView.cellForRow(at: indexPath))

        panel.beginItemEditing()
        cell.setHighlighted(true, animated: false)
        panel.tableView(panel.tableView, didHighlightRowAt: indexPath)
        await drainMainQueue()

        #expect(cell.isHighlighted)
    }
```

파일 맨 아래 helper 영역(`private func makePanel` 근처)에 추가:

```swift
/// 패널이 `DispatchQueue.main.async`로 예약한 작업이 끝날 때까지 기다린다
@MainActor
private func drainMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async { continuation.resume() }
    }
}
```

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: 컴파일 실패 `value of type 'ClipboardHistoryPanelView' has no member 'tableView(_:didHighlightRowAt:)'`

실행 결과: 진단 코드는 `git checkout -- Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`로 제거했고 이후 `git diff`가 비어 있음을 확인했다(진단 코드만 있던 상태였음을 재확인). 새 테스트 2개와 `drainMainQueue` helper 추가 후 실행:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests
```

RED 확인. 컴파일 실패 메시지는 예상 문구와 정확히 같지 않지만 같은 원인이다:
`SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift:136:15: error: no exact matches in call to instance method 'tableView'`
(`didHighlightRowAt` 오버로드가 아직 없어 `tableView(_:didSelectRowAt:)` 등 기존 오버로드와 매칭 실패). `** TEST FAILED **`.

- [x] **Step 5: 수정 구현**

(a) `ClipboardHistoryPanelView.swift` 맨 위 `import UIKit` 아래에 추가:

```swift
import UIKit.UIGestureRecognizerSubclass
```

(b) `longPressRecognizer` 프로퍼티 선언 바로 뒤에 추가:

```swift
    /// 테이블 터치의 시작·끝을 지연 없이 관찰한다. 손가락이 모두 떨어진 뒤 남은 행 눌림을 정리하는 기준이다
    private lazy var touchObserver: ClipboardHistoryTouchObserver = {
        let recognizer = ClipboardHistoryTouchObserver()
        recognizer.onAllTouchesEnded = { [weak self] in self?.scheduleStaleHighlightCleanup() }
        return recognizer
    }()
```

(c) `setupUI()`의 `tableView.addGestureRecognizer(longPressRecognizer)` 다음 줄에 추가:

```swift
        tableView.addGestureRecognizer(touchObserver)
```

(d) `// MARK: - Private Methods`의 private extension에서 `handleLongPress` 앞에 추가:

```swift
    /// 같은 터치 도중 스와이프가 끝나면 스크롤 뷰가 붙잡아 둔 touchesBegan이 이미 취소된 터치로 다시 전달돼
    /// 눌림만 걸리고 끝 이벤트는 오지 않는다. 다음 runloop에서 손가락이 없고 선택 없이 눌림만 남은 행을 해제한다.
    /// 짧은 탭은 같은 이벤트 처리 안에서 선택·해제가 끝나므로 영향이 없고, 편집 모드는 선택 표시를 쓰므로 건드리지 않는다
    func scheduleStaleHighlightCleanup() {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isItemEditing, self.touchObserver.activeTouchCount == 0 else { return }
            for cell in self.tableView.visibleCells where cell.isHighlighted && !cell.isSelected {
                cell.setHighlighted(false, animated: true)
            }
        }
    }
```

(e) `UITableViewDelegate` extension의 `didDeselectRowAt` 뒤에 추가:

```swift
    /// 손가락이 이미 떨어진 뒤의 눌림은 짧은 탭이면 곧바로 선택이 이어지고, 늦게 전달된 터치면 그대로 남는다
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard touchObserver.activeTouchCount == 0 else { return }
        scheduleStaleHighlightCleanup()
    }
```

(f) `// MARK: - Supporting Types`의 `ClipboardHistoryDataSource` 뒤에 추가:

```swift
/// 터치 수만 세는 인식기. 인식하지 않고, 다른 인식기를 막거나 막히지 않으며, 뷰로 가는 터치를 지연·취소하지 않는다
private final class ClipboardHistoryTouchObserver: UIGestureRecognizer {
    private(set) var activeTouchCount = 0
    var onAllTouchesEnded: (() -> Void)?

    init() {
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        activeTouchCount += touches.count
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        endTouches(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        endTouches(touches)
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    private func endTouches(_ touches: Set<UITouch>) {
        activeTouchCount = max(0, activeTouchCount - touches.count)
        guard activeTouchCount == 0 else { return }
        onAllTouchesEnded?()
        // 인식하지 않으므로 실패로 끝내 다음 터치에서 다시 시작한다
        state = .failed
    }
}
```

브리프의 코드를 그대로 적용했다(변경 없음).

- [x] **Step 6: 테스트 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: `TEST SUCCEEDED`, 새 테스트 2개 포함. 실제 개수를 기록한다. 이어서 `HangeulKeyboard`, `HangeulEnglishKeyboard` scheme을 `-only-testing` 없이 빌드해 `BUILD SUCCEEDED`를 확인하고, SYKeyboard app scheme 빌드를 같은 iOS 18.6 시뮬레이터에 설치한다(앱 삭제 금지).

실행 결과:

- 첫 실행이 `xcodebuild[38639]`에서 `The test runner hung before establishing connection.`으로 실패(`Testing failed`, exit 65). 원인 확인: `xcrun simctl list devices`로 확인한 결과 이전 병렬 테스트가 남긴 clone 시뮬레이터 2개(`CBD992D3-...`, `583AC8EE-...`)가 booted 상태였고, 그중 하나에 `Apple ID 확인` 시스템 알림이 떠 있었다(화면 캡처로 확인). CoreSimulatorService·리소스 경합에 따른 환경 문제로 판단해 코드 실패로 기록하지 않았다. `xcrun simctl shutdown`으로 두 clone을 모두 종료한 뒤 같은 명령을 재시도했다(재시도 1회, 지침 범위 내).
- 재시도: `** TEST SUCCEEDED **`, 총 23개 테스트 모두 통과(새 테스트 2개 `test손가락없이걸린눌림은_다음runloop에해제`, `test편집모드는_눌림정리안함` 포함). 실패 0건.
- `HangeulKeyboard` scheme 빌드(`-only-testing` 없이): `** BUILD SUCCEEDED **`.
- `HangeulEnglishKeyboard` scheme 빌드(`-only-testing` 없이): `** BUILD SUCCEEDED **`.
- `SYKeyboard` app scheme 빌드(iOS 18.6 시뮬레이터): `** BUILD SUCCEEDED **`.
- 설치: DerivedData `SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Build/Products/Debug-iphonesimulator/SYKeyboard.app`을 대상 시뮬레이터(`82146144-24DE-4F91-B25D-23D147A91142`, 부팅 후)에 `xcrun simctl install`로 설치, 성공(exit 0). 앱은 삭제하지 않았다. 이어서 `xcrun simctl terminate ... github.com-SNMac.SYKeyboard`는 "found nothing to terminate"로 응답(지침에서 무시하도록 안내한 상황).

- [x] **Step 7: 재현 조작으로 수정 확인(사용자 조작 필요)**

Step 2와 같은 환경에서 끌다 놓기(특히 누른 채 원위치로 되돌렸다가 다시 끌기)를 20회 이상 반복해 눌림 배경이 남지 않는지, 행 짧은 탭 붙여넣기·1초 누르기 후 떼기·같은 행 재탭·스크롤·스와이프 삭제·스와이프 고정·길게 누르기 상세·편집 모드 다중 선택이 그대로인지 확인한다. 여전히 남으면 수정을 되돌리고 Step 1로 돌아간다(추가 수정을 쌓지 않는다). 확인하지 못했으면 체크하지 않고 이유를 적는다.

실행 결과(2026-09-15, 사용자 수행, Step 6에서 설치한 빌드):
1. 끌다 놓기 20회: 눌림 배경이 남지 않음. 수정 전에는 5회 중 4회 재현됐지만 간헐 현상이라 "20회 미재현"으로만 기록한다.
2. 행 짧은 탭 붙여넣기: 정상.
3. 끌다 놓기 직후 같은 행 재탭: 정상 붙여넣기.
4. 1초 누르기: 길게 누르기(기본 0.5초)로 상세 화면이 열림(기존 동작). 상세를 닫으면 눌림 배경 없음.
5. 스크롤: 정상.
6. 스와이프 삭제·고정/해제: 정상.
7. 편집 모드 다중 선택·삭제: 동작은 정상. 삭제 애니메이션에서 행이 위로 뭉개지며 체크 표시가 옆 행과 겹쳐 보이는 현상이 관찰됨. 이번 수정은 편집 모드에서 동작하지 않으므로(`isItemEditing` guard) 이번 diff의 회귀인지 기존 동작인지 별도로 확인한다(사용자가 `26399d8b` 영향 여부를 제기).

- [ ] **Step 8: 커밋**

`git diff`에 진단 코드가 없는지 확인한 뒤:

```bash
git add Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift \
  SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift \
  docs/superpowers/plans/2026-09-15-issue-131-ngram-application-support.md
git commit -m "fix: #131 - 클립보드 기록 행을 끌다 놓으면 눌림 배경이 남는 현상 수정"
```

### Task 4: 키보드 상세 화면에서 텍스트 일부 선택·복사와 기록 갱신

**배경:** 2026-09-15 사용자 요청으로 #131에 추가했다. 앱 상세 시트(`ClipboardHistorySettingsView`의 `Text(...).textSelection(.enabled)`)처럼 키보드 확장의 상세 화면에서도 본문을 길게 눌러 일부를 선택·복사하고, 복사한 내용이 클립보드 기록에 바로 반영되게 한다. 승인된 설계:

- 상세 본문 `UITextView`를 `isSelectable = true`로 바꾼다(편집 불가 유지). 전체가 URL인 항목의 탭으로 열기는 유지하되, 선택 영역이 있으면 탭으로 열지 않는다.
- 키보드가 `UIPasteboard.changedNotification`을 받으면 패널이 열려 있을 때 기존 동기화를 돌리고, 목록이 바뀌었으면 **상세 화면을 닫지 않고** 뒤의 목록만 다시 읽는다.
- 상세가 가리키는 항목을 인덱스(`detailIndex`)가 아니라 id로 들고 있어, 새 항목이 앞에 들어와도 붙여넣기·고정·URL 열기가 보던 항목에 적용된다. `ClipboardHistoryItem.id`는 내용에서 만든 값이라 같은 텍스트가 다시 기록돼도 id가 같다. 가리키던 항목이 목록에서 사라지면 지금처럼 상세를 닫는다.
- 기존 갱신 경로(패널 열기, 삭제, 고정, 호스트 재활성화 등)는 지금처럼 `configure(state:)`에서 상세를 닫는다.

**조사 결과:**
- `ClipboardHistoryPanelView.configure(state:)`는 첫 줄에서 `hideDetail()`을 부른다. `detailIndex`는 `showDetail(at:)`에서 저장되고 `onPaste`/`onTogglePin`/`onOpenURL` 클로저가 쓴다.
- `copyTextToPasteboard`와 `restoreImageToPasteboard`는 쓴 직후 `lastSeenPasteboardChangeCount`를 갱신하므로, 알림 처리를 다음 runloop로 미루면 이 두 경로는 동기화가 건너뛰어 중복 기록되지 않는다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Test: `SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift`

**Interfaces:**
- Produces: `ClipboardHistoryPanelView.configure(state: State, keepsDetail: Bool = false)`, `ClipboardHistoryPanelView.pasteDetailItem()`, `ClipboardHistoryPanelView.toggleDetailItemPin()`, `BaseKeyboardViewController.reloadClipboardPanel(keepsDetail: Bool = false)`.

- [x] **Step 1: 실패하는 테스트 작성**

`ClipboardHistoryPanelViewTests`에서 `test편집모드는_눌림정리안함` 뒤에 추가:

```swift
    @Test("기본 configure는 열린 상세를 닫음")
    func test기본configure는_상세를닫음() {
        let items = [unpinned("a"), unpinned("b")]
        let (panel, _) = makePanel(items: items)

        panel.showDetail(at: 1)
        panel.configure(state: .items(items))

        #expect(panel.isDetailVisible == false)
    }

    @Test("상세를 유지하는 갱신에서 앞에 새 항목이 들어오면 붙여넣기는 보던 항목의 새 인덱스를 요청")
    func test상세유지갱신후_붙여넣기는보던항목() {
        let items = [unpinned("a"), unpinned("b")]
        let (panel, spy) = makePanel(items: items)

        panel.showDetail(at: 1)
        panel.configure(state: .items([unpinned("new")] + items), keepsDetail: true)

        #expect(panel.isDetailVisible)
        panel.pasteDetailItem()
        #expect(spy.selectedIndices == [2])
    }

    @Test("상세를 유지하는 갱신에서 보던 항목이 다시 기록돼 앞으로 오면 고정은 그 항목을 요청")
    func test같은내용이다시기록되면_고정은그항목() {
        let (panel, spy) = makePanel(items: [unpinned("a"), unpinned("b")])

        panel.showDetail(at: 1)
        panel.configure(state: .items([unpinned("b"), unpinned("a")]), keepsDetail: true)

        #expect(panel.isDetailVisible)
        panel.toggleDetailItemPin()
        #expect(spy.toggledPinIndices == [0])
    }

    @Test("상세를 유지하는 갱신이어도 보던 항목이 사라지면 상세를 닫고 요청하지 않음")
    func test보던항목이사라지면_상세를닫음() {
        let (panel, spy) = makePanel(items: [unpinned("a"), unpinned("b")])

        panel.showDetail(at: 1)
        panel.configure(state: .items([unpinned("a")]), keepsDetail: true)
        panel.pasteDetailItem()

        #expect(panel.isDetailVisible == false)
        #expect(spy.selectedIndices.isEmpty)
    }
```

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: 컴파일 실패 `extra argument 'keepsDetail' in call` 또는 `value of type 'ClipboardHistoryPanelView' has no member 'pasteDetailItem'`

**실제 결과(RED):** 위 명령을 실행해 컴파일 실패를 확인했다.
```
error: extra argument 'keepsDetail' in call
error: value of type 'ClipboardHistoryPanelView' has no member 'pasteDetailItem'
error: extra argument 'keepsDetail' in call
error: value of type 'ClipboardHistoryPanelView' has no member 'toggleDetailItemPin'
error: extra argument 'keepsDetail' in call
error: value of type 'ClipboardHistoryPanelView' has no member 'pasteDetailItem'
** TEST FAILED **
```

- [x] **Step 2: 패널이 상세 항목을 id로 가리키게 구현**

`ClipboardHistoryPanelView.swift`에서:

(a) `private var detailIndex: Int?`를 교체:

```swift
    /// 상세 뷰가 보여주는 항목의 id. 목록이 갱신돼 순서가 바뀌어도 같은 항목을 가리킨다
    private var detailItemID: String?
    /// 상세 뷰가 보여주는 항목의 현재 인덱스. 목록에서 사라졌으면 `nil`
    private var detailItemIndex: Int? {
        guard let detailItemID else { return nil }
        return items.firstIndex { $0.id == detailItemID }
    }
```

(b) `detailView` 클로저를 교체:

```swift
        view.onClose = { [weak self] in self?.hideDetail() }
        view.onPaste = { [weak self] in self?.pasteDetailItem() }
        view.onTogglePin = { [weak self] in self?.toggleDetailItemPin() }
        view.onOpenURL = { [weak self] in
            guard let self, let index = self.detailItemIndex else { return }
            self.delegate?.clipboardPanel(self, didRequestOpenURLAt: index)
        }
```

(c) `configure(state:)`를 시그니처와 문서 주석, 첫 줄, 끝부분만 바꾼다:

```swift
    /// 패널 상태를 갱신합니다. 상세 뷰는 닫고, 편집 모드는 유지하되 항목이 없어지면 해제합니다.
    ///
    /// `keepsDetail`이면 상세 뷰를 닫지 않고 보던 항목을 새 목록에서 다시 가리킵니다. 그 항목이 사라졌으면 닫습니다.
    /// 상세 뷰에서 일부를 복사해 기록이 늘어난 경우처럼 사용자가 상세를 보는 중인 갱신에 씁니다.
    ///
    /// 패널이 보이는 중이면 바뀐 행만 삭제·삽입 애니메이션으로 반영하고, 숨겨진 상태면 전체를 다시 그립니다.
    func configure(state: State, keepsDetail: Bool = false) {
        if !keepsDetail { hideDetail() }
        hideDeleteConfirmation()
```

같은 메서드에서 `items`를 갱신하는 `switch` 바로 뒤(`if items.isEmpty { endItemEditing() }` 앞)에 추가:

```swift
        if keepsDetail, detailItemID != nil, detailItemIndex == nil { hideDetail() }
```

(d) `showDetail(at:)`의 `detailIndex = index`를 교체:

```swift
        detailItemID = items[index].id
```

(e) `showDetail(at:)` 바로 뒤(같은 internal 영역)에 추가:

```swift
    /// 상세 뷰의 붙여넣기(텍스트)·복사(이미지). 행 탭과 같은 델리게이트 경로다. 테스트에서 직접 호출할 수 있도록 internal로 둔다
    func pasteDetailItem() {
        guard let index = detailItemIndex else { return }
        // 붙여넣기(텍스트)는 이 직후 패널이 닫히지만, 복사(이미지)는 패널이 열린 채 유지된다.
        // 상세 뷰는 여기서 먼저 숨기고, 이미지 쪽은 이어지는 configure() 갱신으로 다시 숨김 상태가 반영된다
        hideDetail(animated: false)
        delegate?.clipboardPanel(self, didSelectItemAt: index)
    }

    /// 상세 뷰의 고정/해제. 테스트에서 직접 호출할 수 있도록 internal로 둔다
    func toggleDetailItemPin() {
        guard let index = detailItemIndex else { return }
        delegate?.clipboardPanel(self, didTogglePinAt: index)
    }
```

(f) `hideDetail(animated:)`의 `detailIndex = nil`을 `detailItemID = nil`로 바꾼다.

파일에 `detailIndex`가 남아 있지 않은지 `grep -n detailIndex Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`로 확인한다.

**실제 결과:** (a)~(f) 모두 반영했고 `grep -n detailIndex Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`는 매치 없음(종료 코드 1)으로 확인했다.

- [x] **Step 3: 테스트 통과 확인**

Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`
Expected: `TEST SUCCEEDED`, 새 테스트 4개 포함. 실제 개수를 기록한다.

**실제 결과(GREEN):** `** TEST SUCCEEDED **`. `ClipboardHistoryPanelViewTests` 27개(기존 23 + 신규 4: `test기본configure는_상세를닫음`, `test상세유지갱신후_붙여넣기는보던항목`, `test같은내용이다시기록되면_고정은그항목`, `test보던항목이사라지면_상세를닫음`) 모두 통과.

- [x] **Step 4: 상세 본문 선택 허용**

`ClipboardHistoryPanelView.swift`의 `ClipboardHistoryDetailView`에서:

(a) `textView` 초기화의 `textView.isSelectable = false`를 교체:

```swift
        // 길게 누르거나 두 번 탭해 일부를 선택하고 시스템 메뉴로 복사한다. 편집은 막는다
        textView.isSelectable = true
```

(b) `ClipboardHistoryDetailView` 클래스 본문의 `// MARK: - Lifecycle` 영역(`layoutSubviews()` 뒤)에 추가한다. `gestureRecognizerShouldBegin(_:)`은 `UIView`에 이미 있는 메서드라 extension이 아닌 클래스 본문에서 `override`로 둔다:

```swift
    /// 선택 영역이 있을 때의 탭은 선택 해제로 쓰이므로 링크를 열지 않는다
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === openURLTapGesture else { return super.gestureRecognizerShouldBegin(gestureRecognizer) }
        return textView.selectedRange.length == 0
    }
```

(c) 파일의 `ClipboardHistoryDetailView` UI Methods extension 뒤에 추가:

```swift
// MARK: - UIGestureRecognizerDelegate

extension ClipboardHistoryDetailView: UIGestureRecognizerDelegate {
    /// 본문 선택용 텍스트 뷰 제스처(길게 누르기·두 번 탭)를 막지 않는다
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return gestureRecognizer === openURLTapGesture
    }
}
```

(d) `setupUI()`에서 `textView.addGestureRecognizer(openURLTapGesture)` 앞에 `openURLTapGesture.delegate = self`를 넣는다. `update(text:isPinned:canPin:canOpenURL:)`에서 `textView.attributedText = ...` 다음 줄에 이전 선택이 남지 않도록 `textView.selectedRange = NSRange(location: 0, length: 0)`을 넣는다.

**실제 결과:** (a)~(d) 브리프 코드 그대로 적용했다.

- [x] **Step 5: 키보드가 pasteboard 변경을 받아 기록·목록 갱신**

`BaseKeyboardViewController.swift`에서:

(a) `viewDidLoad()`의 `clipboardImageDidRecord` 옵저버 등록 바로 뒤에 추가:

```swift
        // 상세 뷰에서 본문 일부를 복사하면 viewWillAppear 등 기존 동기화 시점이 오지 않으므로 여기서 기록한다
        NotificationCenter.default.addObserver(
            self, selector: #selector(pasteboardDidChange), name: UIPasteboard.changedNotification, object: nil
        )
```

(b) `hostDidBecomeActive()` 뒤에 추가:

```swift
    /// 패널이 열린 채 이 키보드 안에서 pasteboard가 바뀌면(상세 뷰 일부 복사) 기록에 반영하고, 보던 상세 뷰는 유지한다.
    /// 붙여넣기·이미지 복원은 쓴 직후 changeCount를 갱신하므로, 그 갱신이 끝난 다음 runloop에서 확인해 중복 기록하지 않는다
    @objc func pasteboardDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isClipboardPanelVisible, self.isClipboardHistoryAvailable,
                  let clipboardHistoryStore = self.clipboardHistoryStore else { return }
            self.synchronizeClipboardHistoryIfNeeded()
            guard clipboardHistoryStore.load() != self.clipboardHistoryPanelView.items else { return }
            self.reloadClipboardPanel(keepsDetail: true)
        }
    }
```

(c) `reloadClipboardPanel()`을 교체:

```swift
    /// `keepsDetail`은 `ClipboardHistoryPanelView.configure(state:keepsDetail:)`로 그대로 넘긴다
    func reloadClipboardPanel(keepsDetail: Bool = false) {
        guard hasFullAccess, let clipboardHistoryStore else {
            clipboardHistoryPanelView.configure(state: .fullAccessRequired)
            return
        }
        let items = clipboardHistoryStore.load()
        clipboardHistoryPanelView.configure(state: items.isEmpty ? .empty : .items(items), keepsDetail: keepsDetail)
    }
```

**실제 결과:** (a)~(c) 브리프 코드 그대로 적용했다.

- [x] **Step 6: 테스트·빌드·설치**

1. Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests -only-testing:SYKeyboardTests/ClipboardHistoryPasteboardSynchronizerTests -only-testing:SYKeyboardTests/ClipboardHistoryStoreTests`
   Expected: `TEST SUCCEEDED`. 실제 개수를 기록한다.
2. `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` scheme을 `-only-testing` 없이 빌드. Expected: 모두 `BUILD SUCCEEDED`.
3. SYKeyboard app scheme을 iOS 18.6 destination으로 빌드해 시뮬레이터 `82146144-24DE-4F91-B25D-23D147A91142`에 설치한다(앱 삭제 금지). `.xcscheme` `RemotePath` 변경은 되돌린다.

**실제 결과:**
1. `** TEST SUCCEEDED **`. 3개 suite 합계 57개 테스트 모두 통과(`ClipboardHistoryPanelViewTests` 27, `ClipboardHistoryStoreTests` 22, `ClipboardHistoryPasteboardSynchronizerTests` 8).
2. `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard` 세 scheme 모두 `** BUILD SUCCEEDED **`.
3. `SYKeyboard` scheme `** BUILD SUCCEEDED **`. 빌드 산출물 `~/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Build/Products/Debug-iphonesimulator/SYKeyboard.app`을 시뮬레이터 `82146144-24DE-4F91-B25D-23D147A91142`에 `xcrun simctl install`로 설치(삭제 없이 덮어 설치) 완료. 설치 전 해당 시뮬레이터가 Shutdown 상태라 `xcrun simctl boot`으로 부팅했다. `xcrun simctl terminate ... github.com-SNMac.SYKeyboard`는 "found nothing to terminate"(무시 대상). 빌드 후 `git status --short`에는 의도한 3개 파일만 남았고 `.xcscheme` 변경은 없었다(되돌릴 것 없음).

- [x] **Step 7: 수동 확인(사용자 조작 필요)**

클립보드 기록 설정 켜짐, 전체 접근 허용 상태에서 키보드 확장의 클립보드 기록 패널로 확인한다.
1. 텍스트 항목을 길게 눌러 상세 화면을 연 뒤, 본문을 길게 눌러 일부를 선택하고 메뉴에서 복사한다. 붙여넣기 권한 알림이 뜨지 않고 상세 화면이 그대로 유지된다.
2. 상세를 닫으면 복사한 일부 텍스트가 목록 맨 위에 있다.
3. 1의 상세에서 복사 후 바로 "붙여넣기"를 누르면 상세에서 보던 원래 항목 전체가 입력된다.
4. 1의 상세에서 복사 후 "고정"을 누르면 보던 원래 항목이 고정된다.
5. 본문 전체를 선택해 복사해도 상세가 유지되고 목록에 같은 항목이 중복으로 생기지 않는다.
6. 본문 전체가 URL인 항목: 탭하면 링크가 열리고, 길게 누르면 선택된다. 선택이 있는 상태에서 탭하면 선택만 해제되고 링크가 열리지 않는다.
7. 행 탭 붙여넣기 뒤 목록에 같은 항목이 중복으로 생기지 않는다(기존 동작 유지).
8. 이미지 항목 상세의 "복사"는 기존처럼 안내 토스트가 뜨고 목록이 중복되지 않는다.

확인하지 못한 항목은 체크하지 않고 이유를 적는다.

실행 결과(2026-09-15, 사용자 수행, iPhone 13 mini / iOS 18.6 시뮬레이터 `82146144-24DE-4F91-B25D-23D147A91142`): 1~8 모두 정상. 리뷰 후 추가한 9. 본문을 선택한 채 "닫기"·클립보드 버튼으로 닫아도 편집 메뉴·선택 핸들이 남지 않음 — 정상. 1에서 키보드 확장 안에 복사 메뉴가 뜨고 붙여넣기 권한 알림은 뜨지 않음을 함께 확인했다.

- [ ] **Step 8: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardTests/Presentation/ClipboardHistoryPanelViewTests.swift \
  docs/superpowers/plans/2026-09-15-issue-131-ngram-application-support.md
git commit -m "feat: #131 - 키보드 클립보드 상세 화면에서 본문 일부를 선택해 복사하고 기록에 바로 반영"
```

### Task 5: 키보드 앱 상세 시트에서 선택 밖을 탭하면 선택이 풀리게 하기

**배경:** Task 4 수동 확인 중 사용자가 발견했다. 키보드 앱(메인 앱) 클립보드 기록 관리의 상세 시트는 SwiftUI `Text(...).textSelection(.enabled)`라서 (1) 일부 선택 후 다른 곳을 탭해도 선택이 풀리지 않고 (2) URL 항목에서 일부 선택 중 URL을 탭하면 바로 브라우저로 이동한다. Apple 문서(Context7 `/websites/developer_apple_swiftui`) 기준 `textSelection`에는 선택 범위를 읽거나 해제하는 binding이 없어 SwiftUI 설정만으로는 고칠 수 없다.

**확정 규칙(2026-09-15 사용자 결정, 키보드 앱·키보드 확장 공통):**
- 선택이 있을 때 선택 밖을 탭하면 URL 글자·일반 텍스트·여백 모두 선택만 풀린다. 링크는 열리지 않는다(다시 탭하면 열린다).
- 선택이 없을 때 URL 항목의 글자 영역을 탭하면 링크를 연다.
- 선택 영역 안을 탭하면 `UITextView` 기본 동작을 따른다.
- 키보드 확장(`ClipboardHistoryDetailView`)은 Task 4에서 이미 이 규칙이다(수동 확인 6·9). 이 Task는 키보드 앱만 바꾼다.

**Files:**
- Modify: `SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift` (앱 타깃은 동기화 폴더라 pbxproj 수정 없음. 새 파일을 만들지 않고 같은 파일의 private 타입으로 둔다)

- [x] **Step 1: 원문 본문을 `UITextView`로 교체**

브리프의 (a)~(d) 코드를 그대로 적용했다(`ClipboardHistorySettingsView.swift`). `import UIKit`은 추가하지 않았다 —
같은 파일이 이미 `UIImage`를 import 없이 쓰고 있었고(예: 썸네일 로딩), 이번에 추가한 `UITextView`,
`UIViewRepresentable`, `NSAttributedString`, `NSUnderlineStyle`, `UIGestureRecognizerDelegate` 등도
`SYKeyboard` 앱 scheme 빌드(Step 2)에서 추가 import 없이 컴파일됨을 확인했다.

(a) `ClipboardHistoryDetailView`(SwiftUI, 이 파일의 private struct)에 환경값을 추가한다(`@Environment(\.dismiss)` 다음 줄):

```swift
    @Environment(\.openURL) private var openURL
```

(b) 더 이상 쓰지 않는 `linkStyledText` 계산 프로퍼티를 지운다.

(c) `body`의 텍스트 분기(`ScrollView { Text(linkStyledText) ... }`)를 교체:

```swift
                } else {
                    // SwiftUI Text의 선택은 코드로 해제할 수 없어 UITextView로 보여준다. 키보드 패널 상세와 같은 선택·링크 규칙이다
                    ClipboardHistoryDetailTextView(
                        text: text,
                        url: ClipboardHistoryPolicy.openableURL(in: text),
                        onOpenURL: { openURL($0) }
                    )
                }
```

(d) `// MARK: - Preview` 바로 앞에 추가:

```swift
// MARK: - Detail Text

/// 원문 본문. 편집 없이 선택·복사만 허용한다.
/// 선택이 있을 때 선택 밖을 탭하면 선택만 풀리고, 선택이 없을 때 본문 전체가 URL이면 글자 영역을 탭해 연다.
/// 키보드 패널 상세(`ClipboardHistoryPanelView`의 상세 뷰)와 같은 규칙이다
private struct ClipboardHistoryDetailTextView: UIViewRepresentable {
    let text: String
    let url: URL?
    let onOpenURL: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.delegate = context.coordinator
        textView.addGestureRecognizer(tapGesture)
        context.coordinator.textView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.url = url
        context.coordinator.onOpenURL = onOpenURL
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label
        ]
        if url != nil {
            // 텍스트 전체가 URL이면 일반 링크처럼 파란 밑줄로 그린다
            attributes[.foregroundColor] = UIColor.link
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        // SwiftUI가 다시 그릴 때마다 교체하면 선택이 풀리므로 내용이 바뀐 경우에만 넣는다
        guard textView.attributedText != attributedText else { return }
        textView.attributedText = attributedText
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var textView: UITextView?
        var url: URL?
        var onOpenURL: ((URL) -> Void)?

        /// 글자가 있는 영역을 탭했을 때만 연다. 빈 여백 탭은 무시한다
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let textView, let url else { return }
            let point = recognizer.location(in: textView)
            let inset = textView.textContainerInset
            let usedRect = textView.layoutManager.usedRect(for: textView.textContainer)
                .offsetBy(dx: inset.left, dy: inset.top)
            guard usedRect.contains(point) else { return }
            onOpenURL?(url)
        }

        /// 선택 영역이 있을 때의 탭은 선택 해제로 쓰이므로 링크를 열지 않는다
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return (textView?.selectedRange.length ?? 0) == 0
        }

        /// 본문 선택용 텍스트 뷰 제스처(길게 누르기·두 번 탭·선택 해제 탭)를 막지 않는다
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}
```

컴파일에 필요하면 파일 상단에 `import UIKit`을 추가한다(`SwiftUI`만으로 UIKit 타입이 보이면 추가하지 않는다).

- [x] **Step 2: 회귀 테스트와 빌드**

선택·탭 동작은 UIKit 런타임 동작이라 unit test로 고정하지 않는다. 기존 회귀만 확인한다.
1. Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPolicyTests -only-testing:SYKeyboardTests/ClipboardHistoryStoreTests`
   (Task 6 검증과 겹쳐 `ClipboardHistoryPanelViewTests`도 같은 실행에 포함). 결과: `TEST SUCCEEDED`,
   `ClipboardHistoryPolicyTests` 32개 · `ClipboardHistoryStoreTests` 22개 · `ClipboardHistoryPanelViewTests` 27개,
   총 81개 전부 통과(iPhone 13 mini, iOS 18.6).
2. SYKeyboard app scheme을 iOS 18.6 destination으로 빌드: `BUILD SUCCEEDED`. 빌드 산출물
   `~/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Build/Products/Debug-iphonesimulator/SYKeyboard.app`을
   시뮬레이터 `82146144-24DE-4F91-B25D-23D147A91142`에 `xcrun simctl install`로 설치(기존 앱 유지, 삭제 안 함).
   빌드 뒤 `git status --short`에 `.xcscheme` 변경 없음 — 되돌릴 대상 없었다.

- [x] **Step 3: 수동 확인(사용자 조작 필요)**

키보드 앱 → 클립보드 기록 관리에서 항목을 눌러 상세 시트를 연다.
1. 일반 텍스트: 길게 눌러 일부 선택 → 선택 밖의 다른 글자를 탭하면 선택이 풀린다. 여백을 탭해도 풀린다.
2. 선택 후 시스템 메뉴의 복사가 동작한다.
3. URL 항목: 선택이 없을 때 URL을 탭하면 브라우저가 열린다. 여백 탭은 아무 일도 없다.
4. URL 항목: 일부 선택 중 선택 밖 URL을 탭하면 선택만 풀리고 브라우저는 열리지 않는다. 이어서 다시 탭하면 열린다.
5. 긴 텍스트 스크롤, 다크 모드 글자 색, 글자 크기(Dynamic Type 변경 후 시트 다시 열기)가 자연스럽다.
6. "편집"·저장·취소, "공유", "복사", 고정 버튼, 이미지 항목 미리보기가 기존과 같다.

확인하지 못한 항목은 체크하지 않고 이유를 적는다.

실행 결과(2026-09-15, 사용자 수행, iPhone 13 mini / iOS 18.6 시뮬레이터 `82146144-24DE-4F91-B25D-23D147A91142`): 1~6 모두 정상. 2의 복사는 되지만 시트 뒤 목록에는 실시간으로 반영되지 않음(시트를 연 채 앱 안에서 복사한 경우의 동기화 경로가 없음. 수정 전 SwiftUI `Text` 선택 복사도 같은 경로라 이번 diff의 회귀는 아니며 범위 밖으로 기록).

- [ ] **Step 4: 커밋**

```bash
git add SYKeyboard/Presentation/KeyboardSettings/ClipboardHistorySettingsView.swift \
  docs/superpowers/plans/2026-09-15-issue-131-ngram-application-support.md
git commit -m "fix: #131 - 키보드 앱 클립보드 상세에서 선택 밖을 탭하면 선택이 풀리고 선택 중 URL 탭은 해제만 하도록 수정"
```

### Task 6: 편집 모드 삭제 애니메이션에서 행이 겹쳐 보이는 현상

**배경:** Task 3 수동 확인 7번에서 관찰했고, 2026-09-15 사용자 요청으로 #131에 추가했다. 편집 모드에서 항목을 삭제하면 지워지는 행이 위로 뭉개지며 체크 표시와 옆 행 글자가 겹쳐 보인다.

**조사 결과:**
- `26399d8b`(편집 모드 전환을 `UIView.animate` 안의 `setEditing(_:animated: false)`로 교체)를 되돌린 비교 빌드에서도 같은 현상이 재현돼 원인에서 제외했다.
- 셀(`makeCell`의 `cell.backgroundColor = .clear`)과 테이블(`tableView.backgroundColor = .clear`) 배경은 #54 첫 구현 `590fb7ce`부터 투명이다. `UITableViewDiffableDataSource`의 기본 행 애니메이션(`.automatic`)은 삭제되는 행 위로 아래 행이 밀려 올라오는데, 불투명 배경이면 가려질 겹침이 투명 배경에서는 그대로 보인다는 가설(사용자 제기)이 유력하다.
- 기존부터 있던 동작이다. 수정은 스와이프 삭제·고정 이동 등 같은 data source의 모든 행 애니메이션에 적용된다.

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift`

- [x] **Step 1: 가설 확인 빌드(사용자 조작 필요)**

코드 라인은 적용해 아래 반영했고, Task 5와 같은 `SYKeyboard` app scheme 빌드·설치(위 Step 2 기록)에 포함되어
시뮬레이터 `82146144-24DE-4F91-B25D-23D147A91142`에 이미 설치돼 있다. 겹침이 사라졌는지와 애니메이션이
자연스러운지에 대한 실제 화면 확인은 사용자 몫이라 이 Step은 체크하지 않는다.

`setupUI()`의 `tableView.dataSource = dataSource` 다음 줄에 아래를 넣고, SYKeyboard app scheme을 iOS 18.6 destination으로 빌드해 시뮬레이터 `82146144-24DE-4F91-B25D-23D147A91142`에 설치한다(앱 삭제 금지):

```swift
        // 셀·테이블 배경이 투명해 기본 애니메이션(.automatic)은 삭제되는 행과 밀려 올라오는 행이 겹쳐 보인다
        dataSource.defaultRowAnimation = .fade
```

사용자가 편집 모드 다중 삭제, 스와이프 삭제, 스와이프 고정/해제(행 이동), 고정 항목 포함 삭제 확인 후 삭제를 해 보고 겹침이 사라졌는지와 애니메이션이 어색하지 않은지 확인한다.
- 겹침이 사라지면 Step 2로 간다.
- 그대로면 이 줄을 되돌리고 멈춰 사용자에게 보고한다(원인 재조사).

실행 결과(2026-09-15, 사용자 수행, 같은 시뮬레이터): 편집 모드 다중 삭제의 겹침이 사라짐. 스와이프 삭제·스와이프 고정/해제 이동·고정 항목 포함 확인 후 삭제 애니메이션 모두 어색하지 않음.

- [x] **Step 2: 회귀 테스트와 빌드**

행 애니메이션 종류는 시각 속성이라 unit test로 고정하지 않는다(CLAUDE.md 테스트 경계). 기존 동작 회귀만 확인한다.

1. Run: `-only-testing:SYKeyboardTests/ClipboardHistoryPanelViewTests`(Task 5 Step 2와 같은 실행에 포함). 결과:
   `TEST SUCCEEDED`, `ClipboardHistoryPanelViewTests` 27개 전부 통과(iPhone 13 mini, iOS 18.6).
2. `HangeulKeyboard`, `EnglishKeyboard`, `HangeulEnglishKeyboard`를 `-only-testing` 없이 각각 빌드: 모두
   `BUILD SUCCEEDED`(iPhone 13 mini, iOS 18.6). 빌드 뒤 `git status --short`에 `.xcscheme` 변경 없음 — 되돌릴 대상 없었다.

- [ ] **Step 3: 커밋**

```bash
git add Modules/SYKeyboardCore/Presentation/View/ClipboardHistoryPanelView.swift \
  docs/superpowers/plans/2026-09-15-issue-131-ngram-application-support.md
git commit -m "fix: #131 - 클립보드 기록 행 삭제·이동 애니메이션에서 투명 배경 행이 겹쳐 보이는 현상 수정"
```

### Task 7: 전체 검증과 결과 기록

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

# 한·영 통합 키보드 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 한글·영문 입력 동작을 어댑터로 재사용하면서 document language hint와 마지막 사용 mode에 따라 시작하고 내부 한/영 버튼으로 전환되는 통합 keyboard extension을 완성한다.

**Architecture:** `HangeulEnglishKeyboardViewController`는 `BaseKeyboardViewController`를 상속하고 `HangeulKeyboardInputAdapter`와 `EnglishKeyboardInputAdapter`를 조합한다. `BaseKeyboardViewController`는 안정적인 전체 primary view 목록과 현재 active primary view를 분리하고, 공통 `SuggestionController`는 `ko-KR`/`en-US` 엔진을 지연 전환한다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26+, iOS 16+, local Swift packages (`SYKeyboardCore`, `HangeulKeyboardCore`, `EnglishKeyboardCore`, `SYKeyboardAssets`)

## Global Constraints

- 기존 한글·영문 전용 extension의 입력 흐름, 버튼 event timing과 gesture 동작을 유지한다.
- `selectionWillChange(_:)`/`selectionDidChange(_:)` 호출에 의존하지 않고 `textWillChange(_:)`/`textDidChange(_:)`에서 focus와 외부 문맥을 동기화한다.
- 같은 TextField의 수동 언어 선택을 이후 callback이 덮어쓰지 않는다.
- 시작 mode 우선순위는 document `primaryLanguage`의 `ko`/`en` hint → 마지막 사용 mode → 한글이다.
- 한글에서 영어로 전환할 때 문서에 이미 반영된 글자는 유지하고 내부 composition/Processor/undo 상태만 확정·초기화한다.
- 자동완성 후보의 가로 스크롤과 scroll edge effect를 재도입하지 않는다.
- `SuggestionButtonLabelColor`는 변경하지 않고 `SYKeyboardAssets`에 별도 `LanguageSwitchMutedLabelColor`를 만든다.
- `LanguageSwitchButton`은 `SecondaryButton`이며 문자열 `한/영`의 active/muted 구간만 갱신한다.
- globe 버튼은 iOS 시스템 keyboard 전환, 한/영 버튼은 통합 extension 내부 mode 전환만 담당한다.
- Firebase, AdMob, bundle identifier, provisioning과 기존 entitlement 값은 변경하지 않는다.
- 새 production 동작은 실패 테스트를 먼저 확인한 뒤 최소 구현한다.
- helper가 production 로직을 복제하지 않으며, 가능한 테스트는 실제 production 진입점을 호출한다.
- exact RGB, font, corner radius, effect subclass와 private subview 계층을 unit test로 고정하지 않는다.
- 각 Task는 코드·테스트·이 계획 문서의 실제 결과를 함께 갱신한 직후 하나의 커밋으로 남긴다.
- 기본 자동 검증 destination은 `iPhone 13 mini / iOS 16.0`이다. 다른 runtime을 사용하면 실제 기기명과 OS를 Result에 기록한다.

## Completed Baseline

- `5999cae3`: `HangeulEnglishKeyboard` target, embed, xcconfig, entitlement, `PrimaryLanguage = mul`, 템플릿 ViewController
- `18e21fa9`: 현재 `BaseKeyboardViewController` lifecycle에 맞춘 공통 변경
- 2026-08-12 iPhone 13 mini / iOS 16.0 baseline:
  - `SYKeyboard` Debug build 성공
  - 앱 산출물에 `HangeulEnglishKeyboard.appex` 포함
  - `SYKeyboardTests` 383개 통과, 실패·스킵 0개

위 항목은 다시 구현하지 않는다. 최종 Task에서 target/plist/embed를 회귀 검증한다.

## File Map

### Create

- `Modules/SYKeyboardCore/Presentation/Utils/Enums/HangeulEnglishLanguageMode.swift`: mode와 locale 식별자
- `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardLanguageModePolicy.swift`: document hint와 저장값의 순수 판정
- `Modules/SYKeyboardCore/Presentation/Utils/Coordinators/HangeulEnglishKeyboardModeCoordinator.swift`: focus identity와 active mode
- `Modules/HangeulKeyboardCore/Presentation/Input/HangeulKeyboardInputAdapter.swift`: 한글 composition/Processor/view 상태
- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/Input/EnglishKeyboardInputAdapter.swift`: 영어 Shift/caps/view 상태
- `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/LanguageSwitchButton.swift`: attributed `한/영` secondary button
- `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/SYKeyboardAssets.xcassets/Colors/KeyboardButton/Secondary/LanguageSwitchMutedLabelColor.colorset/Contents.json`: 전환 버튼 muted 색상
- `SYKeyboardTests/Utils/KeyboardLanguageModePolicyTests.swift`
- `SYKeyboardTests/Utils/KeyboardPrimaryViewCollectionTests.swift`
- `SYKeyboardTests/Domain/HangeulKeyboardInputAdapterTests.swift`
- `SYKeyboardTests/Domain/EnglishKeyboardInputAdapterTests.swift`
- `SYKeyboardTests/Utils/LanguageSwitchButtonTests.swift`
- `SYKeyboardTests/Utils/KeyboardLanguageSegmentTrackerTests.swift`
- `SYKeyboardTests/Utils/HangeulEnglishKeyboardModeCoordinatorTests.swift`
- `SYKeyboard.xcodeproj/xcshareddata/xcschemes/HangeulEnglishKeyboard.xcscheme`: 통합 extension shared scheme

### Modify

- `Modules/SYKeyboardCore/Storage/{UserDefaultsKeys,DefaultValues,UserDefaultsManager}.swift`
- `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`
- `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
- `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
- `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/PrimaryKeyboardRepresentable.swift`
- `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/{StandardKeyboardView,FourByFourKeyboardView,FourByFourPlusKeyboardView}.swift`
- `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift`
- `Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift`
- `Modules/HangeulKeyboardCore/Presentation/View/Protocols/HangeulKeyboardLayoutProvider.swift`
- `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
- `Modules/HangeulKeyboardCore/Presentation/View/{NaratgeulKeyboardView,CheonjiinKeyboardView,DubeolsikKeyboardView}.swift`
- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift`
- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift`
- `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/Protocols/EnglishKeyboardLayoutProvider.swift`
- `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift`
- `SYKeyboardAssets/Sources/SYKeyboardAssets/Utils/Extensions/UIColor+Extension.swift`
- `SYKeyboard.xcodeproj/project.pbxproj`
- `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`
- `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`
- 이 계획 문서

---

### Task 1: 언어 mode, 시작 정책과 마지막 mode 저장

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Enums/HangeulEnglishLanguageMode.swift`
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardLanguageModePolicy.swift`
- Create: `SYKeyboardTests/Utils/KeyboardLanguageModePolicyTests.swift`
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift`
- Modify: `Modules/SYKeyboardCore/Storage/DefaultValues.swift`
- Modify: `Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift`
- Modify: `SYKeyboardTests/Storage/UserDefaultsContractTests.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Modify: `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md`

**Interfaces:**
- Produces: `public enum HangeulEnglishLanguageMode: String, Codable, Equatable`
- Produces: `public var languageIdentifier: String`
- Produces: `public static func initialMode(documentPrimaryLanguage:lastMode:) -> HangeulEnglishLanguageMode`
- Produces: `UserDefaultsManager.lastHangeulEnglishLanguageMode`
- Consumes: BCP 47 language string from `UITextInputMode.primaryLanguage`

- [x] **Step 1: mode 판정과 저장 계약 실패 테스트 작성**

```swift
@Suite("한영 통합 키보드 시작 언어 정책")
struct KeyboardLanguageModePolicyTests {
    @Test("document 언어가 저장값보다 우선")
    func testDocumentLanguageOverridesLastMode() {
        #expect(KeyboardLanguageModePolicy.initialMode(
            documentPrimaryLanguage: "ko-KR",
            lastMode: .english
        ) == .hangeul)
        #expect(KeyboardLanguageModePolicy.initialMode(
            documentPrimaryLanguage: "en-US",
            lastMode: .hangeul
        ) == .english)
    }

    @Test("nil mul 기타 언어는 마지막 mode로 fallback")
    func testUnsupportedDocumentLanguageUsesLastMode() {
        for language in [nil, "", "mul", "ja-JP"] as [String?] {
            #expect(KeyboardLanguageModePolicy.initialMode(
                documentPrimaryLanguage: language,
                lastMode: .english
            ) == .english)
        }
    }

    @Test("hint와 저장값이 없으면 한글")
    func testDefaultModeIsHangeul() {
        #expect(KeyboardLanguageModePolicy.initialMode(
            documentPrimaryLanguage: nil,
            lastMode: nil
        ) == .hangeul)
    }
}
```

`UserDefaultsContractTests`에는 키 문자열, `.hangeul` 기본값, raw value round-trip과 손상 raw value fallback을 추가한다. 테스트는 shared storage 원래 값을 저장하고 `defer`에서 복구한다.

- [x] **Step 2: 기능 부재 RED 확인**

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardLanguageModePolicyTests \
  -only-testing:SYKeyboardTests/UserDefaultsContractTests
```

Expected: `HangeulEnglishLanguageMode`, `KeyboardLanguageModePolicy` 또는 새 storage symbol을 찾지 못해 test build가 실패한다. Simulator/permission 실패는 RED로 인정하지 않는다.

- [x] **Step 3: mode와 순수 정책 최소 구현**

```swift
public enum HangeulEnglishLanguageMode: String, Codable, Equatable {
    case hangeul
    case english

    public var languageIdentifier: String {
        switch self {
        case .hangeul: return "ko-KR"
        case .english: return "en-US"
        }
    }
}

public enum KeyboardLanguageModePolicy {
    public static func initialMode(
        documentPrimaryLanguage: String?,
        lastMode: HangeulEnglishLanguageMode?
    ) -> HangeulEnglishLanguageMode {
        let language = documentPrimaryLanguage?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if language == "ko" || language?.hasPrefix("ko-") == true { return .hangeul }
        if language == "en" || language?.hasPrefix("en-") == true { return .english }
        return lastMode ?? .hangeul
    }
}
```

Storage contract:

```swift
public static let lastHangeulEnglishLanguageMode = "lastHangeulEnglishLanguageMode"
public static let lastHangeulEnglishLanguageMode: HangeulEnglishLanguageMode = .hangeul

@UserDefaultsRawRepresentableWrapper(
    key: UserDefaultsKeys.lastHangeulEnglishLanguageMode,
    defaultValue: DefaultValues.lastHangeulEnglishLanguageMode
)
public var lastHangeulEnglishLanguageMode: HangeulEnglishLanguageMode
```

새 SYKeyboardCore 파일은 synchronized group membership exception의 기존 Core 파일과 같은 target 범위에 추가한다.

- [x] **Step 4: GREEN 확인**

Step 2 명령을 다시 실행한다. Expected: 두 suite 전체 PASS.

- [x] **Step 5: 결과 기록과 커밋**

이 Task 아래 `**Result:**`를 추가해 RED/GREEN exit code, 고유 테스트 개수, destination과 `.xcresult` 경로를 기록한다.

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Enums/HangeulEnglishLanguageMode.swift \
  Modules/SYKeyboardCore/Presentation/Utils/Policies/KeyboardLanguageModePolicy.swift \
  Modules/SYKeyboardCore/Storage/UserDefaultsKeys.swift \
  Modules/SYKeyboardCore/Storage/DefaultValues.swift \
  Modules/SYKeyboardCore/Storage/UserDefaultsManager.swift \
  SYKeyboardTests/Utils/KeyboardLanguageModePolicyTests.swift \
  SYKeyboardTests/Storage/UserDefaultsContractTests.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md
git commit -m "feat: #46 - 통합 키보드 시작 언어 정책 추가"
```

**Result:**

- RED: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/KeyboardLanguageModePolicyTests -only-testing:SYKeyboardTests/UserDefaultsContractTests`를 권한 있는 환경에서 실행해 exit 65를 확인했다. `KeyboardLanguageModePolicy`와 `HangeulEnglishLanguageMode`를 찾지 못해 test build가 실패했으며, 결과는 `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.13_00-29-32-+0900.xcresult`에 기록되었다. 기본 sandbox 실행은 Simulator/SwiftPM cache 권한 오류(exit 74)로 컴파일 전 중단되어 RED 근거로 사용하지 않았다.
- GREEN: 같은 명령을 권한 있는 환경에서 다시 실행해 exit 0, 12/12 passed, failed 0, skipped 0을 확인했다. destination은 iPhone 13 mini / iOS 16.0 (arm64)이며 결과는 `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.13_00-30-55-+0900.xcresult`에 기록되었다.

### Task 2: 자동완성 언어 안전 전환

**Files:**
- Modify: `Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift`
- Modify: `Modules/SYKeyboardCore/Domain/SuggestionController.swift`
- Modify: `SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift`
- Modify: `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md`

**Interfaces:**
- Produces: `func updateLanguage(to language: String)` on `SuggestionService`
- Produces: mutable `SuggestionController.language`
- Preserves: `lexiconEngine` instance across language changes
- Guards: async n-gram callback with captured `engineGeneration` and language

- [x] **Step 1: language 전환 실패 테스트 추가**

`CountingSuggestionEngineFactory`가 생성 요청 language, n-gram provider별 `saveCount`와 생성된 provider 배열을 기록하게 한다. 다음 production 진입점 테스트를 추가한다.

```swift
@Test("language 전환은 이전 ngram을 저장하고 새 엔진을 지연 생성")
func testLanguageChangeSavesOldEngineAndDefersNewCreation() {
    let factory = CountingSuggestionEngineFactory()
    let controller = SuggestionController(language: "ko-KR", engineFactory: factory.makeFactory())
    controller.isPredictiveTextEnabled = true
    controller.preparePredictiveEnginesIfNeeded()
    let koreanEngine = factory.lastNGramProvider

    controller.updateLanguage(to: "en-US")

    #expect(koreanEngine?.saveCount == 1)
    #expect(factory.nGramLanguages == ["ko-KR"])
    controller.preparePredictiveEnginesIfNeeded()
    #expect(factory.nGramLanguages == ["ko-KR", "en-US"])
    #expect(factory.textCheckerLanguages == ["ko-KR", "en-US"])
}

@Test("이전 language load callback은 새 후보를 갱신하지 않음")
func testStaleLanguageLoadCallbackIsIgnored() {
    let factory = CountingSuggestionEngineFactory()
    let delegate = RecordingSuggestionControllerDelegate()
    let controller = SuggestionController(language: "ko-KR", engineFactory: factory.makeFactory())
    controller.delegate = delegate
    controller.isPredictiveTextEnabled = true
    controller.updateSuggestions(for: "", selectedText: nil, mathExpressionText: "")
    let koreanEngine = factory.lastNGramProvider

    controller.updateLanguage(to: "en-US")
    let updateCount = delegate.updates.count
    koreanEngine?.completeLoad(suggestions: ["오래된 후보"])

    #expect(delegate.updates.count == updateCount)
}
```

- [x] **Step 2: API 부재 RED 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests
```

Expected: `updateLanguage(to:)` 또는 test spy 필드 부재로 test build 실패.

- [x] **Step 3: language 전환 구현**

```swift
private var language: String
private var engineGeneration = 0

func updateLanguage(to language: String) {
    guard self.language != language else { return }
    nGramEngine?.saveToDisk()
    engineGeneration += 1
    self.language = language
    textCheckerEngine = nil
    nGramEngine = nil
    lastSuggestionBaseText = nil
    lastMathExpressionText = nil
    lastSuggestionOrigin = nil
    currentMathCompletion = nil
    currentMathSuggestionOrigin = nil
    clearSuggestions()
}
```

`preparePredictiveEnginesIfNeeded()`에서 새 n-gram을 만들 때 현재 generation과 language를 capture한다.

```swift
let generation = engineGeneration
let engineLanguage = language
let engine = engineFactory.makeNGramEngine(engineLanguage)
engine.onLoadCompleted = { [weak self] in
    guard let self,
          self.engineGeneration == generation,
          self.language == engineLanguage else { return }
    self.refreshSuggestionsAfterNGramLoadIfNeeded()
}
```

`lexiconEngine`과 `isLoadingLexicon`은 language 전환에서 해제하지 않는다. `SuggestionService` test double이 있으면 동일 API를 no-op이 아니라 호출 기록 방식으로 구현한다.

- [x] **Step 4: GREEN과 기존 준비 회귀 확인**

Step 2 명령 실행. Expected: 기존 지연 준비 테스트를 포함해 suite 전체 PASS.

- [x] **Step 5: 결과 기록과 커밋**

```sh
git add Modules/SYKeyboardCore/Domain/Protocols/SuggestionService.swift \
  Modules/SYKeyboardCore/Domain/SuggestionController.swift \
  SYKeyboardTests/Domain/SuggestionControllerPreparationTests.swift \
  docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md
git commit -m "feat: #46 - 자동완성 언어 전환 지원"
```

**Result:**

- RED: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' -only-testing:SYKeyboardTests/SuggestionControllerPreparationTests`를 권한 있는 환경에서 실행해 exit 65를 확인했다. 새 테스트가 호출하는 `SuggestionController.updateLanguage(to:)`가 없어 test build가 실패했으며, 결과는 `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.13_00-38-13-+0900.xcresult`에 기록되었다. 기본 sandbox 실행은 Simulator/SwiftPM cache 권한 오류(exit 74)로 컴파일 전 중단되어 RED 근거로 사용하지 않았다.
- GREEN: 같은 명령을 권한 있는 환경에서 다시 실행해 exit 0, 고유 9/9 passed, failed 0, skipped 0을 확인했다. destination은 iPhone 13 mini / iOS 16.0 (arm64)이며 결과는 `/Users/macmillan/Library/Developer/Xcode/DerivedData/SYKeyboard-hgprdtyustcuukabeovkjzrtclhy/Logs/Test/Test-SYKeyboard-2026.08.13_00-38-55-+0900.xcresult`에 기록되었다.

### Task 3: 다중 primary view 공통 기반

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Create: `SYKeyboardTests/Utils/KeyboardPrimaryViewCollectionTests.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Modify: `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md`

**Interfaces:**
- Produces: `open var primaryKeyboardViews: [PrimaryKeyboardRepresentable] { [primaryKeyboardView] }`
- Produces: `open var hangeulSwitchGestureKeyboardView: SwitchGestureHandling`
- Produces: `open var englishSwitchGestureKeyboardView: SwitchGestureHandling`
- Produces: `open func textInputDidChange(_ textInput: (any UITextInput)?)`
- Changes: `KeyboardView.loadFromNib(primaryKeyboardViews:)`
- Preserves: single-primary subclasses without override changes

- [ ] **Step 1: 다중 view container 실패 테스트 작성**

테스트 파일에 `StandardKeyboardView`를 상속한 `TestPrimaryKeyboardView` 두 개를 만들고 production `KeyboardView.loadFromNib(primaryKeyboardViews:)`를 호출한다. `KeyboardView`에는 `@testable`에서 설치 결과를 읽을 수 있는 `private(set) var primaryKeyboardViews`를 둔다.

```swift
@MainActor
@Test("KeyboardView는 전달된 primary view를 모두 같은 container에 유지")
func testKeyboardViewKeepsAllPrimaryViews() {
    let first = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let second = TestPrimaryKeyboardView(keyboard: .qwerty)
    let view = KeyboardView.loadFromNib(primaryKeyboardViews: [first, second])

    #expect(view.primaryKeyboardViews.count == 2)
    #expect(view.primaryKeyboardViews[0] === first)
    #expect(view.primaryKeyboardViews[1] === second)
    #expect(first.superview === second.superview)
    #expect(first.translatesAutoresizingMaskIntoConstraints == false)
    #expect(second.translatesAutoresizingMaskIntoConstraints == false)
}
```

`TestPrimaryKeyboardView`는 `keyboard`, 3행 일반/Shift `primaryKeyList`, 같은 shape의 빈 `secondaryKeyList`만 override하고 `PrimaryKeyboardRepresentable`을 채택한다.

- [ ] **Step 2: 단일 인자 API 때문에 RED 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPrimaryViewCollectionTests
```

Expected: `loadFromNib(primaryKeyboardViews:)`를 찾을 수 없어 test build 실패.

- [ ] **Step 3: stable list와 active view 분리 구현**

`BaseKeyboardViewController` 기본 API:

```swift
open var primaryKeyboardView: PrimaryKeyboardRepresentable {
    fatalError("프로퍼티가 오버라이딩 되지 않았습니다.")
}

open var primaryKeyboardViews: [PrimaryKeyboardRepresentable] {
    return [primaryKeyboardView]
}

open var hangeulSwitchGestureKeyboardView: SwitchGestureHandling {
    return primaryKeyboardView
}

open var englishSwitchGestureKeyboardView: SwitchGestureHandling {
    return primaryKeyboardView
}

open func textInputDidChange(_ textInput: (any UITextInput)?) {}
```

- `KeyboardView`는 `private(set) var primaryKeyboardViews`에 전달 순서대로 저장해 hierarchy와 edge constraints를 모두 적용한다.
- `allKeyboardButtonList`, primary/numeric text-interactable 목록, return button 목록, next keyboard 설정과 primary `SwitchButton` action은 전체 목록을 사용한다.
- primary `SwitchButton` action은 action sender와 동일한 view의 button인지 확인한 뒤 `.symbol`로 전환한다.
- `SwitchGestureController`에는 두 overridable gesture view를 전달한다.
- `updateShowingKeyboard()`는 모든 primary view를 숨긴 뒤 `primaryKeyboardView`만 `currentKeyboard == primaryKeyboardView.keyboard`일 때 표시한다.
- `textWillChange` 시작에서 이전/새 `ObjectIdentifier?`를 비교하고 식별자가 실제로 바뀐 경우 한 번만 `textInputDidChange(_:)`를 호출한다. `nil`이면 현재 mode를 강제 변경하지 않는다.
- setup에서 action은 한 번만 등록하며 mode 전환 시 `setupUI()`를 다시 호출하지 않는다.

- [ ] **Step 4: 다중 view와 기존 공통 정책 GREEN 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardPrimaryViewCollectionTests \
  -only-testing:SYKeyboardTests/SwitchGestureControllerTests \
  -only-testing:SYKeyboardTests/KeyboardTextInteractionPolicyTests
```

Expected: 모든 지정 테스트 PASS, Auto Layout constraint warning 없음.

- [ ] **Step 5: 기존 전용 extension compile 회귀 확인**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 두 build exit 0.

- [ ] **Step 6: 결과 기록과 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/View/KeyboardView.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardTests/Utils/KeyboardPrimaryViewCollectionTests.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md
git commit -m "refactor: #46 - 다중 주 키보드 공통 기반 추가"
```

### Task 4: 한글 입력 어댑터 추출

**Files:**
- Create: `Modules/HangeulKeyboardCore/Presentation/Input/HangeulKeyboardInputAdapter.swift`
- Modify: `Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/View/Protocols/HangeulKeyboardLayoutProvider.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/View/NaratgeulKeyboardView.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/View/CheonjiinKeyboardView.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/View/DubeolsikKeyboardView.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift`
- Create: `SYKeyboardTests/Domain/HangeulKeyboardInputAdapterTests.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Modify: `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md`

**Interfaces:**
- Produces: `public final class HangeulKeyboardInputAdapter`
- Produces: `public var primaryKeyboardViews: [PrimaryKeyboardRepresentable]`
- Produces: `public var primaryKeyboardView: PrimaryKeyboardRepresentable`
- Produces: public transition methods returning `HangeulCompositionTransition`
- Produces: `public func finishForLanguageChange()`
- Preserves: `HangeulKeyboardCoreViewController`의 기존 override 결과

- [ ] **Step 1: 어댑터 production 진입점 실패 테스트 작성**

```swift
@Suite("한글 입력 어댑터")
struct HangeulKeyboardInputAdapterTests {
    @Test("입력과 삭제는 기존 composition transition을 반환")
    func testInputAndDeleteTransitions() {
        let adapter = HangeulKeyboardInputAdapter(selectedKeyboard: .dubeolsik)
        let input = adapter.input("ㄱ")
        let delete = adapter.delete()

        #expect(input.proxyEdits == [.insert("ㄱ")])
        #expect(delete.proxyEdits == [.replace(deleteCount: 1, insertText: "")])
    }

    @Test("언어 전환 종료는 문서 edit 없이 조합 상태를 초기화")
    func testFinishForLanguageChangeKeepsDocumentText() {
        let adapter = HangeulKeyboardInputAdapter(selectedKeyboard: .dubeolsik)
        _ = adapter.input("ㄱ")

        adapter.finishForLanguageChange()

        #expect(adapter.shouldDeferUndoRedoCommit == false)
        #expect(adapter.isCompositionOngoing == false)
    }
}
```

기존 `HangeulCompositionStateTests`의 조합/삭제 기대값은 그대로 유지한다.

- [ ] **Step 2: 어댑터 부재 RED 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulKeyboardInputAdapterTests \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests
```

Expected: `HangeulKeyboardInputAdapter` 부재로 test build 실패.

- [ ] **Step 3: transition 공개 범위와 어댑터 최소 구현**

통합 extension이 edit를 Base wrapper로 적용할 수 있게 기존 이름을 유지하며 필요한 멤버만 public으로 연다.

```swift
public enum HangeulProxyEdit: Equatable {
    case none
    case insert(String)
    case delete(count: Int)
    case replace(deleteCount: Int, insertText: String)
}

public struct HangeulCompositionTransition: Equatable {
    public let proxyEdits: [HangeulProxyEdit]
    public var proxyEdit: HangeulProxyEdit {
        return proxyEdits.last ?? .none
    }

    public init(proxyEdit: HangeulProxyEdit) {
        proxyEdits = [proxyEdit]
    }

    public init(proxyEdits: [HangeulProxyEdit]) {
        self.proxyEdits = proxyEdits
    }

    public func appending(
        _ transition: HangeulCompositionTransition?
    ) -> HangeulCompositionTransition {
        guard let transition else { return self }
        return HangeulCompositionTransition(
            proxyEdits: proxyEdits + transition.proxyEdits
        )
    }
}

public struct HangeulDeletePanResult: Equatable {
    public let character: Character
    public let shouldRestore: Bool
    public let transition: HangeulCompositionTransition
}
```

어댑터 핵심 API:

```swift
public final class HangeulKeyboardInputAdapter {
    public init(
        selectedKeyboard: HangeulKeyboardType,
        showsLanguageSwitchButton: Bool = false
    )
    public var primaryKeyboardViews: [PrimaryKeyboardRepresentable] { get }
    public var primaryKeyboardView: PrimaryKeyboardRepresentable { get }
    public var shouldDeferUndoRedoCommit: Bool { get }
    public var isCompositionOngoing: Bool { get }
    public var hasRepeatableInput: Bool { get }

    public func input(_ text: String) -> HangeulCompositionTransition
    public func repeatInput() -> HangeulCompositionTransition
    public func space() -> HangeulCompositionTransition
    public func delete() -> HangeulCompositionTransition
    public func repeatDelete() -> HangeulCompositionTransition
    public func beginDeleteTouchDown()
    public func endDeleteTouchDown()
    public func cancelDeleteTouchDown()
    public func finishRepeatDelete() -> HangeulCompositionTransition
    public func beginDeletePan() -> HangeulDeletePanResult?
    public func restoreDeletePan(_ character: Character) -> HangeulCompositionTransition
    public func finishDeletePan()
    public func clearForExternalTextChange()
    public func finishForLanguageChange()
    public func updateLayout(for keyboardType: UIKeyboardType?)
    public func updateSpaceButtonImage()
    public func resetShiftState()
}
```

`finishForLanguageChange()`는 `compositionState.clearAllBuffers()`와 현재 Processor `reset한글조합()`만 실행한다. 문서를 delete/reinsert하지 않는다. `HangeulDeletePanResult`도 통합 controller가 기존 delete-pan 반환 계약을 유지하는 데 필요한 세 property만 public으로 연다.

Concrete 한글 view와 `HangeulKeyboardLayoutProvider`는 adapter가 public `PrimaryKeyboardRepresentable`로 제공할 수 있는 최소 initializer/access만 공개한다.

- [ ] **Step 4: 기존 한글 controller를 어댑터 routing으로 전환**

- 기존 `compositionState`, 세 Processor, 세 view 저장 property를 adapter 하나로 교체한다.
- 각 override는 adapter의 production method를 호출하고 기존 `applyCompositionTransition(_:)`로 edit를 적용한다.
- `shouldDeferUndoRedoCommit`, space image, shift reset, repeat/delete pan hook의 기존 순서와 `super` 호출 위치를 유지한다.
- 동작 변경 없이 controller가 adapter를 실제 사용하도록 한다. adapter만 테스트하고 controller가 과거 private state를 계속 사용하게 두지 않는다.

- [ ] **Step 5: 관련 한글 전체 GREEN 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulKeyboardInputAdapterTests \
  -only-testing:SYKeyboardTests/HangeulCompositionStateTests \
  -only-testing:SYKeyboardTests/NaratgeulProcessorTests \
  -only-testing:SYKeyboardTests/CheonjiinProcessorTests \
  -only-testing:SYKeyboardTests/DubeolsikProcessorTests \
  -only-testing:SYKeyboardTests/HangeulAutomataTests
```

Expected: 지정 suite 모두 PASS. Processor 반환값과 composition state 기대값이 extraction 전과 동일.

- [ ] **Step 6: 한글 extension build**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: exit 0.

- [ ] **Step 7: 결과 기록과 커밋**

```sh
git add Modules/HangeulKeyboardCore/Domain/HangeulCompositionState.swift \
  Modules/HangeulKeyboardCore/Presentation/Input/HangeulKeyboardInputAdapter.swift \
  Modules/HangeulKeyboardCore/Presentation/View/Protocols/HangeulKeyboardLayoutProvider.swift \
  Modules/HangeulKeyboardCore/Presentation/View/NaratgeulKeyboardView.swift \
  Modules/HangeulKeyboardCore/Presentation/View/CheonjiinKeyboardView.swift \
  Modules/HangeulKeyboardCore/Presentation/View/DubeolsikKeyboardView.swift \
  Modules/HangeulKeyboardCore/Presentation/ViewController/HangeulKeyboardCoreViewController.swift \
  SYKeyboardTests/Domain/HangeulKeyboardInputAdapterTests.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md
git commit -m "refactor: #46 - 한글 입력 상태 어댑터 분리"
```

### Task 5: 영어 입력 어댑터 추출

**Files:**
- Create: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/Input/EnglishKeyboardInputAdapter.swift`
- Modify: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift`
- Modify: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/Protocols/EnglishKeyboardLayoutProvider.swift`
- Modify: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift`
- Create: `SYKeyboardTests/Domain/EnglishKeyboardInputAdapterTests.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Modify: `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md`

**Interfaces:**
- Produces: `public final class EnglishKeyboardInputAdapter`
- Produces: `public var primaryKeyboardView: PrimaryKeyboardRepresentable`
- Produces: Shift/caps 입력·reset·autocapitalization API
- Preserves: English controller의 Smart Punctuation과 auto-capitalization 결과

- [ ] **Step 1: Shift/caps 어댑터 실패 테스트 작성**

```swift
@Suite("영어 입력 어댑터")
struct EnglishKeyboardInputAdapterTests {
    @Test("대문자 입력 후 임시 Shift는 해제")
    func testRecordedUppercaseInputResetsTemporaryShift() {
        let adapter = EnglishKeyboardInputAdapter()
        adapter.primaryKeyboardView.updateShiftButton(to: true)
        adapter.recordInsertedText("A")
        adapter.updateShiftAfterInput(isShiftButtonPressed: false)
        #expect(adapter.isShifted == false)
    }

    @Test("언어 전환 종료는 Shift와 caps를 초기화")
    func testFinishForLanguageChangeResetsShiftAndCaps() {
        let adapter = EnglishKeyboardInputAdapter()
        adapter.primaryKeyboardView.updateShiftButton(to: true)
        adapter.finishForLanguageChange()
        #expect(adapter.isShifted == false)
        #expect(adapter.isCapsLocked == false)
    }

    @Test("문장 시작 자동 대문자 정책을 실제 view에 반영")
    func testAutocapitalizationUpdatesProductionView() {
        let adapter = EnglishKeyboardInputAdapter()
        adapter.updateAutocapitalization(
            type: .sentences,
            documentContextBeforeInput: "Hello. ",
            isEnabled: true,
            isShiftButtonPressed: false
        )
        #expect(adapter.isShifted)
    }
}
```

- [ ] **Step 2: 어댑터 부재 RED 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/EnglishKeyboardInputAdapterTests \
  -only-testing:SYKeyboardTests/KeyboardSmartInputPolicyTests
```

Expected: `EnglishKeyboardInputAdapter` 부재로 test build 실패.

- [ ] **Step 3: 영어 view state 어댑터 구현**

```swift
public final class EnglishKeyboardInputAdapter {
    public init(showsLanguageSwitchButton: Bool = false)
    public var primaryKeyboardView: PrimaryKeyboardRepresentable { get }
    public var isShifted: Bool { get }
    public var isCapsLocked: Bool { get }

    public func recordInsertedText(_ text: String)
    public func updateShiftAfterInput(isShiftButtonPressed: Bool)
    public func updateAutocapitalization(
        type: UITextAutocapitalizationType,
        documentContextBeforeInput: String?,
        isEnabled: Bool,
        isShiftButtonPressed: Bool
    )
    public func updateLayout(for keyboardType: UIKeyboardType?)
    public func finishForLanguageChange()
}
```

`EnglishKeyboardView` initializer/access는 adapter가 소유할 수 있는 최소 수준만 public으로 연다. `finishForLanguageChange()`는 view의 `initShiftButton()`을 사용해 `isShifted`, `wasShifted`, `isCapsLocked`, `willCapsLock`을 함께 초기화한다.

- [ ] **Step 4: 기존 영어 controller를 adapter routing으로 전환**

- 기존 `isUppercaseInput`과 `englishKeyboardView` 저장 property를 adapter로 교체한다.
- `primaryKeyboardView`, `updateKeyboardType`, `textInteractionDidPerform`, `repeatTextInteractionDidPerform`, `textWillChange`는 adapter 진입점을 호출한다.
- `treatsDefaultSmartQuotesAsEnabled == false`, `.englishSystem`, `insertTypedText` 경로와 기존 `super` 호출 순서는 유지한다.

- [ ] **Step 5: 영어 adapter·Smart Punctuation GREEN 확인**

Step 2 명령을 다시 실행한다. Expected: 두 suite 모두 PASS.

- [ ] **Step 6: 영어 extension build와 결과 기록/커밋**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
git add Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/Input/EnglishKeyboardInputAdapter.swift \
  Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift \
  Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/Protocols/EnglishKeyboardLayoutProvider.swift \
  Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/ViewController/EnglishKeyboardCoreViewController.swift \
  SYKeyboardTests/Domain/EnglishKeyboardInputAdapterTests.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md
git commit -m "refactor: #46 - 영어 입력 상태 어댑터 분리"
```

### Task 6: 한/영 버튼, 독립 muted 색상과 동적 SwitchButton

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/LanguageSwitchButton.swift`
- Create: `SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/SYKeyboardAssets.xcassets/Colors/KeyboardButton/Secondary/LanguageSwitchMutedLabelColor.colorset/Contents.json`
- Create: `SYKeyboardTests/Utils/LanguageSwitchButtonTests.swift`
- Modify: `SYKeyboardAssets/Sources/SYKeyboardAssets/Utils/Extensions/UIColor+Extension.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/PrimaryKeyboardRepresentable.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourKeyboardView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/Input/HangeulKeyboardInputAdapter.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/View/NaratgeulKeyboardView.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/View/CheonjiinKeyboardView.swift`
- Modify: `Modules/HangeulKeyboardCore/Presentation/View/DubeolsikKeyboardView.swift`
- Modify: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/Input/EnglishKeyboardInputAdapter.swift`
- Modify: `Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Modify: `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md`

**Interfaces:**
- Produces: `public final class LanguageSwitchButton: SecondaryButton`
- Produces: `public func updateLanguageMode(_ mode: HangeulEnglishLanguageMode)`
- Produces: read-only `activeTitleRange`/`mutedTitleRange` semantic ranges
- Produces: `public var languageSwitchButton: LanguageSwitchButton?` on primary layouts
- Produces: `public func updatePrimaryLanguageMode(_ mode: HangeulEnglishLanguageMode)` on `SwitchButton`
- Produces: `UIColor.languageSwitchMutedLabel`

- [ ] **Step 1: attributed 의미와 SwitchButton label 실패 테스트 작성**

버튼 private label tree를 Mirror로 읽지 않는다. `LanguageSwitchButton.attributedTitleForCurrentMode`, `activeTitleRange`, `mutedTitleRange`를 production 계산 결과로 공개 read-only 처리한다. unit test는 exact color 값이 아니라 active/muted 의미 범위를 검증하고 실제 semantic color 적용은 iOS 16/26 화면에서 확인한다.

```swift
@MainActor
@Test("한글 mode는 한 슬래시 active 영 muted")
func testHangeulModeAttributedRanges() {
    let button = LanguageSwitchButton(mode: .hangeul)
    let value = button.attributedTitleForCurrentMode
    #expect(value.string == "한/영")
    #expect(button.activeTitleRange == NSRange(location: 0, length: 2))
    #expect(button.mutedTitleRange == NSRange(location: 2, length: 1))
}

@MainActor
@Test("영어 mode는 한 muted 슬래시 영 active")
func testEnglishModeAttributedRanges() {
    let button = LanguageSwitchButton(mode: .english)
    let value = button.attributedTitleForCurrentMode
    #expect(value.string == "한/영")
    #expect(button.activeTitleRange == NSRange(location: 1, length: 2))
    #expect(button.mutedTitleRange == NSRange(location: 0, length: 1))
}

@MainActor
@Test("SwitchButton은 symbol 복귀 언어를 mode에 맞게 갱신")
func testSwitchButtonUsesActiveLanguageMode() {
    let button = SwitchButton(keyboard: .symbol)
    button.updatePrimaryLanguageMode(.hangeul)
    #expect(button.titleForCurrentKeyboard == "한글")
    button.updatePrimaryLanguageMode(.english)
    #expect(button.titleForCurrentKeyboard == "ABC")

    let primaryButton = SwitchButton(keyboard: .qwerty)
    primaryButton.updatePrimaryLanguageMode(.hangeul)
    #expect(primaryButton.titleForCurrentKeyboard == "!#1")
    primaryButton.updatePrimaryLanguageMode(.english)
    #expect(primaryButton.titleForCurrentKeyboard == "!#1")
}
```

- [ ] **Step 2: 새 UI API 부재 RED 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/LanguageSwitchButtonTests
```

Expected: 새 button/color/API 부재로 test build 실패.

- [ ] **Step 3: SYKeyboardAssets 전용 색상과 버튼 구현**

`LanguageSwitchMutedLabelColor`의 light/dark component는 현재 `SuggestionButtonLabelColor` 값과 동일하게 시작한다.

```swift
static var languageSwitchMutedLabel: UIColor {
    return UIColor(
        named: "LanguageSwitchMutedLabelColor",
        in: SYKBDAssets.bundle,
        compatibleWith: nil
    )!
}
```

`LanguageSwitchButton`은 `.label`과 `.languageSwitchMutedLabel`로 `한/영` attributed string을 만들고 `primaryKeyListLabel.attributedText`에 반영한다. `playFeedback()`은 다른 secondary modifier와 같은 haptic/modifier sound를 사용한다.

- [ ] **Step 4: 세 primary base에 opt-in 배치 추가**

- `PrimaryKeyboardRepresentable`에 optional `languageSwitchButton`을 추가하고 기본 구현은 `nil`이다.
- `StandardKeyboardView`, `FourByFourKeyboardView`, `FourByFourPlusKeyboardView` initializer에 `showsLanguageSwitchButton: Bool = false`를 추가한다.
- `true`일 때만 `LanguageSwitchButton`을 secondary 목록과 기존 `SwitchButton` 주변 hierarchy에 포함한다.
- 전용 keyboard의 기존 initializer는 기본 `false`를 사용한다.
- 두 adapter의 initializer도 `showsLanguageSwitchButton: Bool = false`를 받고 concrete view까지 전달한다. 통합 controller가 만드는 adapter만 `true`를 전달한다.
- 언어 버튼은 `SwitchButton` 앞에 frontmost sibling으로 두고 자기 bounds의 touch를 가로챈다.
- `SwitchButton`의 전체 `UIButton` frame은 기존 slot을 유지하고, `backgroundView`/`shadowView`의 visible trailing/leading inset만 언어 버튼 폭만큼 줄인다.
- 기존 keyboard/one-handed overlay anchor는 `SwitchButton` 기준을 유지한다.

- [ ] **Step 5: `SwitchButton` 동적 title 구현**

```swift
public private(set) var titleForCurrentKeyboard: String

public func updatePrimaryLanguageMode(_ mode: HangeulEnglishLanguageMode) {
    guard keyboard == .symbol || keyboard == .numeric else { return }
    titleForCurrentKeyboard = mode == .hangeul ? "한글" : "ABC"
    primaryKeyListLabel.text = titleForCurrentKeyboard
    setNeedsLayout()
}
```

기존 한글/영문 전용 extension은 초기 bundle language로 현재 title을 유지한다. `mul`은 assertion을 발생시키지 않고 `.hangeul` 기본 표시 후 통합 controller가 실제 mode를 즉시 주입한다.

- [ ] **Step 6: UI 의미 GREEN과 Auto Layout 로그 확인**

Step 2 명령 실행. Expected: suite PASS, `Unable to simultaneously satisfy constraints` 없음. `SuggestionButtonLabelColor` 파일과 `.suggestionButtonLabel` 사용처가 변경되지 않았는지 `git diff`로 확인한다.

- [ ] **Step 7: asset package build와 결과 기록/커밋**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboardAssets \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
git add Modules/SYKeyboardCore/Presentation/View/Components/Buttons/LanguageSwitchButton.swift \
  Modules/SYKeyboardCore/Presentation/View/Components/Buttons/SwitchButton.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Protocols/Base/PrimaryKeyboardRepresentable.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/StandardKeyboardView.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourKeyboardView.swift \
  Modules/SYKeyboardCore/Presentation/View/KeyboardLayout/Bases/FourByFourPlusKeyboardView.swift \
  Modules/HangeulKeyboardCore/Presentation/Input/HangeulKeyboardInputAdapter.swift \
  Modules/HangeulKeyboardCore/Presentation/View/NaratgeulKeyboardView.swift \
  Modules/HangeulKeyboardCore/Presentation/View/CheonjiinKeyboardView.swift \
  Modules/HangeulKeyboardCore/Presentation/View/DubeolsikKeyboardView.swift \
  Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/Input/EnglishKeyboardInputAdapter.swift \
  Modules/EnglishKeyboardCore/EnglishKeyboard/Presentation/View/EnglishKeyboardView.swift \
  SYKeyboardAssets/Sources/SYKeyboardAssets/Resources/SYKeyboardAssets.xcassets/Colors/KeyboardButton/Secondary/LanguageSwitchMutedLabelColor.colorset/Contents.json \
  SYKeyboardAssets/Sources/SYKeyboardAssets/Utils/Extensions/UIColor+Extension.swift \
  SYKeyboardTests/Utils/LanguageSwitchButtonTests.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md
git commit -m "design: #46 - 한영 전환 버튼과 전용 강조 색상 추가"
```

### Task 7: 통합 ViewController, focus 정책과 shared scheme 연결

**Files:**
- Modify: `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift`
- Create: `SYKeyboard.xcodeproj/xcshareddata/xcschemes/HangeulEnglishKeyboard.xcscheme`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Create: `SYKeyboardTests/Utils/HangeulEnglishKeyboardModeCoordinatorTests.swift`
- Create: `SYKeyboardTests/Utils/KeyboardLanguageSegmentTrackerTests.swift`
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Coordinators/HangeulEnglishKeyboardModeCoordinator.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md`

**Interfaces:**
- Produces: `public final class HangeulEnglishKeyboardModeCoordinator`
- Produces: `modeForTextInputChange(identifier:documentPrimaryLanguage:lastMode:)`
- Produces: `KeyboardLanguageSegmentTracker` and Base의 current-language suggestion buffer
- Consumes: Task 1 policy/storage, Task 2 suggestion API, Tasks 4–5 adapters, Task 6 buttons
- Produces: actual `HangeulEnglishKeyboardViewController: BaseKeyboardViewController`

- [ ] **Step 1: 동일 focus 수동 mode 보존 실패 테스트 작성**

```swift
@Suite("한영 통합 키보드 mode coordinator")
struct HangeulEnglishKeyboardModeCoordinatorTests {
    @Test("새 focus만 document hint로 시작 mode를 다시 판정")
    func testNewFocusReevaluatesLanguageHint() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .hangeul)
        let first = NSObject()
        let second = NSObject()
        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(first), documentPrimaryLanguage: "en-US", lastMode: .hangeul
        ) == .english)
        coordinator.selectModeManually(.hangeul)
        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(first), documentPrimaryLanguage: "en-US", lastMode: .english
        ) == .hangeul)
        #expect(coordinator.modeForTextInputChange(
            identifier: ObjectIdentifier(second), documentPrimaryLanguage: "en-US", lastMode: .hangeul
        ) == .english)
    }

    @Test("nil identifier는 현재 mode를 유지")
    func testNilIdentifierDoesNotForceMode() {
        let coordinator = HangeulEnglishKeyboardModeCoordinator(initialMode: .english)
        #expect(coordinator.modeForTextInputChange(
            identifier: nil, documentPrimaryLanguage: "ko-KR", lastMode: .hangeul
        ) == .english)
    }
}
```

- [ ] **Step 2: coordinator 부재 RED 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulEnglishKeyboardModeCoordinatorTests
```

Expected: coordinator symbol 부재로 test build 실패.

- [ ] **Step 3: coordinator 최소 구현과 GREEN**

```swift
public final class HangeulEnglishKeyboardModeCoordinator {
    public private(set) var currentMode: HangeulEnglishLanguageMode
    private var currentTextInputIdentifier: ObjectIdentifier?

    public init(initialMode: HangeulEnglishLanguageMode) { currentMode = initialMode }

    public func modeForTextInputChange(
        identifier: ObjectIdentifier?,
        documentPrimaryLanguage: String?,
        lastMode: HangeulEnglishLanguageMode?
    ) -> HangeulEnglishLanguageMode {
        guard let identifier else { return currentMode }
        guard identifier != currentTextInputIdentifier else { return currentMode }
        currentTextInputIdentifier = identifier
        return KeyboardLanguageModePolicy.initialMode(
            documentPrimaryLanguage: documentPrimaryLanguage,
            lastMode: lastMode
        )
    }

    public func selectModeManually(_ mode: HangeulEnglishLanguageMode) {
        currentMode = mode
    }
}
```

Step 2 명령을 다시 실행한다. Expected: suite PASS.

- [ ] **Step 4: 언어별 suggestion segment 실패 테스트와 최소 구현**

기존 `inputBuffer`의 document session 동기화는 유지하되, mode 전환 뒤 입력한 suffix만 suggestion/n-gram에 전달하도록 production tracker를 추가한다.

```swift
@Suite("한영 입력 segment 추적")
struct KeyboardLanguageSegmentTrackerTests {
    @Test("언어 경계 뒤 삽입과 대치만 현재 segment에 반영")
    func testTracksOnlyEditsAfterBoundary() {
        var tracker = KeyboardLanguageSegmentTracker()
        tracker.insert("한글")
        tracker.markLanguageBoundary()
        tracker.insert("ab")
        tracker.replace(deleteCount: 1, insertText: "C")

        #expect(tracker.currentSegment(in: "한글aC") == "aC")
    }

    @Test("경계 이전 문서 삭제는 현재 segment를 음수로 만들지 않음")
    func testDeletionDoesNotCrossSegmentBoundary() {
        var tracker = KeyboardLanguageSegmentTracker()
        tracker.insert("한글")
        tracker.markLanguageBoundary()
        tracker.delete(count: 1)

        #expect(tracker.currentSegment(in: "한") == "")
    }
}
```

`KeyboardLanguageSegmentTracker`는 별도 공개 파일을 만들지 않고 `BaseKeyboardViewController.swift`에 internal file-scope 타입으로 둔다. 현재 segment의 character count만 저장한다. `insert`, `delete`, `replace`, 외부 context reset을 Base의 기존 `inputBuffer` wrapper와 같은 지점에서 갱신하고, `markLanguageBoundary()`는 count를 0으로 만든다. Base 내부의 suggestion 조회·n-gram 기록·문장 종료에는 raw `inputBuffer` 대신 `tracker.currentSegment(in: inputBuffer)`를 전달한다. 기존 전용 keyboard는 경계를 표시하지 않으므로 전체 `inputBuffer`가 그대로 반환돼 동작이 바뀌지 않는다.

```swift
struct KeyboardLanguageSegmentTracker {
    private var currentSegmentCount: Int?

    init() {}

    mutating func markLanguageBoundary() {
        currentSegmentCount = 0
    }

    mutating func insert(_ text: String) {
        guard let currentSegmentCount else { return }
        self.currentSegmentCount = currentSegmentCount + text.count
    }

    mutating func delete(count: Int) {
        guard let currentSegmentCount else { return }
        self.currentSegmentCount = max(0, currentSegmentCount - count)
    }

    mutating func replace(deleteCount: Int, insertText: String) {
        delete(count: deleteCount)
        insert(insertText)
    }

    mutating func resetForExternalContext() {
        currentSegmentCount = nil
    }

    func currentSegment(in inputBuffer: String) -> String {
        guard let currentSegmentCount else { return inputBuffer }
        return String(inputBuffer.suffix(currentSegmentCount))
    }
}
```

Run:

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/KeyboardLanguageSegmentTrackerTests
```

Expected RED: tracker symbol 부재. 구현 후 같은 명령 PASS.

- [ ] **Step 5: 템플릿 controller를 실제 통합 controller로 교체**

Controller 구성:

```swift
final class HangeulEnglishKeyboardViewController: BaseKeyboardViewController {
    private let hangeulAdapter = HangeulKeyboardInputAdapter(
        selectedKeyboard: UserDefaultsManager.shared.selectedHangeulKeyboard,
        showsLanguageSwitchButton: true
    )
    private let englishAdapter = EnglishKeyboardInputAdapter(
        showsLanguageSwitchButton: true
    )
    private lazy var modeCoordinator = HangeulEnglishKeyboardModeCoordinator(
        initialMode: keyboardSettingsManager.lastHangeulEnglishLanguageMode
    )

    override var primaryKeyboardViews: [PrimaryKeyboardRepresentable] {
        hangeulAdapter.primaryKeyboardViews + [englishAdapter.primaryKeyboardView]
    }

    override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        modeCoordinator.currentMode == .hangeul
            ? hangeulAdapter.primaryKeyboardView
            : englishAdapter.primaryKeyboardView
    }
}
```

반드시 구현할 routing:

- `textInputDidChange(_:)`: `textInput.map { ObjectIdentifier($0 as AnyObject) }`와 `documentInputMode?.primaryLanguage`를 coordinator에 전달하고 반환 mode 적용
- `textWillChange`: `super` 호출 뒤 active adapter 외부 문맥 reset과 active mode layout/shift 갱신
- `updateKeyboardType`: current language adapter의 URL/email/twitter/webSearch mode와 공통 symbol/TenKey를 연결
- `shouldDeferUndoRedoCommit`, Smart Quote default/rule: current mode에 따라 adapter 정책 반환
- text interaction before/after, repeat, primary/secondary 입력, space/return, delete/repeat delete, delete pan: current adapter 진입점으로 routing
- 한글 transition은 `insertText`, `deleteText`, `replaceText` wrapper만 사용해 적용
- 영어 typed text는 Base `insertTypedText` 사용

`applyLanguageMode(_:, persist:)` 순서:

1. 반복 입력과 pressed button 상태 종료 API 호출
2. 이전 mode adapter `finishForLanguageChange()`
3. 한글 전환 종료이면 deferred undo group 확정
4. coordinator `selectModeManually(_:)`로 current mode 갱신
5. `persist == true`이거나 새 focus 판정이면 `lastHangeulEnglishLanguageMode` 저장
6. `primaryLanguage` 갱신
7. `suggestionController.updateLanguage(to:)`를 호출할 수 있도록 Base에 protected final forwarding API 추가
8. 모든 `LanguageSwitchButton`과 symbol/numeric `SwitchButton` 갱신
9. `currentKeyboard`를 새 primary keyboard로 설정하되 현재 host가 symbol/TenKey를 요구하면 표시 keyboard는 유지
10. 후보를 초기화하고 `KeyboardLanguageSegmentTracker.markLanguageBoundary()` 호출

`textInputDidChange(_:)`는 coordinator 호출 전에 이전 mode를 보관한다. 새 focus 판정이 다른 mode를 반환하면 이전 adapter 종료에 그 보관값을 사용한 뒤 `applyLanguageMode`가 coordinator state를 갱신한다. coordinator가 반환값을 계산하는 시점에 current mode를 먼저 덮어쓰지 않는다.

Base의 private suggestion/inputBuffer를 직접 공개하지 않는다. 다음 목적 제한 forwarding API만 추가한다.

```swift
public final func updateSuggestionLanguage(to language: String)
public final func clearSuggestionsForLanguageChange()
public final func markCurrentInputBufferAsLanguageBoundary()
public final func stopInputInteractionsForLanguageChange()
```

- [ ] **Step 6: 한/영 button action 단일 연결**

각 primary view의 non-nil `languageSwitchButton`에 `.touchUpInside` `UIAction`을 setup 시 한 번 추가한다. action은 current mode의 반대값을 계산해 `applyLanguageMode(_:persist: true)`에 전달하고, coordinator 갱신은 해당 메서드의 공통 순서에서만 수행한다. mode 전환마다 action을 다시 추가하지 않는다.

- [ ] **Step 7: extension lifecycle·overlay와 scheme 연결**

- 기존 한글/영문 extension의 Crashlytics/전체 접근 overlay 초기화 패턴을 읽고 동일 lifecycle hook만 통합 controller에 적용한다.
- `HangeulEnglishKeyboard` shared scheme을 다른 shared extension scheme과 같은 Build/Test configuration으로 추가한다.
- `xcodebuild -list -project SYKeyboard.xcodeproj`에서 scheme이 보여야 한다.
- project target dependency와 app embed는 기존 값을 유지한다.

- [ ] **Step 8: 관련 정책 테스트와 네 scheme build**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0' \
  -only-testing:SYKeyboardTests/HangeulEnglishKeyboardModeCoordinatorTests \
  -only-testing:SYKeyboardTests/KeyboardLanguageSegmentTrackerTests \
  -only-testing:SYKeyboardTests/KeyboardLanguageModePolicyTests \
  -only-testing:SYKeyboardTests/HangeulKeyboardInputAdapterTests \
  -only-testing:SYKeyboardTests/EnglishKeyboardInputAdapterTests \
  -only-testing:SYKeyboardTests/LanguageSwitchButtonTests
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 지정 테스트와 세 extension build 모두 성공.

- [ ] **Step 9: 결과 기록과 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Coordinators/HangeulEnglishKeyboardModeCoordinator.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift \
  SYKeyboardTests/Utils/HangeulEnglishKeyboardModeCoordinatorTests.swift \
  SYKeyboardTests/Utils/KeyboardLanguageSegmentTrackerTests.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboard.xcodeproj/xcshareddata/xcschemes/HangeulEnglishKeyboard.xcscheme \
  docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md
git commit -m "feat: #46 - 한영 통합 키보드 입력 전환 연결"
```

### Task 8: 전체 회귀, 실제 입력 화면과 안내 문구 판정

**Files:**
- Modify only if contradicted by observation: `SYKeyboard/Presentation/`
- Modify: `docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md`

**Interfaces:**
- Consumes: Tasks 1–7의 완성된 통합 extension
- Produces: 재현 가능한 자동/수동 검증 기록
- Preserves: 코드 변경 없는 검증 step도 문서 커밋으로 남김

- [ ] **Step 1: 전체 테스트 실행**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: exit 0, 실패·스킵 0. `.xcresult`에 대해 다음을 실행해 실제 total/failed/skipped를 기록한다.

```sh
xcrun xcresulttool get test-results summary --path '<actual.xcresult>'
```

- [ ] **Step 2: app과 세 extension build**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme EnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=16.0'
```

Expected: 네 build exit 0. 앱 산출물의 `PlugIns/HangeulEnglishKeyboard.appex` 존재와 built extension `Info.plist`의 `PrimaryLanguage = mul`을 확인한다.

- [ ] **Step 3: iOS 16 실제 입력 smoke test**

iPhone 13 mini / iOS 16.0 Simulator에서 통합 keyboard를 활성화하고 다음을 관찰한다.

- 한글 기본 fallback, `ko` hint 한글, `en` hint 영어
- hint 없는 새 TextField에서 마지막 사용 mode
- 같은 TextField의 수동 mode 보존
- 한글 조합 중 영어 전환 후 문서 글자 유지
- 영어 Shift/caps, Smart Punctuation
- 삭제, 반복 삭제, delete pan, 스페이스, 리턴, symbol, numeric/TenKey
- globe/next keyboard, one-handed와 cursor gesture
- symbol/numeric `SwitchButton`의 한글 mode `한글`, 영어 mode `ABC`
- primary `LanguageSwitchButton`의 attributed 구간과 touch 충돌 부재
- Auto Layout conflict/crash 로그 부재

- [ ] **Step 4: iOS 26 light/dark 시각 확인**

설치된 iOS 26.x Simulator에서 light/dark 각각 다음을 확인한다.

- 한글 mode: `한/` active, `영` muted
- 영어 mode: `한` muted, `/영` active
- `LanguageSwitchMutedLabelColor`가 읽히며 Suggestion label 색 변경 없이 독립 동작
- Liquid Glass 환경에서 secondary button 배경, shadow, hit area와 인접 `SwitchButton` 표시

정확한 RGB 조정이 필요하면 이 Task에서 `LanguageSwitchMutedLabelColor.colorset/Contents.json`만 변경하고 두 appearance를 다시 확인한다.

- [ ] **Step 5: 세 keyboard 등록 안내 판정**

iOS 설정에서 한글, 영어, 한·영 통합 extension이 별도 항목으로 표시되는지 확인한다. 앱 안내 문구가 실제 항목과 충돌할 때만 `SYKeyboard/Presentation/`의 해당 문자열/catalog를 최소 수정한다. 충돌하지 않으면 코드나 문구를 변경하지 않고 Result에 “변경 불필요”를 기록한다.

- [ ] **Step 6: 변경 범위와 문서 결과 확인**

```sh
git diff --check
git status --short
git diff --stat origin/develop...HEAD
```

각 자동 명령의 exit code, test count, `.xcresult`/log 경로, 실제 Simulator 기기·OS, 수동 관찰 결과와 미확인 항목의 차단 경로를 이 Task의 `**Result:**`에 기록한다. 수동 미확인 항목이 있으면 production-ready로 표시하지 않는다.

- [ ] **Step 7: 최종 검증 문서 커밋**

안내 문구 변경이 없으면 계획 문서만, 변경이 있으면 해당 Presentation/catalog와 계획 문서만 stage한다.

```sh
git add docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md
git commit -m "docs: #46 - 한영 통합 키보드 검증 결과 기록"
```

안내 문구가 수정됐다면 기능과 문서 목적을 분리한다.

```sh
git add SYKeyboard/Presentation SYKeyboard/Resources/Localizable.xcstrings
git commit -m "docs: #46 - 통합 키보드 등록 안내 반영"
git add docs/superpowers/plans/2026-08-12-hangeul-english-keyboard.md
git commit -m "docs: #46 - 한영 통합 키보드 검증 결과 기록"
```

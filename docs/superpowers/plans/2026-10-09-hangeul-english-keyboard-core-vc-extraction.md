# 한영 통합 키보드 Core VC 추출 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `HangeulEnglishKeyboardViewController`의 입력 로직을 새 static framework `HangeulEnglishKeyboardCore`의 `HangeulEnglishKeyboardCoreViewController`로 옮기고, extension VC를 Firebase 설정과 메모리 경고 로그만 가진 껍데기로 만든다. 동작은 바꾸지 않는다.

**Architecture:** `HangeulKeyboardCore`·`EnglishKeyboardCore`·`SYKeyboardCore`를 의존하는 네 번째 Core 모듈을 `project.pbxproj`에 추가하고, 기존 VC 본문을 `open class`로 옮긴다. Core는 Firebase를 모르므로 Crashlytics 기록은 Core VC의 빈 `open` 훅 `languageModeDecisionDidResolve(requiresLatinInput:resolved:)`를 extension이 오버라이드해 수행한다. 모듈이 되면 `SYKeyboardTests`가 `@testable import`할 수 있어 프록시 읽기 테스트와 해제 테스트를 처음으로 둘 수 있다.

**Tech Stack:** Swift 5 / UIKit / Xcode 27 / Swift Testing / `PBXFileSystemSynchronizedRootGroup`(objectVersion 77) 수동 편집

**Spec:** `docs/superpowers/specs/2026-10-09-hangeul-english-keyboard-core-vc-extraction-design.md`

- 이슈: #190
- 브랜치: `refactor/#190-extract-hangeul-english-core-vc`
- 검증 기준: `iPhone 13 mini / iOS 18.6`

## Global Constraints

- 동작 변경 금지. leaf와 Core를 합친 코드가 옮기기 전 `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift`(develop `b1391416`)와 로직상 같아야 한다. Task 2 Step 2의 diff 목록이 그 증거다.
- Core 모듈은 Firebase를 import하지 않는다. `HangeulEnglishKeyboardCore` 타깃에 `FirebaseCrashlytics`를 링크하지 않는다.
- `HangeulEnglishKeyboardModeCoordinator`, `KeyboardLanguageModePolicy`, `HangeulEnglishLanguageMode`, `LanguageSwitchButton`은 `SYKeyboardCore`에 그대로 둔다.
- `HangeulKeyboardCoreViewController`와 중복된 한글 라우팅 코드를 합치지 않는다.
- `.docc`를 만들지 않는다. 앱 미리보기(`PreviewHangeulEnglishKeyboardViewController`)를 만들지 않는다.
- 새 타깃 빌드 설정은 `EnglishKeyboardCore`와 같고 `PRODUCT_BUNDLE_IDENTIFIER`만 `com.snmac.HangeulEnglishKeyboardCore`다. `MACH_O_TYPE = staticlib`.
- 빌드 뒤 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 경우 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`으로 되돌린다.
- 커밋 메시지는 `type: #190 - subject`, 마지막 줄 `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. 커밋 전 `git branch --show-current`로 브랜치를 확인한다. push하지 않는다.
- 각 Task가 끝나면 이 문서의 체크박스와 실제 결과(테스트 개수, 빌드 결과)를 갱신하고 그 Task의 코드·테스트·문서와 함께 한 커밋으로 남긴다.
- `xcodebuild`는 foreground로 `timeout: 600000`을 명시해 실행하고 로그는 파일로 남긴다. 각 Step의 명령은 셸 변수 `SCRATCH`를 쓰며, 작업 시작 때 한 번 `SCRATCH="${SCRATCH:-$(mktemp -d)}"`로 정의한다(세션 scratchpad 디렉터리가 있으면 그 경로를 넣는다). 몇 분씩 진행이 없으면 CLAUDE.md의 "호스트 앱이 뜨지도 않고 테스트가 매달리는 경우"를 따른다.

## Review Focus

spec이 말하지 않지만 사람이 쓰면서 부딪힐 수 있는 입력·조건과, 그것을 고정하는 테스트가 있는 Task:

1. **영어 모드에서 `textWillChange`가 프록시를 두 번 읽는 회귀** — `withReadCaching` 블록이 옮기는 중 빠지면 shift 자동 대문자 판정이 같은 값을 다시 읽는다. → Task 1 테스트.
2. **한/A 전환 버튼의 `UIAction` 클로저가 VC를 강하게 잡는 회귀** — `[weak self]`가 빠지면 키보드를 내려도 VC가 남아 다음 표시 때 메모리 경고가 난다. → Task 3 해제 테스트.
3. **저장된 마지막 언어가 `english`인데 한글로 시작하는 회귀** — `init()`에서 `storedLanguageMode()`를 읽는 순서가 바뀌면 생긴다. → Task 1 테스트가 `.english`를 저장한 뒤 영어 모드 동작(autocapitalization 읽기)을 요구하므로 함께 고정된다.
4. **Crashlytics 기록 순서가 `applyLanguageMode` 뒤로 밀리는 회귀** — `applyLanguageMode` 안에서 크래시가 나면 `document_primary_language` 키가 리포트에 없다. 자동 테스트로 고정하지 않는다. Task 2 Step 2의 diff에서 훅 호출이 `applyLanguageMode` 호출 **앞** 줄에 있는지 눈으로 확인한다.
5. **앱 타깃이 Core VC 소스를 직접 컴파일해 중복 심볼이 나는 실수** — `SYKeyboard` 타깃의 `Modules` 제외 목록에 경로를 빠뜨리면 난다. → Task 1 Step 6의 `SYKeyboard` 스킴 테스트 빌드가 잡는다.

---

### Task 1: `HangeulEnglishKeyboardCore` 타깃과 Core VC, 프록시 읽기 테스트

**Files:**
- Create: `Modules/HangeulEnglishKeyboardCore/Presentation/ViewController/HangeulEnglishKeyboardCoreViewController.swift`
- Create: `SYKeyboardTests/Controller/HangeulEnglishKeyboardCoreViewControllerProxyReadTests.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `BaseKeyboardViewController`(SYKeyboardCore), `HangeulKeyboardInputAdapter`(HangeulKeyboardCore), `EnglishKeyboardInputAdapter`(EnglishKeyboardCore), `HangeulEnglishKeyboardModeCoordinator`·`KeyboardLanguageModePolicy`·`HangeulEnglishLanguageMode`(SYKeyboardCore), 테스트 보조 `CountingTextDocumentProxy`·`.sharedUserDefaults`(SYKeyboardTests)
- Produces: 모듈 `HangeulEnglishKeyboardCore`, `open class HangeulEnglishKeyboardCoreViewController: BaseKeyboardViewController` with `public init()`, 빈 훅 `open func languageModeDecisionDidResolve(requiresLatinInput: Bool, resolved: HangeulEnglishLanguageMode)`. Task 2의 leaf가 이 둘을 쓴다.

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Controller/HangeulEnglishKeyboardCoreViewControllerProxyReadTests.swift`:

```swift
//
//  HangeulEnglishKeyboardCoreViewControllerProxyReadTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/9/26.
//

import Testing
import UIKit

@testable import HangeulEnglishKeyboardCore
@testable import SYKeyboardCore

/// 한영 통합 VC가 `super.textWillChange` 뒤에서 읽는 값도 같은 콜백 범위에서 한 번만 읽는지 확인한다
@Suite("HangeulEnglishKeyboardCoreViewController 텍스트 프록시 읽기", .sharedUserDefaults)
@MainActor
struct HangeulEnglishKeyboardCoreViewControllerProxyReadTests {

    @Test("영어 모드 textWillChange는 shift 자동 대문자 판정까지 같은 프록시 값을 한 번만 읽음")
    func testTextWillChangeReadsShiftContextOnceInEnglishMode() {
        withLastLanguageMode(.english) {
            let controller = TestHangeulEnglishProxyReadViewController()
            controller.loadViewIfNeeded()
            controller.proxy.resetReadCounts()

            controller.textWillChange(nil)

            #expect(controller.proxy.readCount(of: "autocapitalizationType") == 1)
            #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 1)
        }
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestHangeulEnglishProxyReadViewController: HangeulEnglishKeyboardCoreViewController {
    let proxy = CountingTextDocumentProxy()

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }
}

/// VC `init()`이 읽는 마지막 언어를 바꾸고, body가 끝나면 원래 저장값으로 되돌린다.
/// 한/A 전환이 `persist: true`로 다시 저장하므로 테스트 본문 전체를 감싼다
@MainActor
private func withLastLanguageMode(_ mode: HangeulEnglishLanguageMode, _ body: () -> Void) {
    let storage = UserDefaultsManager.shared.storage
    let key = UserDefaultsKeys.lastHangeulEnglishLanguageMode
    let original = storage.object(forKey: key)
    defer {
        if let original {
            storage.set(original, forKey: key)
        } else {
            storage.removeObject(forKey: key)
        }
    }

    UserDefaultsManager.shared.lastHangeulEnglishLanguageMode = mode
    body()
}
```

- [x] **Step 2: 테스트가 실패하는지 확인**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/HangeulEnglishKeyboardCoreViewControllerProxyReadTests \
  > "$SCRATCH/task1-red.log" 2>&1; tail -5 "$SCRATCH/task1-red.log"
```

기대: `error: no such module 'HangeulEnglishKeyboardCore'`로 컴파일 실패, `** TEST FAILED **`.

- [x] **Step 3: Core VC 파일 작성**

`Modules/HangeulEnglishKeyboardCore/Presentation/ViewController/HangeulEnglishKeyboardCoreViewController.swift`. 현재 extension VC 본문을 옮긴 것이다. 바뀐 곳은 (1) 헤더·import, (2) `open class`/`public init`/`open override`, (3) `logger`·`didReceiveMemoryWarning`·`setupFirebase`·`recordLanguageModeDecision` 제거, (4) `inputTraitsDidChange()`의 `recordLanguageModeDecision(...)` 호출을 `languageModeDecisionDidResolve(...)` 훅 호출로 교체, (5) 훅 선언 추가. 그 외 줄은 글자 그대로다.

```swift
//
//  HangeulEnglishKeyboardCoreViewController.swift
//  HangeulEnglishKeyboardCore
//
//  Created by Claude on 10/9/26.
//

import UIKit

import EnglishKeyboardCore
import HangeulKeyboardCore
import SYKeyboardCore

/// 한글과 영어 입력/UI를 함께 제공하는 통합 키보드 컨트롤러
///
/// Firebase 설정과 진단 기록은 extension의 `HangeulEnglishKeyboardViewController`가 맡는다.
/// Core는 Firebase를 모르므로 `languageModeDecisionDidResolve(requiresLatinInput:resolved:)` 훅만 제공한다
open class HangeulEnglishKeyboardCoreViewController: BaseKeyboardViewController {

    // MARK: - Properties

    private let hangeulAdapter = HangeulKeyboardInputAdapter(
        selectedKeyboard: UserDefaultsManager.shared.selectedHangeulKeyboard,
        showsLanguageSwitchButton: true
    )
    private let englishAdapter = EnglishKeyboardInputAdapter(
        showsLanguageSwitchButton: true
    )
    /// 키보드가 뜰 때 결정한 시작 언어
    private let initialLanguageMode: HangeulEnglishLanguageMode
    private lazy var modeCoordinator = HangeulEnglishKeyboardModeCoordinator(
        initialMode: initialLanguageMode
    )

    open override var primaryKeyboardViews: [PrimaryKeyboardRepresentable] {
        return hangeulAdapter.primaryKeyboardViews + [englishAdapter.primaryKeyboardView]
    }

    open override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        switch modeCoordinator.currentMode {
        case .hangeul:
            return hangeulAdapter.primaryKeyboardView
        case .english:
            return englishAdapter.primaryKeyboardView
        }
    }

    open override var hangeulSwitchGestureKeyboardView: SwitchGestureHandling {
        return hangeulAdapter.primaryKeyboardView
    }

    open override var englishSwitchGestureKeyboardView: SwitchGestureHandling {
        return englishAdapter.primaryKeyboardView
    }

    open override var shouldDeferUndoRedoCommit: Bool {
        return modeCoordinator.currentMode == .hangeul
            && hangeulAdapter.shouldDeferUndoRedoCommit
    }

    open override var treatsDefaultSmartQuotesAsEnabled: Bool {
        return modeCoordinator.currentMode == .hangeul
    }

    open override var smartQuoteRule: KeyboardSmartQuoteRule {
        return modeCoordinator.currentMode == .hangeul ? .koreanSystem : .englishSystem
    }

    // MARK: - Initializer

    public init() {
        // 저장된 언어가 없으면 OS 언어 설정을 따른다.
        // 이 시점에는 textDocumentProxy에 접근하지 않는다(수명주기 크래시 경로)
        let mode = KeyboardLanguageModePolicy.initialMode(
            requiresLatinInput: false,
            lastMode: Self.storedLanguageMode(),
            preferredLanguages: Locale.preferredLanguages
        )
        initialLanguageMode = mode
        SwitchButton.previewPrimaryLanguage = mode.languageIdentifier
        super.init(
            language: mode.languageIdentifier,
            nGramLanguage: NGramPredictiveTextEngine.hangeulEnglishLanguage
        )
        primaryLanguage = mode.languageIdentifier
    }

    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()

        setupLanguageSwitchActions()
        applyLanguageMode(modeCoordinator.currentMode, persist: false)
    }

    // MARK: - Diagnostics Hook

    /// 시작 언어 판정 근거를 남길 자리. Core는 Firebase를 모르므로 extension이 구현한다.
    /// `inputTraitsDidChange()`에서 `applyLanguageMode` **앞**에 불린다
    open func languageModeDecisionDidResolve(
        requiresLatinInput: Bool,
        resolved: HangeulEnglishLanguageMode
    ) {}

    // MARK: - Override Methods

    /// 이 훅은 `textDidChange`에서 `updateKeyboardType()` **뒤에** 불린다.
    /// 그래서 `updateKeyboardType()`이 아직 바뀌기 전 언어로 `currentKeyboard`를 한 번 정하고,
    /// 아래 `applyLanguageMode`가 새 언어로 다시 정한다. 두 번째가 항상 정정해 주는 근거는
    /// `KeyboardLanguageModePolicy.shouldReturnToPrimaryKeyboard`가 문자 자판 네 종류 모두에
    /// `true`를 돌려준다는 것이고, 그 성질은 `testAutomaticSwitchUpdatesPrimaryKeyboard`가 고정한다
    open override func inputTraitsDidChange() {
        let previousMode = modeCoordinator.currentMode
        let requiresLatinInput = KeyboardLanguageModePolicy.requiresLatinInput(
            keyboardType: textDocument.keyboardType,
            textContentType: textDocument.textContentType
        )
        let mode = modeCoordinator.modeForInputTraitsChange(
            requiresLatinInput: requiresLatinInput,
            lastMode: Self.storedLanguageMode(),
            preferredLanguages: Locale.preferredLanguages
        )
        languageModeDecisionDidResolve(requiresLatinInput: requiresLatinInput, resolved: mode)

        // 필드가 강제한 영어는 사용자의 선택이 아니므로 마지막 언어로 저장하지 않는다
        applyLanguageMode(
            mode,
            persist: !requiresLatinInput,
            outgoingMode: previousMode
        )
    }

    open override func textWillChange(_ textInput: (any UITextInput)?) {
        // 영어 모드의 shift 자동 대문자 판정도 Base 콜백과 같은 범위에서 읽는다
        textDocument.withReadCaching {
            super.textWillChange(textInput)

            switch modeCoordinator.currentMode {
            case .hangeul:
                hangeulAdapter.clearForExternalTextChange()
                updateHangeulSpaceButton()
                updateHangeulShiftButton()
            case .english:
                updateEnglishShiftButton()
            }
        }
    }

    open override func undoRedoEditDidApply() {
        super.undoRedoEditDidApply()
        hangeulAdapter.clearForExternalTextChange()
        updateHangeulSpaceButton()
        updateShiftButtonForCurrentMode()
    }

    open override func didSetCurrentKeyboard() {
        super.didSetCurrentKeyboard()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.clearLetterInputState()
        }
        updateShiftButtonForCurrentMode()
    }

    open override func updateKeyboardType() {
        guard textDocument.keyboardType != oldKeyboardType else { return }

        symbolKeyboardView.currentSymbolKeyboardMode = SymbolKeyboardMode(
            keyboardType: textDocument.keyboardType
        )
        hangeulAdapter.updateLayout(for: textDocument.keyboardType)
        englishAdapter.updateLayout(for: textDocument.keyboardType)

        switch textDocument.keyboardType {
        case .default, nil, .asciiCapable, .URL, .emailAddress, .twitter, .webSearch:
            currentKeyboard = primaryKeyboardView.keyboard
        case .numbersAndPunctuation:
            currentKeyboard = .symbol
        case .numberPad, .phonePad, .namePhonePad, .asciiCapableNumberPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .numberPad
            currentKeyboard = .tenKey
        case .decimalPad:
            tenkeyKeyboardView.currentTenkeyKeyboardMode = .decimalPad
            currentKeyboard = .tenKey
        @unknown default:
            currentKeyboard = primaryKeyboardView.keyboard
        }
    }

    open override func textInteractionWillPerform(button: TextInteractable) {
        if modeCoordinator.currentMode == .hangeul {
            if button is DeleteButton {
                hangeulAdapter.beginDeleteTouchDown()
            } else {
                hangeulAdapter.cancelDeleteTouchDown()
            }
        }
        super.textInteractionWillPerform(button: button)
    }

    open override func textInteractionDidPerform(button: TextInteractable) {
        super.textInteractionDidPerform(button: button)

        switch modeCoordinator.currentMode {
        case .hangeul:
            if button is DeleteButton {
                hangeulAdapter.endDeleteTouchDown()
            } else {
                hangeulAdapter.cancelDeleteTouchDown()
            }
            hangeulAdapter.recordTextInteraction()
            if !hangeulAdapter.shouldDeferUndoRedoCommit {
                commitDeferredUndoRedoGroupIfNeeded()
            }
        case .english:
            if let primaryKey = button.type.primaryKeyList.first {
                englishAdapter.recordInsertedText(primaryKey)
            }
        }

        if !isRepeatingInput {
            updateShiftButtonForCurrentMode()
        }
    }

    open override func suggestionDidApply() {
        super.suggestionDidApply()
        guard modeCoordinator.currentMode == .hangeul else { return }

        hangeulAdapter.clearForExternalTextChange()
        updateHangeulSpaceButton()
    }

    open override func repeatTextInteractionWillPerform(button: TextInteractable) {
        super.repeatTextInteractionWillPerform(button: button)
        guard modeCoordinator.currentMode == .hangeul else { return }

        if button is DeleteButton {
            performInitialRepeatDeleteTextInteraction(for: button)
        }
    }

    open override func performInitialRepeatTextInteraction(for button: TextInteractable) {
        guard modeCoordinator.currentMode == .hangeul else {
            super.performInitialRepeatTextInteraction(for: button)
            return
        }

        performTextInteraction(for: button)
        if hangeulAdapter.hasRepeatableInput || button is SpaceButton {
            button.playFeedback()
        }
    }

    open override func repeatTextInteractionDidPerform(button: TextInteractable) {
        super.repeatTextInteractionDidPerform(button: button)

        if modeCoordinator.currentMode == .hangeul {
            if button is DeleteButton {
                applyCompositionTransition(hangeulAdapter.finishRepeatDelete())
            }
            if !hangeulAdapter.shouldDeferUndoRedoCommit {
                commitDeferredUndoRedoGroupIfNeeded()
            }
        }
        updateShiftButtonForCurrentMode()
    }

    open override func insertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }

        switch modeCoordinator.currentMode {
        case .hangeul:
            if currentKeyboard == .symbol {
                hangeulAdapter.clearForExternalTextChange()
                super.insertPrimaryKeyText(from: button)
                updateHangeulSpaceButton()
                return
            }
            guard let primaryKey = button.type.primaryKeyList.first else {
                assertionFailure("primaryKeyList 배열이 비어있습니다.")
                return
            }
            applyCompositionTransition(hangeulAdapter.input(primaryKey))
        case .english:
            guard let primaryKey = button.type.primaryKeyList.first else {
                assertionFailure("primaryKeyList 배열이 비어있습니다.")
                return
            }
            insertTypedText(primaryKey)
        }
    }

    open override func insertSecondaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }
        guard let secondaryKey = button.type.secondaryKey else {
            assertionFailure("secondaryKey가 nil입니다.")
            return
        }

        if modeCoordinator.currentMode == .hangeul {
            applyCompositionTransition(hangeulAdapter.input(secondaryKey))
        } else {
            insertTypedText(secondaryKey)
        }
    }

    open override func repeatInsertPrimaryKeyText(from button: TextInteractable) {
        if BaseKeyboardViewController.isPreview { return }

        switch modeCoordinator.currentMode {
        case .hangeul:
            if currentKeyboard == .symbol {
                super.repeatInsertPrimaryKeyText(from: button)
                updateHangeulSpaceButton()
                return
            }
            guard hangeulAdapter.hasRepeatableInput else {
                super.repeatTextInteractionDidPerform(button: button)
                button.isGesturing = false
                return
            }
            applyCompositionTransition(hangeulAdapter.repeatInput())
        case .english:
            guard let primaryKey = button.type.primaryKeyList.first else {
                assertionFailure("primaryKeyList 배열이 비어있습니다.")
                return
            }
            insertTypedText(primaryKey)
        }
    }

    open override func insertSpaceText() {
        if BaseKeyboardViewController.isPreview { return }

        let isHangeulPrimaryKeyboard = currentKeyboard == .naratgeul
            || currentKeyboard == .cheonjiin
            || currentKeyboard == .dubeolsik
        if modeCoordinator.currentMode == .hangeul,
           isHangeulPrimaryKeyboard {
            let transition = hangeulAdapter.space()
            if transition.proxyEdit == .insert(" ") {
                super.insertSpaceText()
            } else {
                applyCompositionTransition(transition)
            }
            commitUndoRedoGroupIfPossible()
            updateHangeulSpaceButton()
            return
        }

        super.insertSpaceText()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.clearForExternalTextChange()
            updateHangeulSpaceButton()
        }
    }

    open override func insertReturnText() {
        if BaseKeyboardViewController.isPreview { return }

        super.insertReturnText()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.clearForExternalTextChange()
            commitUndoRedoGroupIfPossible()
            updateHangeulSpaceButton()
        }
    }

    open override func deleteBackwardWillPerform() {
        guard modeCoordinator.currentMode == .hangeul else {
            super.deleteBackwardWillPerform()
            return
        }

        if isRepeatingInput {
            super.repeatDeleteBackwardWillPerform()
            return
        }

        super.deleteBackwardWillPerform()
        commitUndoRedoGroupIgnoringCompositionDeferral()
    }

    open override func repeatDeleteBackwardWillPerform() {
        super.repeatDeleteBackwardWillPerform()
        guard modeCoordinator.currentMode == .hangeul,
              !isRepeatingInput else { return }
        commitUndoRedoGroupIgnoringCompositionDeferral()
    }

    open override func deleteBackward() {
        guard modeCoordinator.currentMode == .hangeul else {
            super.deleteBackward()
            return
        }
        if BaseKeyboardViewController.isPreview { return }

        deleteBackwardWillPerform()
        applyCompositionTransition(hangeulAdapter.delete())
        updateHangeulSpaceButton()
    }

    open override func repeatDeleteBackward() {
        guard modeCoordinator.currentMode == .hangeul else {
            super.repeatDeleteBackward()
            return
        }
        if BaseKeyboardViewController.isPreview { return }

        repeatDeleteBackwardWillPerform()
        applyCompositionTransition(hangeulAdapter.repeatDelete())
        updateHangeulSpaceButton()
    }

    open override func deleteButtonPanDeleteText(
        hasPendingRestoreText: Bool
    ) -> (character: Character, shouldRestore: Bool)? {
        guard modeCoordinator.currentMode == .hangeul else {
            return super.deleteButtonPanDeleteText(
                hasPendingRestoreText: hasPendingRestoreText
            )
        }
        if BaseKeyboardViewController.isPreview { return nil }

        if let result = hangeulAdapter.beginDeletePan() {
            applyCompositionTransition(result.transition)
            updateHangeulSpaceButton()
            return (result.character, result.shouldRestore)
        }

        guard let character = deleteButtonPanPreviousCharacter else { return nil }
        deleteText()
        updateHangeulSpaceButton()
        return (character, true)
    }

    open override func deleteButtonPanRestoreText(_ character: Character) {
        guard modeCoordinator.currentMode == .hangeul else {
            super.deleteButtonPanRestoreText(character)
            return
        }
        if BaseKeyboardViewController.isPreview { return }

        applyCompositionTransition(hangeulAdapter.restoreDeletePan(character))
        updateHangeulSpaceButton()
    }

    open override func deleteButtonPanDidStop() {
        super.deleteButtonPanDidStop()
        if modeCoordinator.currentMode == .hangeul {
            hangeulAdapter.finishDeletePan()
        }
    }
}

// MARK: - Language Mode

private extension HangeulEnglishKeyboardCoreViewController {
    var languageSwitchButtons: [LanguageSwitchButton] {
        primaryKeyboardViews.compactMap(\.languageSwitchButton)
        + [
            symbolKeyboardView.languageSwitchButton,
            numericKeyboardView.languageSwitchButton
        ].compactMap { $0 }
    }

    /// 저장된 마지막 언어. 한 번도 저장된 적이 없으면 `nil`
    static func storedLanguageMode() -> HangeulEnglishLanguageMode? {
        let manager = UserDefaultsManager.shared
        guard manager.hasLastHangeulEnglishLanguageMode else { return nil }

        return manager.lastHangeulEnglishLanguageMode
    }

    func setupLanguageSwitchActions() {
        languageSwitchButtons.forEach { button in
            button.addAction(
                UIAction { [weak self] _ in
                    guard let self else { return }
                    let newMode: HangeulEnglishLanguageMode =
                        modeCoordinator.currentMode == .hangeul ? .english : .hangeul
                    applyLanguageMode(newMode, persist: true, isManualSwitch: true)
                },
                for: .touchUpInside
            )
        }
    }

    func applyLanguageMode(
        _ mode: HangeulEnglishLanguageMode,
        persist: Bool,
        outgoingMode: HangeulEnglishLanguageMode? = nil,
        isManualSwitch: Bool = false
    ) {
        let previousMode = outgoingMode ?? modeCoordinator.currentMode

        stopInputInteractionsForLanguageChange()
        switch previousMode {
        case .hangeul:
            hangeulAdapter.finishForLanguageChange()
            commitDeferredUndoRedoGroupIfNeeded()
        case .english:
            englishAdapter.finishForLanguageChange()
        }

        modeCoordinator.selectModeManually(mode)
        if persist {
            keyboardSettingsManager.lastHangeulEnglishLanguageMode = mode
        }
        primaryLanguage = mode.languageIdentifier
        updateSuggestionLanguage(to: mode.languageIdentifier)

        languageSwitchButtons.forEach {
            $0.updateLanguageMode(mode)
        }
        symbolKeyboardView.switchButton.updatePrimaryLanguageMode(mode)
        numericKeyboardView.switchButton.updatePrimaryLanguageMode(mode)

        if KeyboardLanguageModePolicy.shouldReturnToPrimaryKeyboard(
            isManualSwitch: isManualSwitch,
            currentKeyboard: currentKeyboard
        ) {
            currentKeyboard = primaryKeyboardView.keyboard
        }

        updateShiftButtonForCurrentMode()
        updateHangeulSpaceButton()
    }
}

// MARK: - Adapter Routing

private extension HangeulEnglishKeyboardCoreViewController {
    func applyCompositionTransition(_ transition: HangeulCompositionTransition?) {
        guard let transition else { return }

        for proxyEdit in transition.proxyEdits {
            switch proxyEdit {
            case .none:
                break
            case .insert(let text):
                insertText(text)
            case .delete(let count):
                if count == 1 {
                    deleteText()
                } else {
                    replaceText(deleteCount: count, insert: "")
                }
            case .replace(let deleteCount, let insertText):
                replaceText(deleteCount: deleteCount, insert: insertText)
            }
        }

        updateHangeulSpaceButton()
    }

    func updateShiftButtonForCurrentMode() {
        switch modeCoordinator.currentMode {
        case .hangeul:
            updateHangeulShiftButton()
        case .english:
            updateEnglishShiftButton()
        }
    }

    func updateHangeulSpaceButton() {
        hangeulAdapter.updateSpaceButtonImage()
    }

    func updateHangeulShiftButton() {
        guard !buttonStateController.isShiftButtonPressed else { return }
        hangeulAdapter.resetShiftState()
    }

    func updateEnglishShiftButton() {
        let isShiftButtonPressed = buttonStateController.isShiftButtonPressed
        englishAdapter.updateAutocapitalization(
            type: textDocument.autocapitalizationType ?? .none,
            documentContextBeforeInput: textDocument.documentContextBeforeInput,
            isEnabled: keyboardSettingsManager.isAutoCapitalizationEnabled,
            isShiftButtonPressed: isShiftButtonPressed
        )
    }
}
```

- [x] **Step 4: `project.pbxproj`에 타깃 추가**

새 object ID는 모두 `5BD0A1xx2FF2C0000064DC60` 꼴이다. 기존 ID와 겹치지 않는다(`grep -c 5BD0A1 project.pbxproj`가 0이어야 한다). 각 블록은 해당 section의 `/* End … section */` 줄 **바로 앞**에 넣는다. Xcode가 다음 저장 때 ID 순서로 재정렬하므로 위치는 문제 되지 않는다.

| 역할 | ID |
|---|---|
| PBXNativeTarget `HangeulEnglishKeyboardCore` | `5BD0A1012FF2C0000064DC60` |
| PBXFileReference `HangeulEnglishKeyboardCore.framework` | `5BD0A1022FF2C0000064DC60` |
| Headers / Sources / Frameworks / Resources 단계 | `5BD0A103…` / `5BD0A104…` / `5BD0A105…` / `5BD0A106…` |
| XCConfigurationList / Debug / Release | `5BD0A107…` / `5BD0A108…` / `5BD0A109…` |
| `Modules` exception set (새 타깃) | `5BD0A10A2FF2C0000064DC60` |
| 새 타깃 → SYKeyboardCore: proxy / dependency / buildFile | `5BD0A10B…` / `5BD0A10C…` / `5BD0A10D…` |
| 새 타깃 → HangeulKeyboardCore: proxy / dependency / buildFile | `5BD0A10E…` / `5BD0A10F…` / `5BD0A110…` |
| 새 타깃 → EnglishKeyboardCore: proxy / dependency / buildFile | `5BD0A111…` / `5BD0A112…` / `5BD0A113…` |
| SYKeyboard 앱 → 새 타깃: proxy / dependency / buildFile | `5BD0A114…` / `5BD0A115…` / `5BD0A116…` |
| HangeulEnglishKeyboard ext → 새 타깃: proxy / dependency / buildFile | `5BD0A117…` / `5BD0A118…` / `5BD0A119…` |

(`…`는 `2FF2C0000064DC60`.)

**4-a. `/* End PBXBuildFile section */` 앞에 추가**

```
		5BD0A10D2FF2C0000064DC60 /* SYKeyboardCore.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 5BB373512ED5AA18006AB083 /* SYKeyboardCore.framework */; };
		5BD0A1102FF2C0000064DC60 /* HangeulKeyboardCore.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 5BB373DA2ED5DADC006AB083 /* HangeulKeyboardCore.framework */; };
		5BD0A1132FF2C0000064DC60 /* EnglishKeyboardCore.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 5BB373AA2ED5D937006AB083 /* EnglishKeyboardCore.framework */; };
		5BD0A1162FF2C0000064DC60 /* HangeulEnglishKeyboardCore.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 5BD0A1022FF2C0000064DC60 /* HangeulEnglishKeyboardCore.framework */; };
		5BD0A1192FF2C0000064DC60 /* HangeulEnglishKeyboardCore.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 5BD0A1022FF2C0000064DC60 /* HangeulEnglishKeyboardCore.framework */; };
```

**4-b. `/* End PBXContainerItemProxy section */` 앞에 추가**

```
		5BD0A10B2FF2C0000064DC60 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 5B7B3F4E2C569B7800F7C093 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 5BB373502ED5AA18006AB083;
			remoteInfo = SYKeyboardCore;
		};
		5BD0A10E2FF2C0000064DC60 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 5B7B3F4E2C569B7800F7C093 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 5BB373D92ED5DADC006AB083;
			remoteInfo = HangeulKeyboardCore;
		};
		5BD0A1112FF2C0000064DC60 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 5B7B3F4E2C569B7800F7C093 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 5BB373A92ED5D937006AB083;
			remoteInfo = EnglishKeyboardCore;
		};
		5BD0A1142FF2C0000064DC60 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 5B7B3F4E2C569B7800F7C093 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 5BD0A1012FF2C0000064DC60;
			remoteInfo = HangeulEnglishKeyboardCore;
		};
		5BD0A1172FF2C0000064DC60 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 5B7B3F4E2C569B7800F7C093 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 5BD0A1012FF2C0000064DC60;
			remoteInfo = HangeulEnglishKeyboardCore;
		};
```

**4-c. `/* End PBXFileReference section */` 앞에 추가**

```
		5BD0A1022FF2C0000064DC60 /* HangeulEnglishKeyboardCore.framework */ = {isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = HangeulEnglishKeyboardCore.framework; sourceTree = BUILT_PRODUCTS_DIR; };
```

**4-d. `/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */` 앞에 추가**

```
		5BD0A10A2FF2C0000064DC60 /* Exceptions for "Modules" folder in "HangeulEnglishKeyboardCore" target */ = {
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
				HangeulEnglishKeyboardCore/Presentation/ViewController/HangeulEnglishKeyboardCoreViewController.swift,
			);
			target = 5BD0A1012FF2C0000064DC60 /* HangeulEnglishKeyboardCore */;
		};
```

같은 section의 `5BCECD522F26C3B800A7F562 /* Exceptions for "Modules" folder in "SYKeyboard" target */` 블록 `membershipExceptions` 안, `"EnglishKeyboardCore/Storage/UserDefaultsManager+Extension.swift",` 줄 **뒤**(알파벳 순서상 `EnglishKeyboardCore/…` 다음, `HangeulKeyboardCore/…` 앞)에 추가:

```
				HangeulEnglishKeyboardCore/Presentation/ViewController/HangeulEnglishKeyboardCoreViewController.swift,
```

이 목록은 앱 타깃이 `Modules` 그룹을 소유하므로 **제외** 목록이다. 빠뜨리면 앱이 이 파일을 직접 컴파일한다.

**4-e. `5BCECC832F26C3A900A7F562 /* Modules */` 그룹의 `exceptions` 목록 끝에 추가**

```
				5BD0A10A2FF2C0000064DC60 /* Exceptions for "Modules" folder in "HangeulEnglishKeyboardCore" target */,
```

**4-f. `/* End PBXFrameworksBuildPhase section */` 앞에 추가**

```
		5BD0A1052FF2C0000064DC60 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				5BD0A10D2FF2C0000064DC60 /* SYKeyboardCore.framework in Frameworks */,
				5BD0A1102FF2C0000064DC60 /* HangeulKeyboardCore.framework in Frameworks */,
				5BD0A1132FF2C0000064DC60 /* EnglishKeyboardCore.framework in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
```

같은 section의 앱 Frameworks 단계 `5B7B3F532C569B7800F7C093 /* Frameworks */`의 `files` 끝에:

```
				5BD0A1162FF2C0000064DC60 /* HangeulEnglishKeyboardCore.framework in Frameworks */,
```

extension Frameworks 단계 `5BC304102FF15A030064DC60 /* Frameworks */`의 `files` 끝에:

```
				5BD0A1192FF2C0000064DC60 /* HangeulEnglishKeyboardCore.framework in Frameworks */,
```

**4-g. `5B7B3F572C569B7800F7C093 /* Products */` 그룹 `children` 끝에 추가**

```
				5BD0A1022FF2C0000064DC60 /* HangeulEnglishKeyboardCore.framework */,
```

**4-h. Headers / Sources / Resources 단계** — 각각 `/* End PBXHeadersBuildPhase section */`, `/* End PBXSourcesBuildPhase section */`, `/* End PBXResourcesBuildPhase section */` 앞에:

```
		5BD0A1032FF2C0000064DC60 /* Headers */ = {
			isa = PBXHeadersBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
```

```
		5BD0A1042FF2C0000064DC60 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
```

```
		5BD0A1062FF2C0000064DC60 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
```

**4-i. `/* End PBXNativeTarget section */` 앞에 추가**

```
		5BD0A1012FF2C0000064DC60 /* HangeulEnglishKeyboardCore */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 5BD0A1072FF2C0000064DC60 /* Build configuration list for PBXNativeTarget "HangeulEnglishKeyboardCore" */;
			buildPhases = (
				5BD0A1032FF2C0000064DC60 /* Headers */,
				5BD0A1042FF2C0000064DC60 /* Sources */,
				5BD0A1052FF2C0000064DC60 /* Frameworks */,
				5BD0A1062FF2C0000064DC60 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				5BD0A10C2FF2C0000064DC60 /* PBXTargetDependency */,
				5BD0A10F2FF2C0000064DC60 /* PBXTargetDependency */,
				5BD0A1122FF2C0000064DC60 /* PBXTargetDependency */,
			);
			name = HangeulEnglishKeyboardCore;
			productName = HangeulEnglishKeyboardCore;
			productReference = 5BD0A1022FF2C0000064DC60 /* HangeulEnglishKeyboardCore.framework */;
			productType = "com.apple.product-type.framework";
		};
```

같은 section의 앱 타깃 `5B7B3F552C569B7800F7C093 /* SYKeyboard */` `dependencies` 끝에:

```
				5BD0A1152FF2C0000064DC60 /* PBXTargetDependency */,
```

extension 타깃 `5BC304122FF15A030064DC60 /* HangeulEnglishKeyboard */` `dependencies` 끝에:

```
				5BD0A1182FF2C0000064DC60 /* PBXTargetDependency */,
```

**4-j. PBXProject section** — `TargetAttributes` 끝(`5BC304122FF15A030064DC60 = { … };` 뒤)에:

```
					5BD0A1012FF2C0000064DC60 = {
						CreatedOnToolsVersion = 27.0;
					};
```

`targets` 목록 끝에:

```
				5BD0A1012FF2C0000064DC60 /* HangeulEnglishKeyboardCore */,
```

**4-k. `/* End PBXTargetDependency section */` 앞에 추가**

```
		5BD0A10C2FF2C0000064DC60 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 5BB373502ED5AA18006AB083 /* SYKeyboardCore */;
			targetProxy = 5BD0A10B2FF2C0000064DC60 /* PBXContainerItemProxy */;
		};
		5BD0A10F2FF2C0000064DC60 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 5BB373D92ED5DADC006AB083 /* HangeulKeyboardCore */;
			targetProxy = 5BD0A10E2FF2C0000064DC60 /* PBXContainerItemProxy */;
		};
		5BD0A1122FF2C0000064DC60 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 5BB373A92ED5D937006AB083 /* EnglishKeyboardCore */;
			targetProxy = 5BD0A1112FF2C0000064DC60 /* PBXContainerItemProxy */;
		};
		5BD0A1152FF2C0000064DC60 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 5BD0A1012FF2C0000064DC60 /* HangeulEnglishKeyboardCore */;
			targetProxy = 5BD0A1142FF2C0000064DC60 /* PBXContainerItemProxy */;
		};
		5BD0A1182FF2C0000064DC60 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 5BD0A1012FF2C0000064DC60 /* HangeulEnglishKeyboardCore */;
			targetProxy = 5BD0A1172FF2C0000064DC60 /* PBXContainerItemProxy */;
		};
```

**4-l. `/* End XCBuildConfiguration section */` 앞에 추가** — `EnglishKeyboardCore`의 Debug(`5BB373B52ED5D937006AB083`)·Release(`5BB373B62ED5D937006AB083`) 블록을 그대로 복사하되 ID와 `PRODUCT_BUNDLE_IDENTIFIER`만 바꾼다. Debug는 `DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";`과 `ENABLE_DEBUG_DYLIB = YES;`가 있고 Release에는 없다.

```
		5BD0A1082FF2C0000064DC60 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUILD_LIBRARY_FOR_DISTRIBUTION = NO;
				CODE_SIGN_IDENTITY = "";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				DYLIB_COMPATIBILITY_VERSION = 1;
				DYLIB_CURRENT_VERSION = 1;
				DYLIB_INSTALL_NAME_BASE = "@rpath";
				ENABLE_DEBUG_DYLIB = YES;
				ENABLE_MODULE_VERIFIER = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				INSTALL_PATH = "$(LOCAL_LIBRARY_DIR)/Frameworks";
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@loader_path/Frameworks",
				);
				MACH_O_TYPE = staticlib;
				MARKETING_VERSION = 1.0;
				MODULE_VERIFIER_SUPPORTED_LANGUAGES = "objective-c objective-c++";
				MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS = "gnu17 gnu++20";
				PRODUCT_BUNDLE_IDENTIFIER = com.snmac.HangeulEnglishKeyboardCore;
				PRODUCT_NAME = "$(TARGET_NAME:c99extidentifier)";
				SKIP_INSTALL = YES;
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_INSTALL_MODULE = YES;
				SWIFT_INSTALL_OBJC_HEADER = NO;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				VERSIONING_SYSTEM = "apple-generic";
				VERSION_INFO_PREFIX = "";
			};
			name = Debug;
		};
		5BD0A1092FF2C0000064DC60 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUILD_LIBRARY_FOR_DISTRIBUTION = NO;
				CODE_SIGN_IDENTITY = "";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DYLIB_COMPATIBILITY_VERSION = 1;
				DYLIB_CURRENT_VERSION = 1;
				DYLIB_INSTALL_NAME_BASE = "@rpath";
				ENABLE_MODULE_VERIFIER = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				INSTALL_PATH = "$(LOCAL_LIBRARY_DIR)/Frameworks";
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@loader_path/Frameworks",
				);
				MACH_O_TYPE = staticlib;
				MARKETING_VERSION = 1.0;
				MODULE_VERIFIER_SUPPORTED_LANGUAGES = "objective-c objective-c++";
				MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS = "gnu17 gnu++20";
				PRODUCT_BUNDLE_IDENTIFIER = com.snmac.HangeulEnglishKeyboardCore;
				PRODUCT_NAME = "$(TARGET_NAME:c99extidentifier)";
				SKIP_INSTALL = YES;
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_INSTALL_MODULE = YES;
				SWIFT_INSTALL_OBJC_HEADER = NO;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				VERSIONING_SYSTEM = "apple-generic";
				VERSION_INFO_PREFIX = "";
			};
			name = Release;
		};
```

**4-m. `/* End XCConfigurationList section */` 앞에 추가**

```
		5BD0A1072FF2C0000064DC60 /* Build configuration list for PBXNativeTarget "HangeulEnglishKeyboardCore" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				5BD0A1082FF2C0000064DC60 /* Debug */,
				5BD0A1092FF2C0000064DC60 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
```

**4-n. 정합성 확인**

```sh
plutil -lint SYKeyboard.xcodeproj/project.pbxproj
xcodebuild -list -project SYKeyboard.xcodeproj | grep -A12 "Targets:"
grep -c "5BD0A1" SYKeyboard.xcodeproj/project.pbxproj
```

기대: `OK`, Targets에 `HangeulEnglishKeyboardCore`가 보임, 새 ID가 든 줄 수 57(블록 머리 25줄 + 블록 안·목록 안 참조 32줄). 숫자가 다르면 빠진 참조가 있다.

- [x] **Step 5: 테스트가 통과하는지 확인**

Step 2와 같은 명령을 `task1-green.log`로 실행한다.

기대: `Test case '…testTextWillChangeReadsShiftContextOnceInEnglishMode()' passed`, `** TEST SUCCEEDED **`. `Test case` 줄이 없으면 suite 이름 필터가 틀린 것이다.

- [x] **Step 6: 앱 스킴 전체 테스트 빌드로 중복 심볼·누락 등록 확인**

```sh
xcodebuild build-for-testing -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  > "$SCRATCH/task1-app-build.log" 2>&1; grep -E "error:|warning: .*HangeulEnglishKeyboardCore|BUILD" "$SCRATCH/task1-app-build.log" | tail -5
```

기대: `** TEST BUILD SUCCEEDED **`, `duplicate symbol`·`cannot find … in scope` 없음.

- [x] **Step 7: 스킴 부수 효과 되돌리고 커밋**

```sh
git status --short
# .xcscheme이 보이면 RemotePath만 바뀐 것인지 git diff로 확인 후
# git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme
git branch --show-current
git add Modules/HangeulEnglishKeyboardCore SYKeyboardTests/Controller/HangeulEnglishKeyboardCoreViewControllerProxyReadTests.swift SYKeyboard.xcodeproj/project.pbxproj docs/superpowers/plans/2026-10-09-hangeul-english-keyboard-core-vc-extraction.md
git commit -m "refactor: #190 - HangeulEnglishKeyboardCore 모듈과 Core VC 추가

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

**결과 기록 (2026-10-09):**
- RED: `task1-red.log` — `error: Unable to resolve module dependency: 'HangeulEnglishKeyboardCore'`, `** TEST FAILED **`
- pbxproj: `plutil -lint` OK, `xcodebuild -list`에 `HangeulEnglishKeyboardCore` 표시, `5BD0A1` 줄 수 57
- GREEN: `task1-green.log` — `testTextWillChangeReadsShiftContextOnceInEnglishMode()` passed, `** TEST SUCCEEDED **`
- 앱 빌드: `build-for-testing` `** TEST BUILD SUCCEEDED **`, duplicate symbol·cannot find 없음, `.xcscheme` 변경 없음

---

### Task 2: extension VC를 Firebase·메모리 경고만 가진 leaf로 축소

**Files:**
- Modify: `Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift` (전체 교체)

**Interfaces:**
- Consumes: Task 1의 `HangeulEnglishKeyboardCoreViewController`, `public init()`, `open func languageModeDecisionDidResolve(requiresLatinInput:resolved:)`
- Produces: 없음(extension 진입점)

- [x] **Step 1: leaf 파일 교체**

`HangeulKeyboardViewController.swift`와 같은 틀이다. 훅 오버라이드 본문은 옮기기 전 `recordLanguageModeDecision` 본문 그대로다.

```swift
//
//  HangeulEnglishKeyboardViewController.swift
//  HangeulEnglishKeyboard
//
//  Created by 서동환 on 6/28/26.
//

import UIKit
import OSLog

import HangeulEnglishKeyboardCore
import SYKeyboardCore

import FirebaseCore
import FirebaseCrashlytics

/// 한영 통합 키보드 입력/UI 컨트롤러
final class HangeulEnglishKeyboardViewController: HangeulEnglishKeyboardCoreViewController {

    // MARK: - Properties

    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )

    // MARK: - Initializer

    override init() {
        super.init()

        // loadView와 viewDidLoad에서 발생하는 크래시도 기록되도록 가장 먼저 설정한다
        setupFirebase()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        let message = "Memory Warning Received in \(Bundle.main.bundleIdentifier ?? "Unknown Bundle")"
        logger.fault("\(message)")
        Crashlytics.crashlytics().log(message)
        Crashlytics.crashlytics().setCustomValue(true, forKey: "did_receive_memory_warning")
    }

    // MARK: - Override Methods

    /// 시작 언어 판정 근거를 기록한다.
    /// 입력한 텍스트는 남기지 않고 필드 특성만 남긴다
    override func languageModeDecisionDidResolve(
        requiresLatinInput: Bool,
        resolved: HangeulEnglishLanguageMode
    ) {
        let language = textDocument.documentInputMode?.primaryLanguage ?? "nil"
        let keyboardType = textDocument.keyboardType?.rawValue ?? -1
        let contentType = textDocument.textContentType?.rawValue ?? "nil"
        let message = "languageMode documentPrimaryLanguage=\(language)"
        + " keyboardType=\(keyboardType) textContentType=\(contentType)"
        + " requiresLatinInput=\(requiresLatinInput) resolved=\(resolved)"

        logger.info("\(message)")
        Crashlytics.crashlytics().setCustomValue(language, forKey: "document_primary_language")
        Crashlytics.crashlytics().log(message)
    }
}

// MARK: - Private Methods

private extension HangeulEnglishKeyboardViewController {
    func setupFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        Crashlytics.crashlytics().setUserID(
            UIDevice.current.identifierForVendor?.uuidString
        )

        // 진단 기록 연결. 입력한 텍스트는 전달되지 않는다(`KeyboardDiagnostics` 참고)
        KeyboardDiagnostics.record = { message in
            Crashlytics.crashlytics().log(message)
        }
    }
}
```

- [x] **Step 2: 옮기기 전 파일과 Core VC의 diff가 예상 목록과 일치하는지 확인**

```sh
diff <(git show b1391416:Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift) \
     Modules/HangeulEnglishKeyboardCore/Presentation/ViewController/HangeulEnglishKeyboardCoreViewController.swift \
  | grep -E "^[<>]" | grep -vE "^[<>]\s+(open )?override " > "$SCRATCH/task2-diff.txt"; cat "$SCRATCH/task2-diff.txt"
```

`override`가 `open override`로 바뀐 줄을 거르고 남는 차이가 **다음뿐**이어야 한다. 다른 줄이 남으면 로직이 바뀐 것이므로 되돌린다.

- 헤더 주석 5줄(파일명·모듈·작성자)
- `import OSLog`, `import FirebaseCore`, `import FirebaseCrashlytics` 삭제
- 클래스 doc 주석 2줄 추가, `final class … : BaseKeyboardViewController` → `open class … : BaseKeyboardViewController`
- `logger` 프로퍼티 4줄 삭제
- `init()` → `public init()`, `required init?(coder:)` → `@MainActor required public init?(coder:)`
- `setupFirebase()` 호출과 그 앞 주석 삭제
- `didReceiveMemoryWarning()` 메서드 삭제(`// MARK: - Lifecycle` 아래 블록)
- `// MARK: - Diagnostics Hook`과 `languageModeDecisionDidResolve` 선언 추가
- `recordLanguageModeDecision(requiresLatinInput: requiresLatinInput, resolved: mode)` → `languageModeDecisionDidResolve(requiresLatinInput: requiresLatinInput, resolved: mode)`
  — 이 줄이 `applyLanguageMode(` 호출 앞에 그대로 있는지 눈으로 확인한다(Review Focus 4)
- `recordLanguageModeDecision` 메서드와 doc 주석 삭제
- `setupFirebase()` 정의와 `// MARK: - Private Methods` extension 삭제

- [x] **Step 3: extension 스킴 빌드와 관련 테스트**

```sh
xcodebuild build -project SYKeyboard.xcodeproj -scheme HangeulEnglishKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  > "$SCRATCH/task2-ext-build.log" 2>&1; grep -E "error:|BUILD" "$SCRATCH/task2-ext-build.log" | tail -3
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/HangeulEnglishKeyboardCoreViewControllerProxyReadTests \
  -only-testing:SYKeyboardTests/HangeulEnglishKeyboardModeCoordinatorTests \
  > "$SCRATCH/task2-test.log" 2>&1; grep -E "Test case .* (passed|failed)|TEST" "$SCRATCH/task2-test.log" | tail -8
```

기대: `** BUILD SUCCEEDED **`, 모든 `Test case … passed`, `** TEST SUCCEEDED **`.

- [x] **Step 4: 스킴 부수 효과 되돌리고 커밋**

```sh
git status --short   # .xcscheme RemotePath만 바뀌었으면 checkout으로 되돌림
git branch --show-current
git add Keyboards/HangeulEnglishKeyboard/Presentation/HangeulEnglishKeyboardViewController.swift docs/superpowers/plans/2026-10-09-hangeul-english-keyboard-core-vc-extraction.md
git commit -m "refactor: #190 - 한영 extension VC를 Core VC를 상속하는 Firebase 설정 전용 leaf로 축소

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

**결과 기록 (2026-10-09):**
- diff 잔여 항목: `task2-diff.txt` — 헤더 5줄, `import OSLog`/`FirebaseCore`/`FirebaseCrashlytics` 삭제, 클래스 doc 2줄·`open class`, `logger` 4줄, `public init()`, `setupFirebase()` 호출·주석, `@MainActor required public init?(coder:)`, `didReceiveMemoryWarning` 블록, 훅 선언, 훅 호출 교체(`applyLanguageMode` 앞 유지), `recordLanguageModeDecision` 정의, extension 이름 2곳, `setupFirebase` extension. 예상 목록 밖 줄 없음
- 빌드·테스트: `HangeulEnglishKeyboard` 스킴 `** BUILD SUCCEEDED **`; ProxyRead + ModeCoordinator 테스트 7개 passed, `** TEST SUCCEEDED **`; `.xcscheme` 변경 없음

---

### Task 3: VC 해제 테스트

**Files:**
- Modify: `SYKeyboardTests/Controller/HangeulEnglishKeyboardCoreViewControllerProxyReadTests.swift`

**Interfaces:**
- Consumes: Task 1의 테스트 helper `TestHangeulEnglishProxyReadViewController`, `withLastLanguageMode(_:_:)`, `PrimaryKeyboardRepresentable.languageSwitchButton`
- Produces: 없음

- [x] **Step 1: 해제 테스트 추가**

suite 안 첫 테스트 뒤에 추가한다. 한/A 전환 버튼을 실제로 눌러 `setupLanguageSwitchActions()`의 `UIAction` 클로저 경로를 지나게 한다.

```swift
    @Test("한/A 전환과 textWillChange를 거친 VC는 참조를 놓으면 해제됨")
    func testControllerIsReleased() {
        weak var weakController: TestHangeulEnglishProxyReadViewController?
        withLastLanguageMode(.hangeul) {
            autoreleasepool {
                let controller = TestHangeulEnglishProxyReadViewController()
                let window = UIWindow(frame: UIScreen.main.bounds)
                window.addSubview(controller.view)

                // 한/A 전환은 UIAction 클로저를 지나며 마지막 언어를 저장한다(withLastLanguageMode가 되돌림)
                controller.primaryKeyboardView.languageSwitchButton?.sendActions(for: .touchUpInside)
                controller.textWillChange(nil)
                controller.view.removeFromSuperview()
                weakController = controller
            }
            // 창에 올렸던 VC는 UIKit이 예약한 main queue 작업이 끝난 뒤 해제되므로 런루프를 한 번 돌린다
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        }

        #expect(weakController == nil)
    }
```

- [x] **Step 2: 테스트 실행**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/HangeulEnglishKeyboardCoreViewControllerProxyReadTests \
  > "$SCRATCH/task3-test.log" 2>&1; grep -E "Test case .* (passed|failed)|TEST" "$SCRATCH/task3-test.log" | tail -5
```

기대: `Test case` 2개 `passed`. `testControllerIsReleased`가 실패하면 순환 참조가 생긴 것이다. `languageSwitchButton`이 `nil`이라 `sendActions`가 안 불렸을 가능성도 있으니, 실패 시 `#expect(controller.primaryKeyboardView.languageSwitchButton != nil)`을 임시로 넣어 구분한다.

- [x] **Step 3: 커밋**

```sh
git status --short
git branch --show-current
git add SYKeyboardTests/Controller/HangeulEnglishKeyboardCoreViewControllerProxyReadTests.swift docs/superpowers/plans/2026-10-09-hangeul-english-keyboard-core-vc-extraction.md
git commit -m "test: #190 - 한영 Core VC 해제 테스트 추가

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

**결과 기록 (2026-10-09):**
- 테스트: `task3-test.log` — `testControllerIsReleased()` passed, `testTextWillChangeReadsShiftContextOnceInEnglishMode()` passed, `** TEST SUCCEEDED **`. 누수 부재를 지키는 테스트라 RED 단계는 없음(실패 조건이 순환 참조 주입)

---

### Task 4: 문서 갱신

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md` (classDiagram)
- Modify: `docs/architecture/전체 아키텍처.md`
- Modify: `docs/architecture/한영 통합 키보드.md`
- Modify: `docs/architecture/한글 입력 로직.md`

**Interfaces:** 없음

- [ ] **Step 1: `CLAUDE.md`**

프로젝트 개요, `- 영문 키보드 로직은 \`Modules/EnglishKeyboardCore/\`에 있다.` 뒤에 추가:

```
- 한영 통합 키보드 VC는 `Modules/HangeulEnglishKeyboardCore/`에 있으며 한글·영문 Core의 Adapter를 함께 쓴다.
```

아키텍처 트리:

```
    └── HangeulEnglishKeyboardViewController   (Core VC 없이 Base를 직접 상속)
```
→
```
    └── HangeulEnglishKeyboardCoreViewController → HangeulEnglishKeyboardViewController
```

한영 통합 키보드 문단:

```
`HangeulEnglishKeyboardViewController`가 두 Adapter를 함께 들고,
```
→
```
`HangeulEnglishKeyboardCoreViewController`(`HangeulEnglishKeyboardCore`)가 두 Adapter를 함께 들고,
```

같은 문단 끝(`(전환 버튼·레이아웃 갱신이 이 차이에 의존한다).` 뒤)에 추가:

```
Core 모듈은 Firebase를 모르므로 시작 언어 판정 기록은 빈 `open` 훅 `languageModeDecisionDidResolve(requiresLatinInput:resolved:)`로
내보내고, extension의 `HangeulEnglishKeyboardViewController`가 오버라이드해 Crashlytics에 남긴다.
```

주요 디렉터리, `- \`Modules/EnglishKeyboardCore/\`: 영문 키보드 View와 저장소 확장.` 뒤에 추가:

```
- `Modules/HangeulEnglishKeyboardCore/`: 한영 통합 키보드 Core VC. 두 Core의 Adapter와 `SYKeyboardCore`의 `HangeulEnglishKeyboardModeCoordinator`를 조합한다.
```

빌드와 테스트, `세 모듈 타깃이 한 폴더를 공유하므로` → `네 모듈 타깃이 한 폴더를 공유하므로`.

- [ ] **Step 2: `README.md` classDiagram**

`namespace ParentKeyboardViewController` 블록에 `class HangeulEnglishKeyboardCoreViewController` 추가.

```
    BaseKeyboardViewController <|-- HangeulEnglishKeyboardViewController: Inheritance
```
→
```
    BaseKeyboardViewController <|-- HangeulEnglishKeyboardCoreViewController: Inheritance
```

`EnglishKeyboardCoreViewController <|-- EnglishKeyboardViewController: Inheritance` 뒤에 추가:

```
    HangeulEnglishKeyboardCoreViewController <|-- HangeulEnglishKeyboardViewController: Inheritance
```

Composition 3줄의 `HangeulEnglishKeyboardViewController *--` → `HangeulEnglishKeyboardCoreViewController *--`.

- [ ] **Step 3: `docs/architecture/전체 아키텍처.md`**

모듈 표, `EnglishKeyboardCore` 행 뒤에 추가:

```
| `HangeulEnglishKeyboardCore` | `Modules/HangeulEnglishKeyboardCore/` | 한영 통합 키보드 Core VC(두 Core의 Adapter + `HangeulEnglishKeyboardModeCoordinator`) |
```

`세 모듈 타깃이 한 폴더를 공유하므로` → `네 모듈 타깃이 한 폴더를 공유하므로`.

런타임 구조 트리:

```
    └── HangeulEnglishKeyboardViewController       (Core VC 없이 Base를 직접 상속, Adapter 2개 보유)
```
→
```
    └── HangeulEnglishKeyboardCoreViewController   (HangeulEnglishKeyboardCore, Adapter 2개 보유)
        └── HangeulEnglishKeyboardViewController   (HangeulEnglishKeyboard extension 진입점)
```

Adapter 흐름:

```
HangeulEnglishKeyboardViewController ──▶ 두 Adapter를 함께 보유, HangeulEnglishKeyboardModeCoordinator가 언어 결정
```
→
```
HangeulEnglishKeyboardCoreViewController ──▶ 두 Adapter를 함께 보유, HangeulEnglishKeyboardModeCoordinator가 언어 결정
```

- [ ] **Step 4: `docs/architecture/한영 통합 키보드.md`**

3행: `` `HangeulEnglishKeyboardViewController`의 구조를 정리한다. `` → `` `HangeulEnglishKeyboardCoreViewController`의 구조를 정리한다. ``

구조 절 첫 문단:

```
한영 통합 키보드는 별도의 Core VC 없이 `BaseKeyboardViewController`를 직접 상속하고,
한글/영문 키보드의 InputAdapter를 **둘 다** 들고 있다. 새 입력 로직을 만들지 않고
단일 언어 키보드가 쓰는 Adapter를 그대로 재사용하는 구조다.
```
→
```
한영 통합 키보드의 Core VC `HangeulEnglishKeyboardCoreViewController`(`Modules/HangeulEnglishKeyboardCore/`)는
`BaseKeyboardViewController`를 상속하고 한글/영문 키보드의 InputAdapter를 **둘 다** 들고 있다. 새 입력 로직을 만들지 않고
단일 언어 키보드가 쓰는 Adapter를 그대로 재사용하는 구조다. extension의 `HangeulEnglishKeyboardViewController`는
이를 상속해 Firebase 설정·메모리 경고 로그·시작 언어 판정 기록(`languageModeDecisionDidResolve` 훅 오버라이드)만 맡는다.
```

트리 첫 줄: `HangeulEnglishKeyboardViewController (Keyboards/HangeulEnglishKeyboard/Presentation/)` → `HangeulEnglishKeyboardCoreViewController (Modules/HangeulEnglishKeyboardCore/Presentation/ViewController/)`.

문서 나머지에서 `HangeulEnglishKeyboardViewController`를 `grep -n`으로 찾아, 입력 로직을 가리키는 곳은 `HangeulEnglishKeyboardCoreViewController`로 바꾸고 Firebase·진단을 가리키는 곳은 그대로 둔다.

- [ ] **Step 5: `docs/architecture/한글 입력 로직.md`**

```
한영 통합 키보드(`HangeulEnglishKeyboardViewController`)는 Core VC 없이 `HangeulKeyboardInputAdapter`를 직접 들고
같은 방식으로 Transition을 적용한다. → [한영 통합 키보드](한영%20통합%20키보드.md)
```
→
```
한영 통합 키보드(`HangeulEnglishKeyboardCoreViewController`, `Modules/HangeulEnglishKeyboardCore/`)는
`HangeulKeyboardInputAdapter`를 직접 들고 같은 방식으로 Transition을 적용한다. → [한영 통합 키보드](한영%20통합%20키보드.md)
```

- [ ] **Step 6: 남은 옛 문구 검색**

```sh
grep -rn "Core VC 없이\|세 모듈 타깃" CLAUDE.md README.md docs/architecture .github/copilot-instructions.md
```

기대: 출력 없음. `.github/copilot-instructions.md`에 모듈 목록이 직접 적혀 있으면 같은 식으로 고친다.

- [ ] **Step 7: 커밋**

```sh
git status --short
git branch --show-current
git add CLAUDE.md README.md docs/architecture docs/superpowers/plans/2026-10-09-hangeul-english-keyboard-core-vc-extraction.md
git commit -m "docs: #190 - 한영 통합 키보드 Core VC와 HangeulEnglishKeyboardCore 모듈 반영

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: 전체 검증과 시뮬레이터 확인

**Files:**
- Modify: `docs/superpowers/plans/2026-10-09-hangeul-english-keyboard-core-vc-extraction.md` (결과 기록)

**Interfaces:** 없음

- [ ] **Step 1: 전체 테스트**

```sh
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  > "$SCRATCH/task5-test.log" 2>&1
grep -cE "Test case .* passed" "$SCRATCH/task5-test.log"; grep -E "Test case .* failed|TEST (SUCCEEDED|FAILED)" "$SCRATCH/task5-test.log"
```

기대: `** TEST SUCCEEDED **`, failed 0. 통과 개수를 아래에 적는다(#185 직후 기준 1056 + 새 테스트 2).

- [ ] **Step 2: 4개 스킴 빌드**

```sh
for s in HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme $s \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    > "$SCRATCH/task5-build-$s.log" 2>&1; echo "$s: $(grep -E "BUILD (SUCCEEDED|FAILED)" "$SCRATCH/task5-build-$s.log")"
done
```

기대: 세 스킴 모두 `** BUILD SUCCEEDED **`. `SYKeyboard` 스킴은 Step 1이 빌드했다. 끝나면 `.xcscheme` `RemotePath`를 되돌린다.

- [ ] **Step 3: 시뮬레이터 입력 앱 확인**

`HangeulEnglishKeyboard` 스킴을 iPhone 13 mini / iOS 18.6에 설치하고 메모 또는 메시지 앱에서 확인한다. 항목마다 결과를 적는다.

1. 한/A 버튼으로 전환 → 자판만 바뀌고 후보 바·입력 중 단어가 유지됨
2. 한글 모드에서 "안녕" 입력 → 조합·확정 정상, 스페이스 버튼 이미지 갱신
3. 영어 모드에서 문장 첫 글자 → shift 자동 대문자
4. 영어 모드에서 이메일 필드(`textContentType = .emailAddress`. 웹 폼은 로컬 http 서버로 띄운 페이지가 안전하다)로 이동 → 자동으로 영어, 일반 필드로 돌아오면 마지막 언어 복원

- [ ] **Step 4: `deinit` 횟수 확인**

```sh
UDID=$(xcrun simctl list devices booted -j | python3 -c "import json,sys; d=json.load(sys.stdin)['devices']; print([x['udid'] for v in d.values() for x in v][0])")
pgrep -x HangeulEnglishKeyboard   # 떠 있는 extension 확인
xcrun simctl spawn $UDID log stream --level debug \
  --predicate 'subsystem == "github.com-SNMac.SYKeyboard.HangeulEnglishKeyboard" AND eventMessage CONTAINS "deinit"' > "$SCRATCH/deinit.log" &
# 키보드를 5회 내렸다 올린 뒤
grep -oE "(BaseKeyboardViewController|[A-Za-z]+Coordinator)[^]]*" "$SCRATCH/deinit.log" | sed -E 's/ <0x[0-9a-f]+>//' | sort | uniq -c
```

기대: VC 1종과 Coordinator 4종이 각 5회. `leaks`·Instruments는 시뮬레이터 extension에 붙지 않으므로 이 횟수 일치를 근거로 적는다.

- [ ] **Step 5: 결과 기록과 커밋**

이 문서의 각 Task 결과 기록을 채우고 커밋한다.

```sh
git branch --show-current
git add docs/superpowers/plans/2026-10-09-hangeul-english-keyboard-core-vc-extraction.md
git commit -m "docs: #190 - 전체 검증과 시뮬레이터 확인 결과 기록

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

**결과 기록:**
- 전체 테스트:
- 4 scheme 빌드:
- 시뮬레이터 확인 1\~4:
- deinit 횟수:

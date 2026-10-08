# BaseKeyboardViewController Coordinator 추출 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `BaseKeyboardViewController.swift`(3219줄)에서 후보 선택 처리·클립보드 기록·전체 접근 안내를 상태를 소유하는 별도 타입으로 옮겨, 동작은 그대로 두고 본 파일을 줄인다.

**Architecture:** VC가 `SuggestionSelectionCoordinator`와 `ClipboardHistoryCoordinator`를 강하게 소유하고, 두 Coordinator는 `weak` Host 프로토콜로 VC를 역참조한다. 함수 본문은 Coordinator로 가고 VC 콜백의 원래 자리에는 `coordinator.메서드()` 호출이 남아 호출 순서가 바뀌지 않는다. 전체 접근 안내는 새 타입 없이 `RequestFullAccessOverlayView.install(...)`과 `UIResponder` extension으로 옮긴다. 코드를 옮기기 전에 현재 동작을 고정하는 VC 테스트를 먼저 넣고, 옮긴 뒤 수정 없이 통과시킨다.

**Tech Stack:** Swift 5, UIKit, Swift Testing, Xcode 26 이상, 시뮬레이터 `iPhone 13 mini / iOS 18.6`

**Spec:** `docs/superpowers/specs/2026-10-08-base-keyboard-view-controller-coordinator-extraction-design.md`

## Global Constraints

- 기준 커밋 `develop` c68a3a1f. 작업 브랜치 `refactor/#184-extract-suggestion-clipboard-coordinators`(이미 생성, worktree 없음).
- 사용자에게 보이는 동작, 입력 흐름, 콜백 안의 호출 순서, 프록시 읽기 횟수를 바꾸지 않는다.
- Host 참조는 `weak`. 모든 진입점은 `guard let host else { return }`(값 반환은 `false`/`nil`)로 시작한다. `unowned` 금지.
- Coordinator는 `CachingTextDocumentProxy`를 만들지 않고 `host.textDocument`를 저장하지 않는다. 호출마다 `host.textDocument`로 접근한다.
- `textDocumentProxy` 직접 참조 금지. 확인: `grep -rn "textDocumentProxy" Modules Keyboards | grep -v -E ":[0-9]+:[[:space:]]*//"` 결과가 `BaseKeyboardViewController.swift`의 `textDocument`를 만드는 한 줄뿐.
- VC 저장 프로퍼티 중 `private`에서 `internal`로 바뀌는 것은 없다. Coordinator로 옮긴 프로퍼티는 VC에서 삭제한다.
- `Modules/`에 새 파일을 추가하면 `SYKeyboard.xcodeproj/project.pbxproj`의 `SYKeyboard`(target `5B7B3F552C569B7800F7C093`)와 `SYKeyboardCore`(target `5BB373502ED5AA18006AB083`) 두 membershipExceptions에 알파벳 순으로 등록한다. `+`가 든 경로는 큰따옴표로 감싼다. `SYKeyboardTests/`는 등록이 필요 없다.
- 테스트는 Swift Testing(`import Testing`, `@Suite`, `@Test`, `#expect`). UI 테스트 suite는 `@MainActor`, UserDefaults를 바꾸면 `.sharedUserDefaults` trait과 `defer` 복원.
- production 클래스에 `ForTesting` 메서드를 추가하지 않는다. `BaseKeyboardViewController.isPreview` static 플래그를 테스트에서 바꾸지 않는다(병렬 suite에 새어 나간다).
- 마크다운(계획·PR 본문·주석 문서)에서 범위 물결표는 `\~`로 쓴다. 백틱 안은 예외.
- 커밋 메시지: `test: #184 - …`, `refactor: #184 - …`, `docs: #184 - …`. 마침표 없음. 끝에 `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- 빌드·테스트 로그는 `/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad/` 아래 파일로 남기고 `tail`로 본다. `xcodebuild`는 foreground, timeout 600000.
- 테스트가 컴파일 오류 없이 `The test runner timed out while preparing to run tests`로 멈추면 코드 실패가 아니다. CLAUDE.md "붙여넣기 권한 알림" 절을 따라 시뮬레이터 화면을 확인한다.
- 키보드 extension scheme을 빌드한 뒤 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 것인지 확인하고 `git checkout -- <파일>`로 되돌린다.

## Review Focus

1. **VC가 해제된 뒤 도착한 pasteboard 알림·`DispatchQueue.main.async` 작업**: Coordinator가 `host.textDocument`나 Host 메서드에 닿지 않고 조용히 반환해야 한다. Task 3 Step 1, Task 4 Step 2의 "host가 해제된 뒤" 테스트가 고정한다.
2. **미리보기(`isPreview`) 모드에서 클립보드 버튼 탭과 후보 길게 누르기**: 패널이 열리거나 삭제 확인이 떠서는 안 된다. Task 3·4의 Fake Host `isPreviewMode = true` 테스트가 고정한다.
3. **`textWillChange` 안에서 후보 선택 처리의 trait 동기화가 `withReadCaching` 범위 안에서 같은 인스턴스를 읽는지**: Coordinator가 자기 프록시를 만들면 캐시가 깨진다. Task 1의 "수식 후보 탭 시 프록시 읽기 횟수" 테스트와 Task 5의 grep이 고정한다.
4. **클립보드 항목 탭이 undo 1단위로 묶이는 순서**(커밋 → 삽입 → `undoRedoEditDidApply` → 커밋): Task 3 Step 1의 호출 순서 테스트가 고정한다.
5. **수식 후보의 `.confirmOriginal`은 `suggestionDidApply`·후보 갱신을 부르지 않는다**: Task 4 Step 2 테스트가 고정한다.

---

## 파일 구조

| 구분 | 경로 | 책임 |
|---|---|---|
| 생성 | `Modules/SYKeyboardCore/Presentation/Utils/Coordinators/ClipboardHistoryCoordinator.swift` | 패널 열기·닫기, pasteboard 동기화·복사·이미지 복원, 알림 3개. `ClipboardHistoryPanelDelegate` |
| 생성 | `Modules/SYKeyboardCore/Presentation/Utils/Coordinators/SuggestionSelectionCoordinator.swift` | 후보 탭 처리, trait 동기화, 전송 기록, 후보 삭제 확인 오버레이. `SuggestionControllerDelegate`, `SuggestionBarDelegate` |
| 생성 | `Modules/SYKeyboardCore/Presentation/Utils/Extensions/UIResponder+Extension.swift` | `openURLThroughResponderChain(_:)` |
| 수정 | `Modules/SYKeyboardCore/Presentation/View/Components/Overlays/RequestFullAccessOverlayView.swift` | `install(in:onClose:onOpenSettings:)` |
| 수정 | `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` | 세 영역 삭제, Coordinator 소유, Host 채택 extension |
| 수정 | `SYKeyboard.xcodeproj/project.pbxproj` | 새 파일 3개 × 타깃 2개 등록 |
| 생성 | `SYKeyboardTests/Controller/BaseKeyboardViewControllerSuggestionClipboardBehaviorTests.swift` | 추출 전 동작 고정(VC 수준) |
| 생성 | `SYKeyboardTests/Presentation/RequestFullAccessOverlayViewInstallTests.swift` | `install` 단위 테스트 |
| 생성 | `SYKeyboardTests/Utils/ClipboardHistoryCoordinatorTests.swift` | Coordinator 단위 테스트 |
| 생성 | `SYKeyboardTests/Utils/FakeSuggestionService.swift` | `SuggestionService` 기록용 가짜 |
| 생성 | `SYKeyboardTests/Utils/SuggestionSelectionCoordinatorTests.swift` | Coordinator 단위 테스트 |
| 수정 | `SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift` | delegate 호출 경로를 Coordinator로 |
| 수정 | `CLAUDE.md`, `docs/architecture/*.md`(5개), `README.md` | 새 구조 반영 |

Host 프로토콜의 이름 규칙: VC의 `private` 메서드를 감싸는 요구사항은 `refresh…`/`…LastEdit`/`interrupt…`처럼 **VC 메서드와 다른 이름**을 쓴다. `private` 멤버는 internal 프로토콜의 witness가 될 수 없으므로 같은 파일의 Host 채택 extension에서 한 줄로 전달한다. VC의 `public`/`open` 메서드(`insertText`, `replaceText(deleteCount:insert:)`, `suggestionDidApply`, `undoRedoEditDidApply`, `commitUndoRedoGroupIgnoringCompositionDeferral`, `textDocument`, `hasFullAccess`)는 같은 이름으로 그대로 witness가 된다.

---

### Task 1: 추출 전 VC 동작 고정 테스트

**Files:**
- Create: `SYKeyboardTests/Controller/BaseKeyboardViewControllerSuggestionClipboardBehaviorTests.swift`

**Interfaces:**
- Consumes: `BaseKeyboardViewController.init(language:)`, `textDidChange(_:)`, `textWillChange(_:)`, `KeyboardView.suggestionBarView`, `SuggestionBarView.suggestionDelegate`, `clipboardHistoryPanelView`, `clipboardHistoryStore`, `CountingTextDocumentProxy`, `TestPrimaryKeyboardView`
- Produces: Task 3·4가 끝난 뒤 **수정 없이** 통과해야 하는 테스트 5개. 테스트는 Coordinator 타입이나 VC의 `isClipboardPanelVisible`을 직접 참조하지 않는다(옮겨지는 것들이므로)

- [ ] **Step 1: 테스트 파일 작성**

```swift
//
//  BaseKeyboardViewControllerSuggestionClipboardBehaviorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

/// #184 추출 전 동작을 고정한다. 후보 바·클립보드 패널의 delegate 호출은 production 연결(`suggestionDelegate`, `delegate`)을 거친다.
/// Coordinator로 옮겨지는 멤버(`isClipboardPanelVisible` 등)는 참조하지 않는다
@Suite("BaseKeyboardViewController 후보 선택·클립보드 동작 고정", .sharedUserDefaults)
@MainActor
struct BaseKeyboardViewControllerSuggestionClipboardBehaviorTests {

    @Test("수식 후보 1번 칸 탭은 결과만 삽입")
    func testMathResultSuggestionTapInsertsResult() {
        let settings = UserDefaultsManager.shared
        let oldPredictive = settings.isPredictiveTextEnabled
        let oldMath = settings.isShowMathResultsEnabled
        settings.isPredictiveTextEnabled = true
        settings.isShowMathResultsEnabled = true
        defer {
            settings.isPredictiveTextEnabled = oldPredictive
            settings.isShowMathResultsEnabled = oldMath
        }

        let controller = TestBehaviorViewController()
        controller.proxy.beforeInput = "3 - 1 ="
        controller.loadViewIfNeeded()
        controller.textDidChange(nil)
        let bar = controller.suggestionBar

        bar.suggestionDelegate?.suggestionBar(bar, didSelectSuggestionAt: 1)

        #expect(controller.proxy.writes == ["insertText(2)"])
    }

    @Test("수식 후보 탭의 프록시 문맥 읽기 횟수")
    func testMathResultSuggestionTapContextReadCount() {
        let settings = UserDefaultsManager.shared
        let oldPredictive = settings.isPredictiveTextEnabled
        let oldMath = settings.isShowMathResultsEnabled
        settings.isPredictiveTextEnabled = true
        settings.isShowMathResultsEnabled = true
        defer {
            settings.isPredictiveTextEnabled = oldPredictive
            settings.isShowMathResultsEnabled = oldMath
        }

        let controller = TestBehaviorViewController()
        controller.proxy.beforeInput = "3 - 1 ="
        controller.loadViewIfNeeded()
        controller.textDidChange(nil)
        let bar = controller.suggestionBar
        controller.proxy.resetReadCounts()

        bar.suggestionDelegate?.suggestionBar(bar, didSelectSuggestionAt: 1)

        // 추출 전 측정값. Step 3에서 측정해 채운다
        #expect(controller.proxy.contextReadCount == -1)
    }

    @Test("클립보드 버튼 탭은 패널을 열고 자판을 숨기며 다시 탭하면 닫음")
    func testClipboardButtonTapTogglesPanel() {
        let settings = UserDefaultsManager.shared
        let oldClipboard = settings.isClipboardHistoryEnabled
        settings.isClipboardHistoryEnabled = false
        defer { settings.isClipboardHistoryEnabled = oldClipboard }

        let controller = TestBehaviorViewController()
        controller.loadViewIfNeeded()
        let bar = controller.suggestionBar

        bar.suggestionDelegate?.suggestionBarDidTapClipboard(bar)

        #expect(controller.clipboardHistoryPanelView.isHidden == false)
        #expect(controller.primaryView.isHidden)

        bar.suggestionDelegate?.suggestionBarDidTapClipboard(bar)

        #expect(controller.clipboardHistoryPanelView.isHidden)
        #expect(controller.primaryView.isHidden == false)
    }

    @Test("textWillChange는 열린 클립보드 패널을 닫음")
    func testTextWillChangeClosesClipboardPanel() {
        let settings = UserDefaultsManager.shared
        let oldClipboard = settings.isClipboardHistoryEnabled
        settings.isClipboardHistoryEnabled = false
        defer { settings.isClipboardHistoryEnabled = oldClipboard }

        let controller = TestBehaviorViewController()
        controller.loadViewIfNeeded()
        let bar = controller.suggestionBar
        bar.suggestionDelegate?.suggestionBarDidTapClipboard(bar)
        #expect(controller.clipboardHistoryPanelView.isHidden == false)

        controller.textWillChange(nil)

        #expect(controller.clipboardHistoryPanelView.isHidden)
        #expect(controller.primaryView.isHidden == false)
    }

    @Test("클립보드 텍스트 항목 탭은 한 번 삽입하고 패널을 닫음")
    func testClipboardTextItemTapInsertsAndClosesPanel() {
        let settings = UserDefaultsManager.shared
        let oldClipboard = settings.isClipboardHistoryEnabled
        settings.isClipboardHistoryEnabled = false
        defer { settings.isClipboardHistoryEnabled = oldClipboard }

        let controller = TestBehaviorViewController()
        controller.loadViewIfNeeded()
        let bar = controller.suggestionBar
        bar.suggestionDelegate?.suggestionBarDidTapClipboard(bar)
        let panel = controller.clipboardHistoryPanelView
        // 항목 탭은 App Group 저장소에 기록되므로 고유한 텍스트를 쓰고 끝나면 지운다
        let text = "테스트-\(UUID().uuidString)"
        panel.configure(state: .items([ClipboardHistoryItem(text: text, createdAt: Date())]))
        defer {
            if let store = controller.clipboardHistoryStore {
                store.remove(ids: Set(store.load().filter { $0.text == text }.map(\.id)))
            }
        }

        panel.delegate?.clipboardPanel(panel, didSelectItemAt: 0)

        #expect(controller.proxy.writes == ["insertText(\(text))"])
        #expect(controller.clipboardHistoryPanelView.isHidden)
        #expect(controller.primaryView.isHidden == false)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestBehaviorViewController: BaseKeyboardViewController {
    let primaryView = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let proxy = CountingTextDocumentProxy()

    override var primaryKeyboardView: PrimaryKeyboardRepresentable {
        primaryView
    }

    override var textDocumentProxy: any UITextDocumentProxy {
        proxy
    }

    /// `loadView`가 `view`에 넣는 `KeyboardView`의 후보 바. VC의 `suggestionBarView`는 private이라 뷰 계층으로 얻는다
    var suggestionBar: SuggestionBarView {
        (view as! KeyboardView).suggestionBarView
    }

    init() {
        super.init(language: "ko-KR")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateKeyboardType() {}
}
```

- [ ] **Step 2: 실행해 읽기 횟수 테스트만 실패하는지 확인**

```sh
cd /Users/macmillan/Projects/XcodeProjects/SNMac/SYKeyboard/SYKeyboard
LOG=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad/task1-run1.log
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerSuggestionClipboardBehaviorTests \
  > "$LOG" 2>&1; grep -E "Test Case|passed|failed|error:" "$LOG" | tail -n 20
```

Expected: 4개 PASS, `testMathResultSuggestionTapContextReadCount` 1개 FAIL. 실패 메시지에 실제 `contextReadCount` 값이 보인다(예: `Expectation failed: (controller.proxy.contextReadCount → 3) == -1`).

다른 테스트가 실패하면 **production 코드를 고치지 않는다.** 테스트가 현재 동작을 잘못 적은 것이므로 로그에서 실제 값을 확인해 테스트를 고친다. 예를 들어 `writes`에 `insertText(2)` 외의 쓰기가 있으면 그 값을 기대값으로 적고 테스트 이름을 실제 동작에 맞춘다.

- [ ] **Step 3: 측정값을 테스트에 적고 다시 실행**

Step 2 로그의 실제 `contextReadCount` 값(N)으로 `== -1`을 `== N`으로 바꾼다. 주석도 `// 추출 전 측정값(2026-10-08, c68a3a1f): N`으로 바꾼다. 같은 명령을 다시 실행한다.

Expected: 5개 PASS.

- [ ] **Step 4: 커밋**

```sh
git add SYKeyboardTests/Controller/BaseKeyboardViewControllerSuggestionClipboardBehaviorTests.swift
git commit -m "$(cat <<'EOF'
test: #184 - 후보 선택·클립보드 추출 전 VC 동작 고정 테스트 추가

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: 전체 접근 안내를 `RequestFullAccessOverlayView.install`과 `UIResponder` extension으로

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Extensions/UIResponder+Extension.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/View/Components/Overlays/RequestFullAccessOverlayView.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` (`// MARK: - Full Access Guide` 섹션 삭제, `viewDidLoad` 호출 교체)
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Test: `SYKeyboardTests/Presentation/RequestFullAccessOverlayViewInstallTests.swift`

**Interfaces:**
- Produces: `extension UIResponder { func openURLThroughResponderChain(_ url: URL) }`, `RequestFullAccessOverlayView.install(in container: UIView, onClose: @escaping () -> Void, onOpenSettings: @escaping (URL) -> Void)`. Task 3의 `ClipboardHistoryHost.openURL`이 `openURLThroughResponderChain`을 쓴다

- [ ] **Step 1: 실패하는 테스트 작성**

```swift
//
//  RequestFullAccessOverlayViewInstallTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("전체 접근 안내 오버레이 설치")
@MainActor
struct RequestFullAccessOverlayViewInstallTests {

    @Test("설치하면 컨테이너 네 변에 붙고 보임")
    func testInstallAddsOverlayFillingContainer() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let overlay = RequestFullAccessOverlayView()

        overlay.install(in: container, onClose: {}, onOpenSettings: { _ in })
        container.layoutIfNeeded()

        #expect(overlay.superview === container)
        #expect(overlay.isHidden == false)
        #expect(overlay.frame == container.bounds)
    }

    @Test("닫기 버튼은 onClose를 부른 뒤 오버레이를 숨김")
    func testCloseButtonCallsOnCloseThenHides() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let overlay = RequestFullAccessOverlayView()
        var closeCount = 0
        var wasHiddenWhenClosed: Bool?

        overlay.install(
            in: container,
            onClose: {
                closeCount += 1
                wasHiddenWhenClosed = overlay.isHidden
            },
            onOpenSettings: { _ in }
        )
        overlay.closeButton.sendActions(for: .touchUpInside)

        #expect(closeCount == 1)
        #expect(wasHiddenWhenClosed == false)
        #expect(overlay.isHidden)
    }

    @Test("설정 이동 버튼은 앱 URL scheme으로 onOpenSettings를 부름")
    func testSettingsButtonPassesAppURL() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let overlay = RequestFullAccessOverlayView()
        var openedURLs: [URL] = []

        overlay.install(in: container, onClose: {}, onOpenSettings: { openedURLs.append($0) })
        overlay.goToSettingsButton.sendActions(for: .touchUpInside)

        #expect(openedURLs == [URL(string: "sykeyboard://")!])
        #expect(overlay.isHidden == false)
    }
}
```

- [ ] **Step 2: 컴파일 실패 확인**

```sh
LOG=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad/task2-run1.log
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/RequestFullAccessOverlayViewInstallTests \
  > "$LOG" 2>&1; grep -E "error:|passed|failed" "$LOG" | tail -n 10
```

Expected: `error: value of type 'RequestFullAccessOverlayView' has no member 'install'`

- [ ] **Step 3: `UIResponder+Extension.swift` 작성**

```swift
//
//  UIResponder+Extension.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit

extension UIResponder {
    /// extension은 `UIApplication`을 직접 쓸 수 없으므로 responder chain을 따라 올라가 연다.
    /// 브라우저나 앱이 열리면 호스트 앱을 떠나므로 키보드는 시스템이 내린다
    func openURLThroughResponderChain(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url)
                return
            }
            responder = responder?.next
        }
    }
}
```

- [ ] **Step 4: `RequestFullAccessOverlayView`에 `install` 추가**

`RequestFullAccessOverlayView.swift`의 `required init?(coder:)` 바로 아래, 클래스 닫는 중괄호 앞에 추가한다.

```swift
    // MARK: - Install

    /// 컨테이너를 가득 채우도록 붙이고 버튼 액션을 연결한다.
    /// - Parameters:
    ///   - container: 오버레이를 올릴 뷰. 키보드 뷰 위에 덮어야 하므로 호출자가 마지막에 부른다
    ///   - onClose: 닫기 버튼. 호출 뒤 오버레이를 숨긴다
    ///   - onOpenSettings: 시스템 설정 이동 버튼. 앱 URL scheme을 넘긴다
    func install(
        in container: UIView,
        onClose: @escaping () -> Void,
        onOpenSettings: @escaping (URL) -> Void
    ) {
        container.addSubview(self)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: container.topAnchor),
            leadingAnchor.constraint(equalTo: container.leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        closeButton.addAction(
            UIAction { [weak self] _ in
                onClose()
                self?.isHidden = true
            },
            for: .touchUpInside
        )
        goToSettingsButton.addAction(
            UIAction { _ in
                let urlString = "sykeyboard://"
                guard let url = URL(string: urlString) else {
                    assertionFailure("올바르지 않은 URL 형식입니다.")
                    // Core는 Firebase에 의존하지 않으므로 non-fatal 대신 진단 로그로만 남긴다. 상수 URL이라 실제로는 오지 않는 분기다
                    KeyboardDiagnostics.log("Invalid settings URL: \(urlString)")
                    return
                }
                onOpenSettings(url)
            },
            for: .touchUpInside
        )
    }
```

- [ ] **Step 5: pbxproj에 `UIResponder+Extension.swift` 등록**

두 타깃의 membershipExceptions에서 `"SYKeyboardCore/Presentation/Utils/Extensions/String+Extension.swift",` 줄 바로 아래에 다음 줄을 넣는다(현재 284\~286, 387\~389 부근. 두 곳 모두).

```
				"SYKeyboardCore/Presentation/Utils/Extensions/UIResponder+Extension.swift",
```

확인:

```sh
grep -c 'Utils/Extensions/UIResponder+Extension.swift' SYKeyboard.xcodeproj/project.pbxproj
```

Expected: `2`

- [ ] **Step 6: VC의 Full Access Guide 섹션 교체**

`BaseKeyboardViewController.swift`에서

1. `// MARK: - Full Access Guide`부터 파일 끝까지의 `private extension`(`setupRequestFullAccessOverlayView`, `openURL`)을 삭제한다.
2. `viewDidLoad` 마지막의

```swift
        if !BaseKeyboardViewController.isPreview, needToShowFullAccessGuide {
            setupRequestFullAccessOverlayView()
        }
```

를 다음으로 바꾼다.

```swift
        if !BaseKeyboardViewController.isPreview, needToShowFullAccessGuide {
            requestFullAccessOverlayView.install(
                in: view,
                onClose: { [weak self] in self?.keyboardExtensionLocalStateStore.isClosed = true },
                onOpenSettings: { [weak self] url in self?.openURLThroughResponderChain(url) }
            )
        }
```

3. `ClipboardHistoryPanelDelegate`의 `clipboardPanel(_:didRequestOpenURLAt:)` 안 `openURL(url)`을 `openURLThroughResponderChain(url)`로 바꾼다(Task 3에서 Coordinator로 옮기기 전까지 컴파일되게 한다).

확인:

```sh
grep -n "openURL\b\|setupRequestFullAccessOverlayView" Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
```

Expected: 출력 없음.

- [ ] **Step 7: 테스트 통과 확인**

Step 2의 명령을 다시 실행한다. 이어서 Task 1 suite도 실행한다.

```sh
LOG=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad/task2-run2.log
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/RequestFullAccessOverlayViewInstallTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerSuggestionClipboardBehaviorTests \
  > "$LOG" 2>&1; grep -E "error:|passed|failed" "$LOG" | tail -n 10
```

Expected: 8개 PASS, 0 failed.

- [ ] **Step 8: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Extensions/UIResponder+Extension.swift \
  Modules/SYKeyboardCore/Presentation/View/Components/Overlays/RequestFullAccessOverlayView.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Presentation/RequestFullAccessOverlayViewInstallTests.swift
git commit -m "$(cat <<'EOF'
refactor: #184 - 전체 접근 안내 설치를 오버레이 뷰와 UIResponder 확장으로 이동

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `ClipboardHistoryCoordinator` 추출

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Coordinators/ClipboardHistoryCoordinator.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Test: `SYKeyboardTests/Utils/ClipboardHistoryCoordinatorTests.swift`

**Interfaces:**
- Consumes: `UIResponder.openURLThroughResponderChain(_:)` (Task 2)
- Produces:
  - `protocol ClipboardHistoryHost: AnyObject` — `hasFullAccess: Bool`, `isPreviewMode: Bool`, `isViewInWindow: Bool`, `insertText(_:)`, `commitUndoRedoGroupIgnoringCompositionDeferral()`, `undoRedoEditDidApply()`, `refreshShowingKeyboard()`, `refreshClipboardControl()`, `refreshReturnButtonEnabled()`, `refreshSuggestions()`, `interruptPendingDeleteInteractions()`, `openURL(_:)`
  - `final class ClipboardHistoryCoordinator: NSObject, ClipboardHistoryPanelDelegate` — `init(clipboardHistoryStore:clipboardHistoryPanelView:keyboardSettingsManager:host:)`, `private(set) var isPanelVisible: Bool`, `registerNotificationObservers()`, `synchronizeIfNeeded()`, `closePanelIfNeeded()`, `togglePanel()`
  - Task 4의 `SuggestionSelectionHost.toggleClipboardPanel()`이 VC에서 `clipboardHistoryCoordinator.togglePanel()`로 전달된다. `isPreviewMode`, `refreshSuggestions()`, `interruptPendingDeleteInteractions()`, `insertText(_:)`는 Task 4의 Host와 같은 이름·시그니처로 선언해 VC의 witness 하나가 둘을 만족한다

- [ ] **Step 1: 실패하는 테스트 작성**

호스트 앱 테스트에서 `UIPasteboard.general.string`을 읽으면 iOS 붙여넣기 권한 알림이 떠 러너가 멈추고, 쓰면 Mac 클립보드를 덮어쓴다(시뮬레이터와 공유). 그래서 fixture는 `lastSeenPasteboardChangeCount`를 현재 `changeCount`로 맞춰 동기화가 읽기를 건너뛰게 하고, host의 `hasFullAccess` 기본값을 `false`로 두어 복사 경로를 막는다. 저장소에서 항목을 읽어야 하는 테스트만 `hasFullAccess = true`로 켠다.

```swift
//
//  ClipboardHistoryCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("클립보드 기록 Coordinator", .sharedUserDefaults)
@MainActor
struct ClipboardHistoryCoordinatorTests {

    @Test("패널 토글은 삭제 보류를 끊고 열었다가 다시 닫음")
    func testTogglePanelOpensThenCloses() {
        let fixture = makeFixture()
        defer { fixture.restore() }

        fixture.coordinator.togglePanel()

        #expect(fixture.coordinator.isPanelVisible)
        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions", "refreshShowingKeyboard", "refreshClipboardControl"])

        fixture.coordinator.togglePanel()

        #expect(fixture.coordinator.isPanelVisible == false)
        #expect(fixture.host.calls.suffix(2) == ["refreshShowingKeyboard", "refreshClipboardControl"])
    }

    @Test("닫힌 패널에 closePanelIfNeeded는 아무 것도 하지 않음")
    func testClosePanelIfNeededWhenClosedDoesNothing() {
        let fixture = makeFixture()
        defer { fixture.restore() }

        fixture.coordinator.closePanelIfNeeded()

        #expect(fixture.host.calls.isEmpty)
        #expect(fixture.coordinator.isPanelVisible == false)
    }

    @Test("텍스트 항목 탭은 undo 1단위로 삽입하고 기록 맨 위로 올리고 패널을 닫음")
    func testTextItemTapInsertsAsOneUndoGroupAndRecords() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.store.record("이전")
        fixture.coordinator.togglePanel()
        fixture.host.calls.removeAll()
        fixture.panel.configure(state: .items([
            ClipboardHistoryItem(text: "이전", createdAt: Date()),
            ClipboardHistoryItem(text: "복사", createdAt: Date())
        ]))

        fixture.coordinator.clipboardPanel(fixture.panel, didSelectItemAt: 1)

        #expect(fixture.host.calls == [
            "commitUndoRedoGroupIgnoringCompositionDeferral",
            "insertText(복사)",
            "undoRedoEditDidApply",
            "commitUndoRedoGroupIgnoringCompositionDeferral",
            "refreshShowingKeyboard",
            "refreshClipboardControl",
            "refreshReturnButtonEnabled",
            "refreshSuggestions"
        ])
        #expect(fixture.coordinator.isPanelVisible == false)
        #expect(fixture.store.load().first?.text == "복사")
    }

    @Test("항목 삭제는 저장소에서 id로 지우고 패널을 다시 읽음")
    func testDeleteItemsRemovesFromStore() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.host.hasFullAccess = true
        fixture.store.record("하나")
        fixture.store.record("둘")
        fixture.coordinator.togglePanel()
        #expect(fixture.panel.items.map(\.text) == ["둘", "하나"])

        fixture.coordinator.clipboardPanel(fixture.panel, didDeleteItemsAt: [0])

        #expect(fixture.store.load().map(\.text) == ["하나"])
        #expect(fixture.panel.items.map(\.text) == ["하나"])
    }

    @Test("Full Access가 없으면 패널은 안내 상태로 열림")
    func testPanelShowsFullAccessRequiredWithoutFullAccess() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.store.record("하나")

        fixture.coordinator.togglePanel()

        #expect(fixture.coordinator.isPanelVisible)
        #expect(fixture.panel.items.isEmpty)
    }

    @Test("URL 항목 탭은 host에 열기를 요청")
    func testOpenURLRequestForwardsToHost() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.panel.configure(state: .items([
            ClipboardHistoryItem(text: "https://example.com", createdAt: Date())
        ]))

        fixture.coordinator.clipboardPanel(fixture.panel, didRequestOpenURLAt: 0)

        #expect(fixture.host.openedURLs == [URL(string: "https://example.com")!])
    }

    @Test("미리보기에서는 Full Access가 있어도 pasteboard를 복사하지 않음")
    func testPreviewDoesNotWriteToPasteboard() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.host.hasFullAccess = true
        fixture.host.isPreviewMode = true
        let settings = UserDefaultsManager.shared
        settings.lastSeenPasteboardChangeCount = -1
        fixture.panel.configure(state: .items([ClipboardHistoryItem(text: "복사", createdAt: Date())]))

        fixture.coordinator.clipboardPanel(fixture.panel, didSelectItemAt: 0)

        // 복사했다면 changeCount를 갱신한다. 미리보기는 복사 자체를 건너뛴다
        #expect(settings.lastSeenPasteboardChangeCount == -1)
        #expect(fixture.host.calls.contains("insertText(복사)"))
    }

    @Test("host가 해제된 뒤에는 토글·알림이 아무 것도 하지 않음")
    func testReleasedHostIsIgnored() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        var host: RecordingClipboardHistoryHost? = RecordingClipboardHistoryHost()
        host?.hasFullAccess = true
        let coordinator = ClipboardHistoryCoordinator(
            clipboardHistoryStore: fixture.store,
            clipboardHistoryPanelView: fixture.panel,
            keyboardSettingsManager: .shared,
            host: host!
        )
        fixture.store.record("하나")
        host = nil

        coordinator.togglePanel()
        coordinator.synchronizeIfNeeded()
        coordinator.hostDidBecomeActive()
        coordinator.clipboardImageDidRecord()

        #expect(coordinator.isPanelVisible == false)
        #expect(fixture.panel.items.isEmpty)
    }
}

// MARK: - Test Helpers

@MainActor
private final class RecordingClipboardHistoryHost: ClipboardHistoryHost {
    var calls: [String] = []
    var openedURLs: [URL] = []
    /// 기본 false. 켜면 저장소 읽기와 pasteboard 복사 경로가 열린다
    var hasFullAccess = false
    var isPreviewMode = false
    var isViewInWindow = true

    func insertText(_ text: String) { calls.append("insertText(\(text))") }
    func commitUndoRedoGroupIgnoringCompositionDeferral() { calls.append("commitUndoRedoGroupIgnoringCompositionDeferral") }
    func undoRedoEditDidApply() { calls.append("undoRedoEditDidApply") }
    func refreshShowingKeyboard() { calls.append("refreshShowingKeyboard") }
    func refreshClipboardControl() { calls.append("refreshClipboardControl") }
    func refreshReturnButtonEnabled() { calls.append("refreshReturnButtonEnabled") }
    func refreshSuggestions() { calls.append("refreshSuggestions") }
    func interruptPendingDeleteInteractions() { calls.append("interruptPendingDeleteInteractions") }
    func openURL(_ url: URL) { openedURLs.append(url) }
}

@MainActor
private struct Fixture {
    let coordinator: ClipboardHistoryCoordinator
    let host: RecordingClipboardHistoryHost
    let store: ClipboardHistoryStore
    let panel: ClipboardHistoryPanelView
    private let oldClipboardEnabled: Bool
    private let oldChangeCount: Int

    init(
        coordinator: ClipboardHistoryCoordinator,
        host: RecordingClipboardHistoryHost,
        store: ClipboardHistoryStore,
        panel: ClipboardHistoryPanelView,
        oldClipboardEnabled: Bool,
        oldChangeCount: Int
    ) {
        self.coordinator = coordinator
        self.host = host
        self.store = store
        self.panel = panel
        self.oldClipboardEnabled = oldClipboardEnabled
        self.oldChangeCount = oldChangeCount
    }

    /// fixture가 바꾼 설정을 되돌린다. 각 테스트가 `defer`로 부른다
    func restore() {
        UserDefaultsManager.shared.isClipboardHistoryEnabled = oldClipboardEnabled
        UserDefaultsManager.shared.lastSeenPasteboardChangeCount = oldChangeCount
    }
}

/// 임시 디렉터리의 저장소, 실제 패널 뷰, 기록용 host.
/// 클립보드 설정은 켜고, pasteboard 동기화가 `string`을 읽지 않도록 `changeCount`를 현재 값으로 맞춘다(`changeCount` 읽기는 권한 알림을 띄우지 않는다)
@MainActor
private func makeFixture() -> Fixture {
    let settings = UserDefaultsManager.shared
    let oldClipboardEnabled = settings.isClipboardHistoryEnabled
    let oldChangeCount = settings.lastSeenPasteboardChangeCount
    settings.isClipboardHistoryEnabled = true
    settings.lastSeenPasteboardChangeCount = UIPasteboard.general.changeCount

    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("ClipboardHistoryCoordinatorTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let store = ClipboardHistoryStore(
        fileURL: directory.appendingPathComponent("history.plist"),
        imageStore: ClipboardImageStore(directoryURL: directory.appendingPathComponent("images", isDirectory: true))
    )
    let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    let host = RecordingClipboardHistoryHost()
    let coordinator = ClipboardHistoryCoordinator(
        clipboardHistoryStore: store,
        clipboardHistoryPanelView: panel,
        keyboardSettingsManager: settings,
        host: host
    )
    panel.delegate = coordinator
    return Fixture(
        coordinator: coordinator,
        host: host,
        store: store,
        panel: panel,
        oldClipboardEnabled: oldClipboardEnabled,
        oldChangeCount: oldChangeCount
    )
}
```

- [ ] **Step 2: 컴파일 실패 확인**

```sh
LOG=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad/task3-run1.log
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/ClipboardHistoryCoordinatorTests \
  > "$LOG" 2>&1; grep -E "error:|passed|failed" "$LOG" | tail -n 10
```

Expected: `error: cannot find type 'ClipboardHistoryHost' in scope`

- [ ] **Step 3: `ClipboardHistoryCoordinator.swift` 작성**

VC의 `// MARK: - Clipboard History`와 `// MARK: - ClipboardHistoryPanelDelegate` 본문을 옮긴 것이다. 바뀐 부분은 `self.`로 쓰던 VC 멤버가 `host.`로, `isClipboardPanelVisible`이 `isPanelVisible`로, `hasFullAccess`/`viewIfLoaded?.window != nil`/`BaseKeyboardViewController.isPreview`가 host 프로퍼티로 간 것뿐이다.

```swift
//
//  ClipboardHistoryCoordinator.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit
import SYKeyboardAssets

/// `ClipboardHistoryCoordinator`가 소유자(`BaseKeyboardViewController`)에게 요구하는 것.
/// `refresh…`/`interrupt…`는 VC의 private 메서드를 감싼 이름이다. 같은 파일의 Host 채택 extension이 한 줄로 전달한다
@MainActor
protocol ClipboardHistoryHost: AnyObject {
    var hasFullAccess: Bool { get }
    /// `BaseKeyboardViewController.isPreview`. 앱 미리보기에서는 패널을 열지 않고 pasteboard를 쓰지 않는다
    var isPreviewMode: Bool { get }
    /// 키보드가 내려간 뒤 프로세스만 남아 있을 때 pasteboard를 읽지 않기 위한 판정
    var isViewInWindow: Bool { get }

    func insertText(_ text: String)
    func commitUndoRedoGroupIgnoringCompositionDeferral()
    func undoRedoEditDidApply()
    func refreshShowingKeyboard()
    func refreshClipboardControl()
    func refreshReturnButtonEnabled()
    func refreshSuggestions()
    func interruptPendingDeleteInteractions()
    func openURL(_ url: URL)
}

/// 클립보드 기록 패널의 열기·닫기, pasteboard 동기화·복사·이미지 복원, 관련 알림 처리를 맡는다.
/// 패널 표시 여부(`isPanelVisible`)를 소유하고, 자판·버튼 갱신은 host에 요청한다.
/// host는 `weak`다. 알림·`DispatchQueue.main.async`가 이 객체를 VC보다 오래 살릴 수 있으므로 모든 진입점이 `guard let host`로 시작한다
@MainActor
final class ClipboardHistoryCoordinator: NSObject {

    // MARK: - Properties

    /// 패널이 자판 자리에 보이는지. `updateShowingKeyboard`·`updateClipboardControl`이 읽는다
    private(set) var isPanelVisible = false

    private let clipboardHistoryStore: ClipboardHistoryStore?
    private let clipboardHistoryPanelView: ClipboardHistoryPanelView
    private let keyboardSettingsManager: UserDefaultsManager
    private weak var host: ClipboardHistoryHost?

    // MARK: - Initializer

    init(
        clipboardHistoryStore: ClipboardHistoryStore?,
        clipboardHistoryPanelView: ClipboardHistoryPanelView,
        keyboardSettingsManager: UserDefaultsManager,
        host: ClipboardHistoryHost
    ) {
        self.clipboardHistoryStore = clipboardHistoryStore
        self.clipboardHistoryPanelView = clipboardHistoryPanelView
        self.keyboardSettingsManager = keyboardSettingsManager
        self.host = host
        super.init()
    }

    // MARK: - Internal Methods

    /// `viewDidLoad`에서 VC가 부른다. 등록 시점을 VC와 같게 두기 위해 init이 아니라 여기서 한다.
    /// - 호스트 앱이 다른 앱(사진 등)을 거쳐 돌아올 때는 viewWillAppear가 다시 오지 않으므로 활성화 알림에서 pasteboard를 확인한다
    /// - 이미지는 백그라운드에서 파일로 저장된 뒤 기록되므로, 그사이 패널이 열려 있으면 완료 알림에서 다시 읽는다
    /// - 상세 뷰에서 본문 일부를 복사하면 viewWillAppear 등 기존 동기화 시점이 오지 않으므로 pasteboard 변경 알림에서 기록한다
    func registerNotificationObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(hostDidBecomeActive), name: .NSExtensionHostDidBecomeActive, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(clipboardImageDidRecord),
            name: ClipboardHistoryPasteboardSynchronizer.didRecordImageNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(pasteboardDidChange), name: UIPasteboard.changedNotification, object: nil
        )
    }

    /// pasteboard의 `changeCount`가 마지막 확인값과 다를 때만 텍스트 또는 이미지를 읽어 기록에 저장합니다.
    ///
    /// 호출 시점: `viewWillAppear`, 호스트 앱 재활성화, `textWillChange`, 클립보드 버튼 탭. `textDidChange`와 selection 콜백은 쓰지 않습니다.
    /// 앱도 같은 `ClipboardHistoryPasteboardSynchronizer`를 쓰지만, 활성화 시에는 키보드가 예산 초과로 건너뛴 이미지가 남아 있을 때만 읽는다(#154).
    /// 이미지 저장 완료는 `didRecordImageNotification`으로 받는다(`clipboardImageDidRecord`)
    func synchronizeIfNeeded() {
        guard isClipboardHistoryAvailable, let clipboardHistoryStore else { return }
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: clipboardHistoryStore)
    }

    /// 클립보드 버튼 탭. 열려 있으면 닫고, 닫혀 있으면 동기화 후 엽니다.
    func togglePanel() {
        if isPanelVisible {
            closePanelIfNeeded()
        } else {
            openPanel()
        }
    }

    /// 패널을 닫고 자판으로 돌아갑니다. 이미 닫혀 있으면 아무것도 하지 않습니다.
    func closePanelIfNeeded() {
        guard isPanelVisible, let host else { return }
        isPanelVisible = false
        clipboardHistoryPanelView.resetPresentation()
        host.refreshShowingKeyboard()
        host.refreshClipboardControl()
    }

    // MARK: - @objc Methods

    /// 백그라운드 이미지 저장이 끝나 기록됐을 때. 패널이 열려 있으면 새 항목이 보이도록 다시 읽는다
    @objc func clipboardImageDidRecord() {
        guard host != nil, isPanelVisible else { return }
        reloadPanel()
    }

    /// 호스트 앱이 다시 활성화되면 그사이 다른 앱에서 복사한 내용을 반영한다.
    /// 텍스트는 동기 저장이라 패널이 열려 있으면 바로 다시 읽고, 이미지는 저장 완료 콜백이 다시 읽는다.
    /// 제어 센터·알림 센터를 내렸다 올려도 오므로, 목록이 실제로 바뀐 경우에만 다시 구성해 열린 상세 뷰·삭제 확인·안내문을 지우지 않는다
    @objc func hostDidBecomeActive() {
        // 키보드가 내려간 뒤 프로세스만 남아 있을 때는 읽지 않는다. 보이지 않는 키보드가 붙여넣기 권한 알림을 띄우지 않게 한다
        guard let host, host.isViewInWindow else { return }
        synchronizeIfNeeded()
        guard isPanelVisible, isClipboardHistoryAvailable, let clipboardHistoryStore,
              clipboardHistoryStore.load() != clipboardHistoryPanelView.items else { return }
        reloadPanel()
    }

    /// 패널이 열린 채 이 키보드 안에서 pasteboard가 바뀌면(상세 뷰 일부 복사) 기록에 반영하고, 보던 상세 뷰는 유지한다.
    /// 붙여넣기·이미지 복원은 쓴 직후 changeCount를 갱신하므로, 그 갱신이 끝난 다음 runloop에서 확인해 중복 기록하지 않는다
    @objc func pasteboardDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.host != nil, self.isPanelVisible, self.isClipboardHistoryAvailable,
                  let clipboardHistoryStore = self.clipboardHistoryStore else { return }
            self.synchronizeIfNeeded()
            guard clipboardHistoryStore.load() != self.clipboardHistoryPanelView.items else { return }
            self.reloadPanel(keepsDetail: true)
        }
    }
}

// MARK: - Private Methods

private extension ClipboardHistoryCoordinator {

    /// 클립보드 기록 기능 사용 가능 여부. 설정 ON, Full Access, 미리보기 아님. host가 없으면 사용 불가로 본다
    var isClipboardHistoryAvailable: Bool {
        guard let host else { return false }
        return keyboardSettingsManager.isClipboardHistoryEnabled
        && host.hasFullAccess
        && !host.isPreviewMode
    }

    func openPanel() {
        guard let host else { return }
        host.interruptPendingDeleteInteractions()
        synchronizeIfNeeded()
        reloadPanel()
        isPanelVisible = true
        host.refreshShowingKeyboard()
        host.refreshClipboardControl()
    }

    /// `keepsDetail`은 `ClipboardHistoryPanelView.configure(state:keepsDetail:)`로 그대로 넘긴다
    func reloadPanel(keepsDetail: Bool = false) {
        guard let host else { return }
        guard host.hasFullAccess, let clipboardHistoryStore else {
            clipboardHistoryPanelView.configure(state: .fullAccessRequired)
            return
        }
        let items = clipboardHistoryStore.load()
        clipboardHistoryPanelView.configure(state: items.isEmpty ? .empty : .items(items), keepsDetail: keepsDetail)
    }

    /// 이미지 항목은 입력창에 넣을 수 없으므로 시스템 pasteboard에 원본 바이트를 복원하고 패널을 유지한 채 안내한다.
    /// 우리가 쓴 값을 다음 동기화에서 다시 기록하지 않도록 changeCount를 갱신한다
    func restoreImageToPasteboard(_ reference: ClipboardImageReference) {
        guard isClipboardHistoryAvailable,
              let clipboardHistoryStore,
              let imageStore = clipboardHistoryStore.imageStore else { return }
        // 메모리 맵으로 열어 힙에 올리지 않는다. 앱에서 지운 뒤 키보드가 옛 목록을 들고 있으면 항목을 정리한다
        guard let data = try? Data(contentsOf: imageStore.originalURL(for: reference), options: .mappedIfSafe) else {
            clipboardHistoryStore.remove(ids: [ClipboardHistoryItem.Content.image(reference).id])
            reloadPanel()
            return
        }
        let pasteboard = UIPasteboard.general
        pasteboard.setData(data, forPasteboardType: reference.typeIdentifier)
        keyboardSettingsManager.lastSeenPasteboardChangeCount = pasteboard.changeCount

        // 방금 쓴 항목을 최근 복사한 것처럼 미고정 맨 위로 올린다. 고정 항목은 정책상 그대로다.
        // 탭 처리(didSelectRowAt) 안에서 행 이동 애니메이션을 시작하면 눌린 표시가 남을 수 있어 다음 런루프에서 다시 읽는다.
        // 안내 토스트는 재조회와 무관하지만 새 목록이 그려진 뒤에 띄워 순서를 분명히 한다
        clipboardHistoryStore.record(.image(reference))
        DispatchQueue.main.async { [weak self] in
            guard let self, self.host != nil else { return }
            self.reloadPanel()
            self.clipboardHistoryPanelView.showTransientMessage(
                String(localized: "이미지를 복사했습니다.\n입력창을 길게 눌러 붙여넣기 해주세요.", bundle: SYKBDAssets.bundle)
            )
        }
    }

    /// 텍스트를 시스템 pasteboard에 복사한다. 우리가 쓴 값을 다음 동기화에서 다시 기록하지 않도록 changeCount를 갱신한다
    func copyTextToPasteboard(_ text: String) {
        guard isClipboardHistoryAvailable else { return }
        let pasteboard = UIPasteboard.general
        pasteboard.string = text
        keyboardSettingsManager.lastSeenPasteboardChangeCount = pasteboard.changeCount
    }
}

// MARK: - ClipboardHistoryPanelDelegate

extension ClipboardHistoryCoordinator: ClipboardHistoryPanelDelegate {
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int) {
        guard let host, panel.items.indices.contains(index) else { return }
        switch panel.items[index].content {
        case .image(let reference):
            restoreImageToPasteboard(reference)
        case .text(let text):
            // 붙여넣기를 undo 1단위로 만든다: 앞선 입력 그룹을 닫고, 삽입 후 다시 닫는다
            host.commitUndoRedoGroupIgnoringCompositionDeferral()
            host.insertText(text)
            host.undoRedoEditDidApply()
            host.commitUndoRedoGroupIgnoringCompositionDeferral()

            // macOS Spotlight 클립보드 기록처럼 고른 항목을 현재 클립보드로도 올린다. 동기화가 기록한 내용은 목록에 남지만,
            // 기록되지 않는 내용(이미지 기록 OFF·저장 거부 이미지·예산 초과로 앱 재시도 대기 중인 이미지·concealed·문자열 없는 항목)은 덮어써진다
            copyTextToPasteboard(text)
            // 방금 쓴 항목을 최근 복사한 것처럼 미고정 맨 위로 올린다. 고정 항목은 정책상 그대로다
            clipboardHistoryStore?.record(text)

            closePanelIfNeeded()
            host.refreshReturnButtonEnabled()
            host.refreshSuggestions()
        }
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int]) {
        // 인덱스는 패널이 보여준 목록 기준이므로 id로 바꿔 지운다. 파일 순서가 그사이 바뀌어도 안전하다
        let ids = Set(indices.compactMap { panel.items.indices.contains($0) ? panel.items[$0].id : nil })
        clipboardHistoryStore?.remove(ids: ids)
        reloadPanel()
    }

    func clipboardPanelDidDeleteAll(_ panel: ClipboardHistoryPanelView) {
        clipboardHistoryStore?.removeAll()
        reloadPanel()
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didTogglePinAt index: Int) {
        clipboardHistoryStore?.togglePin(at: index)
        reloadPanel()
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didTogglePinsOf ids: Set<String>) {
        // 저장소가 파일을 다시 읽어 정책을 적용하므로 그사이 앱이 바꾼 내용과 어긋나지 않는다
        clipboardHistoryStore?.togglePins(selectedIDs: ids)
        reloadPanel()
    }

    /// 브라우저가 열리면 호스트 앱을 떠나므로 키보드는 시스템이 내린다. 설정 이동과 같은 responder chain 경로다
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didRequestOpenURLAt index: Int) {
        guard let host, panel.items.indices.contains(index),
              let text = panel.items[index].text,
              let url = ClipboardHistoryPolicy.openableURL(in: text) else { return }
        host.openURL(url)
    }
}
```

주의: 원본 VC 코드에서 `pasteboardDidChange`의 비동기 블록과 `restoreImageToPasteboard`의 비동기 블록은 `self`(VC)를 weak로 잡았다. 여기서는 Coordinator를 weak로 잡고 `host != nil`을 추가로 확인한다. 둘 다 "VC가 사라졌으면 아무 일도 하지 않는다"는 같은 결과다.

- [ ] **Step 4: pbxproj에 `ClipboardHistoryCoordinator.swift` 등록**

두 타깃의 membershipExceptions에서 `SYKeyboardCore/Presentation/Utils/ButtonStateController.swift,` 줄 바로 아래(즉 `Coordinators/HangeulEnglishKeyboardModeCoordinator.swift` 줄 바로 위)에 넣는다. 두 곳 모두.

```
				SYKeyboardCore/Presentation/Utils/Coordinators/ClipboardHistoryCoordinator.swift,
```

확인:

```sh
grep -c 'Coordinators/ClipboardHistoryCoordinator.swift' SYKeyboard.xcodeproj/project.pbxproj
```

Expected: `2`

- [ ] **Step 5: VC에서 클립보드 섹션을 Coordinator 호출로 교체**

`BaseKeyboardViewController.swift`를 아래 순서로 고친다.

1. `// MARK: - Clipboard History` private extension과 `// MARK: - ClipboardHistoryPanelDelegate` extension을 **통째로 삭제**한다. (`// MARK: - ClipboardHistoryPanelDelegate` 다음에 오는 `private extension BaseKeyboardViewController { func synchronizeTextInputTraits()…`는 후보 선택 처리라 남긴다. Task 4에서 옮긴다.)

2. UI Components 섹션에서 `final var isClipboardPanelVisible = false`와 그 위 doc 주석 한 줄을 삭제하고, 그 자리에 Coordinator를 둔다. `clipboardHistoryPanelView`와 `clipboardHistoryStore` 선언은 그대로 둔다.

```swift
    /// 클립보드 패널 열기·닫기와 pasteboard 동기화를 맡는다. `ClipboardHistoryHost` 채택은 파일 끝의 extension에 있다
    private lazy var clipboardHistoryCoordinator = ClipboardHistoryCoordinator(
        clipboardHistoryStore: clipboardHistoryStore,
        clipboardHistoryPanelView: clipboardHistoryPanelView,
        keyboardSettingsManager: keyboardSettingsManager,
        host: self
    )
```

3. `viewDidLoad`에서 `NotificationCenter.default.addObserver(...)` 세 호출과 그 위 주석 세 덩어리를 삭제하고, 같은 자리에 한 줄을 둔다.

```swift
        clipboardHistoryCoordinator.registerNotificationObservers()
```

4. `viewWillAppear`의 `synchronizeClipboardHistoryIfNeeded()` → `clipboardHistoryCoordinator.synchronizeIfNeeded()`.

5. `textWillChange`의 `withReadCaching` 블록 안 `closeClipboardPanelIfNeeded()` → `clipboardHistoryCoordinator.closePanelIfNeeded()`, `synchronizeClipboardHistoryIfNeeded()` → `clipboardHistoryCoordinator.synchronizeIfNeeded()`.

6. `viewWillDisappear`의 `closeClipboardPanelIfNeeded()` → `clipboardHistoryCoordinator.closePanelIfNeeded()`.

7. `setDelegates()`의 `clipboardHistoryPanelView.delegate = self` → `clipboardHistoryPanelView.delegate = clipboardHistoryCoordinator`.

8. `updateShowingKeyboard()`의 두 `isClipboardPanelVisible` → `clipboardHistoryCoordinator.isPanelVisible`. `updateClipboardControl()`의 `isPanelVisible: isClipboardPanelVisible` → `isPanelVisible: clipboardHistoryCoordinator.isPanelVisible`.

9. `SuggestionBarDelegate`의 `suggestionBarDidTapClipboard`에서 `toggleClipboardPanel()` → `clipboardHistoryCoordinator.togglePanel()`.

10. 파일 끝(Task 4 뒤에는 `SuggestionSelectionHost` extension 위)에 Host 채택 extension을 추가한다.

```swift
// MARK: - ClipboardHistoryHost

extension BaseKeyboardViewController: ClipboardHistoryHost {
    var isPreviewMode: Bool { BaseKeyboardViewController.isPreview }
    var isViewInWindow: Bool { viewIfLoaded?.window != nil }

    func refreshShowingKeyboard() { updateShowingKeyboard() }
    func refreshClipboardControl() { updateClipboardControl() }
    func refreshReturnButtonEnabled() { updateReturnButtonEnabled() }
    func refreshSuggestions() { updateSuggestions() }
    func interruptPendingDeleteInteractions() { cancelPendingDeleteInteractions() }
    func openURL(_ url: URL) { openURLThroughResponderChain(url) }
}
```

`hasFullAccess`, `insertText(_:)`, `commitUndoRedoGroupIgnoringCompositionDeferral()`, `undoRedoEditDidApply()`는 VC에 이미 public/open으로 있어 witness가 된다.

확인:

```sh
F=Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
grep -nE "isClipboardPanelVisible|synchronizeClipboardHistoryIfNeeded|closeClipboardPanelIfNeeded|toggleClipboardPanel\(\)|openClipboardPanel|reloadClipboardPanel|restoreImageToPasteboard|copyTextToPasteboard|hostDidBecomeActive|pasteboardDidChange|clipboardImageDidRecord|isClipboardHistoryAvailable" $F
```

Expected: 출력 없음.

- [ ] **Step 6: 테스트 통과 확인**

```sh
LOG=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad/task3-run2.log
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/ClipboardHistoryCoordinatorTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerSuggestionClipboardBehaviorTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerProxyReadTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerTextInputTests \
  > "$LOG" 2>&1; grep -E "error:|passed|failed" "$LOG" | tail -n 12
```

Expected: 0 failed. Task 1의 테스트 5개는 **수정 없이** 통과해야 한다. 실패하면 Coordinator의 호출 순서가 VC 원본과 다른 것이므로 Coordinator를 고친다. 테스트를 고치지 않는다.

- [ ] **Step 7: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Coordinators/ClipboardHistoryCoordinator.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Utils/ClipboardHistoryCoordinatorTests.swift
git commit -m "$(cat <<'EOF'
refactor: #184 - 클립보드 기록 패널 처리를 ClipboardHistoryCoordinator로 분리

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: `SuggestionSelectionCoordinator` 추출

**Files:**
- Create: `Modules/SYKeyboardCore/Presentation/Utils/Coordinators/SuggestionSelectionCoordinator.swift`
- Create: `SYKeyboardTests/Utils/FakeSuggestionService.swift`
- Create: `SYKeyboardTests/Utils/SuggestionSelectionCoordinatorTests.swift`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Modify: `SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift`

**Interfaces:**
- Consumes: `ClipboardHistoryCoordinator.togglePanel()` (Task 3), `ClipboardHistoryHost`의 `isPreviewMode`, `refreshSuggestions()`, `interruptPendingDeleteInteractions()`, `insertText(_:)` (같은 선언을 이 Host에도 둔다)
- Produces:
  - `protocol SuggestionSelectionHost: AnyObject` — `textDocument`, `currentInputBuffer`, `generalSuggestionBaseText`, `learnableInputBuffer`, `isPreviewMode`, `overlayContainerView`, `insertText(_:)`, `replaceText(deleteCount:insert:)`, `replaceTextWithSmartSpacing(deleteCount:insert:)`, `smartSpacedText(deleteCount:insert:) -> String`, `replaceSelectedText(_:with:)`, `suggestionDidApply()`, `refreshSuggestions()`, `refreshSuggestionPreviewHighlight()`, `undoLastEdit()`, `redoLastEdit()`, `interruptPendingDeleteInteractions()`, `toggleClipboardPanel()`
  - `final class SuggestionSelectionCoordinator: SuggestionControllerDelegate, SuggestionBarDelegate` — `init(suggestionController:suggestionBarView:keyboardSettingsManager:host:)`, `private(set) var currentAutocorrectionType: UITextAutocorrectionType?`, `synchronizeTextInputTraits()`, `shouldShowMathResults() -> Bool`, `captureSentTextSnapshot()`, `recordSentTextIfNeeded()`, `hideSuggestionRemovalConfirmation()`, `@discardableResult applyMathResultSuggestionAction(_:) -> Bool`

- [ ] **Step 1: `FakeSuggestionService` 작성**

```swift
//
//  FakeSuggestionService.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import UIKit

@testable import SYKeyboardCore

/// `SuggestionService` 호출을 기록하고 미리 정한 값을 돌려준다. Coordinator 테스트 전용
final class FakeSuggestionService: SuggestionService {

    // MARK: - Stubbed Values

    var currentMode: SuggestionMode = .typing
    var mathResultActionResult: MathResultSuggestionAction?
    var nGramSuggestionTextResult: String?
    var selectSuggestionResult: (deleteCount: Int, insertText: String)?
    var removableSuggestionTextResult: String?
    var removableBarIndices = IndexSet()
    var sentenceWordsSnapshotResult: [String] = []
    var textReplacementPreviewSuggestionIndexResult: Int?

    // MARK: - Records

    private(set) var calls: [String] = []
    private(set) var learnedWords: [String] = []
    private(set) var recordedWords: [String] = []
    private(set) var removedWords: [String] = []
    private(set) var endedSentences: [(inputBuffer: String, sentenceWords: [String])] = []
    private(set) var selectSuggestionArguments: [(index: Int, baseText: String, textReplacementBaseText: String)] = []
    private(set) var mathResultActionArguments: [(index: Int, selectedText: String?)] = []

    // MARK: - SuggestionService

    weak var delegate: SuggestionControllerDelegate?
    var isPredictiveTextEnabled = true
    var isTextReplacementEnabled = true
    var isShowMathResultsEnabled = true
    var isSuspended = false

    func updateLanguage(to language: String) { calls.append("updateLanguage(\(language))") }
    func preparePredictiveEnginesIfNeeded() { calls.append("preparePredictiveEnginesIfNeeded") }
    func releaseInactiveLanguageEngines() { calls.append("releaseInactiveLanguageEngines") }
    func prepareLexiconEngineIfNeeded() { calls.append("prepareLexiconEngineIfNeeded") }
    func loadLexicon(from inputViewController: UIInputViewController) { calls.append("loadLexicon") }

    func updateSuggestions(
        for baseText: String,
        selectedText: String?,
        mathExpressionText: String,
        textReplacementBaseText: String
    ) {
        calls.append("updateSuggestions(\(baseText))")
    }

    func updateSuggestionsAfterNGramSelection(baseText: String, textReplacementBaseText: String) {
        calls.append("updateSuggestionsAfterNGramSelection(\(baseText), \(textReplacementBaseText))")
    }

    func clearSuggestions() { calls.append("clearSuggestions") }

    func selectSuggestion(
        at index: Int,
        baseText: String,
        textReplacementBaseText: String
    ) -> (deleteCount: Int, insertText: String)? {
        selectSuggestionArguments.append((index, baseText, textReplacementBaseText))
        calls.append("selectSuggestion(\(index), \(baseText))")
        return selectSuggestionResult
    }

    func nGramSuggestionText(at index: Int) -> String? {
        calls.append("nGramSuggestionText(\(index))")
        return nGramSuggestionTextResult
    }

    func removableSuggestionText(atBarIndex index: Int) -> String? {
        calls.append("removableSuggestionText(\(index))")
        return removableSuggestionTextResult
    }

    func invalidateLearnedWordsCache() { calls.append("invalidateLearnedWordsCache") }
    func removeSuggestionWord(_ word: String) { removedWords.append(word) }

    func mathResultAction(at index: Int, selectedText: String?) -> MathResultSuggestionAction? {
        mathResultActionArguments.append((index, selectedText))
        calls.append("mathResultAction(\(index))")
        return mathResultActionResult
    }

    func textReplacementPreviewSuggestionIndex(baseText: String) -> Int? {
        calls.append("textReplacementPreviewSuggestionIndex(\(baseText))")
        return textReplacementPreviewSuggestionIndexResult
    }

    func learnWord(_ word: String) { learnedWords.append(word) }
    func recordWord(_ word: String) { recordedWords.append(word) }
    func endSentence(inputBuffer: String) { endedSentences.append((inputBuffer, [])) }
    func sentenceWordsSnapshot() -> [String] { sentenceWordsSnapshotResult }
    func endSentence(inputBuffer: String, restoringSentenceWords sentenceWords: [String]) {
        endedSentences.append((inputBuffer, sentenceWords))
    }
    func saveNGramData() { calls.append("saveNGramData") }
    func recordUncommittedWords(from inputBuffer: String) { calls.append("recordUncommittedWords(\(inputBuffer))") }
    func removeLastRecordedWord() { calls.append("removeLastRecordedWord") }
    func resetSentenceBuffer() { calls.append("resetSentenceBuffer") }

    func attemptTextReplacement(
        baseText: String,
        documentContextBeforeInput: String?
    ) -> (deleteCount: Int, insertText: String)? {
        calls.append("attemptTextReplacement(\(baseText))")
        return nil
    }
}
```

`selectSuggestion(at:baseText:)`(두 인자)는 `SuggestionService`의 프로토콜 extension이 제공하며 `textReplacementBaseText: baseText`로 세 인자 요구사항을 부른다. 가짜는 세 인자 요구사항만 구현하면 되고, Coordinator는 원본 VC와 같은 두 인자 호출을 그대로 쓴다.

- [ ] **Step 2: 실패하는 Coordinator 테스트 작성**

```swift
//
//  SuggestionSelectionCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("후보 선택 Coordinator", .sharedUserDefaults)
@MainActor
struct SuggestionSelectionCoordinatorTests {

    @Test("수식 모드에서 결과 삽입 action은 삭제 보류를 끊고 삽입 뒤 적용 훅과 갱신을 부름")
    func testMathInsertResultAction() {
        let fixture = makeFixture()
        fixture.service.currentMode = .mathExpression
        fixture.service.mathResultActionResult = .insertResult("5")

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 1)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions", "insertText(5)", "suggestionDidApply", "refreshSuggestions"])
    }

    @Test("수식 원문 확정은 후보만 비우고 적용 훅을 부르지 않음")
    func testMathConfirmOriginalOnlyClears() {
        let fixture = makeFixture()
        fixture.service.currentMode = .mathExpression
        fixture.service.mathResultActionResult = .confirmOriginal

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 0)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions"])
        #expect(fixture.service.calls.contains("clearSuggestions"))
    }

    @Test("n-gram 후보는 기준 텍스트가 공백으로 끝나지 않으면 앞에 공백을 넣음")
    func testNGramSuggestionInsertsLeadingSpace() {
        let fixture = makeFixture()
        fixture.service.currentMode = .nGram
        fixture.service.nGramSuggestionTextResult = "날씨"
        fixture.host.generalSuggestionBaseText = "오늘"
        fixture.host.currentInputBuffer = "오늘"

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 0)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions", "insertText( )", "insertText(날씨)", "suggestionDidApply"])
        #expect(fixture.service.calls.last == "updateSuggestionsAfterNGramSelection(오늘, 오늘)")
    }

    @Test("n-gram 후보는 기준 텍스트가 공백으로 끝나면 바로 삽입")
    func testNGramSuggestionWithoutLeadingSpace() {
        let fixture = makeFixture()
        fixture.service.currentMode = .nGram
        fixture.service.nGramSuggestionTextResult = "날씨"
        fixture.host.generalSuggestionBaseText = "오늘 "

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 0)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions", "insertText(날씨)", "suggestionDidApply"])
    }

    @Test("입력 중 0번 칸은 현재 단어를 학습·기록하고 후보를 비움")
    func testCurrentWordConfirmation() {
        let fixture = makeFixture()
        fixture.service.currentMode = .typing
        fixture.host.learnableInputBuffer = "안녕"

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 0)

        #expect(fixture.host.calls == ["interruptPendingDeleteInteractions"])
        #expect(fixture.service.learnedWords == ["안녕"])
        #expect(fixture.service.recordedWords == ["안녕"])
        #expect(fixture.service.calls.last == "clearSuggestions")
    }

    @Test("입력 중 1번 이상 칸은 현재 단어를 후보로 바꾸고 기록")
    func testInputBufferSuggestionReplacesCurrentWord() {
        let fixture = makeFixture()
        fixture.service.currentMode = .typing
        fixture.service.selectSuggestionResult = (deleteCount: 2, insertText: "안녕하세요")
        fixture.host.generalSuggestionBaseText = "안녕"
        fixture.host.currentInputBuffer = "안녕"

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 2)

        #expect(fixture.service.selectSuggestionArguments.map(\.index) == [1])
        #expect(fixture.host.calls == [
            "interruptPendingDeleteInteractions",
            "replaceTextWithSmartSpacing(2, 안녕하세요)",
            "suggestionDidApply",
            "refreshSuggestions"
        ])
        #expect(fixture.service.recordedWords == ["안녕하세요"])
    }

    @Test("선택 텍스트가 있으면 선택 범위를 후보로 대치")
    func testSelectedTextSuggestionReplacesSelection() {
        let fixture = makeFixture()
        fixture.service.currentMode = .typing
        fixture.proxy.selected = "abc"
        fixture.service.selectSuggestionResult = (deleteCount: 0, insertText: "ABC")

        fixture.coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 1)

        #expect(fixture.service.selectSuggestionArguments.map(\.baseText) == ["abc"])
        #expect(fixture.host.calls == [
            "interruptPendingDeleteInteractions",
            "smartSpacedText(0, ABC)",
            "replaceSelectedText(abc, ABC)",
            "suggestionDidApply",
            "refreshSuggestions"
        ])
    }

    @Test("후보 길게 누르기는 삭제 가능한 단어가 있으면 확인 오버레이를 띄움")
    func testRemovalLongPressShowsConfirmation() {
        let fixture = makeFixture()
        fixture.service.removableSuggestionTextResult = "오늘"

        let began = fixture.coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)

        #expect(began)
        let overlay = fixture.host.overlayContainerView.subviews.compactMap { $0 as? DeleteConfirmOverlayView }.first
        #expect(overlay?.isHidden == false)

        overlay?.onCancel?()
        #expect(overlay?.isHidden == true)
        #expect(fixture.service.removedWords.isEmpty)
    }

    @Test("삭제 확인을 누르면 단어를 자동완성에서 지움")
    func testRemovalConfirmRemovesWord() {
        let fixture = makeFixture()
        fixture.service.removableSuggestionTextResult = "오늘"
        _ = fixture.coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)
        let overlay = fixture.host.overlayContainerView.subviews.compactMap { $0 as? DeleteConfirmOverlayView }.first

        overlay?.onConfirm?()

        #expect(fixture.service.removedWords == ["오늘"])
        #expect(overlay?.isHidden == true)
    }

    @Test("미리보기에서는 후보 길게 누르기와 클립보드 버튼이 동작하지 않음")
    func testPreviewBlocksRemovalAndClipboard() {
        let fixture = makeFixture()
        fixture.host.isPreviewMode = true
        fixture.service.removableSuggestionTextResult = "오늘"

        let began = fixture.coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)
        fixture.coordinator.suggestionBarDidTapClipboard(fixture.bar)

        #expect(began == false)
        #expect(fixture.host.calls.isEmpty)
    }

    @Test("undo·redo·클립보드 버튼은 host로 전달")
    func testToolbarButtonsForwardToHost() {
        let fixture = makeFixture()

        fixture.coordinator.suggestionBarDidTapUndo(fixture.bar)
        fixture.coordinator.suggestionBarDidTapRedo(fixture.bar)
        fixture.coordinator.suggestionBarDidTapClipboard(fixture.bar)

        #expect(fixture.host.calls == ["undoLastEdit", "redoLastEdit", "toggleClipboardPanel"])
    }

    @Test("trait 동기화는 autocorrection을 저장하고 수식 허용 여부를 반영")
    func testSynchronizeTextInputTraits() {
        let fixture = makeFixture()
        let settings = UserDefaultsManager.shared
        let oldMath = settings.isShowMathResultsEnabled
        settings.isShowMathResultsEnabled = true
        defer { settings.isShowMathResultsEnabled = oldMath }
        fixture.proxy.autocorrectionType = .no
        if #available(iOS 18.0, *) {
            fixture.proxy.mathExpressionCompletionType = .no
        }

        fixture.coordinator.synchronizeTextInputTraits()

        #expect(fixture.coordinator.currentAutocorrectionType == .no)
        if #available(iOS 18.0, *) {
            #expect(fixture.coordinator.shouldShowMathResults() == false)
        } else {
            #expect(fixture.coordinator.shouldShowMathResults())
        }
    }

    @Test("전송으로 입력창이 비면 스냅샷의 버퍼로 문장을 끝냄")
    func testSentTextIsRecordedWhenDocumentEmpties() {
        let fixture = makeFixture()
        fixture.host.learnableInputBuffer = "안녕"
        fixture.service.sentenceWordsSnapshotResult = ["어"]
        fixture.proxy.beforeInput = "어 안녕"

        fixture.coordinator.captureSentTextSnapshot()
        fixture.proxy.beforeInput = nil
        fixture.proxy.afterInput = nil
        fixture.proxy.selected = nil
        fixture.coordinator.recordSentTextIfNeeded()

        #expect(fixture.service.endedSentences.count == 1)
        #expect(fixture.service.endedSentences.first?.inputBuffer == "안녕")
        #expect(fixture.service.endedSentences.first?.sentenceWords == ["어"])
    }

    @Test("기록할 입력이 없으면 스냅샷을 만들지 않아 비워져도 문장을 끝내지 않음")
    func testNoSnapshotWithoutLearnableInput() {
        let fixture = makeFixture()
        fixture.host.learnableInputBuffer = "   "

        fixture.coordinator.captureSentTextSnapshot()
        fixture.proxy.beforeInput = nil
        fixture.coordinator.recordSentTextIfNeeded()

        #expect(fixture.service.endedSentences.isEmpty)
    }

    @Test("후보 갱신 알림은 바를 갱신하고 미리보기 하이라이트를 다시 계산")
    func testSuggestionUpdateRefreshesBar() {
        let fixture = makeFixture()
        let controller = SuggestionController(engineFactory: .stub)

        fixture.coordinator.suggestionController(controller, didUpdateCurrentWord: "안녕", suggestions: ["안녕하세요", "안녕히"])
        fixture.bar.layoutIfNeeded()

        #expect(typedSuggestionButtonViews(in: fixture.bar).count == 3)
        #expect(fixture.host.calls == ["refreshSuggestionPreviewHighlight"])
    }

    @Test("host가 해제된 뒤에는 탭·알림이 아무 것도 하지 않음")
    func testReleasedHostIsIgnored() {
        let fixture = makeFixture()
        var host: RecordingSuggestionSelectionHost? = RecordingSuggestionSelectionHost(proxy: fixture.proxy)
        let coordinator = SuggestionSelectionCoordinator(
            suggestionController: fixture.service,
            suggestionBarView: fixture.bar,
            keyboardSettingsManager: .shared,
            host: host!
        )
        host = nil
        fixture.service.currentMode = .mathExpression
        fixture.service.mathResultActionResult = .insertResult("5")

        coordinator.suggestionBar(fixture.bar, didSelectSuggestionAt: 1)
        coordinator.synchronizeTextInputTraits()
        coordinator.recordSentTextIfNeeded()
        let began = coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)

        #expect(began == false)
        #expect(fixture.service.calls.isEmpty)
        #expect(fixture.service.endedSentences.isEmpty)
    }
}

// MARK: - Test Helpers

@MainActor
private final class RecordingSuggestionSelectionHost: SuggestionSelectionHost {
    var calls: [String] = []
    var currentInputBuffer = ""
    var generalSuggestionBaseText = ""
    var learnableInputBuffer = ""
    var isPreviewMode = false
    let overlayContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    let textDocument: CachingTextDocumentProxy

    init(proxy: CountingTextDocumentProxy) {
        textDocument = CachingTextDocumentProxy { proxy }
    }

    func insertText(_ text: String) { calls.append("insertText(\(text))") }
    func replaceText(deleteCount: Int, insert text: String) { calls.append("replaceText(\(deleteCount), \(text))") }
    func replaceTextWithSmartSpacing(deleteCount: Int, insert text: String) {
        calls.append("replaceTextWithSmartSpacing(\(deleteCount), \(text))")
    }
    func smartSpacedText(deleteCount: Int, insert text: String) -> String {
        calls.append("smartSpacedText(\(deleteCount), \(text))")
        return text
    }
    func replaceSelectedText(_ selectedText: String, with insertText: String) {
        calls.append("replaceSelectedText(\(selectedText), \(insertText))")
    }
    func suggestionDidApply() { calls.append("suggestionDidApply") }
    func refreshSuggestions() { calls.append("refreshSuggestions") }
    func refreshSuggestionPreviewHighlight() { calls.append("refreshSuggestionPreviewHighlight") }
    func undoLastEdit() { calls.append("undoLastEdit") }
    func redoLastEdit() { calls.append("redoLastEdit") }
    func interruptPendingDeleteInteractions() { calls.append("interruptPendingDeleteInteractions") }
    func toggleClipboardPanel() { calls.append("toggleClipboardPanel") }
}

@MainActor
private struct Fixture {
    let coordinator: SuggestionSelectionCoordinator
    let host: RecordingSuggestionSelectionHost
    let service: FakeSuggestionService
    let bar: SuggestionBarView
    let proxy: CountingTextDocumentProxy
}

@MainActor
private func makeFixture() -> Fixture {
    let proxy = CountingTextDocumentProxy()
    proxy.beforeInput = nil
    let host = RecordingSuggestionSelectionHost(proxy: proxy)
    let service = FakeSuggestionService()
    let bar = SuggestionBarView(keyboardHStackView: UIStackView())
    bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
    let coordinator = SuggestionSelectionCoordinator(
        suggestionController: service,
        suggestionBarView: bar,
        keyboardSettingsManager: .shared,
        host: host
    )
    service.delegate = coordinator
    bar.suggestionDelegate = coordinator
    return Fixture(coordinator: coordinator, host: host, service: service, bar: bar, proxy: proxy)
}
```

`CachingTextDocumentProxy`의 `init(proxy:)`는 internal이라 `@testable import`로 쓸 수 있다. `CountingTextDocumentProxy.beforeInput`의 기본값이 `"안녕"`이라 fixture에서 `nil`로 비운다.

- [ ] **Step 3: 컴파일 실패 확인**

```sh
LOG=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad/task4-run1.log
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/SuggestionSelectionCoordinatorTests \
  > "$LOG" 2>&1; grep -E "error:|passed|failed" "$LOG" | tail -n 10
```

Expected: `error: cannot find type 'SuggestionSelectionHost' in scope`

- [ ] **Step 4: `SuggestionSelectionCoordinator.swift` 작성**

VC의 Sent Text Recording, SuggestionControllerDelegate, SuggestionBarDelegate, 후보 선택 처리 private extension, Suggestion Removal을 옮긴 것이다. `replaceSelectedText`는 VC에 남기고 `host.replaceSelectedText`로 부른다. `currentDocumentIdentifier()`는 `host.textDocument.documentIdentifier`로 바꾼다(같은 KVC 읽기).

```swift
//
//  SuggestionSelectionCoordinator.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit
import SYKeyboardAssets

/// `SuggestionSelectionCoordinator`가 소유자(`BaseKeyboardViewController`)에게 요구하는 것.
/// `refresh…`/`…LastEdit`/`interrupt…`/`…SmartSpacing`/`smartSpacedText`는 VC의 private 메서드를 감싼 이름이다.
/// `currentInputBuffer`는 VC의 private `inputBuffer`를 읽기 전용으로 노출한다
@MainActor
protocol SuggestionSelectionHost: AnyObject {
    /// VC의 프록시 창구. Coordinator는 이 값을 저장하지 않고 호출마다 읽는다. 캐시 범위가 VC 콜백에 묶여 있기 때문이다
    var textDocument: CachingTextDocumentProxy { get }
    var currentInputBuffer: String { get }
    var generalSuggestionBaseText: String { get }
    var learnableInputBuffer: String { get }
    /// `BaseKeyboardViewController.isPreview`
    var isPreviewMode: Bool { get }
    /// 삭제 확인 오버레이를 올릴 뷰. 키보드 전체를 덮는다
    var overlayContainerView: UIView { get }

    func insertText(_ text: String)
    func replaceText(deleteCount: Int, insert text: String)
    func replaceTextWithSmartSpacing(deleteCount: Int, insert text: String)
    func smartSpacedText(deleteCount: Int, insert text: String) -> String
    func replaceSelectedText(_ selectedText: String, with insertText: String)
    func suggestionDidApply()
    func refreshSuggestions()
    func refreshSuggestionPreviewHighlight()
    func undoLastEdit()
    func redoLastEdit()
    func interruptPendingDeleteInteractions()
    func toggleClipboardPanel()
}

/// 전송 판정과 기록에 쓰는 `textWillChange` 시점의 입력 상태
private struct SentTextSnapshot {
    let inputBuffer: String
    let sentenceWords: [String]
    let documentIdentifier: UUID?
}

/// 후보 바의 탭·길게 누르기·기능 버튼, `SuggestionController`의 후보 갱신 알림, 입력 trait 동기화, 전송 기록, 후보 삭제 확인 오버레이를 맡는다.
/// host는 `weak`다. 바와 컨트롤러의 delegate가 이 객체를 참조하므로 모든 진입점이 `guard let host`로 시작한다
@MainActor
final class SuggestionSelectionCoordinator {

    // MARK: - Properties

    /// host 입력 변경 callback에서 마지막으로 확인한 자동 수정 설정. VC가 바 숨김 판정에 읽는다
    private(set) var currentAutocorrectionType: UITextAutocorrectionType?
    /// host 입력 변경 callback에서 마지막으로 확인한 수식 자동완성 허용 상태
    private var isMathExpressionCompletionAllowed = true
    private var pendingSentTextSnapshot: SentTextSnapshot?
    /// 자동완성 후보 삭제 확인 오버레이. 처음 길게 누를 때 만든다
    private var suggestionRemovalConfirmView: DeleteConfirmOverlayView?
    /// 삭제 확인을 기다리는 자동완성 단어
    private var pendingSuggestionRemovalWord: String?

    private let suggestionController: SuggestionService
    private let suggestionBarView: SuggestionBarView
    private let keyboardSettingsManager: UserDefaultsManager
    private weak var host: SuggestionSelectionHost?

    // MARK: - Initializer

    init(
        suggestionController: SuggestionService,
        suggestionBarView: SuggestionBarView,
        keyboardSettingsManager: UserDefaultsManager,
        host: SuggestionSelectionHost
    ) {
        self.suggestionController = suggestionController
        self.suggestionBarView = suggestionBarView
        self.keyboardSettingsManager = keyboardSettingsManager
        self.host = host
    }

    // MARK: - Internal Methods

    /// `textWillChange`/`textDidChange`의 `withReadCaching` 안에서 VC가 부른다
    func synchronizeTextInputTraits() {
        guard let host else { return }
        currentAutocorrectionType = host.textDocument.autocorrectionType

        if #available(iOS 18.0, *) {
            isMathExpressionCompletionAllowed =
                host.textDocument.mathExpressionCompletionType != .no
        } else {
            isMathExpressionCompletionAllowed = true
        }
    }

    func shouldShowMathResults() -> Bool {
        return KeyboardPresentationStatePolicy.shouldShowMathResults(
            isSettingEnabled: keyboardSettingsManager.isShowMathResultsEnabled,
            isHostCompletionAllowed: isMathExpressionCompletionAllowed
        )
    }

    /// `textWillChange`에서 VC가 부른다. 기록하지 않은 입력이 있을 때만 스냅샷을 만든다
    func captureSentTextSnapshot() {
        guard let host else { return }
        let buffer = host.learnableInputBuffer
        guard buffer.contains(where: { !$0.isWhitespace }) else {
            pendingSentTextSnapshot = nil
            return
        }
        pendingSentTextSnapshot = SentTextSnapshot(
            inputBuffer: buffer,
            sentenceWords: suggestionController.sentenceWordsSnapshot(),
            documentIdentifier: host.textDocument.documentIdentifier
        )
    }

    /// `textDidChange`에서 VC가 부른다. 입력창이 전송으로 비었으면 스냅샷의 마지막 단어까지 기록하고 문장을 끝낸다
    func recordSentTextIfNeeded() {
        guard let host, let snapshot = pendingSentTextSnapshot else { return }
        pendingSentTextSnapshot = nil
        guard KeyboardSentTextDetectionPolicy.isSentAfterTextChange(
            documentIdentifierBeforeChange: snapshot.documentIdentifier,
            documentIdentifierAfterChange: host.textDocument.documentIdentifier,
            beforeInput: host.textDocument.documentContextBeforeInput,
            afterInput: host.textDocument.documentContextAfterInput,
            selectedText: host.textDocument.selectedText,
            returnKeyType: host.textDocument.returnKeyType
        ) else { return }

        suggestionController.endSentence(
            inputBuffer: snapshot.inputBuffer,
            restoringSentenceWords: snapshot.sentenceWords
        )
    }

    /// `viewWillDisappear`에서 VC가 부른다
    func hideSuggestionRemovalConfirmation() {
        pendingSuggestionRemovalWord = nil
        suggestionRemovalConfirmView?.isHidden = true
    }

    /// `viewWillDisappear`에서 VC가 부른다. 키보드가 내려가면 전송 판정 대상이 없다
    func discardSentTextSnapshot() {
        pendingSentTextSnapshot = nil
    }

    /// 수식 결과 action을 적용한다. 스페이스 입력 경로에서도 VC가 부른다
    @discardableResult
    func applyMathResultSuggestionAction(_ action: MathResultSuggestionAction) -> Bool {
        guard let host else { return false }
        switch action {
        case .confirmOriginal:
            suggestionController.clearSuggestions()
        case .insertResult(let text):
            host.insertText(text)
        case .replaceExpression(let deleteCount, let insertText):
            host.replaceText(deleteCount: deleteCount, insert: insertText)
        case .replaceSelection(let text):
            guard let selectedText = host.textDocument.selectedText,
                  !selectedText.isEmpty else { return false }
            host.replaceSelectedText(selectedText, with: text)
        }
        return true
    }
}

// MARK: - Private Methods

private extension SuggestionSelectionCoordinator {
    func handleSelectedTextSuggestion(at index: Int, host: SuggestionSelectionHost) -> Bool {
        guard let selectedText = host.textDocument.selectedText,
              !selectedText.isEmpty else { return false }

        if index == 0 {
            // 현재 선택된 단어 확정, 후보 비우기
            suggestionController.clearSuggestions()
            return true
        }

        let suggestionIndex = index - 1
        guard suggestionIndex >= 0,
              let result = suggestionController.selectSuggestion(
                at: suggestionIndex,
                baseText: selectedText
              ) else { return true }

        let insertText = host.smartSpacedText(
            deleteCount: 0,
            insert: result.insertText
        )

        host.replaceSelectedText(selectedText, with: insertText)

        host.suggestionDidApply()
        host.refreshSuggestions()
        return true
    }

    func handleMathResultSuggestion(at index: Int, host: SuggestionSelectionHost) -> Bool {
        guard suggestionController.currentMode == .mathExpression else { return false }

        guard let action = suggestionController.mathResultAction(
            at: index,
            selectedText: host.textDocument.selectedText
        ) else { return true }
        guard applyMathResultSuggestionAction(action) else { return true }

        if case .confirmOriginal = action {
            return true
        } else {
            host.suggestionDidApply()
            host.refreshSuggestions()
        }
        return true
    }

    func handleNGramSuggestion(at index: Int, host: SuggestionSelectionHost) -> Bool {
        guard suggestionController.currentMode == .nGram else { return false }
        guard let word = suggestionController.nGramSuggestionText(at: index) else { return true }

        if KeyboardSuggestionSelectionPolicy.shouldInsertLeadingSpaceBeforeNGramSuggestion(
            baseText: host.generalSuggestionBaseText
        ) {
            host.insertText(" ")
        }

        host.insertText(word)

        host.suggestionDidApply()

        suggestionController.updateSuggestionsAfterNGramSelection(
            baseText: host.generalSuggestionBaseText,
            textReplacementBaseText: host.currentInputBuffer
        )
        return true
    }

    func handleCurrentWordConfirmationIfNeeded(at index: Int, host: SuggestionSelectionHost) -> Bool {
        guard index == 0 else { return false }

        let currentWord = KeyboardSuggestionSelectionPolicy.currentWordForConfirmation(
            inputBuffer: host.learnableInputBuffer
        )
        if !currentWord.isEmpty {
            suggestionController.learnWord(currentWord)
            suggestionController.recordWord(currentWord)
        }
        suggestionController.clearSuggestions()
        return true
    }

    func handleInputBufferSuggestion(at index: Int, host: SuggestionSelectionHost) {
        let suggestionIndex = index - 1
        guard let result = suggestionController.selectSuggestion(
            at: suggestionIndex,
            baseText: host.generalSuggestionBaseText,
            textReplacementBaseText: host.currentInputBuffer
        ) else { return }

        host.replaceTextWithSmartSpacing(
            deleteCount: result.deleteCount,
            insert: result.insertText
        )

        suggestionController.recordWord(result.insertText)

        host.suggestionDidApply()
        host.refreshSuggestions()
    }

    // MARK: Suggestion Removal

    func showSuggestionRemovalConfirmation(for word: String, host: SuggestionSelectionHost) {
        let overlay = suggestionRemovalConfirmView ?? makeSuggestionRemovalConfirmView(in: host.overlayContainerView)
        pendingSuggestionRemovalWord = word
        overlay.update(
            title: String(localized: "'\(word)'을(를) 자동완성에서 삭제할까요?", bundle: SYKBDAssets.bundle),
            message: String(localized: "다시 입력하면 다시 학습됩니다.", bundle: SYKBDAssets.bundle)
        )
        // 나중에 붙은 오버레이보다 위에 보이도록 매번 앞으로 가져온다
        host.overlayContainerView.bringSubviewToFront(overlay)
        overlay.isHidden = false
        FeedbackManager.shared.playHaptic()
    }

    func confirmSuggestionRemoval() {
        guard let word = pendingSuggestionRemovalWord else { return }
        hideSuggestionRemovalConfirmation()
        suggestionController.removeSuggestionWord(word)
    }

    /// 키보드 전체를 덮어 확인하는 동안 키 입력을 막는다
    func makeSuggestionRemovalConfirmView(in container: UIView) -> DeleteConfirmOverlayView {
        let overlay = DeleteConfirmOverlayView()
        overlay.isHidden = true
        overlay.onCancel = { [weak self] in self?.hideSuggestionRemovalConfirmation() }
        overlay.onConfirm = { [weak self] in self?.confirmSuggestionRemoval() }
        container.addSubview(overlay)

        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: container.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        suggestionRemovalConfirmView = overlay
        return overlay
    }
}

// MARK: - SuggestionControllerDelegate

extension SuggestionSelectionCoordinator: SuggestionControllerDelegate {
    func suggestionController(_ controller: SuggestionController, didUpdateCurrentWord currentWord: String?, suggestions: [String]) {
        guard let host else { return }
        if controller.currentMode == .mathExpression {
            suggestionBarView.updateSuggestions(
                currentWord: nil,
                suggestions: suggestions
            )
        } else {
            // 길게 눌러 삭제할 수 있는 칸만 medium으로 표시한다. 삭제가 막힌 미리보기에서는 표시도 하지 않는다
            let removableIndices = host.isPreviewMode ? IndexSet() : controller.removableBarIndices
            suggestionBarView.updateSuggestions(
                currentWord: currentWord,
                suggestions: suggestions,
                removableIndices: removableIndices
            )
        }

        host.refreshSuggestionPreviewHighlight()
    }
}

// MARK: - SuggestionBarDelegate

extension SuggestionSelectionCoordinator: SuggestionBarDelegate {
    func suggestionBar(_ bar: SuggestionBarView, didSelectSuggestionAt index: Int) {
        guard let host else { return }
        host.interruptPendingDeleteInteractions()
        if handleMathResultSuggestion(at: index, host: host) { return }
        if handleSelectedTextSuggestion(at: index, host: host) { return }
        if handleNGramSuggestion(at: index, host: host) { return }
        if handleCurrentWordConfirmationIfNeeded(at: index, host: host) { return }
        handleInputBufferSuggestion(at: index, host: host)
    }

    func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool {
        guard let host, !host.isPreviewMode,
              let word = suggestionController.removableSuggestionText(atBarIndex: index) else { return false }
        showSuggestionRemovalConfirmation(for: word, host: host)
        return true
    }

    func suggestionBarDidTapUndo(_ bar: SuggestionBarView) {
        host?.undoLastEdit()
    }

    func suggestionBarDidTapRedo(_ bar: SuggestionBarView) {
        host?.redoLastEdit()
    }

    func suggestionBarDidTapClipboard(_ bar: SuggestionBarView) {
        // 미리보기는 실제 키보드와 같은 모습을 보여주는 것이 목적이라 버튼을 비활성으로 만들지 않고,
        // 패널만 열지 않는다. undo/redo가 미리보기에서 회색인 것은 세션이 비어 canUndo가 false이기 때문이다
        guard let host, !host.isPreviewMode else { return }
        host.toggleClipboardPanel()
    }
}
```

`handle…` 메서드들은 `host`를 인자로 받는다. 진입점(`suggestionBar(_:didSelectSuggestionAt:)`)에서 한 번 `guard let host`를 통과한 강한 참조를 넘겨, 처리 중간에 host가 사라져 절반만 실행되는 일이 없게 한다.

- [ ] **Step 5: pbxproj에 `SuggestionSelectionCoordinator.swift` 등록**

두 타깃의 membershipExceptions에서 `SYKeyboardCore/Presentation/Utils/Coordinators/HangeulEnglishKeyboardModeCoordinator.swift,` 줄 바로 아래에 넣는다. 두 곳 모두.

```
				SYKeyboardCore/Presentation/Utils/Coordinators/SuggestionSelectionCoordinator.swift,
```

확인:

```sh
grep -c 'Coordinators/SuggestionSelectionCoordinator.swift' SYKeyboard.xcodeproj/project.pbxproj
```

Expected: `2`

- [ ] **Step 6: VC에서 후보 선택 섹션을 Coordinator 호출로 교체**

`BaseKeyboardViewController.swift`를 아래 순서로 고친다.

1. **삭제**: `// MARK: - Sent Text Recording` 전체(`private struct SentTextSnapshot` 포함), `// MARK: - SuggestionControllerDelegate` extension, `// MARK: - SuggestionBarDelegate` extension, Task 3에서 남겨 둔 후보 선택 처리 `private extension`(`synchronizeTextInputTraits`부터 `handleInputBufferSuggestion`까지. **단 `replaceSelectedText`는 잠시 복사해 둔다**), `// MARK: - Suggestion Removal` extension.

2. **Properties 삭제**: `private var suggestionRemovalConfirmView: DeleteConfirmOverlayView?`, `private var pendingSuggestionRemovalWord: String?`, `private var pendingSentTextSnapshot: SentTextSnapshot?`, `private var currentAutocorrectionType: UITextAutocorrectionType?`, `private var isMathExpressionCompletionAllowed = true`와 각 doc 주석.

3. **Coordinator 소유**: UI Components 섹션의 `private lazy var suggestionBarView = keyboardView.suggestionBarView` 바로 아래에 추가.

```swift
    /// 후보 탭 처리·trait 동기화·전송 기록·후보 삭제 확인을 맡는다. `SuggestionSelectionHost` 채택은 파일 끝의 extension에 있다
    private lazy var suggestionSelectionCoordinator = SuggestionSelectionCoordinator(
        suggestionController: suggestionController,
        suggestionBarView: suggestionBarView,
        keyboardSettingsManager: keyboardSettingsManager,
        host: self
    )
```

4. **`shouldHideSuggestionBar`**의 `autocorrectionType: currentAutocorrectionType` → `autocorrectionType: suggestionSelectionCoordinator.currentAutocorrectionType`. **`updateSuggestionBarHidden`**(약 1482줄)의 `autocorrectionType: currentAutocorrectionType` → 같게.

5. **`viewDidLoad`**: `suggestionController.isShowMathResultsEnabled = shouldShowMathResults()` → `= suggestionSelectionCoordinator.shouldShowMathResults()`.

6. **`textWillChange`**: `synchronizeTextInputTraits()` → `suggestionSelectionCoordinator.synchronizeTextInputTraits()`. `pendingSentTextSnapshot = makeSentTextSnapshot()` → `suggestionSelectionCoordinator.captureSentTextSnapshot()`.

7. **`textDidChange`**: `synchronizeTextInputTraits()` → `suggestionSelectionCoordinator.synchronizeTextInputTraits()`. `recordSentTextIfNeeded()` → `suggestionSelectionCoordinator.recordSentTextIfNeeded()`.

8. **`viewWillDisappear`**: `hideSuggestionRemovalConfirmation()` → `suggestionSelectionCoordinator.hideSuggestionRemovalConfirmation()`. `pendingSentTextSnapshot = nil` → `suggestionSelectionCoordinator.discardSentTextSnapshot()`. 호출 순서는 그대로 둔다.

9. **`setDelegates()`**: `suggestionController.delegate = self` → `= suggestionSelectionCoordinator`, `suggestionBarView.suggestionDelegate = self` → `= suggestionSelectionCoordinator`.

10. **`updateSuggestionsForCurrentContext`**: `suggestionController.isShowMathResultsEnabled = shouldShowMathResults()` → `= suggestionSelectionCoordinator.shouldShowMathResults()`.

11. **스페이스 입력 경로**(Text Interaction Methods, `case .spaceButton:`): `applyMathResultSuggestionAction(action)` → `suggestionSelectionCoordinator.applyMathResultSuggestionAction(action)`.

12. **`// MARK: - Cursor Context Suggestions`**: `private extension`에서 `generalSuggestionBaseText`와 `learnableInputBuffer` 두 계산 프로퍼티를 잘라 낸다. `captureInputBufferLeadingContextIfNeeded`만 남는다.

13. **Text Proxy Wrapper Methods**(`public func replaceText(deleteCount:insert:)` 아래)에 1번에서 복사해 둔 `replaceSelectedText`를 넣는다. 접근 제어는 internal(아무 수식어 없음)로 둔다. Host witness가 되어야 하기 때문이다.

```swift
    /// 선택 영역을 `insertText`로 대치하고 `inputBuffer`와 undo 기록을 맞춘다. 후보 선택과 수식 결과 대치가 쓴다
    func replaceSelectedText(_ selectedText: String, with insertText: String) {
        captureInputBufferLeadingContextIfNeeded()
        textDocument.insertText(insertText)
        inputBuffer.append(insertText)
        recordUndoRedoChange(
            deletedText: selectedText,
            insertedText: insertText
        )
    }
```

14. **Host 채택 extension**을 파일 끝, `// MARK: - ClipboardHistoryHost` extension 위에 추가한다. 12번에서 잘라 낸 두 프로퍼티는 여기로 온다.

```swift
// MARK: - SuggestionSelectionHost

extension BaseKeyboardViewController: SuggestionSelectionHost {
    var currentInputBuffer: String { inputBuffer }

    /// 일반 후보(n-gram·TextChecker)의 기준 텍스트
    ///
    /// 버퍼가 있으면 떠 둔 앞 문맥을 쓰므로 프록시 문맥을 읽지 않는다(키 입력마다 프록시 왕복을 늘리지 않음)
    var generalSuggestionBaseText: String {
        KeyboardSuggestionSelectionPolicy.generalSuggestionBaseText(
            leadingContext: inputBufferLeadingContext,
            inputBuffer: inputBuffer,
            documentContextBeforeInput: inputBuffer.isEmpty ? textDocument.documentContextBeforeInput : nil
        )
    }

    /// 앞 글자에 붙어 시작한 조각을 뺀 버퍼. NGram 기록과 현재 단어 확정에 쓴다
    var learnableInputBuffer: String {
        KeyboardSuggestionSelectionPolicy.learnableInputBuffer(
            inputBuffer,
            isAttachedToLeadingContext: KeyboardSuggestionSelectionPolicy.isInputBufferAttachedToLeadingContext(
                inputBufferLeadingContext
            )
        )
    }

    var overlayContainerView: UIView { view }

    func replaceTextWithSmartSpacing(deleteCount: Int, insert text: String) {
        replaceTextWithSmartInsertDeleteSpacing(deleteCount: deleteCount, insert: text)
    }

    func smartSpacedText(deleteCount: Int, insert text: String) -> String {
        textWithSmartInsertDeleteLeadingSpace(deleteCount: deleteCount, insert: text)
    }

    func refreshSuggestionPreviewHighlight() { updateSuggestionPreviewHighlight() }
    func undoLastEdit() { performUndo() }
    func redoLastEdit() { performRedo() }
    func toggleClipboardPanel() { clipboardHistoryCoordinator.togglePanel() }
}
```

`isPreviewMode`, `refreshSuggestions()`, `interruptPendingDeleteInteractions()`는 Task 3의 `ClipboardHistoryHost` extension에 이미 있어 두 프로토콜의 witness가 된다. `textDocument`, `insertText`, `replaceText`, `replaceSelectedText`, `suggestionDidApply`도 VC 본문에 있다.

확인:

```sh
F=Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
grep -nE "SentTextSnapshot|makeSentTextSnapshot|recordSentTextIfNeeded\(\)$|currentDocumentIdentifier|synchronizeTextInputTraits\(\)$|handleMathResultSuggestion|handleNGramSuggestion|showSuggestionRemovalConfirmation|suggestionRemovalConfirmView|pendingSuggestionRemovalWord|currentAutocorrectionType\b[^.]|isMathExpressionCompletionAllowed|SuggestionBarDelegate|SuggestionControllerDelegate" $F
```

Expected: 출력 없음.

- [ ] **Step 7: `ProxyReadTests`의 delegate 호출 경로 조정**

`BaseKeyboardViewControllerProxyReadTests.swift`의 `testNonMathSuggestionUpdateDoesNotReadProxy`에서

```swift
        // 넘기는 controller는 표시 분기에만 쓰인다. 하이라이트는 VC 자신의 controller(기본 nGram 모드)를 본다
        controller.suggestionController(
            SuggestionController(),
            didUpdateCurrentWord: "안녕",
            suggestions: ["안녕하세요"]
        )
```

를 다음으로 바꾼다.

```swift
        // 후보 갱신 알림은 production 연결(`suggestionBarView.suggestionDelegate`)이 가리키는 Coordinator가 받는다.
        // 넘기는 controller는 표시 분기에만 쓰인다. 하이라이트는 VC 자신의 controller(기본 nGram 모드)를 본다
        let bar = (controller.view as! KeyboardView).suggestionBarView
        let suggestionDelegate = bar.suggestionDelegate as? SuggestionControllerDelegate
        #expect(suggestionDelegate != nil)
        suggestionDelegate?.suggestionController(
            SuggestionController(),
            didUpdateCurrentWord: "안녕",
            suggestions: ["안녕하세요"]
        )
```

- [ ] **Step 8: 테스트 통과 확인**

```sh
LOG=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad/task4-run2.log
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/SuggestionSelectionCoordinatorTests \
  -only-testing:SYKeyboardTests/ClipboardHistoryCoordinatorTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerSuggestionClipboardBehaviorTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerProxyReadTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerTextInputTests \
  > "$LOG" 2>&1; grep -E "error:|passed|failed" "$LOG" | tail -n 12
```

Expected: 0 failed. Task 1의 테스트 5개(특히 "수식 후보 탭의 프록시 문맥 읽기 횟수")가 **수정 없이** 통과해야 한다. 읽기 횟수가 달라졌으면 Coordinator가 `host.textDocument`를 원본보다 더 읽거나 덜 읽는 것이다. Coordinator를 고친다.

- [ ] **Step 9: 커밋**

```sh
git add Modules/SYKeyboardCore/Presentation/Utils/Coordinators/SuggestionSelectionCoordinator.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Utils/FakeSuggestionService.swift \
  SYKeyboardTests/Utils/SuggestionSelectionCoordinatorTests.swift \
  SYKeyboardTests/Controller/BaseKeyboardViewControllerProxyReadTests.swift
git commit -m "$(cat <<'EOF'
refactor: #184 - 후보 선택·전송 기록·후보 삭제 확인을 SuggestionSelectionCoordinator로 분리

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: 전체 검증

**Files:**
- Modify: 이 계획 문서(결과 기록). 코드 변경 없음(검증 중 발견한 문제는 원인 Task로 돌아가 고치고 그 Task 커밋에 포함하지 않고 `fix: #184 - …`로 따로 커밋한다)

- [ ] **Step 1: 전체 테스트**

```sh
LOG=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad/task5-test.log
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  > "$LOG" 2>&1; grep -E "Executed [0-9]+ tests|Test Suite 'All tests'|failed" "$LOG" | tail -n 5
```

Expected: `Executed N tests, with 0 failures`. N은 기준선 894 + 새 테스트(Task 1: 5, Task 2: 3, Task 3: 8, Task 4: 16) = 926 이상. 실제 값을 이 계획 문서의 Step 아래에 적는다.

- [ ] **Step 2: 4개 scheme 빌드**

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d06648d3-2f18-46d7-878c-aad816a12ce3/scratchpad
for scheme in SYKeyboard HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    > "$S/task5-build-$scheme.log" 2>&1; echo "$scheme: $(grep -E '\*\* BUILD (SUCCEEDED|FAILED) \*\*' "$S/task5-build-$scheme.log")"
done
git status --short
```

Expected: 4개 모두 `** BUILD SUCCEEDED **`. `git status --short`에 `.xcscheme`이 보이면 내용을 확인하고 `RemotePath`만 바뀐 경우 `git checkout -- SYKeyboard.xcodeproj/xcshareddata/xcschemes/<이름>.xcscheme`으로 되돌린다.

- [ ] **Step 3: 정적 확인**

```sh
echo "--- textDocumentProxy 직접 참조 (1줄이어야 함) ---"
grep -rn "textDocumentProxy" Modules Keyboards | grep -v -E ":[0-9]+:[[:space:]]*//"
echo "--- VC 줄 수 ---"
wc -l Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
echo "--- VC 저장 프로퍼티 접근 제어 분포 (internal 저장 프로퍼티가 늘지 않았어야 함) ---"
F=Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
echo "기준(c68a3a1f):"; git show c68a3a1f:$F | sed -n '15,282p' | grep -cE "^\s+(final )?(lazy )?(var|let) "
echo "현재:";          sed -n "15,$(grep -n '// MARK: - Initializer' $F | cut -d: -f1)p" $F | grep -cE "^\s+(final )?(lazy )?(var|let) "
echo "--- 새 lazy Coordinator 2개는 private인지 ---"
grep -nE "lazy var (suggestionSelectionCoordinator|clipboardHistoryCoordinator)" $F
```

Expected: 첫 grep은 `BaseKeyboardViewController.swift`의 `return self.textDocumentProxy` 한 줄. 줄 수는 2700 아래(실측값을 기록). 접근 수식어 없는(`internal`) 저장 프로퍼티 수는 기준보다 **1 적어야** 한다(`final var isClipboardPanelVisible` 삭제). 두 Coordinator는 `private lazy var`.

- [ ] **Step 4: 시뮬레이터 확인**

CLAUDE.md의 `iPhone 13 mini / iOS 18.6`에 `HangeulKeyboard` scheme으로 키보드를 설치하고 메모리 `reference-idb-simulator-quirks`의 방법(메시지 더미 대화, 로컬 http 서버의 웹 입력창)으로 아래를 직접 확인한다. 각 항목의 결과를 이 Step 아래에 `- [x] 항목 — 결과`로 적는다.

- 후보 탭: 두벌식에서 "안녕"을 치고 후보를 탭해 현재 단어가 바뀌는지, n-gram 후보 탭 시 앞 단어와 공백이 맞는지
- 후보 길게 누르기: 학습된 후보를 길게 눌러 확인 오버레이가 뜨고, 취소하면 사라지고, 확인하면 후보에서 빠지는지
- 수식 후보: "3-1=" 입력 뒤 결과 후보 탭, 그리고 스페이스로 적용
- 전송 뒤 NGram 기록: 메시지 앱에서 "오늘 날씨" 전송 뒤 "오늘"을 치면 "날씨"가 후보에 오르는지
- 클립보드 패널: 설정에서 클립보드 기록을 켜고 Full Access 허용 뒤, 버튼으로 열기·닫기, 텍스트 항목 탭으로 붙여넣기와 패널 닫힘, Mac에서 복사한 뒤 시뮬레이터로 돌아왔을 때 목록 갱신
- 전체 접근 안내: Full Access를 끈 상태에서 오버레이 표시, 닫기, 설정 이동 버튼으로 SY키보드 앱이 열리는지
- 미리보기: 메인 앱의 키보드 미리보기에서 클립보드 버튼이 패널을 열지 않는지

시뮬레이터로 확인할 수 없는 항목은 PR 본문에 "실기기 확인 필요"로 남긴다: 햅틱(후보 삭제 확인 표시 시), 클립보드 이미지 항목 복원(시뮬레이터에서 이미지 복사가 되면 확인).

- [ ] **Step 5: 결과 기록 커밋**

이 계획 문서의 Task 5 각 Step 아래에 실제 명령 결과(테스트 개수, 빌드 결과, 줄 수, 시뮬레이터 항목별 결과, 미확인 항목과 이유)를 적고 커밋한다.

```sh
git add docs/superpowers/plans/2026-10-08-base-keyboard-view-controller-coordinator-extraction.md
git commit -m "$(cat <<'EOF'
docs: #184 - Coordinator 추출 검증 결과 기록

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: 문서 갱신

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/architecture/전체 아키텍처.md`
- Modify: `docs/architecture/자동완성 로직.md`
- Modify: `docs/architecture/삭제와 실행취소 로직.md`
- Modify: `docs/architecture/한영 통합 키보드.md`
- Modify: `README.md`

사실과 다른 문장을 고치는 것이 목적이다. 설계 배경을 길게 쓰지 않는다. 각 파일을 **먼저 읽고** 아래 위치를 찾아 고친다. 줄 번호는 기준 커밋 기준이라 어긋날 수 있다.

- [ ] **Step 1: `CLAUDE.md`**

아키텍처 절의 트리에서

```
└── BaseKeyboardViewController          (SYKeyboardCore, ~2400줄, 입력 흐름의 중심)
```

의 `~2400줄`을 Task 5 Step 3에서 측정한 줄 수(백 단위로 반올림, 예: `~2600줄`)로 바꾼다. 그 아래 "`BaseKeyboardViewController`가 텍스트 프록시 조작, 제스처, 자동완성, undo/redo, 높이·한손 모드, `textWillChange`/`textDidChange` 동기화를 전담한다." 문단 끝에 한 문장을 덧붙인다.

```
후보 탭 처리·전송 기록·후보 삭제 확인은 `SuggestionSelectionCoordinator`, 클립보드 패널·pasteboard 동기화는
`ClipboardHistoryCoordinator`가 맡는다. 둘은 `Presentation/Utils/Coordinators/`에 있고 VC를 `weak` Host 프로토콜
(`SuggestionSelectionHost`, `ClipboardHistoryHost`)로 역참조하며, 프록시는 Host가 노출하는 `textDocument`만 쓴다.
```

"자동완성은 `SuggestionController` 한 곳으로 모인다" 문단의 "`SuggestionBarView`가 표시한다" 뒤에 "후보 탭은 `SuggestionSelectionCoordinator`가 받는다."를 추가한다.

- [ ] **Step 2: `docs/architecture/전체 아키텍처.md`**

- 약 60줄 "`SuggestionController`(프로토콜 `SuggestionService`) 보유, `SuggestionBarDelegate`/`SuggestionControllerDelegate` 구현." → "`SuggestionController`(프로토콜 `SuggestionService`) 보유. `SuggestionBarDelegate`/`SuggestionControllerDelegate`는 `SuggestionSelectionCoordinator`가 구현하고 VC는 `SuggestionSelectionHost`로 텍스트 삽입·후보 갱신을 제공한다."
- 라이프사이클 표의 `viewWillAppear` 행 "클립보드 기록 동기화(`synchronizeClipboardHistoryIfNeeded`)" → "클립보드 기록 동기화(`ClipboardHistoryCoordinator.synchronizeIfNeeded`)".
- `textWillChange` 행의 "전송 감지용 스냅샷(`makeSentTextSnapshot`)" → "전송 감지용 스냅샷(`SuggestionSelectionCoordinator.captureSentTextSnapshot`)". 같은 행에 `closeClipboardPanelIfNeeded`가 있으면 `ClipboardHistoryCoordinator.closePanelIfNeeded`로.
- `textDidChange` 행의 "`recordSentTextIfNeeded`" → "`SuggestionSelectionCoordinator.recordSentTextIfNeeded`".
- VC 책임 목록이나 디렉터리 설명에 `Coordinators/`가 `HangeulEnglishKeyboardModeCoordinator`만 언급하면 두 Coordinator를 한 줄씩 추가한다.

- [ ] **Step 3: `docs/architecture/자동완성 로직.md`**

- 약 20줄 흐름도의 `↓ (SuggestionControllerDelegate)` 화살표가 VC를 가리키면 `SuggestionSelectionCoordinator`를 가리키게 바꾸고, 바 갱신 뒤 `host.refreshSuggestionPreviewHighlight()`로 VC의 미리보기 하이라이트를 다시 계산한다고 적는다.
- §6 "후보 탭 처리 — SuggestionBarDelegate" 첫 문단에 구현 위치를 적는다: "`SuggestionSelectionCoordinator`(`Presentation/Utils/Coordinators/`)가 `SuggestionBarDelegate`를 구현한다. 텍스트 삽입·대치, 적용 훅(`suggestionDidApply`), 후보 갱신은 `SuggestionSelectionHost`로 VC에 요청한다." 1\~5 단계 목록의 함수 이름은 그대로 유효하다(이름을 바꾸지 않았다).
- 선택 텍스트 대치 설명에 `replaceSelectedText`가 있으면 "VC의 Text Proxy Wrapper에 있다"고 적는다.

- [ ] **Step 4: `docs/architecture/삭제와 실행취소 로직.md`**

약 125줄 "undo/redo 적용(`performUndo`/`performRedo`)과 클립보드 패널 열기(`openClipboardPanel`)도 같은 취소를 먼저 수행한다." → "undo/redo 적용(`performUndo`/`performRedo`)과 클립보드 패널 열기(`ClipboardHistoryCoordinator.openPanel` → `host.interruptPendingDeleteInteractions()`)도 같은 취소를 먼저 수행한다."

- [ ] **Step 5: `docs/architecture/한영 통합 키보드.md`**

- 약 41줄 "클립보드 패널이 열려 있으면(`isClipboardPanelVisible`)" → "클립보드 패널이 열려 있으면(`ClipboardHistoryCoordinator.isPanelVisible`)".
- 약 225줄 전체 접근 안내 오버레이 설명에서 VC가 설치한다는 문장을 "`BaseKeyboardViewController`가 `viewDidLoad` 마지막에 `RequestFullAccessOverlayView.install(in:onClose:onOpenSettings:)`로 올린다"로 바꾼다.

- [ ] **Step 6: `README.md` 다이어그램**

"전체 구조" flowchart에서

```
    Toolbar -->|후보 탭 · undo/redo · 패널 열기| BaseVC
    ClipboardPanel -->|항목 탭 · 편집| BaseVC
```

를 다음으로 바꾸고, `Suggestion`·`ClipboardStore` 노드 위에 Coordinator 노드 2개를 추가한다.

```
    SuggestionCoord["SuggestionSelectionCoordinator"]
    ClipboardCoord["ClipboardHistoryCoordinator"]
    Toolbar -->|후보 탭 · undo/redo · 패널 열기| SuggestionCoord
    ClipboardPanel -->|항목 탭 · 편집| ClipboardCoord
    SuggestionCoord -->|Host: 삽입 · 후보 갱신 · undo/redo| BaseVC
    ClipboardCoord -->|Host: 삽입 · 자판 갱신| BaseVC
    SuggestionCoord -->|후보 선택 · 학습| Suggestion
    ClipboardCoord -->|기록 조회 · 저장| ClipboardStore
```

기존 `BaseVC -->|후보 조회 · 학습| Suggestion`은 유지한다(후보 갱신 요청은 VC가 한다). `BaseVC -->|기록 조회 · 저장| ClipboardStore`는 삭제한다(VC는 저장소를 소유만 하고 읽고 쓰지 않는다).

"ViewController · InputAdapter 구조" classDiagram의 `BaseKeyboardViewController *-- TenkeyKeyboardLayoutProvider: Composition` 아래에 추가한다.

```
    BaseKeyboardViewController *-- SuggestionSelectionCoordinator: Composition
    BaseKeyboardViewController *-- ClipboardHistoryCoordinator: Composition
```

- [ ] **Step 7: 물결표 규칙 확인과 커밋**

```sh
grep -nE '[^\\`]~[^`]' CLAUDE.md README.md docs/architecture/*.md | grep -v "http" || echo "물결표 위반 없음"
git add CLAUDE.md README.md docs/architecture/
git commit -m "$(cat <<'EOF'
docs: #184 - 문서에 후보 선택·클립보드 Coordinator 구조 반영

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

이미 있던 위반(이번 변경과 무관한 줄)은 고치지 않고 결과에 적는다.

---

## PR

제목: `Refactor/#184 BaseKeyboardViewController에서 후보 선택·클립보드·전체 접근 안내를 별도 타입으로 추출`

본문은 `.github/pull_request_template.md`를 따른다. 연관된 이슈 `- #184`. UI 변경이 없으므로 `## 📸 스크린샷` 절은 표까지 통째로 뺀다. 검증 항목에 Task 5의 실제 명령·결과·미확인 항목을 적는다. 본문에 범위 물결표가 있으면 `\~`. PR 생성과 push는 사용자가 지시할 때만 한다.

## 최종 리뷰 반영 (2026-10-08)

브랜치 전체 리뷰(Critical 0, Important 0, Minor 4) 뒤 사용자 결정으로 Minor 1·2·4를 반영했다.

- Minor 1: `replaceSelectedText` 위 빈 줄 2개 → 1개.
- Minor 2: `SuggestionSelectionHost`의 `generalSuggestionBaseText`/`learnableInputBuffer` 요구사항을 `suggestionBaseText`/`learnableWordText`로 바꾸고, VC의 두 계산 프로퍼티는 Cursor Context Suggestions `private extension`으로 되돌린 뒤 Host 채택 extension에서 한 줄씩 전달한다. 이로써 Host 요구사항은 모두 "VC의 private 멤버와 다른 이름으로 전달" 규칙을 따른다. Task 4의 Interfaces 블록에 적힌 옛 이름 두 개는 이 메모가 대체한다.
- Minor 4: `ClipboardHistoryCoordinatorTests.testReleasedHostIsIgnored`에 `pasteboardDidChange()` 호출 뒤 런루프 한 틱을 돌리고 패널이 비어 있는지 확인하는 단언 추가.
- Minor 3(고정 테스트가 실제 App Group 저장소에 기록 후 삭제)은 VC의 `clipboardHistoryStore`가 고정 생성이라 주입 없이 고칠 수 없어 반영하지 않았다. PR 본문에 남긴다.

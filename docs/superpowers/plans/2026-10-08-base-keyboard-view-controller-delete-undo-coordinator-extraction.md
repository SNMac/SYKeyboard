# BaseKeyboardViewController 삭제·undo/redo Coordinator 추출 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `BaseKeyboardViewController.swift`(2721줄)에서 삭제 touchDown·반복 삭제·삭제 pan·줄 경계 추론·보류 큐 drain과 undo/redo 접착 코드를 `TextDeletionCoordinator`·`UndoRedoCoordinator`로 옮겨, 동작은 그대로 두고 본 파일을 약 1850줄로 줄인다.

**Architecture:** VC가 두 Coordinator를 `private lazy var`로 강하게 소유하고, Coordinator는 `weak` Host 프로토콜(`TextDeletionHost`, `UndoRedoHost`)로 VC를 역참조한다. 삭제 파이프라인의 프록시 쓰기는 전부 VC의 `open`/`public` 메서드를 거치므로 Host 요구사항 대부분이 같은 이름으로 witness가 된다. 두 Coordinator의 접점 세 곳(`recordUndoRedoChange`의 capture → 기록, 확정 draft의 undo 기록, undo 적용 전 삭제 취소)은 VC를 경유한다. 코드를 옮기기 전에 현재 동작을 고정하는 VC 테스트를 먼저 넣고, 옮긴 뒤 수정 없이 통과시킨다.

**Tech Stack:** Swift 5, UIKit, Combine(반복 타이머), Swift Testing, Xcode 26 이상, 시뮬레이터 `iPhone 13 mini / iOS 18.6`(UDID `82146144-24DE-4F91-B25D-23D147A91142`)

**Spec:** `docs/superpowers/specs/2026-10-08-base-keyboard-view-controller-delete-undo-coordinator-extraction-design.md`

## Global Constraints

- 기준 커밋 `develop` f14e15e0. 작업 브랜치 `refactor/#185-extract-delete-undo-coordinators`(이미 생성, worktree 없음). **커밋 명령마다 `git branch --show-current`를 먼저 실행해 이 브랜치인지 확인한다.** spec 커밋이 `develop`에 올라간 적이 있다.
- 사용자에게 보이는 동작, 입력 흐름, 콜백 안의 호출 순서, 프록시 읽기 횟수를 바꾸지 않는다. 함수 본문은 Coordinator로 그대로 옮기고 원래 자리에 호출 한 줄을 남긴다.
- Host 참조는 `weak`. host가 필요한 진입점은 `guard let host else { return }`(값 반환은 `false`/`nil`/비`.started`)로 시작한다. 상태만 바꾸는 메서드는 host 없이 동작한다. `unowned` 금지.
- Coordinator는 `CachingTextDocumentProxy`를 만들지 않고 `host.textDocument`를 저장하지 않는다. 호출마다 `host.textDocument`로 접근한다. 클로저는 `[weak self]`(타이머 sink는 `[weak self, weak button]`).
- `textDocumentProxy` 직접 참조 금지. 확인: `grep -rn "textDocumentProxy" Modules Keyboards | grep -v -E ":[0-9]+:[[:space:]]*//"` 결과가 `BaseKeyboardViewController.swift`의 `return self.textDocumentProxy` 한 줄뿐.
- VC 저장 프로퍼티 중 `private`에서 `internal`로 바뀌는 것은 없다. Coordinator로 옮긴 프로퍼티는 VC에서 삭제한다. `isRepeatingInput`은 `public` 저장 → `public` 계산 프로퍼티로 바뀐다(읽기 전용 유지).
- `Modules/`에 새 파일을 추가하면 `SYKeyboard.xcodeproj/project.pbxproj`의 `SYKeyboard`·`SYKeyboardCore` 두 타깃 membershipExceptions에 알파벳 순으로 등록한다(`SuggestionSelectionCoordinator.swift` 줄 바로 뒤). `SYKeyboardTests/`는 등록이 필요 없다.
- 테스트는 Swift Testing. UI 테스트 suite는 `@MainActor`, UserDefaults를 바꾸면 `.sharedUserDefaults` trait과 `defer` 복원. production 클래스에 `ForTesting` 메서드를 추가하지 않는다. `BaseKeyboardViewController.isPreview` static 플래그를 테스트에서 바꾸지 않는다.
- 마크다운(계획·PR 본문·주석 문서)에서 범위 물결표는 `\~`로 쓴다. 백틱 안은 예외.
- 커밋 메시지: `test: #185 - …`, `refactor: #185 - …`, `docs: #185 - …`. 마침표 없음. 끝에 `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. push·PR 생성은 사용자가 지시할 때만.
- 빌드·테스트 로그는 `$S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad` 아래 파일로 남기고 `grep`/`tail`로 본다. `xcodebuild`는 foreground, timeout 600000. 실행 전에 "무엇을 돌리고 몇 분 걸리는지" 한 줄 알린다. 실패가 예상되는 실행(RED)은 `timeout 300`으로 감싼다.
- 테스트가 컴파일 오류 없이 `The test runner timed out while preparing to run tests`로 멈추면 코드 실패가 아니다. CLAUDE.md "붙여넣기 권한 알림" 절을 따른다. 알림 위험이 있으면 `-destination 'platform=iOS Simulator,id=82146144-24DE-4F91-B25D-23D147A91142' -parallel-testing-enabled NO`로 돌린다.
- 키보드 extension scheme을 빌드한 뒤 `git status --short`에 `.xcscheme`이 보이면 `RemotePath`만 바뀐 것인지 확인하고 `git checkout -- <파일>`로 되돌린다.

## Review Focus

1. **줄바꿈 삭제 뒤 늦게 오는 callback**(경계 요청 → settling 50ms → 보류 pan 재생): 타이머 기반이라 단위 테스트가 없다. Task 5의 코드는 `processDeleteMutationResolution`·`resumeDeletePanAfterSettling`·`scheduleDeletePanBoundaryTimeout`을 글자 그대로 옮기고, Task 6 Step 4 시뮬레이터에서 여러 줄 textarea로 줄 경계 드래그를 직접 확인한다.
2. **VC가 해제된 뒤 도착하는 `asyncAfter`·타이머 틱**: Coordinator가 `host`에 닿지 않고 조용히 반환해야 한다. Task 5 Step 2의 "host 해제 뒤 무해"·"Coordinator 해제" 테스트가 고정한다.
3. **반복 삭제 틱의 프록시 읽기 횟수**(24ff8984): Task 1의 읽기 횟수 테스트가 추출 전 측정값으로 고정한다.
4. **선택 영역 삭제의 undo 기록**: 모델 글자가 아니라 선택 텍스트가 기록돼야 한다. Task 1의 선택 영역 테스트와 Task 5 Step 2의 selection 테스트가 고정한다.
5. **`textDidChange` 안의 순서**(삭제 확정이 프록시에 쓴 뒤 undo 무효화가 새 값을 읽음): Task 5 Step 6의 콜백 교체 순서와 `BaseKeyboardViewControllerProxyReadTests`가 고정한다.

---

## 파일 구조

| 구분 | 경로 | 책임 |
|---|---|---|
| 생성 | `Modules/SYKeyboardCore/Presentation/ViewController/Utils/TextDeletionCoordinator.swift` | 삭제 touchDown·반복 틱·pan·줄 경계·drain·반복 타이머·삭제 드래그 인디케이터. `TextDeletionHost` |
| 생성 | `Modules/SYKeyboardCore/Presentation/ViewController/Utils/UndoRedoCoordinator.swift` | undo/redo 기록·확정·무효화·적용·컨트롤 갱신. `UndoRedoHost` |
| 수정 | `Modules/SYKeyboardCore/Presentation/ViewController/Utils/CachingTextDocumentProxy.swift` | `contextSnapshot` extension |
| 수정 | `Modules/SYKeyboardCore/Presentation/ViewController/Utils/SuggestionSelectionCoordinator.swift`, `ClipboardHistoryCoordinator.swift` | `deinit` 로그 |
| 수정 | `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` | 두 영역 삭제, Coordinator 소유, Host 채택 extension |
| 수정 | `SYKeyboard.xcodeproj/project.pbxproj` | 새 파일 2개 × 타깃 2개 등록 |
| 생성 | `SYKeyboardTests/Controller/BaseKeyboardViewControllerDeleteUndoBehaviorTests.swift` | 추출 전 동작 고정(VC 수준) |
| 수정 | `SYKeyboardTests/Utils/CachingTextDocumentProxyTests.swift` | `contextSnapshot` 읽기 순서 테스트 |
| 수정 | `SYKeyboardTests/Utils/SuggestionSelectionCoordinatorTests.swift`, `ClipboardHistoryCoordinatorTests.swift` | 해제 테스트 |
| 생성 | `SYKeyboardTests/Utils/UndoRedoCoordinatorTests.swift` | Coordinator 단위 테스트 |
| 생성 | `SYKeyboardTests/Utils/TextDeletionCoordinatorTests.swift` | Coordinator 단위 테스트 |
| 수정 | `CLAUDE.md`, `README.md`, `docs/architecture/*.md` | 새 구조 반영 |

Host 요구사항 이름 규칙: VC의 `open`/`public` 메서드(`textInteractionWillPerform`, `deleteBackward`, `deleteText`, `replaceText`, `deleteButtonPan*`, `performRepeatTextInteraction`, `undoRedoEditDidApply`, `shouldDeferUndoRedoCommit`, `textDocument`)는 같은 이름으로 witness. VC의 `private` 멤버를 감싸는 것은 다른 이름(`performDeleteTextInteraction(for:)` → `performTextInteraction(for:)`, `recordEditForUndo` → `recordUndoRedoChange`, `refresh…` → `update…`, `interruptPendingDeleteInteractions` → Coordinator 위임)으로 같은 파일의 Host 채택 extension이 한 줄로 전달한다.

---

### Task 1: 추출 전 VC 동작 고정 테스트

**Files:**
- Create: `SYKeyboardTests/Controller/BaseKeyboardViewControllerDeleteUndoBehaviorTests.swift`

**Interfaces:**
- Consumes: `BaseKeyboardViewController.init(language:)`, `performTextInteraction(for:)`, `performRepeatTextInteraction(for:)`, `repeatTextInteractionWillPerform(button:)`, `repeatTextInteractionDidPerform(button:)`, `insertText(_:)`, `isRepeatingInput`, `deleteButtonPanning(_:to:)`, `deleteButtonPanStopped(_:)`, `textInteractableButtonLongPressing(_:button:)`, `textWillChange(_:)`, `textDidChange(_:)`, `StandardKeyboardView.deleteButton`, `SuggestionBarView.suggestionDelegate`, `TextInteractionGestureController.init(keyboardHStackView:getCurrentPressedButton:setCurrentPressedButton:)`, `CountingTextDocumentProxy`, `TestPrimaryKeyboardView`
- Produces: Task 4·5가 끝난 뒤 **수정 없이** 통과해야 하는 테스트 10개. 테스트는 Coordinator 타입, 인디케이터 뷰, 삭제 파이프라인 상태를 참조하지 않는다

- [x] **Step 1: 테스트 파일 작성**

```swift
//
//  BaseKeyboardViewControllerDeleteUndoBehaviorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

/// #185 추출 전 동작을 고정한다. 진입점은 VC의 public 메서드, 삭제 버튼의 production release `UIAction`,
/// 제스처 delegate 메서드, 후보 바 delegate다. Coordinator로 옮겨질 멤버(삭제 파이프라인 상태, 인디케이터 뷰)는 참조하지 않는다
@Suite("BaseKeyboardViewController 삭제·undo/redo 동작 고정", .sharedUserDefaults)
@MainActor
struct BaseKeyboardViewControllerDeleteUndoBehaviorTests {

    @Test("삭제 탭은 즉시 한 글자를 지우고 release 뒤 undo가 복원")
    func testDeleteTapThenUndoRestores() {
        let settings = UserDefaultsManager.shared
        let oldUndo = settings.isUndoRedoEnabled
        settings.isUndoRedoEnabled = true
        defer { settings.isUndoRedoEnabled = oldUndo }

        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let deleteButton = controller.primaryView.deleteButton

        controller.performTextInteraction(for: deleteButton)
        #expect(controller.proxy.writes == ["deleteBackward"])

        // release는 setupUI가 붙인 production UIAction이 받는다
        deleteButton.sendActions(for: .touchUpInside)
        let bar = controller.suggestionBar
        bar.suggestionDelegate?.suggestionBarDidTapUndo(bar)

        #expect(controller.proxy.writes == ["deleteBackward", "insertText(녕)"])
    }

    @Test("확정 전 두 번째 탭은 보류되고 textDidChange 뒤에 이어 지움")
    func testSecondTapWaitsForTextChange() {
        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let deleteButton = controller.primaryView.deleteButton

        controller.performTextInteraction(for: deleteButton)
        controller.performTextInteraction(for: deleteButton)
        #expect(controller.proxy.writes == ["deleteBackward"])

        controller.textDidChange(nil)

        #expect(controller.proxy.writes == ["deleteBackward", "deleteBackward"])
    }

    @Test("반복 삭제 틱은 프록시 문맥을 한 번씩만 읽음")
    func testRepeatDeleteTickReadsContextOnce() {
        let controller = TestDeleteUndoViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(controller.view)
        let deleteButton = controller.primaryView.deleteButton
        controller.repeatTextInteractionWillPerform(button: deleteButton)
        #expect(controller.isRepeatingInput)
        controller.proxy.resetReadCounts()

        controller.performRepeatTextInteraction(for: deleteButton)

        #expect(controller.proxy.writes == ["deleteBackward"])
        // 추출 전 측정값(2026-10-08, f14e15e0): 틱 시작 스냅샷(앞·뒤·선택 1회씩)과 deleteText()의 선택·앞 문맥 읽기
        #expect(controller.proxy.readCount(of: "documentContextBeforeInput") == 2)
        #expect(controller.proxy.readCount(of: "documentContextAfterInput") == 1)
        #expect(controller.proxy.readCount(of: "selectedText") == 2)
        window.removeFromSuperview()
    }

    @Test("반복 삭제 틱은 직전 틱을 확정하고 이어 지우며 손을 떼면 멈춤")
    func testRepeatDeleteTicksContinueAndStop() {
        let controller = TestDeleteUndoViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(controller.view)
        let deleteButton = controller.primaryView.deleteButton
        controller.repeatTextInteractionWillPerform(button: deleteButton)

        controller.performRepeatTextInteraction(for: deleteButton)
        controller.performRepeatTextInteraction(for: deleteButton)
        #expect(controller.proxy.writes == ["deleteBackward", "deleteBackward"])

        controller.repeatTextInteractionDidPerform(button: deleteButton)

        #expect(controller.isRepeatingInput == false)
        window.removeFromSuperview()
    }

    @Test("삭제 드래그는 왼쪽에서 지우고 오른쪽에서 되살리며 끝나면 훅을 한 번 부름")
    func testDeletePanDeleteRestoreStop() {
        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let gesture = makeGestureController()

        controller.deleteButtonPanning(gesture, to: .left)
        #expect(controller.proxy.writes == ["deleteBackward"])

        controller.deleteButtonPanning(gesture, to: .right)
        #expect(controller.proxy.writes == ["deleteBackward", "insertText(녕)"])

        controller.deleteButtonPanStopped(gesture)
        #expect(controller.panDidStopCount == 1)
    }

    @Test("첨부 토큰 앞에서는 드래그 삭제가 멈춤")
    func testDeletePanStopsBeforeAttachment() {
        let controller = TestDeleteUndoViewController()
        controller.proxy.beforeInput = "a\u{FFFC}"
        controller.loadViewIfNeeded()
        let gesture = makeGestureController()

        controller.deleteButtonPanning(gesture, to: .left)

        #expect(controller.proxy.writes.isEmpty)
    }

    @Test("선택 영역이 있으면 드래그 삭제가 선택 영역을 지우고 undo가 선택 텍스트를 되살림")
    func testDeletePanDeletesSelectionAndUndoRestoresIt() {
        let settings = UserDefaultsManager.shared
        let oldUndo = settings.isUndoRedoEnabled
        settings.isUndoRedoEnabled = true
        defer { settings.isUndoRedoEnabled = oldUndo }

        let controller = TestDeleteUndoViewController()
        controller.proxy.beforeInput = "안"
        controller.proxy.selected = "녕"
        controller.loadViewIfNeeded()
        let gesture = makeGestureController()

        controller.deleteButtonPanning(gesture, to: .left)
        #expect(controller.proxy.writes == ["deleteBackward"])

        // 선택 영역 삭제는 복구 버퍼에 들어가지 않으므로 오른쪽 드래그는 아무것도 쓰지 않는다
        controller.deleteButtonPanning(gesture, to: .right)
        #expect(controller.proxy.writes == ["deleteBackward"])

        let bar = controller.suggestionBar
        bar.suggestionDelegate?.suggestionBarDidTapUndo(bar)
        #expect(controller.proxy.writes == ["deleteBackward", "insertText(녕)"])
    }

    @Test("undo 뒤 redo는 같은 편집을 다시 적용")
    func testUndoThenRedo() {
        let settings = UserDefaultsManager.shared
        let oldUndo = settings.isUndoRedoEnabled
        settings.isUndoRedoEnabled = true
        defer { settings.isUndoRedoEnabled = oldUndo }

        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let bar = controller.suggestionBar

        controller.insertText("가")
        bar.suggestionDelegate?.suggestionBarDidTapUndo(bar)
        #expect(controller.proxy.writes == ["insertText(가)", "deleteBackward"])

        bar.suggestionDelegate?.suggestionBarDidTapRedo(bar)
        #expect(controller.proxy.writes == ["insertText(가)", "deleteBackward", "insertText(가)"])
    }

    @Test("undo/redo 설정이 꺼져 있으면 undo 탭이 쓰지 않음")
    func testUndoDisabledDoesNotWrite() {
        let settings = UserDefaultsManager.shared
        let oldUndo = settings.isUndoRedoEnabled
        settings.isUndoRedoEnabled = false
        defer { settings.isUndoRedoEnabled = oldUndo }

        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let bar = controller.suggestionBar

        controller.insertText("가")
        bar.suggestionDelegate?.suggestionBarDidTapUndo(bar)

        #expect(controller.proxy.writes == ["insertText(가)"])
    }

    @Test("삭제 중 입력창이 바뀌면 보류된 드래그를 끝내고 훅을 한 번 부름")
    func testTextInputChangeCancelsPendingPan() {
        let controller = TestDeleteUndoViewController()
        controller.loadViewIfNeeded()
        let deleteButton = controller.primaryView.deleteButton
        let gesture = makeGestureController()
        let first = UITextField()
        let second = UITextField()

        controller.textWillChange(first)
        controller.performTextInteraction(for: deleteButton)
        controller.deleteButtonPanning(gesture, to: .left)
        #expect(controller.proxy.writes == ["deleteBackward"])

        controller.textWillChange(second)
        #expect(controller.panDidStopCount == 1)

        controller.textDidChange(second)
        #expect(controller.proxy.writes == ["deleteBackward"])
    }

    @Test("삭제·반복·undo를 거친 VC는 참조를 놓으면 해제됨")
    func testControllerIsReleased() {
        weak var weakController: TestDeleteUndoViewController?
        autoreleasepool {
            let controller = TestDeleteUndoViewController()
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.addSubview(controller.view)
            let deleteButton = controller.primaryView.deleteButton
            let gesture = makeGestureController()

            controller.textInteractableButtonLongPressing(gesture, button: deleteButton)
            controller.deleteButtonPanning(gesture, to: .left)
            controller.insertText("가")
            controller.view.removeFromSuperview()
            weakController = controller
        }

        #expect(weakController == nil)
    }
}

// MARK: - Test Helpers

@MainActor
private final class TestDeleteUndoViewController: BaseKeyboardViewController {
    let primaryView = TestPrimaryKeyboardView(keyboard: .dubeolsik)
    let proxy = CountingTextDocumentProxy()
    /// 하위 VC가 보는 pan 종료 훅 호출 횟수
    private(set) var panDidStopCount = 0

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

    override func deleteButtonPanDidStop() {
        super.deleteButtonPanDidStop()
        panDidStopCount += 1
    }
}

/// 제스처 delegate 메서드는 `controller` 인자를 쓰지 않으므로 빈 컨트롤러를 넘긴다
@MainActor
private func makeGestureController() -> TextInteractionGestureController {
    TextInteractionGestureController(
        keyboardHStackView: UIStackView(),
        getCurrentPressedButton: { nil },
        setCurrentPressedButton: { _ in }
    )
}
```

- [x] **Step 2: 실행해 측정값·해제 여부 확인**

"BaseKeyboardViewControllerDeleteUndoBehaviorTests 실행, 빌드 포함 약 3\~5분"이라고 알린 뒤 실행한다.

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerDeleteUndoBehaviorTests \
  > "$S/task1-test.log" 2>&1; grep -E "Test Case .* (passed|failed)|error:|Executed|expectation" "$S/task1-test.log" | tail -n 40
```

Expected: 읽기 횟수 테스트는 통과하거나 측정값만 다르게 실패한다(실패 메시지의 실제 값을 Step 3에서 적는다). 나머지는 통과해야 한다. 통과하지 않는 테스트가 있으면 **production 코드를 고치지 않고** 테스트의 가정(진입점·프록시 초기값)이 현재 동작과 다른 것이므로 로그의 실제 값으로 테스트를 고친다. 단, `testControllerIsReleased`가 실패하면 먼저 상호작용 없이 `TestDeleteUndoViewController()`를 만들고 `loadViewIfNeeded()`만 한 뒤 놓는 변형으로 다시 돌려 UIKit이 `UIInputViewController`를 붙드는지 본다. 그 변형도 실패하면 이 테스트를 지우고 이 Step 아래에 "UIKit이 테스트에서 VC를 해제하지 않아 VC 수준 해제 테스트는 제외, Coordinator 단위 해제 테스트(Task 3·4·5)로 대체"라고 기록한다.

- [x] **Step 3: 측정값을 테스트에 적고 다시 실행**

Step 2에서 읽기 횟수가 달랐다면 세 `readCount` 기대값을 실제 값으로 바꾸고 주석의 설명도 맞춘다. 같은 명령을 다시 실행해 `Executed 11 tests, with 0 failures`(해제 테스트를 뺐으면 10)를 확인한다.

- [x] **Step 4: 커밋**

```sh
git branch --show-current   # refactor/#185-extract-delete-undo-coordinators 여야 한다
git add SYKeyboardTests/Controller/BaseKeyboardViewControllerDeleteUndoBehaviorTests.swift
git commit -m "$(cat <<'EOF'
test: #185 - 삭제·반복 삭제·undo/redo 동작을 고정하는 VC 테스트 추가

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

#### Task 1 결과 (2026-10-09)

- Step 2: 읽기 횟수 기대값(앞 2·뒤 1·선택 2)은 측정값과 같아 수정 없음. `testControllerIsReleased`만 실패 → 상호작용 없는 VC는 해제됨 → 분할(창만·길게 누르기만·드래그만·삽입만)에서 **창에 올렸다 내린 경우만** 붙잡힘 → 참조를 놓은 뒤 `RunLoop.main.run(until: +0.2)`을 돌리면 전체 상호작용을 거친 VC도 해제됨. 누수가 아니라 UIKit이 창에 올라간 VC에 예약한 main queue 작업이 끝날 때까지 들고 있는 것이다. **Ruling:** 해제 테스트는 참조를 놓고 런루프 한 틱 뒤 `nil`을 확인하는 형태로 확정(임시 분할 테스트는 삭제). 틀렸을 때 비용: 런루프 한 틱 안에 끝나는 짧은 보유를 놓칠 수 있으나, 누적 누수는 Task 6의 시뮬레이터 `deinit`·`leaks` 확인이 잡는다. 로그 `scratchpad/task1-test.log`, `task1-bisect.log`, `task1-bisect2.log`, `task1-final.log`.
- Step 3: 11개 통과(`task1-final.log`). suite 주석은 사용자 요청으로 이슈 번호 없이 테스트 성격만 적었다.
- `-only-testing:…/<suite>/<함수>` 형식은 이 suite(Swift Testing)에서 0개가 실행됐다. suite 단위로만 좁힌다.

---

### Task 2: `CachingTextDocumentProxy.contextSnapshot`

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Utils/CachingTextDocumentProxy.swift` (파일 끝)
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift` (`currentTextContextSnapshot()`, 약 1990줄)
- Modify: `SYKeyboardTests/Utils/CachingTextDocumentProxyTests.swift`

**Interfaces:**
- Produces: `extension CachingTextDocumentProxy { var contextSnapshot: KeyboardTextContextSnapshot { get } }`. 앞 문맥을 먼저, 뒤 문맥을 다음에 한 번씩 읽는다. Task 4·5의 Coordinator와 VC가 쓴다

- [x] **Step 1: 실패하는 테스트 작성**

`SYKeyboardTests/Utils/CachingTextDocumentProxyTests.swift`를 먼저 읽고 suite 안 마지막 테스트 뒤에 추가한다.

```swift
    @Test("contextSnapshot은 앞·뒤 문맥을 한 번씩 읽어 담음")
    func testContextSnapshotReadsBeforeAndAfterOnce() {
        let proxy = CountingTextDocumentProxy()
        proxy.beforeInput = "앞"
        proxy.afterInput = "뒤"
        let document = CachingTextDocumentProxy { proxy }

        let snapshot = document.contextSnapshot

        #expect(snapshot == KeyboardTextContextSnapshot(beforeInput: "앞", afterInput: "뒤"))
        #expect(proxy.readCount(of: "documentContextBeforeInput") == 1)
        #expect(proxy.readCount(of: "documentContextAfterInput") == 1)
        #expect(proxy.readCount(of: "selectedText") == 0)
    }
```

- [x] **Step 2: 컴파일 실패 확인**

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
timeout 300 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/CachingTextDocumentProxyTests \
  > "$S/task2-red.log" 2>&1; grep -E "error:" "$S/task2-red.log" | head -n 3
```

Expected: `value of type 'CachingTextDocumentProxy' has no member 'contextSnapshot'`.

- [x] **Step 3: extension 추가**

`CachingTextDocumentProxy.swift` 끝(`// MARK: - Private Methods` extension 뒤)에 추가한다.

```swift
// MARK: - Context Snapshot

extension CachingTextDocumentProxy {
    /// 커서 앞·뒤 문맥을 그 순서로 한 번씩 읽은 스냅샷. VC와 Coordinator가 같은 헬퍼를 써서 읽기 횟수를 같게 유지한다
    var contextSnapshot: KeyboardTextContextSnapshot {
        KeyboardTextContextSnapshot(
            beforeInput: documentContextBeforeInput,
            afterInput: documentContextAfterInput
        )
    }
}
```

- [x] **Step 4: VC의 `currentTextContextSnapshot()`이 extension을 쓰게 교체**

`BaseKeyboardViewController.swift`의 Private Methods에서

```swift
    func currentTextContextSnapshot() -> KeyboardTextContextSnapshot {
        return KeyboardTextContextSnapshot(
            beforeInput: textDocument.documentContextBeforeInput,
            afterInput: textDocument.documentContextAfterInput
        )
    }
```

를

```swift
    func currentTextContextSnapshot() -> KeyboardTextContextSnapshot {
        return textDocument.contextSnapshot
    }
```

로 바꾼다. 호출처 13곳은 그대로 둔다(Task 4·5에서 Coordinator로 옮겨지며 줄어든다).

- [x] **Step 5: 테스트 통과 확인**

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/CachingTextDocumentProxyTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerProxyReadTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerDeleteUndoBehaviorTests \
  > "$S/task2-test.log" 2>&1; grep -E "Executed|failed" "$S/task2-test.log" | tail -n 5
```

Expected: 0 failures. `ProxyReadTests`의 콜백 읽기 횟수와 Task 1의 틱 읽기 횟수가 그대로다.

- [x] **Step 6: 커밋**

```sh
git branch --show-current
git add Modules/SYKeyboardCore/Presentation/ViewController/Utils/CachingTextDocumentProxy.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboardTests/Utils/CachingTextDocumentProxyTests.swift
git commit -m "$(cat <<'EOF'
refactor: #185 - 문맥 스냅샷 읽기를 CachingTextDocumentProxy.contextSnapshot으로 통일

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

#### Task 2 결과 (2026-10-09)

- Step 2 RED: `has no member 'contextSnapshot'`. Step 5: 세 suite 26개 통과(`scratchpad/task2-test.log`), `ProxyReadTests`·틱 읽기 횟수 그대로.

---

### Task 3: #184 Coordinator의 `deinit` 로그와 해제 테스트

**Files:**
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Utils/SuggestionSelectionCoordinator.swift` (init 뒤)
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Utils/ClipboardHistoryCoordinator.swift` (init 뒤)
- Modify: `SYKeyboardTests/Utils/SuggestionSelectionCoordinatorTests.swift`, `SYKeyboardTests/Utils/ClipboardHistoryCoordinatorTests.swift`

**Interfaces:**
- Produces: 두 Coordinator의 `private let logger`와 `deinit`. 다른 코드가 쓰지 않는다

- [x] **Step 1: 해제 테스트 작성**

`SuggestionSelectionCoordinatorTests.swift`의 `testReleasedHostIsIgnored` 뒤에 추가한다. 오버레이 콜백(`[weak self]`)과 delegate(`weak`)가 걸린 상태에서 놓는다.

```swift
    @Test("오버레이와 delegate가 걸린 Coordinator는 참조를 놓으면 해제됨")
    func testCoordinatorIsReleased() {
        weak var weakCoordinator: SuggestionSelectionCoordinator?
        autoreleasepool {
            let fixture = makeFixture()
            fixture.service.removableSuggestionTextResult = "오늘"
            _ = fixture.coordinator.suggestionBar(fixture.bar, shouldBeginRemovalAt: 0)
            weakCoordinator = fixture.coordinator
        }

        #expect(weakCoordinator == nil)
    }
```

`ClipboardHistoryCoordinatorTests.swift`의 `testReleasedHostIsIgnored` 뒤에 추가한다. 알림 observer 3개와 다음 런루프 작업이 예약된 상태에서 놓고, 예약된 작업이 실행돼도 크래시가 없어야 한다.

```swift
    @Test("observer와 예약 작업이 걸린 Coordinator는 참조를 놓으면 해제됨")
    func testCoordinatorIsReleased() {
        weak var weakCoordinator: ClipboardHistoryCoordinator?
        autoreleasepool {
            let fixture = makeFixture()
            defer { fixture.restore() }
            fixture.coordinator.registerNotificationObservers()
            fixture.coordinator.pasteboardDidChange()
            weakCoordinator = fixture.coordinator
        }

        #expect(weakCoordinator == nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        NotificationCenter.default.post(name: UIPasteboard.changedNotification, object: nil)
    }
```

- [x] **Step 2: 실행해 통과 확인(RED가 아님)**

이 테스트는 현재 코드에서도 통과해야 한다(누수가 없다는 §7-1 검토의 증거). 실패하면 누수이므로 원인을 찾아 `fix: #185 - …`로 따로 커밋한다.

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/SuggestionSelectionCoordinatorTests \
  -only-testing:SYKeyboardTests/ClipboardHistoryCoordinatorTests \
  > "$S/task3-test.log" 2>&1; grep -E "Executed|failed" "$S/task3-test.log" | tail -n 5
```

Expected: 0 failures.

- [x] **Step 3: `deinit` 로그 추가**

`SuggestionSelectionCoordinator.swift`: `import SYKeyboardAssets` 아래에 `import OSLog`를 추가하고, `// MARK: - Properties` 첫 줄에

```swift
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "SuggestionSelectionCoordinator")
```

를, init 블록 바로 뒤에

```swift
    deinit {
        logger.debug("SuggestionSelectionCoordinator deinit")
    }
```

를 추가한다. `ClipboardHistoryCoordinator.swift`도 같은 위치에 category `ClipboardHistoryCoordinator`로 추가한다(`super.init()` 뒤 init 블록 뒤). `Logger`는 `Sendable`인 `let`이라 `deinit`에서 isolation 경고 없이 읽힌다. `lazy var`로 만들지 않는다.

- [x] **Step 4: 빌드와 테스트 재확인**

Step 2와 같은 명령. Expected: 0 failures, 경고 없음(`grep -c "warning:" "$S/task3-test.log"`가 기준과 같음).

- [x] **Step 5: 커밋**

```sh
git branch --show-current
git add Modules/SYKeyboardCore/Presentation/ViewController/Utils/SuggestionSelectionCoordinator.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Utils/ClipboardHistoryCoordinator.swift \
  SYKeyboardTests/Utils/SuggestionSelectionCoordinatorTests.swift \
  SYKeyboardTests/Utils/ClipboardHistoryCoordinatorTests.swift
git commit -m "$(cat <<'EOF'
test: #185 - 후보 선택·클립보드 Coordinator 해제 테스트와 deinit 로그 추가

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

#### Task 3 결과 (2026-10-09)

- Step 2: 두 해제 테스트가 현재 코드에서 통과(`scratchpad/task3-test.log`, 26개). 누수 없음. Step 4: `deinit` 로그 추가 뒤 26개 통과(`task3-test2.log`). 소스 파일 경고 0건(로그의 `warning:` 117건은 전부 DerivedData 사전컴파일 모듈 경고).

---

### Task 4: `UndoRedoCoordinator` 추출

**Files:**
- Create: `SYKeyboardTests/Utils/UndoRedoCoordinatorTests.swift`
- Create: `Modules/SYKeyboardCore/Presentation/ViewController/Utils/UndoRedoCoordinator.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj` (두 타깃 membershipExceptions)
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`

**Interfaces:**
- Consumes: `KeyboardUndoRedoSession`, `KeyboardUndoRedoEdit`, `KeyboardTextContextNavigator.cursorOffset(from:to:)`, `KeyboardPresentationStatePolicy.shouldShowUndoRedoControls(isSuggestionBarHidden:isUndoRedoFeatureAvailable:)`, `SuggestionBarView.updateUndoRedoControls(isVisible:canUndo:canRedo:)`, `SuggestionService.clearReplacementHistory()`, `CachingTextDocumentProxy.contextSnapshot`(Task 2)
- Produces:
  - `protocol UndoRedoHost: AnyObject` — `textDocument`, `isPreviewMode`, `shouldDeferUndoRedoCommit`, `undoRedoEditDidApply()`, `refreshReturnButtonEnabled()`, `refreshSuggestions()`, `refreshClipboardControl()`, `interruptPendingDeleteInteractions()`
  - `final class UndoRedoCoordinator` — `init(suggestionBarView:suggestionController:keyboardSettingsManager:host:)`, `prepareForTextWillChange(inputIdentifier:)`, `invalidateHistoryIfNeededAfterTextChange(inputIdentifier:)`, `removeAllHistory()`, `record(deletedText:insertedText:)`, `commitPendingGroup()`, `commitPendingGroupIgnoringDeferral()`, `commitDeferredGroupIfNeeded()`, `undo()`, `redo()`, `refreshControls()`. Task 5의 VC `recordUndoRedoChange`가 `record`를 부른다

- [x] **Step 1: 실패하는 Coordinator 테스트 작성**

```swift
//
//  UndoRedoCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("undo/redo Coordinator", .sharedUserDefaults)
@MainActor
struct UndoRedoCoordinatorTests {

    @Test("기록한 삽입을 undo하면 삭제 취소 → 쓰기 → 훅 → 갱신 순서로 적용")
    func testUndoAppliesInOrder() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.host.calls.removeAll()

        fixture.coordinator.undo()

        #expect(fixture.proxy.writes == ["insertText(가)", "deleteBackward"])
        #expect(fixture.host.calls == [
            "interruptPendingDeleteInteractions",
            "undoRedoEditDidApply",
            "refreshReturnButtonEnabled",
            "refreshSuggestions",
            "refreshClipboardControl"
        ])
    }

    @Test("undo 뒤 redo는 삽입을 다시 적용")
    func testRedoAfterUndo() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.coordinator.undo()

        fixture.coordinator.redo()

        #expect(fixture.proxy.writes == ["insertText(가)", "deleteBackward", "insertText(가)"])
    }

    @Test("삭제 기록을 undo하면 지운 텍스트를 다시 삽입")
    func testUndoOfDeletionReinserts() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.beforeInput = "안녕"
        fixture.proxy.deleteBackward()
        fixture.coordinator.record(deletedText: "녕", insertedText: "")

        fixture.coordinator.undo()

        #expect(fixture.proxy.writes == ["deleteBackward", "insertText(녕)"])
    }

    @Test("미리보기에서는 적용하지 않고 이력을 비움")
    func testPreviewBlocksApply() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.host.isPreviewMode = true

        fixture.coordinator.undo()
        fixture.host.isPreviewMode = false
        fixture.coordinator.redo()

        #expect(fixture.proxy.writes == ["insertText(가)"])
    }

    @Test("설정이 꺼져 있으면 기록도 undo도 하지 않음")
    func testFeatureDisabled() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        UserDefaultsManager.shared.isUndoRedoEnabled = false
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")

        fixture.coordinator.undo()

        #expect(fixture.proxy.writes == ["insertText(가)"])
        #expect(fixture.host.calls.isEmpty)
    }

    @Test("조합 지연 중에는 그룹 확정을 미루고 지연 확정이 풀리면 반영")
    func testDeferredCommit() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.host.shouldDeferUndoRedoCommit = true
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.coordinator.commitPendingGroup()
        fixture.host.calls.removeAll()

        fixture.host.shouldDeferUndoRedoCommit = false
        fixture.coordinator.commitDeferredGroupIfNeeded()

        #expect(fixture.host.calls == ["refreshClipboardControl"])
        fixture.coordinator.undo()
        #expect(fixture.proxy.writes == ["insertText(가)", "deleteBackward"])
    }

    @Test("입력창 식별자가 바뀐 textDidChange는 이력과 대치 이력을 비움")
    func testInputChangeInvalidatesHistory() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        // 임시 객체는 바로 해제돼 다음 객체가 같은 주소를 받을 수 있으므로 필드를 살려 둔다
        let firstField = UITextField()
        let secondField = UITextField()
        let first = ObjectIdentifier(firstField)
        let second = ObjectIdentifier(secondField)
        fixture.proxy.insertText("가")
        fixture.coordinator.record(deletedText: "", insertedText: "가")
        fixture.coordinator.prepareForTextWillChange(inputIdentifier: first)
        fixture.coordinator.invalidateHistoryIfNeededAfterTextChange(inputIdentifier: first)
        #expect(fixture.service.calls.contains("clearReplacementHistory") == false)

        fixture.coordinator.prepareForTextWillChange(inputIdentifier: second)
        fixture.coordinator.invalidateHistoryIfNeededAfterTextChange(inputIdentifier: second)
        fixture.coordinator.undo()

        #expect(fixture.service.calls.contains("clearReplacementHistory"))
        #expect(fixture.proxy.writes == ["insertText(가)"])
    }

    @Test("이력이 없으면 컨트롤 갱신이 프록시를 읽지 않음")
    func testRefreshControlsWithoutHistoryDoesNotReadProxy() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        fixture.proxy.resetReadCounts()

        fixture.coordinator.refreshControls()
        fixture.coordinator.removeAllHistory()

        #expect(fixture.proxy.contextReadCount == 0)
        #expect(fixture.host.calls == ["refreshClipboardControl", "refreshClipboardControl"])
    }

    @Test("host가 해제된 뒤에는 아무 것도 쓰지 않음")
    func testReleasedHostIsIgnored() {
        let fixture = makeFixture()
        defer { fixture.restore() }
        var host: RecordingUndoRedoHost? = RecordingUndoRedoHost(proxy: fixture.proxy)
        let coordinator = UndoRedoCoordinator(
            suggestionBarView: fixture.bar,
            suggestionController: fixture.service,
            keyboardSettingsManager: .shared,
            host: host!
        )
        fixture.proxy.insertText("가")
        coordinator.record(deletedText: "", insertedText: "가")
        host = nil

        coordinator.undo()
        coordinator.redo()
        coordinator.commitPendingGroup()
        coordinator.commitPendingGroupIgnoringDeferral()
        coordinator.commitDeferredGroupIfNeeded()
        coordinator.refreshControls()
        coordinator.removeAllHistory()

        #expect(fixture.proxy.writes == ["insertText(가)"])
    }

    @Test("디바운스 타이머가 걸린 Coordinator는 참조를 놓으면 해제됨")
    func testCoordinatorIsReleased() {
        weak var weakCoordinator: UndoRedoCoordinator?
        autoreleasepool {
            let fixture = makeFixture()
            defer { fixture.restore() }
            fixture.proxy.insertText("가")
            fixture.coordinator.record(deletedText: "", insertedText: "가")
            weakCoordinator = fixture.coordinator
        }

        #expect(weakCoordinator == nil)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    }
}

// MARK: - Test Helpers

@MainActor
private final class RecordingUndoRedoHost: UndoRedoHost {
    var calls: [String] = []
    var isPreviewMode = false
    var shouldDeferUndoRedoCommit = false
    let textDocument: CachingTextDocumentProxy

    init(proxy: CountingTextDocumentProxy) {
        textDocument = CachingTextDocumentProxy { proxy }
    }

    func undoRedoEditDidApply() { calls.append("undoRedoEditDidApply") }
    func refreshReturnButtonEnabled() { calls.append("refreshReturnButtonEnabled") }
    func refreshSuggestions() { calls.append("refreshSuggestions") }
    func refreshClipboardControl() { calls.append("refreshClipboardControl") }
    func interruptPendingDeleteInteractions() { calls.append("interruptPendingDeleteInteractions") }
}

@MainActor
private struct Fixture {
    let coordinator: UndoRedoCoordinator
    let host: RecordingUndoRedoHost
    let service: FakeSuggestionService
    let bar: SuggestionBarView
    let proxy: CountingTextDocumentProxy
    private let oldUndoEnabled: Bool

    init(
        coordinator: UndoRedoCoordinator,
        host: RecordingUndoRedoHost,
        service: FakeSuggestionService,
        bar: SuggestionBarView,
        proxy: CountingTextDocumentProxy,
        oldUndoEnabled: Bool
    ) {
        self.coordinator = coordinator
        self.host = host
        self.service = service
        self.bar = bar
        self.proxy = proxy
        self.oldUndoEnabled = oldUndoEnabled
    }

    /// fixture가 켠 undo/redo 설정을 되돌린다. 각 테스트가 `defer`로 부른다
    func restore() {
        UserDefaultsManager.shared.isUndoRedoEnabled = oldUndoEnabled
    }
}

/// undo/redo 설정을 켜고, 빈 문서(`beforeInput = nil`)의 프록시와 기록용 host로 Coordinator를 만든다
@MainActor
private func makeFixture() -> Fixture {
    let settings = UserDefaultsManager.shared
    let oldUndoEnabled = settings.isUndoRedoEnabled
    settings.isUndoRedoEnabled = true
    let proxy = CountingTextDocumentProxy()
    proxy.beforeInput = nil
    let host = RecordingUndoRedoHost(proxy: proxy)
    let service = FakeSuggestionService()
    let bar = SuggestionBarView(keyboardHStackView: UIStackView())
    bar.frame = CGRect(x: 0, y: 0, width: 300, height: 44)
    let coordinator = UndoRedoCoordinator(
        suggestionBarView: bar,
        suggestionController: service,
        keyboardSettingsManager: settings,
        host: host
    )
    return Fixture(coordinator: coordinator, host: host, service: service, bar: bar, proxy: proxy, oldUndoEnabled: oldUndoEnabled)
}
```

- [x] **Step 2: 컴파일 실패 확인**

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
timeout 300 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/UndoRedoCoordinatorTests \
  > "$S/task4-red.log" 2>&1; grep -E "error:" "$S/task4-red.log" | head -n 3
```

Expected: `cannot find type 'UndoRedoHost' in scope` 또는 `cannot find 'UndoRedoCoordinator' in scope`.

- [x] **Step 3: `UndoRedoCoordinator.swift` 작성**

VC의 `performUndo`/`performRedo`/`applyUndoRedoEdit`/`recordUndoRedoChange`(undo 부분)/`commitPendingUndoRedoGroup`/`invalidateUndoRedoHistoryForTextContextChange`/`updateUndoRedoControls`/`invalidateUndoRedoHistoryIfNeededAfterTextChange`/`restoreTextPositionIfPossible`과 `commit…` public 래퍼 세 개의 본문을 옮긴 것이다. `self`의 VC 멤버는 `host.`로, `currentTextContextSnapshot()`은 `host.textDocument.contextSnapshot`으로, `BaseKeyboardViewController.isPreview`는 `host.isPreviewMode`로, `updateUndoRedoControls()`는 `refreshControls()`로 바뀐 것 외에는 같다.

```swift
//
//  UndoRedoCoordinator.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit
import OSLog

/// `UndoRedoCoordinator`가 소유자(`BaseKeyboardViewController`)에게 요구하는 것.
/// `shouldDeferUndoRedoCommit`·`undoRedoEditDidApply`는 VC의 `open` 멤버라 같은 이름으로 witness가 되고,
/// `refresh…`/`interrupt…`는 VC의 private 메서드를 감싼 이름이다. 같은 파일의 Host 채택 extension이 한 줄로 전달한다
@MainActor
protocol UndoRedoHost: AnyObject {
    /// VC의 프록시 창구. Coordinator는 이 값을 저장하지 않고 호출마다 읽는다. 캐시 범위가 VC 콜백에 묶여 있기 때문이다
    var textDocument: CachingTextDocumentProxy { get }
    /// `BaseKeyboardViewController.isPreview`. 앱 미리보기에서는 undo/redo를 적용하지 않는다
    var isPreviewMode: Bool { get }
    /// 조합 중인 텍스트가 있을 때 undo 단위 확정을 미루기 위한 hook
    var shouldDeferUndoRedoCommit: Bool { get }

    func undoRedoEditDidApply()
    func refreshReturnButtonEnabled()
    func refreshSuggestions()
    func refreshClipboardControl()
    func interruptPendingDeleteInteractions()
}

/// undo/redo 기록·그룹 확정·무효화·적용과 후보 바의 undo/redo 컨트롤 갱신을 맡는다.
/// `KeyboardUndoRedoSession`을 소유하고, 삭제 확정 파이프라인과의 접점(capture 뒤 기록, 적용 전 삭제 취소)은 VC를 거친다.
/// host는 `weak`다. 디바운스 확정 클로저가 이 객체를 VC보다 오래 살릴 수 있으므로 host가 필요한 진입점은 `guard let host`로 시작한다
@MainActor
final class UndoRedoCoordinator {

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "UndoRedoCoordinator")

    /// 키보드 세션 동안만 유지되는 undo/redo 상태 관리자
    private var undoRedoSession = KeyboardUndoRedoSession()

    private let suggestionBarView: SuggestionBarView
    private let suggestionController: SuggestionService
    private let keyboardSettingsManager: UserDefaultsManager
    private weak var host: UndoRedoHost?

    /// undo/redo 기능 사용 가능 여부. 자동완성 설정과 독립이다
    private var isUndoRedoFeatureAvailable: Bool {
        return keyboardSettingsManager.isUndoRedoEnabled
    }

    // MARK: - Initializer

    init(
        suggestionBarView: SuggestionBarView,
        suggestionController: SuggestionService,
        keyboardSettingsManager: UserDefaultsManager,
        host: UndoRedoHost
    ) {
        self.suggestionBarView = suggestionBarView
        self.suggestionController = suggestionController
        self.keyboardSettingsManager = keyboardSettingsManager
        self.host = host
    }

    deinit {
        logger.debug("UndoRedoCoordinator deinit")
    }

    // MARK: - Text Change Callbacks

    /// `textWillChange`에서 VC가 부른다. 식별자는 VC가 `textInputIdentifier(for:)`로 계산해 넘긴다
    func prepareForTextWillChange(inputIdentifier: ObjectIdentifier?) {
        guard let host else { return }
        undoRedoSession.prepareForTextWillChange(
            inputIdentifier: inputIdentifier,
            context: host.textDocument.contextSnapshot
        )
    }

    /// `textDidChange`에서 VC가 부른다. 입력창이 바뀌었으면 이력과 대치 이력을 비운다
    func invalidateHistoryIfNeededAfterTextChange(inputIdentifier: ObjectIdentifier?) {
        guard let host else { return }
        if undoRedoSession.shouldInvalidateAfterTextChange(
            inputIdentifier: inputIdentifier,
            currentContext: host.textDocument.contextSnapshot
        ) {
            invalidateHistoryForTextContextChange()
            suggestionController.clearReplacementHistory()
        }
    }

    /// `viewWillDisappear`에서 VC가 부른다. 세션 한정 기능이라 이력을 모두 지운다
    func removeAllHistory() {
        undoRedoSession.removeAll()
        refreshControls()
    }

    // MARK: - Recording

    /// 삭제 확정 파이프라인이 capture하지 않은 편집을 기록한다. VC의 `recordUndoRedoChange`가 부른다
    func record(deletedText: String, insertedText: String) {
        guard let host,
              isUndoRedoFeatureAvailable,
              !undoRedoSession.isApplyingEdit else { return }
        undoRedoSession.record(
            deletedText: deletedText,
            insertedText: insertedText,
            targetContext: host.textDocument.contextSnapshot,
            shouldDeferCommit: { [weak self] in
                self?.host?.shouldDeferUndoRedoCommit == true
            },
            debouncedCommitDidFinish: { [weak self] in
                self?.refreshControls()
            }
        )
        refreshControls()
    }

    /// 스페이스/리턴처럼 사용자가 명시적인 편집 경계를 만든 경우 pending undo 단위를 확정한다
    func commitPendingGroup() {
        guard let host else { return }
        undoRedoSession.commitPendingGroup(shouldDeferCommit: host.shouldDeferUndoRedoCommit)
        refreshControls()
    }

    /// 삭제 시작처럼 조합 중이어도 이전 편집 단위를 끊어야 하는 경우 pending undo 단위를 확정한다
    func commitPendingGroupIgnoringDeferral() {
        guard isUndoRedoFeatureAvailable else { return }

        undoRedoSession.commitPendingGroupIgnoringDeferral()
        refreshControls()
    }

    /// 조합 확정 지연 요청이 있었고 현재 확정 가능한 상태라면 pending undo 단위를 stack에 반영한다
    func commitDeferredGroupIfNeeded() {
        guard let host,
              undoRedoSession.commitDeferredGroupIfNeeded(
                shouldDeferCommit: host.shouldDeferUndoRedoCommit
              ) else { return }
        refreshControls()
    }

    // MARK: - Applying

    func undo() {
        guard let host, isUndoRedoFeatureAvailable else { return }

        host.interruptPendingDeleteInteractions()
        undoRedoSession.cancelDebounceTimer()
        guard undoRedoSession.canApplyUndo(from: host.textDocument.contextSnapshot) else {
            refreshControls()
            return
        }
        guard let edit = undoRedoSession.undo() else {
            refreshControls()
            return
        }
        guard applyEdit(edit, host: host) else {
            invalidateHistoryForTextContextChange()
            return
        }
        undoRedoSession.updateLastRedoTargetContext(host.textDocument.contextSnapshot)
        refreshControls()
        FeedbackManager.shared.playHaptic()
    }

    func redo() {
        guard let host, isUndoRedoFeatureAvailable else { return }

        host.interruptPendingDeleteInteractions()
        undoRedoSession.cancelDebounceTimer()
        guard undoRedoSession.canApplyRedo(from: host.textDocument.contextSnapshot) else {
            refreshControls()
            return
        }
        guard let edit = undoRedoSession.redo() else {
            refreshControls()
            return
        }
        guard applyEdit(edit, host: host) else {
            invalidateHistoryForTextContextChange()
            return
        }
        undoRedoSession.updateLastUndoTargetContext(host.textDocument.contextSnapshot)
        refreshControls()
        FeedbackManager.shared.playHaptic()
    }

    // MARK: - Controls

    /// 후보 바의 undo/redo 버튼 표시·활성 상태를 갱신하고 끝에 클립보드 버튼도 갱신한다
    func refreshControls() {
        guard let host else { return }
        let shouldShowUndoRedo = KeyboardPresentationStatePolicy.shouldShowUndoRedoControls(
            isSuggestionBarHidden: suggestionBarView.isHidden,
            isUndoRedoFeatureAvailable: isUndoRedoFeatureAvailable
        )
        // 기록이 없으면 결과가 문맥과 무관하게 false다.
        // 키보드가 사라질 때처럼 문서 상태가 교체되는 순간 프록시를 읽으면 크래시하므로 읽지 않는다
        let hasUndoRedoHistory = undoRedoSession.canUndo || undoRedoSession.canRedo
        let currentContext = hasUndoRedoHistory
            ? host.textDocument.contextSnapshot
            : KeyboardTextContextSnapshot(beforeInput: nil, afterInput: nil)
        suggestionBarView.updateUndoRedoControls(
            isVisible: shouldShowUndoRedo,
            canUndo: undoRedoSession.canApplyUndo(from: currentContext),
            canRedo: undoRedoSession.canApplyRedo(from: currentContext)
        )
        host.refreshClipboardControl()
    }
}

// MARK: - Private Methods

private extension UndoRedoCoordinator {
    func applyEdit(_ edit: KeyboardUndoRedoEdit, host: UndoRedoHost) -> Bool {
        guard !host.isPreviewMode else { return false }

        return undoRedoSession.performApplyingEdit {
            guard restoreTextPositionIfPossible(to: edit.targetContext, host: host) else { return false }

            for _ in 0..<edit.deleteCount {
                host.textDocument.deleteBackward()
            }
            if !edit.insertText.isEmpty {
                host.textDocument.insertText(edit.insertText)
            }

            host.undoRedoEditDidApply()
            host.refreshReturnButtonEnabled()
            host.refreshSuggestions()
            return true
        }
    }

    func restoreTextPositionIfPossible(to targetContext: KeyboardTextContextSnapshot?, host: UndoRedoHost) -> Bool {
        guard let targetContext else { return true }

        guard let offset = KeyboardTextContextNavigator.cursorOffset(
            from: host.textDocument.contextSnapshot,
            to: targetContext
        ) else {
            return false
        }

        if offset != 0 {
            host.textDocument.adjustTextPosition(byCharacterOffset: offset)
        }
        return true
    }

    func invalidateHistoryForTextContextChange() {
        guard !undoRedoSession.isApplyingEdit else { return }
        undoRedoSession.removeAll()
        refreshControls()
    }
}
```

- [x] **Step 4: pbxproj에 `UndoRedoCoordinator.swift` 등록**

`SYKeyboard.xcodeproj/project.pbxproj`에서 `SYKeyboardCore/Presentation/ViewController/Utils/SuggestionSelectionCoordinator.swift,` 줄이 두 번(SYKeyboard 타깃 약 357줄, SYKeyboardCore 타깃 약 463줄) 나온다. 각 줄 바로 뒤에 같은 들여쓰기로 추가한다.

```
				SYKeyboardCore/Presentation/ViewController/Utils/UndoRedoCoordinator.swift,
```

확인: `grep -c "Utils/UndoRedoCoordinator.swift" SYKeyboard.xcodeproj/project.pbxproj`가 2.

- [x] **Step 5: VC에서 undo/redo 섹션을 Coordinator 호출로 교체**

`BaseKeyboardViewController.swift`를 위에서 아래로 고친다. 줄 번호는 Task 2 뒤 기준이라 조금 어긋날 수 있다.

(a) Properties: `private var undoRedoSession = KeyboardUndoRedoSession()`(주석 포함 2줄)과 `isUndoRedoFeatureAvailable` 계산 프로퍼티(주석 포함 4줄)를 삭제한다.

(b) UI Components: `clipboardHistoryCoordinator` 선언 뒤에 추가한다.

```swift
    /// undo/redo 기록·확정·적용과 컨트롤 갱신을 맡는다. `UndoRedoHost` 채택은 파일 끝의 extension에 있다
    private lazy var undoRedoCoordinator = UndoRedoCoordinator(
        suggestionBarView: suggestionBarView,
        suggestionController: suggestionController,
        keyboardSettingsManager: keyboardSettingsManager,
        host: self
    )
```

(c) `textWillChange`: 

```swift
            undoRedoSession.prepareForTextWillChange(
                inputIdentifier: textInputIdentifier(for: textInput),
                context: currentTextContextSnapshot()
            )
```

→ `undoRedoCoordinator.prepareForTextWillChange(inputIdentifier: textInputIdentifier(for: textInput))`.

(d) `textDidChange`: `invalidateUndoRedoHistoryIfNeededAfterTextChange(textInput)` → `undoRedoCoordinator.invalidateHistoryIfNeededAfterTextChange(inputIdentifier: textInputIdentifier(for: textInput))`.

(e) `viewWillDisappear`: 

```swift
        undoRedoSession.removeAll()
        updateUndoRedoControls()
```

→ `undoRedoCoordinator.removeAllHistory()`.

(f) Public 래퍼 세 개:

```swift
    public final func commitDeferredUndoRedoGroupIfNeeded() {
        undoRedoCoordinator.commitDeferredGroupIfNeeded()
    }

    public final func commitUndoRedoGroupIfPossible() {
        undoRedoCoordinator.commitPendingGroup()
    }

    public final func commitUndoRedoGroupIgnoringCompositionDeferral() {
        undoRedoCoordinator.commitPendingGroupIgnoringDeferral()
    }
```

(문서 주석은 그대로 둔다.)

(g) Update Methods `updateSuggestionBarHidden`: `updateUndoRedoControls()` → `undoRedoCoordinator.refreshControls()`.

(h) Private Methods: `performUndo`, `performRedo`, `applyUndoRedoEdit`, `commitPendingUndoRedoGroup`, `invalidateUndoRedoHistoryForTextContextChange`, `updateUndoRedoControls`, `invalidateUndoRedoHistoryIfNeededAfterTextChange`, `restoreTextPositionIfPossible`을 삭제한다. `recordUndoRedoChange`는 뒷부분만 바꾼다.

```swift
    func recordUndoRedoChange(
        deletedText: String,
        insertedText: String,
        reliability: RepeatDeleteMutationReliability = .authoritative
    ) {
        let captureResult = deleteMutationLifecycle.capture(
            deletedText: deletedText,
            insertedText: insertedText,
            reliability: reliability
        )
        switch captureResult {
        case .awaitingTextChange:
            return
        case .completion(let resolution):
            processDeleteMutationResolution(resolution)
            return
        case nil:
            break
        }

        undoRedoCoordinator.record(deletedText: deletedText, insertedText: insertedText)
    }
```

(i) TextInteractionGestureControllerDelegate 보조 extension `moveCursorIfPossible`: `updateUndoRedoControls()` → `undoRedoCoordinator.refreshControls()`.

(j) Host 채택 extension(`SuggestionSelectionHost`): `func undoLastEdit() { performUndo() }` → `{ undoRedoCoordinator.undo() }`, `redoLastEdit` → `{ undoRedoCoordinator.redo() }`. 파일 끝에 추가한다.

```swift
// MARK: - UndoRedoHost

extension BaseKeyboardViewController: UndoRedoHost {}
```

`textDocument`·`isPreviewMode`·`shouldDeferUndoRedoCommit`·`undoRedoEditDidApply`·`refreshReturnButtonEnabled`·`refreshSuggestions`·`refreshClipboardControl`·`interruptPendingDeleteInteractions`는 이미 VC 본문 또는 `ClipboardHistoryHost` extension에 같은 이름으로 있어 그대로 witness가 된다.

(k) 확인: `grep -n "undoRedoSession\|updateUndoRedoControls\|performUndo\|performRedo\|isUndoRedoFeatureAvailable" Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`가 비어 있어야 한다.

- [x] **Step 6: 테스트 통과 확인**

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/UndoRedoCoordinatorTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerDeleteUndoBehaviorTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerProxyReadTests \
  -only-testing:SYKeyboardTests/BaseKeyboardViewControllerSuggestionClipboardBehaviorTests \
  -only-testing:SYKeyboardTests/ClipboardHistoryCoordinatorTests \
  > "$S/task4-test.log" 2>&1; grep -E "Executed|failed|error:" "$S/task4-test.log" | tail -n 8
```

Expected: 0 failures. Task 1 테스트는 수정 없이 통과한다. 실패하면 Coordinator가 아니라 VC 교체(Step 5)에서 호출 순서가 바뀐 곳을 먼저 의심한다.

- [x] **Step 7: 커밋**

```sh
git branch --show-current
git add Modules/SYKeyboardCore/Presentation/ViewController/Utils/UndoRedoCoordinator.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Utils/UndoRedoCoordinatorTests.swift
git commit -m "$(cat <<'EOF'
refactor: #185 - undo/redo 기록·확정·적용을 UndoRedoCoordinator로 분리

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

#### Task 4 결과 (2026-10-09)

- Step 2 RED: `cannot find type 'UndoRedoHost'`. Step 6: 다섯 suite 통과(`scratchpad/task4-test.log`·`task4-test2.log`). VC 고정 테스트 11개는 수정 없이 통과. `testInputChangeInvalidatesHistory`는 처음에 실패했는데 `ObjectIdentifier(UITextField())`의 임시 객체가 바로 해제돼 두 식별자가 같아진 테스트 결함이었고, 필드를 변수로 살려 두도록 테스트(와 Task 5의 같은 패턴)를 고쳤다. production 변경 없음. VC 2718 → 2579줄.

---

### Task 5: `TextDeletionCoordinator` 추출

**Files:**
- Create: `SYKeyboardTests/Utils/TextDeletionCoordinatorTests.swift`
- Create: `Modules/SYKeyboardCore/Presentation/ViewController/Utils/TextDeletionCoordinator.swift`
- Modify: `SYKeyboard.xcodeproj/project.pbxproj`
- Modify: `Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift`

**Interfaces:**
- Consumes: `DeleteMutationLifecycle`, `DeleteInteractionCoordinator`, `DeletePanTextModel`, `DeletePanBoundaryState`, `DeleteInteractionNonDeleteMutationBoundary.cancel(lifecycle:coordinator:)`, `DeleteInteractionInputChangeBoundary.cancelIfInputIdentifierChanged(to:lifecycle:coordinator:)`, `KeyboardTextInteractionPolicy.*`, `KeyboardDiagnostics.log/bucket`, `FeedbackManager.shared.playHaptic()/playDeleteSound()`, `CursorDragIndicatorView`, `SuggestionService.attemptRestoreReplacement(inputBuffer:documentContextBeforeInput:selectedText:)`, `UserDefaultsManager.repeatRate`, `CachingTextDocumentProxy.contextSnapshot`(Task 2), `UndoRedoCoordinator.record`(Task 4)
- Produces:
  - `protocol TextDeletionHost: AnyObject` — `textDocument`, `currentInputBuffer`, `isViewInWindow`, `textInteractionWillPerform(button:)`, `textInteractionDidPerform(button:)`, `deleteBackward()`, `repeatDeleteBackward()`, `deleteText()`, `replaceText(deleteCount:insert:)`, `deleteButtonPanDeleteText(hasPendingRestoreText:)`, `deleteButtonPanRestoreText(_:)`, `deleteButtonPanDidStop()`, `performRepeatTextInteraction(for:)`, `performDeleteTextInteraction(for:)`, `recordEditForUndo(deletedText:insertedText:)`, `refreshSuggestions()`
  - `final class TextDeletionCoordinator` — `init(deleteDragIndicatorView:suggestionController:keyboardSettingsManager:host:)`, `isRepeatingInput`(`private(set)`), `panPreviousCharacter`, `synchronizeInputIdentifier(_:)`, `completeAfterTextChange(currentContext:)`, `resetInputIdentifier()`, `performTouchDown(for:)`, `finishTouchDown()`, `cancelPendingInteractions()`, `captureMutation(deletedText:insertedText:reliability:) -> Bool`, `takePanDeletedTextOverride() -> String?`, `clearPanRestoreState()`, `beginRepeatInput()`, `endRepeatInput(isDeleteButton:)`, `performRepeatTick(for:)`, `performInitialRepeatDelete(for:)`, `startRepeatInputTimer(for:)`, `stopRepeatInputTracking(preservingTouchDown:)`, `handlePan(to:)`, `handlePanStop()`

- [x] **Step 1: 실패하는 Coordinator 테스트 작성**

가짜 Host는 VC의 래퍼가 제공하는 계약(프록시에 쓰고, 지운 글자를 `captureMutation`으로 삭제 파이프라인에 넘기고, 반복 틱·touchDown 요청을 Coordinator로 되돌려 보냄)을 최소로 흉내 낸다. 그 계약이 실제 VC에서 성립하는지는 Task 1의 VC 수준 테스트가 확인하므로, 이 파일의 단언은 Coordinator가 Host를 부르는 순서·횟수와 프록시 쓰기에 한정한다.

```swift
//
//  TextDeletionCoordinatorTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 10/8/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("삭제 상호작용 Coordinator", .sharedUserDefaults)
@MainActor
struct TextDeletionCoordinatorTests {

    @Test("삭제 touchDown은 hook 사이에서 지우고 release 확정 뒤 undo 기록을 요청")
    func testTouchDownHooksAndRelease() {
        let fixture = makeFixture()

        fixture.coordinator.performTouchDown(for: fixture.button)

        #expect(fixture.host.calls == ["textInteractionWillPerform", "deleteBackward", "textInteractionDidPerform"])
        #expect(fixture.proxy.writes == ["deleteBackward"])
        // 지운 글자는 파이프라인이 capture했으므로 아직 undo에 기록되지 않는다
        #expect(fixture.host.uncapturedEdits.isEmpty)

        fixture.coordinator.finishTouchDown()

        #expect(fixture.host.calls.last == "recordEditForUndo(녕, )")
    }

    @Test("대치 복구가 있으면 삭제 대신 replaceText를 부름")
    func testRestoreReplacementTakesPrecedence() {
        let fixture = makeFixture()
        fixture.service.restoreReplacementResult = (deleteCount: 1, insertText: "abc")

        fixture.coordinator.performTouchDown(for: fixture.button)

        #expect(fixture.host.calls == ["textInteractionWillPerform", "replaceText(1, abc)", "textInteractionDidPerform"])
    }

    @Test("확정 전 두 번째 touchDown은 보류되고 textDidChange 뒤에 drain")
    func testSecondTouchDownIsDrainedAfterTextChange() {
        let fixture = makeFixture()

        fixture.coordinator.performTouchDown(for: fixture.button)
        fixture.coordinator.performTouchDown(for: fixture.button)
        #expect(fixture.proxy.writes == ["deleteBackward"])

        fixture.coordinator.completeAfterTextChange(currentContext: fixture.host.textDocument.contextSnapshot)

        #expect(fixture.proxy.writes == ["deleteBackward", "deleteBackward"])
    }

    @Test("pan 왼쪽은 모델 글자를 override로 넘겨 지우고 오른쪽은 되살리며 종료 시 훅과 인디케이터를 정리")
    func testPanDeleteRestoreStop() {
        let fixture = makeFixture()

        fixture.coordinator.handlePan(to: .left)

        #expect(fixture.indicator.isHidden == false)
        #expect(fixture.host.calls == ["deleteButtonPanDeleteText(false)", "deleteText", "refreshSuggestions"])
        #expect(fixture.host.panDeletedTextOverrides == ["녕"])
        #expect(fixture.proxy.writes == ["deleteBackward"])
        #expect(fixture.coordinator.panPreviousCharacter == "안")

        fixture.coordinator.handlePan(to: .right)

        #expect(fixture.host.calls.suffix(2) == ["deleteButtonPanRestoreText(녕)", "refreshSuggestions"])
        #expect(fixture.proxy.writes == ["deleteBackward", "insertText(녕)"])

        fixture.coordinator.handlePanStop()

        #expect(fixture.host.calls.last == "deleteButtonPanDidStop")
        #expect(fixture.indicator.isHidden)
    }

    @Test("첨부 토큰 앞에서는 pan 삭제를 요청하지 않음")
    func testPanStopsBeforeAttachment() {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = "a\u{FFFC}"

        fixture.coordinator.handlePan(to: .left)

        #expect(fixture.host.calls.isEmpty)
        #expect(fixture.proxy.writes.isEmpty)
    }

    @Test("선택 영역이 있으면 모델 글자를 떼지 않고 복구 버퍼에도 넣지 않음")
    func testPanWithSelectionDoesNotTrackStep() {
        let fixture = makeFixture()
        fixture.proxy.beforeInput = "안"
        fixture.proxy.selected = "녕"

        fixture.coordinator.handlePan(to: .left)
        #expect(fixture.proxy.writes == ["deleteBackward"])
        #expect(fixture.coordinator.panPreviousCharacter == "안")

        fixture.coordinator.handlePan(to: .right)

        #expect(fixture.proxy.writes == ["deleteBackward"])
        #expect(fixture.host.calls.contains("deleteButtonPanRestoreText(녕)") == false)
    }

    @Test("입력창 식별자가 바뀌면 보류된 pan을 끝내고 인디케이터를 숨김")
    func testInputChangeCancelsPendingPan() {
        let fixture = makeFixture()
        // 임시 객체는 바로 해제돼 다음 객체가 같은 주소를 받을 수 있으므로 필드를 살려 둔다
        let firstField = UITextField()
        let secondField = UITextField()
        let first = ObjectIdentifier(firstField)
        let second = ObjectIdentifier(secondField)
        fixture.coordinator.synchronizeInputIdentifier(first)
        fixture.coordinator.performTouchDown(for: fixture.button)
        fixture.coordinator.handlePan(to: .left)
        #expect(fixture.indicator.isHidden == false)

        fixture.coordinator.synchronizeInputIdentifier(second)

        #expect(fixture.host.calls.last == "deleteButtonPanDidStop")
        #expect(fixture.indicator.isHidden)
        #expect(fixture.proxy.writes == ["deleteBackward"])
    }

    @Test("반복 타이머는 host에 틱을 보내고 창 밖이면 멈춤")
    func testRepeatTimerTicksAndStopsOutsideWindow() {
        let fixture = makeFixture()
        // 0.25초 동안 바닥나지 않도록 긴 문맥을 둔다
        fixture.proxy.beforeInput = String(repeating: "가", count: 50)
        fixture.coordinator.beginRepeatInput()
        #expect(fixture.coordinator.isRepeatingInput)

        fixture.coordinator.startRepeatInputTimer(for: fixture.button)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.25))

        #expect(fixture.host.calls.contains("performRepeatTextInteraction"))
        #expect(fixture.proxy.writes.isEmpty == false)

        fixture.host.isViewInWindow = false
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))

        #expect(fixture.coordinator.isRepeatingInput == false)
    }

    @Test("반복 종료는 마지막 틱을 확정하고 반복 상태를 끝냄")
    func testEndRepeatInputCompletesLastTick() {
        let fixture = makeFixture()
        fixture.coordinator.beginRepeatInput()
        fixture.coordinator.performRepeatTick(for: fixture.button)
        #expect(fixture.proxy.writes == ["deleteBackward"])

        fixture.coordinator.endRepeatInput(isDeleteButton: true)

        #expect(fixture.coordinator.isRepeatingInput == false)
        #expect(fixture.host.calls.contains("recordEditForUndo(녕, )"))
    }

    @Test("captureMutation은 진행 중 요청이 없으면 false")
    func testCaptureMutationWithoutRequestReturnsFalse() {
        let fixture = makeFixture()

        let captured = fixture.coordinator.captureMutation(deletedText: "a", insertedText: "", reliability: .proxyContext)

        #expect(captured == false)
    }

    @Test("host가 해제된 뒤에는 어떤 진입점도 쓰지 않음")
    func testReleasedHostIsIgnored() {
        let fixture = makeFixture()
        var host: RecordingTextDeletionHost? = RecordingTextDeletionHost(proxy: fixture.proxy)
        let coordinator = TextDeletionCoordinator(
            deleteDragIndicatorView: fixture.indicator,
            suggestionController: fixture.service,
            keyboardSettingsManager: .shared,
            host: host!
        )
        host = nil

        coordinator.performTouchDown(for: fixture.button)
        coordinator.finishTouchDown()
        coordinator.handlePan(to: .left)
        coordinator.handlePan(to: .right)
        coordinator.handlePanStop()
        coordinator.beginRepeatInput()
        coordinator.performRepeatTick(for: fixture.button)
        coordinator.performInitialRepeatDelete(for: fixture.button)
        coordinator.startRepeatInputTimer(for: fixture.button)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
        coordinator.completeAfterTextChange(currentContext: fixture.host.textDocument.contextSnapshot)
        coordinator.endRepeatInput(isDeleteButton: true)

        #expect(fixture.proxy.writes.isEmpty)
    }

    @Test("타이머와 경계 대기가 걸린 Coordinator는 참조를 놓으면 해제됨")
    func testCoordinatorIsReleased() {
        weak var weakCoordinator: TextDeletionCoordinator?
        autoreleasepool {
            let fixture = makeFixture()
            fixture.coordinator.beginRepeatInput()
            fixture.coordinator.startRepeatInputTimer(for: fixture.button)
            // 모델이 바닥난 상태에서 pan을 보내 줄 경계 요청과 타임아웃(asyncAfter)을 예약한다
            fixture.proxy.beforeInput = ""
            fixture.coordinator.handlePan(to: .left)
            weakCoordinator = fixture.coordinator
        }

        #expect(weakCoordinator == nil)
        // 예약된 타이머 틱·타임아웃 클로저가 실행돼도 크래시가 없어야 한다
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.3))
    }
}

// MARK: - Test Helpers

/// VC의 래퍼 계약을 흉내 내는 host: 프록시에 쓰고, 지운 글자를 Coordinator의 `captureMutation`에 넘기며,
/// 반복 틱·touchDown 요청은 Coordinator로 되돌려 보낸다
@MainActor
private final class RecordingTextDeletionHost: TextDeletionHost {
    var calls: [String] = []
    /// 파이프라인이 capture하지 않아 undo에 바로 기록됐을 편집
    var uncapturedEdits: [String] = []
    /// `deleteText()`가 `takePanDeletedTextOverride()`로 받은 값
    var panDeletedTextOverrides: [String?] = []
    var currentInputBuffer = ""
    var isViewInWindow = true
    let textDocument: CachingTextDocumentProxy
    weak var coordinator: TextDeletionCoordinator?

    init(proxy: CountingTextDocumentProxy) {
        textDocument = CachingTextDocumentProxy { proxy }
    }

    func textInteractionWillPerform(button: TextInteractable) { calls.append("textInteractionWillPerform") }
    func textInteractionDidPerform(button: TextInteractable) { calls.append("textInteractionDidPerform") }
    func deleteBackward() { calls.append("deleteBackward"); performSingleDelete() }
    func repeatDeleteBackward() { calls.append("repeatDeleteBackward"); performSingleDelete() }
    func deleteText() { calls.append("deleteText"); performSingleDelete() }

    func replaceText(deleteCount: Int, insert text: String) {
        calls.append("replaceText(\(deleteCount), \(text))")
        let deletedText = String((textDocument.documentContextBeforeInput ?? "").suffix(deleteCount))
        for _ in 0..<deleteCount { textDocument.deleteBackward() }
        if !text.isEmpty { textDocument.insertText(text) }
        capture(deletedText: deletedText, insertedText: text, reliability: .authoritative)
    }

    func deleteButtonPanDeleteText(hasPendingRestoreText: Bool) -> (character: Character, shouldRestore: Bool)? {
        calls.append("deleteButtonPanDeleteText(\(hasPendingRestoreText))")
        // Base VC의 기본 구현과 같다: 모델 글자가 없으면 nil, 있으면 deleteText()
        guard let character = coordinator?.panPreviousCharacter else { return nil }
        deleteText()
        return (character, true)
    }

    func deleteButtonPanRestoreText(_ character: Character) {
        calls.append("deleteButtonPanRestoreText(\(character))")
        textDocument.insertText(String(character))
        capture(deletedText: "", insertedText: String(character), reliability: .authoritative)
    }

    func deleteButtonPanDidStop() { calls.append("deleteButtonPanDidStop") }

    func performRepeatTextInteraction(for button: TextInteractable) {
        calls.append("performRepeatTextInteraction")
        coordinator?.performRepeatTick(for: button)
    }

    func performDeleteTextInteraction(for button: TextInteractable) {
        calls.append("performDeleteTextInteraction")
        coordinator?.performTouchDown(for: button)
    }

    func recordEditForUndo(deletedText: String, insertedText: String) {
        calls.append("recordEditForUndo(\(deletedText), \(insertedText))")
        capture(deletedText: deletedText, insertedText: insertedText, reliability: .authoritative)
    }

    func refreshSuggestions() { calls.append("refreshSuggestions") }

    /// VC `deleteText()`의 계약: 선택 영역이 비었으면 pan override, 아니면 선택 텍스트·앞 글자를 지운 글자로 삼는다
    private func performSingleDelete() {
        let selectedText = textDocument.selectedText
        let override = coordinator?.takePanDeletedTextOverride()
        panDeletedTextOverrides.append(override)
        let deletedText = ((selectedText ?? "").isEmpty ? override : nil)
            ?? KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: selectedText,
                documentContextBeforeInput: textDocument.documentContextBeforeInput
            )
        textDocument.deleteBackward()
        capture(
            deletedText: deletedText,
            insertedText: "",
            reliability: selectedText?.isEmpty == false ? .authoritative : .proxyContext
        )
    }

    private func capture(deletedText: String, insertedText: String, reliability: RepeatDeleteMutationReliability) {
        let captured = coordinator?.captureMutation(
            deletedText: deletedText, insertedText: insertedText, reliability: reliability
        ) ?? false
        if !captured { uncapturedEdits.append("\(deletedText)/\(insertedText)") }
    }
}

@MainActor
private struct Fixture {
    let coordinator: TextDeletionCoordinator
    let host: RecordingTextDeletionHost
    let service: FakeSuggestionService
    let indicator: CursorDragIndicatorView
    let proxy: CountingTextDocumentProxy
    let button: DeleteButton
}

/// 앞 문맥 "안녕", 선택 없음, 보이지 않는 인디케이터로 시작한다
@MainActor
private func makeFixture() -> Fixture {
    let proxy = CountingTextDocumentProxy()
    let host = RecordingTextDeletionHost(proxy: proxy)
    let service = FakeSuggestionService()
    let indicator = CursorDragIndicatorView(symbolName: CursorDragIndicatorSymbolFactory.deleteSymbolName)
    indicator.isHidden = true
    let coordinator = TextDeletionCoordinator(
        deleteDragIndicatorView: indicator,
        suggestionController: service,
        keyboardSettingsManager: .shared,
        host: host
    )
    host.coordinator = coordinator
    return Fixture(
        coordinator: coordinator,
        host: host,
        service: service,
        indicator: indicator,
        proxy: proxy,
        button: DeleteButton(keyboard: .dubeolsik)
    )
}
```

`FakeSuggestionService.attemptRestoreReplacement`는 지금 항상 `nil`을 돌려준다. `SYKeyboardTests/Utils/FakeSuggestionService.swift`의 stub 프로퍼티 목록(`textReplacementPreviewSuggestionIndexResult` 아래)에 `var restoreReplacementResult: (deleteCount: Int, insertText: String)?`를 추가하고 `attemptRestoreReplacement`가 `return restoreReplacementResult`를 돌려주게 바꾼다(`calls.append`는 유지).

- [x] **Step 2: 컴파일 실패 확인**

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
timeout 300 xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  -only-testing:SYKeyboardTests/TextDeletionCoordinatorTests \
  > "$S/task5-red.log" 2>&1; grep -E "error:" "$S/task5-red.log" | head -n 3
```

Expected: `cannot find type 'TextDeletionHost' in scope`.

- [x] **Step 3: `TextDeletionCoordinator.swift` 작성**

VC의 Private Methods(삭제 부분)와 `TextInteractionGestureControllerDelegate` 보조 extension(삭제 pan 부분), `startRepeatInputTimer`, `stopRepeatInputTracking`, `cancelTimer`, `finishRepeatDeleteWithoutDeletion`을 옮긴 것이다. 바뀐 것은 `self`의 VC 멤버 → `host.`, `currentTextContextSnapshot()` → `host.textDocument.contextSnapshot`, `textDocument.` → `host.textDocument.`, `recordUndoRedoChange(deletedText:insertedText:)` → `host.recordEditForUndo`, `updateSuggestions()` → `host.refreshSuggestions()`, `inputBuffer` → `host.currentInputBuffer`, `view.window` → `host.isViewInWindow`, `performTextInteraction(for:)` → `host.performDeleteTextInteraction(for:)`, `cancelPendingDeleteInteractions()` → `cancelPendingInteractions()`, `deleteButtonPanPreviousCharacter` → `panPreviousCharacter`뿐이다.

```swift
//
//  TextDeletionCoordinator.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit
import Combine
import OSLog

/// `TextDeletionCoordinator`가 소유자(`BaseKeyboardViewController`)에게 요구하는 것.
/// 삭제 파이프라인의 프록시 쓰기는 전부 VC의 `open`/`public` 메서드를 거치므로 대부분 같은 이름으로 witness가 된다.
/// `performDeleteTextInteraction(for:)`는 기본 인자가 있는 `performTextInteraction(for:)`를, `recordEditForUndo`는 private
/// `recordUndoRedoChange`를, `refreshSuggestions`는 private `updateSuggestions`를 감싼 이름이다
@MainActor
protocol TextDeletionHost: AnyObject {
    /// VC의 프록시 창구. Coordinator는 이 값을 저장하지 않고 호출마다 읽는다. 캐시 범위가 VC 콜백에 묶여 있기 때문이다
    var textDocument: CachingTextDocumentProxy { get }
    /// VC의 private `inputBuffer`. 단일 삭제의 대치 복구 판정에 쓴다
    var currentInputBuffer: String { get }
    /// 반복 타이머가 창 밖이면 멈추기 위한 판정
    var isViewInWindow: Bool { get }

    func textInteractionWillPerform(button: TextInteractable)
    func textInteractionDidPerform(button: TextInteractable)
    func deleteBackward()
    func repeatDeleteBackward()
    func deleteText()
    func replaceText(deleteCount: Int, insert text: String)
    func deleteButtonPanDeleteText(hasPendingRestoreText: Bool) -> (character: Character, shouldRestore: Bool)?
    func deleteButtonPanRestoreText(_ character: Character)
    func deleteButtonPanDidStop()
    func performRepeatTextInteraction(for button: TextInteractable)
    /// VC의 `performTextInteraction(for:)`. 한글 VC의 첫 반복 삭제가 조합 상태를 보존한 채 일반 삭제 경로를 타게 한다
    func performDeleteTextInteraction(for button: TextInteractable)
    /// VC의 `recordUndoRedoChange(deletedText:insertedText:)`. 확정된 draft를 undo에 기록할 때 부른다
    func recordEditForUndo(deletedText: String, insertedText: String)
    func refreshSuggestions()
}

/// 삭제 touchDown·반복 틱·pan 삭제/복구·줄 경계 추론·보류 큐 drain·반복 입력 타이머·삭제 드래그 인디케이터를 맡는다.
/// 삭제 파이프라인 상태(`DeleteMutationLifecycle`, `DeleteInteractionCoordinator`)와 pan 모델·복구 버퍼·타이머를 소유하고,
/// 실제 프록시 쓰기와 하위 VC 훅은 host에 요청한다.
/// host는 `weak`다. `DispatchQueue.main.asyncAfter`와 타이머 sink가 이 객체를 VC보다 오래 살릴 수 있으므로
/// host가 필요한 진입점은 `guard let host`로 시작하고, 상태만 바꾸는 메서드는 host 없이 동작한다
@MainActor
final class TextDeletionCoordinator {

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "TextDeletionCoordinator")

    /// 현재 반복 입력 동작 중인지 확인하는 플래그. VC가 `isRepeatingInput`으로 노출한다
    private(set) var isRepeatingInput: Bool = false
    /// 삭제 버튼 팬 제스처가 다음에 지울 커서 앞 글자. VC가 `deleteButtonPanPreviousCharacter`로 노출한다
    ///
    /// 입력창이 늦게 보낸 낡은 문맥을 읽지 않도록 `documentContextBeforeInput` 대신 드래그 시작 때 읽은 모델을 따른다
    var panPreviousCharacter: Character? {
        return deletePanTextModel?.lastCharacter
    }

    /// 반복 입력용 타이머
    private var timer: AnyCancellable?
    /// 진단용 반복 입력 tick 수. 구간으로만 기록한다
    private var repeatInputTickCount: Int = 0
    /// touchDown과 반복 삭제 요청을 실제 문맥 변경 확인 후 성공 또는 무효로 한 번만 완료합니다.
    private var deleteMutationLifecycle = DeleteMutationLifecycle()
    /// 삭제 touchDown, pan, pan stop을 generation 단위 FIFO로 조정합니다.
    private var deleteInteractionCoordinator = DeleteInteractionCoordinator()
    /// 보류 삭제 drain 중 동기 callback 재진입을 막습니다.
    private var isDrainingPendingDeleteInteractions = false
    /// 현재 host text input의 식별자입니다.
    private var currentTextInputIdentifier: ObjectIdentifier?
    /// 삭제 버튼 팬 제스처로 인해 임시로 삭제된 내용을 저장하는 변수
    private var tempDeletedCharacters: [Character] = []
    /// 삭제 버튼 팬 제스처 동안 커서 앞 문맥을 대신하는 모델(드래그 시작 때 한 번 읽음)
    private var deletePanTextModel: DeletePanTextModel?
    /// 삭제 버튼 팬 제스처가 마지막으로 문서를 편집한 시각
    private var lastDeletePanEditTime: CFTimeInterval = 0
    /// 삭제 버튼 팬 제스처가 줄 경계를 넘을 때의 대기·막힘 상태
    private var deletePanBoundaryState = DeletePanBoundaryState()
    /// 다음 `deleteText()`가 undo에 기록할 삭제 문자열(삭제 버튼 팬 제스처가 모델에서 정한 값)
    private var deletePanDeletedTextOverride: String?

    private let deleteDragIndicatorView: CursorDragIndicatorView
    private let suggestionController: SuggestionService
    private let keyboardSettingsManager: UserDefaultsManager
    private weak var host: TextDeletionHost?

    // MARK: - Initializer

    init(
        deleteDragIndicatorView: CursorDragIndicatorView,
        suggestionController: SuggestionService,
        keyboardSettingsManager: UserDefaultsManager,
        host: TextDeletionHost
    ) {
        self.deleteDragIndicatorView = deleteDragIndicatorView
        self.suggestionController = suggestionController
        self.keyboardSettingsManager = keyboardSettingsManager
        self.host = host
    }

    deinit {
        logger.debug("TextDeletionCoordinator deinit")
    }

    // MARK: - Text Change Callbacks

    /// `textWillChange`/`textDidChange`에서 VC가 부른다. 입력창이 바뀌었으면 진행·보류 삭제를 모두 취소한다
    func synchronizeInputIdentifier(_ inputIdentifier: ObjectIdentifier?) {
        if let cancellation = DeleteInteractionInputChangeBoundary.cancelIfInputIdentifierChanged(
            to: inputIdentifier,
            lifecycle: &deleteMutationLifecycle,
            coordinator: &deleteInteractionCoordinator
        ) {
            finishCancelledDeletePanIfNeeded(cancellation)
        }
        if let inputIdentifier {
            currentTextInputIdentifier = inputIdentifier
        }
    }

    /// `textDidChange`에서 VC가 부른다. 앞·뒤 문맥은 VC가 커서 햅틱 판정에 쓴 스냅샷을 그대로 받아 읽기 횟수를 유지한다
    func completeAfterTextChange(currentContext: KeyboardTextContextSnapshot) {
        guard let host else { return }
        let deleteMutationOutcome = deleteMutationLifecycle.completeAfterTextChange(
            currentContext: currentContext,
            currentSelectedText: host.textDocument.selectedText
        )
        processDeleteMutationCallbackOutcome(deleteMutationOutcome)
        resumePendingDeletePanBoundaryIfNeeded()
    }

    /// `viewWillDisappear`에서 VC가 부른다
    func resetInputIdentifier() {
        currentTextInputIdentifier = nil
    }

    // MARK: - Touch Down

    /// 삭제 버튼 touchDown. 반복 중이 아니면 released 요청을 체크포인트로 확정하고 새 요청을 시작한다
    func performTouchDown(for button: TextInteractable) {
        guard let host else { return }
        if !isRepeatingInput {
            let previousResolution = deleteMutationLifecycle
                .completeReleasedTouchDownAtCheckpoint(
                    currentContext: host.textDocument.contextSnapshot,
                    currentSelectedText: host.textDocument.selectedText
                )
            processDeleteMutationResolution(previousResolution)

            let disposition = deleteInteractionCoordinator.beginTouchDown(
                button: button,
                inputIdentifier: currentTextInputIdentifier
            )
            if disposition == .enqueued {
                return
            }
            guard beginDeleteTouchDownRequest() == .started else {
                cancelPendingInteractions()
                return
            }
        }
        performDeleteTextInteractionWithSemanticHooks(for: button) {
            performDeleteButtonTextInteraction()
        }
    }

    /// 삭제 버튼 release. 확정 가능하면 즉시 resolve, 아니면 released로 전환해 `textDidChange`를 기다린다
    func finishTouchDown() {
        guard let host else { return }
        let resolution = deleteMutationLifecycle.finishTouchDown(
            currentContext: host.textDocument.contextSnapshot,
            currentSelectedText: host.textDocument.selectedText
        )
        processDeleteMutationResolution(resolution)
    }

    /// 삭제가 아닌 입력, undo/redo, 클립보드 패널 열기처럼 진행·보류 삭제를 모두 버려야 할 때
    func cancelPendingInteractions() {
        finishCancelledDeletePanIfNeeded(
            DeleteInteractionNonDeleteMutationBoundary.cancel(
                lifecycle: &deleteMutationLifecycle,
                coordinator: &deleteInteractionCoordinator
            )
        )
    }

    /// 래퍼가 수행한 편집을 삭제 파이프라인에 캡처한다. VC의 `recordUndoRedoChange`가 먼저 부른다.
    /// - Returns: 파이프라인이 처리했으면 `true`(기다리거나 확정했음). `false`면 VC가 undo에 바로 기록한다
    func captureMutation(
        deletedText: String,
        insertedText: String,
        reliability: RepeatDeleteMutationReliability
    ) -> Bool {
        let captureResult = deleteMutationLifecycle.capture(
            deletedText: deletedText,
            insertedText: insertedText,
            reliability: reliability
        )
        switch captureResult {
        case .awaitingTextChange:
            return true
        case .completion(let resolution):
            processDeleteMutationResolution(resolution)
            return true
        case nil:
            return false
        }
    }

    /// pan 삭제가 모델에서 정한 지울 글자. VC의 `deleteText()`가 받아 가며 한 번 읽으면 지워진다
    func takePanDeletedTextOverride() -> String? {
        defer { deletePanDeletedTextOverride = nil }
        return deletePanDeletedTextOverride
    }

    /// `textInteractionWillPerform`에서 VC가 부른다. 삭제 이외의 입력이 끼어들면 복구 버퍼가 사라진다
    func clearPanRestoreState() {
        tempDeletedCharacters.removeAll()
        resetDeletePanTextModel()
    }

    // MARK: - Repeat Input

    /// `repeatTextInteractionWillPerform`에서 VC가 부른다
    func beginRepeatInput() {
        // 방어 코드
        cancelTimer()
        isRepeatingInput = true
    }

    /// `repeatTextInteractionDidPerform`에서 VC가 부른다. 삭제 버튼이면 마지막 틱을 확정 시도한다
    func endRepeatInput(isDeleteButton: Bool) {
        if isDeleteButton {
            completeRepeatDeleteAtCurrentContext()
        }
        stopRepeatInputTracking(preservingTouchDown: isDeleteButton)
        tempDeletedCharacters.removeAll()
        resetDeletePanTextModel()
    }

    /// 반복 타이머 틱의 삭제 버튼 처리
    func performRepeatTick(for button: TextInteractable) {
        performDeleteTextInteractionWithSemanticHooks(for: button) {
            performRepeatDeleteTextInteraction()
        }
    }

    /// 한글 조합 상태를 보존하는 첫 반복 삭제. `view.window` 확인은 VC에 남아 있다
    func performInitialRepeatDelete(for button: TextInteractable) {
        guard let host else { return }
        let action = deleteMutationLifecycle.actionForNextRepeat(
            currentContext: host.textDocument.contextSnapshot,
            currentSelectedText: host.textDocument.selectedText
        )
        switch action {
        case .deleteAwaitingTextChange(let previousResolution):
            processDeleteMutationResolution(previousResolution)
            guard beginRepeatDeleteRequest() == .started else { return }
            host.performDeleteTextInteraction(for: button)
        case .awaitingPreviousMutation:
            return
        case .finishWithoutDeletion:
            finishRepeatDeleteWithoutDeletion()
        }
    }

    func startRepeatInputTimer(for button: TextInteractable) {
        let repeatTimerInterval = KeyboardTextInteractionPolicy.repeatTimerInterval(
            repeatRate: keyboardSettingsManager.repeatRate
        )
        repeatInputTickCount = 0
        KeyboardDiagnostics.log(
            "repeatInput start button=\(String(describing: type(of: button))) interval=\(repeatTimerInterval)"
        )
        let startedInputIdentifier = currentTextInputIdentifier
        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self, weak button] _ in
                guard let self else { return }
                if !KeyboardTextInteractionPolicy.shouldContinueRepeatInput(
                    startedInputIdentifier: startedInputIdentifier,
                    currentInputIdentifier: self.currentTextInputIdentifier
                ) {
                    self.stopRepeatInputTracking()
                    return
                }
                guard let host = self.host, host.isViewInWindow else {
                    self.stopRepeatInputTracking()
                    return
                }
                guard let button else {
                    self.stopRepeatInputTracking()
                    return
                }

                host.performRepeatTextInteraction(for: button)
            }
        logger.debug("반복 타이머 생성")
    }

    func stopRepeatInputTracking(preservingTouchDown: Bool = false) {
        KeyboardDiagnostics.log(
            "repeatInput stop ticks=\(KeyboardDiagnostics.bucket(repeatInputTickCount))"
            + " preservingTouchDown=\(preservingTouchDown)"
        )
        cancelTimer()
        if preservingTouchDown {
            deleteMutationLifecycle.finishRepeatTracking()
        } else {
            cancelPendingInteractions()
        }
        isRepeatingInput = false
    }

    // MARK: - Delete Pan

    /// `deleteButtonPanning`에서 VC가 부른다
    func handlePan(to direction: PanDirection) {
        showDeleteDragOverlays()
        guard deleteInteractionCoordinator.enqueuePan(direction) == .performNow else {
            // 경계 요청을 보내기 전이면 방향을 바꾼 사용자를 기다리게 하지 않는다
            if deletePanBoundaryState.shouldCancelPendingBeforeSend(on: .pan(direction: direction)) {
                cancelPendingDeletePanBoundary()
            }
            return
        }
        performDeleteButtonPanIfLifecycleReady(to: direction)
    }

    /// `deleteButtonPanStopped`에서 VC가 부른다
    func handlePanStop() {
        hideDeleteDragOverlays()
        guard deleteInteractionCoordinator.enqueuePanStop() == .performNow else {
            // 경계 요청을 보내기 전이면 손을 뗀 뒤에 보내지 않고 바로 끝낸다
            if deletePanBoundaryState.shouldCancelPendingBeforeSend(on: .panStop) {
                cancelPendingDeletePanBoundary()
                return
            }
            guard let host else { return }
            let generation = deleteInteractionCoordinator.currentGeneration
            let resolution = deleteMutationLifecycle.finishPanBoundary(
                currentContext: host.textDocument.contextSnapshot,
                currentSelectedText: host.textDocument.selectedText
            )
            processDeleteMutationResolution(resolution)
            if let generation,
               resolution == nil,
               deleteMutationLifecycle.hasReleasedPanBoundaryRequest {
                scheduleReleasedPanBoundaryCheckpoint(for: generation)
            }
            return
        }
        finishDeleteButtonPanTracking()
    }
}

// MARK: - Private Methods

private extension TextDeletionCoordinator {
    func performDeleteTextInteractionWithSemanticHooks(
        for button: TextInteractable,
        body: () -> Void
    ) {
        guard let host else { return }
        let wasDraining = isDrainingPendingDeleteInteractions
        isDrainingPendingDeleteInteractions = true
        host.textInteractionWillPerform(button: button)
        defer {
            host.textInteractionDidPerform(button: button)
            isDrainingPendingDeleteInteractions = wasDraining
            if !wasDraining {
                drainPendingDeleteInteractionsIfPossible()
            }
        }
        body()
    }

    func performRepeatDeleteTextInteraction() {
        guard let host else { return }
        repeatInputTickCount += 1
        let context = host.textDocument.contextSnapshot
        let selectedText = host.textDocument.selectedText
        let action = deleteMutationLifecycle.actionForNextRepeat(
            currentContext: context,
            currentSelectedText: selectedText
        )
        switch action {
        case .deleteAwaitingTextChange(let previousResolution):
            // 처리할 이전 결과가 없으면 그 사이 프록시가 바뀌지 않으므로 방금 읽은 문맥을 다시 쓴다.
            // 프록시 읽기는 UIKit 내부 레이스로 크래시할 수 있어 틱마다 읽는 횟수를 줄인다
            let startState = previousResolution == nil ? (context, selectedText) : nil
            processDeleteMutationResolution(previousResolution)
            guard beginRepeatDeleteRequest(reusing: startState) == .started else { return }
            host.repeatDeleteBackward()
        case .awaitingPreviousMutation:
            return
        case .finishWithoutDeletion:
            finishRepeatDeleteWithoutDeletion()
        }
    }

    func beginDeleteTouchDownRequest() -> DeleteMutationStartResult {
        guard let host else { return .deferred }
        return deleteMutationLifecycle.beginTouchDown(
            context: host.textDocument.contextSnapshot,
            selectedText: host.textDocument.selectedText
        )
    }

    /// - Parameter startState: 같은 틱에서 이미 읽은 문맥. `nil`이면 프록시에서 새로 읽는다
    func beginRepeatDeleteRequest(
        reusing startState: (KeyboardTextContextSnapshot, String?)? = nil
    ) -> DeleteMutationStartResult {
        guard let host else { return .deferred }
        guard deleteInteractionCoordinator.beginRepeatMutation(
            inputIdentifier: currentTextInputIdentifier
        ) != nil else {
            return .awaitingPreviousMutation
        }

        let (context, selectedText) = startState
            ?? (host.textDocument.contextSnapshot, host.textDocument.selectedText)
        let result = deleteMutationLifecycle.beginRepeat(
            context: context,
            selectedText: selectedText
        )
        guard result == .started else {
            cancelPendingInteractions()
            return result
        }
        return .started
    }

    func performDeleteButtonTextInteraction() {
        guard let host else { return }
        if let restore = suggestionController.attemptRestoreReplacement(
            inputBuffer: host.currentInputBuffer,
            documentContextBeforeInput: host.textDocument.documentContextBeforeInput,
            selectedText: host.textDocument.selectedText
        ) {
            host.replaceText(deleteCount: restore.deleteCount, insert: restore.insertText)
            return
        }

        let deletedCharacters = KeyboardTextInteractionPolicy.temporaryDeletedCharactersForSingleDelete(
            selectedText: host.textDocument.selectedText,
            documentContextBeforeInput: host.textDocument.documentContextBeforeInput
        )
        tempDeletedCharacters.append(contentsOf: deletedCharacters)
        host.deleteBackward()
    }

    func processDeleteMutationResolution(_ resolution: DeleteMutationResolution?) {
        guard let resolution, let host else { return }

        let effects = KeyboardTextInteractionPolicy.mutationResolutionEffects(resolution)
        tempDeletedCharacters.append(contentsOf: effects.restorableCharacters)
        deletePanBoundaryState.didResolve(resolution)
        if resolution.origin == .panBoundary, !effects.restorableCharacters.isEmpty {
            // 줄바꿈을 지워 새로 보이는 이전 줄로 모델을 다시 채운다
            deletePanTextModel = DeletePanTextModel(beforeInput: host.textDocument.documentContextBeforeInput)
        }

        if effects.appliesMutationEffects,
           case .mutations(let drafts) = resolution.completion {
            for draft in drafts {
                host.recordEditForUndo(
                    deletedText: draft.deletedText,
                    insertedText: draft.insertedText
                )
            }
        }
        if effects.appliesMutationEffects && resolution.shouldPlayFeedback {
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playDeleteSound()
        }
        guard !effects.settlesBeforeResumingPan else {
            resumeDeletePanAfterSettling()
            return
        }
        resolvePendingDeleteInteractionsIfNeeded(
            discardingLeadingNoOpPanLeft: effects.discardsLeadingNoOpPanLeft
        )
        drainPendingDeleteInteractionsIfPossible()
    }

    /// 줄바꿈 삭제 뒤 입력창이 늦게 보내는 callback을 먼저 받은 다음 보류된 pan을 이어서 재생합니다.
    func resumeDeletePanAfterSettling() {
        guard let generation = deleteInteractionCoordinator.currentGeneration else { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + KeyboardTextInteractionPolicy.deletePanBoundaryQuietInterval
        ) { [weak self] in
            guard let self,
                  self.deleteInteractionCoordinator.currentGeneration == generation,
                  self.deleteInteractionCoordinator.isWaitingForResolution,
                  !self.deleteMutationLifecycle.isPending
            else { return }

            self.resolvePendingDeleteInteractionsIfNeeded(discardingLeadingNoOpPanLeft: false)
            self.drainPendingDeleteInteractionsIfPossible()
        }
    }

    func processDeleteMutationCallbackOutcome(_ outcome: DeleteMutationCallbackOutcome) {
        switch outcome {
        case .noResolution:
            break
        case .resolved(let resolution):
            processDeleteMutationResolution(resolution)
        case .cancelled:
            cancelPendingInteractions()
        }
    }

    func resolvePendingDeleteInteractionsIfNeeded(
        discardingLeadingNoOpPanLeft: Bool
    ) {
        guard let generation = deleteInteractionCoordinator.currentGeneration else { return }
        _ = deleteInteractionCoordinator.resolve(
            generation,
            discardingLeadingNoOpPanLeft: discardingLeadingNoOpPanLeft
        )
    }

    @discardableResult
    func completeRepeatDeleteAtCurrentContext() -> Bool {
        guard let host else { return false }
        let resolution = deleteMutationLifecycle.completeAtCheckpoint(
            currentContext: host.textDocument.contextSnapshot,
            currentSelectedText: host.textDocument.selectedText
        )
        guard resolution != nil else { return false }

        processDeleteMutationResolution(resolution)
        return true
    }

    func cancelTimer() {
        timer?.cancel()
        timer = nil
        logger.debug("반복 타이머 초기화")
    }

    func finishRepeatDeleteWithoutDeletion() {
        KeyboardDiagnostics.log("repeatDelete exhausted")
        guard deleteMutationLifecycle.completeWithoutDeletion() == .noDeletion else { return }

        stopRepeatInputTracking()
    }

    func showDeleteDragOverlays() {
        deleteDragIndicatorView.isHidden = false
    }

    func hideDeleteDragOverlays() {
        deleteDragIndicatorView.isHidden = true
    }

    func drainPendingDeleteInteractionsIfPossible() {
        guard !isDrainingPendingDeleteInteractions, let host else { return }

        isDrainingPendingDeleteInteractions = true
        defer { isDrainingPendingDeleteInteractions = false }

        while let event = deleteInteractionCoordinator.nextReadyEvent() {
            switch event {
            case .touchDown(let button):
                guard beginDeleteTouchDownRequest() == .started else {
                    cancelPendingInteractions()
                    return
                }
                performDeleteTextInteractionWithSemanticHooks(for: button) {
                    performDeleteButtonTextInteraction()
                }
                let resolution = deleteMutationLifecycle.finishTouchDown(
                    currentContext: host.textDocument.contextSnapshot,
                    currentSelectedText: host.textDocument.selectedText
                )
                processDeleteMutationResolution(resolution)
                if deleteMutationLifecycle.isPending {
                    return
                }
            case .pan(let direction):
                performDeleteButtonPanIfLifecycleReady(to: direction)
                if deleteMutationLifecycle.isPending {
                    return
                }
            case .panStop:
                finishDeleteButtonPanTracking()
            }
        }
    }

    func finishCancelledDeletePanIfNeeded(_ cancellation: DeleteInteractionCancellationResult) {
        guard cancellation.shouldFinishPanTracking else { return }

        hideDeleteDragOverlays()
        tempDeletedCharacters.removeAll()
        resetDeletePanTextModel()
        host?.deleteButtonPanDidStop()
        logger.debug("취소된 삭제 pan 임시 상태 초기화")
    }

    func performDeleteButtonPanInteraction(to direction: PanDirection) {
        switch direction {
        case .left:
            performDeleteButtonPanDeleteIfPossible()
        case .right:
            performDeleteButtonPanRestoreIfPossible()
        default:
            assertionFailure("도달할 수 없는 case 입니다.")
        }
    }

    func performDeleteButtonPanIfLifecycleReady(to direction: PanDirection) {
        guard let host else { return }
        let action = deleteMutationLifecycle.actionForDeletePan(
            currentContext: host.textDocument.contextSnapshot,
            currentSelectedText: host.textDocument.selectedText
        )
        switch action {
        case .perform(let previousResolution):
            processDeleteMutationResolution(previousResolution)
            performDeleteButtonPanInteraction(to: direction)
        case .awaitingPreviousMutation:
            return
        }
    }

    /// 드래그의 첫 삭제·복구 전에 커서 앞 문맥을 한 번 읽어 모델을 만듭니다.
    func prepareDeletePanTextModelIfNeeded() {
        guard deletePanTextModel == nil, let host else { return }
        deletePanTextModel = DeletePanTextModel(beforeInput: host.textDocument.documentContextBeforeInput)
    }

    func resetDeletePanTextModel() {
        deletePanTextModel = nil
        deletePanBoundaryState.reset()
    }

    func scheduleReleasedPanBoundaryCheckpoint(
        for generation: DeleteInteractionGeneration
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let host = self.host,
                  self.deleteInteractionCoordinator.currentGeneration == generation,
                  self.deleteInteractionCoordinator.isWaitingForResolution,
                  self.deleteMutationLifecycle.hasReleasedPanBoundaryRequest
            else { return }

            let resolution = self.deleteMutationLifecycle.completeAtCheckpoint(
                currentContext: host.textDocument.contextSnapshot,
                currentSelectedText: host.textDocument.selectedText
            )
            guard let resolution else {
                self.cancelPendingInteractions()
                return
            }
            self.processDeleteMutationResolution(resolution)
        }
    }

    func finishDeleteButtonPanTracking() {
        tempDeletedCharacters.removeAll()
        resetDeletePanTextModel()
        host?.deleteButtonPanDidStop()
        logger.debug("임시 삭제 내용 저장 변수 초기화")
    }

    func performDeleteButtonPanDeleteIfPossible() {
        guard let host else { return }
        prepareDeletePanTextModelIfNeeded()
        let selectedText = host.textDocument.selectedText
        // 되살릴 수 없는 첨부·토큰 앞에서는 지우지 않고 멈춘다
        guard !KeyboardTextInteractionPolicy.shouldStopDeletePan(
            previousCharacter: panPreviousCharacter,
            selectedText: selectedText
        ) else { return }
        deletePanDeletedTextOverride = panPreviousCharacter.map(String.init)
        let deleteResult = host.deleteButtonPanDeleteText(
            hasPendingRestoreText: !tempDeletedCharacters.isEmpty
        )
        deletePanDeletedTextOverride = nil
        if let deleteResult {
            lastDeletePanEditTime = CACurrentMediaTime()
            if KeyboardTextInteractionPolicy.shouldTrackDeletePanStep(selectedText: selectedText) {
                deletePanTextModel?.removeLast()
                if deleteResult.shouldRestore {
                    tempDeletedCharacters.append(deleteResult.character)
                }
            }
            host.refreshSuggestions()
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playDeleteSound()
            return
        }

        guard !deletePanBoundaryState.isBlocked,
              KeyboardTextInteractionPolicy.shouldRequestDeletePanBoundary(
                hasText: host.textDocument.hasText,
                hasDeletedInCurrentPan: !tempDeletedCharacters.isEmpty,
                documentContextBeforeInput: deletePanTextModel?.remainingText,
                selectedText: host.textDocument.selectedText
              ) else { return }
        guard let generation = deleteInteractionCoordinator.beginPanBoundaryMutation(
            inputIdentifier: currentTextInputIdentifier
        ) else { return }
        deletePanBoundaryState.beginPending(generation: generation)

        // 입력창이 직전 편집을 반영할 시간을 준 뒤 앞 문맥을 본다
        let delay = KeyboardTextInteractionPolicy.deletePanBoundaryDelay(
            elapsedSinceLastEdit: CACurrentMediaTime() - lastDeletePanEditTime
        )
        guard delay > 0 else {
            evaluatePendingDeletePanBoundary(for: generation)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.evaluatePendingDeletePanBoundary(for: generation)
        }
    }

    /// 모델이 바닥난 뒤 입력창 앞 문맥을 보고 경계를 묻거나, 기다리거나, 모델을 다시 채웁니다.
    ///
    /// 경계 요청(`deleteBackward()`)을 보내기 전 단계라서 이 동안의 방향 전환·팬 종료는 바로 취소할 수 있습니다.
    func evaluatePendingDeletePanBoundary(for generation: DeleteInteractionGeneration) {
        guard let host,
              deletePanBoundaryState.isPending(generation: generation),
              deleteInteractionCoordinator.currentGeneration == generation,
              deleteInteractionCoordinator.isWaitingForResolution,
              !deleteMutationLifecycle.hasPanBoundaryRequest
        else { return }

        switch KeyboardTextInteractionPolicy.deletePanExhaustedContextAction(
            sourceText: deletePanTextModel?.sourceText ?? "",
            documentContextBeforeInput: host.textDocument.documentContextBeforeInput
        ) {
        case .requestBoundary:
            sendDeletePanBoundaryRequest(for: generation)
        case .awaitSync:
            waitForDeletePanBoundaryContextSync(for: generation)
        case .refill:
            // 모델이 잘려 있었으므로 보이는 앞 문맥으로 다시 채우고, 경계를 묻지 않은 채 이어서 지운다
            deletePanTextModel = DeletePanTextModel(beforeInput: host.textDocument.documentContextBeforeInput)
            finishPendingDeletePanBoundaryWithoutRequest(discardingLeadingNoOpPanLeft: false)
            performDeleteButtonPanDeleteIfPossible()
            drainPendingDeleteInteractionsIfPossible()
        }
    }

    func sendDeletePanBoundaryRequest(for generation: DeleteInteractionGeneration) {
        guard let host else { return }
        let timeoutID = deletePanBoundaryState.didSendRequest()
        guard deleteMutationLifecycle.beginPanBoundary(
            context: host.textDocument.contextSnapshot,
            selectedText: host.textDocument.selectedText
        ) == .started else {
            deleteMutationLifecycle.cancel()
            finishCancelledDeletePanIfNeeded(deleteInteractionCoordinator.cancel())
            return
        }

        lastDeletePanEditTime = CACurrentMediaTime()
        host.deleteText()
        scheduleDeletePanBoundaryTimeout(for: generation, timeoutID: timeoutID)
    }

    /// 입력창 문맥이 따라오기를 기다리고, 끝내 따라오지 않으면 경계를 넘지 않고 끝냅니다.
    func waitForDeletePanBoundaryContextSync(for generation: DeleteInteractionGeneration) {
        guard let waitID = deletePanBoundaryState.beginSyncWait() else { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + KeyboardTextInteractionPolicy.deletePanBoundaryTimeout
        ) { [weak self] in
            guard let self,
                  self.deletePanBoundaryState.isCurrentSyncWait(waitID),
                  self.deletePanBoundaryState.isPending(generation: generation),
                  self.deleteInteractionCoordinator.currentGeneration == generation,
                  self.deleteInteractionCoordinator.isWaitingForResolution,
                  !self.deleteMutationLifecycle.hasPanBoundaryRequest
            else { return }

            self.cancelPendingDeletePanBoundary()
        }
    }

    /// 경계 요청을 보내기 전 단계의 대기를 취소하고, 이번 드래그에서는 더 이상 경계를 넘지 않습니다.
    func cancelPendingDeletePanBoundary() {
        deletePanBoundaryState.cancelPending()
        resolvePendingDeleteInteractionsIfNeeded(discardingLeadingNoOpPanLeft: true)
        drainPendingDeleteInteractionsIfPossible()
    }

    func finishPendingDeletePanBoundaryWithoutRequest(discardingLeadingNoOpPanLeft: Bool) {
        deletePanBoundaryState.finishPendingWithoutRequest()
        resolvePendingDeleteInteractionsIfNeeded(
            discardingLeadingNoOpPanLeft: discardingLeadingNoOpPanLeft
        )
    }

    func resumePendingDeletePanBoundaryIfNeeded() {
        // 마지막 드래그 편집 뒤 조용한 시간이 지나기 전에는 예약된 판정에 맡긴다.
        // 그 사이 callback은 드래그 전 문맥을 담고 있을 수 있어 모델을 잘못 다시 채울 수 있다
        guard let generation = deletePanBoundaryState.pendingGeneration,
              KeyboardTextInteractionPolicy.deletePanBoundaryDelay(
                elapsedSinceLastEdit: CACurrentMediaTime() - lastDeletePanEditTime
              ) == 0
        else { return }
        evaluatePendingDeletePanBoundary(for: generation)
    }

    /// callback 없이 경계 요청이 끝나지 않으면 일정 시간 뒤 확정해 드래그가 멈추지 않게 합니다.
    func scheduleDeletePanBoundaryTimeout(
        for generation: DeleteInteractionGeneration,
        timeoutID: Int
    ) {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + KeyboardTextInteractionPolicy.deletePanBoundaryTimeout
        ) { [weak self] in
            guard let self,
                  let host = self.host,
                  self.deleteInteractionCoordinator.currentGeneration == generation,
                  self.deleteInteractionCoordinator.isWaitingForResolution,
                  self.deleteMutationLifecycle.hasPanBoundaryRequest,
                  // 입력창 확인 없이 확정하므로 이번 드래그에서는 더 이상 경계를 넘지 않는다
                  self.deletePanBoundaryState.requestDidTimeOut(timeoutID)
            else { return }

            self.processDeleteMutationResolution(
                self.deleteMutationLifecycle.completePanBoundaryAfterTimeout(
                    currentContext: host.textDocument.contextSnapshot,
                    currentSelectedText: host.textDocument.selectedText
                )
            )
        }
    }

    func performDeleteButtonPanRestoreIfPossible() {
        guard let host else { return }
        guard let lastDeleted = tempDeletedCharacters.popLast() else { return }

        prepareDeletePanTextModelIfNeeded()
        host.deleteButtonPanRestoreText(lastDeleted)
        deletePanTextModel?.append(lastDeleted)
        lastDeletePanEditTime = CACurrentMediaTime()
        host.refreshSuggestions()
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playDeleteSound()
    }
}
```

`DeletePanTextModel.removeLast()`가 `@discardableResult`가 아니면 VC와 같이 경고가 나지 않도록 원래 VC 코드와 동일하게 둔다(VC에서 경고 없이 컴파일되던 표현이다). `deletePanTextModel?.remainingText`·`sourceText`·`pendingGeneration`·`isBlocked`는 모두 기존 순수 타입의 멤버다.

- [x] **Step 4: pbxproj에 `TextDeletionCoordinator.swift` 등록**

Task 4 Step 4와 같은 두 자리에서 `SuggestionSelectionCoordinator.swift,` 줄 바로 뒤, `UndoRedoCoordinator.swift,` 줄 앞에 추가한다(알파벳 순 S < T < U).

```
				SYKeyboardCore/Presentation/ViewController/Utils/TextDeletionCoordinator.swift,
```

확인: `grep -c "Utils/TextDeletionCoordinator.swift" SYKeyboard.xcodeproj/project.pbxproj`가 2.

- [x] **Step 5: VC에서 삭제 섹션을 Coordinator 호출로 교체**

`BaseKeyboardViewController.swift`를 위에서 아래로 고친다.

(a) 상단 `import Combine`을 지운다(타이머가 유일한 Combine 사용처였다). 확인: `grep -n "AnyCancellable\|\.sink\|Publisher" …`가 비어 있음.

(b) Properties: 다음 저장 프로퍼티(각 문서 주석 포함)를 삭제한다. `timer`, `isRepeatingInput`, `repeatInputTickCount`, `deleteMutationLifecycle`, `deleteInteractionCoordinator`, `isDrainingPendingDeleteInteractions`, `currentTextInputIdentifier`, `tempDeletedCharacters`, `deletePanTextModel`, `lastDeletePanEditTime`, `deletePanBoundaryState`, `deletePanDeletedTextOverride`. `isRepeatingInput` 자리에는 계산 프로퍼티를 둔다.

```swift
    /// 현재 반복 입력 동작 중인지 확인하는 플래그
    public var isRepeatingInput: Bool { textDeletionCoordinator.isRepeatingInput }
```

`lastNotifiedTextInputIdentifier`, `isPrimaryCursorDragging`, `pendingCursorDragHapticContext`는 남긴다.

(c) UI Components: `deleteDragIndicatorView` 선언 뒤에 추가한다.

```swift
    /// 삭제 touchDown·반복·pan과 삭제 확정 파이프라인을 맡는다. `TextDeletionHost` 채택은 파일 끝의 extension에 있다
    private lazy var textDeletionCoordinator = TextDeletionCoordinator(
        deleteDragIndicatorView: deleteDragIndicatorView,
        suggestionController: suggestionController,
        keyboardSettingsManager: keyboardSettingsManager,
        host: self
    )
```

(d) `textWillChange`의 `withReadCaching` 본문:

```swift
            let inputIdentifier = textInputIdentifier(for: textInput)
            if let inputIdentifier,
               inputIdentifier != lastNotifiedTextInputIdentifier {
                lastNotifiedTextInputIdentifier = inputIdentifier
                textInputDidChange(textInput)
            }
            suggestionSelectionCoordinator.synchronizeTextInputTraits()
            textDeletionCoordinator.synchronizeInputIdentifier(inputIdentifier)
            undoRedoCoordinator.prepareForTextWillChange(inputIdentifier: inputIdentifier)
            suggestionSelectionCoordinator.captureSentTextSnapshot()
```

(이하 `resetInputBuffer()`부터 그대로.)

(e) `textDidChange`의 `withReadCaching` 본문 앞부분:

```swift
            suggestionSelectionCoordinator.synchronizeTextInputTraits()
            let inputIdentifier = textInputIdentifier(for: textInput)
            textDeletionCoordinator.synchronizeInputIdentifier(inputIdentifier)
            // `textWillChange`에서 떠 둔 스냅샷과 지금 문맥을 비교해 전송으로 비워졌으면 기록한다
            suggestionSelectionCoordinator.recordSentTextIfNeeded()
            let currentTextContext = textDocument.contextSnapshot
            if KeyboardGesturePolicy.shouldPlayCursorDragHapticOnTextDidChange(
                isPrimaryCursorDragging: isPrimaryCursorDragging,
                pendingRequestContext: pendingCursorDragHapticContext,
                currentContext: currentTextContext
            ) {
                FeedbackManager.shared.playHaptic(isForcing: true)
            }
            pendingCursorDragHapticContext = nil
            textDeletionCoordinator.completeAfterTextChange(currentContext: currentTextContext)
            undoRedoCoordinator.invalidateHistoryIfNeededAfterTextChange(inputIdentifier: inputIdentifier)
            updateKeyboardType()
```

(이하 trait 비교부터 그대로.)

(f) `viewWillDisappear`:

```swift
        textDeletionCoordinator.stopRepeatInputTracking()
        clipboardHistoryCoordinator.closePanelIfNeeded()
        suggestionSelectionCoordinator.hideSuggestionRemovalConfirmation()
        textDeletionCoordinator.resetInputIdentifier()
        lastNotifiedTextInputIdentifier = nil
        undoRedoCoordinator.removeAllHistory()
```

(g) Overridable Methods:
- `textInteractionWillPerform`: 끝의 `tempDeletedCharacters.removeAll()` / `resetDeletePanTextModel()` 두 줄 → `textDeletionCoordinator.clearPanRestoreState()`.
- `repeatTextInteractionWillPerform`: `cancelTimer()` / `isRepeatingInput = true` 두 줄(주석 "방어 코드" 포함) → `textDeletionCoordinator.beginRepeatInput()`.
- `repeatTextInteractionDidPerform` 전체 본문:

```swift
        let isDeleteButton: Bool
        if case .deleteButton = button.type {
            isDeleteButton = true
        } else {
            isDeleteButton = false
        }
        textDeletionCoordinator.endRepeatInput(isDeleteButton: isDeleteButton)

        updateReturnButtonEnabled()
        updateSuggestions()
```

- `deleteButtonPanPreviousCharacter`: `return deletePanTextModel?.lastCharacter` → `return textDeletionCoordinator.panPreviousCharacter`.

(h) Text Proxy Wrapper `deleteText()`:

```swift
        let wasSpaceAtEnd = inputBuffer.last?.isWhitespace == true
        let selectedText = textDocument.selectedText
        let panDeletedTextOverride = textDeletionCoordinator.takePanDeletedTextOverride()
        // 선택 영역을 지우는 경우에는 모델 글자 대신 선택 영역을 기록한다
        let panDeletedText = (selectedText ?? "").isEmpty ? panDeletedTextOverride : nil
        let deletedText = panDeletedText
            ?? KeyboardTextInteractionPolicy.deletedTextForSingleBackward(
                selectedText: selectedText,
                documentContextBeforeInput: textDocument.documentContextBeforeInput
            )

        textDocument.deleteBackward()
```

(`deletePanDeletedTextOverride = nil` 줄은 지운다. 이하 그대로.)

- `stopInputInteractionsForLanguageChange`: `stopRepeatInputTracking()` → `textDeletionCoordinator.stopRepeatInputTracking()`.

(i) Button Action `makeDeleteButtonReleaseAction`:

```swift
    func makeDeleteButtonReleaseAction() -> UIAction {
        return UIAction { [weak self] _ in
            self?.textDeletionCoordinator.finishTouchDown()
        }
    }
```

(j) Text Interaction Methods:

```swift
        if case .deleteButton = button.type {
            textDeletionCoordinator.performTouchDown(for: button)
            return
        } else {
            textDeletionCoordinator.cancelPendingInteractions()
        }
```

(`performTextInteraction` 안. `insertSecondaryKeyIfAvailable` 분기 이하 그대로.)

```swift
        if case .deleteButton = button.type {
            textDeletionCoordinator.performRepeatTick(for: button)
            return
        }

        textDeletionCoordinator.cancelPendingInteractions()
```

(`performRepeatTextInteraction` 안.)

```swift
    final public func performInitialRepeatDeleteTextInteraction(for button: TextInteractable) {
        guard self.view.window != nil else { return }

        textDeletionCoordinator.performInitialRepeatDelete(for: button)
    }
```

(k) Private Methods: `performDeleteTextInteractionWithSemanticHooks`, `performRepeatDeleteTextInteraction`, `beginDeleteTouchDownRequest`, `beginRepeatDeleteRequest`, `performDeleteButtonTextInteraction`, `processDeleteMutationResolution`, `resumeDeletePanAfterSettling`, `processDeleteMutationCallbackOutcome`, `resolvePendingDeleteInteractionsIfNeeded`, `completeRepeatDeleteAtCurrentContext`, `cancelTimer`, `stopRepeatInputTracking`, `finishRepeatDeleteWithoutDeletion`을 삭제한다. `recordUndoRedoChange`는 최종 형태가 된다.

```swift
    /// 래퍼가 수행한 편집을 기록한다. 삭제 파이프라인이 먼저 capture를 시도하고, 삭제 요청 중이 아니면 undo에 기록한다
    func recordUndoRedoChange(
        deletedText: String,
        insertedText: String,
        reliability: RepeatDeleteMutationReliability = .authoritative
    ) {
        if textDeletionCoordinator.captureMutation(
            deletedText: deletedText,
            insertedText: insertedText,
            reliability: reliability
        ) { return }
        undoRedoCoordinator.record(deletedText: deletedText, insertedText: insertedText)
    }
```

`currentTextContextSnapshot()`은 남은 호출처가 없으면 삭제한다(`grep -n currentTextContextSnapshot`로 확인).

(l) TextInteractionGestureControllerDelegate:

```swift
    final func deleteButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection) {
        textDeletionCoordinator.handlePan(to: direction)
    }

    final func deleteButtonPanStopped(_ controller: TextInteractionGestureController) {
        textDeletionCoordinator.handlePanStop()
    }
```

`textInteractableButtonLongPressing`의 `startRepeatInputTimer(for: button)` → `textDeletionCoordinator.startRepeatInputTimer(for: button)`.

보조 private extension에서 `showDeleteDragOverlays`, `hideDeleteDragOverlays`, `cancelPendingDeleteInteractions`, `drainPendingDeleteInteractionsIfPossible`, `synchronizeDeleteInteractionInputIdentifier`, `finishCancelledDeletePanIfNeeded`, `performDeleteButtonPanInteraction`, `performDeleteButtonPanIfLifecycleReady`, `prepareDeletePanTextModelIfNeeded`, `resetDeletePanTextModel`, `scheduleReleasedPanBoundaryCheckpoint`, `finishDeleteButtonPanTracking`, `performDeleteButtonPanDeleteIfPossible`, `evaluatePendingDeletePanBoundary`, `sendDeletePanBoundaryRequest`, `waitForDeletePanBoundaryContextSync`, `cancelPendingDeletePanBoundary`, `finishPendingDeletePanBoundaryWithoutRequest`, `resumePendingDeletePanBoundaryIfNeeded`, `scheduleDeletePanBoundaryTimeout`, `performDeleteButtonPanRestoreIfPossible`, `startRepeatInputTimer`를 삭제한다. `showCursorDragOverlays`, `hideCursorDragOverlays`, `moveCursorIfPossible`, `performNumberInputLongPress`, `markSymbolInputAfterLongPressIfNeeded`, `switchToPrimaryAfterApostropheLongPressIfNeeded`는 남긴다.

(m) Host 채택: `ClipboardHistoryHost` extension의 `func interruptPendingDeleteInteractions() { cancelPendingDeleteInteractions() }` → `{ textDeletionCoordinator.cancelPendingInteractions() }`. 파일 끝(`UndoRedoHost` extension 앞)에 추가한다.

```swift
// MARK: - TextDeletionHost

extension BaseKeyboardViewController: TextDeletionHost {
    func performDeleteTextInteraction(for button: TextInteractable) { performTextInteraction(for: button) }

    func recordEditForUndo(deletedText: String, insertedText: String) {
        recordUndoRedoChange(deletedText: deletedText, insertedText: insertedText)
    }
}
```

(n) 확인:

```sh
F=Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
grep -nE "deleteMutationLifecycle|deleteInteractionCoordinator|tempDeletedCharacters|deletePan|repeatInputTickCount|isDrainingPending|currentTextInputIdentifier|cancelPendingDeleteInteractions|stopRepeatInputTracking\(|startRepeatInputTimer|cancelTimer|timer\b" $F
```

결과는 `textDeletionCoordinator.…` 호출 줄뿐이어야 한다. `wc -l $F`는 1900 아래여야 한다.

- [x] **Step 6: 테스트 통과 확인**

"SYKeyboardTests 전체 실행, 약 3\~5분"이라고 알린 뒤 실행한다.

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  > "$S/task5-test.log" 2>&1; grep -E "Executed|failed|error:" "$S/task5-test.log" | tail -n 8
```

Expected: 0 failures. Task 1 테스트가 수정 없이 통과한다. 틱 읽기 횟수가 달라졌다면 `performRepeatDeleteTextInteraction`의 `startState` 재사용이나 `completeAfterTextChange(currentContext:)`에 스냅샷을 넘기는 자리가 어긋난 것이다. Coordinator 쪽을 고치고 테스트 기대값은 바꾸지 않는다.

- [x] **Step 7: 커밋**

```sh
git branch --show-current
git add Modules/SYKeyboardCore/Presentation/ViewController/Utils/TextDeletionCoordinator.swift \
  Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift \
  SYKeyboard.xcodeproj/project.pbxproj \
  SYKeyboardTests/Utils/TextDeletionCoordinatorTests.swift \
  SYKeyboardTests/Utils/FakeSuggestionService.swift
git commit -m "$(cat <<'EOF'
refactor: #185 - 삭제 드래그·반복 삭제·삭제 확정 접착 코드를 TextDeletionCoordinator로 분리

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

#### Task 5 결과 (2026-10-09)

- Step 2 RED: `cannot find type 'TextDeletionHost'`. Step 5 (k)에서 `moveCursorIfPossible`의 `currentTextContextSnapshot()` 호출이 하나 남아 `textDocument.contextSnapshot`으로 바꿨다(계획의 "남은 호출처가 없으면 삭제" 조건을 이 호출처만 고치고 적용). Step 6: 전체 1056개 통과, 0 failures, 소스 파일 경고 0건(`scratchpad/task5-test.log`). VC 고정 테스트 11개 수정 없이 통과. VC 2579 → 1931줄, `TextDeletionCoordinator.swift` 854줄.

---

### Task 6: 전체 검증

**Files:**
- Modify: 이 계획 문서(결과 기록). 코드 변경 없음(검증 중 발견한 문제는 원인 Task로 돌아가 고치고 `fix: #185 - …`로 따로 커밋한다)

- [x] **Step 1: 전체 테스트**

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard \
  -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
  > "$S/task6-test.log" 2>&1; grep -E "Executed [0-9]+ tests|Test Suite 'All tests'|failed" "$S/task6-test.log" | tail -n 5
```

Expected: `** TEST SUCCEEDED **`, 0 failures. 개수는 기준 1020 + Task 1(11) + Task 2(1) + Task 3(2) + Task 4(10) + Task 5(12) = 1056 이상. 실제 값을 이 Step 아래에 적는다.

- [x] **Step 2: 4개 scheme 빌드**

```sh
S=/private/tmp/claude-501/-Users-macmillan-Projects-XcodeProjects-SNMac-SYKeyboard-SYKeyboard/d55fb879-2fd6-4e31-bf24-9aa46889bd80/scratchpad
for scheme in SYKeyboard HangeulKeyboard EnglishKeyboard HangeulEnglishKeyboard; do
  xcodebuild build -project SYKeyboard.xcodeproj -scheme "$scheme" \
    -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6' \
    > "$S/task6-build-$scheme.log" 2>&1; echo "$scheme: $(grep -E '\*\* BUILD (SUCCEEDED|FAILED) \*\*' "$S/task6-build-$scheme.log") warnings=$(grep -c 'warning:' "$S/task6-build-$scheme.log")"
done
git status --short
```

Expected: 4개 모두 `** BUILD SUCCEEDED **`. `.xcscheme`이 보이면 `RemotePath`만 바뀐 경우 되돌린다.

- [x] **Step 3: 정적 확인**

```sh
F=Modules/SYKeyboardCore/Presentation/ViewController/Bases/BaseKeyboardViewController.swift
echo "--- textDocumentProxy 직접 참조 (1줄이어야 함) ---"
grep -rn "textDocumentProxy" Modules Keyboards | grep -v -E ":[0-9]+:[[:space:]]*//"
echo "--- VC 줄 수 ---"; wc -l $F
echo "--- 접근 수식어 없는 저장 프로퍼티 수 (기준 f14e15e0: 5) ---"
echo "기준:"; git show f14e15e0:$F | sed -n "15,$(git show f14e15e0:$F | grep -n '// MARK: - Initializer' | cut -d: -f1)p" | grep -E "^\s+(final )?(lazy )?(var|let) " | grep -vcE "^\s+(final )?(lazy )?(var|let) (isRepeatingInput|previewOneHandedMode)"
echo "현재:"; sed -n "15,$(grep -n '// MARK: - Initializer' $F | cut -d: -f1)p" $F | grep -cE "^\s+(final )?(lazy )?(var|let) "
echo "--- Coordinator 4개는 private lazy인지 ---"
grep -nE "lazy var (suggestionSelectionCoordinator|clipboardHistoryCoordinator|textDeletionCoordinator|undoRedoCoordinator)" $F
echo "--- unowned 금지, host는 weak ---"
grep -n "unowned\|weak var host" Modules/SYKeyboardCore/Presentation/ViewController/Utils/*Coordinator.swift
```

Expected: 첫 grep은 `return self.textDocumentProxy` 한 줄. 줄 수 1900 아래(실측값 기록). 접근 수식어 없는 저장 프로퍼티 수가 기준과 같음. Coordinator 4개가 `private lazy var`. `unowned` 없음, `weak var host` 4개.

- [x] **Step 4: 시뮬레이터 기능 확인**

`iPhone 13 mini / iOS 18.6`(UDID `82146144-24DE-4F91-B25D-23D147A91142`)에서 작업자가 직접 한다. 메모리 `reference-idb-simulator-quirks`의 방법을 따른다.

준비:
1. `xcrun simctl boot 82146144-24DE-4F91-B25D-23D147A91142`, `open -a Simulator`.
2. `HangeulKeyboard` scheme 빌드 결과(Step 2의 DerivedData, `SYKeyboard.app`)를 `xcrun simctl install`로 설치. App Group plist에서 `isClipboardHistoryEnabled`를 꺼 붙여넣기 알림을 피하고, `selectedHangeulKeyboard`를 2(두벌식)로 둔다. `AppleKeyboards` 배열 맨 앞에 우리 한글 키보드 식별자를 둔다(끝나면 복원).
3. scratchpad에 여러 줄 `textarea`와 선택 버튼이 있는 HTML을 두고 `python3 -m http.server 8765 --bind 127.0.0.1`로 띄운 뒤 `xcrun simctl openurl … http://127.0.0.1:8765/delete.html`로 연다. HTML의 버튼은 `textarea.setSelectionRange(start, end)`를 호출해 선택 영역을 만든다(idb 탭으로 누를 수 있어야 하므로 큰 `<button>`).
4. `xcrun simctl spawn <UDID> log stream --level debug --predicate 'subsystem == "<HangeulKeyboard 번들 ID>"' > "$S/task6-sim.log" 2>&1 &`로 로그를 받는다(번들 ID는 `Keyboards/HangeulKeyboard`의 Info.plist·xcconfig에서 확인).

확인 항목. 각 항목의 결과를 이 Step 아래에 `- [x] 항목 — 결과`로 적는다. 키 좌표는 캡처(`idb screenshot`)에서 읽는다(1080x2340px, 포인트 = px × 0.3472).

- 삭제 드래그: "안녕하세요" 입력 뒤 삭제 키를 길게 누른 채 왼쪽으로 끌어 글자가 지워지고 인디케이터가 뜨는지, 오른쪽으로 끌어 되살아나는지(`idb ui swipe`로 삭제 키에서 좌·우로 끌기, 안 되면 `idb ui tap --duration`과 좌표 이동 조합).
- 줄 경계: 두 줄 입력("가나" 리턴 "다") 뒤 둘째 줄을 드래그로 다 지우고 계속 끌면 줄바꿈을 넘어 첫 줄이 지워지는지, 오른쪽 복구가 줄바꿈까지 되살리는지.
- 선택 영역: HTML 선택 버튼으로 "녕하"를 선택한 뒤 드래그 삭제 → 선택만 지워지고, undo 버튼으로 "녕하"가 돌아오는지.
- 반복 삭제: 한글 조합 중("안ㄴ") 삭제 키 길게 누르기 → 조합부터 글자 단위로 이어서 지워지고 손을 떼면 멈추는지.
- undo/redo: "ㅋㅌ" 입력 뒤 undo → 비워지고 redo → 돌아오는지.
- 삭제 중 필드 전환: 드래그 삭제 중 다른 입력창(HTML에 두 번째 textarea)을 탭 → 첫 입력창이 더 지워지지 않고 키보드가 새 입력창에서 정상 동작하는지.
- 첨부 토큰 앞 멈춤: 메시지 앱 더미 대화에서 사진 첨부가 되면 첨부 뒤에 글자를 쓰고 드래그 삭제가 첨부 앞에서 멈추는지. 첨부를 못 하면 "실기기 확인 필요"로 남긴다.

시뮬레이터로 확인할 수 없는 항목(PR 본문 "실기기 확인 필요"): 햅틱·삭제 사운드.

- [x] **Step 5: 시뮬레이터 해제·누수 확인**

1. 키보드를 띄웠다 내리기를 5회 반복한다(입력창 탭 → 하드웨어 Return `idb ui key 40` 또는 다른 앱 전환). 로그 파일에서 `deinit` 줄을 센다.

```sh
grep -cE "BaseKeyboardViewController deinit|HangeulKeyboardViewController deinit" "$S/task6-sim.log"
grep -oE "(TextDeletionCoordinator|UndoRedoCoordinator|SuggestionSelectionCoordinator|ClipboardHistoryCoordinator) deinit" "$S/task6-sim.log" | sort | uniq -c
```

Expected: VC `deinit`이 내린 횟수만큼, 네 Coordinator `deinit`이 각각 같은 횟수.

2. 키보드를 내린 직후 extension 프로세스가 남아 있는 동안 `leaks`를 돌린다.

```sh
PID=$(pgrep -f "HangeulKeyboard.appex" | head -n 1); echo "pid=$PID"
leaks "$PID" > "$S/task6-leaks.txt" 2>&1; grep -E "leaks for|Process .* leaks" "$S/task6-leaks.txt"
```

Expected: `0 leaks for 0 total leaked bytes`. 프로세스가 이미 종료돼 잡히지 않으면 키보드를 띄운 상태에서(삭제 드래그·undo를 한 번 수행한 뒤) 실행하고 그 사실을 기록한다. `leaks`가 실행되지 않으면(권한 등) 이유를 기록하고 1의 `deinit` 로그를 근거로 삼는다.

3. 끝나면 `AppleKeyboards` 배열과 App Group 설정을 원래대로 되돌리고 로그 프로세스를 종료한다.

- [x] **Step 6: 결과 기록 커밋**

이 계획 문서의 Task 6 각 Step 아래에 실제 명령 결과(테스트 개수, 빌드 결과, 줄 수, 시뮬레이터 항목별 결과, `deinit` 횟수, `leaks` 결과, 미확인 항목과 이유)를 적고 커밋한다.

```sh
git branch --show-current
git add docs/superpowers/plans/2026-10-08-base-keyboard-view-controller-delete-undo-coordinator-extraction.md
git commit -m "$(cat <<'EOF'
docs: #185 - 삭제·undo/redo Coordinator 추출 검증 결과 기록

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

#### Task 6 결과 (2026-10-09, 브랜치 `refactor/#185-extract-delete-undo-coordinators` @ 54961918)

- Step 1 전체 테스트: `xcodebuild test -project SYKeyboard.xcodeproj -scheme SYKeyboard -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=18.6'` → `** TEST SUCCEEDED **`, 1056 passed, 0 failed(기준 1020 + 36). 로그 `scratchpad/task6-test.log`(Task 5 task-done 실행과 동일 명령).
- Step 2 빌드: SYKeyboard·HangeulKeyboard·EnglishKeyboard·HangeulEnglishKeyboard 모두 `** BUILD SUCCEEDED **`, 소스 파일 경고 0건. 빌드 뒤 `git status --short` 비어 있음(`.xcscheme` 변경 없음).
- Step 3 정적 확인: `textDocumentProxy` 직접 참조는 `BaseKeyboardViewController.swift:58 return self.textDocumentProxy` 한 줄. VC 2721 → **1931줄**. 접근 수식어 없는 저장 프로퍼티 수 기준 5 → 현재 5(목록 동일). Coordinator 4개 모두 `private lazy var`. `unowned` 없음, `weak var host` 4개.
- Step 4 시뮬레이터(iPhone 13 mini / iOS 18.6, Safari의 로컬 http `delete.html` textarea, idb 조작). **떠 있던 키보드는 `HangeulKeyboard`가 아니라 한영 통합 키보드(`HangeulEnglishKeyboard`)의 한글(두벌식) 모드였다**(`AppleKeyboards` 맨 앞에 HangeulKeyboard를 뒀지만 Safari가 마지막 사용 키보드를 유지). 삭제·undo 코드는 Base와 Coordinator에 있어 검증 대상은 같고, 한영 통합 VC의 `deleteButtonPan*`·`repeatDeleteBackward` 오버라이드까지 거쳤다. 캡처 `scratchpad/shot-*.png`, `crop-*.png`.
  - [x] 삭제 드래그(왼쪽) — "안녕하세요" 입력 뒤 삭제 키에서 왼쪽으로 끌자 전부 지워짐(`shot-03`→`shot-04`). undo 버튼 활성.
  - [x] undo/redo — undo 탭 → "안녕하세요" 복원, redo 탭 → 다시 비워짐(`crop-05`, `crop-06`).
  - [x] 줄 경계 — "ㄱ나⏎다"에서 짧은 드래그는 "다"만 지우고 줄 경계에서 멈춤(`crop-09`→`crop-10`). 빈 둘째 줄에서 더 길게 끌자 줄바꿈을 넘어 첫 줄까지 지워지고(`crop-11`), undo로 줄바꿈과 "ㄱ나"가 복원(`crop-12`).
  - [x] 선택 영역 — JS로 끝 2자 "녕하"를 선택한 뒤 삭제 키 드래그 → 선택이 지워지고 이어진 드래그가 나머지도 지움(`crop-13`→`crop-14`), undo 한 번으로 선택 텍스트까지 전부 복원(`crop-15`). 드래그는 touchDown에서 선택을 먼저 지우므로 "선택만 드래그로 지우는" 단계는 단위 테스트(`testDeletePanDeletesSelectionAndUndoRestoresIt`, `testPanWithSelectionDoesNotTrackStep`)로 본다.
  - [x] 반복 삭제 — 조합 중("…안ㄴ") 삭제 키 0.9초 누름 → 조합부터 이어서 지워짐(`crop-16`→`crop-17`). ㅏ 14개에서 0.8초 누름 → 6개 남음, 손을 떼면 멈춤(`crop-18`).
  - [ ] 삭제 드래그 오른쪽 복구 — idb `ui swipe`는 직선 한 구간이라 한 제스처 안에서 방향을 바꿀 수 없어 시뮬레이터로 재현하지 못함. `testDeletePanDeleteRestoreStop`(VC)·`testPanDeleteRestoreStop`(Coordinator)이 고정. **실기기 확인 필요**.
  - [ ] 삭제 드래그 중 다른 입력창 탭 — idb로 제스처를 겹칠 수 없어 재현하지 못함. `testTextInputChangeCancelsPendingPan`(VC)·`testInputChangeCancelsPendingPan`(Coordinator)이 고정. **실기기 확인 필요**.
  - [ ] 첨부(U+FFFC) 앞 멈춤 — 메시지 앱 첨부를 시도하지 않음(웹 입력창에는 첨부가 없음). `testDeletePanStopsBeforeAttachment`·`testPanStopsBeforeAttachment`가 고정. **실기기 확인 필요**.
  - 햅틱·삭제 사운드 — 시뮬레이터로 관찰 불가. **실기기 확인 필요**.
- Step 5 해제·누수:
  - `xcrun simctl spawn <UDID> log stream --level debug --predicate 'subsystem == "github.com-SNMac.SYKeyboard.HangeulEnglishKeyboard" AND eventMessage CONTAINS "deinit"'`로 받으며 Done → 입력창 탭을 5회 반복: `HangeulEnglishKeyboardViewController` 5, `TextDeletionCoordinator` 5, `UndoRedoCoordinator` 5, `SuggestionSelectionCoordinator` 5, `ClipboardHistoryCoordinator` 5(`TextInteractionGestureController`·`SwitchGestureController`도 5). 로그 `scratchpad/task6-sim.log`. `log show`는 debug 레벨을 저장하지 않아 쓰지 못했고 live stream만 유효했다.
  - `leaks <pid>`: `Failed to get DYLD info for task … (os/kern) failure (5)`로 실행 불가. `xctrace record --template Leaks --device <UDID> --attach HangeulEnglishKeyboard`: `Failed to generate memory graph … libmalloc hasn't been initialized`로 실패(`task6-xctrace.log`). 시뮬레이터 extension 프로세스에는 두 도구 모두 붙지 않아 **누수 0건 확인은 하지 못했고**, 위 `deinit` 일치(5/5)를 근거로 삼는다.
  - 끝난 뒤 `AppleKeyboards` 원래 배열로 복원, App Group `isClipboardHistoryEnabled`는 true로 되돌림(확인 전 원래 값을 읽지 않고 false로 썼으므로 원래 값이 true였다는 가정. 사용자 시뮬레이터 설정과 다르면 메인 앱에서 다시 켜거나 끈다).

---

### Task 7: 문서 갱신

**Files:**
- Modify: `CLAUDE.md`, `README.md`, `docs/architecture/README.md`, `docs/architecture/전체 아키텍처.md`, `docs/architecture/삭제와 실행취소 로직.md`, `docs/architecture/성능 고려 사항.md`, `docs/architecture/자동완성 로직.md`, `docs/architecture/한영 통합 키보드.md`, `docs/architecture/한글 입력 로직.md`

사실과 다른 문장을 고치는 것이 목적이다. 설계 배경을 길게 쓰지 않는다. **각 파일을 먼저 전부 읽고** 아래 지점과, 읽으며 발견한 다른 불일치를 고친다. 아래 줄 번호는 기준 커밋 기준이라 어긋날 수 있다.

- [x] **Step 1: `CLAUDE.md`**

아키텍처 절 트리의 `BaseKeyboardViewController          (SYKeyboardCore, ~2700줄, 입력 흐름의 중심)`의 줄 수를 Task 6 Step 3 실측값(백 단위 반올림)으로. 그 아래 "후보 탭 처리·전송 기록·후보 삭제 확인은 `SuggestionSelectionCoordinator`, 클립보드 패널·pasteboard 동기화는 `ClipboardHistoryCoordinator`가 맡는다. 둘은 …" 문단을 다음으로 바꾼다.

```
후보 탭 처리·전송 기록·후보 삭제 확인은 `SuggestionSelectionCoordinator`, 클립보드 패널·pasteboard 동기화는
`ClipboardHistoryCoordinator`, 삭제 touchDown·반복 삭제·삭제 드래그·삭제 확정 파이프라인은 `TextDeletionCoordinator`,
undo/redo 기록·확정·적용은 `UndoRedoCoordinator`가 맡는다. 넷은 VC 계층 보조 타입이라 `Presentation/ViewController/Utils/`에 있고
VC를 `weak` Host 프로토콜(`SuggestionSelectionHost`, `ClipboardHistoryHost`, `TextDeletionHost`, `UndoRedoHost`)로 역참조하며,
프록시는 Host가 노출하는 `textDocument`만 쓴다. 삭제 파이프라인의 프록시 쓰기는 VC의 `open` 메서드(`deleteText`,
`deleteButtonPanDeleteText` 등)를 거치므로 하위 VC 오버라이드가 그대로 불린다.
```

"텍스트 프록시는 `textDocument`(`CachingTextDocumentProxy`)로만 읽고 쓴다" 문단에 "앞·뒤 문맥 스냅샷은 `textDocument.contextSnapshot`으로 읽는다" 한 문장을 덧붙인다.

- [x] **Step 2: `docs/architecture/삭제와 실행취소 로직.md`**

- §1 "관련 타입은 모두 … 있고, Base VC가 두 인스턴스를 보유한다" 문단과 다이어그램을 `TextDeletionCoordinator`가 보유하고 VC가 `textDeletionCoordinator`를 소유하는 구조로 바꾼다. 다이어그램:

```
BaseKeyboardViewController
└── textDeletionCoordinator: TextDeletionCoordinator   ← 삭제 접착 코드(touchDown·반복·pan·drain·타이머), VC를 TextDeletionHost로 역참조
    ├── deleteMutationLifecycle: DeleteMutationLifecycle      ← 요청 1건의 수명주기 (시작→캡처→확정)
    └── deleteInteractionCoordinator: DeleteInteractionCoordinator ← 요청 여러 건의 FIFO 직렬화 (generation 단위)
```

- §2-3 표의 "VC 처리" 열 제목을 "Coordinator 처리"로, `cancelPendingDeleteInteractions()` → `cancelPendingInteractions()`.
- §2-4 제목 `processDeleteMutationResolution`은 그대로(이름 유지). 본문의 "VC는 그 값대로 적용만 한다" → "Coordinator는 그 값대로 적용만 하고, undo 기록은 `host.recordEditForUndo` → VC `recordUndoRedoChange` → `UndoRedoCoordinator.record`로 간다".
- §3 "삭제가 아닌 다른 입력이 시작되면 `cancelPendingDeleteInteractions()`로" → "`TextDeletionCoordinator.cancelPendingInteractions()`로". "undo/redo 적용(`performUndo`/`performRedo`)" → "undo/redo 적용(`UndoRedoCoordinator.undo`/`redo` → `host.interruptPendingDeleteInteractions()`)". `synchronizeDeleteInteractionInputIdentifier` → `TextDeletionCoordinator.synchronizeInputIdentifier`.
- §4-1 흐름의 `performTextInteraction(.deleteButton)` 아래에 "→ `TextDeletionCoordinator.performTouchDown`" 한 줄, `touchUp → lifecycle.finishTouchDown` → "`TextDeletionCoordinator.finishTouchDown`". §4-2 `performRepeatDeleteTextInteraction` 앞에 "`TextDeletionCoordinator.performRepeatTick` →". "VC" 주어가 있는 문장은 "Coordinator"로. 반복 종료 부분 `stopRepeatInputTracking(preservingTouchDown:)` → `endRepeatInput(isDeleteButton:)`.
- §4-3 `deleteButtonPanning(to:)` 뒤에 "→ `TextDeletionCoordinator.handlePan`", `deleteButtonPanStopped` → "`handlePanStop`". "지울 글자와 undo 기록 글자는 … 모델(deleteButtonPanPreviousCharacter)에서 정한다" 뒤에 "VC의 `deleteText()`는 `takePanDeletedTextOverride()`로 받는다"를 붙인다.
- §5 다이어그램 `KeyboardUndoRedoSession ← VC가 보유` → `← UndoRedoCoordinator가 보유(VC는 undoRedoCoordinator를 소유하고 UndoRedoHost로 역참조된다)`. §5-1 `updateUndoRedoControls()` → `UndoRedoCoordinator.refreshControls()`. §5-2 "모든 래핑 메서드가 `recordUndoRedoChange`를 호출한다 … 이 함수는 먼저 삭제 확정 파이프라인에 캡처를 시도하고(§2), 삭제 요청 중이 아니면 undo 세션에 기록한다" → "… VC의 `recordUndoRedoChange`는 `TextDeletionCoordinator.captureMutation`이 `false`일 때만 `UndoRedoCoordinator.record`를 부른다". §5-4 `performUndo/performRedo` → `UndoRedoCoordinator.undo/redo`, "6. undoRedoEditDidApply()" 앞에 "host.".
- §6 테스트 표에 `TextDeletionCoordinatorTests`, `UndoRedoCoordinatorTests`, `BaseKeyboardViewControllerDeleteUndoBehaviorTests` 행과 `-only-testing` 줄을 추가한다.

- [x] **Step 3: `docs/architecture/전체 아키텍처.md`**

- 약 64줄 "**undo/redo**: `KeyboardUndoRedoSession` 보유, …(버튼 탭은 Coordinator가 받아 Host로 전달)" → "**undo/redo**: `UndoRedoCoordinator`(`ViewController/Utils/`)가 `KeyboardUndoRedoSession`을 보유하고 기록·확정·적용·컨트롤 갱신을 맡는다. 버튼 탭은 `SuggestionSelectionCoordinator`가 받아 `host.undoLastEdit` → VC → `UndoRedoCoordinator.undo`로 전달".
- 약 68줄 "**삭제 파이프라인**: `DeleteMutationLifecycle` + `DeleteInteractionCoordinator`로 …" → "**삭제 파이프라인**: `TextDeletionCoordinator`(`ViewController/Utils/`)가 `DeleteMutationLifecycle` + `DeleteInteractionCoordinator`를 보유하고 touchDown·반복·드래그 삭제를 실제 텍스트 변경 확인 후 확정. 프록시 쓰기는 VC의 `open` 메서드를 거친다".
- 약 67줄 "두 Coordinator는 VC를 `weak`로 역참조하고" → "네 Coordinator는 …".
- 버튼 이벤트 표: `touchDown`(삭제 버튼) 행의 `DeleteMutationLifecycle.finishTouchDown` → `TextDeletionCoordinator.finishTouchDown`; 팬 제스처 행 끝에 "(`TextDeletionCoordinator.handlePan`)"; 반복 타이머 행 "`Timer.publish(…)`. 텍스트 필드가 바뀌거나 window에서 분리되면 자동 중단" 앞에 "`TextDeletionCoordinator`가 소유. ".
- 라이프사이클 표: `textWillChange` 행의 "undo/redo 준비" → "undo/redo 준비(`UndoRedoCoordinator.prepareForTextWillChange`)"; `textDidChange` 행의 "**삭제 확정 파이프라인 완료 처리**" → "**삭제 확정 파이프라인 완료 처리**(`TextDeletionCoordinator.completeAfterTextChange`)", 이어지는 undo 무효화 언급이 있으면 `UndoRedoCoordinator.invalidateHistoryIfNeededAfterTextChange`; `viewWillDisappear` 행 "반복 입력 중단, …, undo 이력 제거" → "반복 입력 중단(`TextDeletionCoordinator.stopRepeatInputTracking`), …, undo 이력 제거(`UndoRedoCoordinator.removeAllHistory`)".
- 약 209줄 Coordinator 목록 "`SuggestionSelectionCoordinator`/`ClipboardHistoryCoordinator`(ViewController/Utils/, …)"에 `TextDeletionCoordinator`/`UndoRedoCoordinator`를 추가한다.

- [x] **Step 4: `docs/architecture/성능 고려 사항.md`**

§2-4 표에서 "반복 삭제 tick에서 프록시 문맥·선택 텍스트는 한 번만 읽고 …" 행의 위치 열과 "삭제 드래그 가장자리 반복은 50ms 하한 …" 행의 위치 열에 `BaseKeyboardViewController`가 있으면 `TextDeletionCoordinator`로. `handlePeriodShortcutOnDelete()` 행은 VC에 남으므로 그대로. 테스트 표(약 464줄 이후)에 "삭제·undo 접착 코드의 Host 호출 순서 | `TextDeletionCoordinatorTests`, `UndoRedoCoordinatorTests`" 행을 추가한다. 4절 체크리스트(약 444줄)에 "삭제 확정 파이프라인, 반복 타이머, 삭제 드래그 가장자리·경계 대기 | …" 행이 문서 절만 가리키면 그대로 둔다.

- [x] **Step 5: `docs/architecture/자동완성 로직.md`, `한영 통합 키보드.md`**

- 자동완성 §1 다이어그램 약 26줄 "undo/redo 버튼 ← KeyboardUndoRedoSession 연동 (후보와 별개)" → "undo/redo 버튼 ← UndoRedoCoordinator 연동 (후보와 별개)".
- 한영 통합 약 103줄 "1. stopInputInteractionsForLanguageChange() ← 반복 입력·눌린 버튼·Shift 상태 종료 (Base)" 뒤에 "(반복 중단은 `TextDeletionCoordinator.stopRepeatInputTracking`)"을 덧붙인다. 약 105줄 `commitDeferredUndoRedoGroupIfNeeded()`는 VC public 래퍼 이름이 그대로라 유지한다.

- [x] **Step 6: `README.md`**

"전체 구조" flowchart에 노드 2개와 간선을 추가한다. `ClipboardCoord["ClipboardHistoryCoordinator"]` 아래에

```
    DeletionCoord["TextDeletionCoordinator"]
    UndoCoord["UndoRedoCoordinator"]
```

를, 간선 블록의 `ClipboardCoord -->|기록 조회 · 저장| ClipboardStore` 아래에

```
    Gesture -->|삭제 드래그 · 길게 누르기| BaseVC
    BaseVC -->|삭제 · 반복 · 드래그 위임| DeletionCoord
    DeletionCoord -->|Host: open 삭제 메서드 · 훅| BaseVC
    BaseVC -->|기록 · 확정 · 적용 위임| UndoCoord
    UndoCoord -->|Host: 쓰기 · 갱신| BaseVC
```

를 추가한다. 기존 `BaseVC -->|터치/드래그| Gesture`는 유지한다.

"ViewController · InputAdapter 구조" classDiagram의 `BaseKeyboardViewController *-- ClipboardHistoryCoordinator: Composition` 아래에

```
    BaseKeyboardViewController *-- TextDeletionCoordinator: Composition
    BaseKeyboardViewController *-- UndoRedoCoordinator: Composition
```

를 추가한다. 트러블 슈팅 절은 과거 코드라고 명시돼 있으므로 손대지 않는다.

- [x] **Step 7: `docs/architecture/README.md`, `한글 입력 로직.md` 확인**

둘을 읽고 삭제·undo·VC 보유 구조를 서술한 문장이 있으면 고치고, 없으면 "확인함, 변경 없음"으로 Step 8 결과에 적는다. 한글 입력 로직 §6(팬 복구 보정)에서 "Base VC가 …" 주어가 삭제 pan 처리를 가리키면 `TextDeletionCoordinator`로 바꾼다.

- [x] **Step 8: 물결표 규칙 확인과 커밋**

```sh
grep -nE '[^\\`]~[^`]' CLAUDE.md README.md docs/architecture/*.md | grep -v "http" || echo "물결표 위반 없음"
git branch --show-current
git add CLAUDE.md README.md docs/architecture/
git commit -m "$(cat <<'EOF'
docs: #185 - 문서에 삭제·undo/redo Coordinator 구조 반영

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
EOF
)"
```

이미 있던 위반(이번 변경과 무관한 줄)은 고치지 않고 결과에 적는다. 이 Step의 결과를 이 계획 문서에 적고 `docs: #185 - 문서 갱신 결과 기록`으로 커밋한다.

#### Task 7 결과 (2026-10-09)

- 7개 파일 갱신(`CLAUDE.md`, `README.md`, 삭제와 실행취소 로직·전체 아키텍처·성능 고려 사항·자동완성 로직·한영 통합 키보드). `docs/architecture/README.md`와 `한글 입력 로직.md`는 읽은 뒤 변경 없음(한글 입력 로직 §6의 `deleteButtonPanPreviousCharacter`는 여전히 Base의 공개 계산 프로퍼티라 맞음). 물결표 검사에서 걸린 줄은 CLAUDE.md 코드 블록 안의 `~1900줄`과 이번 변경과 무관한 기존 문장(README 개발 기간, 삭제 로직 §4-3의 `10~20ms`, 한글 입력 로직·자동완성 로직의 범위 표기)이라 손대지 않았다.

---

## PR

제목: `Refactor/#185 BaseKeyboardViewController에서 삭제 드래그·반복 삭제·undo/redo를 별도 타입으로 추출`

본문은 `.github/pull_request_template.md`를 따른다. 연관된 이슈 `- #185`. UI 변경이 없으므로 `## 📸 스크린샷` 절은 표까지 통째로 뺀다. 검증 항목에 Task 6의 실제 명령·결과·시뮬레이터 항목·`deinit`/`leaks` 결과·미확인 항목(햅틱·삭제 사운드, 첨부 앞 멈춤은 시뮬레이터에서 못 했을 때)을 적는다. 본문에 범위 물결표가 있으면 `\~`. `🤖 Generated with` 줄은 넣지 않는다. PR 생성과 push는 사용자가 지시할 때만 한다.

## 최종 리뷰 (2026-10-09)

브랜치 전체 리뷰(별도 리뷰어, f14e15e0..5944c5a1): Critical 0, Important 0, Minor 4, Ready to merge. 옮겨진 본문·콜백 순서·프록시 읽기 횟수·undo 기록 경로가 원본과 일치하고 해제 경로가 `weak host`+`[weak self]`로 닫혀 있음을 확인했다. Minor는 코드 수정 없이 기록만 한다.

- Minor 1: 시뮬레이터 확인이 spec의 `HangeulKeyboard`가 아니라 `HangeulEnglishKeyboard` 한글 모드에서 이뤄짐 → Task 6 결과와 PR 검증 항목에 실제 scheme을 적는다(두 VC의 삭제 훅 오버라이드 집합이 같고 이 diff가 두 VC를 건드리지 않음).
- Minor 2: `RecordingTextDeletionHost.performSingleDelete`가 VC `deleteText()`의 override·reliability 계약을 흉내 냄 → 단언 대상은 Coordinator→Host 호출 순서와 프록시 쓰기이고 실제 계약은 `BaseKeyboardViewControllerDeleteUndoBehaviorTests`가 덮는다. 사용자 결정으로 가짜 Host 문서 주석에 그 사실을 적었다.
- Minor 3: 반복 타이머 테스트 2개가 `RunLoop.main.run(until:)` 0.25s/0.15s 대기에 의존 → 간격 상한 0.1s라 최소 2틱 보장. 사용자 결정으로 생략. 느린 CI에서 흔들리면 간격 주입으로 바꾼다.
- Minor 4: `beginDeleteTouchDownRequest`/`beginRepeatDeleteRequest`가 host nil일 때 `.deferred` 반환 → 호출자가 모두 host guard 뒤라 도달하지 않음. 사용자 결정으로 두 guard에 주석을 달았다.
- 이후 사용자 요청으로 `CLAUDE.md`의 디렉터리·코드 스타일·빌드와 테스트 절을 추가로 최신화했다(caafa9c3).
- Minor 2·4 반영 뒤 `TextDeletionCoordinatorTests`·`BaseKeyboardViewControllerDeleteUndoBehaviorTests` 23개 통과(`scratchpad/minor-test.log`).

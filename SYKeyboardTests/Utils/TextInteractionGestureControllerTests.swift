//
//  TextInteractionGestureControllerTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/14/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("텍스트 상호작용 제스처 컨트롤러 검증")
@MainActor
struct TextInteractionGestureControllerTests {

    @Test("정상 종료된 짧은 pan은 입력을 확정")
    func test정상종료된짧은Pan() {
        let keyboardHStackView = UIView()
        let button = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄱ"], secondary: nil)
        )
        var currentPressedButton: BaseKeyboardButton? = button
        var inputCount = 0
        let controller = TextInteractionGestureController(
            keyboardHStackView: keyboardHStackView,
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )
        let gesture = TestPanGestureRecognizer(state: .ended)

        button.addAction(UIAction { _ in inputCount += 1 }, for: .touchUpInside)
        button.addGestureRecognizer(gesture)

        controller.panGestureHandler(gesture)

        #expect(inputCount == 1)
    }

    @Test("취소된 짧은 pan은 입력하지 않고 눌린 버튼을 해제")
    func test취소된짧은Pan() {
        let keyboardHStackView = UIView()
        let button = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄱ"], secondary: nil)
        )
        var currentPressedButton: BaseKeyboardButton? = button
        var inputCount = 0
        let controller = TextInteractionGestureController(
            keyboardHStackView: keyboardHStackView,
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )
        let gesture = TestPanGestureRecognizer(state: .cancelled)

        button.addAction(UIAction { _ in inputCount += 1 }, for: .touchUpInside)
        button.addGestureRecognizer(gesture)

        controller.panGestureHandler(gesture)

        #expect(inputCount == 0)
        #expect(currentPressedButton == nil)
        #expect(button.isGesturing == false)
        #expect(keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("취소된 삭제 pan은 입력하지 않고 stop callback을 호출")
    func test취소된삭제Pan() {
        let keyboardHStackView = UIView()
        let button = DeleteButton(keyboard: .dubeolsik)
        var currentPressedButton: BaseKeyboardButton? = button
        var inputCount = 0
        let delegate = TextInteractionGestureDelegateSpy()
        let controller = TextInteractionGestureController(
            keyboardHStackView: keyboardHStackView,
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )
        let gesture = TestPanGestureRecognizer(state: .cancelled)

        controller.delegate = delegate
        button.addAction(UIAction { _ in inputCount += 1 }, for: .touchUpInside)
        button.addGestureRecognizer(gesture)

        controller.panGestureHandler(gesture)

        #expect(inputCount == 0)
        #expect(currentPressedButton == nil)
        #expect(delegate.deletePanStoppedCount == 1)
    }

    @Test("실패한 짧은 pan은 입력하지 않고 눌린 버튼을 해제")
    func test실패한짧은Pan() {
        let keyboardHStackView = UIView()
        let button = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄱ"], secondary: nil)
        )
        var currentPressedButton: BaseKeyboardButton? = button
        var inputCount = 0
        let controller = TextInteractionGestureController(
            keyboardHStackView: keyboardHStackView,
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )
        let gesture = TestPanGestureRecognizer(state: .failed)

        button.addAction(UIAction { _ in inputCount += 1 }, for: .touchUpInside)
        button.addGestureRecognizer(gesture)

        controller.panGestureHandler(gesture)

        #expect(inputCount == 0)
        #expect(currentPressedButton == nil)
    }

    @Test("취소된 pan은 다른 현재 눌린 버튼을 해제하지 않음")
    func test취소된Pan_다른현재버튼보존() {
        let keyboardHStackView = UIView()
        let gestureButton = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄱ"], secondary: nil)
        )
        let otherButton = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄴ"], secondary: nil)
        )
        var currentPressedButton: BaseKeyboardButton? = otherButton
        let controller = TextInteractionGestureController(
            keyboardHStackView: keyboardHStackView,
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )
        let gesture = TestPanGestureRecognizer(state: .cancelled)

        gestureButton.addGestureRecognizer(gesture)

        controller.panGestureHandler(gesture)

        #expect(currentPressedButton === otherButton)
    }

    @Test("primary cursor pan 종료는 stop callback을 호출")
    func testPrimaryCursorPan종료_stopCallback() {
        let keyboardHStackView = UIView()
        let cursorButton = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄷ"], secondary: nil)
        )
        var currentPressedButton: BaseKeyboardButton? = cursorButton
        let delegate = TextInteractionGestureDelegateSpy()
        let controller = TextInteractionGestureController(
            keyboardHStackView: keyboardHStackView,
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )
        let cursorGesture = TestPanGestureRecognizer()
        let oldCursorActiveDistance = UserDefaultsManager.shared.cursorActiveDistance

        controller.delegate = delegate
        UserDefaultsManager.shared.cursorActiveDistance = 0
        defer { UserDefaultsManager.shared.cursorActiveDistance = oldCursorActiveDistance }

        cursorButton.addGestureRecognizer(cursorGesture)
        cursorGesture.state = .began
        controller.panGestureHandler(cursorGesture)
        cursorGesture.state = .changed
        controller.panGestureHandler(cursorGesture)
        cursorGesture.state = .ended
        controller.panGestureHandler(cursorGesture)

        #expect(delegate.primaryPanStoppedCount == 1)
    }

    @Test("primary cursor pan 활성화는 keyboard stack interaction을 끔")
    func testPrimaryCursorPan활성화_keyboardStackInteraction비활성화() {
        let keyboardHStackView = UIView()
        let cursorButton = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄷ"], secondary: nil)
        )
        var currentPressedButton: BaseKeyboardButton? = cursorButton
        let controller = TextInteractionGestureController(
            keyboardHStackView: keyboardHStackView,
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )
        let cursorGesture = TestPanGestureRecognizer()
        let oldCursorActiveDistance = UserDefaultsManager.shared.cursorActiveDistance

        UserDefaultsManager.shared.cursorActiveDistance = 0
        defer { UserDefaultsManager.shared.cursorActiveDistance = oldCursorActiveDistance }

        cursorButton.addGestureRecognizer(cursorGesture)
        cursorGesture.state = .began
        controller.panGestureHandler(cursorGesture)

        cursorGesture.state = .changed
        controller.panGestureHandler(cursorGesture)

        #expect(keyboardHStackView.isUserInteractionEnabled == false)
    }

    @Test("primary cursor pan 중 이동 간격을 넘으면 cursor pan callback을 호출")
    func testPrimaryCursorPan_cursorCallback() {
        let keyboardHStackView = UIView()
        let cursorButton = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄷ"], secondary: nil)
        )
        var currentPressedButton: BaseKeyboardButton? = cursorButton
        let delegate = TextInteractionGestureDelegateSpy()
        let controller = TextInteractionGestureController(
            keyboardHStackView: keyboardHStackView,
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )
        let cursorGesture = TestPanGestureRecognizer()
        let oldCursorActiveDistance = UserDefaultsManager.shared.cursorActiveDistance
        let oldCursorMoveInterval = UserDefaultsManager.shared.cursorMoveInterval

        controller.delegate = delegate
        UserDefaultsManager.shared.cursorActiveDistance = 0
        UserDefaultsManager.shared.cursorMoveInterval = 5
        defer {
            UserDefaultsManager.shared.cursorActiveDistance = oldCursorActiveDistance
            UserDefaultsManager.shared.cursorMoveInterval = oldCursorMoveInterval
        }

        cursorButton.addGestureRecognizer(cursorGesture)
        cursorGesture.state = .began
        cursorGesture.location = .zero
        controller.panGestureHandler(cursorGesture)

        cursorGesture.state = .changed
        cursorGesture.location = .zero
        controller.panGestureHandler(cursorGesture)

        cursorGesture.location = CGPoint(x: 5, y: 0)
        controller.panGestureHandler(cursorGesture)

        #expect(delegate.primaryPanningCount == 1)
    }

    @Test("삭제 long press 제스처 상태는 실제 종료까지 유지")
    func testDeleteLongPressOwnsGesturingStateUntilEnd() {
        let keyboardHStackView = UIView()
        let button = DeleteButton(keyboard: .dubeolsik)
        var currentPressedButton: BaseKeyboardButton? = button
        let controller = TextInteractionGestureController(
            keyboardHStackView: keyboardHStackView,
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )
        let gesture = TestLongPressGestureRecognizer()

        button.addGestureRecognizer(gesture)
        gesture.state = .began
        controller.longPressGestureHandler(gesture)

        #expect(button.isGesturing)

        gesture.state = .changed
        controller.longPressGestureHandler(gesture)

        #expect(button.isGesturing)

        gesture.state = .ended
        controller.longPressGestureHandler(gesture)

        #expect(button.isGesturing == false)
    }

}

@MainActor
private final class TextInteractionGestureDelegateSpy: TextInteractionGestureControllerDelegate {
    var primaryCursorDragActivatedCount = 0
    var deletePanStoppedCount = 0
    var primaryPanStoppedCount = 0
    var primaryPanningCount = 0

    func primaryButtonCursorDragActivated(_ controller: TextInteractionGestureController) {
        primaryCursorDragActivatedCount += 1
    }

    func primaryButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection, steps: Int) {
        primaryPanningCount += 1
    }

    func deleteButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection) {}

    func primaryButtonPanStopped(_ controller: TextInteractionGestureController) {
        primaryPanStoppedCount += 1
    }

    func deleteButtonPanStopped(_ controller: TextInteractionGestureController) {
        deletePanStoppedCount += 1
    }

    func textInteractableButtonLongPressing(_ controller: TextInteractionGestureController, button: TextInteractable) {}

    func textInteractableButtonLongPressStopped(_ controller: TextInteractionGestureController, button: TextInteractable) {}
}

// Xcode Cloud의 x86_64 simulator에서는 UIGestureRecognizer.state 직접 대입이
// handler 호출 시점까지 안정적으로 유지되지 않아 종료 상태를 테스트 더블로 고정한다.
private final class TestPanGestureRecognizer: UIPanGestureRecognizer {
    private var forcedState: UIGestureRecognizer.State
    var location: CGPoint = .zero

    init(state: UIGestureRecognizer.State = .possible) {
        self.forcedState = state
        super.init(target: nil, action: nil)
    }

    override var state: UIGestureRecognizer.State {
        get { forcedState }
        set { forcedState = newValue }
    }

    override func location(in view: UIView?) -> CGPoint {
        location
    }
}

private final class TestLongPressGestureRecognizer: UILongPressGestureRecognizer {
    private var forcedState: UIGestureRecognizer.State = .possible

    override var state: UIGestureRecognizer.State {
        get { forcedState }
        set { forcedState = newValue }
    }
}

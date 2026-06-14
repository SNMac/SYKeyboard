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
        let gesture = UIPanGestureRecognizer()

        button.addAction(UIAction { _ in inputCount += 1 }, for: .touchUpInside)
        button.addGestureRecognizer(gesture)
        gesture.state = .ended

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
        let gesture = UIPanGestureRecognizer()

        button.addAction(UIAction { _ in inputCount += 1 }, for: .touchUpInside)
        button.addGestureRecognizer(gesture)
        gesture.state = .cancelled

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
        let gesture = UIPanGestureRecognizer()

        controller.delegate = delegate
        button.addAction(UIAction { _ in inputCount += 1 }, for: .touchUpInside)
        button.addGestureRecognizer(gesture)
        gesture.state = .cancelled

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
        let gesture = UIPanGestureRecognizer()

        button.addAction(UIAction { _ in inputCount += 1 }, for: .touchUpInside)
        button.addGestureRecognizer(gesture)
        gesture.state = .failed

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
        let gesture = UIPanGestureRecognizer()

        gestureButton.addGestureRecognizer(gesture)
        gesture.state = .cancelled

        controller.panGestureHandler(gesture)

        #expect(currentPressedButton === otherButton)
    }
}

@MainActor
private final class TextInteractionGestureDelegateSpy: TextInteractionGestureControllerDelegate {
    var deletePanStoppedCount = 0

    func primaryButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection, steps: Int) {}

    func deleteButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection) {}

    func deleteButtonPanStopped(_ controller: TextInteractionGestureController) {
        deletePanStoppedCount += 1
    }

    func textInteractableButtonLongPressing(_ controller: TextInteractionGestureController, button: TextInteractable) {}

    func textInteractableButtonLongPressStopped(_ controller: TextInteractionGestureController, button: TextInteractable) {}
}

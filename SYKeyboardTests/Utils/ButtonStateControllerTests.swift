//
//  ButtonStateControllerTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/14/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("버튼 상태 컨트롤러 검증")
@MainActor
struct ButtonStateControllerTests {

    @Test("일반 버튼 touchCancel은 눌림 상태를 해제하고 다음 버튼이 이전 입력을 실행하지 않음")
    func test일반버튼_TouchCancel() {
        let keyboardHStackView = UIStackView()
        let suggestionBarView = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let controller = ButtonStateController(suggestionBarView: suggestionBarView)
        let firstButton = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄱ"], secondary: nil)
        )
        let secondButton = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄴ"], secondary: nil)
        )
        var firstButtonInputCount = 0

        firstButton.addAction(
            UIAction { _ in firstButtonInputCount += 1 },
            for: .touchUpInside
        )
        controller.setFeedbackActionToButtons([firstButton, secondButton])
        controller.setExclusiveActionToButtons([firstButton, secondButton])

        firstButton.sendActions(for: .touchDown)
        #expect(controller.currentPressedButton === firstButton)
        #expect(suggestionBarView.isUserInteractionEnabled == false)

        firstButton.sendActions(for: .touchCancel)
        #expect(controller.currentPressedButton == nil)
        #expect(suggestionBarView.isUserInteractionEnabled)

        secondButton.sendActions(for: .touchDown)
        #expect(firstButtonInputCount == 0)
        #expect(controller.currentPressedButton === secondButton)
    }

    @Test("Shift touchCancel은 눌림 상태를 해제")
    func testShift_TouchCancel() {
        let keyboardHStackView = UIStackView()
        let suggestionBarView = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let controller = ButtonStateController(suggestionBarView: suggestionBarView)
        let shiftButton = ShiftButton(keyboard: .dubeolsik)

        controller.setFeedbackActionToButtons([shiftButton])
        controller.setExclusiveActionToButtons([shiftButton])

        shiftButton.sendActions(for: .touchDown)
        #expect(controller.isShiftButtonPressed)

        shiftButton.sendActions(for: .touchCancel)
        #expect(controller.isShiftButtonPressed == false)
    }

    @Test("제스처가 시작된 일반 버튼 touchCancel은 눌림 상태와 recognizer를 유지")
    func test일반버튼_제스처중TouchCancel() {
        let keyboardHStackView = UIStackView()
        let suggestionBarView = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let controller = ButtonStateController(suggestionBarView: suggestionBarView)
        let button = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄱ"], secondary: nil)
        )
        let gesture = UIPanGestureRecognizer()

        button.addGestureRecognizer(gesture)
        controller.setFeedbackActionToButtons([button])
        controller.setExclusiveActionToButtons([button])

        button.sendActions(for: .touchDown)
        button.isGesturing = true
        gesture.state = .began

        button.sendActions(for: .touchCancel)

        #expect(controller.currentPressedButton === button)
        #expect(gesture.state == .began)
        #expect(suggestionBarView.isUserInteractionEnabled == false)
    }

    @Test("제스처가 시작된 Shift touchCancel은 눌림 상태를 유지")
    func testShift_제스처중TouchCancel() {
        let keyboardHStackView = UIStackView()
        let suggestionBarView = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        let controller = ButtonStateController(suggestionBarView: suggestionBarView)
        let shiftButton = ShiftButton(keyboard: .dubeolsik)

        controller.setFeedbackActionToButtons([shiftButton])
        controller.setExclusiveActionToButtons([shiftButton])

        shiftButton.sendActions(for: .touchDown)
        shiftButton.isGesturing = true

        shiftButton.sendActions(for: .touchCancel)

        #expect(controller.isShiftButtonPressed)
    }
}

//
//  SwitchGestureControllerTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/14/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("키보드 전환 제스처 컨트롤러 검증")
@MainActor
struct SwitchGestureControllerTests {

    @Test("정상 종료된 키보드 선택 pan은 전환을 확정")
    func test정상종료된키보드선택Pan() {
        let environment = makeEnvironment()
        let gesture = UIPanGestureRecognizer()

        environment.handler.showKeyboardSelectOverlay(needToEmphasizeTarget: true)
        environment.handler.switchButton.addGestureRecognizer(gesture)
        gesture.state = .ended

        environment.controller.keyboardSelectPanGestureHandler(gesture)

        #expect(environment.delegate.changedKeyboards == [.numeric])
        #expect(environment.handler.keyboardSelectOverlayView.isHidden)
    }

    @Test("취소된 키보드 선택 pan은 전환하지 않고 overlay를 정리")
    func test취소된키보드선택Pan() {
        let environment = makeEnvironment()
        let gesture = UIPanGestureRecognizer()

        environment.handler.showKeyboardSelectOverlay(needToEmphasizeTarget: true)
        environment.handler.switchButton.addGestureRecognizer(gesture)
        gesture.state = .cancelled

        environment.controller.keyboardSelectPanGestureHandler(gesture)

        #expect(environment.delegate.changedKeyboards.isEmpty)
        #expect(environment.handler.keyboardSelectOverlayView.isHidden)
        #expect(environment.currentPressedButton() == nil)
        #expect(environment.keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("취소된 한 손 모드 pan은 모드를 변경하지 않고 overlay를 정리")
    func test취소된한손모드Pan() {
        let environment = makeEnvironment()
        let gesture = UIPanGestureRecognizer()

        environment.handler.showOneHandedModeSelectOverlay(of: .center)
        environment.handler.switchButton.addGestureRecognizer(gesture)
        gesture.state = .cancelled

        environment.controller.oneHandedModeSelectPanGestureHandler(gesture)

        #expect(environment.delegate.changedOneHandedModes.isEmpty)
        #expect(environment.handler.oneHandedModeSelectOverlayView.isHidden)
        #expect(environment.currentPressedButton() == nil)
        #expect(environment.keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("실패한 키보드 선택 pan은 전환하지 않고 overlay를 정리")
    func test실패한키보드선택Pan() {
        let environment = makeEnvironment()
        let gesture = UIPanGestureRecognizer()

        environment.handler.showKeyboardSelectOverlay(needToEmphasizeTarget: true)
        environment.handler.switchButton.addGestureRecognizer(gesture)
        gesture.state = .failed

        environment.controller.keyboardSelectPanGestureHandler(gesture)

        #expect(environment.delegate.changedKeyboards.isEmpty)
        #expect(environment.handler.keyboardSelectOverlayView.isHidden)
        #expect(environment.currentPressedButton() == nil)
    }

    @Test("취소된 한 손 모드 long press는 모드를 변경하지 않고 overlay를 정리")
    func test취소된한손모드LongPress() {
        let environment = makeEnvironment()
        let gesture = UILongPressGestureRecognizer()

        environment.handler.showOneHandedModeSelectOverlay(of: .center)
        environment.handler.switchButton.addGestureRecognizer(gesture)
        gesture.state = .cancelled

        environment.controller.oneHandedModeLongPressGestureHandler(gesture)

        #expect(environment.delegate.changedOneHandedModes.isEmpty)
        #expect(environment.handler.oneHandedModeSelectOverlayView.isHidden)
        #expect(environment.currentPressedButton() == nil)
        #expect(environment.keyboardHStackView.isUserInteractionEnabled)
    }

    @Test("취소된 연속 한 손 모드 long press는 모드를 변경하지 않고 overlay를 정리")
    func test취소된연속한손모드LongPress() {
        let environment = makeEnvironment()
        let gesture = UILongPressGestureRecognizer()

        environment.handler.showOneHandedModeSelectOverlay(of: .center)
        environment.keyboardHStackView.addGestureRecognizer(gesture)
        gesture.state = .cancelled

        environment.controller.keyboardHStackViewPressGestureHandler(gesture)

        #expect(environment.delegate.changedOneHandedModes.isEmpty)
        #expect(environment.handler.oneHandedModeSelectOverlayView.isHidden)
        #expect(environment.handler.switchButton.isGesturing == false)
    }

    @Test("다른 버튼이 눌린 상태에서 취소된 한 손 모드 long press는 현재 버튼을 해제하지 않음")
    func test취소된한손모드LongPress_다른현재버튼보존() {
        let otherButton = PrimaryKeyButton(
            keyboard: .dubeolsik,
            button: .keyButton(primary: ["ㄱ"], secondary: nil)
        )
        let environment = makeEnvironment(currentPressedButton: otherButton)
        let gesture = UILongPressGestureRecognizer()

        environment.handler.switchButton.addGestureRecognizer(gesture)
        gesture.state = .cancelled

        environment.controller.oneHandedModeLongPressGestureHandler(gesture)

        #expect(environment.currentPressedButton() === otherButton)
    }
}

@MainActor
private extension SwitchGestureControllerTests {
    struct Environment {
        let keyboardHStackView: UIView
        let handler: SwitchGestureHandlingSpy
        let delegate: SwitchGestureDelegateSpy
        let controller: SwitchGestureController
        let currentPressedButton: () -> BaseKeyboardButton?
    }

    func makeEnvironment(currentPressedButton initialCurrentPressedButton: BaseKeyboardButton? = nil) -> Environment {
        let keyboardHStackView = UIView()
        let handler = SwitchGestureHandlingSpy()
        let delegate = SwitchGestureDelegateSpy()
        var currentPressedButton: BaseKeyboardButton? = initialCurrentPressedButton ?? handler.switchButton
        let controller = SwitchGestureController(
            keyboardHStackView: keyboardHStackView,
            hangeulKeyboardView: handler,
            englishKeyboardView: nil,
            symbolKeyboardView: handler,
            numericKeyboardView: handler,
            getCurrentKeyboard: { .dubeolsik },
            getCurrentOneHandedMode: { .center },
            getCurrentPressedButton: { currentPressedButton },
            setCurrentPressedButton: { currentPressedButton = $0 }
        )

        controller.delegate = delegate

        return Environment(
            keyboardHStackView: keyboardHStackView,
            handler: handler,
            delegate: delegate,
            controller: controller,
            currentPressedButton: { currentPressedButton }
        )
    }
}

@MainActor
private final class SwitchGestureHandlingSpy: SwitchGestureHandling {
    let switchButton = SwitchButton(keyboard: .dubeolsik)
    let keyboardSelectOverlayView = KeyboardSelectOverlayView(keyboard: .dubeolsik)
    let oneHandedModeSelectOverlayView = OneHandedModeSelectOverlayView()

    init() {
        keyboardSelectOverlayView.isHidden = true
        oneHandedModeSelectOverlayView.isHidden = true
    }

    func enableAllButtonUserInteraction() {}

    func disableAllButtonUserInteraction() {}
}

@MainActor
private final class SwitchGestureDelegateSpy: SwitchGestureControllerDelegate {
    var changedKeyboards: [SYKeyboardType] = []
    var changedOneHandedModes: [OneHandedMode] = []

    func changeKeyboard(_ controller: SwitchGestureController, to newKeyboard: SYKeyboardType) {
        changedKeyboards.append(newKeyboard)
    }

    func changeOneHandedMode(_ controller: SwitchGestureController, to newMode: OneHandedMode) {
        changedOneHandedModes.append(newMode)
    }
}

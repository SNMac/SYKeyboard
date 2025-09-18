//
//  ButtonStateController.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/17/25.
//

import UIKit
import OSLog

final class ButtonStateController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    /// 현재 눌린 버튼
    var currentPressedButton: BaseKeyboardButton? {
        didSet {
            oldValue?.isPressed = false
            currentPressedButton?.isPressed = true
        }
    }
    /// Shift 버튼 눌림 여부
    private(set) var isShiftButtonPressed: Bool = false
    /// 제스처 활성화 여부
    var isGestureActive: Bool = false
    
    // MARK: - Internal Methods
    
    func setFeedbackActionToButtons(_ buttonList: [BaseKeyboardButton]) {
        buttonList.forEach { button in
            let playFeedbackAndSetPressed: UIAction
            if button is ShiftButton {
                playFeedbackAndSetPressed = UIAction { [weak self] _ in
                    guard let self else { return }
                    
                    if isGestureActive {
                        logger.notice("현재 활성화중인 제스처로 인해 버튼 입력 무시")
                        return
                    }
                    
                    if let previousButton = currentPressedButton, previousButton != button {
                        previousButton.sendActions(for: .touchUpInside)
                    }
                    
                    isShiftButtonPressed = true
                    button.playFeedback()
                }
            } else {
                playFeedbackAndSetPressed = UIAction { [weak self] _ in
                    guard let self else { return }
                    
                    if isGestureActive {
                        logger.notice("현재 활성화중인 제스처로 인해 버튼 입력 무시")
                        return
                    }
                    
                    if let previousButton = currentPressedButton, previousButton != button {
                        previousButton.sendActions(for: .touchUpInside)
                    }
                    
                    currentPressedButton = button
                    button.playFeedback()
                }
            }
            button.addAction(playFeedbackAndSetPressed, for: .touchDown)
        }
    }
    
    func setExclusiveActionToButtons(_ buttonList: [BaseKeyboardButton]) {
        buttonList.forEach { button in
            let buttonReleaseAction: UIAction
            if button is ShiftButton {
                buttonReleaseAction = UIAction { [weak self] _ in
                    self?.isShiftButtonPressed = false
                }
            } else {
                buttonReleaseAction = UIAction { [weak self] _ in
                    guard let currentPressedButton = self?.currentPressedButton, currentPressedButton == button else { return }
                    self?.currentPressedButton = nil
                }
            }
            button.addAction(buttonReleaseAction, for: .touchUpInside)
        }
    }
}

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
    
    /// 제스처 활성화 여부
    var isGestureActive: Bool = false
    
    // MARK: - Internal Methods
    
    func setFeedbackActionToButtons(_ buttonList: [BaseKeyboardButton]) {
        buttonList.forEach { button in
            let playFeedback = UIAction { [weak self] _ in
                guard let self else { return }
                
                if isGestureActive {
                    logger.notice("현재 활성화중인 제스처로 인해 버튼 입력 무시")
                    return
                }
                
                if let previousButton = currentPressedButton, previousButton != button {
                    previousButton.sendActions(for: .touchUpInside)
                }
                
                if !(button is ShiftButton) {
                    currentPressedButton = button
                }
                button.playFeedback()
            }
            button.addAction(playFeedback, for: .touchDown)
        }
    }
    
    func setExclusiveActionToButtons(_ buttonList: [BaseKeyboardButton]) {
        buttonList.forEach { button in
            guard !(button is ShiftButton) else { return }
            let dismissCurrentButtonAction = UIAction { [weak self] _ in
                guard let self else { return }
                if let currentPressedButton = self.currentPressedButton, currentPressedButton == button {
                    self.currentPressedButton = nil
                }
            }
            button.addAction(dismissCurrentButtonAction, for: .touchUpInside)
        }
    }
}

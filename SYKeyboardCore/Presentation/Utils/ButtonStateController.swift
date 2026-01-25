//
//  ButtonStateController.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/17/25.
//

import UIKit
import OSLog

final public class ButtonStateController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    /// 현재 눌린 버튼
    weak var currentPressedButton: BaseKeyboardButton? {
        didSet {
            oldValue?.isPressed = false
            oldValue?.gestureRecognizers?.forEach { $0.state = .cancelled }
            
            currentPressedButton?.isPressed = true
        }
    }
    /// Shift 버튼 눌림 여부
    public var isShiftButtonPressed: Bool = false
    
    // MARK: - Lifecycle
    
    deinit {
        logger.debug("\(String(describing: type(of: self))) deinit")
    }
    
    // MARK: - Internal Methods
    
    func setFeedbackActionToButtons(_ buttonList: [BaseKeyboardButton]) {
        buttonList.forEach { button in
            let playFeedbackAndSetPressed: UIAction
            if button is ShiftButton {
                playFeedbackAndSetPressed = UIAction { [weak self] action in
                    guard let senderButton = action.sender as? BaseKeyboardButton else { return }
                    
                    if let previousButton = self?.currentPressedButton, previousButton != senderButton {
                        previousButton.sendActions(for: .touchUpInside)
                    }
                    
                    self?.isShiftButtonPressed = true
                    senderButton.playFeedback()
                }
            } else {
                playFeedbackAndSetPressed = UIAction { [weak self] action in
                    guard let senderButton = action.sender as? BaseKeyboardButton else { return }
                    
                    if let previousButton = self?.currentPressedButton, previousButton != senderButton {
                        previousButton.sendActions(for: .touchUpInside)
                    }
                    
                    self?.currentPressedButton = senderButton
                    senderButton.playFeedback()
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
                buttonReleaseAction = UIAction { [weak self] action in
                    guard let senderButton = action.sender as? BaseKeyboardButton else { return }
                    
                    if self?.currentPressedButton == senderButton {
                        self?.currentPressedButton = nil
                    }
                }
            }
            button.addAction(buttonReleaseAction, for: .touchUpInside)
        }
    }
}

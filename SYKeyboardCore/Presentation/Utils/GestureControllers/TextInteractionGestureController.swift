//
//  TextInteractionGestureController.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/3/25.
//

import UIKit
import OSLog

protocol TextInteractionGestureControllerDelegate: AnyObject {
    func primaryButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection)
    func deleteButtonPanning(_ controller: TextInteractionGestureController, to direction: PanDirection)
    func deleteButtonPanStopped(_ controller: TextInteractionGestureController)
    func textInteractableButtonLongPressing(_ controller: TextInteractionGestureController, button: TextInteractable)
    func textInteractableButtonLongPressStopped(_ controller: TextInteractionGestureController)
}

/// 입력 상호작용 버튼(리턴 버튼 제외) 제스처 컨트롤러
final class TextInteractionGestureController: NSObject {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    private var isCursorActive: Bool = false
    private var initialPanPoint: CGPoint = .zero
    private var intervalReferPanPoint: CGPoint = .zero
    
    // Initializer Injection
    private let keyboardFrameView: UIView
    private let getCurrentPressedButton: () -> BaseKeyboardButton?
    private let setCurrentPressedButton: (BaseKeyboardButton?) -> ()
    
    // Property Injection
    weak var delegate: TextInteractionGestureControllerDelegate?
    
    // MARK: - Initializer
    
    init(keyboardFrameView: UIView,
         getCurrentPressedButton: @escaping () -> BaseKeyboardButton?,
         setCurrentPressedButton: @escaping (BaseKeyboardButton?) -> ()) {
        self.keyboardFrameView = keyboardFrameView
        self.getCurrentPressedButton = getCurrentPressedButton
        self.setCurrentPressedButton = setCurrentPressedButton
    }
    
    // MARK: - @objc Gesture Methods
    
    @objc func panGestureHandler(_ gesture: UIPanGestureRecognizer) {
        let gestureButton = gesture.view as? TextInteractable
        let currentPoint = gesture.location(in: gesture.view)
        
        switch gesture.state {
        case .began:
            gestureButton?.isGesturing = true
            initialPanPoint = currentPoint
            intervalReferPanPoint = currentPoint
            logger.debug("팬 제스처 활성화")
        case .changed:
            let distance = calcDistance(point1: initialPanPoint, point2: currentPoint)
            if isCursorActive || distance >= UserDefaultsManager.shared.cursorActiveDistance {
                keyboardFrameView.isUserInteractionEnabled = false
                
                isCursorActive = true
                gestureButton?.isGesturing = false
                onPanGestureChanged(gesture)
            }
        case .ended, .cancelled, .failed:
            // 순서 중요
            if !isCursorActive { gestureButton?.sendActions(for: .touchUpInside) }
            setCurrentPressedButton(nil)
            
            onPanGestureEnded(gesture)
            isCursorActive = false
            initialPanPoint = .zero
            intervalReferPanPoint = .zero
            gestureButton?.isGesturing = false
            
            keyboardFrameView.isUserInteractionEnabled = true
            logger.debug("팬 제스처 비활성화")
        default:
            break
        }
    }
    
    @objc func longPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        let gestureButton = gesture.view as? TextInteractable
        
        switch gesture.state {
        case .began:
            guard getCurrentPressedButton() === gestureButton else {
                logger.info("현재 눌려있는 버튼으로 인해 제스처 무시")
                gesture.state = .cancelled
                return
            }
            keyboardFrameView.isUserInteractionEnabled = false
            
            gestureButton?.isGesturing = true
            onLongPressGestureBegan(gesture)
            logger.debug("길게 누르기 제스처 활성화")
        case .ended, .cancelled, .failed:
            // 순서 중요
            if gesture.state == .cancelled {
                logger.debug("길게 누르기 제스처 취소")
            } else {
                setCurrentPressedButton(nil)
                logger.debug("길게 누르기 제스처 비활성화")
            }
            
            onLongPressGestureEnded()
            gestureButton?.isGesturing = false
            keyboardFrameView.isUserInteractionEnabled = true
        default:
            break
        }
    }
}

// MARK: - Gesture Methods

private extension TextInteractionGestureController {
    func onPanGestureChanged(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: gesture.view)
        
        let distance = currentPoint.x - intervalReferPanPoint.x
        if abs(distance) >= UserDefaultsManager.shared.cursorMoveInterval {
            if gesture.view is DeleteButton {
                if distance > 0 {
                    delegate?.deleteButtonPanning(self, to: .right)
                } else {
                    delegate?.deleteButtonPanning(self, to: .left)
                }
            } else if gesture.view is TextInteractable {
                if distance > 0 {
                    delegate?.primaryButtonPanning(self, to: .right)
                } else {
                    delegate?.primaryButtonPanning(self, to: .left)
                }
            } else {
                assertionFailure("입력 상호작용 버튼이 아닙니다.")
            }
            intervalReferPanPoint = currentPoint
        }
    }
    
    func onPanGestureEnded(_ gesture: UIPanGestureRecognizer) {
        if gesture.view is DeleteButton {
            delegate?.deleteButtonPanStopped(self)
        }
    }
    
    func onLongPressGestureBegan(_ gesture: UILongPressGestureRecognizer) {
        guard let gestureButton = gesture.view as? TextInteractable else {
            assertionFailure("입력 상호작용 버튼이 아닙니다.")
            return
        }
        delegate?.textInteractableButtonLongPressing(self, button: gestureButton)
    }
    
    func onLongPressGestureEnded() {
        delegate?.textInteractableButtonLongPressStopped(self)
    }
}

// MARK: - Gesture Helper Methods

private extension TextInteractionGestureController {
    func calcDistance(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TextInteractionGestureController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }
}

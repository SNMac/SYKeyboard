//
//  TextInteractionButtonGestureController.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/3/25.
//

import UIKit
import OSLog

protocol TextInteractionButtonGestureControllerDelegate: AnyObject {
    func primaryButtonPanning(_ controller: TextInteractionButtonGestureController, to direction: PanDirection)
    func deleteButtonPanning(_ controller: TextInteractionButtonGestureController, to direction: PanDirection)
    func deleteButtonPanStopped(_ controller: TextInteractionButtonGestureController)
    func textInteractionButtonLongPressing(_ controller: TextInteractionButtonGestureController, button: TextInteractionType)
    func textInteractionButtonLongPressStopped(_ controller: TextInteractionButtonGestureController)
}

/// 입력 상호작용 버튼(리턴 버튼 제외) 제스처 컨트롤러
final class TextInteractionButtonGestureController: NSObject {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    private var initialPanPoint: CGPoint = .zero
    private var intervalReferPanPoint: CGPoint = .zero
    private var isCursorActive: Bool = false
    
    // Property Injection
    weak var delegate: TextInteractionButtonGestureControllerDelegate?
    
    // MARK: - @objc Gesture Methods
    
    @objc func panGestureHandler(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: gesture.view)
        let currentButton = gesture.view as? TextInteractionButton
        
        switch gesture.state {
        case .began:
            currentButton?.isSelected = true
            initialPanPoint = currentPoint
            intervalReferPanPoint = currentPoint
            logger.debug("팬 제스처 활성화")
        case .changed:
            let distance = calcDistance(point1: initialPanPoint, point2: currentPoint)
            if isCursorActive || distance >= UserDefaultsManager.shared.cursorActiveDistance {
                isCursorActive = true
                currentButton?.isSelected = false
                onPanGestureChanged(gesture)
            }
        case .ended, .cancelled, .failed:
            onPanGestureEnded(gesture)
            initialPanPoint = .zero
            intervalReferPanPoint = .zero
            isCursorActive = false
            currentButton?.isSelected = false
            logger.debug("팬 제스처 비활성화")
        default:
            break
        }
    }
    
    @objc func longPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        let currentButton = gesture.view as? TextInteractionButton
        
        switch gesture.state {
        case .began:
            currentButton?.isSelected = true
            onLongPressGestureBegan(gesture)
            logger.debug("길게 누르기 제스처 활성화")
        case .ended, .cancelled, .failed:
            onLongPressGestureEnded()
            currentButton?.isSelected = false
            logger.debug("길게 누르기 제스처 비활성화")
        default:
            break
        }
    }
}

// MARK: - Gesture Methods

private extension TextInteractionButtonGestureController {
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
            } else if gesture.view is TextInteractionButton {
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
        let currentButton = gesture.view as? TextInteractionButton
        guard let button = currentButton?.button else {
            assertionFailure("입력 상호작용 버튼이 아닙니다.")
            return
        }
        delegate?.textInteractionButtonLongPressing(self, button: button)
    }
    
    func onLongPressGestureEnded() {
        delegate?.textInteractionButtonLongPressStopped(self)
    }
}

// MARK: - Gesture Helper Methods

private extension TextInteractionButtonGestureController {
    func calcDistance(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TextInteractionButtonGestureController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }
}

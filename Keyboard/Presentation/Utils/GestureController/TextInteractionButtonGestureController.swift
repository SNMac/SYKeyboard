//
//  TextInteractionButtonGestureController.swift
//  Keyboard
//
//  Created by 서동환 on 9/3/25.
//

import UIKit
import OSLog

protocol TextInteractionButtonGestureControllerDelegate: AnyObject {
    func moveCursor(_ controller: TextInteractionButtonGestureController, to direction: PanDirection)
//    func repeatInput()
}

final class TextInteractionButtonGestureController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    private var initialPanPoint: CGPoint = .zero
    private var intervalReferPanPoint: CGPoint = .zero
    private var isPanGestureHandlerActive: Bool = false {
        didSet {
            if isPanGestureHandlerActive {
                logger.debug("팬 제스처 활성화 중")
            } else {
                logger.debug("팬 제스처 비활성화됨")
            }
        }
    }
    
    // Initializer Injection
    private let naratgeulKeyboardView: TextInteractionButtonGestureHandler
    private let symbolKeyboardView: TextInteractionButtonGestureHandler
    private let numericKeyboardView: TextInteractionButtonGestureHandler
    private let getCurrentKeyboardLayout: () -> KeyboardLayout
    
    // Property Injection
    weak var delegate: TextInteractionButtonGestureControllerDelegate?
    
    // MARK: - Initializer
    
    init(naratgeulKeyboardView: TextInteractionButtonGestureHandler,
         symbolKeyboardView: TextInteractionButtonGestureHandler,
         numericKeyboardView: TextInteractionButtonGestureHandler,
         getCurrentKeyboardLayout: @escaping () -> KeyboardLayout) {
        self.naratgeulKeyboardView = naratgeulKeyboardView
        self.symbolKeyboardView = symbolKeyboardView
        self.numericKeyboardView = numericKeyboardView
        self.getCurrentKeyboardLayout = getCurrentKeyboardLayout
    }
    
    // MARK: - @objc Gesture Methods
    
    @objc func panGestureHandler(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: gesture.view)
        let currentButton = gesture.view as? TextInteractionButton
        
        switch gesture.state {
        case .began:
            currentButton?.isSelected = true
            initialPanPoint = currentPoint
        case .changed:
            let distance = calcDistance(point1: initialPanPoint, point2: currentPoint)
            if isPanGestureHandlerActive || distance >= UserDefaultsManager.shared.cursorActiveDistance {
                currentButton?.isSelected = false
                isPanGestureHandlerActive = true
                onPanGestureChanged(gesture)
            }
        case .ended, .cancelled, .failed:
            initialPanPoint = .zero
            isPanGestureHandlerActive = false
            currentButton?.isSelected = false
        default:
            break
        }
    }
    
    @objc func longPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        let currentButton = gesture.view as? TextInteractionButton
        let gestureHandler = setGestureHandler()
        
        switch gesture.state {
        case .began:
            currentButton?.isSelected = true
        case .changed:
            onLongPressGestureChanged(gesture, gestureHandler: gestureHandler)
        case .ended, .cancelled, .failed:
            onLongPressGestureEnded(gesture, gestureHandler: gestureHandler)
            currentButton?.isSelected = false
        default:
            break
        }
    }
}

// MARK: - Gesture Methods

private extension TextInteractionButtonGestureController {
    func onPanGestureChanged(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: gesture.view)
        
        let distance = calcDistance(point1: intervalReferPanPoint, point2: currentPoint)
        if distance >= UserDefaultsManager.shared.cursorMoveInterval {
            if currentPoint.x - intervalReferPanPoint.x > 0 {
                delegate?.moveCursor(self, to: .right)
            } else {
                delegate?.moveCursor(self, to: .left)
            }
            intervalReferPanPoint = currentPoint
        }
    }
    
    func onLongPressGestureChanged(_ gesture: UILongPressGestureRecognizer, gestureHandler: TextInteractionButtonGestureHandler) {
        
    }
    
    func onLongPressGestureEnded(_ gesture: UILongPressGestureRecognizer, gestureHandler: TextInteractionButtonGestureHandler) {
        
    }
}

// MARK: - Gesture Helper Methods

private extension TextInteractionButtonGestureController {
    func setGestureHandler() -> TextInteractionButtonGestureHandler {
        let gestureHandler: TextInteractionButtonGestureHandler
        
        let currentKeyboardLayout = getCurrentKeyboardLayout()
        switch currentKeyboardLayout {
        case .hangeul:
            gestureHandler = naratgeulKeyboardView
        case .symbol:
            gestureHandler = symbolKeyboardView
        case .numeric:
            gestureHandler = numericKeyboardView
        default:
            fatalError("구현되지 않은 case입니다.")
        }
        return gestureHandler
    }
    
    func calcDistance(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}

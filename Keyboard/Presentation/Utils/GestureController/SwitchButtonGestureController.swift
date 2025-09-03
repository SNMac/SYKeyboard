//
//  SwitchButtonGestureController.swift
//  Keyboard
//
//  Created by 서동환 on 9/2/25.
//

import UIKit
import OSLog

protocol SwitchButtonGestureControllerDelegate: AnyObject {
    func changeKeyboardLayout(_ controller: SwitchButtonGestureController, to newLayout: KeyboardLayout)
    func changeOneHandedMode(_ controller: SwitchButtonGestureController, to newMode: OneHandedMode)
}

/// 키보드 전환 버튼 제스처 컨트롤러
final class SwitchButtonGestureController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    private var initialPanPoint: CGPoint = .zero
    
    typealias PanConfig = (gestureHandler: SwitchButtonGestureHandler,
                           targetLayout: KeyboardLayout,
                           targetDirection: PanDirection)
    
    // Initializer Injection
    private let naratgeulKeyboardView: SwitchButtonGestureHandler
    private let symbolKeyboardView: SwitchButtonGestureHandler
    private let numericKeyboardView: SwitchButtonGestureHandler
    private let getCurrentKeyboardLayout: () -> KeyboardLayout
    private let getCurrentOneHandedMode: () -> OneHandedMode
    
    // Property Injection
    weak var delegate: SwitchButtonGestureControllerDelegate?
    
    // MARK: - Initializer
    
    init(naratgeulKeyboardView: SwitchButtonGestureHandler,
         symbolKeyboardView: SwitchButtonGestureHandler,
         numericKeyboardView: SwitchButtonGestureHandler,
         getCurrentKeyboardLayout: @escaping () -> KeyboardLayout,
         getCurrentOneHandedMode: @escaping () -> OneHandedMode) {
        self.naratgeulKeyboardView = naratgeulKeyboardView
        self.symbolKeyboardView = symbolKeyboardView
        self.numericKeyboardView = numericKeyboardView
        self.getCurrentKeyboardLayout = getCurrentKeyboardLayout
        self.getCurrentOneHandedMode = getCurrentOneHandedMode
    }
    
    // MARK: - @objc Gesture Methods
    
    @objc func panGestureHandler(_ gesture: UIPanGestureRecognizer) {
        let currentButton = gesture.view as? SwitchButton
        let config = setPanConfig()
        
        switch gesture.state {
        case .began:
            currentButton?.isSelected = true
            logger.debug("팬 제스처 활성화")
        case .changed:
            onPanGestureChanged(gesture, config: config)
        case .ended, .cancelled, .failed:
            onPanGestureEnded(gesture, config: config)
            currentButton?.isSelected = false
            logger.debug("팬 제스처 비활성화")
        default:
            break
        }
    }
    
    @objc func longPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        let currentButton = gesture.view as? SwitchButton
        let gestureHandler = setGestureHandler()
        
        switch gesture.state {
        case .began:
            currentButton?.isSelected = true
            onLongPressGestureBegan(gestureHandler: gestureHandler)
            logger.debug("길게 누르기 제스처 활성화")
        case .changed:
            onLongPressGestureChanged(gesture, gestureHandler: gestureHandler)
        case .ended, .cancelled, .failed:
            onLongPressGestureEnded(gesture, gestureHandler: gestureHandler)
            currentButton?.isSelected = false
            logger.debug("길게 누르기 제스처 비활성화")
        default:
            break
        }
    }
}

// MARK: - Gesture Methods

private extension SwitchButtonGestureController {
    func onPanGestureChanged(_ gesture: UIPanGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            let panLocation = gesture.location(in: switchButton)
            let panDirection = checkPanGestureDirection(panLocation: panLocation, targetRect: switchButton.bounds)
            
            if panDirection == config.targetDirection {
                config.gestureHandler.showKeyboardSelectOverlay(needToEmphasizeTarget: true)
                switchButton.configureKeyboardSelectComponent(needToEmphasize: true)
            } else if panDirection == .up {
                let currentOneHandedMode = getCurrentOneHandedMode()
                config.gestureHandler.showOneHandedModeSelectOverlay(of: currentOneHandedMode)
                switchButton.configureOneHandedComponent(needToEmphasize: true)
            }
            
        } else if !keyboardSelectOverlayView.isHidden {
            let panTarget = keyboardSelectOverlayView.xmarkImageContainerView
            let panLocation = gesture.location(in: keyboardSelectOverlayView)
            let panDirection = checkKeyboardSelectPanDirection(panLocation: panLocation, targetRect: panTarget.frame, targetDirection: config.targetDirection)
            
            config.gestureHandler.showKeyboardSelectOverlay(needToEmphasizeTarget: panDirection == config.targetDirection)
            
        } else if !oneHandedModeSelectOverlayView.isHidden {
            let panLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(panLocation: panLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            let targetOneHandedMode = selectOneHandedModeOverlay(panDirection: panDirection)
            config.gestureHandler.showOneHandedModeSelectOverlay(of: targetOneHandedMode)
        }
    }
    
    func onPanGestureEnded(_ gesture: UIPanGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if !keyboardSelectOverlayView.isHidden {
            let panTarget = keyboardSelectOverlayView.xmarkImageContainerView
            let panLocation = gesture.location(in: keyboardSelectOverlayView)
            let panDirection = checkKeyboardSelectPanDirection(panLocation: panLocation, targetRect: panTarget.frame, targetDirection: config.targetDirection)
            
            if panDirection == config.targetDirection {
                delegate?.changeKeyboardLayout(self, to: config.targetLayout)
            }
            config.gestureHandler.hideKeyboardSelectOverlay()
            switchButton.configureKeyboardSelectComponent(needToEmphasize: false)
            
        } else if !oneHandedModeSelectOverlayView.isHidden {
            let panLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(panLocation: panLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            delegate?.changeOneHandedMode(self, to: selectOneHandedModeOverlay(panDirection: panDirection))
            config.gestureHandler.hideOneHandedModeSelectOverlay()
            switchButton.configureOneHandedComponent(needToEmphasize: false)
        }
    }
    
    func onLongPressGestureBegan(gestureHandler: SwitchButtonGestureHandler) {
        let switchButton = gestureHandler.switchButton
        let keyboardSelectOverlayView = gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = gestureHandler.oneHandedModeSelectOverlayView
        
        if keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            let currentOneHandedMode = getCurrentOneHandedMode()
            gestureHandler.showOneHandedModeSelectOverlay(of: currentOneHandedMode)
            switchButton.configureOneHandedComponent(needToEmphasize: true)
        }
    }
    
    func onLongPressGestureChanged(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchButtonGestureHandler) {
        let oneHandedModeSelectOverlayView = gestureHandler.oneHandedModeSelectOverlayView
        
        if !oneHandedModeSelectOverlayView.isHidden {
            let panLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(panLocation: panLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            let targetOneHandedMode = selectOneHandedModeOverlay(panDirection: panDirection)
            gestureHandler.showOneHandedModeSelectOverlay(of: targetOneHandedMode)
        }
    }
    
    func onLongPressGestureEnded(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchButtonGestureHandler) {
        let switchButton = gestureHandler.switchButton
        let oneHandedModeSelectOverlayView = gestureHandler.oneHandedModeSelectOverlayView
        
        if !oneHandedModeSelectOverlayView.isHidden {
            let panLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(panLocation: panLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            delegate?.changeOneHandedMode(self, to: selectOneHandedModeOverlay(panDirection: panDirection))
            gestureHandler.hideOneHandedModeSelectOverlay()
            switchButton.configureOneHandedComponent(needToEmphasize: false)
        }
    }
}

// MARK: - Gesture Helper Methods

private extension SwitchButtonGestureController {
    func setGestureHandler() -> SwitchButtonGestureHandler {
        let gestureHandler: SwitchButtonGestureHandler
        
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
    
    func setPanConfig() -> PanConfig {
        let config: PanConfig
        
        let currentKeyboardLayout = getCurrentKeyboardLayout()
        switch currentKeyboardLayout {
        case .hangeul:
            config = (gestureHandler: naratgeulKeyboardView,
                      targetLayout: .numeric,
                      targetDirection: .left)
        case .symbol:
            config = (gestureHandler: symbolKeyboardView,
                      targetLayout: .numeric,
                      targetDirection: .right)
        case .numeric:
            config = (gestureHandler: numericKeyboardView,
                      targetLayout: .symbol,
                      targetDirection: .left)
        default:
            fatalError("구현되지 않은 case입니다.")
        }
        return config
    }
    
    func checkPanGestureDirection(panLocation: CGPoint, targetRect: CGRect) -> PanDirection? {
        if panLocation.y < targetRect.minY {
            return .up
        } else if panLocation.x < targetRect.minX {
            return .left
        } else if panLocation.x > targetRect.maxX {
            return .right
        } else if panLocation.y > targetRect.maxY {
            return .down
        } else {
            return .none
        }
    }
    
    func checkKeyboardSelectPanDirection(panLocation: CGPoint, targetRect: CGRect, targetDirection: PanDirection) -> PanDirection? {
        switch targetDirection {
        case .left:
            if panLocation.x <= targetRect.minX {
                return .left
            } else if panLocation.x > targetRect.minX {
                return .right
            } else {
                return .none
            }
        case .right:
            if panLocation.x < targetRect.maxX {
                return .left
            } else if panLocation.x >= targetRect.maxX {
                return .right
            } else {
                return .none
            }
        default:
            fatalError("사용되지 않는 targetDirection 입니다.")
        }
    }
    
    func checkOneHandModePanDirection(panLocation: CGPoint, targetMinX: CGFloat, targetMaxX: CGFloat, targetRect: CGRect) -> PanDirection? {
        if targetRect.contains(panLocation) {
            if panLocation.x < targetMinX {
                return .left
            } else if panLocation.x > targetMaxX {
                return .right
            } else if panLocation.x >= targetMinX && panLocation.x <= targetMaxX {
                return .center
            }
        }
        return .none
    }
    
    func selectOneHandedModeOverlay(panDirection: PanDirection?) -> OneHandedMode {
        switch panDirection {
        case .left:
            return .left
        case .right:
            return .right
        case .center:
            return .center
        default:
            return getCurrentOneHandedMode()
        }
    }
}

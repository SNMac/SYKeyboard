//
//  GestureController.swift
//  Keyboard
//
//  Created by 서동환 on 9/2/25.
//

import UIKit

protocol GestureControllerDelegate: AnyObject {
    func changeKeyboardLayout(_ controller: GestureController, to newLayout: KeyboardLayout)
    func changeOneHandedMode(_ controller: GestureController, to newMode: OneHandedMode)
}

/// 키보드 제스처 컨트롤러
final class GestureController {
    
    // MARK: - Properties
    
    // Initializer Injection
    private let naratgeulKeyboardView: SwitchButtonGestureHandler
    private let symbolKeyboardView: SwitchButtonGestureHandler
    private let numericKeyboardView: SwitchButtonGestureHandler
//    private let tenkeyKeyboardView: SwitchButtonGestureHandler
    private let getCurrentKeyboardLayout: () -> KeyboardLayout
    private let getCurrentOneHandedMode: () -> OneHandedMode
    
    // Property Injection
    weak var delegate: GestureControllerDelegate?
    
    typealias PanConfig = (
        gestureHandler: SwitchButtonGestureHandler,
        targetLayout: KeyboardLayout,
        targetDirection: PanDirection
    )
    
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
    
    @objc func handleSwitchButtonPanGesture(_ gesture: UIPanGestureRecognizer) {
        let config = setPanConfig()
        
        switch gesture.state {
        case .changed:
            handlePanGestureChanged(gesture, config: config)
        case .ended:
            handlePanGestureEnded(gesture, config: config)
        default:
            break
        }
    }
    
    @objc func handleSwitchButtonLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        let gestureHandler = setGestureHandler()
        
        switch gesture.state {
        case .began:
            handleLongPressGestureBegan(gestureHandler: gestureHandler)
        case .changed:
            handleLongPressGestureChanged(gesture, gestureHandler: gestureHandler)
        case .ended:
            handleLongPressGestureEnded(gesture, gestureHandler: gestureHandler)
        default:
            break
        }
    }
}

// MARK: - Button Gesture Methods

private extension GestureController {
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
    
    func handlePanGestureChanged(_ gesture: UIPanGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            let dragLocation = gesture.location(in: switchButton)
            let panDirection = checkPanGestureDirection(dragLocation: dragLocation, targetRect: switchButton.bounds)
            
            if panDirection == config.targetDirection {
                config.gestureHandler.showKeyboardSelectOverlay(needToEmphasizeTarget: true)
                switchButton.configureKeyboardSelectComponent(needToEmphasize: true)
            } else if panDirection == .up {
                let currentOneHandedMode = getCurrentOneHandedMode()
                config.gestureHandler.showOneHandedModeSelectOverlay(of: currentOneHandedMode)
                switchButton.configureOneHandedComponent(needToEmphasize: true)
            }
            
        } else if !keyboardSelectOverlayView.isHidden {
            let panTarget = config.gestureHandler.keyboardSelectOverlayView.xmarkImageContainerView
            let dragLocation = gesture.location(in: keyboardSelectOverlayView)
            let panDirection = checkKeyboardSelectPanDirection(dragLocation: dragLocation, targetRect: panTarget.frame, targetDirection: config.targetDirection)
            
            config.gestureHandler.showKeyboardSelectOverlay(needToEmphasizeTarget: panDirection == config.targetDirection)
            
        } else if !oneHandedModeSelectOverlayView.isHidden {
            let dragLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(dragLocation: dragLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            let targetOneHandedMode = selectOneHandedModeOverlay(panDirection: panDirection)
            config.gestureHandler.showOneHandedModeSelectOverlay(of: targetOneHandedMode)
        }
    }
    
    func handlePanGestureEnded(_ gesture: UIPanGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if !keyboardSelectOverlayView.isHidden {
            let panTarget = config.gestureHandler.keyboardSelectOverlayView.xmarkImageContainerView
            let dragLocation = gesture.location(in: keyboardSelectOverlayView)
            let panDirection = checkKeyboardSelectPanDirection(dragLocation: dragLocation, targetRect: panTarget.frame, targetDirection: config.targetDirection)
            
            if panDirection == config.targetDirection {
                delegate?.changeKeyboardLayout(self, to: config.targetLayout)
            }
            config.gestureHandler.hideKeyboardSelectOverlay()
            switchButton.configureKeyboardSelectComponent(needToEmphasize: false)
            
        } else if !oneHandedModeSelectOverlayView.isHidden {
            let dragLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(dragLocation: dragLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            delegate?.changeOneHandedMode(self, to: selectOneHandedModeOverlay(panDirection: panDirection))
            config.gestureHandler.hideOneHandedModeSelectOverlay()
            switchButton.configureOneHandedComponent(needToEmphasize: false)
        }
    }
    
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
    
    func handleLongPressGestureBegan(gestureHandler: SwitchButtonGestureHandler) {
        let switchButton = gestureHandler.switchButton
        let keyboardSelectOverlayView = gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = gestureHandler.oneHandedModeSelectOverlayView
        
        if keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            let currentOneHandedMode = getCurrentOneHandedMode()
            gestureHandler.showOneHandedModeSelectOverlay(of: currentOneHandedMode)
            switchButton.configureOneHandedComponent(needToEmphasize: true)
        }
    }
    
    func handleLongPressGestureChanged(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchButtonGestureHandler) {
        let oneHandedModeSelectOverlayView = gestureHandler.oneHandedModeSelectOverlayView
        
        if !oneHandedModeSelectOverlayView.isHidden {
            let dragLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(dragLocation: dragLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            let targetOneHandedMode = selectOneHandedModeOverlay(panDirection: panDirection)
            gestureHandler.showOneHandedModeSelectOverlay(of: targetOneHandedMode)
        }
    }
    
    func handleLongPressGestureEnded(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchButtonGestureHandler) {
        let switchButton = gestureHandler.switchButton
        let oneHandedModeSelectOverlayView = gestureHandler.oneHandedModeSelectOverlayView
        
        if !oneHandedModeSelectOverlayView.isHidden {
            let dragLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(dragLocation: dragLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            delegate?.changeOneHandedMode(self, to: selectOneHandedModeOverlay(panDirection: panDirection))
            gestureHandler.hideOneHandedModeSelectOverlay()
            switchButton.configureOneHandedComponent(needToEmphasize: false)
        }
    }
    
    func checkPanGestureDirection(dragLocation: CGPoint, targetRect: CGRect) -> PanDirection? {
        if dragLocation.y < targetRect.minY {
            return .up
        } else if dragLocation.x < targetRect.minX {
            return .left
        } else if dragLocation.x > targetRect.maxX {
            return .right
        } else if dragLocation.y > targetRect.maxY {
            return .down
        } else {
            return .none
        }
    }
    
    func checkKeyboardSelectPanDirection(dragLocation: CGPoint, targetRect: CGRect, targetDirection: PanDirection) -> PanDirection? {
        switch targetDirection {
        case .left:
            if dragLocation.x < targetRect.minX {
                return .left
            } else if dragLocation.x > targetRect.minX {
                return .right
            } else {
                return .none
            }
        case .right:
            if dragLocation.x < targetRect.maxX {
                return .left
            } else if dragLocation.x > targetRect.maxX {
                return .right
            } else {
                return .none
            }
        default:
            fatalError("사용되지 않는 targetDirection 입니다.")
        }
    }
    
    func checkOneHandModePanDirection(dragLocation: CGPoint, targetMinX: CGFloat, targetMaxX: CGFloat, targetRect: CGRect) -> PanDirection? {
        if targetRect.contains(dragLocation) {
            if dragLocation.x < targetMinX {
                return .left
            } else if dragLocation.x > targetMaxX {
                return .right
            } else if dragLocation.x >= targetMinX && dragLocation.x <= targetMaxX {
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

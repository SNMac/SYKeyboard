//
//  SwitchGestureController.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/2/25.
//

import UIKit
import OSLog

protocol SwitchGestureControllerDelegate: AnyObject {
    func changeKeyboard(_ controller: SwitchGestureController, to newKeyboard: SYKeyboardType)
    func changeOneHandedMode(_ controller: SwitchGestureController, to newMode: OneHandedMode)
}

/// 키보드 전환 버튼 제스처 컨트롤러
final class SwitchGestureController: NSObject {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    typealias PanConfig = (gestureHandler: SwitchGestureHandling,
                           keyboardSelectTargetkeyboard: SYKeyboardType,
                           keyboardSelectTargetDirection: PanDirection)
    
    private var isOverlayActive: Bool = false
    private var isDragOutside: Bool = false
    private var isKeepGesturing: Bool = false
    
    private lazy var keyboardFrameViewPressGestureRecognizer: UILongPressGestureRecognizer = {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(keyboardFrameViewPressGestureHandler(_:)))
        gestureRecognizer.minimumPressDuration = 0
        
        return gestureRecognizer
    }()
    
    // Initializer Injection
    private let keyboardFrameView: UIView
    private let hangeulKeyboardView: SwitchGestureHandling?
    private let englishKeyboardView: SwitchGestureHandling?
    private let symbolKeyboardView: SwitchGestureHandling
    private let numericKeyboardView: SwitchGestureHandling
    private let getCurrentKeyboard: () -> SYKeyboardType
    private let getCurrentOneHandedMode: () -> OneHandedMode
    private let getCurrentPressedButton: () -> BaseKeyboardButton?
    private let setCurrentPressedButton: (BaseKeyboardButton?) -> ()
    
    // Property Injection
    weak var delegate: SwitchGestureControllerDelegate?
    
    // MARK: - Initializer
    
    init(keyboardFrameView: UIView,
         hangeulKeyboardView: SwitchGestureHandling?,
         englishKeyboardView: SwitchGestureHandling?,
         symbolKeyboardView: SwitchGestureHandling,
         numericKeyboardView: SwitchGestureHandling,
         getCurrentKeyboard: @escaping () -> SYKeyboardType,
         getCurrentOneHandedMode: @escaping () -> OneHandedMode,
         getCurrentPressedButton: @escaping () -> BaseKeyboardButton?,
         setCurrentPressedButton: @escaping (BaseKeyboardButton?) -> ()) {
        self.keyboardFrameView = keyboardFrameView
        self.hangeulKeyboardView = hangeulKeyboardView
        self.englishKeyboardView = englishKeyboardView
        self.symbolKeyboardView = symbolKeyboardView
        self.numericKeyboardView = numericKeyboardView
        self.getCurrentKeyboard = getCurrentKeyboard
        self.getCurrentOneHandedMode = getCurrentOneHandedMode
        self.getCurrentPressedButton = getCurrentPressedButton
        self.setCurrentPressedButton = setCurrentPressedButton
    }
    
    // MARK: - @objc Gesture Methods
    
    @objc func keyboardSelectPanGestureHandler(_ gesture: UIPanGestureRecognizer) {
        let gestureButton = gesture.view as? SwitchButton
        let config = setPanConfig()
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        switch gesture.state {
        case .began:
            gestureButton?.isGesturing = true
            logger.debug("키보드 선택 팬 제스처 활성화")
        case .changed:
            isOverlayActive = !keyboardSelectOverlayView.isHidden || !oneHandedModeSelectOverlayView.isHidden
            if isOverlayActive { keyboardFrameView.isUserInteractionEnabled = false }
            onkeyboardSelectPanGestureChanged(gesture, config: config)
        case .ended, .cancelled, .failed:
            // 순서 중요
            if !isOverlayActive { gestureButton?.sendActions(for: .touchUpInside) }
            setCurrentPressedButton(nil)
            
            onkeyboardSelectPanGestureEnded(gesture, config: config)
            isOverlayActive = false
            gestureButton?.isGesturing = false
            
            keyboardFrameView.isUserInteractionEnabled = true
            logger.debug("키보드 선택 팬 제스처 비활성화")
        default:
            break
        }
    }
    
    @objc func oneHandedModeSelectPanGestureHandler(_ gesture: UIPanGestureRecognizer) {
        let gestureButton = gesture.view as? SwitchButton
        let config = setPanConfig()
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        switch gesture.state {
        case .began:
            gestureButton?.isGesturing = true
            logger.debug("팬 제스처 활성화")
        case .changed:
            isOverlayActive = !keyboardSelectOverlayView.isHidden || !oneHandedModeSelectOverlayView.isHidden
            if isOverlayActive { keyboardFrameView.isUserInteractionEnabled = false }
            onOneHandedModeSelectPanGestureChanged(gesture, config: config)
        case .ended, .cancelled, .failed:
            // 순서 중요
            if !isOverlayActive { gestureButton?.sendActions(for: .touchUpInside) }
            setCurrentPressedButton(nil)
            
            onOneHandedModeSelectPanGestureEnded(gesture, config: config)
            isOverlayActive = false
            gestureButton?.isGesturing = false
            
            keyboardFrameView.isUserInteractionEnabled = true
            logger.debug("팬 제스처 비활성화")
        default:
            break
        }
    }
    
    @objc func oneHandedModeLongPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        let gestureButton = gesture.view as? SwitchButton
        let config = setPanConfig()
        
        switch gesture.state {
        case .began:
            guard getCurrentPressedButton() === gestureButton else {
                logger.info("현재 눌려있는 버튼으로 인해 제스처 무시")
                gesture.state = .cancelled
                return
            }
            keyboardFrameView.isUserInteractionEnabled = false
            
            gestureButton?.isGesturing = true
            onLongPressGestureBegan(config: config)
            logger.debug("길게 누르기 제스처 활성화")
        case .changed:
            onLongPressGestureChanged(gesture, config: config)
        case .ended, .cancelled, .failed:
            // 순서 중요
            if gesture.state == .cancelled {
                logger.debug("길게 누르기 제스처 취소")
            } else {
                setCurrentPressedButton(nil)
                logger.debug("길게 누르기 제스처 비활성화")
            }
            onLongPressGestureEnded(gesture, config: config)
            gestureButton?.isGesturing = isKeepGesturing
            if isKeepGesturing { config.gestureHandler.disableAllButtonUserInteraction() }
            
            keyboardFrameView.isUserInteractionEnabled = true
        default:
            break
        }
    }
    
    @objc func keyboardFrameViewPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        let gestureHandler = setGestureHandler()
        let gestureButton = gestureHandler.switchButton
        
        switch gesture.state {
        case .began:
            logger.debug("키보드 길게 누르기 제스처 활성화")
            fallthrough
        case .changed:
            onKeyboardFrameViewPressGestureChanged(gesture, gestureHandler: gestureHandler)
        case .ended, .cancelled, .failed:
            onKeyboardFrameViewPressGestureEnded(gesture, gestureHandler: gestureHandler)
            gestureButton.isGesturing = false
            gestureHandler.enableAllButtonUserInteraction()
            logger.debug("키보드 길게 누르기 제스처 비활성화")
        default:
            break
        }
    }
}

// MARK: - Keyboard Select Pan Gesture Methods

private extension SwitchGestureController {
    func onkeyboardSelectPanGestureChanged(_ gesture: UIPanGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            let panLocation = gesture.location(in: switchButton)
            let panDirection = checkSwitchButtonPanGestureDirection(panLocation: panLocation, targetRect: switchButton.bounds)
            
            if panDirection == config.keyboardSelectTargetDirection {
                startkeyboardSelect(config: config, switchButton: switchButton)
            }
            
        } else if !keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            selectKeyboard(keyboardSelectOverlayView,
                           gesture: gesture,
                           config: config)
        }
    }
    
    func onkeyboardSelectPanGestureEnded(_ gesture: UIPanGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if !keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            endKeyboardSelect(keyboardSelectOverlayView,
                                gesture: gesture,
                                config: config,
                                switchButton: switchButton)
            
        }
    }
}

// MARK: - One Handed Mode Select Pan Gesture Methods

private extension SwitchGestureController {
    func onOneHandedModeSelectPanGestureChanged(_ gesture: UIPanGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            let panLocation = gesture.location(in: switchButton)
            let panDirection = checkSwitchButtonPanGestureDirection(panLocation: panLocation, targetRect: switchButton.bounds)
            
            if panDirection == .up {
                startOneHandedModeSelect(config: config, switchButton: switchButton)
            }
            
        } else if keyboardSelectOverlayView.isHidden && !oneHandedModeSelectOverlayView.isHidden {
            selectOneHandedMode(oneHandedModeSelectOverlayView,
                                gesture: gesture,
                                config: config)
        }
    }
    
    func onOneHandedModeSelectPanGestureEnded(_ gesture: UIPanGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if keyboardSelectOverlayView.isHidden && !oneHandedModeSelectOverlayView.isHidden {
            endOneHandedModeSelect(oneHandedModeSelectOverlayView,
                                     gesture: gesture,
                                     config: config,
                                     switchButton: switchButton)
        }
    }
}

// MARK: - One Handed Mode Select Long Press Gesture Methods

private extension SwitchGestureController {
    func onLongPressGestureBegan(config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            startOneHandedModeSelect(config: config, switchButton: switchButton)
        }
    }
    
    func onLongPressGestureChanged(_ gesture: UILongPressGestureRecognizer, config: PanConfig) {
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if !oneHandedModeSelectOverlayView.isHidden && keyboardSelectOverlayView.isHidden {
            selectOneHandedMode(oneHandedModeSelectOverlayView, gesture: gesture, config: config)
        }
    }
    
    func onLongPressGestureEnded(_ gesture: UILongPressGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if !oneHandedModeSelectOverlayView.isHidden && keyboardSelectOverlayView.isHidden {
            endOneHandedModeSelect(oneHandedModeSelectOverlayView, gesture: gesture, config: config, switchButton: switchButton)
        }
        
        isDragOutside = false
    }
}

// MARK: - KeyboardView Pan Gesture Methods

private extension SwitchGestureController {
    func onKeyboardFrameViewPressGestureChanged(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchGestureHandling) {
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
    
    func onKeyboardFrameViewPressGestureEnded(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchGestureHandling) {
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
            
            keyboardFrameView.removeGestureRecognizer(keyboardFrameViewPressGestureRecognizer)
        }
    }
}

// MARK: - Gesture Helper Methods

private extension SwitchGestureController {
    func setGestureHandler() -> SwitchGestureHandling {
        let gestureHandler: SwitchGestureHandling
        
        let currentKeyboard = getCurrentKeyboard()
        switch currentKeyboard {
        case .naratgeul, .cheonjiin, .dubeolsik:
            guard let hangeulKeyboardView else { fatalError("옵셔널 바인딩 실패 - hangeulKeyboardView가 nil입니다.") }
            gestureHandler = hangeulKeyboardView
        case .qwerty:
            guard let englishKeyboardView else { fatalError("옵셔널 바인딩 실패 - englishKeyboardView가 nil입니다.") }
            gestureHandler = englishKeyboardView
        case .symbol:
            gestureHandler = symbolKeyboardView
        case .numeric:
            gestureHandler = numericKeyboardView
        case .tenKey:
            fatalError("도달할 수 없는 case입니다.")
        }
        return gestureHandler
    }
    
    func setPanConfig() -> PanConfig {
        let config: PanConfig
        
        let currentKeyboard = getCurrentKeyboard()
        switch currentKeyboard {
        case .naratgeul, .cheonjiin, .dubeolsik:
            guard let hangeulKeyboardView else { fatalError("옵셔널 바인딩 실패 - hangeulKeyboardView가 nil입니다.") }
            config = (gestureHandler: hangeulKeyboardView,
                      keyboardSelectTargetkeyboard: .numeric,
                      keyboardSelectTargetDirection: .left)
        case .qwerty:
            guard let englishKeyboardView else { fatalError("옵셔널 바인딩 실패 - englishKeyboardView가 nil입니다.") }
            config = (gestureHandler: englishKeyboardView,
                      keyboardSelectTargetkeyboard: .numeric,
                      keyboardSelectTargetDirection: .right)
        case .symbol:
            config = (gestureHandler: symbolKeyboardView,
                      keyboardSelectTargetkeyboard: .numeric,
                      keyboardSelectTargetDirection: .right)
        case .numeric:
            config = (gestureHandler: numericKeyboardView,
                      keyboardSelectTargetkeyboard: .symbol,
                      keyboardSelectTargetDirection: .left)
        case .tenKey:
            fatalError("도달할 수 없는 case입니다.")
        }
        return config
    }
    
    func checkSwitchButtonPanGestureDirection(panLocation: CGPoint, targetRect: CGRect) -> PanDirection? {
        if panLocation.x >= targetRect.minX && panLocation.x <= targetRect.maxX
            && panLocation.y < targetRect.minY {
            return .up
        } else if panLocation.y >= targetRect.minY && panLocation.y <= targetRect.maxY
            && panLocation.x < targetRect.minX {
            return .left
        } else if panLocation.y >= targetRect.minY && panLocation.y <= targetRect.maxY
            && panLocation.x > targetRect.maxX {
            return .right
        } else if panLocation.x >= targetRect.minX && panLocation.x <= targetRect.maxX
            && panLocation.y > targetRect.maxY {
            return .down
        } else {
            return nil
        }
    }
    
    func checkKeyboardSelectPanDirection(panLocation: CGPoint, xmarkRect: CGRect, targetDirection: PanDirection) -> PanDirection? {
        switch targetDirection {
        case .left:
            if panLocation.x <= xmarkRect.minX {
                return .left
            } else if panLocation.x > xmarkRect.minX {
                return .right
            } else {
                return nil
            }
        case .right:
            if panLocation.x < xmarkRect.maxX {
                return .left
            } else if panLocation.x >= xmarkRect.maxX {
                return .right
            } else {
                return nil
            }
        default:
            assertionFailure("사용되지 않는 targetDirection 입니다.")
            return nil
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
        return nil
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
    
    func startkeyboardSelect(config: PanConfig, switchButton: SwitchButton) {
        config.gestureHandler.showKeyboardSelectOverlay(needToEmphasizeTarget: true)
        switchButton.configureKeyboardSelectComponent(needToEmphasize: true)
    }
    
    func selectKeyboard(_ keyboardSelectOverlayView: KeyboardSelectOverlayView, gesture: UIGestureRecognizer, config: PanConfig) {
        let xmarkRect = keyboardSelectOverlayView.xmarkImageContainerView.frame
        let panLocation = gesture.location(in: keyboardSelectOverlayView)
        let panDirection = checkKeyboardSelectPanDirection(panLocation: panLocation, xmarkRect: xmarkRect, targetDirection: config.keyboardSelectTargetDirection)
        
        config.gestureHandler.showKeyboardSelectOverlay(needToEmphasizeTarget: panDirection == config.keyboardSelectTargetDirection)
    }
    
    func endKeyboardSelect(_ keyboardSelectOverlayView: KeyboardSelectOverlayView, gesture: UIGestureRecognizer, config: PanConfig, switchButton: SwitchButton) {
        let xmarkRect = keyboardSelectOverlayView.xmarkImageContainerView.frame
        let panLocation = gesture.location(in: keyboardSelectOverlayView)
        let panDirection = checkKeyboardSelectPanDirection(panLocation: panLocation, xmarkRect: xmarkRect, targetDirection: config.keyboardSelectTargetDirection)
        
        if panDirection == config.keyboardSelectTargetDirection {
            delegate?.changeKeyboard(self, to: config.keyboardSelectTargetkeyboard)
        }
        config.gestureHandler.hideKeyboardSelectOverlay()
        switchButton.configureKeyboardSelectComponent(needToEmphasize: false)
    }
    
    func startOneHandedModeSelect(config: PanConfig, switchButton: SwitchButton) {
        let currentOneHandedMode = getCurrentOneHandedMode()
        config.gestureHandler.showOneHandedModeSelectOverlay(of: currentOneHandedMode)
        switchButton.configureOneHandedComponent(needToEmphasize: true)
    }
    
    func selectOneHandedMode(_ oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView, gesture: UIGestureRecognizer, config: PanConfig) {
        let panLocation = gesture.location(in: oneHandedModeSelectOverlayView)
        let panDirection = checkOneHandModePanDirection(panLocation: panLocation,
                                                        targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                        targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                        targetRect: oneHandedModeSelectOverlayView.bounds)
        
        if gesture is UILongPressGestureRecognizer && panDirection == nil {
            isDragOutside = true
        }
        let targetOneHandedMode = selectOneHandedModeOverlay(panDirection: panDirection)
        config.gestureHandler.showOneHandedModeSelectOverlay(of: targetOneHandedMode)
    }
    
    func endOneHandedModeSelect(_ oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView, gesture: UIGestureRecognizer, config: PanConfig, switchButton: SwitchButton) {
        let panLocation = gesture.location(in: oneHandedModeSelectOverlayView)
        let panDirection = checkOneHandModePanDirection(panLocation: panLocation,
                                                        targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                        targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                        targetRect: oneHandedModeSelectOverlayView.bounds)
        
        if gesture is UILongPressGestureRecognizer {
            if panDirection != nil || isDragOutside {
                delegate?.changeOneHandedMode(self, to: selectOneHandedModeOverlay(panDirection: panDirection))
                config.gestureHandler.hideOneHandedModeSelectOverlay()
                switchButton.configureOneHandedComponent(needToEmphasize: false)
                isKeepGesturing = false
            } else {
                keyboardFrameView.addGestureRecognizer(keyboardFrameViewPressGestureRecognizer)
                isKeepGesturing = true
            }
        } else {
            delegate?.changeOneHandedMode(self, to: selectOneHandedModeOverlay(panDirection: panDirection))
            config.gestureHandler.hideOneHandedModeSelectOverlay()
            switchButton.configureOneHandedComponent(needToEmphasize: false)
        }
    }
    
    func calcDistance(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SwitchGestureController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }
}

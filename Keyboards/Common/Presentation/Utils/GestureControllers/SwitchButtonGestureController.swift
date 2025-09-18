//
//  SwitchButtonGestureController.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/2/25.
//

import UIKit
import OSLog

import Then

protocol SwitchButtonGestureControllerDelegate: AnyObject {
    func changeKeyboard(_ controller: SwitchButtonGestureController, to newKeyboard: SYKeyboardType)
    func changeOneHandedMode(_ controller: SwitchButtonGestureController, to newMode: OneHandedMode)
}

/// 키보드 전환 버튼 제스처 컨트롤러
final class SwitchButtonGestureController: NSObject {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    typealias PanConfig = (gestureHandler: SwitchButtonGestureHandler,
                           targetkeyboard: SYKeyboardType,
                           targetDirection: PanDirection)
    
    private var isOverlayActive: Bool = false
    private var isDragOutside: Bool = false
    
    private lazy var keyboardFrameViewPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(keyboardFrameViewPressGestureHandler(_:))).then {
        $0.minimumPressDuration = 0
    }
    
    // Initializer Injection
    private let keyboardFrameView: UIView
    private let hangeulKeyboardView: SwitchButtonGestureHandler?
    private let englishKeyboardView: SwitchButtonGestureHandler?
    private let symbolKeyboardView: SwitchButtonGestureHandler
    private let numericKeyboardView: SwitchButtonGestureHandler
    private let getCurrentKeyboard: () -> SYKeyboardType
    private let getCurrentOneHandedMode: () -> OneHandedMode
    private let getCurrentPressedButton: () -> BaseKeyboardButton?
    private let setCurrentPressedButton: (BaseKeyboardButton?) -> ()
    
    // Property Injection
    weak var delegate: SwitchButtonGestureControllerDelegate?
    
    // MARK: - Initializer
    
    init(keyboardFrameView: UIView,
         hangeulKeyboardView: SwitchButtonGestureHandler?,
         englishKeyboardView: SwitchButtonGestureHandler?,
         symbolKeyboardView: SwitchButtonGestureHandler,
         numericKeyboardView: SwitchButtonGestureHandler,
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
    
    @objc func panGestureHandler(_ gesture: UIPanGestureRecognizer) {
        let gestureButton = gesture.view as? SwitchButton
        let config = setPanConfig()
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        switch gesture.state {
        case .began:
            gestureButton?.isSelected = true
            logger.debug("팬 제스처 활성화")
        case .changed:
            isOverlayActive = !keyboardSelectOverlayView.isHidden || !oneHandedModeSelectOverlayView.isHidden
            if isOverlayActive { keyboardFrameView.isUserInteractionEnabled = false }
            onPanGestureChanged(gesture, config: config)
        case .ended, .cancelled, .failed:
            // 순서 중요
            if !isOverlayActive { gestureButton?.sendActions(for: .touchUpInside) }
            setCurrentPressedButton(nil)
            
            onPanGestureEnded(gesture, config: config)
            isOverlayActive = false
            gestureButton?.isSelected = false
            
            keyboardFrameView.isUserInteractionEnabled = true
            logger.debug("팬 제스처 비활성화")
        default:
            break
        }
    }
    
    @objc func longPressGestureHandler(_ gesture: UILongPressGestureRecognizer) {
        let gestureButton = gesture.view as? SwitchButton
        let gestureHandler = setGestureHandler()
        
        switch gesture.state {
        case .began:
            guard getCurrentPressedButton() === gestureButton else {
                logger.notice("현재 눌려있는 버튼으로 인해 제스처 무시")
                gesture.state = .cancelled
                return
            }
            keyboardFrameView.isUserInteractionEnabled = false
            
            gestureButton?.isSelected = true
            onLongPressGestureBegan(gestureHandler: gestureHandler)
            logger.debug("길게 누르기 제스처 활성화")
        case .changed:
            onLongPressGestureChanged(gesture, gestureHandler: gestureHandler)
        case .ended, .cancelled, .failed:
            // 순서 중요
            if gesture.state == .cancelled {
                logger.debug("길게 누르기 제스처 취소")
            } else {
                setCurrentPressedButton(nil)
                logger.debug("길게 누르기 제스처 비활성화")
            }
            let isKeepSelected = onLongPressGestureEnded(gesture, gestureHandler: gestureHandler)
            gestureButton?.isSelected = isKeepSelected
            
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
            gestureButton.isSelected = false
            logger.debug("키보드 길게 누르기 제스처 비활성화")
        default:
            break
        }
    }
}

// MARK: - Pan Gesture Methods

private extension SwitchButtonGestureController {
    func onPanGestureChanged(_ gesture: UIPanGestureRecognizer, config: PanConfig) {
        let switchButton = config.gestureHandler.switchButton
        let keyboardSelectOverlayView = config.gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = config.gestureHandler.oneHandedModeSelectOverlayView
        
        if keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
            let panLocation = gesture.location(in: switchButton)
            let panDirection = checkPanGestureDirection(panLocation: panLocation, targetRect: switchButton.bounds)
            
            if UserDefaultsManager.shared.isNumericKeypadEnabled && panDirection == config.targetDirection {
                // 숫자 키보드 선택 오버레이
                config.gestureHandler.showKeyboardSelectOverlay(needToEmphasizeTarget: true)
                switchButton.configureKeyboardSelectComponent(needToEmphasize: true)
            } else if UserDefaultsManager.shared.isOneHandedKeyboardEnabled && panDirection == .up {
                // 한 손 키보드 선택 오버레이
                let currentOneHandedMode = getCurrentOneHandedMode()
                config.gestureHandler.showOneHandedModeSelectOverlay(of: currentOneHandedMode)
                switchButton.configureOneHandedComponent(needToEmphasize: true)
            }
            
        } else if !keyboardSelectOverlayView.isHidden {
            let xmarkRect = keyboardSelectOverlayView.xmarkImageContainerView.frame
            let panLocation = gesture.location(in: keyboardSelectOverlayView)
            print("panLocation: \(panLocation.x)")
            print(keyboardSelectOverlayView.xmarkImageContainerView.frame.minX)
            print(keyboardSelectOverlayView.xmarkImageContainerView.frame.maxX)
            let panDirection = checkKeyboardSelectPanDirection(panLocation: panLocation, xmarkRect: xmarkRect, targetDirection: config.targetDirection)
            
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
            let xmarkRect = keyboardSelectOverlayView.xmarkImageContainerView.frame
            let panLocation = gesture.location(in: keyboardSelectOverlayView)
            let panDirection = checkKeyboardSelectPanDirection(panLocation: panLocation, xmarkRect: xmarkRect, targetDirection: config.targetDirection)
            
            if panDirection == config.targetDirection {
                delegate?.changeKeyboard(self, to: config.targetkeyboard)
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
}

// MARK: - Long Press Gesture Methods

private extension SwitchButtonGestureController {
    func onLongPressGestureBegan(gestureHandler: SwitchButtonGestureHandler) {
        let switchButton = gestureHandler.switchButton
        let keyboardSelectOverlayView = gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = gestureHandler.oneHandedModeSelectOverlayView
        
        if UserDefaultsManager.shared.isOneHandedKeyboardEnabled
            && keyboardSelectOverlayView.isHidden && oneHandedModeSelectOverlayView.isHidden {
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
            
            if panDirection == nil { isDragOutside = true }
            let targetOneHandedMode = selectOneHandedModeOverlay(panDirection: panDirection)
            gestureHandler.showOneHandedModeSelectOverlay(of: targetOneHandedMode)
        }
    }
    
    func onLongPressGestureEnded(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchButtonGestureHandler) -> Bool {
        let switchButton = gestureHandler.switchButton
        let oneHandedModeSelectOverlayView = gestureHandler.oneHandedModeSelectOverlayView
        
        if !oneHandedModeSelectOverlayView.isHidden {
            let panLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(panLocation: panLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            if panDirection != nil || isDragOutside {
                delegate?.changeOneHandedMode(self, to: selectOneHandedModeOverlay(panDirection: panDirection))
                gestureHandler.hideOneHandedModeSelectOverlay()
                switchButton.configureOneHandedComponent(needToEmphasize: false)
            } else {
                keyboardFrameView.addGestureRecognizer(keyboardFrameViewPressGestureRecognizer)
                return true
            }
        }
        
        isDragOutside = false
        return false
    }
}

// MARK: - KeyboardView Pan Gesture Methods

private extension SwitchButtonGestureController {
    func onKeyboardFrameViewPressGestureChanged(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchButtonGestureHandler) {
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
    
    func onKeyboardFrameViewPressGestureEnded(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchButtonGestureHandler) {
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

private extension SwitchButtonGestureController {
    func setGestureHandler() -> SwitchButtonGestureHandler {
        let gestureHandler: SwitchButtonGestureHandler
        
        let currentKeyboard = getCurrentKeyboard()
        switch currentKeyboard {
        case .hangeul:
            guard let hangeulKeyboardView else { fatalError("옵셔널 바인딩 실패 - hangeulKeyboardView가 nil입니다.") }
            gestureHandler = hangeulKeyboardView
        case .english:
            guard let englishKeyboardView else { fatalError("옵셔널 바인딩 실패 - englishKeyboardView가 nil입니다.") }
            gestureHandler = englishKeyboardView
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
        
        let currentKeyboard = getCurrentKeyboard()
        switch currentKeyboard {
        case .hangeul:
            guard let hangeulKeyboardView else { fatalError("옵셔널 바인딩 실패 - hangeulKeyboardView가 nil입니다.") }
            config = (gestureHandler: hangeulKeyboardView,
                      targetkeyboard: .numeric,
                      targetDirection: .left)
        case .english:
            guard let englishKeyboardView else { fatalError("옵셔널 바인딩 실패 - englishKeyboardView가 nil입니다.") }
            config = (gestureHandler: englishKeyboardView,
                      targetkeyboard: .numeric,
                      targetDirection: .right)
        case .symbol:
            config = (gestureHandler: symbolKeyboardView,
                      targetkeyboard: .numeric,
                      targetDirection: .right)
        case .numeric:
            config = (gestureHandler: numericKeyboardView,
                      targetkeyboard: .symbol,
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
    
    func calcDistance(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SwitchButtonGestureController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return false
    }
}

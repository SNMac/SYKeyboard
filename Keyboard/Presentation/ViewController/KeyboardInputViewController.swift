//
//  KeyboardInputViewController.swift
//  Keyboard
//
//  Created by 서동환 on 7/29/24.
//

import UIKit
import OSLog

import SnapKit
import Then

/// 키보드 입력/UI 컨트롤러
final class KeyboardInputViewController: UIInputViewController {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    /// 현재 키보드
    private var currentKeyboardLayout: KeyboardLayout = .hangeul {
        didSet {
            updateKeyboardLayout()
        }
    }
    /// 현재 한 손 키보드
    private var currentOneHandedMode: OneHandedMode = .center {
        didSet {
            UserDefaultsManager.shared.lastOneHandedMode = currentOneHandedMode
            updateKeyboardConstraints()
        }
    }
    /// iPhone SE용 키보드 전환 버튼 액션
    private let nextKeyboardAction: Selector = #selector(handleInputModeList(from:with:))
    
    // MARK: - UI Components
    
    /// 키보드 전체 프레임
    private let keyboardFrameHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 0
        $0.backgroundColor = .clear
    }
    /// 키보드 뷰
    private let keyboardLayoutView = UIView().then {
        $0.backgroundColor = .clear
    }
    /// 한 손 키보드 해제 버튼(오른손 모드)
    private let leftChevronButton = ChevronButton(direction: .left).then { $0.isHidden = true }
    /// 나랏글 키보드
    private lazy var naratgeulKeyboardView = NaratgeulKeyboardView(needsInputModeSwitchKey: needsInputModeSwitchKey,
                                                                   nextKeyboardAction: nextKeyboardAction).then { $0.isHidden = false }
    /// 기호 키보드
    private lazy var symbolKeyboardView = SymbolKeyboardView(needsInputModeSwitchKey: needsInputModeSwitchKey,
                                                             nextKeyboardAction: nextKeyboardAction).then { $0.isHidden = true }
    /// 숫자 키보드
    private lazy var numericKeyboardView = NumericKeyboardView(needsInputModeSwitchKey: needsInputModeSwitchKey,
                                                               nextKeyboardAction: nextKeyboardAction).then { $0.isHidden = true }
    /// 텐키 키보드
    private lazy var tenkeyKeyboardView = TenkeyKeyboardView().then { $0.isHidden = true }
    /// 한 손 키보드 해제 버튼(왼손 모드)
    private let rightChevronButton = ChevronButton(direction: .right).then { $0.isHidden = true }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

// MARK: - UI Methods

private extension KeyboardInputViewController {
    func setupUI() {
        setStyles()
        setActions()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.inputView?.backgroundColor = .clear
    }
    
    func setActions() {
        setSwitchButtonAction()
        setChevronButtonAction()
    }
    
    func setHierarchy() {
        guard let inputView = self.inputView else { return }
        inputView.addSubview(keyboardFrameHStackView)
        
        keyboardFrameHStackView.addArrangedSubviews(leftChevronButton, keyboardLayoutView, rightChevronButton)
        
        keyboardLayoutView.addSubviews(naratgeulKeyboardView,
                                       symbolKeyboardView,
                                       numericKeyboardView,
                                       tenkeyKeyboardView)
    }
    
    func setConstraints() {
        keyboardFrameHStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(UserDefaultsManager.shared.keyboardHeight).priority(.high)
        }
        
        naratgeulKeyboardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        symbolKeyboardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        numericKeyboardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        tenkeyKeyboardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

// MARK: - Button Action Methods

private extension KeyboardInputViewController {
    func setSwitchButtonAction() {
        // 기호 키보드 전환
        let switchToSymbolKeyboard = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .symbol
        }
        naratgeulKeyboardView.switchButton.addAction(switchToSymbolKeyboard, for: .touchUpInside)
        
        // 한글 키보드 전환
        let switchToHangeulKeyboard = UIAction { [weak self] _ in
            self?.currentKeyboardLayout = .hangeul
        }
        symbolKeyboardView.switchButton.addAction(switchToHangeulKeyboard, for: .touchUpInside)
        numericKeyboardView.switchButton.addAction(switchToHangeulKeyboard, for: .touchUpInside)
        
        // 키보드 전환 버튼 제스쳐
        [naratgeulKeyboardView.switchButton,
         symbolKeyboardView.switchButton,
         numericKeyboardView.switchButton].forEach { addGesturesToSwitchButton($0) }
    }
    
    func addGesturesToSwitchButton(_ button: SwitchButton) {
        // 팬 제스쳐
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwitchButtonPanGesture(_:)))
        button.addGestureRecognizer(panGesture)
        
        // 롱 탭 제스쳐
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleSwitchButtonLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = UserDefaultsManager.shared.longPressDuration
        longPressGesture.allowableMovement = UserDefaultsManager.shared.cursorActiveDistance
        button.addGestureRecognizer(longPressGesture)
    }
    
    func setChevronButtonAction() {
        let resetOneHandMode = UIAction { [weak self] _ in
            self?.currentOneHandedMode = .center
        }
        leftChevronButton.addAction(resetOneHandMode, for: .touchUpInside)
        rightChevronButton.addAction(resetOneHandMode, for: .touchUpInside)
    }
}

// MARK: - Button Gesture Methods

private extension KeyboardInputViewController {
    typealias PanConfig = (
        gestureHandler: SwitchButtonGestureHandler,
        targetLayout: KeyboardLayout,
        targetDirection: PanDirection
    )
    
    func setPanConfig() -> PanConfig {
        let config: PanConfig
        
        switch currentKeyboardLayout {
        case .hangeul:
            config = (
                gestureHandler: naratgeulKeyboardView,
                targetLayout: .numeric,
                targetDirection: .left
            )
        case .symbol:
            config = (
                gestureHandler: symbolKeyboardView,
                targetLayout: .numeric,
                targetDirection: .right
            )
        case .numeric:
            config = (
                gestureHandler: numericKeyboardView,
                targetLayout: .symbol,
                targetDirection: .left
            )
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
                currentKeyboardLayout = config.targetLayout
            }
            config.gestureHandler.hideKeyboardSelectOverlay()
            switchButton.configureKeyboardSelectComponent(needToEmphasize: false)
            
        } else if !oneHandedModeSelectOverlayView.isHidden {
            let dragLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(dragLocation: dragLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            currentOneHandedMode = selectOneHandedModeOverlay(panDirection: panDirection)
            config.gestureHandler.hideOneHandedModeSelectOverlay()
            switchButton.configureOneHandedComponent(needToEmphasize: false)
        }
    }
    
    func setGestureHandler() -> SwitchButtonGestureHandler {
        let gestureHandler: SwitchButtonGestureHandler
        
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
            gestureHandler.showOneHandedModeSelectOverlay(of: currentOneHandedMode)
            switchButton.configureOneHandedComponent(needToEmphasize: true)
        }
    }
    
    func handleLongPressGestureChanged(_ gesture: UILongPressGestureRecognizer, gestureHandler: SwitchButtonGestureHandler) {
        let switchButton = gestureHandler.switchButton
        let keyboardSelectOverlayView = gestureHandler.keyboardSelectOverlayView
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
        let keyboardSelectOverlayView = gestureHandler.keyboardSelectOverlayView
        let oneHandedModeSelectOverlayView = gestureHandler.oneHandedModeSelectOverlayView
        
        if !oneHandedModeSelectOverlayView.isHidden {
            let dragLocation = gesture.location(in: oneHandedModeSelectOverlayView)
            let panDirection = checkOneHandModePanDirection(dragLocation: dragLocation,
                                                            targetMinX: oneHandedModeSelectOverlayView.leftKeyboardImageContainerView.frame.maxX,
                                                            targetMaxX: oneHandedModeSelectOverlayView.rightKeyboardImageContainerView.frame.minX,
                                                            targetRect: oneHandedModeSelectOverlayView.bounds)
            
            currentOneHandedMode = selectOneHandedModeOverlay(panDirection: panDirection)
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
            return currentOneHandedMode
        }
    }
    
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

// MARK: - Update Methods

private extension KeyboardInputViewController {
    func updateKeyboardLayout() {
        naratgeulKeyboardView.isHidden = (currentKeyboardLayout != .hangeul)
        symbolKeyboardView.isHidden = (currentKeyboardLayout != .symbol)
        numericKeyboardView.isHidden = (currentKeyboardLayout != .numeric)
        tenkeyKeyboardView.isHidden = (currentKeyboardLayout != .tenKey)
    }
    
    func updateKeyboardConstraints() {
        switch currentOneHandedMode {
        case .left, .right:
            keyboardLayoutView.snp.remakeConstraints {
                $0.width.equalTo(UserDefaultsManager.shared.oneHandedKeyboardWidth).priority(.high)
            }
        case .center:
            keyboardLayoutView.snp.removeConstraints()
        }
        leftChevronButton.isHidden = !(currentOneHandedMode == .right)
        rightChevronButton.isHidden = !(currentOneHandedMode == .left)
    }
}

//
//  SymbolKeyboardView.swift
//  Keyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit
import Then

/// 기호 키보드
final class SymbolKeyboardView: UIView, SwitchButtonGestureHandler, TextInteractionButtonGestureHandler {
    
    // MARK: - Properties
    
    private(set) lazy var totalTextInteractionButtonList: [TextInteractionButtonProtocol] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + [deleteButton, spaceButton]
    
    /// 기호 키보드 키 배열
    private let symbolKeyList = [
        [
            [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
            [ ["-"], ["/"], [":"], [";"], ["("], [")"], ["₩"], ["&"], ["@"], ["\""] ],
            [ ["."], [","], ["?"], ["!"], ["'"] ]
        ],
        [
            [ ["["], ["]"], ["{"], ["}"], ["#"], ["%"], ["^"], ["*"], ["+"], ["="] ],
            [ ["_"], ["\\"], ["|"], ["~"], ["<"], [">"], ["$"], ["£"], ["¥"], ["•"] ],
            [ ["."], [","], ["?"], ["!"], ["'"] ]
        ]
    ]
    
    private var isShifted: Bool = false {
        didSet {
            updateKeyButtonList()
            updateSymbolShiftButton()
        }
    }
    
    // MARK: - UI Components
    
    /// 키보드 레이아웃 프레임
    private let layoutVStackView = KeyboardLayoutVStackView()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView()
    /// 키보드 세번째 행
    private let thirdRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView().then {
        $0.distribution = .fill
    }
    /// 키보드 네번째 좌측 `SecondaryButton` 행
    private let fourthRowLeftSecondaryButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `KeyButton` 배열
    private lazy var firstRowKeyButtonList = symbolKeyList[0][0].map { KeyButton(layout: .symbol, button: .keyButton(keys: $0)) }
    /// 키보드 두번째 행 `KeyButton` 배열
    private lazy var secondRowKeyButtonList = symbolKeyList[0][1].map { KeyButton(layout: .symbol, button: .keyButton(keys: $0)) }
    /// 키보드 세번째 행 `KeyButton` 배열
    private lazy var thirdRowKeyButtonList = symbolKeyList[0][2].map { KeyButton(layout: .symbol, button: .keyButton(keys: $0)) }
    
    /// 기호 전환 버튼
    private let symbolShiftButton = SymbolShiftButton(layout: .symbol)
    /// 삭제 버튼
    private(set) var deleteButton = DeleteButton(layout: .symbol)
    /// 키보드 전환 버튼
    private(set) var switchButton = SwitchButton(layout: .symbol)
    /// 스페이스 버튼
    private let spaceButton = SpaceButton(layout: .symbol)
    /// 리턴 버튼
    private let returnButton = ReturnButton(layout: .symbol)
    /// iPhone SE용 키보드 전환 버튼
    private let nextKeyboardButton: NextKeyboardButton
    /// 키보드 레이아웃 선택 UI
    private(set) var keyboardSelectOverlayView = KeyboardSelectOverlayView(layout: .symbol).then { $0.isHidden = true }
    /// 한 손 키보드 선택 UI
    private(set) var oneHandedModeSelectOverlayView = OneHandedModeSelectOverlayView().then { $0.isHidden = true }
    
    // MARK: - Initializer
    
    init(needsInputModeSwitchKey: Bool, nextKeyboardAction: Selector) {
        self.nextKeyboardButton = NextKeyboardButton(layout: .symbol, nextKeyboardAction: nextKeyboardAction)
        super.init(frame: .zero)
        
        nextKeyboardButton.isHidden = !needsInputModeSwitchKey
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Internal Methods
    
    func showKeyboardSelectOverlay(needToEmphasizeTarget: Bool) {
        keyboardSelectOverlayView.configure(needToEmphasizeTarget: needToEmphasizeTarget)
        keyboardSelectOverlayView.isHidden = false
    }
    
    func hideKeyboardSelectOverlay() {
        keyboardSelectOverlayView.isHidden = true
        keyboardSelectOverlayView.resetIsEmphasizingTarget()
    }
    
    func showOneHandedModeSelectOverlay(of mode: OneHandedMode) {
        oneHandedModeSelectOverlayView.configure(emphasizeOf: mode)
        oneHandedModeSelectOverlayView.isHidden = false
    }
    
    func hideOneHandedModeSelectOverlay() {
        oneHandedModeSelectOverlayView.isHidden = true
        oneHandedModeSelectOverlayView.resetLastEmphasizeMode()
    }
}

// MARK: - UI Methods

private extension SymbolKeyboardView {
    func setupUI() {
        setStyles()
        setActions()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setActions() {
        setSymbolShiftButtonAction()
    }
    
    func setHierarchy() {
        self.addSubviews(layoutVStackView,
                         keyboardSelectOverlayView,
                         oneHandedModeSelectOverlayView)
        
        layoutVStackView.addArrangedSubviews(firstRowHStackView,
                                             secondRowHStackView,
                                             thirdRowHStackView,
                                             fourthRowHStackView)
        
        firstRowKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        
        secondRowKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        
        thirdRowHStackView.addArrangedSubview(symbolShiftButton)
        thirdRowKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }
        thirdRowHStackView.addArrangedSubview(deleteButton)
        
        fourthRowHStackView.addArrangedSubviews(fourthRowLeftSecondaryButtonHStackView, spaceButton, returnButton)
        fourthRowLeftSecondaryButtonHStackView.addArrangedSubview(switchButton)
        fourthRowLeftSecondaryButtonHStackView.addArrangedSubview(nextKeyboardButton)
    }
    
    func setConstraints() {
        layoutVStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        fourthRowLeftSecondaryButtonHStackView.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(4)
        }
        
        spaceButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(2)
        }
        
        returnButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(4)
        }
        
        keyboardSelectOverlayView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(4)
            $0.centerY.equalTo(symbolShiftButton)
            $0.width.equalToSuperview().multipliedBy(KeyboardSize.keyboardSelectOverlayWidthMultiplier)
            $0.height.equalTo(symbolShiftButton)
        }
        
        oneHandedModeSelectOverlayView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(4)
            $0.centerY.equalTo(symbolShiftButton)
            $0.width.equalToSuperview().multipliedBy(KeyboardSize.oneHandedModeSelectOverlayWidthMultiplier)
            $0.height.equalTo(symbolShiftButton)
        }
    }
}

// MARK: - Action Methods

private extension SymbolKeyboardView {
    func setSymbolShiftButtonAction() {
        let symbolShiftButtonTouchUpInside = UIAction { [weak self] _ in
            self?.isShifted.toggle()
        }
        symbolShiftButton.addAction(symbolShiftButtonTouchUpInside, for: .touchUpInside)
    }
}

// MARK: - Update Methods

private extension SymbolKeyboardView {
    func updateKeyButtonList() {
        let symbolKeyListIndex = (isShifted ? 1 : 0)
        let rowList = [firstRowKeyButtonList, secondRowKeyButtonList, thirdRowKeyButtonList]
        for (rowIndex, buttonList) in rowList.enumerated() {
            for (buttonIndex, button) in buttonList.enumerated() {
                let keys = symbolKeyList[symbolKeyListIndex][rowIndex][buttonIndex]
                button.update(button: TextInteractionButton.keyButton(keys: keys))
            }
        }
    }
    
    func updateSymbolShiftButton() {
        symbolShiftButton.update(isShifted: isShifted)
    }
}

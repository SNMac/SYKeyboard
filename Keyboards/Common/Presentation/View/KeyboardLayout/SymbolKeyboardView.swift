//
//  SymbolKeyboardView.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

import SnapKit
import Then

/// 기호 키보드
final class SymbolKeyboardView: UIView, SymbolKeyboardLayout {
    
    // MARK: - Properties
    
    private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + [spaceButton, atButton, periodButton, slashButton, dotComButton]
    private(set) lazy var secondaryButtonList: [SecondaryButton] = [shiftButton, deleteButton, switchButton, returnButton, nextKeyboardButton]
    private(set) lazy var totalTextInteractionButtonList: [TextInteractionButton] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList
    + [deleteButton, spaceButton, atButton, periodButton, slashButton, dotComButton, returnButton]
    
    var currentSymbolKeyboardMode: SymbolKeyboardMode = .default {
        didSet(oldMode) {
            updateLayoutForCurrentSymbolKeyboardMode(oldMode: oldMode)
            isShifted = false
        }
    }
    
    var isShifted: Bool = false {
        didSet {
            shiftButton.updateShiftState(to: isShifted)
            updateKeyButtonList()
        }
    }
    var wasShifted: Bool = false
    
    // MARK: - UI Components
    
    /// 키보드 레이아웃 수직 스택
    private let layoutVStackView = KeyboardLayoutVStackView()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView()
    /// 키보드 세번째 행
    private let thirdRowHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    /// 키보드 세번째 내부 행
    private let thirdRowInsideHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    private(set) var fourthRowLeftSecondaryButtonHStackView = KeyboardRowHStackView()
    private(set) var spaceButtonHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    
    /// 키보드 첫번째 행 `PrimaryButton` 배열
    private lazy var firstRowKeyButtonList = currentSymbolKeyboardMode.keyList[0][0].map { PrimaryKeyButton(keyboard: .symbol, button: .keyButton(keys: $0)) }
    /// 키보드 두번째 행 `PrimaryButton` 배열
    private lazy var secondRowKeyButtonList = currentSymbolKeyboardMode.keyList[0][1].map { PrimaryKeyButton(keyboard: .symbol, button: .keyButton(keys: $0)) }
    /// 키보드 세번째 행 `PrimaryButton` 배열
    private lazy var thirdRowKeyButtonList = currentSymbolKeyboardMode.keyList[0][2].map { PrimaryKeyButton(keyboard: .symbol, button: .keyButton(keys: $0)) }
    
    private(set) var shiftButton = ShiftButton(keyboard: .symbol)
    private(set) var deleteButton = DeleteButton(keyboard: .symbol)
    private(set) var switchButton = SwitchButton(keyboard: .symbol)
    
    // 스페이스 버튼 위치
    private(set) var spaceButton = SpaceButton(keyboard: .symbol)
    private(set) var atButton = PrimaryKeyButton(keyboard: .symbol, button: .keyButton(keys: ["@"]))
    private(set) var periodButton = PrimaryKeyButton(keyboard: .symbol, button: .keyButton(keys: ["."]))
    private(set) var slashButton = PrimaryKeyButton(keyboard: .symbol, button: .keyButton(keys: ["/"]))
    private(set) var dotComButton = PrimaryKeyButton(keyboard: .symbol, button: .keyButton(keys: [".com"]))
    
    private(set) var returnButton = ReturnButton(keyboard: .symbol)
    private(set) var nextKeyboardButton = NextKeyboardButton(keyboard: .symbol)
    
    private(set) var keyboardSelectOverlayView = KeyboardSelectOverlayView(keyboard: .symbol).then { $0.isHidden = true }
    private(set) var oneHandedModeSelectOverlayView = OneHandedModeSelectOverlayView().then { $0.isHidden = true }
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateLayoutToDefault()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        setShiftButtonAction()
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
        
        thirdRowHStackView.addArrangedSubviews(shiftButton, thirdRowInsideHStackView, deleteButton)
        thirdRowKeyButtonList.forEach { thirdRowInsideHStackView.addArrangedSubview($0) }
        
        fourthRowHStackView.addArrangedSubviews(fourthRowLeftSecondaryButtonHStackView, spaceButtonHStackView, returnButton)
        fourthRowLeftSecondaryButtonHStackView.addArrangedSubviews(switchButton, nextKeyboardButton)
        spaceButtonHStackView.addArrangedSubviews(spaceButton, atButton, periodButton, slashButton, dotComButton)
    }
    
    func setConstraints() {
        layoutVStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        shiftButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(6.65)
        }
        
        deleteButton.snp.makeConstraints {
            $0.width.equalTo(shiftButton)
        }
        
        fourthRowLeftSecondaryButtonHStackView.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(4)
        }
        
        spaceButtonHStackView.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(2)
        }
        
        atButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(4)
        }
        periodButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(5)
        }
        slashButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(3)
        }
        dotComButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(3)
        }
        
        keyboardSelectOverlayView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(4)
            $0.centerY.equalTo(shiftButton)
            $0.width.equalToSuperview().multipliedBy(KeyboardSize.keyboardSelectOverlayWidthMultiplier)
            $0.height.equalTo(shiftButton)
        }
        
        oneHandedModeSelectOverlayView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(4)
            $0.centerY.equalTo(shiftButton)
            $0.width.equalToSuperview().multipliedBy(KeyboardSize.oneHandedModeSelectOverlayWidthMultiplier)
            $0.height.equalTo(shiftButton)
        }
    }
}

// MARK: - Action Methods

private extension SymbolKeyboardView {
    func setShiftButtonAction() {
        let enableShift = UIAction { [weak self] _ in
            guard let self else { return }
            wasShifted = isShifted
            isShifted = true
        }
        shiftButton.addAction(enableShift, for: .touchDown)
        
        let disableShift = UIAction { [weak self] _ in
            guard let self else { return }
            if wasShifted {
                isShifted = false
            }
        }
        shiftButton.addAction(disableShift, for: .touchUpInside)
    }
}

// MARK: - Update Methods

private extension SymbolKeyboardView {
    func updateKeyButtonList() {
        let symbolKeyListIndex = (isShifted ? 1 : 0)
        let rowList = [firstRowKeyButtonList, secondRowKeyButtonList, thirdRowKeyButtonList]
        for (rowIndex, buttonList) in rowList.enumerated() {
            for (buttonIndex, button) in buttonList.enumerated() {
                let keys = currentSymbolKeyboardMode.keyList[symbolKeyListIndex][rowIndex][buttonIndex]
                button.update(button: TextInteractionButtonType.keyButton(keys: keys))
            }
        }
    }
}

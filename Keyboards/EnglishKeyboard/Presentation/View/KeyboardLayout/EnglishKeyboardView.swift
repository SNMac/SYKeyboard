//
//  EnglishKeyboardView.swift
//  EnglishKeyboard
//
//  Created by 서동환 on 9/8/25.
//

import UIKit

import SnapKit
import Then

/// 영어 키보드
final class EnglishKeyboardView: UIView, EnglishKeyboardLayout {
    
    // MARK: - Properties
    
    private(set) lazy var totalTextInteractionButtonList: [TextInteractionButtonProtocol] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + [deleteButton, spaceButton]
    
    var currentEnglishKeyboardMode: EnglishKeyboardMode = .default {
        didSet(oldMode) { updateLayoutForCurrentEnglishMode(oldMode: oldMode) }
    }
    
    var isShifted: Bool = false {
        didSet {
            updateShiftButton()
            updateKeyButtonList()
        }
    }
    var wasShiftEnabledOnTouchDown: Bool = false
    
    // MARK: - UI Components
    
    /// 키보드 레이아웃 수직 스택
    private let layoutVStackView = KeyboardLayoutVStackView()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    /// 키보드 세번째 행
    private let thirdRowHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    private(set) var fourthRowLeftSecondaryButtonHStackView = KeyboardRowHStackView()
    private(set) var spaceButtonHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    private(set) var returnButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private lazy var firstRowKeyButtonList = currentEnglishKeyboardMode.keyList[0][0].map { PrimaryKeyButton(layout: .english, button: .keyButton(keys: $0)) }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowKeyButtonList = currentEnglishKeyboardMode.keyList[0][1].map { PrimaryKeyButton(layout: .english, button: .keyButton(keys: $0)) }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private lazy var thirdRowKeyButtonList = currentEnglishKeyboardMode.keyList[0][2].map { PrimaryKeyButton(layout: .english, button: .keyButton(keys: $0)) }
    
    private(set) var shiftButton = ShiftButton(layout: .english)
    private(set) var deleteButton = DeleteButton(layout: .english)
    private(set) var switchButton = SwitchButton(layout: .english)
    
    // 스페이스 버튼 위치
    private(set) var spaceButton = SpaceButton(layout: .english)
    private(set) var atButton = PrimaryKeyButton(layout: .english, button: .keyButton(keys: ["@"]))
    private(set) var periodButton = PrimaryKeyButton(layout: .english, button: .keyButton(keys: ["."]))
    private(set) var slashButton = PrimaryKeyButton(layout: .english, button: .keyButton(keys: ["/"]))
    private(set) var dotComButton = PrimaryKeyButton(layout: .english, button: .keyButton(keys: [".com"]))
    
    // 리턴 버튼 위치
    private(set) var returnButton = ReturnButton(layout: .english)
    private(set) var secondaryAtButton = SecondaryKeyButton(layout: .english, button: .keyButton(keys: ["@"]))
    private(set) var secondarySharpButton = SecondaryKeyButton(layout: .english, button: .keyButton(keys: ["#"]))
    
    private(set) var nextKeyboardButton: NextKeyboardButton
    
    private(set) var keyboardSelectOverlayView = KeyboardSelectOverlayView(layout: .english).then { $0.isHidden = true }
    private(set) var oneHandedModeSelectOverlayView = OneHandedModeSelectOverlayView().then { $0.isHidden = true }
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        self.nextKeyboardButton = NextKeyboardButton(layout: .english)
        self.nextKeyboardButton.isHidden = true
        super.init(frame: frame)
        
        setupUI()
        updateLayoutToDefault()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension EnglishKeyboardView {
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
        
        thirdRowHStackView.addArrangedSubview(shiftButton)
        thirdRowKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }
        thirdRowHStackView.addArrangedSubview(deleteButton)
        
        fourthRowHStackView.addArrangedSubviews(fourthRowLeftSecondaryButtonHStackView, spaceButtonHStackView, returnButtonHStackView)
        fourthRowLeftSecondaryButtonHStackView.addArrangedSubviews(switchButton, nextKeyboardButton)
        spaceButtonHStackView.addArrangedSubviews(spaceButton, atButton, periodButton, slashButton, dotComButton)
        returnButtonHStackView.addArrangedSubviews(returnButton, secondaryAtButton, secondarySharpButton)
    }
    
    func setConstraints() {
        layoutVStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        for (index, button) in secondRowKeyButtonList.enumerated() {
            if index == 0 {
                if let lastButton = secondRowKeyButtonList.last {
                    button.snp.makeConstraints {
                        $0.width.equalTo(lastButton)
                    }
                }
            } else if index == secondRowKeyButtonList.count - 1 {
                continue
            } else {
                button.snp.makeConstraints {
                    $0.width.equalToSuperview().dividedBy(firstRowKeyButtonList.count)
                }
            }
        }
        
        shiftButton.snp.makeConstraints {
            $0.width.equalTo(deleteButton)
        }
        
        thirdRowKeyButtonList.forEach { button in
            button.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(firstRowKeyButtonList.count)
            }
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

private extension EnglishKeyboardView {
    func setShiftButtonAction() {
        let shiftButtonEnabled = UIAction { [weak self] _ in
            guard let self else { return }
            wasShiftEnabledOnTouchDown = isShifted
            if !wasShiftEnabledOnTouchDown {
                isShifted = true
            }
        }
        shiftButton.addAction(shiftButtonEnabled, for: .touchDown)
        
        let shiftButtonDisabled = UIAction { [weak self] _ in
            guard let self else { return }
            if wasShiftEnabledOnTouchDown {
                isShifted = false
            }
        }
        shiftButton.addAction(shiftButtonDisabled, for: .touchUpInside)
    }
}

// MARK: - Update Methods

private extension EnglishKeyboardView {
    func updateKeyButtonList() {
        let englishKeyListIndex = (isShifted ? 1 : 0)
        let rowList = [firstRowKeyButtonList, secondRowKeyButtonList, thirdRowKeyButtonList]
        for (rowIndex, buttonList) in rowList.enumerated() {
            for (buttonIndex, button) in buttonList.enumerated() {
                let keys = currentEnglishKeyboardMode.keyList[englishKeyListIndex][rowIndex][buttonIndex]
                button.update(button: TextInteractionButton.keyButton(keys: keys))
            }
        }
    }
    
    func updateShiftButton() {
        shiftButton.update(isShifted: isShifted)
    }
}

//
//  QwertyKeyboardView.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 9/12/25.
//

import UIKit

import SnapKit
import Then

class QwertyKeyboardView: UIView {
    
    // MARK: - Properties
    
    /// 키보드 종류
    var keyboard: SYKeyboardType { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 키 배열
    var keyList: [[[[String]]]] { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    
    private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + [spaceButton, atButton, periodButton, slashButton, dotComButton]
    private(set) lazy var secondaryButtonList: [SecondaryButton] = [shiftButton, deleteButton, switchButton, returnButton, secondaryAtButton, secondarySharpButton, nextKeyboardButton]
    private(set) lazy var totalTextInterableButtonList: [TextInteractable] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList
    + [deleteButton, spaceButton, atButton, periodButton, slashButton, dotComButton, returnButton, secondaryAtButton, secondarySharpButton]
    
    final var isShifted: Bool = false {
        didSet {
            shiftButton.updateShiftState(to: isShifted)
            updateKeyButtonList()
        }
    }
    final var wasShifted: Bool = false
    
    // MARK: - UI Components
    
    /// 키보드 레이아웃 수직 스택
    private let keyboardVStackView = KeyboardLayoutVStackView()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    /// 키보드 세번째 행
    private let thirdRowHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    /// 키보드 세번째 내부 행
    private let thirdRowInsideHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    private(set) var fourthRowLeftSecondaryButtonHStackView = KeyboardRowHStackView()
    private(set) var spaceButtonHStackView = KeyboardRowHStackView().then { $0.distribution = .fill }
    private(set) var returnButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `PrimaryButton` 배열
    private lazy var firstRowKeyButtonList = keyList[0][0].map { PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: $0)) }
    /// 키보드 두번째 행 `PrimaryButton` 배열
    private lazy var secondRowKeyButtonList = keyList[0][1].map { PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: $0)) }
    /// 키보드 세번째 행 `PrimaryButton` 배열
    private lazy var thirdRowKeyButtonList = keyList[0][2].map { PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: $0)) }
    
    private(set) lazy var shiftButton = ShiftButton(keyboard: keyboard)
    private(set) lazy var deleteButton = DeleteButton(keyboard: keyboard)
    private(set) lazy var switchButton = SwitchButton(keyboard: keyboard)
    
    // 스페이스 버튼 위치
    private(set) lazy var spaceButton = SpaceButton(keyboard: keyboard)
    private(set) lazy var atButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["@"]))
    private(set) lazy var periodButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["."]))
    private(set) lazy var slashButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["/"]))
    private(set) lazy var dotComButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: [".com"]))
    
    // 리턴 버튼 위치
    private(set) lazy var returnButton = ReturnButton(keyboard: keyboard)
    private(set) lazy var secondaryAtButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["@"]))
    private(set) lazy var secondarySharpButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["#"]))
    
    private(set) lazy var nextKeyboardButton = NextKeyboardButton(keyboard: keyboard)
    
    private(set) lazy var keyboardSelectOverlayView = KeyboardSelectOverlayView(keyboard: keyboard).then { $0.isHidden = true }
    private(set) var oneHandedModeSelectOverlayView = OneHandedModeSelectOverlayView().then { $0.isHidden = true }
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overridable Methods
    
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

// MARK: - UI Methods

private extension QwertyKeyboardView {
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
        self.addSubviews(keyboardVStackView,
                         keyboardSelectOverlayView,
                         oneHandedModeSelectOverlayView)
        
        keyboardVStackView.addArrangedSubviews(firstRowHStackView,
                                               secondRowHStackView,
                                               thirdRowHStackView,
                                               fourthRowHStackView)
        
        firstRowKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        
        secondRowKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        
        thirdRowHStackView.addArrangedSubviews(shiftButton, thirdRowInsideHStackView, deleteButton)
        thirdRowKeyButtonList.forEach { thirdRowInsideHStackView.addArrangedSubview($0) }
        
        fourthRowHStackView.addArrangedSubviews(fourthRowLeftSecondaryButtonHStackView, spaceButtonHStackView, returnButtonHStackView)
        fourthRowLeftSecondaryButtonHStackView.addArrangedSubviews(switchButton, nextKeyboardButton)
        spaceButtonHStackView.addArrangedSubviews(spaceButton, atButton, periodButton, slashButton, dotComButton)
        returnButtonHStackView.addArrangedSubviews(returnButton, secondaryAtButton, secondarySharpButton)
    }
    
    func setConstraints() {
        keyboardVStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        guard let referenceKey = firstRowKeyButtonList.first else { fatalError("firstRowKeyButtonList가 비어있습니다.") }
        for (index, button) in secondRowKeyButtonList.enumerated() {
            if index == 0 {
                guard let lastButton = secondRowKeyButtonList.last else { fatalError("secondRowKeyButtonList가 비어있습니다.") }
                button.snp.makeConstraints {
                    $0.width.equalTo(lastButton)
                }
                button.updateKeyAlignment(.right, referenceKey: referenceKey)
            } else if index == secondRowKeyButtonList.count - 1 {
                button.updateKeyAlignment(.left, referenceKey: referenceKey)
            } else {
                button.snp.makeConstraints {
                    $0.width.equalToSuperview().dividedBy(firstRowKeyButtonList.count)
                }
            }
        }
        
        shiftButton.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(KeyboardLayoutFigure.shiftAndDeleteButtonDivider)
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
            $0.width.equalToSuperview().multipliedBy(KeyboardLayoutFigure.keyboardSelectOverlayWidthMultiplier)
            $0.height.equalTo(shiftButton)
        }
        
        oneHandedModeSelectOverlayView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(4)
            $0.centerY.equalTo(shiftButton)
            $0.width.equalToSuperview().multipliedBy(KeyboardLayoutFigure.oneHandedModeSelectOverlayWidthMultiplier)
            $0.height.equalTo(shiftButton)
        }
    }
}

// MARK: - Update Methods

extension QwertyKeyboardView {
    final func updateKeyButtonList() {
        let keyListIndex = (isShifted ? 1 : 0)
        let rowList = [firstRowKeyButtonList, secondRowKeyButtonList, thirdRowKeyButtonList]
        for (rowIndex, buttonList) in rowList.enumerated() {
            for (buttonIndex, button) in buttonList.enumerated() {
                let keys = keyList[keyListIndex][rowIndex][buttonIndex]
                button.update(buttonType: TextInteractableType.keyButton(keys: keys))
            }
        }
    }
}

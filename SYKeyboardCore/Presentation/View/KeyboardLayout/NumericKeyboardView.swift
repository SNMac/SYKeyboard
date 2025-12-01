//
//  NumericKeyboardView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

/// 숫자 키보드
final class NumericKeyboardView: UIView, NumericKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    public private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    public private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + fourthRowKeyButtonList + [spaceButton]
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [deleteButton, returnButton, switchButton, nextKeyboardButton]
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + fourthRowKeyButtonList + [deleteButton, spaceButton, returnButton]
    
    /// 숫자 키보드 키 배열
    private let numericKeyList = [
        [ ["1"], ["2"], ["3"] ],
        [ ["4"], ["5"], ["6"] ],
        [ ["7"], ["8"], ["9"] ],
        [ ["-"], [","], ["0"], ["."], ["/"] ]
    ]
    
    // MARK: - UI Components
    
    /// 상단 여백
    private let topSpacer = KeyboardSpacer()
    /// 키보드 레이아웃 수직 스택
    private let layoutVStackView = KeyboardLayoutVStackView()
    /// 하단 여백
    private let bottomSpacer = KeyboardSpacer()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView()
    /// 키보드 세번째 행
    private let thirdRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 좌측 `PrimaryKeyButton` 행
    private let fourthRowLeftPrimaryButtonHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 우측 `PrimaryKeyButton` 행
    private let fourthRowRightPrimaryButtonHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 우측 `SecondaryButton` 행
    private let fourthRowRightSecondaryButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private lazy var firstRowKeyButtonList = numericKeyList[0].map { PrimaryKeyButton(keyboard: .numeric, button: .keyButton(primary: $0, secondary: nil)) }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowKeyButtonList = numericKeyList[1].map { PrimaryKeyButton(keyboard: .numeric, button: .keyButton(primary: $0, secondary: nil)) }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private lazy var thirdRowKeyButtonList = numericKeyList[2].map { PrimaryKeyButton(keyboard: .numeric, button: .keyButton(primary: $0, secondary: nil)) }
    /// 키보드 네번째 행 `PrimaryKeyButton` 배열
    private lazy var fourthRowKeyButtonList = numericKeyList[3].map { PrimaryKeyButton(keyboard: .numeric, button: .keyButton(primary: $0, secondary: nil)) }
    
    public private(set) var deleteButton = DeleteButton(keyboard: .numeric)
    public private(set) var spaceButton = SpaceButton(keyboard: .numeric)
    public private(set) var returnButton = ReturnButton(keyboard: .numeric)
    public private(set) var switchButton = SwitchButton(keyboard: .numeric)
    public private(set) var nextKeyboardButton = NextKeyboardButton(keyboard: .numeric)
    
    private(set) var keyboardSelectOverlayView: KeyboardSelectOverlayView = {
        let overlayView = KeyboardSelectOverlayView(keyboard: .numeric)
        overlayView.isHidden = true
        
        return overlayView
    }()
    private(set) var oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView = {
        let overlayView = OneHandedModeSelectOverlayView()
        overlayView.isHidden = true
        
        return overlayView
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension NumericKeyboardView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setHierarchy() {
        [topSpacer,
         layoutVStackView,
         bottomSpacer,
         keyboardSelectOverlayView,
         oneHandedModeSelectOverlayView].forEach { self.addSubview($0) }
        
        [firstRowHStackView,
         secondRowHStackView,
         thirdRowHStackView,
         fourthRowHStackView].forEach { layoutVStackView.addArrangedSubview($0) }
        
        firstRowKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        firstRowHStackView.addArrangedSubview(deleteButton)
        
        secondRowKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        secondRowHStackView.addArrangedSubview(spaceButton)
        
        thirdRowKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }
        thirdRowHStackView.addArrangedSubview(returnButton)
        
        [fourthRowLeftPrimaryButtonHStackView,
         fourthRowKeyButtonList[2],
         fourthRowRightPrimaryButtonHStackView,
         fourthRowRightSecondaryButtonHStackView].forEach { fourthRowHStackView.addArrangedSubview($0) }
        
        [fourthRowKeyButtonList[0], fourthRowKeyButtonList[1]].forEach { fourthRowLeftPrimaryButtonHStackView.addArrangedSubview($0) }
        [fourthRowKeyButtonList[3], fourthRowKeyButtonList[4]].forEach { fourthRowRightPrimaryButtonHStackView.addArrangedSubview($0) }
        fourthRowRightSecondaryButtonHStackView.addArrangedSubview(nextKeyboardButton)
        fourthRowRightSecondaryButtonHStackView.addArrangedSubview(switchButton)
    }
    
    func setConstraints() {
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topSpacer.topAnchor.constraint(equalTo: self.topAnchor),
            topSpacer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            topSpacer.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            topSpacer.heightAnchor.constraint(equalToConstant: 2)
        ])
        
        layoutVStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layoutVStackView.topAnchor.constraint(equalTo: topSpacer.bottomAnchor),
            layoutVStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            layoutVStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            layoutVStackView.bottomAnchor.constraint(equalTo: bottomSpacer.topAnchor)
        ])
        
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomSpacer.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            bottomSpacer.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 2)
        ])
        
        keyboardSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboardSelectOverlayView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
            keyboardSelectOverlayView.centerYAnchor.constraint(equalTo: returnButton.centerYAnchor),
            keyboardSelectOverlayView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: KeyboardLayoutFigure.keyboardSelectOverlayWidthMultiplier),
            keyboardSelectOverlayView.heightAnchor.constraint(equalTo: returnButton.heightAnchor)
        ])
        
        oneHandedModeSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            oneHandedModeSelectOverlayView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
            oneHandedModeSelectOverlayView.centerYAnchor.constraint(equalTo: returnButton.centerYAnchor),
            oneHandedModeSelectOverlayView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: KeyboardLayoutFigure.oneHandedModeSelectOverlayWidthMultiplier),
            oneHandedModeSelectOverlayView.heightAnchor.constraint(equalTo: returnButton.heightAnchor)
        ])
    }
}

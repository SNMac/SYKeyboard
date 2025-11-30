//
//  FourByFourKeyboardView.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 9/12/25.
//

import UIKit

import SYKeyboardCore

class FourByFourKeyboardView: UIView, HangeulKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + fourthRowKeyButtonList + [spaceButton]
    private(set) lazy var secondaryButtonList: [SecondaryButton] = [deleteButton, returnButton, secondaryAtButton, secondarySharpButton, switchButton, nextKeyboardButton]
    private(set) lazy var totalTextInterableButtonList: [TextInteractable] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + fourthRowKeyButtonList
    + [deleteButton, spaceButton, returnButton, secondaryAtButton, secondarySharpButton]
    
    final var currentHangeulKeyboardMode: HangeulKeyboardMode = .default {
        didSet(oldMode) { updateLayoutForCurrentHangeulMode(oldMode: oldMode) }
    }
    
    final let keyboard: SYKeyboardType
    /// 한글 키 배열
    var hangeulKeyList: [[[String]]] { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 숫자 키 배열 (한글 키 보조)
    var numberKeyList: [[[String]]] {
        [
            [ ["1"], ["2"], ["3"] ],
            [ ["4"], ["5"], ["6"] ],
            [ ["7"], ["8"], ["9"] ],
            [ [""], ["0"], [""] ]
        ]
    }
    
    // MARK: - UI Components
    
    /// 상단 여백
    private let topSpacer = KeyboardSpacer()
    /// 키보드 레이아웃 수직 스택
    private let layoutVStackView = KeyboardLayoutVStackView()
    /// 하단 여백 `KeyboardSpacer`
    private let bottomSpacer = KeyboardSpacer()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView()
    /// 키보드 세번째 행
    private let thirdRowHStackView = KeyboardRowHStackView()
    /// 리턴 버튼 행
    private(set) var returnButtonHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 우측 `SecondaryButton` 행
    private let fourthRowRightSecondaryButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `PrimaryButton` 배열
    private lazy var firstRowKeyButtonList = zip(hangeulKeyList[0], numberKeyList[0]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 두번째 행 `PrimaryButton` 배열
    private lazy var secondRowKeyButtonList = zip(hangeulKeyList[1], numberKeyList[1]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 세번째 행 `PrimaryButton` 배열
    private lazy var thirdRowKeyButtonList = zip(hangeulKeyList[2], numberKeyList[2]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 네번째 행 `PrimaryButton` 배열
    private lazy var fourthRowKeyButtonList = zip(hangeulKeyList[3], numberKeyList[3]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    
    private(set) lazy var deleteButton = DeleteButton(keyboard: keyboard)
    private(set) lazy var spaceButton = SpaceButton(keyboard: keyboard)
    
    // 리턴 버튼 위치
    private(set) lazy var returnButton = ReturnButton(keyboard: keyboard)
    private(set) lazy var secondaryAtButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(primary: ["@"], secondary: nil))
    private(set) lazy var secondarySharpButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(primary: ["#"], secondary: nil))
    
    private(set) lazy var switchButton = SwitchButton(keyboard: keyboard)
    private(set) lazy var nextKeyboardButton = NextKeyboardButton(keyboard: keyboard)
    
    private(set) lazy var keyboardSelectOverlayView: KeyboardSelectOverlayView = {
        let overlayView = KeyboardSelectOverlayView(keyboard: keyboard)
        overlayView.isHidden = true
        
        return overlayView
    }()
    private(set) lazy var oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView = {
        let overlayView = OneHandedModeSelectOverlayView()
        overlayView.isHidden = true
        
        return overlayView
    }()
    
    // MARK: - Initializer
    
    init(keyboard: SYKeyboardType) {
        self.keyboard = keyboard
        super.init(frame: .zero)
        
        setupUI()
        updateLayoutToDefault()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension FourByFourKeyboardView {
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
        [returnButton, secondaryAtButton, secondarySharpButton].forEach { returnButtonHStackView.addArrangedSubview($0) }
        thirdRowHStackView.addArrangedSubview(returnButtonHStackView)
        
        fourthRowKeyButtonList.forEach { fourthRowHStackView.addArrangedSubview($0) }
        fourthRowHStackView.addArrangedSubview(fourthRowRightSecondaryButtonHStackView)
        [nextKeyboardButton, switchButton].forEach { fourthRowRightSecondaryButtonHStackView.addArrangedSubview($0) }
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

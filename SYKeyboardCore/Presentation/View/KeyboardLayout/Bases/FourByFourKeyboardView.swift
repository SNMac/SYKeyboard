//
//  FourByFourKeyboardView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/12/25.
//

import UIKit

open class FourByFourKeyboardView: UIView {
    
    // MARK: - Properties
    
    /// 키보드 종류
    open var keyboard: SYKeyboardType { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 키 배열
    open var primaryKeyList: [[[String]]] { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 보조 키 배열
    open var secondaryKeyList: [[[String]]] { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    
    public private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    public private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + fourthRowPrimaryKeyButtonList + [spaceButton]
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [deleteButton, returnButton, secondaryAtButton, secondarySharpButton, switchButton, nextKeyboardButton]
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + fourthRowPrimaryKeyButtonList
    + [deleteButton, spaceButton, returnButton, secondaryAtButton, secondarySharpButton]
    
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
    public private(set) var returnButtonHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 우측 `SecondaryButton` 행
    private let fourthRowRightSecondaryButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private lazy var firstRowPrimaryKeyButtonList = zip(primaryKeyList[0], secondaryKeyList[0]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowPrimaryKeyButtonList = zip(primaryKeyList[1], secondaryKeyList[1]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private lazy var thirdRowPrimaryKeyButtonList = zip(primaryKeyList[2], secondaryKeyList[2]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 네번째 행 `PrimaryKeyButton` 배열
    private lazy var fourthRowPrimaryKeyButtonList = zip(primaryKeyList[3], secondaryKeyList[3]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    
    public private(set) lazy var deleteButton = DeleteButton(keyboard: keyboard)
    public private(set) lazy var spaceButton = SpaceButton(keyboard: keyboard)
    
    // 리턴 버튼 위치
    public private(set) lazy var returnButton = ReturnButton(keyboard: keyboard)
    public private(set) lazy var secondaryAtButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(primary: ["@"], secondary: nil))
    public private(set) lazy var secondarySharpButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(primary: ["#"], secondary: nil))
    
    public  private(set) lazy var switchButton = SwitchButton(keyboard: keyboard)
    public  private(set) lazy var nextKeyboardButton = NextKeyboardButton(keyboard: keyboard)
    
    public  private(set) lazy var keyboardSelectOverlayView: KeyboardSelectOverlayView = {
        let overlayView = KeyboardSelectOverlayView(keyboard: keyboard)
        overlayView.isHidden = true
        
        return overlayView
    }()
    public  private(set) lazy var oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView = {
        let overlayView = OneHandedModeSelectOverlayView()
        overlayView.isHidden = true
        
        return overlayView
    }()
    
    // MARK: - Initializer
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
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
        
        firstRowPrimaryKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        firstRowHStackView.addArrangedSubview(deleteButton)
        
        secondRowPrimaryKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        secondRowHStackView.addArrangedSubview(spaceButton)
        
        thirdRowPrimaryKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }
        [returnButton, secondaryAtButton, secondarySharpButton].forEach { returnButtonHStackView.addArrangedSubview($0) }
        thirdRowHStackView.addArrangedSubview(returnButtonHStackView)
        
        fourthRowPrimaryKeyButtonList.forEach { fourthRowHStackView.addArrangedSubview($0) }
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

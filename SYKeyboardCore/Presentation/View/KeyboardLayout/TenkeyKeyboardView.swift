//
//  TenkeyKeyboardView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/14/25.
//

import UIKit

/// 텐키 키보드
final class TenkeyKeyboardView: UIView, TenkeyKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    public private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    public private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + fourthRowKeyButtonList
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [periodButton, deleteButton]
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + fourthRowKeyButtonList
    + [periodButton, deleteButton]
    
    public var currentTenkeyKeyboardMode: TenkeyKeyboardMode = .numberPad {
        didSet(oldMode) { updateLayoutForCurrentTenkeyKeyboardMode(oldMode: oldMode) }
    }
    
    /// 텐키 키보드 키 배열
    private let tenKeyList = [
        [ ["1"], ["2"], ["3"] ],
        [ ["4"], ["5"], ["6"] ],
        [ ["7"], ["8"], ["9"] ],
        [ ["0"] ]
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
    
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private lazy var firstRowPrimaryKeyButtonList = tenKeyList[0].map { PrimaryKeyButton(keyboard: .tenKey, button: .keyButton(primary: $0, secondary: nil)) }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowPrimaryKeyButtonList = tenKeyList[1].map { PrimaryKeyButton(keyboard: .tenKey, button: .keyButton(primary: $0, secondary: nil)) }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private lazy var thirdRowPrimaryKeyButtonList = tenKeyList[2].map { PrimaryKeyButton(keyboard: .tenKey, button: .keyButton(primary: $0, secondary: nil)) }
    /// 키보드 네번째 행 `PrimaryKeyButton` 배열
    private lazy var fourthRowKeyButtonList = tenKeyList[3].map { PrimaryKeyButton(keyboard: .tenKey, button: .keyButton(primary: $0, secondary: nil)) }
    
    public private(set) var bottomLeftButtonSpacer = KeyboardSpacer()
    public private(set) var periodButton = SecondaryKeyButton(keyboard: .tenKey, button: .keyButton(primary: ["."], secondary: nil))
    public private(set) var deleteButton = DeleteButton(keyboard: .tenKey)
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateLayoutToNumberPad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension TenkeyKeyboardView {
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
         bottomSpacer].forEach { self.addSubview($0) }
        
        [firstRowHStackView,
         secondRowHStackView,
         thirdRowHStackView,
         fourthRowHStackView].forEach { layoutVStackView.addArrangedSubview($0) }
        
        firstRowPrimaryKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        
        secondRowPrimaryKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        
        thirdRowPrimaryKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }
        
        [bottomLeftButtonSpacer, periodButton].forEach { fourthRowHStackView.addArrangedSubview($0) }
        fourthRowKeyButtonList.forEach { fourthRowHStackView.addArrangedSubview($0) }
        fourthRowHStackView.addArrangedSubview(deleteButton)
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
    }
}

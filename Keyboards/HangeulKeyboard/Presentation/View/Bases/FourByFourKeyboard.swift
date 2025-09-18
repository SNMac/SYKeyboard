//
//  FourByFourKeyboard.swift
//  HangeulKeyboard
//
//  Created by 서동환 on 9/12/25.
//

import UIKit

import SnapKit
import Then

class FourByFourKeyboard: UIView, HangeulKeyboardLayout {
    
    // MARK: - Properties
    
    private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + fourthRowKeyButtonList + [spaceButton]
    private(set) lazy var secondaryButtonList: [SecondaryButton] = [deleteButton, returnButton, secondaryAtButton, secondarySharpButton, switchButton, nextKeyboardButton]
    private(set) lazy var totalTextInteractionButtonList: [TextInteractionButton] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + fourthRowKeyButtonList
    + [deleteButton, spaceButton, returnButton, secondaryAtButton, secondarySharpButton]
    
    final var currentHangeulKeyboardMode: HangeulKeyboardMode = .default {
        didSet(oldMode) { updateLayoutForCurrentHangeulMode(oldMode: oldMode) }
    }
    
    /// 한글 키 배열
    var hangeulKeyList: [[[String]]] { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    
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
    private(set) var returnButtonHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 우측 `SecondaryButton` 행
    private let fourthRowRightSecondaryButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `PrimaryButton` 배열
    private lazy var firstRowKeyButtonList = hangeulKeyList[0].map { PrimaryKeyButton(keyboard: .hangeul, button: .keyButton(keys: $0)) }
    /// 키보드 두번째 행 `PrimaryButton` 배열
    private lazy var secondRowKeyButtonList = hangeulKeyList[1].map { PrimaryKeyButton(keyboard: .hangeul, button: .keyButton(keys: $0)) }
    /// 키보드 세번째 행 `PrimaryButton` 배열
    private lazy var thirdRowKeyButtonList = hangeulKeyList[2].map { PrimaryKeyButton(keyboard: .hangeul, button: .keyButton(keys: $0)) }
    /// 키보드 네번째 행 `PrimaryButton` 배열
    private lazy var fourthRowKeyButtonList = hangeulKeyList[3].map { PrimaryKeyButton(keyboard: .hangeul, button: .keyButton(keys: $0)) }
    
    private(set) var deleteButton = DeleteButton(keyboard: .hangeul)
    private(set) var spaceButton = SpaceButton(keyboard: .hangeul)
    
    // 리턴 버튼 위치
    private(set) var returnButton = ReturnButton(keyboard: .hangeul)
    private(set) var secondaryAtButton = SecondaryKeyButton(keyboard: .hangeul, button: .keyButton(keys: ["@"]))
    private(set) var secondarySharpButton = SecondaryKeyButton(keyboard: .hangeul, button: .keyButton(keys: ["#"]))
    
    private(set) var switchButton = SwitchButton(keyboard: .hangeul)
    private(set) var nextKeyboardButton = NextKeyboardButton(keyboard: .hangeul)
    
    private(set) var keyboardSelectOverlayView = KeyboardSelectOverlayView(keyboard: .hangeul).then { $0.isHidden = true }
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

private extension FourByFourKeyboard {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setHierarchy() {
        self.addSubviews(topSpacer,
                         layoutVStackView,
                         bottomSpacer,
                         keyboardSelectOverlayView,
                         oneHandedModeSelectOverlayView)
        
        layoutVStackView.addArrangedSubviews(firstRowHStackView,
                                             secondRowHStackView,
                                             thirdRowHStackView,
                                             fourthRowHStackView)
        
        firstRowKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        firstRowHStackView.addArrangedSubview(deleteButton)
        
        secondRowKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        secondRowHStackView.addArrangedSubview(spaceButton)
        
        thirdRowKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }
        returnButtonHStackView.addArrangedSubviews(returnButton, secondaryAtButton, secondarySharpButton)
        thirdRowHStackView.addArrangedSubview(returnButtonHStackView)
        
        fourthRowKeyButtonList.forEach { fourthRowHStackView.addArrangedSubview($0) }
        fourthRowHStackView.addArrangedSubview(fourthRowRightSecondaryButtonHStackView)
        fourthRowRightSecondaryButtonHStackView.addArrangedSubviews(nextKeyboardButton, switchButton)
    }
    
    func setConstraints() {
        topSpacer.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        layoutVStackView.snp.makeConstraints {
            $0.top.equalTo(topSpacer.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomSpacer.snp.top)
        }
        
        bottomSpacer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        keyboardSelectOverlayView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(4)
            $0.centerY.equalTo(returnButton)
            $0.width.equalToSuperview().multipliedBy(KeyboardSize.keyboardSelectOverlayWidthMultiplier)
            $0.height.equalTo(returnButton)
        }
        
        oneHandedModeSelectOverlayView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(4)
            $0.centerY.equalTo(returnButton)
            $0.width.equalToSuperview().multipliedBy(KeyboardSize.oneHandedModeSelectOverlayWidthMultiplier)
            $0.height.equalTo(returnButton)
        }
    }
}

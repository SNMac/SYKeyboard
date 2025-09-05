//
//  NaratgeulKeyboardView.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit
import Then

/// 나랏글 키보드
final class NaratgeulKeyboardView: UIView, HangeulKeyboardLayout {
    
    // MARK: - Properties
    
    private(set) lazy var totalTextInteractionButtonList: [TextInteractionButtonProtocol] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + fourthRowKeyButtonList + [deleteButton, spaceButton]
    
    var currentHangeulKeyboardMode: HangeulKeyboardMode = .default
    
    /// 나랏글 키보드 키 배열
    private let naratgeulKeyList = [
        [ ["ㄱ"], ["ㄴ"], ["ㅏ", "ㅓ"] ],
        [ ["ㄹ"], ["ㅁ"], ["ㅗ", "ㅜ"] ],
        [ ["ㅅ"], ["ㅇ"], ["ㅣ"] ],
        [ ["획"], ["ㅡ"], ["쌍"] ]
    ]
    
    // MARK: - UI Components
    
    /// 상단 여백
    private let topSpacer = KeyboardSpacer()
    /// 키보드 레이아웃 프레임
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
    
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private lazy var firstRowKeyButtonList = naratgeulKeyList[0].map { PrimaryKeyButton(layout: .hangeul, button: .keyButton(keys: $0)) }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowKeyButtonList = naratgeulKeyList[1].map { PrimaryKeyButton(layout: .hangeul, button: .keyButton(keys: $0)) }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private lazy var thirdRowKeyButtonList = naratgeulKeyList[2].map { PrimaryKeyButton(layout: .hangeul, button: .keyButton(keys: $0)) }
    /// 키보드 네번째 행 `PrimaryKeyButton` 배열
    private lazy var fourthRowKeyButtonList = naratgeulKeyList[3].map { PrimaryKeyButton(layout: .hangeul, button: .keyButton(keys: $0)) }
    
    private(set) var deleteButton = DeleteButton(layout: .hangeul)
    private(set) var spaceButton = SpaceButton(layout: .hangeul)
    
    private(set) var returnButton = ReturnButton(layout: .hangeul)
    private(set) var secondaryAtButton = SecondaryKeyButton(layout: .hangeul, button: .keyButton(keys: ["@"])).then { $0.isHidden = true }
    private(set) var secondarySharpButton = SecondaryKeyButton(layout: .hangeul, button: .keyButton(keys: ["#"])).then { $0.isHidden = true }
    
    private(set) var switchButton = SwitchButton(layout: .hangeul)
    private(set) var nextKeyboardButton: NextKeyboardButton
    
    private(set) var keyboardSelectOverlayView = KeyboardSelectOverlayView(layout: .hangeul).then { $0.isHidden = true }
    private(set) var oneHandedModeSelectOverlayView = OneHandedModeSelectOverlayView().then { $0.isHidden = true }
    
    // MARK: - Initializer
    
    init(needsInputModeSwitchKey: Bool, nextKeyboardAction: Selector) {
        self.nextKeyboardButton = NextKeyboardButton(layout: .hangeul, nextKeyboardAction: nextKeyboardAction)
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

private extension NaratgeulKeyboardView {
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

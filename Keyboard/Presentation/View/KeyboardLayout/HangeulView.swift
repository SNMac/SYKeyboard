//
//  HangeulView.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

import SnapKit

/// 한글 키보드
final class HangeulView: UIView {
    
    // MARK: - Properties
    
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
    /// 키보드 전체 프레임
    private let frameStackView = KeyboardFrameStackView()
    /// 하단 여백 `KeyboardSpacer`
    private let bottomSpacer = KeyboardSpacer()
    
    /// 키보드 첫번째 행
    private let firstRowStackView = KeyboardRowStackView()
    /// 키보드 두번째 행
    private let secondRowStackView = KeyboardRowStackView()
    /// 키보드 세번째 행
    private let thirdRowStackView = KeyboardRowStackView()
    /// 키보드 네번째 행
    private let fourthRowStackView = KeyboardRowStackView()
    /// 키보드 네번째 우측 `SecondaryButton` 행
    private let fourthRowRightSecondaryButtonStackView = KeyboardRowStackView()
    
    /// 키보드 첫번째 행 `KeyButton` 배열
    private lazy var firstRowKeyButtonList = naratgeulKeyList[0].map { KeyButton(layout: .hangeul, keys: $0) }
    /// 키보드 두번째 행 `KeyButton` 배열
    private lazy var secondRowKeyButtonList = naratgeulKeyList[1].map { KeyButton(layout: .hangeul, keys: $0) }
    /// 키보드 세번째 행 `KeyButton` 배열
    private lazy var thirdRowKeyButtonList = naratgeulKeyList[2].map { KeyButton(layout: .hangeul, keys: $0) }
    /// 키보드 네번째 행 `KeyButton` 배열
    private lazy var fourthRowKeyButtonList = naratgeulKeyList[3].map { KeyButton(layout: .hangeul, keys: $0) }
    
    /// 삭제 버튼
    private let deleteButton = DeleteButton(layout: .hangeul)
    /// 스페이스 버튼
    private let spaceButton = SpaceButton(layout: .hangeul)
    /// 리턴 버튼
    private let returnButton = ReturnButton(layout: .hangeul)
    /// 키보드 전환 버튼
    private(set) var switchButton = SwitchButton(layout: .hangeul)
    /// iPhone SE용 키보드 전환 버튼
    private lazy var nextKeyboardButton: NextKeyboardButton? = nil
    
    // MARK: - Initializer
    
    init(nextKeyboardAction: Selector?) {
        super.init(frame: .zero)
        
        if let nextKeyboardAction { setNextKeyboardButtonTarget(action: nextKeyboardAction) }
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension HangeulView {
    func setupUI() {
        setStyles()
        setViewHierarchy()
        setConstraints()
    }
    
    func setStyles() {}
    
    func setViewHierarchy() {
        self.addSubviews(topSpacer,
                         frameStackView,
                         bottomSpacer)
        
        frameStackView.addArrangedSubviews(firstRowStackView,
                                           secondRowStackView,
                                           thirdRowStackView,
                                           fourthRowStackView)
        
        firstRowKeyButtonList.forEach { firstRowStackView.addArrangedSubview($0) }
        firstRowStackView.addArrangedSubview(deleteButton)
        
        secondRowKeyButtonList.forEach { secondRowStackView.addArrangedSubview($0) }
        secondRowStackView.addArrangedSubview(spaceButton)
        
        thirdRowKeyButtonList.forEach { thirdRowStackView.addArrangedSubview($0) }
        thirdRowStackView.addArrangedSubview(returnButton)
        
        fourthRowKeyButtonList.forEach { fourthRowStackView.addArrangedSubview($0) }
        fourthRowStackView.addArrangedSubview(fourthRowRightSecondaryButtonStackView)
        fourthRowRightSecondaryButtonStackView.addArrangedSubview(switchButton)
        // iPhone SE일 때 키보드 전환 버튼 추가
        if let nextKeyboardButton {
            fourthRowRightSecondaryButtonStackView.addArrangedSubview(nextKeyboardButton)
        }
    }
    
    func setConstraints() {
        topSpacer.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        frameStackView.snp.makeConstraints {
            $0.top.equalTo(topSpacer.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomSpacer.snp.top)
        }
        
        bottomSpacer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(2)
        }
    }
}

// MARK: - Action Methods

private extension HangeulView {
    func setNextKeyboardButtonTarget(action: Selector) {
        nextKeyboardButton = NextKeyboardButton(layout: .hangeul)
        nextKeyboardButton?.addTarget(nil, action: action, for: .allTouchEvents)
    }
}

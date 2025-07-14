//
//  HangeulView.swift
//  Keyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

/// 한글 자판 `UIView`
final class HangeulView: UIView {
    
    // MARK: - Properties
    
    /// 나랏글 자판 키 배열
    private let naratgeulKeyList = [
        [ ["ㄱ"], ["ㄴ"], ["ㅏ", "ㅓ"] ],
        [ ["ㄹ"], ["ㅁ"], ["ㅗ", "ㅜ"] ],
        [ ["ㅅ"], ["ㅇ"], ["ㅣ"] ],
        [ ["획"], ["ㅡ"], ["쌍"] ]
    ]
    
    // MARK: - UI Components
    
    /// 상단 여백 `KeyboardSpacer`
    private let spacer = KeyboardSpacer()
    /// 키보드 전체 프레임 `KeyboardFrameStackView`
    private let frameStackView = KeyboardFrameStackView()
    
    /// 키보드 첫번째 행 `KeyboardRowStackView`
    private let firstRowStackView = KeyboardRowStackView()
    /// 키보드 두번째 행 `KeyboardRowStackView`
    private let secondRowStackView = KeyboardRowStackView()
    /// 키보드 세번째 행 `KeyboardRowStackView`
    private let thirdRowStackView = KeyboardRowStackView()
    /// 키보드 네번째 행 `KeyboardRowStackView`
    private let fourthRowStackView = KeyboardRowStackView()
    
    /// 키보드 첫번째 행 `KeyButton` 배열
    private lazy var firstRowKeyButtonList = naratgeulKeyList[0].map { KeyButton(layout: .hangeul, keys: $0) }
    /// 키보드 두번째 행 `KeyButton` 배열
    private lazy var secondRowKeyButtonList = naratgeulKeyList[1].map { KeyButton(layout: .hangeul, keys: $0) }
    /// 키보드 세번째 행 `KeyButton` 배열
    private lazy var thirdRowKeyButtonList = naratgeulKeyList[2].map { KeyButton(layout: .hangeul, keys: $0) }
    /// 키보드 네번째 행 `KeyButton` 배열
    private lazy var fourthRowKeyButtonList = naratgeulKeyList[3].map { KeyButton(layout: .hangeul, keys: $0) }
    
    /// 삭제 버튼 `DeleteButton`
    private let deleteButton = DeleteButton(layout: .hangeul)
    /// 스페이스 버튼 `SpaceButton`
    private let spaceButton = SpaceButton(layout: .hangeul)
    /// 리턴 버튼 `ReturnButton`
    private let returnButton = ReturnButton(layout: .hangeul)
    /// 자판 전환 버튼 `SwitchButton`
    private let switchButton = SwitchButton(layout: .hangeul)
    
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

private extension HangeulView {
    func setupUI() {
        setStyles()
        setViewHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setViewHierarchy() {
        self.addSubviews(spacer,
                         frameStackView)
        
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
        fourthRowStackView.addArrangedSubview(switchButton)
    }
    
    func setConstraints() {
        spacer.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        frameStackView.snp.makeConstraints {
            $0.top.equalTo(spacer.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        firstRowStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(firstRowStackView.arrangedSubviews.count)
            }
        }
        
        secondRowStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(secondRowStackView.arrangedSubviews.count)
            }
        }
        
        thirdRowStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(thirdRowStackView.arrangedSubviews.count)
            }
        }
        
        fourthRowStackView.arrangedSubviews.forEach { subview in
            subview.snp.makeConstraints {
                $0.width.equalToSuperview().dividedBy(fourthRowStackView.arrangedSubviews.count)
            }
        }
    }
}

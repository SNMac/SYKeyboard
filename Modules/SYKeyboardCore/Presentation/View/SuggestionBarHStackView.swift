//
//  SuggestionBarHStackView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/10/26.
//

import UIKit

import SYKeyboardAssets

/// `SuggestionBarHStackView`의 사용자 상호작용 이벤트를 수신하는 델리게이트 프로토콜
protocol SuggestionBarDelegate: AnyObject {
    /// 자동완성 후보 버튼이 탭되었을 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - bar: 이벤트를 발생시킨 `SuggestionBarHStackView`
    ///   - index: 선택된 후보의 인덱스 (0~2)
    func suggestionBar(_ bar: SuggestionBarHStackView, didSelectSuggestionAt index: Int)
}

/// 자동완성 후보 단어와 맞춤법 검사 버튼을 표시하는 수평 스택 툴바
///
/// 최대 3개의 후보 버튼과 1개의 맞춤법 검사 버튼으로 구성되며,
/// 각 버튼의 탭 이벤트는 `SuggestionBarDelegate`를 통해 전달됩니다.
final class SuggestionBarHStackView: UIStackView {
    
    // MARK: - Properties
    
    weak var suggestionDelegate: SuggestionBarDelegate?
    
    // MARK: - UI Components
    
    private lazy var predictedWordButton1: WordSuggestionButton = {
        let button = WordSuggestionButton()
        button.trailingDivider = firstWordButtonDivider
        
        return button
    }()
    
    private let firstWordButtonDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var predictedWordButton2: WordSuggestionButton = {
        let button = WordSuggestionButton()
        button.leadingDivider = firstWordButtonDivider
        button.trailingDivider = secondWordButtonDivider
        
        return button
    }()
    
    private let secondWordButtonDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var predictedWordButton3: WordSuggestionButton = {
        let button = WordSuggestionButton()
        button.leadingDivider = secondWordButtonDivider
        
        return button
    }()
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 이미 하나의 버튼이 highlighted 상태면 다른 터치 무시
        let buttons: [UIButton] = [predictedWordButton1, predictedWordButton2, predictedWordButton3]
        
        if buttons.contains(where: { $0.isHighlighted }) {
            return nil
        }
        
        return super.hitTest(point, with: event)
    }
    
    // MARK: - Internal Methods
    
    /// 자동완성 후보 단어를 업데이트합니다.
    ///
    /// 후보가 3개 미만이면 나머지 버튼의 타이틀을 빈 문자열로 설정합니다.
    ///
    /// - Parameter suggestions: 표시할 후보 단어 배열 (최대 3개)
    func updatePredictions(_ suggestions: [String]) {
        let buttons = [predictedWordButton1, predictedWordButton2, predictedWordButton3]
        
        for (index, button) in buttons.enumerated() {
            if index < suggestions.count {
                button.update(to: suggestions[index])
            } else {
                button.update(to: "")
            }
        }
    }
}

// MARK: - UI Methods

private extension SuggestionBarHStackView {
    func setupUI() {
        setStyles()
        setActions()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.axis = .horizontal
        self.alignment = .center
        self.spacing = 0
    }
    
    func setActions() {
        let buttons = [predictedWordButton1, predictedWordButton2, predictedWordButton3]
        
        for (index, button) in buttons.enumerated() {
            let action = UIAction { [weak self] _ in
                guard let self else { return }
                suggestionDelegate?.suggestionBar(self, didSelectSuggestionAt: index)
                FeedbackManager.shared.playHaptic()
                FeedbackManager.shared.playModifierSound()
            }
            button.addAction(action, for: .touchUpInside)
        }
    }
    
    func setHierarchy() {
        [predictedWordButton1, firstWordButtonDivider, predictedWordButton2, secondWordButtonDivider, predictedWordButton3].forEach {
            self.addArrangedSubview($0)
        }
    }
    
    func setConstraints() {
        [firstWordButtonDivider, secondWordButtonDivider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: 1).isActive = true
            $0.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.suggestionButtonDividerHeight).isActive = true
        }
        
        NSLayoutConstraint.activate([
            predictedWordButton1.heightAnchor.constraint(equalTo: self.heightAnchor),
            predictedWordButton2.widthAnchor.constraint(equalTo: predictedWordButton1.widthAnchor),
            predictedWordButton2.heightAnchor.constraint(equalTo: self.heightAnchor),
            predictedWordButton3.widthAnchor.constraint(equalTo: predictedWordButton1.widthAnchor),
            predictedWordButton3.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])
    }
}

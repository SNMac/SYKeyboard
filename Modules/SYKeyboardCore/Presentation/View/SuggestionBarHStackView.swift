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
        button.trailingDivider = leftDivider
        
        return button
    }()
    
    private let leftDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var predictedWordButton2: WordSuggestionButton = {
        let button = WordSuggestionButton()
        button.leadingDivider = leftDivider
        button.trailingDivider = rightDivider
        
        return button
    }()
    
    private let rightDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var predictedWordButton3: WordSuggestionButton = {
        let button = WordSuggestionButton()
        button.leadingDivider = rightDivider
        
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
    
    /// 자동완성 바를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - currentWord: 현재 입력 중인 단어 (button1에 ""로 감싸서 표시)
    ///   - suggestions: 자동완성 후보 배열 (최대 2개, button2~3에 표시)
    func updateSuggestions(currentWord: String?, suggestions: [String]) {
        // Button 1: 현재 입력 단어를 따옴표로 감싸서 표시
        if let word = currentWord, !word.isEmpty {
            predictedWordButton1.update(to: "\"\(word)\"")
        } else {
            predictedWordButton1.update(to: "")
        }
        
        // Button 2-3: 자동완성 후보
        let suggestionButtons = [predictedWordButton2, predictedWordButton3]
        for (index, button) in suggestionButtons.enumerated() {
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
        self.layoutMargins = UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
        self.isLayoutMarginsRelativeArrangement = true
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
        [predictedWordButton1, leftDivider, predictedWordButton2, rightDivider, predictedWordButton3].forEach {
            self.addArrangedSubview($0)
        }
    }
    
    func setConstraints() {
        [leftDivider, rightDivider].forEach {
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

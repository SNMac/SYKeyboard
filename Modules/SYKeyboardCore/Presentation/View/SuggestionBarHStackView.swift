//
//  SuggestionBarHStackView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/10/26.
//

import UIKit

import SYKeyboardAssets

final class SuggestionBarHStackView: UIStackView {
    
    // MARK: - UI Components
    
    private let predictionHStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.alignment = .center
        
        return stackView
    }()
    
    private lazy var predictedWordButton1: WordSuggestionButton = {
        let button = WordSuggestionButton()
        button.trailingDivider = predictedWordDivider1
        
        return button
    }()
    
    private let predictedWordDivider1: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var predictedWordButton2: WordSuggestionButton = {
        let button = WordSuggestionButton()
        button.leadingDivider = predictedWordDivider1
        button.trailingDivider = predictedWordDivider2
        
        return button
    }()
    
    private let predictedWordDivider2: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var predictedWordButton3: WordSuggestionButton = {
        let button = WordSuggestionButton()
        button.leadingDivider = predictedWordDivider2
        button.trailingDivider = predictedWordDivider3
        
        return button
    }()
    
    private let predictedWordDivider3: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var grammarCheckButton: GrammarCheckButton = {
        let button = GrammarCheckButton()
        button.leadingDivider = predictedWordDivider3
        
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
        let buttons: [UIButton] = [predictedWordButton1, predictedWordButton2, predictedWordButton3, grammarCheckButton]
        
        if buttons.contains(where: { $0.isHighlighted }) {
            return nil
        }
        
        return super.hitTest(point, with: event)
    }
}

// MARK: - UI Methods

private extension SuggestionBarHStackView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.axis = .horizontal
        self.spacing = 0
    }
    
    func setHierarchy() {
        [predictedWordButton1, predictedWordDivider1, predictedWordButton2, predictedWordDivider2, predictedWordButton3, predictedWordDivider3].forEach {
            predictionHStackView.addArrangedSubview($0)
        }
        
        [predictionHStackView, grammarCheckButton].forEach {
            self.addArrangedSubview($0)
        }
    }
    
    func setConstraints() {
        [predictedWordDivider1, predictedWordDivider2, predictedWordDivider3].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: 1).isActive = true
            $0.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.suggestionButtonDividerHeight).isActive = true
        }
        
        NSLayoutConstraint.activate([
            predictedWordButton1.heightAnchor.constraint(equalTo: predictionHStackView.heightAnchor),
            predictedWordButton2.widthAnchor.constraint(equalTo: predictedWordButton1.widthAnchor),
            predictedWordButton2.heightAnchor.constraint(equalTo: predictionHStackView.heightAnchor),
            predictedWordButton3.widthAnchor.constraint(equalTo: predictedWordButton1.widthAnchor),
            predictedWordButton3.heightAnchor.constraint(equalTo: predictionHStackView.heightAnchor)
        ])
        
        grammarCheckButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grammarCheckButton.widthAnchor.constraint(equalTo: grammarCheckButton.heightAnchor)
        ])
    }
}

//
//  SuggestionBarView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/10/26.
//

import UIKit

import SYKeyboardAssets

/// `SuggestionBarView`의 사용자 상호작용 이벤트를 수신하는 델리게이트 프로토콜
protocol SuggestionBarDelegate: AnyObject {
    /// 자동완성 후보 버튼이 탭되었을 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - bar: 이벤트를 발생시킨 `SuggestionBarView`
    ///   - index: 선택된 후보의 인덱스 (0~2)
    func suggestionBar(_ bar: SuggestionBarView, didSelectSuggestionAt index: Int)
}

/// 자동완성 후보 단어와 맞춤법 검사 버튼을 표시하는 툴바
///
/// 최대 3개의 후보 버튼과 1개의 맞춤법 검사 버튼으로 구성되며,
/// 각 버튼의 탭 이벤트는 `SuggestionBarDelegate`를 통해 전달됩니다.
///
/// ## 표시 모드
/// - **입력 중**: button1에 `"현재단어"`, button2~3에 자동완성 후보
/// - **입력 없음 / 자동완성 후**: button1~3에 n-gram 다음 단어 예측
final class SuggestionBarView: UIView {
    
    // MARK: - Properties
    
    weak var suggestionDelegate: SuggestionBarDelegate?
    
    private var suggestionButtons: [WordSuggestionButtonLikeView] {
        return [predictedWordButton1, predictedWordButton2, predictedWordButton3]
    }
    
    // MARK: - UI Components
    
    private let buttonContainerHStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.alignment = .center
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        return stackView
    }()
    
    private lazy var predictedWordButton1: WordSuggestionButtonLikeView = {
        let button = WordSuggestionButtonLikeView()
        button.trailingDivider = leftDivider
        
        return button
    }()
    
    private let leftDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var predictedWordButton2: WordSuggestionButtonLikeView = {
        let button = WordSuggestionButtonLikeView()
        button.leadingDivider = leftDivider
        button.trailingDivider = rightDivider
        
        return button
    }()
    
    private let rightDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var predictedWordButton3: WordSuggestionButtonLikeView = {
        let button = WordSuggestionButtonLikeView()
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        updateHighlight(at: point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        updateHighlight(at: point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        
        if let (index, _) = suggestionButton(at: point) {
            suggestionDelegate?.suggestionBar(self, didSelectSuggestionAt: index)
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playModifierSound()
        }
        
        clearAllHighlights()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        clearAllHighlights()
    }
    
    // MARK: - Internal Methods
    
    /// 자동완성 바를 업데이트합니다.
    ///
    /// `currentWord`가 있으면 button1에 따옴표로 감싸서 표시하고
    /// button2~3에 자동완성 후보를 표시합니다.
    /// `currentWord`가 없으면 button1~3에 다음 단어 예측 후보를 표시합니다.
    ///
    /// - Parameters:
    ///   - currentWord: 현재 입력 중인 단어 (없으면 nil)
    ///   - suggestions: 자동완성 또는 예측 후보 배열
    func updateSuggestions(currentWord: String?, suggestions: [String]) {
        if let word = currentWord, !word.isEmpty {
            // 입력 중: button1에 "현재단어", button2~3에 자동완성 후보
            predictedWordButton1.update(to: "\"\(word)\"")
            
            let suggestionButtons = [predictedWordButton2, predictedWordButton3]
            for (index, button) in suggestionButtons.enumerated() {
                if index < suggestions.count {
                    button.update(to: suggestions[index])
                } else {
                    button.update(to: "")
                }
            }
        } else {
            // 입력 없음 / 자동완성 후: button1~3에 n-gram 예측 후보
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
}

// MARK: - UI Methods

private extension SuggestionBarView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setHierarchy() {
        self.addSubview(buttonContainerHStackView)
        
        [predictedWordButton1, leftDivider, predictedWordButton2, rightDivider, predictedWordButton3].forEach {
            buttonContainerHStackView.addArrangedSubview($0)
        }
    }
    
    func setConstraints() {
        buttonContainerHStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonContainerHStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: KeyboardLayoutFigure.keyboardFrameSpacing),
            buttonContainerHStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            buttonContainerHStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            buttonContainerHStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
        ])
        
        [leftDivider, rightDivider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: 1).isActive = true
            $0.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.suggestionButtonDividerHeight).isActive = true
        }
        
        predictedWordButton1.translatesAutoresizingMaskIntoConstraints = false
        predictedWordButton2.translatesAutoresizingMaskIntoConstraints = false
        predictedWordButton3.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            predictedWordButton1.heightAnchor.constraint(equalTo: buttonContainerHStackView.heightAnchor),
            predictedWordButton2.widthAnchor.constraint(equalTo: predictedWordButton1.widthAnchor),
            predictedWordButton2.heightAnchor.constraint(equalTo: buttonContainerHStackView.heightAnchor),
            predictedWordButton3.widthAnchor.constraint(equalTo: predictedWordButton1.widthAnchor),
            predictedWordButton3.heightAnchor.constraint(equalTo: buttonContainerHStackView.heightAnchor)
        ])
    }
}

// MARK: - Private Methods

private extension SuggestionBarView {
    func suggestionButton(at point: CGPoint) -> (Int, WordSuggestionButtonLikeView)? {
        for (index, button) in suggestionButtons.enumerated() {
            guard button.hasText else { continue }
            let buttonFrame = button.convert(button.bounds, to: self)
            if buttonFrame.contains(point) {
                return (index, button)
            }
        }
        return nil
    }
    
    func updateHighlight(at point: CGPoint) {
        let hit = suggestionButton(at: point)
        for button in suggestionButtons {
            button.isSuggestionHighlighted = (button === hit?.1)
        }
    }

    func clearAllHighlights() {
        for button in suggestionButtons {
            button.isSuggestionHighlighted = false
        }
    }
}

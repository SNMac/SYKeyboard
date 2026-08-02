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
    /// undo 버튼이 탭되었을 때 호출됩니다.
    func suggestionBarDidTapUndo(_ bar: SuggestionBarView)
    /// redo 버튼이 탭되었을 때 호출됩니다.
    func suggestionBarDidTapRedo(_ bar: SuggestionBarView)
}

/// 자동완성 후보 단어와 맞춤법 검사 버튼을 표시하는 툴바
///
/// 최대 3개의 후보 버튼과 1개의 맞춤법 검사 버튼으로 구성되며,
/// 각 버튼의 탭 이벤트는 `SuggestionBarDelegate`를 통해 전달됩니다.
///
/// ## 표시 모드
/// - **입력 중**: button1에 `"현재단어"`, button2~3에 자동완성 후보
/// - **입력 없음 / 자동완성 후**: button1~3에 n-gram 다음 단어 예측
/// - **수식 결과**: button1에 원문, button2에 원문+결과, button3에 결과 대치 후보
final class SuggestionBarView: UIView {
    
    // MARK: - Properties

    weak var keyboardHStackView: UIView?
    weak var suggestionDelegate: SuggestionBarDelegate?
    
    private weak var activeTouch: UITouch?
    private weak var touchHighlightedSuggestionButton: SuggestionButtonView?
    private weak var touchHighlightedActionButton: SuggestionActionButtonView?
    private var previewHighlightIndex: Int?
    
    private var suggestionButtons: [SuggestionButtonView] {
        return [suggestionButton1, suggestionButton2, suggestionButton3]
    }

    private var undoRedoViews: [UIView] {
        return [undoRedoLeadingDivider, undoButton, undoRedoMiddleDivider, redoButton]
    }

    private var undoRedoButtons: [SuggestionActionButtonView] {
        return [undoButton, redoButton]
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
    
    private lazy var suggestionButton1: SuggestionButtonView = {
        let button = SuggestionButtonView()
        button.trailingDivider = leftDivider
        
        return button
    }()
    
    private let leftDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var suggestionButton2: SuggestionButtonView = {
        let button = SuggestionButtonView()
        button.leadingDivider = leftDivider
        button.trailingDivider = rightDivider
        
        return button
    }()
    
    private let rightDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        
        return view
    }()
    
    private lazy var suggestionButton3: SuggestionButtonView = {
        let button = SuggestionButtonView()
        button.leadingDivider = rightDivider
        
        return button
    }()

    private let undoRedoLeadingDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        view.isHidden = true

        return view
    }()

    private lazy var undoButton: SuggestionActionButtonView = {
        let button = makeUndoRedoButton(systemName: "arrow.uturn.backward")

        return button
    }()

    private let undoRedoMiddleDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        view.isHidden = true

        return view
    }()

    private lazy var redoButton: SuggestionActionButtonView = {
        let button = makeUndoRedoButton(systemName: "arrow.uturn.forward")

        return button
    }()
    
    // MARK: - Initializer
    
    init(keyboardHStackView: UIStackView) {
        self.keyboardHStackView = keyboardHStackView
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch
        let point = touch.location(in: self)
        updateHighlight(at: point)
        keyboardHStackView?.isUserInteractionEnabled = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        updateHighlight(at: point)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        
        if let (index, _) = suggestionButton(at: point) {
            suggestionDelegate?.suggestionBar(self, didSelectSuggestionAt: index)
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playModifierSound()
        } else if let action = undoRedoButton(at: point) {
            switch action {
            case undoButton:
                suggestionDelegate?.suggestionBarDidTapUndo(self)
            case redoButton:
                suggestionDelegate?.suggestionBarDidTapRedo(self)
            default:
                break
            }
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playModifierSound()
        }
        
        activeTouch = nil
        clearTouchHighlights()
        keyboardHStackView?.isUserInteractionEnabled = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        activeTouch = nil
        clearTouchHighlights()
        keyboardHStackView?.isUserInteractionEnabled = true
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
            suggestionButton1.update(to: "\"\(word)\"")
            
            let suggestionButtons = [suggestionButton2, suggestionButton3]
            for (index, button) in suggestionButtons.enumerated() {
                if index < suggestions.count {
                    button.update(to: suggestions[index])
                } else {
                    button.update(to: "")
                }
            }
        } else {
            // 입력 없음 / 자동완성 후: button1~3에 n-gram 예측 후보
            let buttons = [suggestionButton1, suggestionButton2, suggestionButton3]
            for (index, button) in buttons.enumerated() {
                if index < suggestions.count {
                    button.update(to: suggestions[index])
                } else {
                    button.update(to: "")
                }
            }
        }
        applyHighlights()
    }

    /// 수식 결과 후보를 업데이트합니다.
    ///
    /// - Parameter suggestions: 원문, 원문+결과, 결과값 후보 배열
    func updateMathResultSuggestions(_ suggestions: [String]) {
        let buttons = [suggestionButton1, suggestionButton2, suggestionButton3]
        for (index, button) in buttons.enumerated() {
            let title = index < suggestions.count ? suggestions[index] : ""
            button.update(to: title)
        }
        applyHighlights()
    }

    /// 스페이스로 자동 적용될 후보의 preview 하이라이트를 갱신합니다.
    ///
    /// - Parameter index: 강조할 후보 인덱스 (0~2), 없으면 `nil`
    func updatePreviewHighlight(index: Int?) {
        if let index, !suggestionButtons.indices.contains(index) {
            previewHighlightIndex = nil
        } else {
            previewHighlightIndex = index
        }
        applyHighlights()
        updateDividers()
    }

    /// 자동완성 바 우측의 undo/redo 버튼 표시와 활성 상태를 갱신합니다.
    func updateUndoRedoControls(isVisible: Bool, canUndo: Bool, canRedo: Bool) {
        undoRedoViews.forEach { $0.isHidden = !isVisible }
        undoButton.isEnabled = isVisible && canUndo
        redoButton.isEnabled = isVisible && canRedo
        updateDividers()
    }

    #if DEBUG
    func updateTouchHighlightForTesting(index: Int?) {
        if let index, suggestionButtons.indices.contains(index) {
            touchHighlightedSuggestionButton = suggestionButtons[index]
        } else {
            touchHighlightedSuggestionButton = nil
        }
        applyHighlights()
        updateDividers()
    }

    func updateUndoRedoTouchHighlightForTesting(index: Int?) {
        if let index, undoRedoButtons.indices.contains(index) {
            touchHighlightedActionButton = undoRedoButtons[index]
        } else {
            touchHighlightedActionButton = nil
        }
        applyHighlights()
        updateDividers()
    }
    #endif
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
        
        [suggestionButton1,
         leftDivider,
         suggestionButton2,
         rightDivider,
         suggestionButton3,
         undoRedoLeadingDivider,
         undoButton,
         undoRedoMiddleDivider,
         redoButton].forEach {
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
        
        [leftDivider, rightDivider, undoRedoLeadingDivider, undoRedoMiddleDivider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: 1).isActive = true
            $0.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.suggestionButtonDividerHeight).isActive = true
        }
        
        suggestionButton1.translatesAutoresizingMaskIntoConstraints = false
        suggestionButton2.translatesAutoresizingMaskIntoConstraints = false
        suggestionButton3.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            suggestionButton1.heightAnchor.constraint(equalTo: buttonContainerHStackView.heightAnchor),
            suggestionButton2.widthAnchor.constraint(equalTo: suggestionButton1.widthAnchor),
            suggestionButton2.heightAnchor.constraint(equalTo: buttonContainerHStackView.heightAnchor),
            suggestionButton3.widthAnchor.constraint(equalTo: suggestionButton1.widthAnchor),
            suggestionButton3.heightAnchor.constraint(equalTo: buttonContainerHStackView.heightAnchor)
        ])

        [undoButton, redoButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: KeyboardLayoutFigure.undoRedoButtonWidth).isActive = true
            $0.heightAnchor.constraint(equalTo: buttonContainerHStackView.heightAnchor).isActive = true
        }
    }

}

// MARK: - Private Methods

private extension SuggestionBarView {
    func makeUndoRedoButton(systemName: String) -> SuggestionActionButtonView {
        let button = SuggestionActionButtonView(systemName: systemName)
        button.isHidden = true

        return button
    }

    func suggestionButton(at point: CGPoint) -> (Int, SuggestionButtonView)? {
        for (index, button) in suggestionButtons.enumerated() {
            guard button.hasText else { continue }
            let buttonFrame = button.convert(button.bounds, to: self)
            if buttonFrame.contains(point) {
                return (index, button)
            }
        }
        return nil
    }

    func undoRedoButton(at point: CGPoint) -> SuggestionActionButtonView? {
        for button in undoRedoButtons {
            guard !button.isHidden, button.isEnabled else { continue }
            let buttonFrame = button.convert(button.bounds, to: self)
            if buttonFrame.contains(point) {
                return button
            }
        }
        return nil
    }
    
    func updateHighlight(at point: CGPoint) {
        let hit = suggestionButton(at: point)
        touchHighlightedSuggestionButton = hit?.1

        let actionHit = undoRedoButton(at: point)
        touchHighlightedActionButton = actionHit
        applyHighlights()
        updateDividers()
    }
    
    func clearTouchHighlights() {
        touchHighlightedSuggestionButton = nil
        touchHighlightedActionButton = nil
        applyHighlights()
        updateDividers()
    }

    func applyHighlights() {
        let hasTouchHighlight = touchHighlightedSuggestionButton != nil || touchHighlightedActionButton != nil

        for (index, button) in suggestionButtons.enumerated() {
            let isPreviewHighlighted = !hasTouchHighlight && previewHighlightIndex == index
            let isTouchHighlighted = button === touchHighlightedSuggestionButton
            button.isHighlighted = isTouchHighlighted || isPreviewHighlighted
        }

        for button in undoRedoButtons {
            button.isHighlighted = (button === touchHighlightedActionButton)
        }
    }
    
    func updateDividers() {
        let btn1Highlighted = suggestionButton1.isHighlighted
        let btn2Highlighted = suggestionButton2.isHighlighted
        let btn3Highlighted = suggestionButton3.isHighlighted
        
        leftDivider.backgroundColor = (btn1Highlighted || btn2Highlighted)
        ? .clear
        : .suggestionDividerColor
        rightDivider.backgroundColor = (btn2Highlighted || btn3Highlighted)
        ? .clear
        : .suggestionDividerColor
        undoRedoLeadingDivider.backgroundColor = (btn3Highlighted || undoButton.isHighlighted)
        ? .clear
        : .suggestionDividerColor
        undoRedoMiddleDivider.backgroundColor = (undoButton.isHighlighted || redoButton.isHighlighted)
        ? .clear
        : .suggestionDividerColor
    }
}

// MARK: - Supporting Views

private final class SuggestionActionButtonView: UIView {

    // MARK: - Properties

    private let cornerRadius: CGFloat

    var isHighlighted: Bool = false {
        didSet {
            backgroundView.backgroundColor = isHighlighted ? .suggestionButtonPressed : .clear
        }
    }

    var isEnabled: Bool = false {
        didSet {
            imageView.alpha = isEnabled ? 1.0 : 0.32
        }
    }

    // MARK: - UI Components

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        view.layer.cornerRadius = cornerRadius

        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false

        return imageView
    }()

    // MARK: - Initializer

    init(systemName: String) {
        if #available(iOS 26, *) {
            let height = KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing - KeyboardLayoutFigure.keyboardFrameSpacing
            self.cornerRadius = min(KeyboardLayoutFigure.undoRedoButtonWidth, height) / 2
        } else {
            self.cornerRadius = 4.6
        }
        super.init(frame: .zero)
        imageView.image = UIImage(systemName: systemName)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension SuggestionActionButtonView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }

    func setStyles() {
        self.backgroundColor = .systemBackground.withAlphaComponent(0.001)
    }

    func setHierarchy() {
        self.insertSubview(backgroundView, at: 0)
        self.addSubview(imageView)
    }

    func setConstraints() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 18),
            imageView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
}

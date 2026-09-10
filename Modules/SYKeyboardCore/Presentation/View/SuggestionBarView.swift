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
    /// 클립보드 버튼이 탭되었을 때 호출됩니다.
    func suggestionBarDidTapClipboard(_ bar: SuggestionBarView)
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
    private var touchedSuggestionIndex: Int?
    private var touchedActionIndex: Int?
    private var previewHighlightIndex: Int?
    
    private var suggestionButtons: [SuggestionButtonView] {
        return [suggestionButton1, suggestionButton2, suggestionButton3]
    }

    private var undoRedoViews: [UIView] {
        return [undoRedoLeadingDivider, undoButton, undoRedoMiddleDivider, redoButton]
    }

    private var clipboardViews: [UIView] {
        return [clipboardButton, clipboardDivider]
    }

    /// 후보 영역이 숨겨질 때 함께 사라지는 후보 사이 divider
    private var suggestionAreaDividers: [UIView] {
        return [leftDivider, rightDivider]
    }

    /// 히트테스트·하이라이트 대상 accessory 버튼. 인덱스가 `SuggestionHighlightPolicy`의 action 인덱스다
    private var actionButtons: [SuggestionActionButtonView] {
        return [clipboardButton, undoButton, redoButton]
    }

    private static let clipboardClosedSymbolName = "list.clipboard"
    private static let clipboardOpenSymbolName = "keyboard"
    private var isClipboardPanelVisible = false

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

    private lazy var clipboardButton: SuggestionActionButtonView = {
        let button = makeActionButton(systemName: SuggestionBarView.clipboardClosedSymbolName)

        return button
    }()

    private let clipboardDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        view.isHidden = true

        return view
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
        let button = makeActionButton(systemName: "arrow.uturn.backward")

        return button
    }()

    private let undoRedoMiddleDivider: UIView = {
        let view = UIView()
        view.backgroundColor = .suggestionDividerColor
        view.isHidden = true

        return view
    }()

    private lazy var redoButton: SuggestionActionButtonView = {
        let button = makeActionButton(systemName: "arrow.uturn.forward")

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
        beginTouchInteraction(at: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        moveTouchInteraction(to: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        endTouchInteraction(at: touch.location(in: self), playsFeedback: true)
        activeTouch = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        cancelTouchInteraction()
        activeTouch = nil
    }

    // MARK: - Internal Methods

    func beginTouchInteraction(at point: CGPoint) {
        updateHighlight(at: point)
        keyboardHStackView?.isUserInteractionEnabled = false
    }

    func moveTouchInteraction(to point: CGPoint) {
        updateHighlight(at: point)
    }

    func endTouchInteraction(at point: CGPoint, playsFeedback: Bool) {
        if let (index, _) = suggestionButton(at: point) {
            suggestionDelegate?.suggestionBar(
                self,
                didSelectSuggestionAt: index
            )
            playSelectionFeedbackIfNeeded(playsFeedback)
        } else if let action = actionButton(at: point) {
            switch action {
            case clipboardButton:
                suggestionDelegate?.suggestionBarDidTapClipboard(self)
            case undoButton:
                suggestionDelegate?.suggestionBarDidTapUndo(self)
            case redoButton:
                suggestionDelegate?.suggestionBarDidTapRedo(self)
            default:
                break
            }
            playSelectionFeedbackIfNeeded(playsFeedback)
        }

        resetTouchInteraction()
    }

    func cancelTouchInteraction() {
        resetTouchInteraction()
    }

    func playSelectionFeedbackIfNeeded(_ shouldPlay: Bool) {
        guard shouldPlay else { return }
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }

    func resetTouchInteraction() {
        clearTouchHighlights()
        keyboardHStackView?.isUserInteractionEnabled = true
    }

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

    /// 후보 영역 표시 여부를 갱신합니다.
    ///
    /// 후보 라벨은 `SuggestionController.isSuspended`가 비우므로 여기서는 후보 사이 divider만 숨겨
    /// 액션 버튼 위치를 그대로 둔 채 가운데를 빈 상태로 만듭니다.
    func updateSuggestionArea(isVisible: Bool) {
        suggestionAreaDividers.forEach { $0.isHidden = !isVisible }
    }

    /// 자동완성 바 우측의 undo/redo 버튼 표시와 활성 상태를 갱신합니다.
    func updateUndoRedoControls(isVisible: Bool, canUndo: Bool, canRedo: Bool) {
        undoRedoViews.forEach { $0.isHidden = !isVisible }
        undoButton.isEnabled = isVisible && canUndo
        redoButton.isEnabled = isVisible && canRedo
        updateDividers()
    }

    /// 자동완성 바 좌측의 클립보드 버튼 표시와 아이콘을 갱신합니다.
    ///
    /// 패널이 열려 있으면 키보드 아이콘으로 바꿔 다시 탭하면 자판으로 돌아감을 알립니다.
    func updateClipboardControl(isVisible: Bool, isPanelVisible: Bool) {
        clipboardViews.forEach { $0.isHidden = !isVisible }
        clipboardButton.isEnabled = isVisible
        if isClipboardPanelVisible != isPanelVisible {
            isClipboardPanelVisible = isPanelVisible
            clipboardButton.updateImage(
                systemName: isPanelVisible
                ? SuggestionBarView.clipboardOpenSymbolName
                : SuggestionBarView.clipboardClosedSymbolName
            )
        }
        updateDividers()
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
        
        [clipboardButton,
         clipboardDivider,
         suggestionButton1,
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
        
        [clipboardDivider, leftDivider, rightDivider, undoRedoLeadingDivider, undoRedoMiddleDivider].forEach {
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

        [clipboardButton, undoButton, redoButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: KeyboardLayoutFigure.undoRedoButtonWidth).isActive = true
            $0.heightAnchor.constraint(equalTo: buttonContainerHStackView.heightAnchor).isActive = true
        }
    }

}

// MARK: - Private Methods

private extension SuggestionBarView {
    func makeActionButton(systemName: String) -> SuggestionActionButtonView {
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

    func actionButton(at point: CGPoint) -> SuggestionActionButtonView? {
        for button in actionButtons {
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
        touchedSuggestionIndex = hit?.0

        let actionHit = actionButton(at: point)
        touchedActionIndex = actionHit.flatMap { actionButton in
            actionButtons.firstIndex { $0 === actionButton }
        }
        applyHighlights()
        updateDividers()
    }
    
    func clearTouchHighlights() {
        touchedSuggestionIndex = nil
        touchedActionIndex = nil
        applyHighlights()
        updateDividers()
    }

    func applyHighlights() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: previewHighlightIndex,
            touchedSuggestionIndex: touchedSuggestionIndex,
            touchedActionIndex: touchedActionIndex,
            suggestionCount: suggestionButtons.count,
            actionCount: actionButtons.count
        )

        for (index, button) in suggestionButtons.enumerated() {
            button.isHighlighted = state.highlightedSuggestionIndex == index
        }

        for (index, button) in actionButtons.enumerated() {
            button.isHighlighted = state.highlightedActionIndex == index
        }
    }
    
    func updateDividers() {
        let btn1Highlighted = suggestionButton1.isHighlighted
        let btn2Highlighted = suggestionButton2.isHighlighted
        let btn3Highlighted = suggestionButton3.isHighlighted

        clipboardDivider.backgroundColor = (clipboardButton.isHighlighted || btn1Highlighted)
        ? .clear
        : .suggestionDividerColor
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

    func updateImage(systemName: String) {
        imageView.image = UIImage(systemName: systemName)
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

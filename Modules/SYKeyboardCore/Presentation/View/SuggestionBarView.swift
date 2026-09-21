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
    ///   - index: 선택된 후보의 인덱스
    func suggestionBar(_ bar: SuggestionBarView, didSelectSuggestionAt index: Int)
    /// 후보를 길게 눌렀을 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - bar: 이벤트를 발생시킨 `SuggestionBarView`
    ///   - index: 누른 후보의 인덱스
    /// - Returns: 삭제 확인을 띄웠으면 `true`. 이때 이번 터치는 손을 떼도 후보를 선택하지 않습니다
    func suggestionBar(_ bar: SuggestionBarView, shouldBeginRemovalAt index: Int) -> Bool
    /// undo 버튼이 탭되었을 때 호출됩니다.
    func suggestionBarDidTapUndo(_ bar: SuggestionBarView)
    /// redo 버튼이 탭되었을 때 호출됩니다.
    func suggestionBarDidTapRedo(_ bar: SuggestionBarView)
    /// 클립보드 버튼이 탭되었을 때 호출됩니다.
    func suggestionBarDidTapClipboard(_ bar: SuggestionBarView)
}

/// 자동완성 후보 단어와 맞춤법 검사 버튼을 표시하는 툴바
///
/// 후보 버튼은 가로 스크롤 영역에 들어가고, 클립보드·undo/redo 버튼은 양옆에 고정되며,
/// 각 버튼의 탭 이벤트는 `SuggestionBarDelegate`를 통해 전달됩니다.
///
/// ## 표시 모드
/// - **입력 중**: 0번 칸에 `"현재단어"`, 그 뒤 칸에 자동완성 후보
/// - **입력 없음 / 자동완성 후**: 0번 칸부터 n-gram 다음 단어 예측
/// - **수식 결과**: 0번 칸에 원문, 1번에 원문+결과, 2번에 결과 대치 후보
final class SuggestionBarView: UIView {
    
    // MARK: - Properties

    weak var keyboardHStackView: UIView?
    weak var suggestionDelegate: SuggestionBarDelegate?
    
    private weak var activeTouch: UITouch?
    private var touchedSuggestionIndex: Int?
    private var touchedActionIndex: Int?
    private var previewHighlightIndex: Int?
    /// 삭제 길게 누르기 대상 후보 인덱스. 누른 후보를 벗어나거나 터치가 끝나면 `nil`이 된다
    private var removalPressedIndex: Int?
    /// 삭제 길게 누르기 타이머
    private var removalLongPressWorkItem: DispatchWorkItem?
    /// 길게 눌러 삭제 확인을 띄운 터치인지 여부. 손을 떼도 후보를 선택하지 않는다
    private var isTouchConsumedByRemoval = false

    /// 후보 버튼 재사용 풀. 한 번 만든 버튼은 버리지 않고 `isHidden`으로만 감춘다
    private var pooledButtons: [SuggestionButtonView] = []
    /// 후보 사이 divider 재사용 풀. 버튼 N개에 divider N-1개를 쓴다
    private var pooledDividers: [UIView] = []
    /// 현재 표시 중인 후보 버튼 개수
    private var visibleSuggestionCount = 0
    /// 후보 영역 표시 여부. 숨겨져 있으면 후보 사이 divider를 모두 감춘다
    private var isSuggestionAreaVisible = true

    /// 하이라이트·히트테스트 대상 후보 버튼. 풀에서 지금 쓰는 앞쪽 N개만 본다
    private var suggestionButtons: [SuggestionButtonView] {
        return Array(pooledButtons.prefix(visibleSuggestionCount))
    }

    /// 후보 영역이 가로로 넘쳐 스크롤될 수 있는 상태인지.
    ///
    /// 스크롤과 가장자리 페이드의 유일한 발생 조건이다. 후보 개수로 분기하지 않는다.
    /// 0.5pt는 부동소수 오차로 1pt도 안 되는 차이에 스크롤이 생기는 것을 막는 허용 오차다
    var isSuggestionAreaScrollable: Bool {
        return suggestionScrollView.contentSize.width
            > suggestionScrollView.bounds.width + SuggestionScrollFadePolicy.edgeTolerance
    }

    private var undoRedoViews: [UIView] {
        return [undoRedoLeadingDivider, undoButton, undoRedoMiddleDivider, redoButton]
    }

    private var clipboardViews: [UIView] {
        return [clipboardButton, clipboardDivider]
    }

    /// 히트테스트·하이라이트 대상 accessory 버튼. 인덱스가 `SuggestionHighlightPolicy`의 action 인덱스다
    private var actionButtons: [SuggestionActionButtonView] {
        return [clipboardButton, undoButton, redoButton]
    }

    private static let clipboardClosedSymbolName = "list.clipboard"
    private static let clipboardOpenSymbolName = "keyboard"
    private var isClipboardPanelVisible = false

    /// 화면에 한 번에 보이는 후보 칸 수. 버튼 폭 계산 기준이다
    private static let visibleSuggestionColumnCount = 3
    /// divider 두께
    private static let dividerWidth: CGFloat = 1
    /// 가장자리 페이드 폭
    private static let edgeFadeWidth: CGFloat = 16

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

    private lazy var suggestionScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .never
        // 키보드라 기본 150ms 지연을 쓸 수 없다. 손을 대는 즉시 하이라이트가 켜져야 한다
        scrollView.delaysContentTouches = false
        // 스택이 기능 버튼을 배치하고 남긴 공간을 이 뷰가 전부 가져간다
        scrollView.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        scrollView.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        scrollView.delegate = self

        return scrollView
    }()

    /// 스크롤 가장자리 페이드용 mask. 남은 방향에만 정지점을 넣어 흐리게 만든다
    private let edgeFadeLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]

        return layer
    }()

    private lazy var suggestionContentView: SuggestionScrollContentView = {
        let view = SuggestionScrollContentView()
        view.forwardingTarget = self

        return view
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

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSuggestionContent()
    }

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
        scheduleRemovalLongPress(at: point)
    }

    func moveTouchInteraction(to point: CGPoint) {
        guard !isTouchConsumedByRemoval else { return }
        if suggestionButton(at: point)?.0 != removalPressedIndex {
            cancelRemovalLongPress()
        }
        updateHighlight(at: point)
    }

    func endTouchInteraction(at point: CGPoint, playsFeedback: Bool) {
        guard !isTouchConsumedByRemoval else {
            resetTouchInteraction()
            return
        }

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

    /// 삭제 길게 누르기 타이머가 발동했을 때 호출됩니다.
    func handleRemovalLongPress() {
        removalLongPressWorkItem = nil
        guard let index = removalPressedIndex else { return }
        removalPressedIndex = nil
        guard suggestionDelegate?.suggestionBar(self, shouldBeginRemovalAt: index) == true else { return }
        isTouchConsumedByRemoval = true
        clearTouchHighlights()
    }

    func playSelectionFeedbackIfNeeded(_ shouldPlay: Bool) {
        guard shouldPlay else { return }
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playModifierSound()
    }

    func resetTouchInteraction() {
        cancelRemovalLongPress()
        isTouchConsumedByRemoval = false
        clearTouchHighlights()
        keyboardHStackView?.isUserInteractionEnabled = true
    }

    /// 자동완성 바를 업데이트합니다.
    ///
    /// `currentWord`가 있으면 0번 칸에 따옴표로 감싸서 표시하고
    /// 그 뒤 칸에 자동완성 후보를 표시합니다.
    /// `currentWord`가 없으면 0번 칸부터 n-gram 다음 단어 예측 후보를 표시합니다.
    ///
    /// - Parameters:
    ///   - currentWord: 현재 입력 중인 단어 (없으면 nil)
    ///   - suggestions: 자동완성 또는 예측 후보 배열
    func updateSuggestions(currentWord: String?, suggestions: [String]) {
        var titles: [String] = []
        if let word = currentWord, !word.isEmpty {
            // 입력 중: 0번 칸이 "현재단어", 그 뒤가 자동완성 후보
            titles.append("\"\(word)\"")
        }
        titles.append(contentsOf: suggestions)

        ensurePooledViews(count: titles.count)
        for (index, button) in pooledButtons.enumerated() {
            let title = index < titles.count ? titles[index] : ""
            button.update(to: title)
            button.isHidden = index >= titles.count
        }
        visibleSuggestionCount = titles.count

        applyDividerVisibility()
        suggestionScrollView.contentOffset = .zero
        setNeedsLayout()
        applyHighlights()
    }

    /// 스페이스로 자동 적용될 후보의 preview 하이라이트를 갱신합니다.
    ///
    /// 유효 범위는 지금 표시 중인 후보 버튼 개수를 따른다. 대상이 스크롤 밖에 있어도 자동으로 스크롤하지 않는다
    ///
    /// - Parameter index: 강조할 후보 인덱스, 없으면 `nil`
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
        isSuggestionAreaVisible = isVisible
        applyDividerVisibility()
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

    func updateDividers() {
        let buttons = suggestionButtons
        let firstHighlighted = isVisibleAndHighlighted(buttons.first)
        let lastHighlighted = isVisibleAndHighlighted(buttons.last)

        clipboardDivider.backgroundColor = (clipboardButton.isHighlighted || firstHighlighted)
        ? .clear
        : .suggestionDividerColor
        undoRedoLeadingDivider.backgroundColor = (lastHighlighted || undoButton.isHighlighted)
        ? .clear
        : .suggestionDividerColor
        undoRedoMiddleDivider.backgroundColor = (undoButton.isHighlighted || redoButton.isHighlighted)
        ? .clear
        : .suggestionDividerColor

        for index in pooledDividers.indices {
            let leadingHighlighted = buttons.indices.contains(index) && buttons[index].isHighlighted
            let trailingHighlighted = buttons.indices.contains(index + 1) && buttons[index + 1].isHighlighted
            pooledDividers[index].backgroundColor = (leadingHighlighted || trailingHighlighted)
            ? .clear
            : .suggestionDividerColor
        }
    }

    /// 경계 divider를 지울지 판단합니다.
    ///
    /// 스크롤로 뷰포트 밖에 완전히 나간 버튼 때문에 보이지도 않는 divider가 사라지는 것을 막는다
    func isVisibleAndHighlighted(_ button: SuggestionButtonView?) -> Bool {
        guard let button, button.isHighlighted else { return false }
        return button.frame.intersects(suggestionScrollView.bounds)
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
        suggestionScrollView.layer.mask = edgeFadeLayer
    }
    
    func setHierarchy() {
        self.addSubview(buttonContainerHStackView)

        [clipboardButton,
         clipboardDivider,
         suggestionScrollView,
         undoRedoLeadingDivider,
         undoButton,
         undoRedoMiddleDivider,
         redoButton].forEach {
            buttonContainerHStackView.addArrangedSubview($0)
        }

        suggestionScrollView.addSubview(suggestionContentView)
    }
    
    func setConstraints() {
        buttonContainerHStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonContainerHStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: KeyboardLayoutFigure.keyboardFrameSpacing),
            buttonContainerHStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            buttonContainerHStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            buttonContainerHStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
        ])
        
        [clipboardDivider, undoRedoLeadingDivider, undoRedoMiddleDivider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.widthAnchor.constraint(equalToConstant: SuggestionBarView.dividerWidth).isActive = true
            $0.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.suggestionButtonDividerHeight).isActive = true
        }

        suggestionScrollView.translatesAutoresizingMaskIntoConstraints = false
        suggestionScrollView.heightAnchor.constraint(
            equalTo: buttonContainerHStackView.heightAnchor
        ).isActive = true

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

    func scheduleRemovalLongPress(at point: CGPoint) {
        cancelRemovalLongPress()
        guard let index = suggestionButton(at: point)?.0 else { return }
        removalPressedIndex = index
        let workItem = DispatchWorkItem { [weak self] in
            self?.handleRemovalLongPress()
        }
        removalLongPressWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + KeyboardSuggestionSelectionPolicy.removalLongPressDuration,
            execute: workItem
        )
    }

    func cancelRemovalLongPress() {
        removalLongPressWorkItem?.cancel()
        removalLongPressWorkItem = nil
        removalPressedIndex = nil
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
    
    /// 풀에 버튼 `count`개와 divider `count - 1`개가 있도록 채웁니다.
    func ensurePooledViews(count: Int) {
        while pooledButtons.count < count {
            let button = SuggestionButtonView()
            suggestionContentView.addSubview(button)
            pooledButtons.append(button)
        }

        let dividerCount = max(count - 1, 0)
        while pooledDividers.count < dividerCount {
            let divider = UIView()
            divider.backgroundColor = .suggestionDividerColor
            suggestionContentView.addSubview(divider)
            pooledDividers.append(divider)
        }
    }

    /// 스크롤 content의 프레임과 `contentSize`를 갱신합니다.
    ///
    /// 버튼 폭은 뷰포트에 후보 3칸과 그 사이 divider 2개가 정확히 들어가는 값이다.
    /// 클립보드·undo/redo 버튼이 숨겨질 수 있어 뷰포트 폭이 변하므로 매 레이아웃마다 다시 계산한다
    func layoutSuggestionContent() {
        // 스크롤 뷰는 buttonContainerHStackView(스택)의 arranged subview라 스택 자신의
        // layoutSubviews()가 돌아야 프레임이 확정된다. bar의 layoutSubviews()는 스택보다
        // 먼저 호출되므로, 강제로 스택의 레이아웃을 먼저 끝내 확정된 뷰포트 폭을 읽는다
        buttonContainerHStackView.layoutIfNeeded()

        let viewportWidth = suggestionScrollView.bounds.width
        let viewportHeight = suggestionScrollView.bounds.height
        guard viewportWidth > 0, viewportHeight > 0 else { return }

        let dividerWidth = SuggestionBarView.dividerWidth
        let columnCount = CGFloat(SuggestionBarView.visibleSuggestionColumnCount)
        let buttonWidth = (viewportWidth - dividerWidth * (columnCount - 1)) / columnCount
        let dividerHeight = KeyboardLayoutFigure.suggestionButtonDividerHeight

        var offsetX: CGFloat = 0
        for index in 0..<visibleSuggestionCount {
            pooledButtons[index].frame = CGRect(
                x: offsetX,
                y: 0,
                width: buttonWidth,
                height: viewportHeight
            )
            offsetX += buttonWidth

            guard index < visibleSuggestionCount - 1 else { continue }
            pooledDividers[index].frame = CGRect(
                x: offsetX,
                y: (viewportHeight - dividerHeight) / 2,
                width: dividerWidth,
                height: dividerHeight
            )
            offsetX += dividerWidth
        }

        let contentWidth = max(offsetX, viewportWidth)
        suggestionContentView.frame = CGRect(
            x: 0,
            y: 0,
            width: contentWidth,
            height: viewportHeight
        )
        suggestionScrollView.contentSize = suggestionContentView.bounds.size
        updateEdgeFade()
    }

    /// 가장자리 페이드 mask의 프레임과 정지점을 갱신합니다.
    ///
    /// mask는 스크롤 뷰 `bounds` 좌표계라 `contentOffset`만큼 함께 움직인다. 매번 원점을 맞춘다
    func updateEdgeFade() {
        let bounds = suggestionScrollView.bounds
        guard bounds.width > 0 else { return }

        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: suggestionScrollView.contentOffset.x,
            viewportWidth: bounds.width,
            contentWidth: suggestionScrollView.contentSize.width
        )
        let fraction = min(SuggestionBarView.edgeFadeWidth / bounds.width, 0.5)
        let leading = NSNumber(value: state.showsLeadingFade ? Double(fraction) : 0)
        let trailing = NSNumber(value: state.showsTrailingFade ? Double(1 - fraction) : 1)

        // CALayer 암시적 애니메이션을 끄지 않으면 스크롤할 때마다 페이드가 늦게 따라온다
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        edgeFadeLayer.frame = bounds
        edgeFadeLayer.locations = [NSNumber(value: 0.0), leading, trailing, NSNumber(value: 1.0)]
        CATransaction.commit()
    }

    func applyDividerVisibility() {
        let visibleDividerCount = max(visibleSuggestionCount - 1, 0)
        for (index, divider) in pooledDividers.enumerated() {
            divider.isHidden = !isSuggestionAreaVisible || index >= visibleDividerCount
        }
    }
}

// MARK: - UIScrollViewDelegate

extension SuggestionBarView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateEdgeFade()
        updateDividers()
    }
}

// MARK: - Supporting Views

/// 스크롤 뷰 안에서 받은 터치를 `SuggestionBarView`의 터치 처리로 그대로 넘기는 content view
///
/// 터치 추적 상태를 따로 들지 않고 bar의 오버라이드를 그대로 부른다. 두 뷰가 각각 가드를 들면
/// 후보와 기능 버튼을 동시에 누를 때 두 터치가 각각 통과해 액션이 두 번 발생한다.
/// `UITouch.location(in:)`이 대상 뷰를 인자로 받으므로 어느 뷰가 터치를 받았든 바 좌표가 정확히 나온다.
/// 덕분에 `beginTouchInteraction(at:)` 계열의 본문은 스크롤 도입 전과 같다.
/// 손가락을 끌어 스크롤이 시작되면 `UIScrollView`가 여기로 `touchesCancelled`를 보낸다
private final class SuggestionScrollContentView: UIView {

    weak var forwardingTarget: SuggestionBarView?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        forwardingTarget?.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        forwardingTarget?.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        forwardingTarget?.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        forwardingTarget?.touchesCancelled(touches, with: event)
    }
}

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

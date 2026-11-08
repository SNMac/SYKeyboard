//
//  SymbolKeyboardView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/14/25.
//

import UIKit
import OSLog

/// 기호 키보드
final class SymbolKeyboardView: UIView, SymbolKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    public private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    public private(set) lazy var primaryButtonList: [PrimaryButton] = numberRowPrimaryKeyButtonList + firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + [thirdRowSplitDuplicateButton] + [spaceButton, atButton, periodButton, slashButton, dotComButton, leftSpaceButton]
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [shiftButton, deleteButton, switchButton, returnButton, nextKeyboardButton]
    + [languageSwitchButton].compactMap { $0 as SecondaryButton? }
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = numberRowPrimaryKeyButtonList + firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + [thirdRowSplitDuplicateButton]
    + [deleteButton, spaceButton, atButton, periodButton, slashButton, dotComButton, returnButton, leftSpaceButton]
    
    var currentSymbolKeyboardMode: SymbolKeyboardMode = .default {
        didSet(oldMode) {
            updateLayoutForCurrentSymbolKeyboardMode(oldMode: oldMode)
            isShifted = false
        }
    }
    
    var isShifted: Bool = false {
        didSet {
            shiftButton.updateShiftState(to: isShifted)
            updateKeyButtonList()
        }
    }
    var wasShifted: Bool = false
    
    /// `periodButton`의 너비 제약 조건
    public var periodButtonWidthConstraint: NSLayoutConstraint?
    /// 통합 키보드 modifier 영역의 너비 제약
    private var fourthRowModifierWidthConstraint: NSLayoutConstraint?
    /// 셋째 줄 키 너비 제약. 배열이 바뀌면 다시 만든다
    private var thirdRowWidthConstraints: [NSLayoutConstraint] = []
    /// 스페이스 묶음 너비 제약(한영 전환 버튼이 없을 때만 있음). 분할 자판에서는 끈다
    private var spaceButtonHStackWidthConstraint: NSLayoutConstraint?
    /// 분할 자판 여부
    private var usesSplitLayout = false
    /// 분할 자판에서 넷째 줄 간격을 가운데에 고정하는 제약
    private lazy var fourthRowSplitGapCenterConstraint = fourthRowSplitGap.centerXAnchor.constraint(
        equalTo: fourthRowHStackView.centerXAnchor
    )

    private let showsLanguageSwitchButton: Bool
    private let showsNumberRowSetting: Bool

    // MARK: - NormalKeyboardLayoutProvider

    public var showsNumberRow: Bool { showsNumberRowSetting }

    // MARK: - UI Components

    /// 키보드 레이아웃 수직 스택
    private let layoutVStackView = KeyboardLayoutVStackView()

    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView()
    /// 키보드 세번째 행
    private let thirdRowHStackView: KeyboardRowHStackView = {
        let keyboardRowHStackView = KeyboardRowHStackView()
        keyboardRowHStackView.distribution = .fill
        
        return keyboardRowHStackView
    }()
    /// 키보드 세번째 내부 행
    private let thirdRowInsideHStackView: KeyboardRowHStackView = {
        let keyboardRowHStackView = KeyboardRowHStackView()
        keyboardRowHStackView.distribution = .fill
        
        return keyboardRowHStackView
    }()
    /// 키보드 네번째 행
    private let fourthRowHStackView: KeyboardRowHStackView = {
        let keyboardRowHStackView = KeyboardRowHStackView()
        keyboardRowHStackView.distribution = .fill
        
        return keyboardRowHStackView
    }()
    public private(set) var fourthRowLeftSecondaryButtonHStackView = KeyboardRowHStackView()
    public private(set) var spaceButtonHStackView: KeyboardRowHStackView = {
        let keyboardRowHStackView = KeyboardRowHStackView()
        keyboardRowHStackView.distribution = .fill
        
        return keyboardRowHStackView
    }()
    
    /// 분할 자판에서 각 줄 가운데를 비우는 간격. 평소에는 숨긴다
    private let firstRowSplitGap = SymbolKeyboardView.makeHiddenSpacer()
    private let secondRowSplitGap = SymbolKeyboardView.makeHiddenSpacer()
    private let thirdRowSplitGap = SymbolKeyboardView.makeHiddenSpacer()
    private let fourthRowSplitGap = SymbolKeyboardView.makeHiddenSpacer()
    /// 스페이스가 없는 입력 모드(URL)의 분할 자판에서 왼쪽 반쪽 넷째 줄을 채우는 빈칸
    private let leftSpaceFillerSpacer = SymbolKeyboardView.makeHiddenSpacer()

    /// 키보드 숫자 행
    private lazy var numberRow = KeyboardNumberRow(isEnabled: showsNumberRowSetting)
    /// 숫자 행 `PrimaryKeyButton` 배열. 숫자 행이 꺼져 있으면 비어 있다
    var numberRowPrimaryKeyButtonList: [PrimaryKeyButton] { numberRow.buttonList }
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private(set) lazy var firstRowPrimaryKeyButtonList = SymbolKeyboardMode.keyList(usesNumberRow: showsNumberRowSetting)[0][0].map {
        PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
    }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowPrimaryKeyButtonList = SymbolKeyboardMode.keyList(usesNumberRow: showsNumberRowSetting)[0][1].map {
        PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
    }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private(set) lazy var thirdRowPrimaryKeyButtonList = SymbolKeyboardMode.keyList(usesNumberRow: showsNumberRowSetting)[0][2].map {
        PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
    }
    /// 셋째 줄 경계 키('?')의 위치. 분할 자판에서 양쪽 반쪽에 하나씩 보인다
    private var thirdRowSplitIndex: Int { thirdRowPrimaryKeyButtonList.count / 2 }
    /// 분할 자판 오른쪽 반쪽 셋째 줄 맨 앞의 경계 키. 평소에는 숨긴다
    private(set) lazy var thirdRowSplitDuplicateButton: PrimaryKeyButton = {
        let button = PrimaryKeyButton(
            keyboard: .symbol,
            button: .keyButton(
                primary: SymbolKeyboardMode.keyList(usesNumberRow: showsNumberRowSetting)[0][2][thirdRowSplitIndex],
                secondary: nil
            )
        )
        button.isHidden = true

        return button
    }()
    
    public private(set) var shiftButton = ShiftButton(keyboard: .symbol)
    public private(set) var deleteButton = DeleteButton(keyboard: .symbol)
    public private(set) var switchButton = SwitchButton(keyboard: .symbol)
    public private(set) lazy var languageSwitchButton: LanguageSwitchButton? = {
        guard showsLanguageSwitchButton else { return nil }
        return LanguageSwitchButton(mode: .hangeul, keyboard: .symbol)
    }()
    
    public private(set) var spaceButton = SpaceButton(keyboard: .symbol)
    /// 분할 자판 왼쪽 반쪽의 스페이스. 평소와 스페이스가 없는 입력 모드에서는 숨긴다
    private(set) var leftSpaceButton: SpaceButton = {
        let button = SpaceButton(keyboard: .symbol)
        button.isHidden = true

        return button
    }()
    public private(set) var atButton = PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: ["@"], secondary: nil))
    public private(set) var periodButton = PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: ["."], secondary: nil))
    public private(set) var slashButton = PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: ["/"], secondary: nil))
    public private(set) var dotComButton = PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: [".com"], secondary: nil))
    
    public private(set) var returnButton = ReturnButton(keyboard: .symbol)
    public private(set) var nextKeyboardButton = NextKeyboardButton(keyboard: .symbol)
    
    public private(set) var keyboardSelectOverlayView: KeyboardSelectOverlayView = {
        let overlayView = KeyboardSelectOverlayView(keyboard: .symbol)
        overlayView.isHidden = true
        
        return overlayView
    }()
    public private(set) var oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView = {
        let overlayView = OneHandedModeSelectOverlayView()
        overlayView.isHidden = true
        
        return overlayView
    }()
    
    // MARK: - Initializer
    
    init(showsLanguageSwitchButton: Bool = false, showsNumberRow: Bool = false) {
        self.showsLanguageSwitchButton = showsLanguageSwitchButton
        self.showsNumberRowSetting = showsNumberRow
        super.init(frame: .zero)
        setupUI()
        updateLayoutToDefault()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logger.debug("\(String(describing: type(of: self))) deinit")
    }
}

// MARK: - UI Methods

private extension SymbolKeyboardView {
    func setupUI() {
        setStyles()
        setActions()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
    }
    
    func setActions() {
        setShiftButtonAction()
    }
    
    func setHierarchy() {
        [layoutVStackView,
         keyboardSelectOverlayView,
         oneHandedModeSelectOverlayView].forEach { self.addSubview($0) }

        [firstRowHStackView,
         secondRowHStackView,
         thirdRowHStackView,
         fourthRowHStackView].forEach { layoutVStackView.addArrangedSubview($0) }
        
        firstRowPrimaryKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        firstRowHStackView.insertArrangedSubview(firstRowSplitGap, at: firstRowPrimaryKeyButtonList.count / 2)
        
        secondRowPrimaryKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        secondRowHStackView.insertArrangedSubview(secondRowSplitGap, at: secondRowPrimaryKeyButtonList.count / 2)
        
        [shiftButton, thirdRowInsideHStackView, deleteButton].forEach { thirdRowHStackView.addArrangedSubview($0) }
        thirdRowPrimaryKeyButtonList.forEach { thirdRowInsideHStackView.addArrangedSubview($0) }
        // 경계 키 뒤에 간격과 오른쪽 반쪽용 경계 키를 둔다
        [thirdRowSplitGap, thirdRowSplitDuplicateButton].enumerated().forEach { offset, view in
            thirdRowInsideHStackView.insertArrangedSubview(view, at: thirdRowSplitIndex + 1 + offset)
        }
        
        [fourthRowLeftSecondaryButtonHStackView,
         leftSpaceButton,
         leftSpaceFillerSpacer,
         fourthRowSplitGap,
         spaceButtonHStackView,
         returnButton].forEach { fourthRowHStackView.addArrangedSubview($0) }
        let modifierButtons: [SecondaryButton] = [switchButton]
        + [languageSwitchButton].compactMap { $0 }
        + [nextKeyboardButton]
        modifierButtons.forEach(fourthRowLeftSecondaryButtonHStackView.addArrangedSubview)
        [spaceButton, atButton, periodButton, slashButton, dotComButton].forEach { spaceButtonHStackView.addArrangedSubview($0) }
    }
    
    func setConstraints() {
        layoutVStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layoutVStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            layoutVStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            layoutVStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        numberRow.install(in: self, above: layoutVStackView)
        numberRow.installSplitGap(gapToKeyRatio: KeyboardSplitLayoutPolicy.edgeAlignedRowGapColumnCount)

        // 한 열의 폭은 첫 줄 키 폭이다. 평소에는 행 폭의 1/10, 분할 자판에서는 1/14가 된다
        guard let columnReferenceView = firstRowPrimaryKeyButtonList.first else {
            fatalError("firstRowPrimaryKeyButtonList가 비어있습니다.")
        }

        // 첫째·둘째 줄은 간격이 들어갈 수 있도록 `.fill`로 두고 키끼리 등폭으로 맞춘다.
        // 간격이 숨겨진 평소에는 `.fillEqually`와 같은 해가 나온다
        for (row, buttons, gap) in [(firstRowHStackView, firstRowPrimaryKeyButtonList, firstRowSplitGap),
                                    (secondRowHStackView, secondRowPrimaryKeyButtonList, secondRowSplitGap)] {
            row.distribution = .fill
            for button in buttons where button !== columnReferenceView {
                button.widthAnchor.constraint(equalTo: columnReferenceView.widthAnchor).isActive = true
            }
            activateSplitGapWidth(gap,
                                  columnReferenceView: columnReferenceView,
                                  columnCount: KeyboardSplitLayoutPolicy.edgeAlignedRowGapColumnCount)
        }
        activateSplitGapWidth(thirdRowSplitGap,
                              columnReferenceView: columnReferenceView,
                              columnCount: KeyboardSplitLayoutPolicy.gapColumnCount)
        activateSplitGapWidth(fourthRowSplitGap,
                              columnReferenceView: columnReferenceView,
                              columnCount: KeyboardSplitLayoutPolicy.gapColumnCount)

        updateThirdRowWidthConstraints()
        
        if let referenceView = firstRowPrimaryKeyButtonList.first {
            shiftButton.widthAnchor.constraint(
                equalTo: referenceView.widthAnchor,
                multiplier: KeyboardLayoutFigure.shiftAndDeleteButtonWidthMultiplier
            ).isActive = true
            deleteButton.widthAnchor.constraint(
                equalTo: referenceView.widthAnchor,
                multiplier: KeyboardLayoutFigure.shiftAndDeleteButtonWidthMultiplier
            ).isActive = true
        }
        
        fourthRowLeftSecondaryButtonHStackView.translatesAutoresizingMaskIntoConstraints = false
        if let languageSwitchButton,
           let referenceView = firstRowPrimaryKeyButtonList.first {
            fourthRowLeftSecondaryButtonHStackView.distribution = .fill
            languageSwitchButton.widthAnchor.constraint(
                equalTo: referenceView.widthAnchor,
                multiplier: KeyboardLayoutFigure.languageSwitchButtonWidthMultiplier
            ).isActive = true
            switchButton.widthAnchor.constraint(
                equalTo: referenceView.widthAnchor,
                multiplier: switchButtonWidthMultiplier
            ).isActive = true
            let globeWidth = nextKeyboardButton.widthAnchor.constraint(
                equalTo: referenceView.widthAnchor,
                multiplier: KeyboardLayoutFigure.nextKeyboardButtonWidthMultiplier
            )
            globeWidth.priority = .init(999)
            globeWidth.isActive = true
            updateFourthRowModifierWidthConstraint(needsInputModeSwitchKey: true)
        } else {
            // 행 폭의 1/4(2.5열). 분할 자판에서도 같은 폭을 쓰도록 열 폭 기준으로 건다
            fourthRowLeftSecondaryButtonHStackView.widthAnchor.constraint(
                equalTo: columnReferenceView.widthAnchor,
                multiplier: 0.25 * CGFloat(firstRowPrimaryKeyButtonList.count)
            ).isActive = true
        }
        
        spaceButtonHStackView.translatesAutoresizingMaskIntoConstraints = false
        if languageSwitchButton == nil,
           let superview = spaceButtonHStackView.superview {
            // 분할 자판에서는 왼쪽 스페이스와 나눠 가져야 하므로 `updateSplitLayout(_:)`이 끈다
            let widthConstraint = spaceButtonHStackView.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                                               multiplier: 0.5)
            widthConstraint.isActive = true
            spaceButtonHStackWidthConstraint = widthConstraint
        }
        
        atButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = atButton.superview {
            let widthConstraint = atButton.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                                  multiplier: 0.25)
            widthConstraint.priority = .init(999)
            widthConstraint.isActive = true
        }
        
        periodButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = periodButton.superview {
            periodButtonWidthConstraint = periodButton.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                                              multiplier: 0.2)
            periodButtonWidthConstraint?.priority = .init(999)
            periodButtonWidthConstraint?.isActive = true
        }
        
        slashButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = slashButton.superview {
            let widthConstraint = slashButton.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                                     multiplier: 1.0 / 3.0)
            widthConstraint.priority = .init(999)
            widthConstraint.isActive = true
        }
        
        dotComButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = dotComButton.superview {
            let widthConstraint = dotComButton.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                                      multiplier: 1.0 / 3.0)
            widthConstraint.priority = .init(999)
            widthConstraint.isActive = true
        }
        
        returnButton.translatesAutoresizingMaskIntoConstraints = false
        // 행 폭의 1/4(2.5열). 분할 자판에서도 같은 폭을 쓰도록 열 폭 기준으로 건다
        returnButton.widthAnchor.constraint(
            equalTo: columnReferenceView.widthAnchor,
            multiplier: KeyboardLayoutFigure.returnButtonWidthMultiplier * CGFloat(firstRowPrimaryKeyButtonList.count)
        ).isActive = true
        
        keyboardSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboardSelectOverlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            keyboardSelectOverlayView.bottomAnchor.constraint(equalTo: switchButton.topAnchor, constant: -4),
            keyboardSelectOverlayView.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.selectOverlayHeight)
        ])

        // 취소 영역의 경계선을 `switchButton` 오른쪽 모서리보다 안쪽에 둔다.
        // 오버레이가 열리는 순간 손가락이 이미 목표 쪽에 있게 된다
        let cancelBoundary = keyboardSelectOverlayView.xmarkImageContainerView.trailingAnchor.constraint(
            equalTo: switchButton.trailingAnchor,
            constant: -KeyboardLayoutFigure.keyboardSelectBoundaryInset
        )
        cancelBoundary.priority = .init(999)
        NSLayoutConstraint.activate([
            cancelBoundary,
            keyboardSelectOverlayView.xmarkImageContainerView.widthAnchor.constraint(
                greaterThanOrEqualToConstant: KeyboardLayoutFigure.keyboardSelectCancelMinWidth
            )
        ])
        
        oneHandedModeSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            oneHandedModeSelectOverlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            oneHandedModeSelectOverlayView.bottomAnchor.constraint(equalTo: switchButton.topAnchor, constant: -4),
            oneHandedModeSelectOverlayView.widthAnchor.constraint(equalToConstant: KeyboardLayoutFigure.oneHandedModeSelectOverlayWidth),
            oneHandedModeSelectOverlayView.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.selectOverlayHeight)
        ])
    }

    /// 분할 간격 폭을 열 폭 기준으로 건다.
    /// 숨겨진 동안에는 `UIStackView`의 숨김 제약(폭 0)이 이겨야 하므로 required보다 낮춘다
    func activateSplitGapWidth(_ gap: UIView, columnReferenceView: UIView, columnCount: CGFloat) {
        let width = gap.widthAnchor.constraint(equalTo: columnReferenceView.widthAnchor, multiplier: columnCount)
        width.priority = .init(999)
        width.isActive = true
    }

    static func makeHiddenSpacer() -> KeyboardSpacer {
        let spacer = KeyboardSpacer()
        spacer.isHidden = true

        return spacer
    }

    /// 분할 자판 넷째 줄 왼쪽 반쪽을 채운다. 스페이스가 있는 입력 모드면 스페이스를,
    /// 없는 모드(URL)면 빈칸을 둔다. 입력 모드가 바뀔 때마다 `updateKeyButtonList()`에서 다시 맞춘다
    func updateSplitLeftSpaceVisibility() {
        let showsLeftSpace = usesSplitLayout && !spaceButton.isHidden
        let showsFiller = usesSplitLayout && spaceButton.isHidden
        if leftSpaceButton.isHidden == showsLeftSpace { leftSpaceButton.isHidden = !showsLeftSpace }
        if leftSpaceFillerSpacer.isHidden == showsFiller { leftSpaceFillerSpacer.isHidden = !showsFiller }
    }

    /// `switchButton`과 한영 전환 버튼의 합이 리턴 버튼 너비와 같아지는 `switchButton` 계수
    var switchButtonWidthMultiplier: CGFloat {
        KeyboardLayoutFigure.switchButtonWidthMultiplier(columnCount: firstRowPrimaryKeyButtonList.count)
    }

    func updateFourthRowModifierWidthConstraint(needsInputModeSwitchKey: Bool) {
        guard let referenceView = firstRowPrimaryKeyButtonList.first else { return }

        let globeMultiplier = needsInputModeSwitchKey
        ? KeyboardLayoutFigure.nextKeyboardButtonWidthMultiplier
        : 0
        fourthRowModifierWidthConstraint?.isActive = false
        fourthRowModifierWidthConstraint = fourthRowLeftSecondaryButtonHStackView.widthAnchor.constraint(
            equalTo: referenceView.widthAnchor,
            multiplier: switchButtonWidthMultiplier
            + KeyboardLayoutFigure.languageSwitchButtonWidthMultiplier
            + globeMultiplier
        )
        fourthRowModifierWidthConstraint?.isActive = true
    }
}

// MARK: - Action Methods

private extension SymbolKeyboardView {
    func setShiftButtonAction() {
        let enableShift = UIAction { [weak self] _ in
            guard let self else { return }
            wasShifted = isShifted
            isShifted = true
        }
        shiftButton.addAction(enableShift, for: .touchDown)
        
        let disableShift = UIAction { [weak self] _ in
            guard let self else { return }
            if wasShifted {
                isShifted = false
            }
        }
        shiftButton.addAction(disableShift, for: .touchUpInside)
    }
}

// MARK: - Update Methods

private extension SymbolKeyboardView {
    func updateKeyButtonList() {
        let symbolKeyListIndex = (isShifted ? 1 : 0)
        let rowList = [firstRowPrimaryKeyButtonList, secondRowPrimaryKeyButtonList, thirdRowPrimaryKeyButtonList]
        for (rowIndex, buttonList) in rowList.enumerated() {
            for (buttonIndex, button) in buttonList.enumerated() {
                let primaryKeyList = SymbolKeyboardMode.keyList(usesNumberRow: showsNumberRowSetting)[symbolKeyListIndex][rowIndex][buttonIndex]
                button.update(buttonType: TextInteractableType.keyButton(primary: primaryKeyList, secondary: nil))
            }
        }
        // 경계 키 복제본은 원래 키와 같은 글자를 쓴다
        let duplicateKeyList = SymbolKeyboardMode.keyList(usesNumberRow: showsNumberRowSetting)[symbolKeyListIndex][2][thirdRowSplitIndex]
        thirdRowSplitDuplicateButton.update(buttonType: TextInteractableType.keyButton(primary: duplicateKeyList, secondary: nil))
        // `update`가 글자가 있으면 버튼을 보이게 하므로 분할 자판이 아닐 때는 다시 숨긴다
        thirdRowSplitDuplicateButton.isHidden = !usesSplitLayout
        // 입력 모드가 바뀌면 shift가 풀리며 여기로 오므로 스페이스 표시도 함께 맞춘다
        updateSplitLeftSpaceVisibility()
        updateThirdRowWidthConstraints()
    }

    /// 셋째 줄에서 실제로 보이는 키만 대상으로 양 끝 정렬을 다시 잡는다.
    /// 빈 키는 `PrimaryKeyButton`이 숨겨 너비가 0이 되므로 기준으로 쓸 수 없다
    func updateThirdRowWidthConstraints() {
        NSLayoutConstraint.deactivate(thirdRowWidthConstraints)
        thirdRowWidthConstraints.removeAll()

        // 분할 자판의 경계 키 복제본까지 화면 순서대로 본다
        let visibleButtons = thirdRowInsideHStackView.arrangedSubviews
            .compactMap { $0 as? PrimaryKeyButton }
            .filter { !$0.isHidden }
        guard let firstButton = visibleButtons.first,
              let lastButton = visibleButtons.last,
              let columnReferenceView = firstRowPrimaryKeyButtonList.first else { return }

        // 열 폭(첫 줄 키 폭) 기준이라 분할 자판에서도 같은 식을 쓴다
        let multiplier = KeyboardSplitLayoutPolicy.symbolThirdRowButtonWidthMultiplier(usesSplitLayout: usesSplitLayout)

        // 양 끝 버튼이 남는 폭을 똑같이 나눠 갖고, 시각 요소는 안쪽으로 붙인다
        if firstButton !== lastButton {
            thirdRowWidthConstraints.append(firstButton.widthAnchor.constraint(equalTo: lastButton.widthAnchor))
        }
        for button in visibleButtons where button !== firstButton && button !== lastButton {
            thirdRowWidthConstraints.append(
                button.widthAnchor.constraint(equalTo: columnReferenceView.widthAnchor, multiplier: multiplier)
            )
        }
        NSLayoutConstraint.activate(thirdRowWidthConstraints)

        for button in visibleButtons {
            button.translatesAutoresizingMaskIntoConstraints = false
            if button === firstButton {
                button.updateKeyAlignment(.right, referenceView: columnReferenceView, multiplier: multiplier)
            } else if button === lastButton {
                button.updateKeyAlignment(.left, referenceView: columnReferenceView, multiplier: multiplier)
            } else {
                button.updateKeyAlignment(.center, referenceView: nil, multiplier: multiplier)
            }
        }
    }
}

// MARK: - Internal Methods

extension SymbolKeyboardView {
    func nextKeyboardButtonVisibilityDidChange(needsInputModeSwitchKey: Bool) {
        guard languageSwitchButton != nil else { return }
        updateFourthRowModifierWidthConstraint(needsInputModeSwitchKey: needsInputModeSwitchKey)
        setNeedsLayout()
    }

    func updateNumberRowHeight(_ height: CGFloat) {
        numberRow.updateHeight(height)
    }

    /// 분할 자판 여부를 적용합니다.
    ///
    /// 각 줄 가운데 간격과 경계 키 복제본, 왼쪽 반쪽 스페이스를 보이거나 숨긴다.
    /// 열 폭은 첫 줄 키 폭을 기준으로 걸려 있어 간격이 보이면 저절로 1/14로 줄어든다
    func updateSplitLayout(_ usesSplitLayout: Bool) {
        guard usesSplitLayout != self.usesSplitLayout else { return }
        self.usesSplitLayout = usesSplitLayout

        [firstRowSplitGap, secondRowSplitGap, thirdRowSplitGap, fourthRowSplitGap].forEach {
            $0.isHidden = !usesSplitLayout
        }
        thirdRowSplitDuplicateButton.isHidden = !usesSplitLayout
        updateSplitLeftSpaceVisibility()
        // 스페이스 묶음 고정 폭과 가운데 고정은 함께 쓸 수 없으므로 순서대로 바꾼다
        if usesSplitLayout {
            spaceButtonHStackWidthConstraint?.isActive = false
            fourthRowSplitGapCenterConstraint.isActive = true
        } else {
            fourthRowSplitGapCenterConstraint.isActive = false
            spaceButtonHStackWidthConstraint?.isActive = true
        }
        numberRow.updateSplitLayout(usesSplitLayout)
        updateThirdRowWidthConstraints()
        setNeedsLayout()
    }

    func updatePeriodButtonWidthConstraint(multiplier: CGFloat?) {
        periodButtonWidthConstraint?.isActive = false
        
        guard let multiplier,
              let superview = periodButton.superview else { return }
        
        periodButtonWidthConstraint = periodButton.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                                          multiplier: multiplier)
        periodButtonWidthConstraint?.priority = .init(999)
        periodButtonWidthConstraint?.isActive = true
    }
}

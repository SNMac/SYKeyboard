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
    public private(set) lazy var primaryButtonList: [PrimaryButton] = numberRowPrimaryKeyButtonList + firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + [spaceButton, atButton, periodButton, slashButton, dotComButton]
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [shiftButton, deleteButton, switchButton, returnButton, nextKeyboardButton]
    + [languageSwitchButton].compactMap { $0 as SecondaryButton? }
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = numberRowPrimaryKeyButtonList + firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList
    + [deleteButton, spaceButton, atButton, periodButton, slashButton, dotComButton, returnButton]
    
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
    
    public private(set) var shiftButton = ShiftButton(keyboard: .symbol)
    public private(set) var deleteButton = DeleteButton(keyboard: .symbol)
    public private(set) var switchButton = SwitchButton(keyboard: .symbol)
    public private(set) lazy var languageSwitchButton: LanguageSwitchButton? = {
        guard showsLanguageSwitchButton else { return nil }
        return LanguageSwitchButton(mode: .hangeul, keyboard: .symbol)
    }()
    
    public private(set) var spaceButton = SpaceButton(keyboard: .symbol)
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
        
        secondRowPrimaryKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        
        [shiftButton, thirdRowInsideHStackView, deleteButton].forEach { thirdRowHStackView.addArrangedSubview($0) }
        thirdRowPrimaryKeyButtonList.forEach { thirdRowInsideHStackView.addArrangedSubview($0) }
        
        [fourthRowLeftSecondaryButtonHStackView, spaceButtonHStackView, returnButton].forEach { fourthRowHStackView.addArrangedSubview($0) }
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
        } else if let superview = fourthRowLeftSecondaryButtonHStackView.superview {
            fourthRowLeftSecondaryButtonHStackView.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                                          multiplier: 0.25).isActive = true
        }
        
        spaceButtonHStackView.translatesAutoresizingMaskIntoConstraints = false
        if languageSwitchButton == nil,
           let superview = spaceButtonHStackView.superview {
            spaceButtonHStackView.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                        multiplier: 0.5).isActive = true
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
        if let superview = returnButton.superview {
            returnButton.widthAnchor.constraint(
                equalTo: superview.widthAnchor,
                multiplier: KeyboardLayoutFigure.returnButtonWidthMultiplier
            ).isActive = true
        }
        
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
        updateThirdRowWidthConstraints()
    }

    /// 셋째 줄에서 실제로 보이는 키만 대상으로 양 끝 정렬을 다시 잡는다.
    /// 빈 키는 `PrimaryKeyButton`이 숨겨 너비가 0이 되므로 기준으로 쓸 수 없다
    func updateThirdRowWidthConstraints() {
        NSLayoutConstraint.deactivate(thirdRowWidthConstraints)
        thirdRowWidthConstraints.removeAll()

        let visibleButtons = thirdRowPrimaryKeyButtonList.filter { !$0.isHidden }
        guard let firstButton = visibleButtons.first,
              let lastButton = visibleButtons.last else { return }

        let multiplier = 1.0 / CGFloat(firstRowPrimaryKeyButtonList.count)
        * KeyboardLayoutFigure.symbolThirdRowButtonWidthMultiplier

        // 양 끝 버튼이 남는 폭을 똑같이 나눠 갖고, 시각 요소는 안쪽으로 붙인다
        if firstButton !== lastButton {
            thirdRowWidthConstraints.append(firstButton.widthAnchor.constraint(equalTo: lastButton.widthAnchor))
        }
        for button in visibleButtons where button !== firstButton && button !== lastButton {
            thirdRowWidthConstraints.append(
                button.widthAnchor.constraint(equalTo: thirdRowHStackView.widthAnchor, multiplier: multiplier)
            )
        }
        NSLayoutConstraint.activate(thirdRowWidthConstraints)

        for button in visibleButtons {
            button.translatesAutoresizingMaskIntoConstraints = false
            if button === firstButton {
                button.updateKeyAlignment(.right, referenceView: thirdRowHStackView, multiplier: multiplier)
            } else if button === lastButton {
                button.updateKeyAlignment(.left, referenceView: thirdRowHStackView, multiplier: multiplier)
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

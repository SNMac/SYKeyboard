//
//  StandardKeyboardView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/12/25.
//

import UIKit
import OSLog

open class StandardKeyboardView: UIView, NormalKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    /// 키보드 종류
    open var keyboard: SYKeyboardType { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 키 배열
    open var primaryKeyList: [[[[String]]]] { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 보조 키 배열
    open var secondaryKeyList: [[[[String]]]] { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    
    public private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    public private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + [spaceButton, atButton, periodButton, slashButton, dotComButton]
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [shiftButton, deleteButton, switchButton, returnButton, secondaryAtButton, secondarySharpButton, nextKeyboardButton]
    + [languageSwitchButton].compactMap { $0 as SecondaryButton? }
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList
    + [deleteButton, spaceButton, atButton, periodButton, slashButton, dotComButton, returnButton, secondaryAtButton, secondarySharpButton]
    
    final public var isShifted: Bool = false {
        didSet {
            shiftButton.updateShiftState(to: isShifted)
            updateKeyButtonList()
        }
    }
    final public var wasShifted: Bool = false
    
    /// `periodButton`의 너비 제약 조건을 저장하는 변수
    public var periodButtonWidthConstraint: NSLayoutConstraint?
    /// 통합 키보드 modifier 영역의 너비 제약
    private var fourthRowModifierWidthConstraint: NSLayoutConstraint?
    
    // Initializer Injection
    public let getIsShiftedLetterInput: () -> Bool
    public let setIsShiftedLetterInput: (Bool) -> ()
    private let showsLanguageSwitchButton: Bool
    
    // MARK: - UI Components
    
    /// 키보드 레이아웃 수직 스택
    private let layoutVStackView = KeyboardLayoutVStackView()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView: KeyboardRowHStackView = {
        let keyboardRowHStackView = KeyboardRowHStackView()
        keyboardRowHStackView.distribution = .fill
        
        return keyboardRowHStackView
    }()
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
    public private(set) var returnButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private lazy var firstRowPrimaryKeyButtonList = zip(primaryKeyList[0][0], secondaryKeyList[0][0]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowPrimaryKeyButtonList = zip(primaryKeyList[0][1], secondaryKeyList[0][1]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private lazy var thirdRowPrimaryKeyButtonList = zip(primaryKeyList[0][2], secondaryKeyList[0][2]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    
    public lazy var shiftButton = ShiftButton(keyboard: keyboard)
    public private(set) lazy var deleteButton = DeleteButton(keyboard: keyboard)
    public private(set) lazy var switchButton = SwitchButton(keyboard: keyboard)
    public private(set) lazy var languageSwitchButton: LanguageSwitchButton? = {
        guard showsLanguageSwitchButton else { return nil }
        let mode: HangeulEnglishLanguageMode = keyboard == .qwerty ? .english : .hangeul
        return LanguageSwitchButton(mode: mode, keyboard: keyboard)
    }()
    
    // 스페이스 버튼 위치
    public private(set) lazy var spaceButton = SpaceButton(keyboard: keyboard)
    public private(set) lazy var atButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(primary: ["@"], secondary: nil))
    public private(set) lazy var periodButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(primary: ["."], secondary: nil))
    public private(set) lazy var slashButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(primary: ["/"], secondary: nil))
    public private(set) lazy var dotComButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(primary: [".com"], secondary: nil))
    
    // 리턴 버튼 위치
    public private(set) lazy var returnButton = ReturnButton(keyboard: keyboard)
    public private(set) lazy var secondaryAtButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(primary: ["@"], secondary: nil))
    public private(set) lazy var secondarySharpButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(primary: ["#"], secondary: nil))
    
    public private(set) lazy var nextKeyboardButton = NextKeyboardButton(keyboard: keyboard)
    
    public private(set) lazy var keyboardSelectOverlayView: KeyboardSelectOverlayView = {
        let keyboardSelectOverlayView = KeyboardSelectOverlayView(keyboard: keyboard)
        keyboardSelectOverlayView.isHidden = true
        
        return keyboardSelectOverlayView
    }()
    public private(set) var oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView = {
        let oneHandedModeSelectOverlayView = OneHandedModeSelectOverlayView()
        oneHandedModeSelectOverlayView.isHidden = true
        
        return oneHandedModeSelectOverlayView
    }()
    
    // MARK: - Initializer
    
    public init(
        getIsShiftedLetterInput: @escaping () -> Bool,
        setIsShiftedLetterInput: @escaping (Bool) -> (),
        showsLanguageSwitchButton: Bool = false
    ) {
        self.getIsShiftedLetterInput = getIsShiftedLetterInput
        self.setIsShiftedLetterInput = setIsShiftedLetterInput
        self.showsLanguageSwitchButton = showsLanguageSwitchButton
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logger.debug("\(String(describing: type(of: self))) deinit")
    }
    
    // MARK: - Overridable Methods
    
    open func setShiftButtonAction() {
        let enableShift = UIAction { [weak self] _ in
            guard let self else { return }
            wasShifted = isShifted
            isShifted = true
        }
        shiftButton.addAction(enableShift, for: .touchDown)
        
        let disableShift = UIAction { [weak self] _ in
            guard let self else { return }
            if wasShifted || getIsShiftedLetterInput() {
                isShifted = false
                setIsShiftedLetterInput(false)
            }
        }
        shiftButton.addAction(disableShift, for: .touchUpInside)
    }
}

// MARK: - UI Methods

private extension StandardKeyboardView {
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
        
        [fourthRowLeftSecondaryButtonHStackView, spaceButtonHStackView, returnButtonHStackView].forEach { fourthRowHStackView.addArrangedSubview($0) }
        let modifierButtons: [SecondaryButton] = [switchButton]
        + [languageSwitchButton].compactMap { $0 }
        + [nextKeyboardButton]
        modifierButtons.forEach(fourthRowLeftSecondaryButtonHStackView.addArrangedSubview)
        [spaceButton, atButton, periodButton, slashButton, dotComButton].forEach { spaceButtonHStackView.addArrangedSubview($0) }
        [returnButton, secondaryAtButton, secondarySharpButton].forEach { returnButtonHStackView.addArrangedSubview($0) }
    }
    
    func setConstraints() {
        layoutVStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layoutVStackView.topAnchor.constraint(equalTo: self.topAnchor),
            layoutVStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            layoutVStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            layoutVStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        for (index, button) in secondRowPrimaryKeyButtonList.enumerated() {
            button.translatesAutoresizingMaskIntoConstraints = false
            guard let superview = button.superview else { continue }
            
            let multiplier = 1.0 / CGFloat(firstRowPrimaryKeyButtonList.count)
            if index == 0 {
                guard let lastButton = secondRowPrimaryKeyButtonList.last else { fatalError("secondRowPrimaryKeyButtonList가 비어있습니다.") }
                button.widthAnchor.constraint(equalTo: lastButton.widthAnchor).isActive = true
                button.updateKeyAlignment(.right,
                                          referenceView: superview,
                                          multiplier: multiplier)
                
            } else if index == secondRowPrimaryKeyButtonList.count - 1 {
                button.updateKeyAlignment(.left,
                                          referenceView: superview,
                                          multiplier: multiplier)
                
            } else {
                button.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                              multiplier: multiplier).isActive = true
            }
        }
        
        for (index, button) in thirdRowPrimaryKeyButtonList.enumerated() {
            button.translatesAutoresizingMaskIntoConstraints = false
            
            let multiplier = 1.0 / CGFloat(firstRowPrimaryKeyButtonList.count)
            if index == 0 {
                guard let lastButton = thirdRowPrimaryKeyButtonList.last else { fatalError("thirdRowPrimaryKeyButtonList가 비어있습니다.") }
                button.widthAnchor.constraint(equalTo: lastButton.widthAnchor).isActive = true
                button.updateKeyAlignment(.right,
                                          referenceView: thirdRowHStackView,
                                          multiplier: multiplier)
                
            } else if index == thirdRowPrimaryKeyButtonList.count - 1 {
                button.updateKeyAlignment(.left,
                                          referenceView: thirdRowHStackView,
                                          multiplier: multiplier)
                
            } else {
                button.widthAnchor.constraint(equalTo: thirdRowHStackView.widthAnchor,
                                              multiplier: multiplier).isActive = true
            }
        }
        
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
            fourthRowLeftSecondaryButtonHStackView.widthAnchor
                .constraint(equalTo: superview.widthAnchor, multiplier: 0.25)
                .isActive = true
        }
        
        atButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = atButton.superview {
            let widthConstraint = atButton.widthAnchor.constraint(
                equalTo: superview.widthAnchor,
                multiplier: 0.25
            )
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
            let widthConstraint = slashButton.widthAnchor.constraint(
                equalTo: superview.widthAnchor,
                multiplier: 1.0/3.0
            )
            widthConstraint.priority = .init(999)
            widthConstraint.isActive = true
        }
        
        dotComButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = dotComButton.superview {
            let widthConstraint = dotComButton.widthAnchor.constraint(
                equalTo: superview.widthAnchor,
                multiplier: 1.0/3.0
            )
            widthConstraint.priority = .init(999)
            widthConstraint.isActive = true
        }
        
        returnButtonHStackView.translatesAutoresizingMaskIntoConstraints = false
        if let superview = returnButtonHStackView.superview {
            returnButtonHStackView.widthAnchor.constraint(
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

// MARK: - Update Methods

extension StandardKeyboardView {
    final public func nextKeyboardButtonVisibilityDidChange(needsInputModeSwitchKey: Bool) {
        guard languageSwitchButton != nil else { return }
        updateFourthRowModifierWidthConstraint(needsInputModeSwitchKey: needsInputModeSwitchKey)
        setNeedsLayout()
    }

    /// `periodButton`의 너비 제약 조건을 업데이트합니다.
    /// - Parameter multiplier: 설정할 비율 (`nil`인 경우 제약 조건 비활성화)
    final public func updatePeriodButtonWidthConstraint(multiplier: CGFloat?) {
        periodButtonWidthConstraint?.isActive = false
        
        guard let multiplier else { return }
        
        if let superview = periodButton.superview {
            periodButtonWidthConstraint = periodButton.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: multiplier)
            periodButtonWidthConstraint?.priority = .init(999)
            periodButtonWidthConstraint?.isActive = true
        }
    }
    
    final public func updateKeyButtonList() {
        let keyListIndex = (isShifted ? 1 : 0)
        let rowList = [firstRowPrimaryKeyButtonList, secondRowPrimaryKeyButtonList, thirdRowPrimaryKeyButtonList]
        for (rowIndex, buttonList) in rowList.enumerated() {
            for (buttonIndex, button) in buttonList.enumerated() {
                let primaryKeyList = primaryKeyList[keyListIndex][rowIndex][buttonIndex]
                let secondaryKeyList = secondaryKeyList[keyListIndex][rowIndex][buttonIndex]
                button.update(buttonType: TextInteractableType.keyButton(primary: primaryKeyList, secondary: secondaryKeyList.first))
            }
        }
    }
}

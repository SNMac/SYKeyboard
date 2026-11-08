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
    public private(set) lazy var primaryButtonList: [PrimaryButton] = numberRowPrimaryKeyButtonList + firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + splitDuplicateButtonList + [spaceButton, atButton, periodButton, slashButton, dotComButton, leftSpaceButton]
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [shiftButton, deleteButton, switchButton, returnButton, secondaryAtButton, secondarySharpButton, nextKeyboardButton]
    + [languageSwitchButton].compactMap { $0 as SecondaryButton? }
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = numberRowPrimaryKeyButtonList + firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + splitDuplicateButtonList
    + [deleteButton, spaceButton, atButton, periodButton, slashButton, dotComButton, returnButton, secondaryAtButton, secondarySharpButton, leftSpaceButton]
    
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
    /// 분할 자판 여부
    private var usesSplitLayout = false
    /// 분할 자판에서 넷째 줄 간격을 가운데에 고정하는 제약.
    /// 넷째 줄은 왼쪽(스페이스)과 오른쪽(스페이스 묶음) 두 곳이 늘어나므로 간격 위치를 정해 줘야 한다
    private lazy var fourthRowSplitGapCenterConstraint = fourthRowSplitGap.centerXAnchor.constraint(
        equalTo: fourthRowHStackView.centerXAnchor
    )

    // Initializer Injection
    public let getIsShiftedLetterInput: () -> Bool
    public let setIsShiftedLetterInput: (Bool) -> ()
    private let showsLanguageSwitchButton: Bool
    /// 숫자 행 표시 여부
    public let showsNumberRow: Bool
    /// 실제 버튼에 쓰는 보조 키 배열. 숫자 행이 켜져 있으면 숫자 대신 shift 짝 문자를 쓴다
    private var resolvedSecondaryKeyList: [[[[String]]]] {
        showsNumberRow
        ? KeyboardTextInteractionPolicy.shiftPairSecondaryKeyList(from: primaryKeyList)
        : secondaryKeyList
    }

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

    /// 분할 자판에서 각 줄 가운데를 비우는 간격. 평소에는 숨긴다
    private let firstRowSplitGap = StandardKeyboardView.makeSplitGap()
    private let secondRowSplitGap = StandardKeyboardView.makeSplitGap()
    private let thirdRowSplitGap = StandardKeyboardView.makeSplitGap()
    private let fourthRowSplitGap = StandardKeyboardView.makeSplitGap()
    /// 스페이스가 없는 입력 모드(URL)의 분할 자판에서 왼쪽 반쪽 넷째 줄을 채우는 빈칸
    private let leftSpaceFillerSpacer = StandardKeyboardView.makeSplitGap()
    
    /// 숫자 행
    private lazy var numberRow = KeyboardNumberRow(isEnabled: showsNumberRow)
    /// 숫자 행 `PrimaryKeyButton` 배열. 숫자 행이 꺼져 있으면 비어 있다
    private var numberRowPrimaryKeyButtonList: [PrimaryKeyButton] { numberRow.buttonList }
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private lazy var firstRowPrimaryKeyButtonList = zip(primaryKeyList[0][0], resolvedSecondaryKeyList[0][0]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowPrimaryKeyButtonList = zip(primaryKeyList[0][1], resolvedSecondaryKeyList[0][1]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private lazy var thirdRowPrimaryKeyButtonList = zip(primaryKeyList[0][2], resolvedSecondaryKeyList[0][2]).map { (primary, secondary) in
        PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primary, secondary: secondary.first)
        )
    }

    /// 둘째 줄 경계 키(두벌식 ㅎ, 영문 G)의 위치. 분할 자판에서 양쪽 반쪽에 하나씩 보인다
    private var secondRowSplitIndex: Int { secondRowPrimaryKeyButtonList.count / 2 }
    /// 셋째 줄 경계 키(두벌식 ㅍ, 영문 V)의 위치
    private var thirdRowSplitIndex: Int { thirdRowPrimaryKeyButtonList.count / 2 }
    /// 분할 자판 오른쪽 반쪽 둘째 줄 맨 앞의 경계 키. 평소에는 숨긴다
    private lazy var secondRowSplitDuplicateButton = makeSplitDuplicateButton(row: 1, index: secondRowSplitIndex)
    /// 분할 자판 오른쪽 반쪽 셋째 줄 맨 앞의 경계 키. 평소에는 숨긴다
    private lazy var thirdRowSplitDuplicateButton = makeSplitDuplicateButton(row: 2, index: thirdRowSplitIndex)
    /// 분할 자판에서만 보이는 경계 키 배열
    private var splitDuplicateButtonList: [PrimaryKeyButton] { [secondRowSplitDuplicateButton, thirdRowSplitDuplicateButton] }
    
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
    /// 분할 자판 왼쪽 반쪽의 스페이스. 평소와 스페이스가 없는 입력 모드에서는 숨긴다
    public private(set) lazy var leftSpaceButton: SpaceButton = {
        let button = SpaceButton(keyboard: keyboard)
        button.isHidden = true

        return button
    }()
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
        showsLanguageSwitchButton: Bool = false,
        showsNumberRow: Bool = UserDefaultsManager.shared.showsNumberRow
    ) {
        self.getIsShiftedLetterInput = getIsShiftedLetterInput
        self.setIsShiftedLetterInput = setIsShiftedLetterInput
        self.showsLanguageSwitchButton = showsLanguageSwitchButton
        self.showsNumberRow = showsNumberRow
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
        self.addSubview(layoutVStackView)
        [keyboardSelectOverlayView,
         oneHandedModeSelectOverlayView].forEach { self.addSubview($0) }

        [firstRowHStackView,
         secondRowHStackView,
         thirdRowHStackView,
         fourthRowHStackView].forEach { layoutVStackView.addArrangedSubview($0) }
        
        firstRowPrimaryKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        firstRowHStackView.insertArrangedSubview(firstRowSplitGap, at: firstRowPrimaryKeyButtonList.count / 2)
        
        secondRowPrimaryKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        // 경계 키 뒤에 간격과 오른쪽 반쪽용 경계 키를 둔다
        [secondRowSplitGap, secondRowSplitDuplicateButton].enumerated().forEach { offset, view in
            secondRowHStackView.insertArrangedSubview(view, at: secondRowSplitIndex + 1 + offset)
        }
        
        [shiftButton, thirdRowInsideHStackView, deleteButton].forEach { thirdRowHStackView.addArrangedSubview($0) }
        thirdRowPrimaryKeyButtonList.forEach { thirdRowInsideHStackView.addArrangedSubview($0) }
        [thirdRowSplitGap, thirdRowSplitDuplicateButton].enumerated().forEach { offset, view in
            thirdRowInsideHStackView.insertArrangedSubview(view, at: thirdRowSplitIndex + 1 + offset)
        }
        
        [fourthRowLeftSecondaryButtonHStackView,
         leftSpaceButton,
         leftSpaceFillerSpacer,
         fourthRowSplitGap,
         spaceButtonHStackView,
         returnButtonHStackView].forEach { fourthRowHStackView.addArrangedSubview($0) }
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

        // 첫 줄은 간격이 들어갈 수 있도록 `.fill`로 두고 키끼리 등폭으로 맞춘다.
        // 간격이 숨겨진 평소에는 `.fillEqually`와 같은 해가 나온다
        firstRowHStackView.distribution = .fill
        firstRowPrimaryKeyButtonList.dropFirst().forEach {
            $0.widthAnchor.constraint(equalTo: columnReferenceView.widthAnchor).isActive = true
        }
        activateSplitGapWidth(firstRowSplitGap,
                              columnReferenceView: columnReferenceView,
                              columnCount: KeyboardSplitLayoutPolicy.edgeAlignedRowGapColumnCount)

        for (index, button) in secondRowPrimaryKeyButtonList.enumerated() {
            button.translatesAutoresizingMaskIntoConstraints = false
            
            if index == 0 {
                guard let lastButton = secondRowPrimaryKeyButtonList.last else { fatalError("secondRowPrimaryKeyButtonList가 비어있습니다.") }
                button.widthAnchor.constraint(equalTo: lastButton.widthAnchor).isActive = true
                button.updateKeyAlignment(.right,
                                          referenceView: columnReferenceView,
                                          multiplier: 1.0)
                
            } else if index == secondRowPrimaryKeyButtonList.count - 1 {
                button.updateKeyAlignment(.left,
                                          referenceView: columnReferenceView,
                                          multiplier: 1.0)
                
            } else {
                button.widthAnchor.constraint(equalTo: columnReferenceView.widthAnchor).isActive = true
            }
        }
        activateSplitDuplicateWidth(secondRowSplitDuplicateButton, columnReferenceView: columnReferenceView)
        activateSplitGapWidth(secondRowSplitGap,
                              columnReferenceView: columnReferenceView,
                              columnCount: KeyboardSplitLayoutPolicy.gapColumnCount)
        
        for (index, button) in thirdRowPrimaryKeyButtonList.enumerated() {
            button.translatesAutoresizingMaskIntoConstraints = false
            
            if index == 0 {
                guard let lastButton = thirdRowPrimaryKeyButtonList.last else { fatalError("thirdRowPrimaryKeyButtonList가 비어있습니다.") }
                button.widthAnchor.constraint(equalTo: lastButton.widthAnchor).isActive = true
                button.updateKeyAlignment(.right,
                                          referenceView: columnReferenceView,
                                          multiplier: 1.0)
                
            } else if index == thirdRowPrimaryKeyButtonList.count - 1 {
                button.updateKeyAlignment(.left,
                                          referenceView: columnReferenceView,
                                          multiplier: 1.0)
                
            } else {
                button.widthAnchor.constraint(equalTo: columnReferenceView.widthAnchor).isActive = true
            }
        }
        activateSplitDuplicateWidth(thirdRowSplitDuplicateButton, columnReferenceView: columnReferenceView)
        activateSplitGapWidth(thirdRowSplitGap,
                              columnReferenceView: columnReferenceView,
                              columnCount: KeyboardSplitLayoutPolicy.gapColumnCount)
        
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
            fourthRowLeftSecondaryButtonHStackView.widthAnchor
                .constraint(equalTo: columnReferenceView.widthAnchor,
                            multiplier: 0.25 * CGFloat(firstRowPrimaryKeyButtonList.count))
                .isActive = true
        }
        activateSplitGapWidth(fourthRowSplitGap,
                              columnReferenceView: columnReferenceView,
                              columnCount: KeyboardSplitLayoutPolicy.gapColumnCount)
        
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
        // 행 폭의 1/4(2.5열). 분할 자판에서도 같은 폭을 쓰도록 열 폭 기준으로 건다
        returnButtonHStackView.widthAnchor.constraint(
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

    /// 경계 키 복제본을 한 열 폭으로 건다. 숨겨진 동안을 위해 required보다 낮춘다
    func activateSplitDuplicateWidth(_ button: PrimaryKeyButton, columnReferenceView: UIView) {
        button.translatesAutoresizingMaskIntoConstraints = false
        let width = button.widthAnchor.constraint(equalTo: columnReferenceView.widthAnchor)
        width.priority = .init(999)
        width.isActive = true
    }

    /// 분할 자판 경계 키 복제본을 만든다. 처음에는 숨겨 둔다
    func makeSplitDuplicateButton(row: Int, index: Int) -> PrimaryKeyButton {
        let button = PrimaryKeyButton(
            keyboard: keyboard,
            button: .keyButton(primary: primaryKeyList[0][row][index],
                               secondary: resolvedSecondaryKeyList[0][row][index].first)
        )
        button.isHidden = true

        return button
    }

    static func makeSplitGap() -> KeyboardSpacer {
        let gap = KeyboardSpacer()
        gap.isHidden = true

        return gap
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

// MARK: - Update Methods

extension StandardKeyboardView {
    final public func nextKeyboardButtonVisibilityDidChange(needsInputModeSwitchKey: Bool) {
        guard languageSwitchButton != nil else { return }
        updateFourthRowModifierWidthConstraint(needsInputModeSwitchKey: needsInputModeSwitchKey)
        setNeedsLayout()
    }

    final public func updateNumberRowHeight(_ height: CGFloat) {
        numberRow.updateHeight(height)
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
        let resolvedSecondaryKeyList = resolvedSecondaryKeyList
        let rowList = [firstRowPrimaryKeyButtonList, secondRowPrimaryKeyButtonList, thirdRowPrimaryKeyButtonList]
        for (rowIndex, buttonList) in rowList.enumerated() {
            for (buttonIndex, button) in buttonList.enumerated() {
                let primaryKeyList = primaryKeyList[keyListIndex][rowIndex][buttonIndex]
                let secondaryKeyList = resolvedSecondaryKeyList[keyListIndex][rowIndex][buttonIndex]
                button.update(buttonType: TextInteractableType.keyButton(primary: primaryKeyList, secondary: secondaryKeyList.first))
            }
        }
        // 경계 키 복제본은 원래 키와 같은 글자를 쓴다
        for (rowIndex, index, button) in [(1, secondRowSplitIndex, secondRowSplitDuplicateButton),
                                          (2, thirdRowSplitIndex, thirdRowSplitDuplicateButton)] {
            let primaryKeyList = primaryKeyList[keyListIndex][rowIndex][index]
            let secondaryKeyList = resolvedSecondaryKeyList[keyListIndex][rowIndex][index]
            button.update(buttonType: TextInteractableType.keyButton(primary: primaryKeyList, secondary: secondaryKeyList.first))
            // `update`가 글자가 있으면 버튼을 보이게 하므로 분할 자판이 아닐 때는 다시 숨긴다
            button.isHidden = !usesSplitLayout
        }
        // 입력 모드가 바뀌면 shift가 풀리며 여기로 오므로 스페이스 표시도 함께 맞춘다
        updateSplitLeftSpaceVisibility()
    }

    /// 분할 자판 여부를 적용합니다.
    ///
    /// 각 줄 가운데 간격과 경계 키 복제본, 왼쪽 반쪽 스페이스를 보이거나 숨긴다.
    /// 열 폭은 첫 줄 키 폭을 기준으로 걸려 있어 간격이 보이면 저절로 1/14로 줄어든다
    public func updateSplitLayout(_ usesSplitLayout: Bool) {
        guard usesSplitLayout != self.usesSplitLayout else { return }
        self.usesSplitLayout = usesSplitLayout

        [firstRowSplitGap, secondRowSplitGap, thirdRowSplitGap, fourthRowSplitGap].forEach {
            $0.isHidden = !usesSplitLayout
        }
        splitDuplicateButtonList.forEach { $0.isHidden = !usesSplitLayout }
        updateSplitLeftSpaceVisibility()
        fourthRowSplitGapCenterConstraint.isActive = usesSplitLayout
        numberRow.updateSplitLayout(usesSplitLayout)
        setNeedsLayout()
    }

    /// 스페이스 이미지는 분할 자판 왼쪽 반쪽의 스페이스에도 같이 적용한다
    public func updateSpaceButtonImage(systemName: String) {
        spaceButton.updateImage(systemName: systemName)
        leftSpaceButton.updateImage(systemName: systemName)
    }
}

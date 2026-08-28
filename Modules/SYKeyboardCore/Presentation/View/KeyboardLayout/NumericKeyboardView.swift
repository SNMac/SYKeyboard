//
//  NumericKeyboardView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/14/25.
//

import UIKit
import OSLog

/// 숫자 키보드
final class NumericKeyboardView: UIView, NumericKeyboardLayoutProvider {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    public private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    public private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + fourthRowPrimaryKeyButtonList + [spaceButton]
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [deleteButton, returnButton, switchButton, nextKeyboardButton]
    + [languageSwitchButton].compactMap { $0 as SecondaryButton? }
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + fourthRowPrimaryKeyButtonList + [deleteButton, spaceButton, returnButton]
    
    private let showsLanguageSwitchButton: Bool

    /// 스페이스를 맨 아랫줄로 내리는 배치 사용 여부.
    /// `SwitchGestureHandling` 요구사항이므로 `public`이어야 한다
    public let usesBottomSpaceLayout: Bool

    /// 4열 폭 비율 제약 관리자
    private let columnWidthLayoutController = FourColumnWidthLayoutController()

    /// 숫자 키보드 키 배열
    private let numericKeyList = [
        [ ["1"], ["2"], ["3"] ],
        [ ["4"], ["5"], ["6"] ],
        [ ["7"], ["8"], ["9"] ],
        [ ["-"], [","], ["0"], ["."], ["/"] ]
    ]
    
    // MARK: - UI Components
    
    /// 키보드 레이아웃 수직 스택
    private let layoutVStackView = KeyboardLayoutVStackView()
    
    /// 키보드 첫번째 행
    private let firstRowHStackView = KeyboardRowHStackView()
    /// 키보드 두번째 행
    private let secondRowHStackView = KeyboardRowHStackView()
    /// 키보드 세번째 행
    private let thirdRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 행
    private let fourthRowHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 좌측 `PrimaryKeyButton` 행
    private let fourthRowLeftPrimaryButtonHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 우측 `PrimaryKeyButton` 행
    private let fourthRowRightPrimaryButtonHStackView = KeyboardRowHStackView()
    /// 키보드 네번째 우측 `SecondaryButton` 행
    private let fourthRowRightSecondaryButtonHStackView = KeyboardRowHStackView()
    
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private lazy var firstRowPrimaryKeyButtonList = numericKeyList[0].map {
        PrimaryKeyButton(keyboard: .numeric, button: .keyButton(primary: $0, secondary: nil))
    }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowPrimaryKeyButtonList = numericKeyList[1].map {
        PrimaryKeyButton(keyboard: .numeric, button: .keyButton(primary: $0, secondary: nil))
    }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private lazy var thirdRowPrimaryKeyButtonList = numericKeyList[2].map {
        PrimaryKeyButton(keyboard: .numeric, button: .keyButton(primary: $0, secondary: nil))
    }
    /// 키보드 네번째 행 `PrimaryKeyButton` 배열
    private lazy var fourthRowPrimaryKeyButtonList = numericKeyList[3].map {
        PrimaryKeyButton(keyboard: .numeric, button: .keyButton(primary: $0, secondary: nil))
    }
    
    public private(set) var deleteButton = DeleteButton(keyboard: .numeric)
    public private(set) var spaceButton = SpaceButton(keyboard: .numeric)
    public private(set) var returnButton = ReturnButton(keyboard: .numeric)
    public private(set) lazy var switchButton = SwitchButton(
        keyboard: .numeric,
        usesBottomSpaceLayout: usesBottomSpaceLayout
    )
    public private(set) lazy var languageSwitchButton: LanguageSwitchButton? = {
        guard showsLanguageSwitchButton else { return nil }
        return LanguageSwitchButton(mode: .hangeul, keyboard: .numeric)
    }()
    public private(set) var nextKeyboardButton = NextKeyboardButton(keyboard: .numeric)

    private(set) lazy var keyboardSelectOverlayView: KeyboardSelectOverlayView = {
        let overlayView = KeyboardSelectOverlayView(
            keyboard: .numeric,
            usesBottomSpaceLayout: usesBottomSpaceLayout
        )
        overlayView.isHidden = true

        return overlayView
    }()
    private(set) var oneHandedModeSelectOverlayView: OneHandedModeSelectOverlayView = {
        let overlayView = OneHandedModeSelectOverlayView()
        overlayView.isHidden = true
        
        return overlayView
    }()
    
    // MARK: - Initializer
    
    init(showsLanguageSwitchButton: Bool = false,
         usesBottomSpaceLayout: Bool = UserDefaultsManager.shared.isNumericKeypadBottomSpaceEnabled) {
        self.showsLanguageSwitchButton = showsLanguageSwitchButton
        self.usesBottomSpaceLayout = usesBottomSpaceLayout
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logger.debug("\(String(describing: type(of: self))) deinit")
    }
}

// MARK: - Update Methods

extension NumericKeyboardView {
    /// 지구본 표시 여부가 바뀌면 modifier 영역의 폭 분배를 다시 정합니다.
    public func nextKeyboardButtonVisibilityDidChange(needsInputModeSwitchKey: Bool) {
        guard languageSwitchButton != nil else { return }
        updateModifierDistribution(isNextKeyboardButtonVisible: needsInputModeSwitchKey)
        setNeedsLayout()
    }

    /// 4x4 계열은 4행 스택이 전체 폭을 4등분해 modifier 영역 폭이 고정이다.
    /// 지구본이 표시되면 세 버튼이 그 폭을 균등하게 나눠 갖고,
    /// 숨겨지면 한영 전환 버튼이 고정 폭을 쓰고 나머지는 전환 버튼이 채운다
    func updateModifierDistribution(isNextKeyboardButtonVisible: Bool) {
        fourthRowRightSecondaryButtonHStackView.distribution =
        isNextKeyboardButtonVisible ? .fillEqually : .fill
    }

    /// 글자 열 너비 배율을 다시 적용합니다.
    public func updateLetterColumnWidthMultiplier(_ multiplier: Double) {
        columnWidthLayoutController.update(multiplier: multiplier)
        setNeedsLayout()
    }
}

// MARK: - UI Methods

private extension NumericKeyboardView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .clear
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
        firstRowHStackView.addArrangedSubview(deleteButton)

        secondRowPrimaryKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        thirdRowPrimaryKeyButtonList.forEach { thirdRowHStackView.addArrangedSubview($0) }

        let modifierButtons: [SecondaryButton]
        if usesBottomSpaceLayout {
            // 스페이스가 4행으로 내려가면서 리턴이 2행, 우측 글자 스택이 3행 우측 칸으로
            // 올라가고 좌측 글자 스택이 4행 끝으로 간다.
            // 모든 행은 그대로 4칸 균등 분할이다.
            // 숫자 입력에서 가장 잦은 '.'과 ','를 엄지에 가까운 4행 끝에 모으고
            // '-'와 '/'를 3행 우측으로 올린다
            [fourthRowPrimaryKeyButtonList[3], fourthRowPrimaryKeyButtonList[1]].forEach { fourthRowLeftPrimaryButtonHStackView.addArrangedSubview($0) }
            [fourthRowPrimaryKeyButtonList[0], fourthRowPrimaryKeyButtonList[4]].forEach { fourthRowRightPrimaryButtonHStackView.addArrangedSubview($0) }

            secondRowHStackView.addArrangedSubview(returnButton)
            thirdRowHStackView.addArrangedSubview(fourthRowRightPrimaryButtonHStackView)

            [fourthRowRightSecondaryButtonHStackView,
             fourthRowPrimaryKeyButtonList[2],
             spaceButton,
             fourthRowLeftPrimaryButtonHStackView].forEach { fourthRowHStackView.addArrangedSubview($0) }

            modifierButtons = [switchButton]
            + [languageSwitchButton].compactMap { $0 }
            + [nextKeyboardButton]
        } else {
            [fourthRowPrimaryKeyButtonList[0], fourthRowPrimaryKeyButtonList[1]].forEach { fourthRowLeftPrimaryButtonHStackView.addArrangedSubview($0) }
            [fourthRowPrimaryKeyButtonList[3], fourthRowPrimaryKeyButtonList[4]].forEach { fourthRowRightPrimaryButtonHStackView.addArrangedSubview($0) }

            secondRowHStackView.addArrangedSubview(spaceButton)
            thirdRowHStackView.addArrangedSubview(returnButton)

            [fourthRowLeftPrimaryButtonHStackView,
             fourthRowPrimaryKeyButtonList[2],
             fourthRowRightPrimaryButtonHStackView,
             fourthRowRightSecondaryButtonHStackView].forEach { fourthRowHStackView.addArrangedSubview($0) }

            modifierButtons = [nextKeyboardButton]
            + [languageSwitchButton].compactMap { $0 }
            + [switchButton]
        }
        modifierButtons.forEach(fourthRowRightSecondaryButtonHStackView.addArrangedSubview)
    }
    
    func setConstraints() {
        layoutVStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layoutVStackView.topAnchor.constraint(equalTo: self.topAnchor),
            layoutVStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            layoutVStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            layoutVStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        // 4열 폭 비율은 컨트롤러가 관리한다.
        // 한영 전환 버튼 폭도 기능 열에 연동되므로 함께 넘긴다
        columnWidthLayoutController.install(
            rows: [firstRowHStackView,
                   secondRowHStackView,
                   thirdRowHStackView,
                   fourthRowHStackView],
            languageSwitchButton: languageSwitchButton,
            referenceView: self,
            multiplier: UserDefaultsManager.shared.letterColumnWidthMultiplier
        )

        if languageSwitchButton != nil {
            updateModifierDistribution(isNextKeyboardButtonVisible: !nextKeyboardButton.isHidden)
        }

        keyboardSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false
        oneHandedModeSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            keyboardSelectOverlayView.bottomAnchor.constraint(equalTo: switchButton.topAnchor, constant: -4),
            keyboardSelectOverlayView.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.selectOverlayHeight),
            oneHandedModeSelectOverlayView.bottomAnchor.constraint(equalTo: switchButton.topAnchor, constant: -4),
            oneHandedModeSelectOverlayView.widthAnchor.constraint(equalToConstant: KeyboardLayoutFigure.oneHandedModeSelectOverlayWidth),
            oneHandedModeSelectOverlayView.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.selectOverlayHeight)
        ])

        // 취소 영역의 경계선을 `switchButton`의 바깥 모서리보다 안쪽에 둔다.
        // 오버레이가 열리는 순간 손가락이 이미 목표 쪽에 있게 된다
        let cancelBoundary: NSLayoutConstraint
        if usesBottomSpaceLayout {
            // `switchButton`이 4행 좌측 끝이므로 오버레이는 오른쪽으로 펼쳐진다
            NSLayoutConstraint.activate([
                keyboardSelectOverlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
                oneHandedModeSelectOverlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4)
            ])
            cancelBoundary = keyboardSelectOverlayView.xmarkImageContainerView.trailingAnchor.constraint(
                equalTo: switchButton.trailingAnchor,
                constant: -KeyboardLayoutFigure.keyboardSelectBoundaryInset
            )
        } else {
            NSLayoutConstraint.activate([
                keyboardSelectOverlayView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
                oneHandedModeSelectOverlayView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4)
            ])
            cancelBoundary = keyboardSelectOverlayView.xmarkImageContainerView.leadingAnchor.constraint(
                equalTo: switchButton.leadingAnchor,
                constant: KeyboardLayoutFigure.keyboardSelectBoundaryInset
            )
        }
        cancelBoundary.priority = .init(999)
        NSLayoutConstraint.activate([
            cancelBoundary,
            keyboardSelectOverlayView.xmarkImageContainerView.widthAnchor.constraint(
                greaterThanOrEqualToConstant: KeyboardLayoutFigure.keyboardSelectCancelMinWidth
            )
        ])
    }
}

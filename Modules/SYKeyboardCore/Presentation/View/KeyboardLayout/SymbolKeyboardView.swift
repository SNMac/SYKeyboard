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
    
    private let keyList: [[[[String]]]] = [
        [
            [ ["1"], ["2"], ["3"], ["4"], ["5"], ["6"], ["7"], ["8"], ["9"], ["0"] ],
            [ ["-"], ["/"], [":"], [";"], ["("], [")"], ["₩"], ["&"], ["@"], ["“"] ],
            [ ["."], [","], ["?"], ["!"], ["’"] ]
        ],
        [
            [ ["["], ["]"], ["{"], ["}"], ["#"], ["%"], ["^"], ["*"], ["+"], ["="] ],
            [ ["_"], ["\\"], ["|"], ["~"], ["<"], [">"], ["$"], ["£"], ["¥"], ["•"] ],
            [ ["."], [","], ["?"], ["!"], ["’"] ]
        ]
    ]
    
    public private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    public private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList + [spaceButton]
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [shiftButton, deleteButton, switchButton, returnButton, nextKeyboardButton]
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = firstRowPrimaryKeyButtonList + secondRowPrimaryKeyButtonList + thirdRowPrimaryKeyButtonList
    + [deleteButton, spaceButton, returnButton]
    
    var isShifted: Bool = false {
        didSet {
            shiftButton.updateShiftState(to: isShifted)
            updateKeyButtonList()
        }
    }
    var wasShifted: Bool = false
    
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
    
    /// 키보드 첫번째 행 `PrimaryKeyButton` 배열
    private lazy var firstRowPrimaryKeyButtonList = keyList[0][0].map {
        PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
    }
    /// 키보드 두번째 행 `PrimaryKeyButton` 배열
    private lazy var secondRowPrimaryKeyButtonList = keyList[0][1].map {
        PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
    }
    /// 키보드 세번째 행 `PrimaryKeyButton` 배열
    private lazy var thirdRowPrimaryKeyButtonList = keyList[0][2].map {
        PrimaryKeyButton(keyboard: .symbol, button: .keyButton(primary: $0, secondary: nil))
    }
    
    public private(set) var shiftButton = ShiftButton(keyboard: .symbol)
    public private(set) var deleteButton = DeleteButton(keyboard: .symbol)
    public private(set) var switchButton = SwitchButton(keyboard: .symbol)
    
    public private(set) var spaceButton = SpaceButton(keyboard: .symbol)
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
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
        
        [fourthRowLeftSecondaryButtonHStackView, spaceButton, returnButton].forEach { fourthRowHStackView.addArrangedSubview($0) }
        [switchButton, nextKeyboardButton].forEach { fourthRowLeftSecondaryButtonHStackView.addArrangedSubview($0) }
    }
    
    func setConstraints() {
        layoutVStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layoutVStackView.topAnchor.constraint(equalTo: self.topAnchor),
            layoutVStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            layoutVStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            layoutVStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        for (index, button) in thirdRowPrimaryKeyButtonList.enumerated() {
            button.translatesAutoresizingMaskIntoConstraints = false
            
            let multiplier = 1.0 / CGFloat(firstRowPrimaryKeyButtonList.count) * KeyboardLayoutFigure.symbolThirdRowButtonWidthMultiplier
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
        if let superview = fourthRowLeftSecondaryButtonHStackView.superview {
            fourthRowLeftSecondaryButtonHStackView.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                                          multiplier: 0.25).isActive = true
        }
        
        returnButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = returnButton.superview {
            returnButton.widthAnchor.constraint(equalTo: superview.widthAnchor,
                                                multiplier: 0.25).isActive = true
        }
        
        keyboardSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboardSelectOverlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            keyboardSelectOverlayView.centerYAnchor.constraint(equalTo: shiftButton.centerYAnchor),
            keyboardSelectOverlayView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: KeyboardLayoutFigure.keyboardSelectOverlayWidthMultiplier),
            keyboardSelectOverlayView.heightAnchor.constraint(equalTo: shiftButton.heightAnchor)
        ])
        
        oneHandedModeSelectOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            oneHandedModeSelectOverlayView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            oneHandedModeSelectOverlayView.centerYAnchor.constraint(equalTo: shiftButton.centerYAnchor),
            oneHandedModeSelectOverlayView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: KeyboardLayoutFigure.oneHandedModeSelectOverlayWidthMultiplier),
            oneHandedModeSelectOverlayView.heightAnchor.constraint(equalTo: shiftButton.heightAnchor)
        ])
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
                let primaryKeyList = keyList[symbolKeyListIndex][rowIndex][buttonIndex]
                button.update(buttonType: TextInteractableType.keyButton(primary: primaryKeyList, secondary: nil))
            }
        }
    }
}

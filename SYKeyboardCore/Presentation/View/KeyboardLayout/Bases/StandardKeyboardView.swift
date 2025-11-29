//
//  StandardKeyboardView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/12/25.
//

import UIKit

open class StandardKeyboardView: UIView {
    
    // MARK: - Properties
    
    /// 키보드 종류
    open var keyboard: SYKeyboardType { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    /// 키 배열
    open var keyList: [[[[String]]]] { fatalError("프로퍼티가 오버라이딩 되지 않았습니다.") }
    
    public private(set) lazy var allButtonList: [BaseKeyboardButton] = primaryButtonList + secondaryButtonList
    public private(set) lazy var primaryButtonList: [PrimaryButton] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList + [spaceButton, atButton, periodButton, slashButton, dotComButton]
    public private(set) lazy var secondaryButtonList: [SecondaryButton] = [shiftButton, deleteButton, switchButton, returnButton, secondaryAtButton, secondarySharpButton, nextKeyboardButton]
    public private(set) lazy var totalTextInterableButtonList: [TextInteractable] = firstRowKeyButtonList + secondRowKeyButtonList + thirdRowKeyButtonList
    + [deleteButton, spaceButton, atButton, periodButton, slashButton, dotComButton, returnButton, secondaryAtButton, secondarySharpButton]
    
    final public var isShifted: Bool = false {
        didSet {
            shiftButton.updateShiftState(to: isShifted)
            updateKeyButtonList()
        }
    }
    final public var wasShifted: Bool = false
    
    // MARK: - UI Components
    
    /// 키보드 레이아웃 수직 스택
    private let keyboardVStackView = KeyboardLayoutVStackView()
    
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
    private let thirdRowInsideHStackView = KeyboardRowHStackView()
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
    
    /// 키보드 첫번째 행 `PrimaryButton` 배열
    private lazy var firstRowKeyButtonList = keyList[0][0].map { PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: $0)) }
    /// 키보드 두번째 행 `PrimaryButton` 배열
    private lazy var secondRowKeyButtonList = keyList[0][1].map { PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: $0)) }
    /// 키보드 세번째 행 `PrimaryButton` 배열
    private lazy var thirdRowKeyButtonList = keyList[0][2].map { PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: $0)) }
    
    public lazy var shiftButton = ShiftButton(keyboard: keyboard)
    public private(set) lazy var deleteButton = DeleteButton(keyboard: keyboard)
    public private(set) lazy var switchButton = SwitchButton(keyboard: keyboard)
    
    // 스페이스 버튼 위치
    public private(set) lazy var spaceButton = SpaceButton(keyboard: keyboard)
    public private(set) lazy var atButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["@"]))
    public private(set) lazy var periodButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["."]))
    public private(set) lazy var slashButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["/"]))
    public private(set) lazy var dotComButton = PrimaryKeyButton(keyboard: keyboard, button: .keyButton(keys: [".com"]))
    
    // 리턴 버튼 위치
    public private(set) lazy var returnButton = ReturnButton(keyboard: keyboard)
    public private(set) lazy var secondaryAtButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["@"]))
    public private(set) lazy var secondarySharpButton = SecondaryKeyButton(keyboard: keyboard, button: .keyButton(keys: ["#"]))
    
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
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            if wasShifted {
                isShifted = false
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
        [keyboardVStackView,
         keyboardSelectOverlayView,
         oneHandedModeSelectOverlayView].forEach { self.addSubview($0) }
        
        [firstRowHStackView,
         secondRowHStackView,
         thirdRowHStackView,
         fourthRowHStackView].forEach { keyboardVStackView.addArrangedSubview($0) }
        
        firstRowKeyButtonList.forEach { firstRowHStackView.addArrangedSubview($0) }
        
        secondRowKeyButtonList.forEach { secondRowHStackView.addArrangedSubview($0) }
        
        [shiftButton, thirdRowInsideHStackView, deleteButton].forEach { thirdRowHStackView.addArrangedSubview($0) }
        thirdRowKeyButtonList.forEach { thirdRowInsideHStackView.addArrangedSubview($0) }
        
        [fourthRowLeftSecondaryButtonHStackView, spaceButtonHStackView, returnButtonHStackView].forEach { fourthRowHStackView.addArrangedSubview($0) }
        [switchButton, nextKeyboardButton].forEach { fourthRowLeftSecondaryButtonHStackView.addArrangedSubview($0) }
        [spaceButton, atButton, periodButton, slashButton, dotComButton].forEach { spaceButtonHStackView.addArrangedSubview($0) }
        [returnButton, secondaryAtButton, secondarySharpButton].forEach { returnButtonHStackView.addArrangedSubview($0) }
    }
    
    func setConstraints() {
        keyboardVStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboardVStackView.topAnchor.constraint(equalTo: self.topAnchor),
            keyboardVStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            keyboardVStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            keyboardVStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        guard let referenceKey = firstRowKeyButtonList.first else { fatalError("firstRowKeyButtonList가 비어있습니다.") }
        for (index, button) in secondRowKeyButtonList.enumerated() {
            button.translatesAutoresizingMaskIntoConstraints = false
            guard let superview = button.superview else { continue }
            
            if index == 0 {
                guard let lastButton = secondRowKeyButtonList.last else { fatalError("secondRowKeyButtonList가 비어있습니다.") }
                button.widthAnchor.constraint(equalTo: lastButton.widthAnchor).isActive = true
                button.updateKeyAlignment(.right, referenceKey: referenceKey)
                
            } else if index == secondRowKeyButtonList.count - 1 {
                button.updateKeyAlignment(.left, referenceKey: referenceKey)
                
            } else {
                let multiplier = 1.0 / CGFloat(firstRowKeyButtonList.count)
                button.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: multiplier).isActive = true
            }
        }
        
        shiftButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = shiftButton.superview {
            let multiplier = 1.0 / KeyboardLayoutFigure.shiftAndDeleteButtonDivider
            shiftButton.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: multiplier).isActive = true
        }
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.widthAnchor.constraint(equalTo: shiftButton.widthAnchor).isActive = true
        
        fourthRowLeftSecondaryButtonHStackView.translatesAutoresizingMaskIntoConstraints = false
        if let superview = fourthRowLeftSecondaryButtonHStackView.superview {
            fourthRowLeftSecondaryButtonHStackView.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: 0.25).isActive = true
        }
        
        spaceButtonHStackView.translatesAutoresizingMaskIntoConstraints = false
        if let superview = spaceButtonHStackView.superview {
            spaceButtonHStackView.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: 0.5).isActive = true
        }
        
        atButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = atButton.superview {
            atButton.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: 0.25).isActive = true
        }
        
        periodButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = periodButton.superview {
            periodButton.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: 0.2).isActive = true
        }
        
        slashButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = slashButton.superview {
            slashButton.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: 1.0/3.0).isActive = true
        }
        
        dotComButton.translatesAutoresizingMaskIntoConstraints = false
        if let superview = dotComButton.superview {
            dotComButton.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: 1.0/3.0).isActive = true
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

// MARK: - Update Methods

extension StandardKeyboardView {
    final public func updateKeyButtonList() {
        let keyListIndex = (isShifted ? 1 : 0)
        let rowList = [firstRowKeyButtonList, secondRowKeyButtonList, thirdRowKeyButtonList]
        for (rowIndex, buttonList) in rowList.enumerated() {
            for (buttonIndex, button) in buttonList.enumerated() {
                let keys = keyList[keyListIndex][rowIndex][buttonIndex]
                button.update(buttonType: TextInteractableType.keyButton(keys: keys))
            }
        }
    }
}

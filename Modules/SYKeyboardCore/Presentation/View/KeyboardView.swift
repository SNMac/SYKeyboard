//
//  KeyboardView.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 11/25/25.
//

import UIKit
import OSLog

import SYKeyboardAssets

final public class KeyboardView: UIInputView {
    
    // MARK: - Properties
    
    private lazy var logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "\(String(describing: type(of: self))) <\(Unmanaged.passUnretained(self).toOpaque())>"
    )
    
    private var keyboardLayoutWidthConstraint: NSLayoutConstraint?

    /// 사용자가 설정한 한 손 키보드 너비
    private var configuredOneHandedWidth = CGFloat(UserDefaultsManager.shared.oneHandedKeyboardWidth)
    
    // MARK: - UI Components
    
    /// 키보드 전체 수직 스택
    private let keyboardFrameVStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        
        return stackView
    }()
    
    /// 자동완성 툴바
    lazy var suggestionBarView: SuggestionBarView = {
        let suggestionBar = SuggestionBarView(keyboardHStackView: keyboardHStackView)
        suggestionBar.isHidden = !UserDefaultsManager.shared.isPredictiveTextEnabled
        
        return suggestionBar
    }()
    
    /// 키보드 수평 스택
    let keyboardHStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.layoutMargins = UIEdgeInsets(top: KeyboardLayoutFigure.keyboardFrameSpacing, left: 0, bottom: 0, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        return stackView
    }()
    
    /// 키보드 레이아웃 뷰
    private let keyboardLayoutView = UIView()
    
    /// 한 손 키보드 해제 버튼(오른손 모드)
    let leftChevronButton: ChevronButton = {
        let chevronButton = ChevronButton(direction: .left)
        chevronButton.isHidden = true
        
        return chevronButton
    }()
    
    /// 주 키보드 목록
    private(set) var primaryKeyboardViews: [PrimaryKeyboardRepresentable] = []
    
    /// 주 키보드에 한영 전환 버튼이 있는지 여부
    private var showsLanguageSwitchButton: Bool {
        primaryKeyboardViews.contains { $0.languageSwitchButton != nil }
    }
    
    /// 기호 키보드
    lazy var symbolKeyboardView: SymbolKeyboardLayoutProvider = {
        let symbolKeyboardView = SymbolKeyboardView(
            showsLanguageSwitchButton: showsLanguageSwitchButton
        )
        symbolKeyboardView.isHidden = true
        
        return symbolKeyboardView
    }()
    
    /// 숫자 키보드
    lazy var numericKeyboardView: NumericKeyboardLayoutProvider = {
        let numericKeyboardView = NumericKeyboardView(
            showsLanguageSwitchButton: showsLanguageSwitchButton
        )
        numericKeyboardView.isHidden = true
        
        return numericKeyboardView
    }()
    
    /// 텐키 키보드
    lazy var tenkeyKeyboardView: TenkeyKeyboardLayoutProvider = {
        let tenkeyKeyboardView = TenkeyKeyboardView()
        tenkeyKeyboardView.isHidden = true
        
        return tenkeyKeyboardView
    }()
    
    /// 한 손 키보드 해제 버튼(왼손 모드)
    let rightChevronButton: ChevronButton = {
        let chevronButton = ChevronButton(direction: .right)
        chevronButton.isHidden = true
        
        return chevronButton
    }()
    
    // MARK: - Initializer
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        logger.debug("\(String(describing: type(of: self))) deinit")
    }
    
    // MARK: - Lifecycle
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateKeyboardLayoutWidthConstraint()
    }
    
    // MARK: - Internal Methods
    
    static func loadFromNib(primaryKeyboardViews: [PrimaryKeyboardRepresentable]) -> KeyboardView {
        let nibName = "KeyboardView"
        
        let bundle = SYKBDAssets.bundle
        let nib = UINib(nibName: nibName, bundle: bundle)
        
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? KeyboardView else {
            fatalError("bundle로부터 \(nibName)를 불러오는 데에 실패했습니다.")
        }
        
        view.primaryKeyboardViews = primaryKeyboardViews
        view.setupUI()
        
        return view
    }
    
    /// 한 손 키보드 너비 업데이트를 업데이트하는 메서드
    func updateOneHandedWidth(_ width: Double) {
        configuredOneHandedWidth = CGFloat(width)
        updateKeyboardLayoutWidthConstraint()
        self.layoutIfNeeded()
    }

    /// 현재 한 손 키보드 모드에 맞게 Chevron 표시를 업데이트하는 메서드
    func updateOneHandedMode(_ mode: OneHandedMode) {
        leftChevronButton.isHidden = mode != .right
        rightChevronButton.isHidden = mode != .left
    }
}

// MARK: - UI Methods

private extension KeyboardView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.backgroundColor = .systemBackground.withAlphaComponent(0.001)  // 터치 영역 확보용
    }
    
    func setHierarchy() {
        self.addSubview(keyboardFrameVStackView)
        
        [suggestionBarView, keyboardHStackView].forEach {
            keyboardFrameVStackView.addArrangedSubview($0)
        }
        
        [leftChevronButton, keyboardLayoutView, rightChevronButton].forEach { keyboardHStackView.addArrangedSubview($0) }
        
        (primaryKeyboardViews.map { $0 as UIView }
         + [symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView])
            .forEach { keyboardLayoutView.addSubview($0) }
    }
    
    func setConstraints() {
        keyboardFrameVStackView.translatesAutoresizingMaskIntoConstraints = false
        if BaseKeyboardViewController.isPreview {
            keyboardFrameVStackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            keyboardFrameVStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            keyboardFrameVStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            keyboardFrameVStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        suggestionBarView.translatesAutoresizingMaskIntoConstraints = false
        let suggestionBarHeightConstraint = suggestionBarView.heightAnchor.constraint(
            equalToConstant: KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing
        )
        suggestionBarHeightConstraint.priority = .init(999)
        suggestionBarHeightConstraint.isActive = true
        
        keyboardLayoutView.translatesAutoresizingMaskIntoConstraints = false
        // required가 아니면 `keyboardHStackView`의 내부 제약에 밀려 조용히 무시된다.
        // 회전 도중의 제약 충돌은 `updateKeyboardLayoutWidthConstraint()`가 상수를 가용 폭으로 낮춰 막는다
        let widthConstraint = keyboardLayoutView.widthAnchor.constraint(
            greaterThanOrEqualToConstant: configuredOneHandedWidth
        )
        widthConstraint.isActive = true
        keyboardLayoutWidthConstraint = widthConstraint
        
        (primaryKeyboardViews.map { $0 as UIView }
         + [symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView]).forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: keyboardLayoutView.topAnchor),
                $0.leadingAnchor.constraint(equalTo: keyboardLayoutView.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: keyboardLayoutView.trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: keyboardLayoutView.bottomAnchor)
            ])
        }
    }

    /// 한 손 키보드 최소 폭 제약의 상수를 현재 가용 폭 안으로 제한하는 메서드
    func updateKeyboardLayoutWidthConstraint() {
        guard let keyboardLayoutWidthConstraint else { return }

        // `keyboardHStackView`는 항상 `KeyboardView` 전체 폭을 차지하지만
        // 하위 레이아웃 순서상 이 시점에 bounds가 비어 있을 수 있어 자기 폭을 사용한다
        let minWidth = KeyboardPresentationStatePolicy.oneHandedKeyboardMinimumWidth(
            configuredWidth: configuredOneHandedWidth,
            availableWidth: self.bounds.width
        )
        guard keyboardLayoutWidthConstraint.constant != minWidth else { return }
        keyboardLayoutWidthConstraint.constant = minWidth
    }
}

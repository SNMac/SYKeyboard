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
    
    // MARK: - UI Components
    
    /// 키보드 전체 수직 스택
    private let keyboardFrameVStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        
        return stackView
    }()
    
    /// 자동완성 툴바
    let suggestionBarView: SuggestionBarView = {
        let suggestionBar = SuggestionBarView()
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
    
    /// 주 키보드
    private var primaryKeyboardView: PrimaryKeyboardRepresentable!
    
    /// 기호 키보드
    lazy var symbolKeyboardView: SymbolKeyboardLayoutProvider = {
        let symbolKeyboardView = SymbolKeyboardView()
        symbolKeyboardView.isHidden = true
        
        return symbolKeyboardView
    }()
    
    /// 숫자 키보드
    lazy var numericKeyboardView: NumericKeyboardLayoutProvider = {
        let numericKeyboardView = NumericKeyboardView()
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
    
    // MARK: - Internal Methods
    
    static func loadFromNib(primaryKeyboardView: PrimaryKeyboardRepresentable) -> KeyboardView {
        let nibName = "KeyboardView"
        
        let bundle = SYKBDAssets.bundle
        let nib = UINib(nibName: nibName, bundle: bundle)
        
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? KeyboardView else {
            fatalError("bundle로부터 \(nibName)를 불러오는 데에 실패했습니다.")
        }
        
        view.primaryKeyboardView = primaryKeyboardView
        view.setupUI()
        
        return view
    }
    
    /// 한 손 키보드 너비 업데이트를 업데이트하는 메서드
    func updateOneHandedWidth(_ width: Double) {
        keyboardLayoutWidthConstraint?.constant = width
        self.layoutIfNeeded()
    }
}

// MARK: - UI Methods

private extension KeyboardView {
    func setupUI() {
        setHierarchy()
        setConstraints()
    }
    
    func setHierarchy() {
        self.addSubview(keyboardFrameVStackView)
        
        [suggestionBarView, keyboardHStackView].forEach {
            keyboardFrameVStackView.addArrangedSubview($0)
        }
        
        [leftChevronButton, keyboardLayoutView, rightChevronButton].forEach { keyboardHStackView.addArrangedSubview($0) }
        
        [primaryKeyboardView, symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView].forEach { keyboardLayoutView.addSubview($0) }
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
        NSLayoutConstraint.activate([
            suggestionBarView.heightAnchor.constraint(equalToConstant: KeyboardLayoutFigure.suggestionBarHeightWithTopSpacing)
        ])
        
        keyboardLayoutView.translatesAutoresizingMaskIntoConstraints = false
        let minWidth = UserDefaultsManager.shared.oneHandedKeyboardWidth
        keyboardLayoutWidthConstraint = keyboardLayoutView.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth)
        keyboardLayoutWidthConstraint?.isActive = true
        
        [primaryKeyboardView, symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: keyboardLayoutView.topAnchor),
                $0.leadingAnchor.constraint(equalTo: keyboardLayoutView.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: keyboardLayoutView.trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: keyboardLayoutView.bottomAnchor)
            ])
        }
    }
}

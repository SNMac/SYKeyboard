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
    let keyboardFrameHStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.backgroundColor = .clear
        
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
        self.addSubview(keyboardFrameHStackView)
        
        [leftChevronButton, keyboardLayoutView, rightChevronButton].forEach { keyboardFrameHStackView.addArrangedSubview($0) }
        
        [primaryKeyboardView, symbolKeyboardView, numericKeyboardView, tenkeyKeyboardView].forEach { keyboardLayoutView.addSubview($0) }
    }
    
    func setConstraints() {
        keyboardFrameHStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboardFrameHStackView.topAnchor.constraint(equalTo: self.topAnchor),
            keyboardFrameHStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            keyboardFrameHStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            keyboardFrameHStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
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

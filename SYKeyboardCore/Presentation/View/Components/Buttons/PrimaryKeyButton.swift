//
//  PrimaryKeyButton.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

/// 주 키 버튼
final public class PrimaryKeyButton: PrimaryButton, TextInteractable {
    
    // MARK: - Properties
    
    /// 버튼 정렬 관리용
    enum KeyAlignment {
        case center  // 일반 키
        case left  // 영어 키보드의 'l' 키처럼 왼쪽에 붙는 키
        case right  // 영어 키보드의 'a' 키처럼 오른쪽에 붙는 키
    }
    
    private var keyAlignment: KeyAlignment = .center
    private var referenceKey: PrimaryKeyButton?  // 너비의 기준이 될 키
    
    public private(set) var type: TextInteractableType {
        didSet {
            if type.primaryKeyList.isEmpty {
                self.isHidden = true
            } else {
                updatePrimaryKeyListLabel()
                self.isHidden = false
            }
            
            updateSecondaryKeyListLabel()
        }
    }
    
    // MARK: - UI Components
    
    private let secondaryKeyLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 9, weight: .regular)
        label.textColor = .secondaryLabel
        label.isHidden = !UserDefaultsManager.shared.isLongPressToNumberInputEnabled
        
        return label
    }()
    
    // MARK: - Initializer
    
    public init(keyboard: SYKeyboardType, button: TextInteractableType) {
        self.type = button
        super.init(keyboard: keyboard)
        
        setupUI()
        updatePrimaryKeyListLabel()
        updateSecondaryKeyListLabel()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updatePrimaryKeyListLabelInsets()
    }
    
    // MARK: - Override Methods
    
    public override func playFeedback() {
        FeedbackManager.shared.playHaptic()
        FeedbackManager.shared.playKeyTypingSound()
    }
    
    // MARK: - Internal Methods
    
    func update(buttonType: TextInteractableType) {
        self.type = buttonType
    }
    
    /// 키의 시각적 정렬을 업데이트합니다.
    /// - Parameters:
    ///   - alignment: 정렬 방향 (`.left`, `.right`, `.center`)
    ///   - referenceKey: 시각적 너비의 기준이 될 뷰 (예: `'s'` 키)
    func updateKeyAlignment(_ alignment: KeyAlignment, referenceKey: PrimaryKeyButton) {
        self.keyAlignment = alignment
        self.referenceKey = referenceKey
        
        remakeConstraintsForVisuals()
    }
}

// MARK: - SecondaryKey UI Methods

private extension PrimaryKeyButton {
    func setupUI() {
        setHierarchy()
        setConstraints()
    }
    
    func setHierarchy() {
        self.addSubview(secondaryKeyLabel)
    }
    
    func setConstraints() {
        let offsetX = insetDx + 2
        let offsetY = insetDy + 2
        
        secondaryKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryKeyLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: offsetY),
            secondaryKeyLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offsetX)
        ])
    }
}

// MARK: - Update Methods

private extension PrimaryKeyButton {
    func updatePrimaryKeyListLabel() {
        if type.primaryKeyList.count == 1 {
            guard let primaryKey = type.primaryKeyList.first else { return }
            primaryKeyListLabel.text = primaryKey
            
            if primaryKey.count == 1 {
                if Character(primaryKey).isLowercase {
                    primaryKeyListLabel.font = .systemFont(ofSize: FontSize.lowercaseKeySize)
                } else {
                    primaryKeyListLabel.font = .systemFont(ofSize: FontSize.defaultKeySize)
                }
            } else {
                primaryKeyListLabel.font = .systemFont(ofSize: FontSize.stringKeySize)
            }
        } else {
            primaryKeyListLabel.text = type.primaryKeyList.joined(separator: "")
            primaryKeyListLabel.font = .systemFont(ofSize: FontSize.defaultKeySize)
        }
    }
    
    func updateSecondaryKeyListLabel() {
        guard let secondaryKey = type.secondaryKey else { return }
        secondaryKeyLabel.text = secondaryKey
    }
    
    func remakeConstraintsForVisuals() {
        guard let referenceKey else { return }
        
        NSLayoutConstraint.deactivate(visualConstraints)
        visualConstraints.removeAll()
        
        let top = shadowView.topAnchor.constraint(equalTo: self.topAnchor, constant: insetDy)
        let bottom = shadowView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insetDy)
        visualConstraints.append(contentsOf: [top, bottom])
        
        let width = shadowView.widthAnchor.constraint(equalTo: referenceKey.widthAnchor, constant: -insetDx)
        visualConstraints.append(width)
        
        switch keyAlignment {
        case .left:
            let leading = shadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: insetDx)
            visualConstraints.append(leading)
            
        case .right:
            let trailing = shadowView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -insetDx)
            visualConstraints.append(trailing)
            
        case .center:
            let leading = shadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: insetDx)
            let trailing = shadowView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -insetDx)
            visualConstraints.append(contentsOf: [leading, trailing])
        }
        
        NSLayoutConstraint.activate(visualConstraints)
    }
    
    func updatePrimaryKeyListLabelInsets() {
        // referenceKey가 존재하는 경우에만 수행
        guard let referenceKey else {
            self.configuration?.contentInsets = .zero
            return
        }
        
        // superview의 레이아웃이 완료된 후 크기를 계산하기 위해 메인 스레드에서 비동기 처리
        DispatchQueue.main.async {
            let totalWidth = self.frame.width
            let visualWidth = referenceKey.frame.width
            
            guard totalWidth > 0, visualWidth > 0 else { return }
            
            // 전체 프레임 너비에서 시각적 뷰 너비를 뺀 나머지 공간
            let extraSpace = totalWidth - visualWidth
            
            var insets = NSDirectionalEdgeInsets.zero
            switch self.keyAlignment {
            case .left:
                insets.trailing = extraSpace
            case .right:
                insets.leading = extraSpace
            case .center:
                break
            }
            
            self.configuration?.contentInsets = insets
        }
    }
}

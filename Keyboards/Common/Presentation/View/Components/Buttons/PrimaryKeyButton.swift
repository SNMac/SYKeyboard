//
//  PrimaryKeyButton.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/13/25.
//

import UIKit

import SnapKit

/// 주 키 버튼
final class PrimaryKeyButton: PrimaryButton, TextInteractionButtonProtocol {
    
    // MARK: - Properties
    
    /// 버튼 정렬 관리용
    enum KeyAlignment {
        case center  // 일반 키
        case left  // 영어 키보드의 'l' 키처럼 왼쪽에 붙는 키
        case right  // 영어 키보드의 'a' 키처럼 오른쪽에 붙는 키
    }
    
    private var keyAlignment: KeyAlignment = .center
    private var referenceKey: PrimaryButton?  // 너비의 기준이 될 키
    
    private(set) var button: TextInteractionButton {
        didSet {
            if button.keys.isEmpty {
                self.isHidden = true
            } else {
                updateTitle()
                self.isHidden = false
            }
        }
    }
    
    // MARK: - Initializer
    
    init(keyboard: Keyboard, button: TextInteractionButton) {
        self.button = button
        super.init(keyboard: keyboard)
        
        setupUI()
        updateTitle()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateTitleInsets()
    }
    
    // MARK: - Internal Methods
    
    func update(button: TextInteractionButton) {
        self.button = button
    }
    
    /// 키의 시각적 정렬을 업데이트합니다.
     /// - Parameters:
     ///   - alignment: 정렬 방향 (`.left`, `.right`, `.center`)
     ///   - referenceKey: 시각적 너비의 기준이 될 뷰 (예: `'s'` 키)
     func updateKeyAlignment(_ alignment: KeyAlignment, referenceKey: PrimaryButton) {
         self.keyAlignment = alignment
         self.referenceKey = referenceKey
         
         updateConstraintsForVisuals()
     }
}

// MARK: - UI Methods

private extension PrimaryKeyButton {
    func setupUI() {
        setActions()
    }
    
    func setActions() {
        let playFeedback = UIAction { _ in
            FeedbackManager.shared.playHaptic()
            FeedbackManager.shared.playKeyTypingSound()
        }
        self.addAction(playFeedback, for: .touchDown)
    }
}

// MARK: - Update Methods

private extension PrimaryKeyButton {
    func updateConstraintsForVisuals() {
        guard let referenceKey = referenceKey else { return }
        
        // 1. Shadow View 제약 조건 재설정
        shadowView.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview().inset(self.insetDy)
            $0.width.equalTo(referenceKey).inset(self.insetDx) // 기준 키의 너비와 동일하게
            
            switch keyAlignment {
            case .left:
                $0.leading.equalToSuperview().inset(self.insetDx)
            case .right:
                $0.trailing.equalToSuperview().inset(self.insetDx)
            case .center:
                $0.leading.trailing.equalToSuperview().inset(self.insetDx)
            }
        }
        
        // 2. Background View 제약 조건 재설정
        backgroundView.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview().inset(self.insetDy)
            $0.width.equalTo(referenceKey).inset(self.insetDx)  // 기준 키의 너비와 동일하게
            
            switch keyAlignment {
            case .left:
                $0.leading.equalToSuperview().inset(self.insetDx)
            case .right:
                $0.trailing.equalToSuperview().inset(self.insetDx)
            case .center:
                $0.leading.trailing.equalToSuperview().inset(self.insetDx)
            }
        }
    }
    
    func updateTitleInsets() {
        // referenceKey가 존재하는 경우에만 수행
        guard let referenceKey = referenceKey else {
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
    
    func updateTitle() {
        let keys = button.keys
        if keys.count == 1 {
            guard let key = keys.first else { return }
            if key.count == 1 {
                if Character(key).isLowercase {
                    self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 24, weight: .regular), .foregroundColor: UIColor.label]))
                } else if Character(key).isUppercase {
                    self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular), .foregroundColor: UIColor.label]))
                } else {
                    self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular), .foregroundColor: UIColor.label]))
                }
            } else {
                self.configuration?.attributedTitle = AttributedString(key, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 18, weight: .regular), .foregroundColor: UIColor.label]))
            }
            
        } else {
            let joined = keys.joined(separator: "")
            self.configuration?.attributedTitle = AttributedString(joined, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 22, weight: .regular), .foregroundColor: UIColor.label]))
        }
    }
}

//
//  OneHandedModeSelectOverlayView.swift
//  Keyboard
//
//  Created by 서동환 on 7/24/25.
//

import UIKit

import SnapKit
import Then

/// 한 손 키보드 선택 UI
final class OneHandedModeSelectOverlayView: UIStackView {
    
    // MARK: - UI Components
    
    /// Material 블러 효과
    private let blurEffect = UIBlurEffect(style: .systemMaterial)
    /// Material 효과를 배경에 적용시키기 위한 뷰
    private lazy var blurView = UIVisualEffectView(effect: blurEffect)
    
    /// 왼손 모드 이미지
    private let leftKeyboardImageView = UIImageView().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        $0.image = UIImage(systemName: "keyboard.onehanded.left")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        $0.contentMode = .center
    }
    /// 왼손 모드 이미지 컨테이너
    private(set) var leftKeyboardImageContainerView = UIView().then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    /// 기본 모드 이미지
    private let normalKeyboardImageView = UIImageView().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        $0.image = UIImage(systemName: "keyboard")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        $0.contentMode = .center
    }
    /// 기본 모드 이미지 컨테이너
    private(set) var normalKeyboardImageContainerView = UIView().then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    /// 오른손 모드 이미지
    private let rightKeyboardImageView = UIImageView().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        $0.image = UIImage(systemName: "keyboard.onehanded.right")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        $0.contentMode = .center
    }
    /// 오른손 모드 이미지 컨테이너
    private(set) var rightKeyboardImageContainerView = UIView().then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Internal Methods
    
    func configure(of mode: OneHandedMode) {
        switch mode {
        case .left:
            leftKeyboardImageView.image = leftKeyboardImageView.image?.withTintColor(.white, renderingMode: .alwaysOriginal)
            leftKeyboardImageContainerView.backgroundColor = .tintColor
            normalKeyboardImageView.image = normalKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            normalKeyboardImageContainerView.backgroundColor = .clear
            rightKeyboardImageView.image = rightKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            rightKeyboardImageContainerView.backgroundColor = .clear
        case .center:
            leftKeyboardImageView.image = leftKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            leftKeyboardImageContainerView.backgroundColor = .clear
            normalKeyboardImageView.image = normalKeyboardImageView.image?.withTintColor(.white, renderingMode: .alwaysOriginal)
            normalKeyboardImageContainerView.backgroundColor = .tintColor
            rightKeyboardImageView.image = rightKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            rightKeyboardImageContainerView.backgroundColor = .clear
        case .right:
            leftKeyboardImageView.image = leftKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            leftKeyboardImageContainerView.backgroundColor = .clear
            normalKeyboardImageView.image = normalKeyboardImageView.image?.withTintColor(.label, renderingMode: .alwaysOriginal)
            normalKeyboardImageContainerView.backgroundColor = .clear
            rightKeyboardImageView.image = rightKeyboardImageView.image?.withTintColor(.white, renderingMode: .alwaysOriginal)
            rightKeyboardImageContainerView.backgroundColor = .tintColor
        }
    }
}

// MARK: - UI Methods

private extension OneHandedModeSelectOverlayView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        self.axis = .horizontal
        self.spacing = 8
        self.distribution = .fillEqually
        self.backgroundColor = .clear
        
        self.isLayoutMarginsRelativeArrangement = true
        self.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 8
    }
    
    func setHierarchy() {
        self.addSubview(blurView)
        
        self.leftKeyboardImageContainerView.addSubview(leftKeyboardImageView)
        self.normalKeyboardImageContainerView.addSubview(normalKeyboardImageView)
        self.rightKeyboardImageContainerView.addSubview(rightKeyboardImageView)
        
        self.addArrangedSubviews(leftKeyboardImageContainerView,
                                 normalKeyboardImageContainerView,
                                 rightKeyboardImageContainerView)
    }
    
    func setConstraints() {
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        leftKeyboardImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        normalKeyboardImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        rightKeyboardImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

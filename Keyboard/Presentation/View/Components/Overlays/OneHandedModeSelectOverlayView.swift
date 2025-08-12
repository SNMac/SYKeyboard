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
    private let leftOneHandedKeyboardImageView = UIImageView().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        $0.image = UIImage(systemName: "keyboard.onehanded.left")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        $0.contentMode = .center
        
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    /// 기본 모드 이미지
    private let normalKeyboardImageView = UIImageView().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        $0.image = UIImage(systemName: "keyboard")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        $0.contentMode = .center
        
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    /// 오른손 모드 이미지
    private let rightOneHandedKeyboardImageView = UIImageView().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        $0.image = UIImage(systemName: "keyboard.onehanded.right")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        $0.contentMode = .center
        
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    
    // MARK: - Initializer
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 8
    }
    
    func setHierarchy() {
        self.addSubview(blurView)
        self.addArrangedSubviews(leftOneHandedKeyboardImageView,
                                 normalKeyboardImageView,
                                 rightOneHandedKeyboardImageView)
    }
    
    func setConstraints() {
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}


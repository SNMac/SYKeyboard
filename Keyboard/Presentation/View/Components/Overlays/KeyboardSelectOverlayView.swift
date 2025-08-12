//
//  KeyboardSelectOverlayView.swift
//  Keyboard
//
//  Created by 서동환 on 7/24/25.
//

import UIKit

import SnapKit
import Then

/// 키보드 레이아웃 선택 UI
final class KeyboardSelectOverlayView: UIStackView {
    
    // MARK: - Properties
    
    private let layout: KeyboardLayout
    
    // MARK: - UI Components
    
    /// Material 블러 효과
    private let blurEffect = UIBlurEffect(style: .systemMaterial)
    /// Material 효과를 배경에 적용시키기 위한 뷰
    private lazy var blurView = UIVisualEffectView(effect: blurEffect)
    
    /// 숫자 키보드를 나타내는 라벨
    private let numericLabel = UILabel().then {
        $0.text = "123"
        $0.font = .systemFont(ofSize: 20, weight: .regular)
        $0.textAlignment = .center
        
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    /// 기호 키보드를 나타내는 라벨
    private let symbolLabel = UILabel().then {
        $0.text = "!#1"
        $0.font = .systemFont(ofSize: 20, weight: .regular)
        
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    /// 키보드 선택 취소 이미지
    private let xmarkImageView = UIImageView().then {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        $0.image = UIImage(systemName: "xmark.square")?.withConfiguration(imageConfig).withTintColor(.label, renderingMode: .alwaysOriginal)
        $0.contentMode = .center
        
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
    }
    
    // MARK: - Initializer
    
    init(layout: KeyboardLayout) {
        self.layout = layout
        super.init(frame: .zero)
        setupUI()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension KeyboardSelectOverlayView {
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
        
        switch layout {
        case .hangeul:
            self.addArrangedSubviews(numericLabel, xmarkImageView)
        case .symbol:
            self.addArrangedSubviews(xmarkImageView, numericLabel)
        case .numeric:
            self.addArrangedSubviews(symbolLabel, xmarkImageView)
        default:
            break
        }
    }
    
    func setConstraints() {
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}


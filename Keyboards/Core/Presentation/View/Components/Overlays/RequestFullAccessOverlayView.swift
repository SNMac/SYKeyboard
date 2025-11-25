//
//  RequestFullAccessOverlayView.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 11/24/25.
//

import UIKit

import SnapKit
import Then

/// 전체 접근 허용 안내 오버레이
final class RequestFullAccessOverlayView: UIView {
    
    // MARK: - UI Components
    
    private let blurEffectView = UIVisualEffectView().then {
        $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
    }
    
    private let warningLabel = UILabel().then {
        $0.text = String(localized: "전체 접근 허용 활성화 필요")
        $0.font = .systemFont(ofSize: 15, weight: .bold)
    }
    
    private let descriptionLabel = UILabel().then {
        $0.text = String(localized: "전체 접근 허용이 비활성화 되어있는 경우 일부 기능이 작동하지 않을 수 있습니다.")
        $0.font = .systemFont(ofSize: 13)
        $0.numberOfLines = 0
    }
    
    private let guideLabel = UILabel().then {
        $0.text = String(localized: "활성화 방법: 설정 ➡️ 일반 ➡️ 키보드 ➡️ 키보드 ➡️ SY키보드 ➡️ '전체 접근 허용' 활성화")
        $0.font = .systemFont(ofSize: 13)
        $0.numberOfLines = 0
    }
    
    private let buttonHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fill
        $0.spacing = 16
    }
    
    private(set) var closeButton = UIButton().then {
        var buttonConfig = UIButton.Configuration.gray()
        buttonConfig.attributedTitle = AttributedString(String(localized: "닫기"), attributes: .init([.font: UIFont.systemFont(ofSize: 15)]))
        $0.configuration = buttonConfig
        
        $0.layer.cornerRadius = 4.6
    }
    
    private(set) var goToSettingsButton = UIButton().then {
        var buttonConfig = UIButton.Configuration.filled()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        buttonConfig.image = UIImage(systemName: "gear")?.withConfiguration(imageConfig)
        buttonConfig.attributedTitle = AttributedString(String(localized: "시스템 설정 이동"), attributes: .init([.font: UIFont.systemFont(ofSize: 15)]))
        buttonConfig.imagePadding = 4
        $0.configuration = buttonConfig
        
        $0.layer.cornerRadius = 4.6
    }
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods

private extension RequestFullAccessOverlayView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    func setStyles() {
        if #available(iOS 26, *) {
            self.clipsToBounds = true
            self.layer.cornerRadius = 12
            
            closeButton.layer.cornerRadius = 8.5
            goToSettingsButton.isHidden = true
        }
    }
    
    func setHierarchy() {
        self.addSubviews(blurEffectView,
                         warningLabel,
                         descriptionLabel,
                         guideLabel,
                         buttonHStackView)
        
        buttonHStackView.addArrangedSubviews(closeButton, goToSettingsButton)
    }
    
    func setConstraints() {
        blurEffectView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        warningLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().inset(16)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(warningLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        guideLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(goToSettingsButton.snp.top).offset(-8)
        }
        
        buttonHStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }        
    }
}

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
        $0.text = String(localized: "‼️ 전체 접근 허용 활성화 필요 ‼️")
        $0.font = .systemFont(ofSize: 17, weight: .bold)
    }
    
    private let descriptionLabel = UILabel().then {
        $0.text = String(localized: "전체 접근 허용이 비활성화 되어있는 경우 일부 기능이 작동하지 않을 수 있습니다.")
        $0.font = .systemFont(ofSize: 15)
        $0.numberOfLines = 0
    }
    
    private let guideLabel = UILabel().then {
        $0.text = String(localized: "활성화 방법: 키보드 ➡️ '전체 접근 허용' 활성화")
        $0.font = .systemFont(ofSize: 15)
        $0.numberOfLines = 0
    }
    
    private let goToSettingsButton = UIButton().then {
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.image = UIImage(systemName: "gear")
        buttonConfig.title = String(localized: "시스템 설정 이동")
        buttonConfig.imagePadding = 4
        $0.configuration = buttonConfig
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

private extension RequestFullAccessOverlayView {
    func setupUI() {
        setHierarchy()
        setConstraints()
    }
    
    func setHierarchy() {
        self.addSubviews(blurEffectView,
                         warningLabel,
                         descriptionLabel,
                         guideLabel,
                         goToSettingsButton)
    }
    
    func setConstraints() {
        blurEffectView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        warningLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().inset(20)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.lessThanOrEqualTo(warningLabel.snp.bottom).offset(20).priority(.low)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        guideLabel.snp.makeConstraints {
            $0.top.greaterThanOrEqualTo(descriptionLabel.snp.bottom).priority(.high)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(goToSettingsButton.snp.top).offset(-10)
        }
        
        goToSettingsButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}

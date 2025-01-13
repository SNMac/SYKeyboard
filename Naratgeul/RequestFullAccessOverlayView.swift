//
//  RequestFullAccessOverlayView.swift
//  Naratgeul
//
//  Created by 서동환 on 1/13/25.
//

import UIKit
import SnapKit

class RequestFullAccessOverlayView: UIView {
    // MARK: - UI Components
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "‼️ 전체 접근 허용 활성화 필요 ‼️"
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "전체 접근 허용이 비활성화되어 있는 경우 일부 기능이 작동하지 않을 수 있습니다."
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        
        return label
    }()
    
    let goToSettingsButton: UIButton = {
        var buttonConfig = UIButton.Configuration.plain()
        buttonConfig.image = UIImage(systemName: "gear")
        buttonConfig.title = "시스템 설정 이동"
        buttonConfig.imagePadding = 5
        let button = UIButton(configuration: buttonConfig)
        
        return button
    }()

    // MARK: - initializers
    init() {
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Methods
private extension RequestFullAccessOverlayView {
    func setupUI() {
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        setViewHierarchy()
        setConstraints()
    }
    
    func setViewHierarchy() {
        addSubview(warningLabel)
        addSubview(descriptionLabel)
        addSubview(goToSettingsButton)
    }
    
    func setConstraints() {
        warningLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(40)
        }
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(warningLabel.snp.bottom).offset(30)
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
        }
        goToSettingsButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-30)
        }
    }
}

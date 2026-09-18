//
//  DeleteConfirmOverlayView.swift
//  SYKeyboardCore
//

import UIKit

import SYKeyboardAssets

/// 키보드 안에서 삭제를 확인받는 오버레이. 키보드 extension은 시스템 알림을 띄울 수 없어 직접 그린다
final class DeleteConfirmOverlayView: UIView {

    // MARK: - Properties

    var onCancel: (() -> Void)?
    var onConfirm: (() -> Void)?

    // MARK: - UI Components

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    private lazy var cancelButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.title = String(localized: "취소", bundle: SYKBDAssets.bundle)
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onCancel?() })
    }()

    private lazy var confirmButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "삭제", bundle: SYKBDAssets.bundle)
        config.baseBackgroundColor = .systemRed
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onConfirm?() })
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        return stackView
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12

        return stackView
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Methods

    /// 확인 제목과 설명을 바꿉니다
    func update(title: String, message: String) {
        titleLabel.text = title
        messageLabel.text = message
    }
}

// MARK: - UI Methods

private extension DeleteConfirmOverlayView {
    func setupUI() {
        [cancelButton, confirmButton].forEach { buttonStackView.addArrangedSubview($0) }
        [titleLabel, messageLabel, buttonStackView].forEach { contentStackView.addArrangedSubview($0) }
        contentStackView.setCustomSpacing(16, after: messageLabel)
        [blurView, contentStackView].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: self.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            contentStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -16)
        ])
    }
}

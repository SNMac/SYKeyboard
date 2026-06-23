//
//  CursorDragIndicatorView.swift
//  SYKeyboardCore
//
//  Created by Codex on 6/22/26.
//

import UIKit

/// 커서 드래그 표시 레이어의 OS별 visual effect 생성 정책
enum CursorDragIndicatorEffectFactory {
    static func effect() -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            return UIGlassEffect()
        } else {
            return UIBlurEffect(style: .systemUltraThinMaterial)
        }
    }
}

/// 커서 드래그 표시 레이어의 SF Symbol 생성 정책
enum CursorDragIndicatorSymbolFactory {
    static let symbolName = "character.cursor.ibeam"
    static let fallbackSymbolName = "text.cursor"

    static func image() -> UIImage? {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: FontSize.overlayLarge, weight: .regular)
        return (UIImage(systemName: symbolName) ?? UIImage(systemName: fallbackSymbolName))?
            .withConfiguration(imageConfig)
            .withRenderingMode(.alwaysTemplate)
    }
}

/// 커서 드래그 표시 레이어의 vibrancy effect 생성 정책
enum CursorDragIndicatorVibrancyEffectFactory {
    static func effect() -> UIVibrancyEffect {
        UIVibrancyEffect(
            blurEffect: UIBlurEffect(style: .systemUltraThinMaterial),
            style: .label
        )
    }
}

/// 커서 드래그가 활성화되었음을 보여주는 overlay
final class CursorDragIndicatorView: UIView {

    // MARK: - UI Components

    private lazy var effectView = UIVisualEffectView(effect: CursorDragIndicatorEffectFactory.effect())
    private lazy var vibrancyView = UIVisualEffectView(effect: CursorDragIndicatorVibrancyEffectFactory.effect())
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = CursorDragIndicatorSymbolFactory.image()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .center

        return imageView
    }()

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

private extension CursorDragIndicatorView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
    }

    func setStyles() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
        if #available(iOS 26, *) {
            self.clipsToBounds = true
            self.layer.cornerRadius = KeyboardLayoutFigure.otherOverlayCornerRadius
        }
    }

    func setHierarchy() {
        self.addSubview(effectView)
        
        if #available(iOS 26, *) {
            effectView.contentView.addSubview(imageView)
        } else {
            effectView.contentView.addSubview(vibrancyView)
            vibrancyView.contentView.addSubview(imageView)
        }
    }

    func setConstraints() {
        effectView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        if #available(iOS 26, *) {
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: effectView.contentView.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: effectView.contentView.centerYAnchor)
            ])
        } else {
            vibrancyView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                vibrancyView.topAnchor.constraint(equalTo: effectView.contentView.topAnchor),
                vibrancyView.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor),
                vibrancyView.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor),
                vibrancyView.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor),
                
                imageView.centerXAnchor.constraint(equalTo: vibrancyView.contentView.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: vibrancyView.contentView.centerYAnchor)
            ])
        }
    }
}

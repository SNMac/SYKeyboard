//
//  PrimaryButton.swift
//  Keyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

final class PrimaryButton: UIButton {
    
    // MARK: - Properties
    
    private let cornerRadius: CGFloat = 4.6
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setShadows()
    }
    
    // MARK: - Methods
    
    func configure(char: Character) {
        guard var config = self.configuration else { return }
        if char.isUppercase {
            config.attributedTitle = AttributedString(String(char), attributes: AttributeContainer([.font: UIFont.preferredFont(forTextStyle: .title2)]))
        } else {
            config.attributedTitle = AttributedString(String(char), attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 25, weight: .regular)]))
        }
        self.configuration = config
    }
}

// MARK: - UI Methods

private extension PrimaryButton {
    func setupUI() {
        setStyles()
    }
    
    func setStyles() {
        let config = UIButton.Configuration.plain()
        self.configuration = config
        self.configurationUpdateHandler = { [weak self] button in
            switch button.state {
            case .normal:
                self?.setNormalLayers()
            case .highlighted:
                self?.setHighlightedLayers()
            default:
                break
            }
        }
        
        self.layer.cornerRadius = cornerRadius
    }
    
    func setNormalLayers() {
        self.layer.removeFromSuperlayer()
        
        let layer1 = CALayer()
        let layer2 = CALayer()
        layer1.backgroundColor = UIColor.primaryButtonColor1.cgColor
        layer2.backgroundColor = UIColor.primaryButtonColor2.cgColor
        self.layer.addSublayers(layer1, layer2)
    }
    
    func setHighlightedLayers() {
        self.layer.removeFromSuperlayer()
        
        let layer1 = CALayer()
        let layer2 = CALayer()
        layer1.backgroundColor = UIColor.primaryButtonPressedColor1.cgColor
        layer2.backgroundColor = UIColor.primaryButtonPressedColor2.cgColor
        self.layer.addSublayers(layer1, layer2)
    }
    
    func setShadows() {
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
        self.layer.shadowColor = UIColor.buttonShadow.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowRadius = 0
    }
}

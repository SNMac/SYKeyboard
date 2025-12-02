//
//  UIColor+Extension.swift
//  SYKeyboardAssets
//
//  Created by 서동환 on 11/26/25.
//

import UIKit

// MARK: - SYKeyboard Colors

public extension UIColor {
    
    /// SPM 내부의 리소스 번들을 가리킵니다.
    private static var resourceBundle: Bundle { .module }
    
    // MARK: - Primary Button
    
    /// PrimaryButtonColor
    static var primaryButton: UIColor {
        return UIColor(named: "PrimaryButtonColor", in: resourceBundle, compatibleWith: nil)!
    }
    
    /// PrimaryButtonPressedColor
    static var primaryButtonPressed: UIColor {
        return UIColor(named: "PrimaryButtonPressedColor", in: resourceBundle, compatibleWith: nil)!
    }
    
    // MARK: - Secondary Button
    
    /// SecondaryButtonColor
    static var secondaryButton: UIColor {
        return UIColor(named: "SecondaryButtonColor", in: resourceBundle, compatibleWith: nil)!
    }
    
    /// SecondaryButtonPressedColor
    static var secondaryButtonPressed: UIColor {
        return UIColor(named: "SecondaryButtonPressedColor", in: resourceBundle, compatibleWith: nil)!
    }
    
    // MARK: - Chevron Button
    
    /// ChevronButtonColor
    static var chevronButton: UIColor {
        return UIColor(named: "ChevronButtonColor", in: resourceBundle, compatibleWith: nil)!
    }
    
    /// ChevronButtonPressedColor
    static var chevronButtonPressed: UIColor {
        return UIColor(named: "ChevronButtonPressedColor", in: resourceBundle, compatibleWith: nil)!
    }
    
    // MARK: - Shadow
    
    /// ButtonShadowColor
    static var buttonShadow: UIColor {
        return UIColor(named: "ButtonShadowColor", in: resourceBundle, compatibleWith: nil)!
    }
}

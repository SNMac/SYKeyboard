//
//  UIColor+Extension.swift
//  SYKeyboardAssets
//
//  Created by 서동환 on 11/26/25.
//

import UIKit

// MARK: - SYKeyboard Colors

public extension UIColor {
    
    // MARK: - Primary Button
    
    /// PrimaryButtonColor
    static var primaryButton: UIColor {
        return UIColor(named: "PrimaryButtonColor", in: SYKBDAssets.bundle, compatibleWith: nil)!
    }
    
    /// PrimaryButtonPressedColor
    static var primaryButtonPressed: UIColor {
        return UIColor(named: "PrimaryButtonPressedColor", in: SYKBDAssets.bundle, compatibleWith: nil)!
    }
    
    // MARK: - Secondary Button
    
    /// SecondaryButtonColor
    static var secondaryButton: UIColor {
        return UIColor(named: "SecondaryButtonColor", in: SYKBDAssets.bundle, compatibleWith: nil)!
    }
    
    /// SecondaryButtonPressedColor
    static var secondaryButtonPressed: UIColor {
        return UIColor(named: "SecondaryButtonPressedColor", in: SYKBDAssets.bundle, compatibleWith: nil)!
    }
    
    // MARK: - Chevron Button
    
    /// ChevronButtonColor
    static var chevronButton: UIColor {
        return UIColor(named: "ChevronButtonColor", in: SYKBDAssets.bundle, compatibleWith: nil)!
    }
    
    /// ChevronButtonPressedColor
    static var chevronButtonPressed: UIColor {
        return UIColor(named: "ChevronButtonPressedColor", in: SYKBDAssets.bundle, compatibleWith: nil)!
    }
    
    // MARK: - Shadow
    
    /// ButtonShadowColor
    static var buttonShadow: UIColor {
        return UIColor(named: "ButtonShadowColor", in: SYKBDAssets.bundle, compatibleWith: nil)!
    }
}

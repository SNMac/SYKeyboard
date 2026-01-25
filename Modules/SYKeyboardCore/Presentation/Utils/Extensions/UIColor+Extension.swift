//
//  UIColor+Extension.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 1/26/26.
//

import UIKit

public extension UIColor {
    
    // MARK: - Primary Button
    
    /// PrimaryButtonColor
    static var primaryButton: UIColor {
        return UIColor(named: "PrimaryButtonColor", in: .syKeyboardCoreResources, compatibleWith: nil) ?? .systemBackground
    }
    
    /// PrimaryButtonPressedColor
    static var primaryButtonPressed: UIColor {
        return UIColor(named: "PrimaryButtonPressedColor", in: .syKeyboardCoreResources, compatibleWith: nil) ?? .systemGroupedBackground
    }
    
    // MARK: - Secondary Button
    
    /// SecondaryButtonColor
    static var secondaryButton: UIColor {
        return UIColor(named: "SecondaryButtonColor", in: .syKeyboardCoreResources, compatibleWith: nil) ?? .secondarySystemBackground
    }
    
    /// SecondaryButtonPressedColor
    static var secondaryButtonPressed: UIColor {
        return UIColor(named: "SecondaryButtonPressedColor", in: .syKeyboardCoreResources, compatibleWith: nil) ?? .secondarySystemGroupedBackground
    }
    
    // MARK: - Chevron Button
    
    /// ChevronButtonColor
    static var chevronButton: UIColor {
        return UIColor(named: "ChevronButtonColor", in: .syKeyboardCoreResources, compatibleWith: nil) ?? .systemBackground
    }
    
    /// ChevronButtonPressedColor
    static var chevronButtonPressed: UIColor {
        return UIColor(named: "ChevronButtonPressedColor", in: .syKeyboardCoreResources, compatibleWith: nil) ?? .systemGroupedBackground
    }
    
    // MARK: - Shadow
    
    /// ButtonShadowColor
    static var buttonShadow: UIColor {
        return UIColor(named: "ButtonShadowColor", in: .syKeyboardCoreResources, compatibleWith: nil) ?? .darkGray
    }
}

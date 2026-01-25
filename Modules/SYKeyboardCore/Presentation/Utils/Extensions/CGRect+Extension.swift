//
//  CGRect+Extension.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 11/30/25.
//

import UIKit

extension CGRect {
    var center : CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
}

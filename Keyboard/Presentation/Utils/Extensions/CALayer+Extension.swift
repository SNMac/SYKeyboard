//
//  CALayer+Extension.swift
//  Keyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

extension CALayer {
    func addSublayers(_ layers: CALayer...) {
        layers.forEach {
            $0.frame = self.bounds
            self.addSublayer($0)
        }
    }
}

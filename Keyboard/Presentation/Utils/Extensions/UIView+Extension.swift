//
//  UIView+Extension.swift
//  Keyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach {
            self.addSubview($0)
        }
    }
}

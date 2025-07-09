//
//  UIStackView+Extension.swift
//  Keyboard
//
//  Created by 서동환 on 7/10/25.
//

import UIKit

extension UIStackView {
    func addArrangedSubviews(_ views: UIView...) {
        views.forEach {
            self.addArrangedSubview($0)
        }
    }
}

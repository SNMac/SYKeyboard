//
//  TextInteractionButton.swift
//  Keyboard
//
//  Created by 서동환 on 9/3/25.
//

import UIKit

protocol TextInteractionButton: UIButton {
    var keys: [String] { get }
}

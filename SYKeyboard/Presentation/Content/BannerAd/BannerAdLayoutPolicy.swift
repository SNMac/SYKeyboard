//
//  BannerAdLayoutPolicy.swift
//  SYKeyboard
//
//  Created by Codex on 6/19/26.
//

import Foundation

enum BannerAdLayoutPolicy {
    
    // MARK: - Internal Methods
    
    static func containerHeight(adHeight: CGFloat, isAdReceived: Bool) -> CGFloat {
        isAdReceived ? adHeight : 0
    }
}

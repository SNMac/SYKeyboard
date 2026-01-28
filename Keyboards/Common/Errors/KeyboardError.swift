//
//  KeyboardError.swift
//  HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 1/29/26.
//

import Foundation

enum KeyboardError: LocalizedError {
    case invalidSettingsURL(url: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidSettingsURL(let url):
            return "Invalid URL Format: \(url)"
        }
    }
}

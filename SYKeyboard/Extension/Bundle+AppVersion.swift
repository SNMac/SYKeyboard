//
//  Bundle+AppVersion.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/16/25.
//

import Foundation

extension Bundle {
    static var currentAppVersion: String? {
        #if os(macOS)
        let infoDictionaryKey = "CFBundleShortVersionString"
        #else
        let infoDictionaryKey = "CFBundleVersion"
        #endif
        
        return Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
    }
}

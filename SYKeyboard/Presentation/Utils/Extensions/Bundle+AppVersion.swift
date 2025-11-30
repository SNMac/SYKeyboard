//
//  Bundle+AppVersion.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/16/25.
//

import Foundation

extension Bundle {
    static var displayName: String? {
        return main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
    
    static var appVersion: String? {
        return main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    static var appBuild: String? {
        return main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}

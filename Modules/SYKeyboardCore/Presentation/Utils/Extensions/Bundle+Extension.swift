//
//  Bundle+Extension.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/9/25.
//

import Foundation

private class BundleToken {}

extension Bundle {
    /// SYKeyboardCore의 리소스 번들에 접근하기 위한 Singleton 프로퍼티
    static let syKeyboardCoreResources: Bundle = {
        let bundleName = "SYKeyboardCoreResources"
        
        let candidates = [
            Bundle(for: BundleToken.self),
            Bundle.main
        ]
        
        for candidate in candidates {
            if let resourceURL = candidate.url(forResource: bundleName, withExtension: "bundle"),
               let resourceBundle = Bundle(url: resourceURL) {
                return resourceBundle
            }
        }
        
        let manualBundlePath = Bundle.main.bundleURL.appendingPathComponent(bundleName + ".bundle")
        if let resourceBundle = Bundle(url: manualBundlePath) {
            return resourceBundle
        }
        
        assertionFailure("\(bundleName).bundle을 찾을 수 없습니다.")
        return Bundle.main
    }()
    
    /// Info.plist에서 "PrimaryLanguage" 값을 가져오는 연산 프로퍼티
    static var primaryLanguage: String? {
        guard let nsExtensionDict = main.object(forInfoDictionaryKey: "NSExtension") as? [String: Any],
              let attributesDict = nsExtensionDict["NSExtensionAttributes"] as? [String: Any] else { return nil }
        return attributesDict["PrimaryLanguage"] as? String
    }
}

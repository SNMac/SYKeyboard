//
//  Bundle+Extension.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 9/9/25.
//

import Foundation

private class BundleToken {}

extension Bundle {
    /// `SYKeyboardCore` 모듈의 리소스 번들(Assets, Color 등)에 접근하기 위한 싱글톤 프로퍼티
    ///
    /// Static Framework 환경에서는 리소스 번들이 실행 앱(Host App)의 번들 내부에 복사되어 위치하게 됩니다.
    /// 이 프로퍼티는 앱 실행 시 최초 1회 실행되며, 다음 순서로 번들을 탐색하여 메모리에 캐싱합니다.
    ///
    /// 1. **BundleToken 위치**: 유닛 테스트 등 별도 모듈 환경
    /// 2. **Main Bundle**: 실제 앱 실행 환경
    ///
    /// - Note: 만약 `SYKeyboardCoreResources.bundle`을 찾지 못할 경우,
    ///         앱 크래시를 방지하기 위해 `Bundle.main`을 기본값으로 반환합니다.
    static let syKeyboardCoreResources: Bundle = {
        let bundleName = "SYKeyboardCoreResources"
        
        let candidates = [
            Bundle(for: BundleToken.self).resourceURL,
            Bundle.main.bundleURL,
            Bundle.main.resourceURL,
        ]
        
        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
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

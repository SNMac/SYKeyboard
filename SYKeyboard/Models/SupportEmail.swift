//
//  SupportEmail.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/21/25.
//

import SwiftUI
import OSLog

struct SupportEmail {
    private let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "SupportEmail")
    
    let toAddress: String
    let subject: String
    let messageHeader: String
    
    let applicationNameStr = String(localized: "앱 이름")
    let appVersionStr = String(localized: "앱 버전")
    let appBuildStr = String(localized: "앱 빌드")
    let iosVersion = String(localized: "iOS 버전")
    let deviceModelStr = String(localized: "단말기 모델")
    
    var body: String {
    """
    \(applicationNameStr): \(Bundle.displayName ?? "Unknown")
    \(appVersionStr): \(Bundle.appVersion ?? "Unknown")
    \(appBuildStr): \(Bundle.appBuild ?? "Unknown")
    \(iosVersion): \(UIDevice.current.systemVersion)
    \(deviceModelStr): \(UIDevice.current.modelName)
    
    \(messageHeader)
    --------------------------------------
    
    
    """
    }
    
    func send(openURL: OpenURLAction) {
        let urlString = "mailto:\(toAddress)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        guard let url = URL(string: urlString) else {
            return
        }
        openURL(url) { accepted in
            if !accepted {
                os_log(
                """
                This device does not support email
                --------------------------------------
                %@
                """, log: log, type: .debug, body)
            }
        }
    }
}

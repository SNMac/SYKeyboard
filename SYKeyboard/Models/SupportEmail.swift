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
    
    let applicationNameLocalStr = String(localized: "앱 이름")
    let appVersionLocalStr = String(localized: "앱 버전")
    let appBuildLocalStr = String(localized: "앱 빌드")
    let iosVersionLocalStr = String(localized: "iOS 버전")
    let deviceModelLocalStr = String(localized: "단말기 모델")
    
    var body: String {
    """
    \(applicationNameLocalStr): \(Bundle.displayName ?? "Unknown")
    \(appVersionLocalStr): \(Bundle.appVersion ?? "Unknown")
    \(appBuildLocalStr): \(Bundle.appBuild ?? "Unknown")
    \(iosVersionLocalStr): \(UIDevice.current.systemVersion)
    \(deviceModelLocalStr): \(UIDevice.current.modelName)
    
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

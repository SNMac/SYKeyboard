//
//  SupportEmailModel.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/21/25.
//

import SwiftUI

struct SupportEmailModel {
    
    private let toAddress: String
    private let subject: String
    private let messageHeader: String
    
    private let applicationNameStr = String(localized: "앱 이름")
    private let appVersionStr = String(localized: "앱 버전")
    private let appBuildStr = String(localized: "앱 빌드")
    private let iosVersionStr = String(localized: "iOS 버전")
    private let deviceModelStr = String(localized: "단말기 모델")
    
    var body: String {
    """
    \(applicationNameStr): \(Bundle.displayName ?? "Unknown")
    \(appVersionStr): \(Bundle.appVersion ?? "Unknown")
    \(appBuildStr): \(Bundle.appBuild ?? "Unknown")
    \(iosVersionStr): \(UIDevice.current.systemVersion)
    \(deviceModelStr): \(UIDevice.current.modelName)
    
    \(messageHeader)
    --------------------------------------
    
    
    """
    }
    
    init(toAddress: String, subject: String, messageHeader: String) {
        self.toAddress = toAddress
        self.subject = subject
        self.messageHeader = messageHeader
    }
    
    func makeURL() -> URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "mailto:\(toAddress)?subject=\(encodedSubject)&body=\(encodedBody)"
        return URL(string: urlString)
    }
}

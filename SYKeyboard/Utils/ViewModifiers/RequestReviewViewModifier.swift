//
//  RequestReview.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/16/25.
//

import SwiftUI
import StoreKit
import OSLog

struct RequestReviewViewModifier: ViewModifier {
    private let log = OSLog(subsystem: "github.com-SNMac.SYKeyboard", category: "RequestReviewViewModifier")
    
    @Environment(\.requestReview) private var requestReview
    @AppStorage("reviewCounter", store: UserDefaults(suiteName: UserDefaultsManager.groupBundleID)) var reviewCounter = 0
    @AppStorage("lastBuildPromptedForReview", store: UserDefaults(suiteName: UserDefaultsManager.groupBundleID)) var lastBuildPromptedForReview = ""
    
    private func presentReview() {
        Task {
            try await Task.sleep(for: .seconds(1))
            requestReview()
        }
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                reviewCounter += 1
                os_log("reviewCounter = %d", log: log, type: .debug, reviewCounter)
            }
            .onDisappear {
                guard let currentAppBuild = Bundle.appBuild else {
                    return
                }
                
                if reviewCounter >= 50, currentAppBuild != lastBuildPromptedForReview {
                    reviewCounter = 0
                    presentReview()
                    
                    lastBuildPromptedForReview = currentAppBuild
                }
            }
    }
}

extension View {
    func requestReviewViewModifier() -> some View {
        modifier(RequestReviewViewModifier())
    }
}

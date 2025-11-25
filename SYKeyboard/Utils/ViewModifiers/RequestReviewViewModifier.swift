//
//  RequestReviewViewModifier.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/16/25.
//

import SwiftUI
import StoreKit
import OSLog

import SYKeyboardCore

struct RequestReviewViewModifier: ViewModifier {
    private let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "RequestReviewViewModifier")
    
    @Environment(\.requestReview) private var requestReview
    @AppStorage(UserDefaultsKeys.reviewCounter, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) var reviewCounter = DefaultValues.reviewCounter
    @AppStorage(UserDefaultsKeys.lastBuildPromptedForReview, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) var lastBuildPromptedForReview = DefaultValues.lastBuildPromptedForReview
    
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

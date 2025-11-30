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
    
    // MARK: - Properties
    
    @Environment(\.requestReview) private var requestReview
    @AppStorage(UserDefaultsKeys.reviewCounter, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) var reviewCounter = DefaultValues.reviewCounter
    @AppStorage(UserDefaultsKeys.lastBuildPromptedForReview, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) var lastBuildPromptedForReview = DefaultValues.lastBuildPromptedForReview
    
    // MARK: - Content
    
    func body(content: Content) -> some View {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
        
        content
            .onAppear {
                reviewCounter += 1
                logger.debug("reviewCounter = \(reviewCounter)")
            }
            .onDisappear {
                guard let currentAppBuild = Bundle.appBuild else { return }
                if reviewCounter >= 50, currentAppBuild != lastBuildPromptedForReview {
                    reviewCounter = 0
                    presentReview()
                    lastBuildPromptedForReview = currentAppBuild
                }
            }
    }
}

// MARK: - Private Methods

private extension RequestReviewViewModifier {
    func presentReview() {
        Task {
            try await Task.sleep(for: .seconds(1))
            requestReview()
        }
    }
}

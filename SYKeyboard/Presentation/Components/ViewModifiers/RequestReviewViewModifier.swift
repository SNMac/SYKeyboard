//
//  RequestReviewViewModifier.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/16/25.
//

import SwiftUI
import OSLog
import StoreKit

struct RequestReviewViewModifier: ViewModifier {
    
    // MARK: - Properties
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "RequestReviewViewModifier"
    )
    
    @Environment(\.requestReview) private var requestReview
    
    @AppStorage(AppUserDefaultsKeys.reviewCounter, store: AppUserDefaultsManager.shared.storage)
    var reviewCounter = AppDefaultValues.reviewCounter
    
    @AppStorage(AppUserDefaultsKeys.lastBuildPromptedForReview, store: AppUserDefaultsManager.shared.storage)
    var lastBuildPromptedForReview = AppDefaultValues.lastBuildPromptedForReview
    
    // MARK: - Content
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                reviewCounter += 1
                Self.logger.debug("reviewCounter = \(reviewCounter)")
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
            try? await Task.sleep(for: .seconds(1))
            requestReview()
        }
    }
}

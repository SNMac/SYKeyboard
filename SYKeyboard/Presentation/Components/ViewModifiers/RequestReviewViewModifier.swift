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

    enum Action {
        case requestAfterDetailSettingsReturn
    }

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "RequestReviewViewModifier"
    )

    @Environment(\.requestReview) private var requestReview

    let action: Action
    let isEnabled: Bool

    @AppStorage(AppUserDefaultsKeys.reviewCounter, store: AppUserDefaultsManager.shared.storage)
    private var reviewCounter = AppDefaultValues.reviewCounter

    @AppStorage(AppUserDefaultsKeys.lastBuildPromptedForReview, store: AppUserDefaultsManager.shared.storage)
    private var lastBuildPromptedForReview = AppDefaultValues.lastBuildPromptedForReview

    // MARK: - Content

    init(action: Action,
         isEnabled: Bool) {
        self.action = action
        self.isEnabled = isEnabled
    }

    func body(content: Content) -> some View {
        content
            .onDisappear {
                requestReviewAfterDetailSettingsReturnIfNeeded()
            }
    }
}

// MARK: - Private Methods

private extension RequestReviewViewModifier {
    func requestReviewAfterDetailSettingsReturnIfNeeded() {
        guard action == .requestAfterDetailSettingsReturn else { return }

        let result = RequestReviewPolicy.recordDetailSettingsReturnAndEvaluate(
            reviewCounter: reviewCounter,
            currentAppBuild: Bundle.appBuild,
            lastBuildPromptedForReview: lastBuildPromptedForReview,
            isEligible: isEnabled
        )

        reviewCounter = result.reviewCounter
        lastBuildPromptedForReview = result.lastBuildPromptedForReview
        Self.logger.debug("reviewCounter = \(reviewCounter)")

        if result.shouldRequestReview {
            presentReview()
        }
    }

    func presentReview() {
        Task {
            try? await Task.sleep(for: .seconds(1))
            requestReview()
        }
    }
}

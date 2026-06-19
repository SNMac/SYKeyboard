//
//  ContentView.swift
//  SYKeyboard
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import OSLog

import GoogleMobileAds

struct ContentView: View {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "ContentView"
    )

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(AppUserDefaultsKeys.isOnboarding, store: AppUserDefaultsManager.shared.storage)
    private var isOnboarding = AppDefaultValues.isOnboarding

    @AppStorage(AppUserDefaultsKeys.reviewCounter, store: AppUserDefaultsManager.shared.storage)
    private var reviewCounter = AppDefaultValues.reviewCounter

    @AppStorage(AppUserDefaultsKeys.lastBuildPromptedForReview, store: AppUserDefaultsManager.shared.storage)
    private var lastBuildPromptedForReview = AppDefaultValues.lastBuildPromptedForReview

    @State private var isAdReceived: Bool = false

    @State private var hasRecordedReviewEligibleVisit: Bool = false

    // MARK: - Content

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let adSize = largeAnchoredAdaptiveBanner(width: geometry.size.width)
                let adHeight = BannerAdLayoutPolicy.containerHeight(
                    adHeight: adSize.size.height,
                    isAdReceived: isAdReceived
                )

                ZStack(alignment: .bottom) {
                    VStack {
                        KeyboardTestView()

                        KeyboardSettingsView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .safeAreaInset(edge: .bottom) {
                        BannerAdView(adSize: adSize, isAdReceived: $isAdReceived)
                            .frame(maxWidth: .infinity, maxHeight: adHeight)
                            .background(isAdReceived ? Color(.systemBackground) : .clear, ignoresSafeAreaEdges: .bottom)
                            .opacity(isAdReceived ? 1 : 0)
                            .allowsHitTesting(isAdReceived)
                            .animation(.easeInOut(duration: 1), value: isAdReceived)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
            .onAppear {
                hideKeyboard()
                recordReviewEligibleAppLaunchIfNeeded()
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .active, .inactive:
                    recordReviewEligibleAppLaunchIfNeeded()
                default:
                    break
                }
            }
            .navigationTitle(Bundle.displayName ?? "SY키보드")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isOnboarding) {
                InstructionsTabView()
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.8)])
            }
        }
    }
}

// MARK: - Private Methods

private extension ContentView {
    func recordReviewEligibleAppLaunchIfNeeded() {
        guard !hasRecordedReviewEligibleVisit else { return }

        let result = RequestReviewPolicy.recordEligibleInteraction(
            reviewCounter: reviewCounter,
            lastBuildPromptedForReview: lastBuildPromptedForReview,
            isEligible: !isOnboarding && KeyboardExtensionAvailability.isEnabled()
        )

        guard result.reviewCounter != reviewCounter else { return }

        hasRecordedReviewEligibleVisit = true
        reviewCounter = result.reviewCounter
        lastBuildPromptedForReview = result.lastBuildPromptedForReview
        Self.logger.debug("reviewCounter = \(reviewCounter)")
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

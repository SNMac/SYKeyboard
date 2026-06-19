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
            isEligible: !isOnboarding && checkKeyboardExtensionEnabled()
        )

        guard result.reviewCounter != reviewCounter else { return }

        hasRecordedReviewEligibleVisit = true
        reviewCounter = result.reviewCounter
        lastBuildPromptedForReview = result.lastBuildPromptedForReview
        Self.logger.debug("reviewCounter = \(reviewCounter)")
    }

    /// 사용자의 "AppleKeyboards" 설정에 현재 앱의 키보드 확장이 포함되어 있는지 여부를 반환하는 메서드
    func checkKeyboardExtensionEnabled() -> Bool {
        // 사용자의 설정 데이터 가져옴
        //   - "AppleKeyboards" 값은 사용자가 설정에서 활성화한 키보드 목록(예: "com.apple.keyboard.emoji", "com.thirdparty.customkeyboard")을 포함
        guard let keyboards = UserDefaults.standard.dictionaryRepresentation()["AppleKeyboards"] as? [String] else {
            return false
        }

        // 현재 앱의 Bundle ID에 "."을 붙여서 키보드 확장의 Bundle ID 패턴을 생성
        //   - 메인 앱의 Bundle ID: "github.com-SNMac.SYKeyboard"
        //     -> 키보드 Extension의 Bundle ID: "github.com-SNMac.SYKeyboard.keyboard"
        let keyboardExtensionBundleIDPrefix = (Bundle.main.bundleIdentifier ?? "Unknown Bundle") + "."
        for keyboard in keyboards {
            // "AppleKeyboards" 목록을 순회하며 현재 앱의 키보드 확장이 포함되어 있는지 검사
            if keyboard.hasPrefix(keyboardExtensionBundleIDPrefix) {
                return true
            }
        }

        return false
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

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

    /// 배너 광고 크기. 화면 폭이 정해진 뒤 `updateBannerAdSize(width:)`가 정한다
    @State private var bannerAdSize: AdSize?

    @State private var hasRecordedReviewEligibleVisit: Bool = false

    // MARK: - Content

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let adHeight = BannerAdLayoutPolicy.containerHeight(
                    adHeight: bannerAdSize?.size.height ?? 0,
                    isAdReceived: isAdReceived
                )

                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        KeyboardTestView()
                            // 입력창과 목록 사이 간격을 헤더 흰 배경 안에 넣는다. 예전 VStack 기본 간격과 같은 값이다
                            .padding(.bottom, 8)
                            .background(Color(.systemBackground).ignoresSafeArea(edges: .top))

                        KeyboardSettingsView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    // iPhone Duo 세로 바 영역을 목록 배경 한 색으로 채운다. 헤더 흰색은 세로 바 앞에서 끝난다
                    .background(Color(.systemGroupedBackground).ignoresSafeArea())
                    .safeAreaInset(edge: .bottom) {
                        if let bannerAdSize {
                            BannerAdView(adSize: bannerAdSize, isAdReceived: $isAdReceived)
                                // SDK는 배너 뷰 크기가 바뀌면 광고 크기를 그 크기로 바꾼다. 광고를 받기 전 높이 0이나
                                // 회전 중 새 폭·옛 높이로 요청하지 않도록 뷰 크기를 광고 크기에 고정한다
                                .frame(width: bannerAdSize.size.width, height: bannerAdSize.size.height)
                                .frame(maxWidth: .infinity, maxHeight: adHeight, alignment: .top)
                                .background(isAdReceived ? Color(.systemBackground) : .clear, ignoresSafeAreaEdges: .bottom)
                                .opacity(isAdReceived ? 1 : 0)
                                .allowsHitTesting(isAdReceived)
                                .animation(.easeInOut(duration: 1), value: isAdReceived)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                .task(id: geometry.size.width) {
                    await updateBannerAdSize(width: geometry.size.width)
                }
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
    /// 화면 폭에 맞는 배너 광고 크기를 정한다.
    ///
    /// 회전하면 중간 폭이 먼저 오고 곧이어 최종 폭이 온다. 폭마다 정하면 회전 한 번에 광고 요청이 여러 번 나가고,
    /// 중간 폭의 크기는 바뀐 화면 방향 기준이라 화면과 맞지 않는다(세로로 돌 때 가로 폭 812pt로 계산한 세로 광고).
    /// 그래서 첫 크기 이후에는 폭이 멈춘 뒤 한 번만 정한다
    func updateBannerAdSize(width: CGFloat) async {
        guard width > 0 else { return }

        if bannerAdSize != nil {
            try? await Task.sleep(for: BannerAdLayoutPolicy.adSizeSettleDelay)
            guard !Task.isCancelled else { return }
        }

        bannerAdSize = largeAnchoredAdaptiveBanner(width: width)
    }

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

//
//  RequestReview.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/16/25.
//

import SwiftUI
import StoreKit

struct RequestReviewViewModifier: ViewModifier {
    @Environment(\.requestReview) private var requestReview
    @AppStorage("reviewCounter", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) var reviewCounter = 0
    @AppStorage("lastVersionPromptedForReview", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) var lastVersionPromptedForReview = ""
    
    private func presentReview() {
        Task {
            try await Task.sleep(for: .seconds(1))
            await requestReview()
        }
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                reviewCounter += 1
                print(reviewCounter)
            }
            .onDisappear {
                guard let currentAppVersion = Bundle.currentAppVersion else {
                    return
                }
                
                if reviewCounter >= 40, currentAppVersion != lastVersionPromptedForReview {
                    reviewCounter = 0
                    presentReview()
                        
                    lastVersionPromptedForReview = currentAppVersion
                }
            }
    }
}

extension View {
    func requestReviewViewModifier() -> some View {
        modifier(RequestReviewViewModifier())
    }
}

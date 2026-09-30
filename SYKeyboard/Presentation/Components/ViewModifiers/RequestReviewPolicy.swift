//
//  RequestReviewPolicy.swift
//  SYKeyboard
//
//  Created by Codex on 6/19/26.
//

enum RequestReviewPolicy {
    
    // MARK: - Nested Types
    
    struct Result {
        let reviewCounter: Int
        let lastBuildPromptedForReview: String
        let shouldRequestReview: Bool
    }
    
    // MARK: - Properties
    
    static let threshold = 30
    
    // MARK: - Internal Methods
    
    static func recordEligibleInteraction(reviewCounter: Int,
                                          lastBuildPromptedForReview: String = "",
                                          isEligible: Bool) -> Result {
        guard isEligible else {
            return Result(reviewCounter: reviewCounter,
                          lastBuildPromptedForReview: lastBuildPromptedForReview,
                          shouldRequestReview: false)
        }
        
        return Result(reviewCounter: reviewCounter + 1,
                      lastBuildPromptedForReview: lastBuildPromptedForReview,
                      shouldRequestReview: false)
    }
    
    static func evaluateDetailSettingsReturn(reviewCounter: Int,
                                             currentAppBuild: String?,
                                             lastBuildPromptedForReview: String,
                                             isEligible: Bool) -> Result {
        guard isEligible,
              let currentAppBuild,
              reviewCounter >= threshold,
              currentAppBuild != lastBuildPromptedForReview else {
            return Result(reviewCounter: reviewCounter,
                          lastBuildPromptedForReview: lastBuildPromptedForReview,
                          shouldRequestReview: false)
        }
        
        return Result(reviewCounter: 0,
                      lastBuildPromptedForReview: currentAppBuild,
                      shouldRequestReview: true)
    }
    
    static func recordDetailSettingsReturnAndEvaluate(reviewCounter: Int,
                                                      currentAppBuild: String?,
                                                      lastBuildPromptedForReview: String,
                                                      isEligible: Bool) -> Result {
        let recordResult = recordEligibleInteraction(
            reviewCounter: reviewCounter,
            lastBuildPromptedForReview: lastBuildPromptedForReview,
            isEligible: isEligible
        )
        
        return evaluateDetailSettingsReturn(
            reviewCounter: recordResult.reviewCounter,
            currentAppBuild: currentAppBuild,
            lastBuildPromptedForReview: recordResult.lastBuildPromptedForReview,
            isEligible: isEligible
        )
    }
}

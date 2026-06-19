//
//  RequestReviewPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/19/26.
//

import Testing

@testable import SYKeyboard

@Suite("자동 리뷰 요청 정책 검증")
struct RequestReviewPolicyTests {

    @Test("앱 실행은 카운트만 증가시키고 즉시 요청하지 않음")
    func testValidAppLaunchIncrementsCounterWithoutPrompting() {
        let result = RequestReviewPolicy.recordEligibleInteraction(
            reviewCounter: 29,
            isEligible: true
        )

        #expect(result.reviewCounter == 30)
        #expect(result.shouldRequestReview == false)
    }

    @Test("온보딩 또는 키보드 미추가 상태에서는 앱 실행을 카운트하지 않음")
    func testInvalidAppLaunchDoesNotIncrementCounter() {
        let result = RequestReviewPolicy.recordEligibleInteraction(
            reviewCounter: 29,
            isEligible: false
        )

        #expect(result.reviewCounter == 29)
        #expect(result.shouldRequestReview == false)
    }

    @Test("상세 설정 복귀 시 1회 카운트한 뒤 기준 횟수와 빌드 조건을 만족하면 요청하고 카운터를 초기화")
    func testDetailReturnRequestsReviewWhenThresholdReached() {
        let result = RequestReviewPolicy.recordDetailSettingsReturnAndEvaluate(
            reviewCounter: 29,
            currentAppBuild: "100",
            lastBuildPromptedForReview: "99",
            isEligible: true
        )

        #expect(result.reviewCounter == 0)
        #expect(result.lastBuildPromptedForReview == "100")
        #expect(result.shouldRequestReview == true)
    }

    @Test("앱 실행은 기준 횟수를 채워도 즉시 요청하지 않음")
    func testAppLaunchDoesNotPromptEvenWhenCounterReachesThreshold() {
        let result = RequestReviewPolicy.recordEligibleInteraction(
            reviewCounter: 29,
            isEligible: true
        )

        #expect(result.reviewCounter == 30)
        #expect(result.shouldRequestReview == false)
    }

    @Test("같은 빌드에서는 상세 설정 복귀 시에도 다시 요청하지 않음")
    func testDetailReturnDoesNotRequestTwiceForSameBuild() {
        let result = RequestReviewPolicy.recordDetailSettingsReturnAndEvaluate(
            reviewCounter: 29,
            currentAppBuild: "100",
            lastBuildPromptedForReview: "100",
            isEligible: true
        )

        #expect(result.reviewCounter == 30)
        #expect(result.lastBuildPromptedForReview == "100")
        #expect(result.shouldRequestReview == false)
    }
}

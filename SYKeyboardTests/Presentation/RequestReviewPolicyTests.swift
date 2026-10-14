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

    @Test("상세 설정 복귀는 1회 카운트한 뒤 30회에 닿고 현재 빌드(100)에서 아직 요청하지 않았을 때만 요청하고 카운터를 초기화",
          arguments: [
            // (label, reviewCounter, lastBuildPrompted, expectedCounter, expectedLastBuild, expectRequest)
            ("기준 횟수와 빌드 조건을 만족하면 요청하고 카운터를 초기화", 29, "99", 0, "100", true),
            ("카운트해도 30회 미만이면 요청하지 않음", 28, "99", 29, "99", false),
            ("같은 빌드에서는 다시 요청하지 않음", 29, "100", 30, "100", false)
          ])
    func testDetailSettingsReturn(
        label: String,
        reviewCounter: Int,
        lastBuildPrompted: String,
        expectedCounter: Int,
        expectedLastBuild: String,
        expectRequest: Bool
    ) {
        let result = RequestReviewPolicy.recordDetailSettingsReturnAndEvaluate(
            reviewCounter: reviewCounter,
            currentAppBuild: "100",
            lastBuildPromptedForReview: lastBuildPrompted,
            isEligible: true
        )

        #expect(result.reviewCounter == expectedCounter)
        #expect(result.lastBuildPromptedForReview == expectedLastBuild)
        #expect(result.shouldRequestReview == expectRequest)
    }
}

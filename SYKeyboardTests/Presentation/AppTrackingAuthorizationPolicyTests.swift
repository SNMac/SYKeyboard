//
//  AppTrackingAuthorizationPolicyTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/19/26.
//

import Testing

@testable import SYKeyboard

@Suite("ATT 요청 정책 검증")
struct AppTrackingAuthorizationPolicyTests {

    @Test("온보딩 중에는 ATT 요청하지 않음")
    func testDoesNotRequestDuringOnboarding() {
        let result = AppTrackingAuthorizationPolicy.evaluateDidBecomeActive(
            isTrackingAuthorizationNotDetermined: true,
            isOnboarding: true,
            isHandlingSettingsRedirect: false
        )

        #expect(result.shouldRequestAuthorization == false)
        #expect(result.shouldClearSettingsRedirect == false)
    }

    @Test("설정 redirect 처리 중에는 ATT 요청하지 않고 redirect 상태를 해제")
    func testDoesNotRequestDuringSettingsRedirectAndClearsRedirectState() {
        let result = AppTrackingAuthorizationPolicy.evaluateDidBecomeActive(
            isTrackingAuthorizationNotDetermined: true,
            isOnboarding: false,
            isHandlingSettingsRedirect: true
        )

        #expect(result.shouldRequestAuthorization == false)
        #expect(result.shouldClearSettingsRedirect == true)
    }

    @Test("온보딩이 끝났고 redirect 중이 아니며 ATT 상태가 미결정이면 요청")
    func testRequestsAfterOnboardingWhenStatusNotDetermined() {
        let result = AppTrackingAuthorizationPolicy.evaluateDidBecomeActive(
            isTrackingAuthorizationNotDetermined: true,
            isOnboarding: false,
            isHandlingSettingsRedirect: false
        )

        #expect(result.shouldRequestAuthorization == true)
        #expect(result.shouldClearSettingsRedirect == false)
    }
    
    @Test("온보딩이 닫히면 설정 redirect 중이 아닐 때 ATT 요청")
    func testRequestsAfterOnboardingDismissed() {
        let result = AppTrackingAuthorizationPolicy.evaluateOnboardingDismissed(
            isTrackingAuthorizationNotDetermined: true,
            isHandlingSettingsRedirect: false
        )
        
        #expect(result.shouldRequestAuthorization == true)
    }
    
    @Test("설정 redirect 중에는 온보딩이 닫혀도 ATT 요청하지 않음")
    func testDoesNotRequestAfterOnboardingDismissedDuringSettingsRedirect() {
        let result = AppTrackingAuthorizationPolicy.evaluateOnboardingDismissed(
            isTrackingAuthorizationNotDetermined: true,
            isHandlingSettingsRedirect: true
        )
        
        #expect(result.shouldRequestAuthorization == false)
    }
}

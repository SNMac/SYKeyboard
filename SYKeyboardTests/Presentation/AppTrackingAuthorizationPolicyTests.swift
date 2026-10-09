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

    @Test("활성화 시 온보딩이 끝났고 redirect 중이 아니며 ATT 상태가 미결정일 때만 요청하고, redirect 처리 중이면 redirect 상태만 해제",
          arguments: [
            // (label, notDetermined, isOnboarding, isHandlingRedirect, expectRequest, expectClear)
            ("온보딩 중에는 ATT 요청하지 않음", true, true, false, false, false),
            ("설정 redirect 처리 중에는 ATT 요청하지 않고 redirect 상태를 해제", true, false, true, false, true),
            ("온보딩이 끝났고 redirect 중이 아니며 ATT 상태가 미결정이면 요청", true, false, false, true, false)
          ])
    func testEvaluateDidBecomeActive(
        label: String,
        notDetermined: Bool,
        isOnboarding: Bool,
        isHandlingRedirect: Bool,
        expectRequest: Bool,
        expectClear: Bool
    ) {
        let result = AppTrackingAuthorizationPolicy.evaluateDidBecomeActive(
            isTrackingAuthorizationNotDetermined: notDetermined,
            isOnboarding: isOnboarding,
            isHandlingSettingsRedirect: isHandlingRedirect
        )

        #expect(result.shouldRequestAuthorization == expectRequest)
        #expect(result.shouldClearSettingsRedirect == expectClear)
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

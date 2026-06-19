//
//  AppTrackingAuthorizationPolicy.swift
//  SYKeyboard
//
//  Created by Codex on 6/19/26.
//

enum AppTrackingAuthorizationPolicy {
    
    // MARK: - Nested Types
    
    struct Result {
        let shouldRequestAuthorization: Bool
        let shouldClearSettingsRedirect: Bool
    }
    
    // MARK: - Internal Methods
    
    static func evaluateDidBecomeActive(isTrackingAuthorizationNotDetermined: Bool,
                                        isOnboarding: Bool,
                                        isHandlingSettingsRedirect: Bool) -> Result {
        if isHandlingSettingsRedirect {
            return Result(shouldRequestAuthorization: false,
                          shouldClearSettingsRedirect: true)
        }
        
        return Result(shouldRequestAuthorization: isTrackingAuthorizationNotDetermined && !isOnboarding,
                      shouldClearSettingsRedirect: false)
    }
    
    static func evaluateOnboardingDismissed(isTrackingAuthorizationNotDetermined: Bool,
                                            isHandlingSettingsRedirect: Bool) -> Result {
        Result(shouldRequestAuthorization: isTrackingAuthorizationNotDetermined && !isHandlingSettingsRedirect,
               shouldClearSettingsRedirect: false)
    }
}

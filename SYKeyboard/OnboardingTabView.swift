//
//  OnboardingTabView.swift
//  SYKeyboard
//
//  Created by 서동환 on 1/21/25.
//

import SwiftUI

struct InstructionsTabView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isOnboarding: Bool
    
    var body: some View {
        TabView {
            OnboardingPageView(title: "커서 이동 방법", imageName: "onboarding_moveCursor")
            
            OnboardingPageView(title: "반복 입력 방법", imageName: "onboarding_pressAndHold")
            
            OnboardingPageView(title: "한손 키보드 변경 방법", imageName: "onboarding_changeOneHand")
            
            OnboardingPageView(title: "숫자 자판 변경 방법", imageName: "onboarding_changeNumberView")
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        
        Button {
            dismiss()
        } label: {
            Text("닫기")
        }
    }
}

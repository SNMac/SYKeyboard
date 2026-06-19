//
//  View+Extension.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/4/24.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func requestReviewOnDetailSettingsReturn(isEnabled: Bool = true) -> some View {
        modifier(RequestReviewViewModifier(action: .requestAfterDetailSettingsReturn,
                                           isEnabled: isEnabled))
    }
}

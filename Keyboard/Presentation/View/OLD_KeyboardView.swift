//
//  OLD_KeyboardView.swift
//  Keyboard
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

struct OLD_KeyboardView: View {
    @EnvironmentObject private var state: KeyboardState
    @AppStorage("isNumericKeypadEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isNumericKeypadEnabled = true
    @AppStorage("isOneHandedKeyboardEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isOneHandedKeyboardEnabled = true
    @AppStorage("currentOneHandedKeyboard", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var currentOneHandedKeyboard = 1
    @AppStorage("reviewCounter", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) var reviewCounter = 0
    
    var body: some View {
        HStack(spacing: 0) {
            if state.currentUIKeyboardType != .numberPad && state.currentUIKeyboardType != .asciiCapableNumberPad
                && isOneHandedKeyboardEnabled && state.currentOneHandedKeyboard == .right {
                ChevronButton(isLeftHandMode: false)
            }
            ZStack(alignment: state.currentKeyboard == .symbol ? .leading : .trailing) {
                    switch state.currentKeyboard {
                    case .hangeul:
                        OLD_HangeulView()
                    case .symbol:
                        if state.currentUIKeyboardType == .URL {
                            URLSymbolView()
                        } else if state.currentUIKeyboardType == .emailAddress {
                            EmailSymbolView()
                        } else if state.currentUIKeyboardType == .webSearch {
                            WebSearchSymbolView()
                        } else {
                            SymbolView()
                        }
                    case .numeric:
                        if state.currentUIKeyboardType == .numberPad {
                            TenKeyView()
                        } else if state.currentUIKeyboardType == .asciiCapableNumberPad {
                            TenKeyView()
                        } else {
                            NumericView()
                        }
                    }
                
                if state.activeKeyboardSelectOverlay {
                    KeyboardSelectOverlayView()
                        .offset(x: state.currentKeyboard == .symbol ? 5 : -5, y: state.keyboardHeight / 8)
                }
                
                if state.activeOneHandedKeyboardSelectOverlay {
                    OneHandedKeyboardSelectOverlayView()
                        .offset(x: state.currentKeyboard == .symbol ? 5 : -5, y: state.keyboardHeight / 8)
                }
            }
            if state.currentUIKeyboardType != .numberPad && state.currentUIKeyboardType != .asciiCapableNumberPad
                && isOneHandedKeyboardEnabled && state.currentOneHandedKeyboard == .left {
                ChevronButton(isLeftHandMode: true)
            }
        }.onAppear {
            reviewCounter += 1
            
            if isOneHandedKeyboardEnabled {
                state.currentOneHandedKeyboard = OneHandedKeyboard(rawValue: currentOneHandedKeyboard) ?? .center
            } else {
                currentOneHandedKeyboard = 1
                state.currentOneHandedKeyboard = .center
            }
        }
    }
}

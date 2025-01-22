//
//  KeyboardView.swift
//  Keyboard
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

struct KeyboardView: View {
    @EnvironmentObject private var state: KeyboardState
    @AppStorage("isNumericKeyboardEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isNumericKeyboardEnabled = true
    @AppStorage("isOneHandKeyboardEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isOneHandKeyboardEnabled = true
    @AppStorage("currentOneHandKeyboard", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var currentOneHandKeyboard = 1
    @AppStorage("reviewCounter", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) var reviewCounter = 0
    
    var body: some View {
        HStack(spacing: 0) {
            if state.currentUIKeyboardType != .numberPad && state.currentUIKeyboardType != .asciiCapableNumberPad
                && isOneHandKeyboardEnabled && state.currentOneHandKeyboard == .right {
                ChevronButton(isLeftHandMode: false)
            }
            ZStack(alignment: state.currentKeyboard == .symbol ? .leading : .trailing) {
                    switch state.currentKeyboard {
                    case .hangeul:
                        HangeulView()
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
                
                if state.activeOneHandKeyboardSelectOverlay {
                    OneHandKeyboardSelectOverlayView()
                        .offset(x: state.currentKeyboard == .symbol ? 5 : -5, y: state.keyboardHeight / 8)
                }
            }
            if state.currentUIKeyboardType != .numberPad && state.currentUIKeyboardType != .asciiCapableNumberPad
                && isOneHandKeyboardEnabled && state.currentOneHandKeyboard == .left {
                ChevronButton(isLeftHandMode: true)
            }
        }.onAppear {
            reviewCounter += 1
            
            if isOneHandKeyboardEnabled {
                state.currentOneHandKeyboard = OneHandKeyboard(rawValue: currentOneHandKeyboard) ?? .center
            } else {
                currentOneHandKeyboard = 1
                state.currentOneHandKeyboard = .center
            }
        }
    }
}

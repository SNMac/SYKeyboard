//
//  NaratgeulView.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

struct NaratgeulView: View {
    @EnvironmentObject private var state: NaratgeulState
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isNumberKeyboardTypeEnabled = true
    @AppStorage("isOneHandModeEnabled", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var isOneHandModeEnabled = true
    @AppStorage("currentOneHandMode", store: UserDefaults(suiteName: GlobalValues.groupBundleID)) private var currentOneHandMode = 1
    
    var body: some View {
        HStack(spacing: 0) {
            if state.currentKeyboardType != .numberPad && state.currentKeyboardType != .asciiCapableNumberPad
                && isOneHandModeEnabled && state.currentOneHandMode == .right {
                ChevronButton(isLeftHandMode: false)
            }
            ZStack(alignment: state.currentInputType == .symbol ? .leading : .trailing) {
                    switch state.currentInputType {
                    case .hangeul:
                        HangeulView()
                    case .symbol:
                        if state.currentKeyboardType == .URL {
                            URLSymbolView()
                        } else if state.currentKeyboardType == .emailAddress {
                            EmailSymbolView()
                        } else if state.currentKeyboardType == .webSearch {
                            WebSearchSymbolView()
                        } else {
                            SymbolView()
                        }
                    case .number:
                        if state.currentKeyboardType == .numberPad {
                            NumberPadView()
                        } else if state.currentKeyboardType == .asciiCapableNumberPad {
                            NumberPadView()
                        } else {
                            NumberView()
                        }
                    }
                
                if state.activeInputTypeSelectOverlay {
                    InputTypeSelectOverlayView()
                        .offset(x: state.currentInputType == .symbol ? 5 : -5, y: state.keyboardHeight / 8)
                }
                
                if state.activeOneHandModeSelectOverlay {
                    OneHandModeSelectOverlayView()
                        .offset(x: state.currentInputType == .symbol ? 5 : -5, y: state.keyboardHeight / 8)
                }
            }
            if state.currentKeyboardType != .numberPad && state.currentKeyboardType != .asciiCapableNumberPad
                && isOneHandModeEnabled && state.currentOneHandMode == .left {
                ChevronButton(isLeftHandMode: true)
            }
        }.onAppear {
            if isOneHandModeEnabled {
                state.currentOneHandMode = OneHandMode(rawValue: currentOneHandMode) ?? .center
            } else {
                currentOneHandMode = 1
                state.currentOneHandMode = .center
            }
        }
    }
}

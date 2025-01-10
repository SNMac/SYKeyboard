//
//  NaratgeulView.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

struct NaratgeulView: View {
    @EnvironmentObject private var state: NaratgeulState
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    @AppStorage("currentOneHandType", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandType = 1
    
    var body: some View {
        HStack(spacing: 0) {
            if state.currentKeyboardType != .numberPad && state.currentKeyboardType != .asciiCapableNumberPad
                && isOneHandTypeEnabled && state.currentOneHandType == .right {
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
                
                if state.isSelectingInputType {
                    InputTypeSelectOverlayView()
                        .offset(x: state.currentInputType == .symbol ? 5 : -5, y: state.keyboardHeight / 8)
                }
                
                if state.isSelectingOneHandType {
                    OneHandSelectOverlayView()
                        .offset(x: state.currentInputType == .symbol ? 5 : -5, y: state.keyboardHeight / 8)
                }
            }
            if state.currentKeyboardType != .numberPad && state.currentKeyboardType != .asciiCapableNumberPad
                && isOneHandTypeEnabled && state.currentOneHandType == .left {
                ChevronButton(isLeftHandMode: true)
            }
        }.onAppear {
            if isOneHandTypeEnabled {
                state.currentOneHandType = OneHandType(rawValue: currentOneHandType) ?? .center
            } else {
                currentOneHandType = 1
                state.currentOneHandType = .center
            }
        }
    }
}

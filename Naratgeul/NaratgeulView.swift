//
//  NaratgeulView.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

struct NaratgeulView: View {
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    @AppStorage("currentOneHandType", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandType = 1
    
    var body: some View {
        ZStack(alignment: state.currentInputType == .symbol ? .leading : .trailing) {
            HStack(spacing: 0) {
                if isOneHandTypeEnabled && state.currentOneHandType == .right {
                    ChevronButton(isLeftHandMode: false)
                }
                if #available(iOS 18, *) {
                    switch state.currentInputType {
                    case .hangeul:
                        Swift6_HangeulView()
                    case .symbol:
                        if state.currentKeyboardType == .URL {
                            Swift6_URLSymbolView()
                        } else if state.currentKeyboardType == .emailAddress {
                            Swift6_EmailSymbolView()
                        } else if state.currentKeyboardType == .webSearch {
                            Swift6_WebSearchSymbolView()
                        } else {
                            Swift6_SymbolView()
                        }
                    case .number:
                        if state.currentKeyboardType == .numberPad {
                            Swift6_NumberPadView()
                        } else {
                            Swift6_NumberView()
                        }
                    }
                } else {
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
                }
                if isOneHandTypeEnabled && state.currentOneHandType == .left {
                    ChevronButton(isLeftHandMode: true)
                }
            }
            
            if state.isSelectingOneHandType {
                OneHandSelectOverlayView()
                    .offset(x: state.currentInputType == .symbol ? 2.5 : -2.5, y: state.keyboardHeight / 8)
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

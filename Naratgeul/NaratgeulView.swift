//
//  NaratgeulView.swift
//  Naratgeul
//
//  Created by 서동환 on 8/14/24.
//

import SwiftUI

struct NaratgeulView: View {
    @EnvironmentObject var state: NaratgeulState
    @EnvironmentObject var autocomplete: TopAutocomplete
    @AppStorage("isNumberKeyboardTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isNumberKeyboardTypeEnabled = true
    @AppStorage("isAutocompleteEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isAutocompleteEnabled = false
    
    var body: some View {
        VStack(spacing: 0) {
//            if isAutocompleteEnabled {
//                HStack {
//                    AutocompleteButton(
//                        text: autocomplete.list.count >= 1 ? autocomplete.list[0] : "",
//                        action: {
//                            if autocomplete.list.count >= 1 {
//                                autocomplete.action(autocomplete.list[0])
//                            }
//                        })
//                    Divider()
//                        .frame(width: 5, height: 25)
//                    AutocompleteButton(
//                        text: autocomplete.list.count >= 2 ? autocomplete.list[1] : "",
//                        action: {
//                            if autocomplete.list.count >= 2 {
//                                autocomplete.action(autocomplete.list[1])
//                            }
//                        })
//                    Divider()
//                        .frame(width: 5, height: 25)
//                    AutocompleteButton(
//                        text: autocomplete.list.count >= 3 ? autocomplete.list[2] : "",
//                        action: {
//                            if autocomplete.list.count >= 3 {
//                                autocomplete.action(autocomplete.list[2])
//                            }
//                        })
//                }
//                .frame(height: 50, alignment: .center)
//            }
            
            ZStack {
                if #available(iOS 18, *) {
                    switch state.currentInputType {
                    case .hangeul:
                        if state.currentKeyboardType == .twitter {
                            Swift6_TwitterHangeulView()
                        } else {
                            Swift6_HangeulView()
                        }
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
                        if state.currentKeyboardType == .twitter {
                            TwitterHangeulView()
                        } else {
                            HangeulView()
                        }
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
                
                if isNumberKeyboardTypeEnabled && state.isSelectingInputType {
                    NaratgeulInputTypeSelectView()
                }
            }
        }
    }
}

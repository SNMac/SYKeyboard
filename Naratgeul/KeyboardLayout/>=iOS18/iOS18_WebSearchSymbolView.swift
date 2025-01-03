//
//  iOS18_WebSearchSymbolView.swift
//  Naratgeul
//
//  Created by 서동환 on 9/27/24.
//

import SwiftUI
import Combine

struct iOS18_WebSearchSymbolView: View {
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("isAutoChangeToHangeulEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isAutoChangeToHangeulEnabled = true
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    @State var timer: AnyCancellable?
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 4.5
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 2.5
    
    let symbols = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "/", ":", ";", "(", ")", "₩", "&", "@", "“", ".", ",", "?", "!", "’"],
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "=", "_", "\\", "|", "~", "<", ">", "$", "£", "¥", "•", ".", ",", "?", "!", "’"]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - 1st row of Symbol Keyboard
                HStack(spacing: 0) {
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][0], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][0])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][0])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][1], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][1])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][1])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][2], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][2])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][2])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][3], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][3])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][3])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][4], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][4])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][4])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][5], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][5])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][5])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][6], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][6])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][6])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][7], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][7])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][7])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][8], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][8])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][8])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][9], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][9])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][9])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - 2nd row of Symbol Keyboard
                HStack(spacing: 0) {
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][10], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][10])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][10])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][11], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][11])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][11])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][12], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][12])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][12])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][13], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][13])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][13])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][14], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][14])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][14])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][15], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][15])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][15])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][16], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][16])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][16])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][17], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][17])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][17])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][18], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][18])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][18])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][19], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][19])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][19])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - 3rd row of Symbol Keyboard
                HStack(spacing: 0) {
                    iOS18_NaratgeulButton(
                        text: "\(state.nowSymbolPage + 1)/\(state.totalSymbolPage)", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.nowSymbolPage = (state.nowSymbolPage + 1) % state.totalSymbolPage
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][20], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][20])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][20])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][21], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][21])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][21])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][22], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][22])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][22])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][23], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][23])
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][23])
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: symbols[state.nowSymbolPage][24], primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][24])
                            if isAutoChangeToHangeulEnabled {
                                state.currentInputType = .hangeul
                            }
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: symbols[state.nowSymbolPage][24])
                            if isAutoChangeToHangeulEnabled {
                                state.currentInputType = .hangeul
                            } else {
                                timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                    .autoconnect()
                                    .sink { _ in
                                        Feedback.shared.playTypingSound()
                                        Feedback.shared.playHaptic(style: .light)
                                        state.delegate?.inputLastSymbol()
                                    }
                            }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        systemName: "delete.left", primary: false,
                        onPress: {
                            Feedback.shared.playDeleteSound()
                            Feedback.shared.playHaptic(style: .light)
                            let _ = state.delegate?.removeKeypadTap(isLongPress: false)
                        },
                        onLongPress: {
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    if let isDeleted = state.delegate?.removeKeypadTap(isLongPress: true) {
                                        if isDeleted {
                                            Feedback.shared.playDeleteSound()
                                            Feedback.shared.playHaptic(style: .light)
                                        }
                                    }
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - (한글, 􀆪), 􁁺, ., 􁂆
                HStack(spacing: 0) {
                    if state.needsInputModeSwitchKey {
                        HStack(spacing: 0) {
                            iOS18_NaratgeulButton(
                                text: "한글", primary: false,
                                onPress: {
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptic(style: .light)
                                },
                                onRelease: {
                                    state.currentInputType = .hangeul
                                },
                                onLongPress: {
                                    if isOneHandTypeEnabled {
                                        state.selectedOneHandType = state.currentOneHandType
                                        state.isSelectingOneHandType = true
                                        Feedback.shared.playHaptic(style: .light)
                                    }
                                },
                                onLongPressRelease: {
                                    if !state.isSelectingOneHandType {
                                        state.currentInputType = .hangeul
                                    }
                                })
                            .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                            .contentShape(Rectangle())
                            
                            NextKeyboardButton(
                                systemName: "globe",
                                action: state.nextKeyboardAction
                            )
                            .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                            .contentShape(Rectangle())
                        }
                    } else {
                        iOS18_NaratgeulButton(
                            text: "한글", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.currentInputType = .hangeul
                            },
                            onLongPress: {
                                if isOneHandTypeEnabled {
                                    state.selectedOneHandType = state.currentOneHandType
                                    state.isSelectingOneHandType = true
                                    Feedback.shared.playHaptic(style: .light)
                                }
                            },
                            onLongPressRelease: {
                                if !state.isSelectingOneHandType {
                                    state.currentInputType = .hangeul
                                }
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                    }
                    
                    iOS18_NaratgeulButton(
                        systemName: "space", primary: true,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.spaceKeypadTap()
                        },
                        onLongPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.spaceKeypadTap()
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.spaceKeypadTap()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .frame(width: geometry.size.width / 2)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        text: ".", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.otherKeypadTap(letter: ".")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Feedback.shared.playHaptic(style: .light)
                            state.delegate?.otherKeypadTap(letter: ".")
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressRelease: {
                            timer?.cancel()
                        })
                    .frame(width: geometry.size.width / 4 / 3)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    iOS18_NaratgeulButton(
                        systemName: "return.left", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.enterKeypadTap()
                        },
                        onLongPressRelease: {
                            state.delegate?.enterKeypadTap()
                        })
                    .frame(width: geometry.size.width / 4 / 3 * 2)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
        }.onAppear {
            state.nowSymbolPage = 0
            state.totalSymbolPage = symbols.count
        }
        .frame(width: state.currentOneHandType == .center ? nil : state.oneHandWidth, height: state.keyboardHeight)
        .background(Color.white.opacity(0.001))
    }
}

//
//  Swift6_HangeulView.swift
//  Naratgeul
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI
import Combine

struct Swift6_HangeulView: View {
    @EnvironmentObject var state: NaratgeulState
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    @AppStorage("currentOneHandType", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var currentOneHandType = 1
    @State var timer: AnyCancellable?
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 2
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
            HStack(spacing: 0) {
                Swift6_NaratgeulButton(
                    text: "ㄱ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㄱ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㄱ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
                    text: "ㄴ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㄴ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㄴ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
                    text: "ㅏㅓ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㅏ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㅏ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
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
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                .contentShape(Rectangle())
            }
            
            // MARK: - ㄹ, ㅁ, ㅗㅜ, 􁁺
            HStack(spacing: 0) {
                Swift6_NaratgeulButton(
                    text: "ㄹ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㄹ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㄹ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
                    text: "ㅁ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㅁ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㅁ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
                    text: "ㅗㅜ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㅗ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㅗ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
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
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                .contentShape(Rectangle())
            }
            
            // MARK: - ㅅ, ㅇ, ㅣ, 􁂆
            HStack(spacing: 0) {
                Swift6_NaratgeulButton(
                    text: "ㅅ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㅅ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㅅ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
                    text: "ㅇ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㅇ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㅇ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
                    text: "ㅣ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㅣ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㅣ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                if state.currentKeyboardType == .twitter {
                    HStack(spacing: 0) {
                        Swift6_NaratgeulButton(
                            text: "@_twitter", primary: true,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.delegate?.otherKeypadTap(letter: "@")
                            },
                            onLongPressRelease: {
                                state.delegate?.otherKeypadTap(letter: "@")
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        Swift6_NaratgeulButton(
                            text: "#_twitter", primary: true,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.delegate?.otherKeypadTap(letter: "#")
                            },
                            onLongPressRelease: {
                                state.delegate?.otherKeypadTap(letter: "#")
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                } else {
                    Swift6_NaratgeulButton(
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
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
            
            // MARK: - 획, ㅡ, 쌍, (!#1, 􀆪)
            HStack(spacing: 0) {
                Swift6_NaratgeulButton(
                    text: "획", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hoegKeypadTap()
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hoegKeypadTap()
                        if state.isHoegSsangAvailable {
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastHangeul()
                                }
                        }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
                    text: "ㅡ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.hangulKeypadTap(letter: "ㅡ")
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.hangulKeypadTap(letter: "ㅡ")
                        timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                                state.delegate?.inputLastHangeul()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                Swift6_NaratgeulButton(
                    text: "쌍", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onRelease: {
                        state.delegate?.ssangKeypadTap()
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        state.delegate?.ssangKeypadTap()
                        if state.isHoegSsangAvailable {
                            timer = Timer.publish(every: state.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Feedback.shared.playHaptic(style: .light)
                                    state.delegate?.inputLastHangeul()
                                }
                        }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                if state.needsInputModeSwitchKey {
                    HStack(spacing: 0) {
                        Swift6_NaratgeulButton(
                            text: "!#1", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.currentInputType = .symbol
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
                                    state.currentInputType = .symbol
                                }
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        NextKeyboardButton(
                            systemName: "globe",
                            action: state.nextKeyboardAction
                        )
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                } else {
                    Swift6_NaratgeulButton(
                        text: "!#1", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.currentInputType = .symbol
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
                                state.currentInputType = .symbol
                            }
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(height: state.keyboardHeight)
        .background(Color.white.opacity(0.001))
    }
}

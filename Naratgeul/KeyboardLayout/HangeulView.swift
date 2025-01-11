//
//  HangeulView.swift
//  Naratgeul
//
//  Created by 서동환 on 7/29/24.
//

import SwiftUI
import Combine

struct HangeulView: View {
    @EnvironmentObject private var state: NaratgeulState
    @State private var timer: AnyCancellable?
    
    private let vPadding: CGFloat = 4
    private let interItemVPadding: CGFloat = 2
    private let hPadding: CGFloat = 4
    private let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
            HStack(spacing: 0) {
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                        NaratgeulButton(
                            text: "@_twitter", primary: true,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.delegate?.otherKeypadTap(letter: "@")
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        NaratgeulButton(
                            text: "#_twitter", primary: true,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.delegate?.otherKeypadTap(letter: "#")
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                } else {
                    NaratgeulButton(
                        systemName: "return.left", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.delegate?.enterKeypadTap()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
            
            // MARK: - 획, ㅡ, 쌍, (!#1, 􀆪)
            HStack(spacing: 0) {
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                
                NaratgeulButton(
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
                        NaratgeulButton(
                            text: "!#1", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                state.currentInputType = .symbol
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
                    NaratgeulButton(
                        text: "!#1", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        },
                        onRelease: {
                            state.currentInputType = .symbol
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: state.currentOneHandMode == .center ? nil : state.oneHandWidth, height: state.keyboardHeight)
        .background(Color.white.opacity(0.001))
    }
}

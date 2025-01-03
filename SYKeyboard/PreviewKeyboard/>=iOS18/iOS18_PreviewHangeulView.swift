//
//  iOS18_PreviewHangeulView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI
import Combine

struct iOS18_PreviewHangeulView: View {
    @EnvironmentObject var state: PreviewNaratgeulState
    @AppStorage("isOneHandTypeEnabled", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var isOneHandTypeEnabled = true
    @AppStorage("repeatTimerSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var repeatTimerSpeed = GlobalValues.defaultRepeatTimerSpeed
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = true
    @Binding var keyboardHeight: Double
    @Binding var oneHandWidth: Double
    @State var timer: AnyCancellable?
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 2
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        let repeatTimerCycle = 0.10 - repeatTimerSpeed
        
        VStack(spacing: 0) {
            // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
            HStack(spacing: 0) {
                iOS18_PreviewNaratgeulButton(
                    text: "ㄱ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    text: "ㄴ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    text: "ㅏㅓ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    systemName: "delete.left", primary: false,
                    onPress: {
                        Feedback.shared.playDeleteSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playDeleteSound()
                                Feedback.shared.playHaptic(style: .light)
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
                iOS18_PreviewNaratgeulButton(
                    text: "ㄹ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    text: "ㅁ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    text: "ㅗㅜ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    systemName: "space", primary: true,
                    onPress: {
                        Feedback.shared.playModifierSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playModifierSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
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
                iOS18_PreviewNaratgeulButton(
                    text: "ㅅ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    text: "ㅇ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    text: "ㅣ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    systemName: "return.left", primary: false,
                    onPress: {
                        Feedback.shared.playModifierSound()
                        Feedback.shared.playHaptic(style: .light)
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                .contentShape(Rectangle())
            }
            
            // MARK: - 획, ㅡ, 쌍, (!#1, 􀆪)
            HStack(spacing: 0) {
                iOS18_PreviewNaratgeulButton(
                    text: "획", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    text: "ㅡ", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                iOS18_PreviewNaratgeulButton(
                    text: "쌍", primary: true,
                    onPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                    },
                    onLongPress: {
                        Feedback.shared.playTypingSound()
                        Feedback.shared.playHaptic(style: .light)
                        timer = Timer.publish(every: repeatTimerCycle, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                Feedback.shared.playTypingSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                if needsInputModeSwitchKey {
                    HStack(spacing: 0) {
                        iOS18_PreviewNaratgeulButton(
                            text: "!#1", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        iOS18_PreviewNaratgeulButton(
                            systemName: "globe", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            }
                        )
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                } else {
                    iOS18_PreviewNaratgeulButton(
                        text: "!#1", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: state.currentOneHandType == .center ? nil : oneHandWidth, height: keyboardHeight)
        .background(Color("KeyboardBackground"))
        .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
    }
}

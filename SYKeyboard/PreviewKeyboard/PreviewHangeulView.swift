//
//  PreviewHangeulView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/16/24.
//

import SwiftUI
import Combine

struct PreviewHangeulView: View {
    @EnvironmentObject private var state: PreviewKeyboardState
    @AppStorage(UserDefaultsKeys.repeatRate, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) private var repeatRate = DefaultValues.repeatRate
    @AppStorage(UserDefaultsKeys.needsInputModeSwitchKey, store: UserDefaults(suiteName: DefaultValues.groupBundleID)) private var needsInputModeSwitchKey = DefaultValues.needsInputModeSwitchKey
    
    @Binding var keyboardHeight: Double
    @Binding var oneHandedKeyboardWidth: Double
    
    @State private var timer: AnyCancellable?
    
    private let vPadding: CGFloat = 4
    private let interItemVPadding: CGFloat = 2
    private let hPadding: CGFloat = 4
    private let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        let repeatTimerInterval = 0.10 - repeatRate
        
        VStack(spacing: 0) {
            
            // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
            
            HStack(spacing: 0) {
                PreviewKeyboardButton(
                    text: "ㄱ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                
                PreviewKeyboardButton(
                    text: "ㄴ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    text: "ㅏㅓ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    systemName: "delete.left", primary: false,
                    onPress: {
                        FeedbackManager.shared.playDeleteSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playDeleteSound()
                                FeedbackManager.shared.playHaptic()
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
                PreviewKeyboardButton(
                    text: "ㄹ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    text: "ㅁ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    text: "ㅗㅜ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    systemName: "space", primary: true,
                    onPress: {
                        FeedbackManager.shared.playModifierSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playModifierSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playModifierSound()
                                FeedbackManager.shared.playHaptic()
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
                PreviewKeyboardButton(
                    text: "ㅅ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    text: "ㅇ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    text: "ㅣ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    systemName: "return.left", primary: false,
                    onPress: {
                        FeedbackManager.shared.playModifierSound()
                        FeedbackManager.shared.playHaptic()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                .contentShape(Rectangle())
            }
            
            // MARK: - 획, ㅡ, 쌍, (!#1, 􀆪)
            
            HStack(spacing: 0) {
                PreviewKeyboardButton(
                    text: "획", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    text: "ㅡ", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                PreviewKeyboardButton(
                    text: "쌍", primary: true,
                    onPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                    },
                    onLongPress: {
                        FeedbackManager.shared.playKeyTypingSound()
                        FeedbackManager.shared.playHaptic()
                        timer = Timer.publish(every: repeatTimerInterval, on: .main, in: .common)
                            .autoconnect()
                            .sink { _ in
                                FeedbackManager.shared.playKeyTypingSound()
                                FeedbackManager.shared.playHaptic()
                            }
                    },
                    onLongPressRelease: {
                        timer?.cancel()
                    })
                .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                .contentShape(Rectangle())
                
                if needsInputModeSwitchKey {
                    HStack(spacing: 0) {
                        PreviewKeyboardButton(
                            text: "!#1", primary: false,
                            onPress: {
                                FeedbackManager.shared.playModifierSound()
                                FeedbackManager.shared.playHaptic()
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                        
                        PreviewKeyboardButton(
                            systemName: "globe", primary: false,
                            onPress: {
                                FeedbackManager.shared.playModifierSound()
                                FeedbackManager.shared.playHaptic()
                            }
                        )
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                } else {
                    PreviewKeyboardButton(
                        text: "!#1", primary: false,
                        onPress: {
                            FeedbackManager.shared.playModifierSound()
                            FeedbackManager.shared.playHaptic()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: state.currentOneHandedKeyboard == .center ? nil : oneHandedKeyboardWidth, height: keyboardHeight)
        .background(Color("KeyboardBackground"))
        .padding(.bottom, needsInputModeSwitchKey ? 0 : 40)
    }
}

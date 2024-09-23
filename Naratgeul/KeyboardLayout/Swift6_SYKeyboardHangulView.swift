//
//  Swift6_SYKeyboardHangulView.swift
//  Naratgeul
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI
import Combine

struct Swift6_SYKeyboardHangeulView: View {
    @EnvironmentObject var options: SYKeyboardOptions
    @State var timer: AnyCancellable?
    private var defaults: UserDefaults?
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 2
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 2.5
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - ㄱ, ㄴ, ㅏㅓ, 􀆛
                HStack(spacing: 0) {
                    Swift6_SYKeyboardButton(
                        text: "ㄱ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㄱ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㄱ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        text: "ㄴ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㄴ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㄴ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        text: "ㅏㅓ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅏ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㅏ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        systemName: "delete.left", primary: false,
                        onPress: {
                            Feedback.shared.playDeleteSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            let _ = options.delegate?.removeKeypadTap(isLongPress: false)
                        },
                        onLongPress: {
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    if let isDeleted = options.delegate?.removeKeypadTap(isLongPress: true) {
                                        if isDeleted {
                                            Feedback.shared.playDeleteSound()
                                            Task {
                                                await Feedback.shared.triggerFeedback()
                                            }
                                        }
                                    }
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                
                // MARK: - ㄹ, ㅁ, ㅗㅜ, 􁁺
                HStack(spacing: 0) {
                    Swift6_SYKeyboardButton(
                        text: "ㄹ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㄹ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㄹ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        text: "ㅁ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅁ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㅁ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        text: "ㅗㅜ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅗ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㅗ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        systemName: "space", primary: true,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.spaceKeypadTap()
                        },
                        onLongPress: {
                            Feedback.shared.playModifierSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.spaceKeypadTap()
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playModifierSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastSymbol()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - ㅅ, ㅇ, ㅣ, 􁂆
                HStack(spacing: 0) {
                    Swift6_SYKeyboardButton(
                        text: "ㅅ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅅ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㅅ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        text: "ㅇ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅇ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㅇ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        text: "ㅣ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅣ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㅣ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        systemName: "return.left", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.enterKeypadTap()
                        },
                        onLongPressFinished: {
                            options.delegate?.enterKeypadTap()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - 획, ㅡ, 쌍, (123, 􀆪)
                HStack(spacing: 0) {
                    Swift6_SYKeyboardButton(
                        text: "획", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hoegKeypadTap()
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hoegKeypadTap()
                            if options.isHoegSsangAvailable {
                                timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                    .autoconnect()
                                    .sink { _ in
                                        Feedback.shared.playTypingSound()
                                        Task {
                                            await Feedback.shared.triggerFeedback()
                                        }
                                        options.delegate?.inputLastHangeul()
                                    }
                            }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        text: "ㅡ", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.hangulKeypadTap(letter: "ㅡ")
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.hangulKeypadTap(letter: "ㅡ")
                            timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                .autoconnect()
                                .sink { _ in
                                    Feedback.shared.playTypingSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                    options.delegate?.inputLastHangeul()
                                }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_SYKeyboardButton(
                        text: "쌍", primary: true,
                        onPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                        },
                        onRelease: {
                            options.delegate?.ssangKeypadTap()
                        },
                        onLongPress: {
                            Feedback.shared.playTypingSound()
                            Task {
                                await Feedback.shared.triggerFeedback()
                            }
                            options.delegate?.ssangKeypadTap()
                            if options.isHoegSsangAvailable {
                                timer = Timer.publish(every: options.repeatTimerCycle, on: .main, in: .common)
                                    .autoconnect()
                                    .sink { _ in
                                        Feedback.shared.playTypingSound()
                                        Task {
                                            await Feedback.shared.triggerFeedback()
                                        }
                                        options.delegate?.inputLastHangeul()
                                    }
                            }
                        },
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    if options.needsInputModeSwitchKey {
                        HStack(spacing: 0) {
                            Swift6_SYKeyboardButton(
                                text: "123", primary: false,
                                onPress: {
                                    Feedback.shared.playModifierSound()
                                    Task {
                                        await Feedback.shared.triggerFeedback()
                                    }
                                },
                                onRelease: {
                                    options.current = .number
                                })
                            .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                            .contentShape(Rectangle())
                            
                            NextKeyboardButton(
                                systemName: "globe",
                                action: options.nextKeyboardAction
                            )
                            .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                            .contentShape(Rectangle())
                        }
                    } else {
                        Swift6_SYKeyboardButton(
                            text: "123", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Task {
                                    await Feedback.shared.triggerFeedback()
                                }
                            },
                            onRelease: {
                                options.current = .number
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        .frame(height: options.keyboardHeight)
        .background(Color("KeyboardBackground"))
    }
}

//
//  Swift6_PreviewSymbolView.swift
//  SYKeyboard
//
//  Created by 서동환 on 9/23/24.
//

import SwiftUI
import Combine

struct Swift6_PreviewSymbolView: View {
    @EnvironmentObject var options: PreviewNaratgeulOptions
    @AppStorage("repeatTimerSpeed", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var repeatTimerSpeed = 0.06
    @AppStorage("keyboardHeight", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var keyboardHeight = 240.0
    @AppStorage("needsInputModeSwitchKey", store: UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")) private var needsInputModeSwitchKey = false
    @Binding var tempKeyboardHeight: Double
    @State var timer: AnyCancellable?
    @State var isShiftTapped: Bool = false
    @State var isShiftReleased: Bool = true
    
    let vPadding: CGFloat = 4
    let interItemVPadding: CGFloat = 4.5
    let hPadding: CGFloat = 4
    let interItemHPadding: CGFloat = 2.5
    
    let symbols = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "/", ":", ";", "(", ")", "₩", "&", "@", "“"],
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "=", "_", "\\", "|", "~", "<", ">", "$", "£", "¥", "•"]
    ]
    let fixedSymbols = [".", ",", "?", "!", "’"]
    
    var body: some View {
        let repeatTimerCycle = 0.10 - repeatTimerSpeed
        
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - symbols[0]
                HStack(spacing: 0) {
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][0], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][1], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][2], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][3], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][4], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][5], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][6], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][7], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][8], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][9], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: vPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - symbols[1]
                HStack(spacing: 0) {
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][10], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][11], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][12], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][13], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][14], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][15], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][16], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][17], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][18], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: symbols[options.nowSymbolPage][19], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - (options.curSymbolPage + 1)/options.totalSymbolPage, symbols.last, 􀆛
                HStack(spacing: 0) {
                    Swift6_PreviewNaratgeulButton(
                        text: "\(options.nowSymbolPage + 1)/\(options.totalSymbolPage)", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                            options.nowSymbolPage = (options.nowSymbolPage + 1) % options.totalSymbolPage
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: fixedSymbols[0], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: fixedSymbols[1], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: fixedSymbols[2], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: fixedSymbols[3], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        text: fixedSymbols[4], primary: true,
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: interItemVPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
                
                // MARK: - (한글, 􀆪), 􁁺, 􁂆
                HStack(spacing: 0) {
                    if needsInputModeSwitchKey {
                        HStack(spacing: 0) {
                            Swift6_PreviewNaratgeulButton(
                                text: "한글", primary: false,
                                onPress: {
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptic(style: .light)
                                },
                                onRelease: {
                                    options.current = .hangeul
                                },
                                onLongPressFinished: {
                                    options.current = .hangeul
                                })
                            .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                            .contentShape(Rectangle())
                            
                            Swift6_PreviewNaratgeulButton(
                                systemName: "globe", primary: false,
                                onPress: {
                                    Feedback.shared.playModifierSound()
                                    Feedback.shared.playHaptic(style: .light)
                                }
                            )
                            .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                            .contentShape(Rectangle())
                        }
                    } else {
                        Swift6_PreviewNaratgeulButton(
                            text: "한글", primary: false,
                            onPress: {
                                Feedback.shared.playModifierSound()
                                Feedback.shared.playHaptic(style: .light)
                            },
                            onRelease: {
                                options.current = .hangeul
                            },
                            onLongPressFinished: {
                                options.current = .hangeul
                            })
                        .padding(EdgeInsets(top: interItemVPadding, leading: hPadding, bottom: vPadding, trailing: interItemHPadding))
                        .contentShape(Rectangle())
                    }
                    
                    Swift6_PreviewNaratgeulButton(
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
                        onLongPressFinished: {
                            timer?.cancel()
                        })
                    .frame(width: geometry.size.width / 2)
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: interItemHPadding))
                    .contentShape(Rectangle())
                    
                    Swift6_PreviewNaratgeulButton(
                        systemName: "return.left", primary: false,
                        onPress: {
                            Feedback.shared.playModifierSound()
                            Feedback.shared.playHaptic(style: .light)
                        })
                    .padding(EdgeInsets(top: interItemVPadding, leading: interItemHPadding, bottom: vPadding, trailing: hPadding))
                    .contentShape(Rectangle())
                }
            }
        }.onAppear {
            options.totalSymbolPage = symbols.count
        }
        .frame(height: tempKeyboardHeight)
        .background(Color("KeyboardBackground"))
        .padding(EdgeInsets(top: 0, leading: 0, bottom: (needsInputModeSwitchKey ? 0 : 40), trailing: 0))
    }
}

//
//  Feedback.swift
//  Naratgeul
//
//  Created by Sunghyun Cho on 2023-01-21.
//  Edited by 서동환 on 8/7/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - Feedback.swift
//

import AVFoundation
import UIKit

final class Feedback {
    static let shared = Feedback()
    
    var defaults: UserDefaults?
    
    let lightHapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    init() {
        defaults = UserDefaults(suiteName: "group.github.com-SNMac.SYKeyboard")
    }
    
    var sounds: Bool {
        return defaults?.bool(forKey: "isSoundFeedbackEnabled") ?? true
    }
    
    var haptics: Bool {
        return defaults?.bool(forKey: "isHapticFeedbackEnabled") ?? true
    }
    
    func prepareHaptics() {
        if !haptics { return }
        lightHapticGenerator.prepare()
    }
    
    func playHaptics() {
        if !haptics { return }
        lightHapticGenerator.impactOccurred()
    }
    
    func playTypingSound() {
        if !sounds { return }
        let systemSoundID: SystemSoundID = 1104
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    func playDeleteSound() {
        if !sounds { return }
        let systemSoundID: SystemSoundID = 1155
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    func playModifierSound() {
        if !sounds { return }
        let systemSoundID: SystemSoundID = 1156
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

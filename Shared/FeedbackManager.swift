//
//  FeedbackManager.swift
//  SYKeyboard, Keyboard
//
//  Created by Sunghyun Cho on 1/21/23.
//  Edited by 서동환 on 8/7/24.
//  - Downloaded from https://github.com/anaclumos/sky-earth-human - Feedback.swift
//

import UIKit
import AVFoundation

/// 햅틱, 사운드 피드백을 관리하는 싱글톤 매니저
final class FeedbackManager {
    
    // MARK: - Properties
    
    /// 햅틱 ON/OFF 여부
    var haptic: Bool {
        let defaults = UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)
        return defaults?.bool(forKey: UserDefaultsKeys.isHapticFeedbackEnabled) ?? true
    }
    
    /// 사운드 ON/OFF 여부
    var sounds: Bool {
        let defaults = UserDefaults(suiteName: UserDefaultsManager.shared.groupBundleID)
        return defaults?.bool(forKey: UserDefaultsKeys.isSoundFeedbackEnabled) ?? true
    }
    
    /// 햅틱 피드백 생성기
    let generator = UIImpactFeedbackGenerator(style: .light)
    /// 키 입력 버튼 사운드
    let keySoundID: SystemSoundID = 1104
    /// 삭제 버튼 사운드
    let deleteSoundID: SystemSoundID = 1155
    /// 스페이스, 리턴, 자판/키보드 변경 버튼 사운드
    let modifierSoundID: SystemSoundID = 1156
    
    // MARK: - Initializer
    
    static let shared = FeedbackManager()
    private init() {}
    
    // MARK: - Methods
    
    /// 탭틱 엔진 준비
    func prepareHaptic() {
        generator.prepare()
    }
    
    /// 햅틱 피드백 강제 재생
    func playHapticByForce(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        if style != .light {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
            generator.prepare()
        } else {
            generator.impactOccurred()
            generator.prepare()
        }
    }
    
    /// 햅틱 피드백 재생
    func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        if haptic {
            if style != .light {
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
                generator.prepare()
            } else {
                generator.impactOccurred()
                generator.prepare()
            }
        }
    }
    
    /// 키 입력 버튼 사운드 재생
    func playTypingSound() {
        if sounds { AudioServicesPlaySystemSound(keySoundID) }
    }
    
    /// 삭제 버튼 사운드 재생
    func playDeleteSound() {
        if sounds { AudioServicesPlaySystemSound(deleteSoundID) }
    }
    
    /// 스페이스, 리턴, 자판/키보드 변경 버튼 사운드 재생
    func playModifierSound() {
        if sounds { AudioServicesPlaySystemSound(modifierSoundID) }
    }
}

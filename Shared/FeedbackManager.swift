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
    
    // MARK: - Singleton Initializer
    
    static let shared = FeedbackManager()
    private init() {}
    
    // MARK: - Properties
    
    /// 햅틱 피드백 생성기
    private let generator = UIImpactFeedbackGenerator(style: .light)
    /// 키 입력 버튼 사운드
    private let keySoundID: SystemSoundID = 1104
    /// 삭제 버튼 사운드
    private let deleteSoundID: SystemSoundID = 1155
    /// 스페이스, 리턴, 키보드 변경 버튼 사운드
    private let modifierSoundID: SystemSoundID = 1156
    
    // MARK: - Haptic Feedback Methods
    
    /// 탭틱 엔진 준비
    func prepareHaptic() {
        generator.prepare()
    }
    
    /// 햅틱 피드백 재생
    func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        if style != .light {
            let tempGenerator = UIImpactFeedbackGenerator(style: style)
            tempGenerator.impactOccurred()
            tempGenerator.prepare()
        } else {
            generator.impactOccurred()
            generator.prepare()
        }
    }
    
    // MARK: - Sound Feedback Methods
    
    /// 키 입력 버튼 사운드 재생
    func playTypingSound() {
        AudioServicesPlaySystemSound(keySoundID)
    }
    
    /// 삭제 버튼 사운드 재생
    func playDeleteSound() {
        AudioServicesPlaySystemSound(deleteSoundID)
    }
    
    /// 스페이스, 리턴, 키보드 변경 버튼 사운드 재생
    func playModifierSound() {
        AudioServicesPlaySystemSound(modifierSoundID)
    }
}

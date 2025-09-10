//
//  FeedbackManager.swift
//  SYKeyboard, HangeulKeyboard, EnglishKeyboard
//
//  Created by 서동환 on 7/16/25.
//

import UIKit
import AVFoundation
import OSLog

/// 햅틱, 사운드 피드백을 관리하는 싱글톤 매니저
final class FeedbackManager {
    
    // MARK: - Singleton Initializer
    
    static let shared = FeedbackManager()
    private init() {}
    
    // MARK: - Properties
    private lazy var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: self))
    
    /// 햅틱 피드백 생성기
    private let generator = UIImpactFeedbackGenerator(style: .light)
    /// 키 입력 버튼 사운드
    private let keyTypingSoundID: SystemSoundID = 1104
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
    func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light, isForcing: Bool = false) {
        if UserDefaultsManager.shared.isHapticFeedbackEnabled || isForcing {
            if style != .light {
                let tempGenerator = UIImpactFeedbackGenerator(style: style)
                tempGenerator.impactOccurred()
                tempGenerator.prepare()
                logger.debug("커스텀 햅틱 피드백 재생")
            } else {
                generator.impactOccurred()
                generator.prepare()
                logger.debug("light 햅틱 피드백 재생")
            }
        }
    }
    
    // MARK: - Sound Feedback Methods
    
    /// 키 입력 사운드 재생
    func playKeyTypingSound() {
        if UserDefaultsManager.shared.isSoundFeedbackEnabled {
            AudioServicesPlaySystemSound(keyTypingSoundID)
            logger.debug("키 입력 사운드 재생")
        }
    }
    
    /// 삭제 사운드 재생
    func playDeleteSound() {
        if UserDefaultsManager.shared.isSoundFeedbackEnabled {
            AudioServicesPlaySystemSound(deleteSoundID)
            logger.debug("삭제 사운드 재생")
        }
    }
    
    /// 모디파이어 사운드 재생
    func playModifierSound() {
        if UserDefaultsManager.shared.isSoundFeedbackEnabled {
            AudioServicesPlaySystemSound(modifierSoundID)
            logger.debug("모디파이어 사운드 재생")
        }
    }
}

//
//  BannerAdLayoutPolicy.swift
//  SYKeyboard
//
//  Created by Codex on 6/19/26.
//

import Foundation

enum BannerAdLayoutPolicy {

    // MARK: - Properties

    /// 화면 폭이 바뀐 뒤 배너 광고 크기를 다시 정하기까지 기다리는 시간.
    /// 회전할 때 중간 폭과 최종 폭은 약 10ms 간격으로 온다(iPhone 13 mini 시뮬레이터).
    /// iPhone Duo를 접고 펼 때는 간격이 더 길어 요청이 두 번 나갈 수 있지만, 마지막 요청의 크기를 받는다
    static let adSizeSettleDelay: Duration = .milliseconds(300)
    
    // MARK: - Internal Methods
    
    static func containerHeight(adHeight: CGFloat, isAdReceived: Bool) -> CGFloat {
        isAdReceived ? adHeight : 0
    }
}

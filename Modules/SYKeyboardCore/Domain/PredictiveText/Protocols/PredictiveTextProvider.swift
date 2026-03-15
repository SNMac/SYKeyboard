//
//  PredictiveTextProvider.swift
//  SYKeyboardCore
//
//  Created by 서동환 on 3/11/26.
//

/// 자동완성 후보 단어를 제공하는 서비스 프로토콜
///
/// 입력 컨텍스트를 기반으로 예측 후보를 반환하고,
/// 사용자가 선택한 단어를 학습하는 기능을 정의합니다.
protocol PredictiveTextProvider: AnyObject {
    /// 현재 입력 컨텍스트를 기반으로 자동완성 후보를 반환합니다.
    ///
    /// - Parameter baseText: 자동완성을 제공할 텍스트
    /// - Returns: 자동완성 후보 단어 배열
    func suggestions(for baseText: String) -> [String]
    /// 사용자가 선택한 단어를 학습하여 이후 추천에 반영합니다.
    ///
    /// - Parameter word: 학습할 단어
    func learn(word: String)
}

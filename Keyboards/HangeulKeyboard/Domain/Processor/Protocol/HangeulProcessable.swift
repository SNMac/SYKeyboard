//
//  HangeulProcessable.swift
//  HangeulKeyboard
//
//  Created by 서동환 on 11/21/25.
//

/// 한글 입력기 프로토콜
protocol HangeulProcessable {
    /// 한글 입력을 처리합니다.
    /// - Parameters:
    ///   - 글자Input: 새로 입력된 글자 (`String` 타입)
    ///   - beforeText: 입력 전의 전체 문자열
    /// - Returns: (처리된 전체 텍스트, 반복 입력을 위한 실제 입력 글자)
    func input(글자Input: String, beforeText: String) -> (processedText: String, input글자: String?)
    /// 마지막 글자를 지우거나 분해합니다.
    /// - Parameters:
    ///   - beforeText: 삭제 전의 전체 문자열
    func delete(beforeText: String) -> String
}

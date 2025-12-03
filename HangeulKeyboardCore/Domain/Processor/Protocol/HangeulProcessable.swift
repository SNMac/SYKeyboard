//
//  HangeulProcessable.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 11/21/25.
//

/// 스페이스바 입력 시 동작 결과
enum SpaceInputResult {
    case insertSpace     // 실제 공백 텍스트(" ")를 입력
    case commitCombination // 조합을 끊고 대기 (입력 없음)
}

/// 한글 입력기 프로토콜
protocol HangeulProcessable: AnyObject {
    /// 현재 한글 조합이 진행 중인지 여부
    /// - `true`: 조합 중 (예: 천지인에서 '화살표' 버튼 표시)
    /// - `false`: 조합 대기/완료 (예: 천지인에서 '스페이스' 버튼 표시)
    var is한글조합OnGoing: Bool { get }
    
    /// 한글 입력을 처리합니다.
    /// - Parameters:
    ///   - 글자Input: 새로 입력된 글자 (`String` 타입)
    ///   - beforeText: 입력 전의 전체 문자열
    /// - Returns: (처리된 전체 텍스트, 반복 입력을 위한 실제 입력 글자)
    func input(글자Input: String, beforeText: String) -> (processedText: String, input글자: String?)
    /// 스페이스바 입력을 처리합니다.
    func inputSpace(beforeText: String) -> SpaceInputResult
    /// 리턴 버튼 입력을 처리합니다.
    func inputReturn()
    /// 마지막 글자를 지우거나 분해합니다.
    /// - Parameters:
    ///   - beforeText: 삭제 전의 전체 문자열
    func delete(beforeText: String) -> String
    /// 한글 조합 상태를 리셋합니다.
    func reset한글조합()
}

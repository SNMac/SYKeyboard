//
//  HangeulProcessable.swift
//  HangeulKeyboardCore
//
//  Created by 서동환 on 11/21/25.
//

/// 오토마타/프로세서의 처리 결과
///
/// 입력, 삭제 등의 결과를 **확정(committed)**과 **조합 중(composing)**으로 분리하여 반환합니다.
///
/// - 예: "간" + "ㅏ" → `committed`: "가", `composing`: "나" (연음)
/// - 예: "가" + "ㄴ" → `committed`: "", `composing`: "간" (종성 추가)
struct CompositionResult {
    /// 조합이 확정되어 더 이상 변경되지 않는 문자열.
    /// ViewController의 `committedBuffer`에 추가됩니다.
    let committed: String
    
    /// 현재 오토마타가 조합 중인 문자열 (최대 1~2글자).
    /// ViewController의 `composingBuffer`를 이 값으로 교체합니다.
    let composing: String
    
    /// 반복 입력(long press)을 위한 실제 입력 글자.
    /// `nil`이면 반복 입력이 불가능합니다.
    let input글자: String?
    
    /// 편의 생성자: `committed` 없이 `composing`만 있는 경우
    static func composingOnly(_ composing: String, input글자: String? = nil) -> CompositionResult {
        CompositionResult(committed: "", composing: composing, input글자: input글자)
    }
    
    /// 편의 생성자: 조합 없이 그대로 확정되는 경우
    static func commitAll(_ text: String, input글자: String? = nil) -> CompositionResult {
        CompositionResult(committed: text, composing: "", input글자: input글자)
    }
}

/// 스페이스바 입력 시 동작 결과
enum SpaceInputResult {
    case insertSpace        // 실제 공백 텍스트(" ")를 입력
    case commitCombination  // 조합을 끊고 대기 (입력 없음)
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
    ///   - composing: 현재 조합 중인 문자열 (최대 1~2글자)
    /// - Returns: 확정/조합 분리된 결과
    func input(글자Input: String, composing: String) -> CompositionResult
    
    /// 스페이스바 입력을 처리합니다.
    /// - Parameter composing: 현재 조합 중인 문자열
    func inputSpace(composing: String) -> SpaceInputResult
    
    /// 마지막 글자를 지우거나 분해합니다.
    /// - Parameter composing: 현재 조합 중인 문자열
    /// - Returns: 삭제 후 남은 조합 문자열
    func delete(composing: String) -> String
    
    /// 한글 조합 상태를 리셋합니다.
    func reset한글조합()
}

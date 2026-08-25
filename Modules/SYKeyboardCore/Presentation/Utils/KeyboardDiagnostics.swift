//
//  KeyboardDiagnostics.swift
//  SYKeyboardCore
//
//  Created by Claude on 8/19/26.
//

import Foundation

/// 크래시 리포트에 남길 진단 기록
///
/// 키보드 확장은 비밀번호와 메시지를 포함한 사용자의 모든 입력을 볼 수 있다.
/// 따라서 이 경로로는 **입력한 텍스트, 그 일부, 정확한 길이를 절대 기록하지 않는다.**
/// 사용자 조작의 흐름과 상태 전이만 남긴다.
///
/// `SYKeyboardCore`는 Firebase에 의존하지 않으므로, 각 확장 타깃이
/// `record`에 실제 리포터를 연결한다.
public enum KeyboardDiagnostics {

    /// 확장 타깃에서 Crashlytics 같은 리포터로 연결한다
    public static var record: ((String) -> Void)?

    static func log(_ message: String) {
        record?(message)
    }

    /// 반복 횟수를 대략적인 구간 문자열로 바꾼다.
    ///
    /// 반복 삭제 tick 수는 지운 글자 수와 거의 같으므로 그대로 남기면
    /// 사용자가 입력한 길이가 기록된다. 폭주 여부만 알 수 있도록 구간으로 줄인다.
    static func bucket(_ count: Int) -> String {
        switch count {
        case ..<0: return "invalid"
        case 0: return "0"
        case 1..<10: return "1-9"
        case 10..<50: return "10-49"
        case 50..<200: return "50-199"
        default: return "200+"
        }
    }
}

//
//  KeyboardSentTextDetectionPolicy.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/28/26.
//

import UIKit

/// 앱의 전송 버튼으로 입력창이 비었는지 판정하는 정책
///
/// 키보드 확장은 전송 버튼을 알 수 없으므로 `textWillChange` 직후 첫 `textDidChange`의 상태로 추정한다.
/// 입력창을 옮기거나 키보드를 내릴 때도 문맥이 모두 비므로, 같은 입력창(`documentIdentifier`)인지 함께 본다.
/// 검색창은 지우기(X) 버튼으로 비워도 같은 모양이라 리턴 키가 검색인 입력창은 제외한다.
/// 호스트 실행 취소나 앱이 초안을 지우는 경우는 구분할 수 없다
enum KeyboardSentTextDetectionPolicy {

    static func isSentAfterTextChange(
        documentIdentifierBeforeChange: UUID?,
        documentIdentifierAfterChange: UUID?,
        beforeInput: String?,
        afterInput: String?,
        selectedText: String?,
        returnKeyType: UIReturnKeyType?
    ) -> Bool {
        guard returnKeyType != .search,
              let documentIdentifierBeforeChange,
              documentIdentifierBeforeChange == documentIdentifierAfterChange else { return false }

        return isEmpty(beforeInput) && isEmpty(afterInput) && isEmpty(selectedText)
    }
}

private extension KeyboardSentTextDetectionPolicy {
    static func isEmpty(_ text: String?) -> Bool {
        return text?.isEmpty ?? true
    }
}

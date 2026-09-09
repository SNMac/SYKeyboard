//
//  ClipboardHistoryPasteboardSynchronizer.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/9/26.
//

import UIKit

/// 시스템 pasteboard의 최신 텍스트를 클립보드 기록에 반영한다. 키보드 extension과 앱이 함께 쓴다
///
/// `changeCount`와 `hasStrings`·타입 확인은 iOS 16 붙여넣기 권한 알림을 띄우지 않고, `.string` 읽기만 띄울 수 있다.
/// 설정 ON·Full Access·미리보기 여부 확인은 호출 측 책임이다.
public enum ClipboardHistoryPasteboardSynchronizer {

    /// 비밀번호 관리자가 비밀 항목에 붙이는 pasteboard 타입. 이 타입이 있으면 기록하지 않는다
    public static let concealedPasteboardType = "org.nspasteboard.ConcealedType"

    /// pasteboard의 `changeCount`가 마지막 확인값과 다를 때만 텍스트를 읽어 `store`에 기록한다
    public static func synchronizeIfNeeded(
        store: ClipboardHistoryStore,
        pasteboard: UIPasteboard = .general,
        settings: UserDefaultsManager = .shared
    ) {
        let changeCount = pasteboard.changeCount
        guard changeCount != settings.lastSeenPasteboardChangeCount else { return }
        // 읽기 실패나 저장 제외여도 같은 값을 반복해 읽지 않도록 먼저 갱신한다
        settings.lastSeenPasteboardChangeCount = changeCount

        guard pasteboard.hasStrings,
              !pasteboard.contains(pasteboardTypes: [concealedPasteboardType]),
              let text = pasteboard.string else { return }
        store.record(text)
    }
}

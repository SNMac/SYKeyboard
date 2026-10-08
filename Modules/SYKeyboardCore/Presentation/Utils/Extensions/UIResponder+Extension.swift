//
//  UIResponder+Extension.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit

extension UIResponder {
    /// extension은 `UIApplication`을 직접 쓸 수 없으므로 responder chain을 따라 올라가 연다.
    /// 브라우저나 앱이 열리면 호스트 앱을 떠나므로 키보드는 시스템이 내린다
    func openURLThroughResponderChain(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url)
                return
            }
            responder = responder?.next
        }
    }
}

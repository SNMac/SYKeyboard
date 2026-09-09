//
//  LazyView.swift
//  SYKeyboard
//
//  Created by Claude on 9/10/26.
//

import SwiftUI

/// 목적지 뷰 생성을 실제로 표시될 때까지 미룬다.
///
/// iOS 16 방식 `NavigationLink(_:destination:)`는 링크를 누르기 전에도 목적지 값을 만들어,
/// 목적지의 `init`이 부모 body가 평가될 때마다 실행된다. 저장소를 읽는 `init`처럼 비용이 있는 목적지에 쓴다
struct LazyView<Content: View>: View {
    private let build: () -> Content

    init(_ build: @escaping @autoclosure () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

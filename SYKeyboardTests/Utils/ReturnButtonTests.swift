//
//  ReturnButtonTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/14/26.
//

import Testing
import UIKit

import SYKeyboardAssets

@testable import SYKeyboardCore

@Suite("리턴 버튼 표시 상태 검증")
@MainActor
struct ReturnButtonTests {

    @Test("기본 리턴 이미지는 비활성 tint를 적용할 수 있는 template 이미지")
    func test기본리턴이미지_TemplateRendering() {
        let button = ReturnButton(keyboard: .dubeolsik)

        button.update(for: .default)

        #expect(button.primaryKeyListImageView.image?.renderingMode == .alwaysTemplate)
    }

    @Test("비활성화 후 활성화하면 기본 리턴 이미지 tint가 활성 색상으로 복원")
    func test기본리턴이미지_활성색상복원() {
        let button = ReturnButton(keyboard: .dubeolsik)
        button.update(for: .default)

        button.updateEnabled(false)
        #expect(button.primaryKeyListImageView.tintColor == .returnButtonDisabledLabel)

        button.updateEnabled(true)
        button.updateConfiguration()

        #expect(button.primaryKeyListImageView.tintColor == .label)
    }
}

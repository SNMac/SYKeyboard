//
//  CursorDragOverlayTests.swift
//  SYKeyboardTests
//
//  Created by Codex on 6/22/26.
//

import Testing
import UIKit

@testable import SYKeyboardCore

@Suite("커서 드래그 overlay 검증")
@MainActor
struct CursorDragOverlayTests {

    @Test("indicator effect는 OS별 regular 효과를 반환")
    func testIndicatorEffect_regular효과() {
        let effect = CursorDragIndicatorEffectFactory.effect()

        if #available(iOS 26.0, *) {
            #expect(effect is UIGlassEffect)
        } else {
            #expect(effect is UIBlurEffect)
        }
    }

    @Test("indicator symbol은 character cursor ibeam을 사용")
    func testIndicatorSymbol_characterCursorIbeam() {
        #expect(CursorDragIndicatorSymbolFactory.symbolName == "character.cursor.ibeam")
    }

    @Test("indicator symbol image는 구형 OS에서도 비어 있지 않음")
    func testIndicatorSymbolImage_존재() {
        #expect(CursorDragIndicatorSymbolFactory.image() != nil)
    }

    @Test("indicator는 아이콘에 vibrancy effect를 적용")
    func testIndicator_아이콘VibrancyEffect적용() {
        let view = CursorDragIndicatorView()

        #expect(view.containsVisualEffect(of: UIVibrancyEffect.self))
    }
}

private extension UIView {
    func containsVisualEffect<T: UIVisualEffect>(of effectType: T.Type) -> Bool {
        if let visualEffectView = self as? UIVisualEffectView,
           visualEffectView.effect is T {
            return true
        }

        return subviews.contains {
            $0.containsVisualEffect(of: effectType)
        }
    }
}

import Testing
import CoreFoundation

@testable import SYKeyboardCore

@Suite("자동완성 highlight 정책 검증")
struct SuggestionHighlightPolicyTests {

    @Test("preview는 해당 후보만 강조")
    func testPreviewSuggestion() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(state.highlightedSuggestionIndex == 1)
        #expect(state.highlightedActionIndex == nil)
    }

    @Test("후보 touch는 preview를 일시 대체하고 touch 종료 시 preview가 복원")
    func testSuggestionTouchOverridesPreview() {
        let touched = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: 2,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )
        let restored = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(touched.highlightedSuggestionIndex == 2)
        #expect(restored.highlightedSuggestionIndex == 1)
    }

    @Test("action touch는 preview를 가리고 action만 강조")
    func testActionTouchOverridesPreview() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 1,
            touchedSuggestionIndex: nil,
            touchedActionIndex: 0,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(state.highlightedSuggestionIndex == nil)
        #expect(state.highlightedActionIndex == 0)
    }

    @Test("nil과 범위 밖 index는 강조하지 않음")
    func testNilAndOutOfRangeIndexes() {
        let nilState = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: nil,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 2
        )
        let invalidState = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 3,
            touchedSuggestionIndex: -1,
            touchedActionIndex: 2,
            suggestionCount: 3,
            actionCount: 2
        )

        #expect(nilState == .none)
        #expect(invalidState == .none)
    }

    @Test("후보가 10개면 9번 후보도 하이라이트 대상")
    func test후보가10개면_9번후보도_하이라이트대상() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: nil,
            touchedSuggestionIndex: 9,
            touchedActionIndex: nil,
            suggestionCount: 10,
            actionCount: 3
        )

        #expect(state == .init(highlightedSuggestionIndex: 9, highlightedActionIndex: nil))
    }

    @Test("후보 수가 줄면 범위를 벗어난 preview 하이라이트는 무시")
    func test후보수가줄면_범위를벗어난preview하이라이트는무시() {
        let state = SuggestionHighlightPolicy.resolve(
            previewSuggestionIndex: 9,
            touchedSuggestionIndex: nil,
            touchedActionIndex: nil,
            suggestionCount: 3,
            actionCount: 3
        )

        #expect(state == .none)
    }
}

@Suite("후보 스크롤 가장자리 페이드 판정 검증")
struct SuggestionScrollFadePolicyTests {

    @Test("내용이 뷰포트를 넘지 않으면 양쪽 모두 페이드 없음")
    func test내용이뷰포트를넘지않으면_양쪽모두페이드없음() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 0,
            viewportWidth: 300,
            contentWidth: 300
        )

        #expect(state == .none)
    }

    @Test("맨 왼쪽이면 오른쪽만 페이드")
    func test맨왼쪽이면_오른쪽만페이드() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 0,
            viewportWidth: 300,
            contentWidth: 900
        )

        #expect(state == .init(showsLeadingFade: false, showsTrailingFade: true))
    }

    @Test("가운데면 양쪽 페이드")
    func test가운데면_양쪽페이드() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 300,
            viewportWidth: 300,
            contentWidth: 900
        )

        #expect(state == .init(showsLeadingFade: true, showsTrailingFade: true))
    }

    @Test("맨 오른쪽이면 왼쪽만 페이드")
    func test맨오른쪽이면_왼쪽만페이드() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 600,
            viewportWidth: 300,
            contentWidth: 900
        )

        #expect(state == .init(showsLeadingFade: true, showsTrailingFade: false))
    }

    @Test("1pt 미만 차이는 페이드를 켜지 않음")
    func test1pt미만차이는_페이드를켜지않음() {
        let state = SuggestionScrollFadePolicy.resolve(
            contentOffsetX: 0.2,
            viewportWidth: 300,
            contentWidth: 300.3
        )

        #expect(state == .none)
    }
}

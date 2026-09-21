import Testing
import CoreFoundation

@testable import SYKeyboardCore

@Suite("자동완성 divider 개수 정책 검증")
struct SuggestionDividerPolicyTests {

    @Test("후보가 열 격자를 채우지 못해도 divider는 3칸 격자를 따름")
    func test후보가열격자를채우지못해도_divider는3칸격자를따름() {
        // 빈 칸에 divider가 없으면 그 자리를 눌렀을 때 앞 후보가 적용될 것처럼 보인다
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 0) == 2)
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 1) == 2)
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 2) == 2)
    }

    @Test("후보가 열 격자를 채우면 후보 사이에만 divider를 둠")
    func test후보가열격자를채우면_후보사이에만divider를둠() {
        // 맨 앞과 맨 뒤에는 divider를 두지 않는다
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 3) == 2)
        #expect(SuggestionDividerPolicy.dividerCount(forSuggestionCount: 10) == 9)
    }
}

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

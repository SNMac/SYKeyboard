//
//  ClipboardHistoryPanelViewTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/8/26.
//

import CoreGraphics
import ImageIO
import UIKit
import Testing
import UniformTypeIdentifiers

@testable import SYKeyboardCore

@Suite("클립보드 기록 패널 편집 동작 검증")
@MainActor
struct ClipboardHistoryPanelViewTests {

    @Test("행 탭은 해당 인덱스의 붙여넣기를 요청")
    func test행탭은_인덱스전달() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        #expect(spy.selectedIndices == [1])
    }

    @Test("편집 모드에서 행 탭은 선택만 하고 붙여넣기를 요청하지 않음")
    func test편집모드행탭은_붙여넣기요청없음() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        #expect(panel.tableView.isEditing)
        #expect(spy.selectedIndices.isEmpty)
    }

    @Test("편집 모드에서 전체 선택 후 삭제하면 전체 삭제를 요청")
    func test전체선택후삭제는_전체삭제요청() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.toggleSelectAll()
        panel.deleteSelectedItems()

        #expect(spy.deleteAllCount == 1)
        #expect(spy.deletedIndices.isEmpty)
    }

    @Test("편집 모드에서 일부 선택 후 삭제하면 선택 인덱스만 오름차순으로 요청")
    func test일부선택후삭제는_선택인덱스만요청() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.tableView.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .none)
        panel.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        panel.deleteSelectedItems()

        #expect(spy.deletedIndices == [[0, 2]])
        #expect(spy.deleteAllCount == 0)
    }

    @Test("편집 모드에서 미고정만 삭제하면 요청한 뒤 편집 모드를 끝냄")
    func test편집모드삭제후_편집모드종료() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.beginItemEditing()
        panel.tableView.selectRow(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: .none)
        panel.deleteSelectedItems()

        #expect(spy.deletedIndices == [[1]])
        #expect(panel.isItemEditing == false)
    }

    @Test("편집 모드에서 고정 항목이 섞인 삭제는 확인 전에는 편집 모드를 유지하고 확인하면 끝냄")
    func test고정포함편집삭제는_확인후편집모드종료() {
        let (panel, spy) = makePanel(items: [pinned("p"), unpinned("a"), unpinned("b")])

        panel.beginItemEditing()
        panel.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        panel.tableView.selectRow(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: .none)
        panel.deleteSelectedItems()

        #expect(spy.deletedIndices.isEmpty)
        #expect(panel.isItemEditing)

        panel.confirmPendingDeletion()

        #expect(spy.deletedIndices == [[0, 1]])
        #expect(panel.isItemEditing == false)
    }

    @Test("편집 모드 고정 버튼은 선택한 항목 id로 고정을 요청하고 편집 모드를 끝냄")
    func test편집모드고정은_선택id요청후편집모드종료() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])
        let expectedIDs: Set<String> = [panel.items[0].id, panel.items[2].id]

        panel.beginItemEditing()
        panel.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        panel.tableView.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .none)
        panel.togglePinsOfSelectedItems()

        #expect(spy.toggledPinIDs == [expectedIDs])
        #expect(panel.isItemEditing == false)
    }

    @Test("편집 모드에서 선택이 없으면 고정을 요청하지 않고 편집 모드를 유지")
    func test선택없으면_고정요청없음() {
        let (panel, spy) = makePanel(texts: ["a", "b"])

        panel.beginItemEditing()
        panel.togglePinsOfSelectedItems()

        #expect(spy.toggledPinIDs.isEmpty)
        #expect(panel.isItemEditing)
    }

    @Test("고정 항목이 섞인 삭제는 확인 전에는 요청하지 않고, 확인하면 요청")
    func test고정포함삭제는_확인후요청() {
        let (panel, spy) = makePanel(items: [pinned("p"), unpinned("a")])

        panel.requestDelete(at: [0, 1], deleteAll: true)
        #expect(spy.deleteAllCount == 0)
        #expect(spy.deletedIndices.isEmpty)

        panel.confirmPendingDeletion()
        #expect(spy.deleteAllCount == 1)
    }

    @Test("고정 항목이 섞인 삭제를 취소하면 요청하지 않고 다시 확인해도 없음")
    func test고정포함삭제_취소하면_요청없음() {
        let (panel, spy) = makePanel(items: [pinned("p"), unpinned("a")])

        panel.requestDelete(at: [0], deleteAll: false)
        panel.cancelPendingDeletion()
        panel.confirmPendingDeletion()

        #expect(spy.deletedIndices.isEmpty)
        #expect(spy.deleteAllCount == 0)
    }

    @Test("trailing swipe 삭제는 미고정 행이면 수행하고, 고정 행이면 확인 대기로 미수행을 알림")
    func testTrailingSwipe삭제는_고정행이면_미수행() {
        let (panel, spy) = makePanel(items: [pinned("p"), unpinned("a")])
        var performed: [Bool] = []

        for row in 0..<2 {
            let actions = panel.tableView(panel.tableView, trailingSwipeActionsConfigurationForRowAt: IndexPath(row: row, section: 0))
            let action = try! #require(actions?.actions.first)
            action.handler(action, UIView()) { performed.append($0) }
        }

        #expect(performed == [false, true])
        #expect(spy.deletedIndices == [[1]])
    }

    @Test("스와이프로 tableView가 편집 상태여도 configure 뒤 편집 모드로 들어가지 않음")
    func test스와이프중configure는_편집모드로바뀌지않음() {
        let (panel, spy) = makePanel(texts: ["a", "b"])

        // UIKit은 스와이프 액션이 열려 있는 동안 tableView.isEditing을 true로 둔다
        panel.tableView.setEditing(true, animated: false)
        panel.configure(state: .items([unpinned("a")]))
        panel.deleteSelectedItems()

        #expect(panel.isItemEditing == false)
        #expect(spy.deletedIndices.isEmpty)
    }

    @Test("손가락 없이 걸린 행 눌림은 선택이 이어지지 않으면 다음 runloop에 해제")
    func test손가락없이걸린눌림은_다음runloop에해제() async throws {
        let (panel, _) = makePanel(texts: ["a", "b"])
        let window = UIWindow(frame: panel.frame)
        window.addSubview(panel)
        panel.layoutIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = try #require(panel.tableView.cellForRow(at: indexPath))
        cell.setHighlighted(true, animated: false)

        panel.tableView(panel.tableView, didHighlightRowAt: indexPath)
        await drainMainQueue()

        #expect(cell.isHighlighted == false)
    }

    @Test("편집 모드에서는 손가락 없이 걸린 눌림도 정리하지 않음")
    func test편집모드는_눌림정리안함() async throws {
        let (panel, _) = makePanel(texts: ["a", "b"])
        let window = UIWindow(frame: panel.frame)
        window.addSubview(panel)
        panel.layoutIfNeeded()
        let indexPath = IndexPath(row: 1, section: 0)
        let cell = try #require(panel.tableView.cellForRow(at: indexPath))

        panel.beginItemEditing()
        cell.setHighlighted(true, animated: false)
        panel.tableView(panel.tableView, didHighlightRowAt: indexPath)
        await drainMainQueue()

        #expect(cell.isHighlighted)
    }

    @Test("기본 configure는 열린 상세를 닫음")
    func test기본configure는_상세를닫음() {
        let items = [unpinned("a"), unpinned("b")]
        let (panel, spy) = makePanel(items: items)

        panel.showDetail(at: 1)
        panel.configure(state: .items(items))
        panel.pasteDetailItem()

        #expect(spy.selectedIndices.isEmpty)
    }

    @Test("상세를 유지하는 갱신에서 앞에 새 항목이 들어오면 붙여넣기는 보던 항목의 새 인덱스를 요청")
    func test상세유지갱신후_붙여넣기는보던항목() {
        let items = [unpinned("a"), unpinned("b")]
        let (panel, spy) = makePanel(items: items)

        panel.showDetail(at: 1)
        panel.configure(state: .items([unpinned("new")] + items), keepsDetail: true)

        panel.pasteDetailItem()
        #expect(spy.selectedIndices == [2])
    }

    @Test("상세를 유지하는 갱신에서 보던 항목이 다시 기록돼 앞으로 오면 고정은 그 항목을 요청")
    func test같은내용이다시기록되면_고정은그항목() {
        let (panel, spy) = makePanel(items: [unpinned("a"), unpinned("b")])

        panel.showDetail(at: 1)
        panel.configure(state: .items([unpinned("b"), unpinned("a")]), keepsDetail: true)

        panel.toggleDetailItemPin()
        #expect(spy.toggledPinIndices == [0])
    }

    @Test("상세를 유지하는 갱신이어도 보던 항목이 사라지면 상세를 닫고 요청하지 않음")
    func test보던항목이사라지면_상세를닫음() {
        let (panel, spy) = makePanel(items: [unpinned("a"), unpinned("b")])

        panel.showDetail(at: 1)
        panel.configure(state: .items([unpinned("a")]), keepsDetail: true)
        panel.pasteDetailItem()

        #expect(spy.selectedIndices.isEmpty)
    }

    @Test("선택이 없으면 삭제를 요청하지 않음")
    func test선택없으면_삭제요청없음() {
        let (panel, spy) = makePanel(texts: ["a"])

        panel.beginItemEditing()
        panel.deleteSelectedItems()

        #expect(spy.deletedIndices.isEmpty)
        #expect(spy.deleteAllCount == 0)
    }

    @Test("항목이 없으면 편집 모드로 들어가지 않음")
    func test항목없으면_편집모드진입없음() {
        let (panel, _) = makePanel(texts: [])

        panel.beginItemEditing()

        #expect(panel.isItemEditing == false)
    }

    @Test("leading swipe는 고정 여부와 무관하게 고정 토글 액션 하나를 제공")
    func testLeadingSwipe는_고정토글액션제공() {
        let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        panel.configure(state: .items([
            ClipboardHistoryItem(text: "p", createdAt: Date(), pinnedAt: Date()),
            ClipboardHistoryItem(text: "a", createdAt: Date())
        ]))
        panel.layoutIfNeeded()

        let pinnedActions = panel.tableView(panel.tableView, leadingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0))
        let unpinnedActions = panel.tableView(panel.tableView, leadingSwipeActionsConfigurationForRowAt: IndexPath(row: 1, section: 0))

        #expect(pinnedActions?.actions.count == 1)
        #expect(unpinnedActions?.actions.count == 1)
    }

    @Test("고정 한도가 차면 미고정 행에는 leading swipe가 없고 고정 행에는 있음")
    func test고정한도차면_미고정행은_leadingSwipe없음() {
        let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let pinned = (0..<ClipboardHistoryPolicy.maxPinnedCount).map {
            ClipboardHistoryItem(text: "p\($0)", createdAt: Date(), pinnedAt: Date(timeIntervalSince1970: TimeInterval($0)))
        }
        panel.configure(state: .items(pinned + [ClipboardHistoryItem(text: "a", createdAt: Date())]))
        panel.layoutIfNeeded()

        let pinnedActions = panel.tableView(panel.tableView, leadingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0))
        let unpinnedActions = panel.tableView(panel.tableView, leadingSwipeActionsConfigurationForRowAt: IndexPath(row: pinned.count, section: 0))

        #expect(pinnedActions?.actions.count == 1)
        #expect(unpinnedActions == nil)
    }

    @Test("다시 configure하면 남은 행 수와 인덱스가 새 목록을 따름")
    func test다시configure하면_행수와인덱스가새목록기준() {
        let (panel, spy) = makePanel(texts: ["a", "b", "c"])

        panel.configure(state: .items(["b", "c"].map { ClipboardHistoryItem(text: $0, createdAt: Date()) }))
        panel.layoutIfNeeded()
        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))

        #expect(panel.tableView.numberOfRows(inSection: 0) == 2)
        #expect(spy.selectedIndices == [0])
        #expect(panel.items[0].text == "b")
    }

    @Test("resetPresentation은 편집 모드를 해제")
    func testResetPresentation은_편집모드해제() {
        let (panel, _) = makePanel(texts: ["a"])
        panel.beginItemEditing()
        #expect(panel.isItemEditing)

        panel.resetPresentation()

        // tableView.isEditing은 resetPresentation이 무조건 끄므로 편집 모드 해제를 구분하지 못한다
        #expect(panel.isItemEditing == false)
        #expect(panel.tableView.isEditing == false)
    }

    @Test("이미지 행을 탭하면 텍스트 행과 같은 델리게이트로 인덱스를 전달")
    func test이미지행탭은_인덱스전달() {
        let (panel, spy) = makePanel(items: [unpinned("a"), imageItem("h1")])

        panel.tableView(panel.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        #expect(spy.selectedIndices == [1])
        #expect(panel.tableView.numberOfRows(inSection: 0) == 2)
    }

    @Test("안내 토스트는 제목을 바꾸지 않고 떠서 configure에도 유지되며 resetPresentation에서 숨겨짐")
    func test안내토스트_표시와_숨김() {
        let (panel, _) = makePanel(items: [imageItem("h1")])
        let title = panel.titleLabel.text

        panel.showTransientMessage("copied")
        #expect(panel.isTransientMessageVisible)
        #expect(panel.transientMessageText == "copied")
        #expect(panel.titleLabel.text == title)

        panel.configure(state: .items([imageItem("h1")]))
        #expect(panel.isTransientMessageVisible)

        panel.resetPresentation()
        #expect(panel.isTransientMessageVisible == false)
    }

    @Test("표시 중에 안내 토스트를 다시 띄우면 문구만 바뀌고 계속 보임")
    func test안내토스트_재표시() {
        let (panel, _) = makePanel(items: [imageItem("h1")])

        panel.showTransientMessage("first")
        panel.showTransientMessage("second")

        #expect(panel.isTransientMessageVisible)
        #expect(panel.transientMessageText == "second")
    }

    @Test("편집 모드에서도 안내 토스트가 뜸")
    func test편집모드에서도_안내토스트() {
        let (panel, _) = makePanel(items: [imageItem("h1")])

        panel.beginItemEditing()
        panel.showTransientMessage("copied")

        #expect(panel.isTransientMessageVisible)
        #expect(panel.isItemEditing)
    }

    @Test("텍스트·이미지가 섞인 목록에서 일부를 지우고 다시 configure해도 행 수가 새 목록을 따름")
    func test혼합목록_삭제후configure() {
        let (panel, spy) = makePanel(items: [unpinned("a"), imageItem("h1"), unpinned("b")])

        panel.requestDelete(at: [1], deleteAll: false)
        panel.configure(state: .items([unpinned("a"), unpinned("b")]))
        panel.layoutIfNeeded()

        #expect(spy.deletedIndices == [[1]])
        #expect(panel.tableView.numberOfRows(inSection: 0) == 2)
        #expect(panel.items.map(\.id) == ["a", "b"])
    }

    // 썸네일로 대체됐는지는 공개된 관찰점이 없어 확인하지 못한다. 예산이 0이어도 상세가 열리는 것까지만 검증한다
    @Test("디코드 예산이 0이어도 상세 미리보기는 열림")
    func test디코드예산0에서도_상세미리보기열림() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-panel-preview", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let imageStore = ClipboardImageStore(directoryURL: directoryURL)
        let reference = try makeStoredImageReference(in: imageStore)

        let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let spy = ClipboardHistoryPanelDelegateSpy()
        panel.delegate = spy
        panel.imageStore = imageStore
        panel.configure(state: .items([ClipboardHistoryItem(content: .image(reference), createdAt: Date())]))
        panel.layoutIfNeeded()
        panel.decodeMemoryBudget = 0

        panel.showDetail(at: 0)
        panel.toggleDetailItemPin()

        #expect(spy.toggledPinIndices == [0])
    }
}

@MainActor
private func makePanel(texts: [String]) -> (ClipboardHistoryPanelView, ClipboardHistoryPanelDelegateSpy) {
    makePanel(items: texts.map(unpinned))
}

@MainActor
private func makePanel(items: [ClipboardHistoryItem]) -> (ClipboardHistoryPanelView, ClipboardHistoryPanelDelegateSpy) {
    let panel = ClipboardHistoryPanelView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    let spy = ClipboardHistoryPanelDelegateSpy()
    panel.delegate = spy
    panel.configure(state: items.isEmpty ? .empty : .items(items))
    panel.layoutIfNeeded()
    return (panel, spy)
}

/// 패널이 `DispatchQueue.main.async`로 예약한 작업이 끝날 때까지 기다린다
@MainActor
private func drainMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async { continuation.resume() }
    }
}

private func unpinned(_ text: String) -> ClipboardHistoryItem {
    ClipboardHistoryItem(text: text, createdAt: Date())
}

private func pinned(_ text: String) -> ClipboardHistoryItem {
    ClipboardHistoryItem(text: text, createdAt: Date(), pinnedAt: Date())
}

/// 단색 PNG를 ImageIO로 인코드해 `imageStore`에 실제로 저장하고 참조를 돌려준다
private func makeStoredImageReference(in imageStore: ClipboardImageStore) throws -> ClipboardImageReference {
    let context = try #require(CGContext(
        data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    context.setFillColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    let image = try #require(context.makeImage())
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).png")
    let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    #expect(CGImageDestinationFinalize(destination))
    return try #require(imageStore.store(temporaryFileURL: url, typeIdentifier: "public.png"))
}

private func imageItem(_ hash: String) -> ClipboardHistoryItem {
    ClipboardHistoryItem(
        content: .image(ClipboardImageReference(hash: hash, typeIdentifier: "public.png", byteSize: 1_024, pixelWidth: 8, pixelHeight: 8)),
        createdAt: Date()
    )
}

@MainActor
private final class ClipboardHistoryPanelDelegateSpy: ClipboardHistoryPanelDelegate {
    private(set) var selectedIndices: [Int] = []
    private(set) var deletedIndices: [[Int]] = []
    private(set) var deleteAllCount = 0
    private(set) var toggledPinIndices: [Int] = []
    private(set) var toggledPinIDs: [Set<String>] = []

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int) {
        selectedIndices.append(index)
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int]) {
        deletedIndices.append(indices)
    }

    func clipboardPanelDidDeleteAll(_ panel: ClipboardHistoryPanelView) {
        deleteAllCount += 1
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didTogglePinAt index: Int) {
        toggledPinIndices.append(index)
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didTogglePinsOf ids: Set<String>) {
        toggledPinIDs.append(ids)
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didRequestOpenURLAt index: Int) {}
}

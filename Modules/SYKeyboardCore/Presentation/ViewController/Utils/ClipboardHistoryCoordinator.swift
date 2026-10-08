//
//  ClipboardHistoryCoordinator.swift
//  SYKeyboardCore
//
//  Created by Claude on 10/8/26.
//

import UIKit
import OSLog
import SYKeyboardAssets

/// `ClipboardHistoryCoordinator`가 소유자(`BaseKeyboardViewController`)에게 요구하는 것.
/// `refresh…`/`interrupt…`는 VC의 private 메서드를 감싼 이름이다. 같은 파일의 Host 채택 extension이 한 줄로 전달한다
@MainActor
protocol ClipboardHistoryHost: AnyObject {
    var hasFullAccess: Bool { get }
    /// `BaseKeyboardViewController.isPreview`. 앱 미리보기에서는 패널을 열지 않고 pasteboard를 쓰지 않는다
    var isPreviewMode: Bool { get }
    /// 키보드가 내려간 뒤 프로세스만 남아 있을 때 pasteboard를 읽지 않기 위한 판정
    var isViewInWindow: Bool { get }

    func insertText(_ text: String)
    func commitUndoRedoGroupIgnoringCompositionDeferral()
    func undoRedoEditDidApply()
    func refreshShowingKeyboard()
    func refreshClipboardControl()
    func refreshReturnButtonEnabled()
    func refreshSuggestions()
    func interruptPendingDeleteInteractions()
    func openURL(_ url: URL)
}

/// 클립보드 기록 패널의 열기·닫기, pasteboard 동기화·복사·이미지 복원, 관련 알림 처리를 맡는다.
/// 패널 표시 여부(`isPanelVisible`)를 소유하고, 자판·버튼 갱신은 host에 요청한다.
/// host는 `weak`다. 알림·`DispatchQueue.main.async`가 이 객체를 VC보다 오래 살릴 수 있으므로 모든 진입점이 `guard let host`로 시작한다
@MainActor
final class ClipboardHistoryCoordinator: NSObject {

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "ClipboardHistoryCoordinator")

    /// 패널이 자판 자리에 보이는지. `updateShowingKeyboard`·`updateClipboardControl`이 읽는다
    private(set) var isPanelVisible = false

    private let clipboardHistoryStore: ClipboardHistoryStore?
    private let clipboardHistoryPanelView: ClipboardHistoryPanelView
    private let keyboardSettingsManager: UserDefaultsManager
    private weak var host: ClipboardHistoryHost?

    // MARK: - Initializer

    init(
        clipboardHistoryStore: ClipboardHistoryStore?,
        clipboardHistoryPanelView: ClipboardHistoryPanelView,
        keyboardSettingsManager: UserDefaultsManager,
        host: ClipboardHistoryHost
    ) {
        self.clipboardHistoryStore = clipboardHistoryStore
        self.clipboardHistoryPanelView = clipboardHistoryPanelView
        self.keyboardSettingsManager = keyboardSettingsManager
        self.host = host
        super.init()
    }

    deinit {
        logger.debug("ClipboardHistoryCoordinator deinit")
    }

    // MARK: - Internal Methods

    /// `viewDidLoad`에서 VC가 부른다. 등록 시점을 VC와 같게 두기 위해 init이 아니라 여기서 한다.
    /// - 호스트 앱이 다른 앱(사진 등)을 거쳐 돌아올 때는 viewWillAppear가 다시 오지 않으므로 활성화 알림에서 pasteboard를 확인한다
    /// - 이미지는 백그라운드에서 파일로 저장된 뒤 기록되므로, 그사이 패널이 열려 있으면 완료 알림에서 다시 읽는다
    /// - 상세 뷰에서 본문 일부를 복사하면 viewWillAppear 등 기존 동기화 시점이 오지 않으므로 pasteboard 변경 알림에서 기록한다
    func registerNotificationObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(hostDidBecomeActive), name: .NSExtensionHostDidBecomeActive, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(clipboardImageDidRecord),
            name: ClipboardHistoryPasteboardSynchronizer.didRecordImageNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(pasteboardDidChange), name: UIPasteboard.changedNotification, object: nil
        )
    }

    /// pasteboard의 `changeCount`가 마지막 확인값과 다를 때만 텍스트 또는 이미지를 읽어 기록에 저장합니다.
    ///
    /// 호출 시점: `viewWillAppear`, 호스트 앱 재활성화, `textWillChange`, 클립보드 버튼 탭. `textDidChange`와 selection 콜백은 쓰지 않습니다.
    /// 앱도 같은 `ClipboardHistoryPasteboardSynchronizer`를 쓰지만, 활성화 시에는 키보드가 예산 초과로 건너뛴 이미지가 남아 있을 때만 읽는다(#154).
    /// 이미지 저장 완료는 `didRecordImageNotification`으로 받는다(`clipboardImageDidRecord`)
    func synchronizeIfNeeded() {
        guard isClipboardHistoryAvailable, let clipboardHistoryStore else { return }
        ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(store: clipboardHistoryStore)
    }

    /// 클립보드 버튼 탭. 열려 있으면 닫고, 닫혀 있으면 동기화 후 엽니다.
    func togglePanel() {
        if isPanelVisible {
            closePanelIfNeeded()
        } else {
            openPanel()
        }
    }

    /// 패널을 닫고 자판으로 돌아갑니다. 이미 닫혀 있으면 아무것도 하지 않습니다.
    func closePanelIfNeeded() {
        guard isPanelVisible, let host else { return }
        isPanelVisible = false
        clipboardHistoryPanelView.resetPresentation()
        host.refreshShowingKeyboard()
        host.refreshClipboardControl()
    }

    // MARK: - @objc Methods

    /// 백그라운드 이미지 저장이 끝나 기록됐을 때. 패널이 열려 있으면 새 항목이 보이도록 다시 읽는다
    @objc func clipboardImageDidRecord() {
        guard host != nil, isPanelVisible else { return }
        reloadPanel()
    }

    /// 호스트 앱이 다시 활성화되면 그사이 다른 앱에서 복사한 내용을 반영한다.
    /// 텍스트는 동기 저장이라 패널이 열려 있으면 바로 다시 읽고, 이미지는 저장 완료 콜백이 다시 읽는다.
    /// 제어 센터·알림 센터를 내렸다 올려도 오므로, 목록이 실제로 바뀐 경우에만 다시 구성해 열린 상세 뷰·삭제 확인·안내문을 지우지 않는다
    @objc func hostDidBecomeActive() {
        // 키보드가 내려간 뒤 프로세스만 남아 있을 때는 읽지 않는다. 보이지 않는 키보드가 붙여넣기 권한 알림을 띄우지 않게 한다
        guard let host, host.isViewInWindow else { return }
        synchronizeIfNeeded()
        guard isPanelVisible, isClipboardHistoryAvailable, let clipboardHistoryStore,
              clipboardHistoryStore.load() != clipboardHistoryPanelView.items else { return }
        reloadPanel()
    }

    /// 패널이 열린 채 이 키보드 안에서 pasteboard가 바뀌면(상세 뷰 일부 복사) 기록에 반영하고, 보던 상세 뷰는 유지한다.
    /// 붙여넣기·이미지 복원은 쓴 직후 changeCount를 갱신하므로, 그 갱신이 끝난 다음 runloop에서 확인해 중복 기록하지 않는다
    @objc func pasteboardDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.host != nil, self.isPanelVisible, self.isClipboardHistoryAvailable,
                  let clipboardHistoryStore = self.clipboardHistoryStore else { return }
            self.synchronizeIfNeeded()
            guard clipboardHistoryStore.load() != self.clipboardHistoryPanelView.items else { return }
            self.reloadPanel(keepsDetail: true)
        }
    }
}

// MARK: - Private Methods

private extension ClipboardHistoryCoordinator {

    /// 클립보드 기록 기능 사용 가능 여부. 설정 ON, Full Access, 미리보기 아님. host가 없으면 사용 불가로 본다
    var isClipboardHistoryAvailable: Bool {
        guard let host else { return false }
        return keyboardSettingsManager.isClipboardHistoryEnabled
        && host.hasFullAccess
        && !host.isPreviewMode
    }

    func openPanel() {
        guard let host else { return }
        host.interruptPendingDeleteInteractions()
        synchronizeIfNeeded()
        reloadPanel()
        isPanelVisible = true
        host.refreshShowingKeyboard()
        host.refreshClipboardControl()
    }

    /// `keepsDetail`은 `ClipboardHistoryPanelView.configure(state:keepsDetail:)`로 그대로 넘긴다
    func reloadPanel(keepsDetail: Bool = false) {
        guard let host else { return }
        guard host.hasFullAccess, let clipboardHistoryStore else {
            clipboardHistoryPanelView.configure(state: .fullAccessRequired)
            return
        }
        let items = clipboardHistoryStore.load()
        clipboardHistoryPanelView.configure(state: items.isEmpty ? .empty : .items(items), keepsDetail: keepsDetail)
    }

    /// 이미지 항목은 입력창에 넣을 수 없으므로 시스템 pasteboard에 원본 바이트를 복원하고 패널을 유지한 채 안내한다.
    /// 우리가 쓴 값을 다음 동기화에서 다시 기록하지 않도록 changeCount를 갱신한다
    func restoreImageToPasteboard(_ reference: ClipboardImageReference) {
        guard isClipboardHistoryAvailable,
              let clipboardHistoryStore,
              let imageStore = clipboardHistoryStore.imageStore else { return }
        // 메모리 맵으로 열어 힙에 올리지 않는다. 앱에서 지운 뒤 키보드가 옛 목록을 들고 있으면 항목을 정리한다
        guard let data = try? Data(contentsOf: imageStore.originalURL(for: reference), options: .mappedIfSafe) else {
            clipboardHistoryStore.remove(ids: [ClipboardHistoryItem.Content.image(reference).id])
            reloadPanel()
            return
        }
        let pasteboard = UIPasteboard.general
        pasteboard.setData(data, forPasteboardType: reference.typeIdentifier)
        keyboardSettingsManager.lastSeenPasteboardChangeCount = pasteboard.changeCount

        // 방금 쓴 항목을 최근 복사한 것처럼 미고정 맨 위로 올린다. 고정 항목은 정책상 그대로다.
        // 탭 처리(didSelectRowAt) 안에서 행 이동 애니메이션을 시작하면 눌린 표시가 남을 수 있어 다음 런루프에서 다시 읽는다.
        // 안내 토스트는 재조회와 무관하지만 새 목록이 그려진 뒤에 띄워 순서를 분명히 한다
        clipboardHistoryStore.record(.image(reference))
        DispatchQueue.main.async { [weak self] in
            guard let self, self.host != nil else { return }
            self.reloadPanel()
            self.clipboardHistoryPanelView.showTransientMessage(
                String(localized: "이미지를 복사했습니다.\n입력창을 길게 눌러 붙여넣기 해주세요.", bundle: SYKBDAssets.bundle)
            )
        }
    }

    /// 텍스트를 시스템 pasteboard에 복사한다. 우리가 쓴 값을 다음 동기화에서 다시 기록하지 않도록 changeCount를 갱신한다
    func copyTextToPasteboard(_ text: String) {
        guard isClipboardHistoryAvailable else { return }
        let pasteboard = UIPasteboard.general
        pasteboard.string = text
        keyboardSettingsManager.lastSeenPasteboardChangeCount = pasteboard.changeCount
    }
}

// MARK: - ClipboardHistoryPanelDelegate

extension ClipboardHistoryCoordinator: ClipboardHistoryPanelDelegate {
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int) {
        guard let host, panel.items.indices.contains(index) else { return }
        switch panel.items[index].content {
        case .image(let reference):
            restoreImageToPasteboard(reference)
        case .text(let text):
            // 붙여넣기를 undo 1단위로 만든다: 앞선 입력 그룹을 닫고, 삽입 후 다시 닫는다
            host.commitUndoRedoGroupIgnoringCompositionDeferral()
            host.insertText(text)
            host.undoRedoEditDidApply()
            host.commitUndoRedoGroupIgnoringCompositionDeferral()

            // macOS Spotlight 클립보드 기록처럼 고른 항목을 현재 클립보드로도 올린다. 동기화가 기록한 내용은 목록에 남지만,
            // 기록되지 않는 내용(이미지 기록 OFF·저장 거부 이미지·예산 초과로 앱 재시도 대기 중인 이미지·concealed·문자열 없는 항목)은 덮어써진다
            copyTextToPasteboard(text)
            // 방금 쓴 항목을 최근 복사한 것처럼 미고정 맨 위로 올린다. 고정 항목은 정책상 그대로다
            clipboardHistoryStore?.record(text)

            closePanelIfNeeded()
            host.refreshReturnButtonEnabled()
            host.refreshSuggestions()
        }
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int]) {
        // 인덱스는 패널이 보여준 목록 기준이므로 id로 바꿔 지운다. 파일 순서가 그사이 바뀌어도 안전하다
        let ids = Set(indices.compactMap { panel.items.indices.contains($0) ? panel.items[$0].id : nil })
        clipboardHistoryStore?.remove(ids: ids)
        reloadPanel()
    }

    func clipboardPanelDidDeleteAll(_ panel: ClipboardHistoryPanelView) {
        clipboardHistoryStore?.removeAll()
        reloadPanel()
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didTogglePinAt index: Int) {
        clipboardHistoryStore?.togglePin(at: index)
        reloadPanel()
    }

    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didTogglePinsOf ids: Set<String>) {
        // 저장소가 파일을 다시 읽어 정책을 적용하므로 그사이 앱이 바꾼 내용과 어긋나지 않는다
        clipboardHistoryStore?.togglePins(selectedIDs: ids)
        reloadPanel()
    }

    /// 브라우저가 열리면 호스트 앱을 떠나므로 키보드는 시스템이 내린다. 설정 이동과 같은 responder chain 경로다
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didRequestOpenURLAt index: Int) {
        guard let host, panel.items.indices.contains(index),
              let text = panel.items[index].text,
              let url = ClipboardHistoryPolicy.openableURL(in: text) else { return }
        host.openURL(url)
    }
}

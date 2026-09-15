//
//  ClipboardHistoryPanelView.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/8/26.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

import SYKeyboardAssets

/// `ClipboardHistoryPanelView`의 사용자 상호작용을 수신하는 델리게이트
protocol ClipboardHistoryPanelDelegate: AnyObject {
    /// 항목을 탭하거나 상세 뷰에서 붙여넣기(텍스트)·복사(이미지)를 눌렀을 때 호출됩니다.
    /// 소유자는 텍스트를 입력창에 넣고 시스템 pasteboard에도 복사하며, 이미지는 pasteboard에 복원합니다.
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int)
    /// 스와이프 삭제 또는 편집 모드에서 일부 항목을 삭제했을 때 호출됩니다. 인덱스는 오름차순입니다.
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int])
    /// 편집 모드에서 전체 선택 후 삭제했을 때 호출됩니다.
    func clipboardPanelDidDeleteAll(_ panel: ClipboardHistoryPanelView)
    /// leading swipe 또는 상세 뷰에서 항목의 고정을 토글했을 때 호출됩니다.
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didTogglePinAt index: Int)
    /// 상세 뷰에서 링크로 표시된 본문을 탭했을 때 호출됩니다. 항목 전체가 http/https URL일 때만 링크가 됩니다.
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didRequestOpenURLAt index: Int)
}

/// 클립보드 기록 목록을 자판 영역에 표시하는 패널
///
/// 저장소를 모르는 표시 전용 뷰다. 상태는 `configure(state:)`로 받고 결정은 델리게이트가 한다.
///
/// ## 동작
/// - 평소: 행 탭은 붙여넣기(텍스트) 또는 pasteboard 복원(이미지), trailing swipe는 개별 삭제, leading swipe는 고정/해제, 길게 누르기는 원문 상세 뷰.
///   이미지 복원 결과 같은 안내는 하단 중앙 토스트(`showTransientMessage`)로 2초간 띄운다
/// - 편집 모드(`isItemEditing`): 행 탭은 선택 토글, 길게 누르기는 선택을 바꾸지 않고 원문 상세 뷰, "전체 선택"·"n개 삭제"·"완료".
///   `UITableView.isEditing`은 스와이프 액션이 열려 있는 동안에도 true가 되므로 판단에 쓰지 않는다
final class ClipboardHistoryPanelView: UIView {

    enum State: Equatable {
        case fullAccessRequired
        case empty
        case items([ClipboardHistoryItem])
    }

    // MARK: - Properties

    weak var delegate: ClipboardHistoryPanelDelegate?

    /// 썸네일·미리보기 파일을 찾는 저장소. 소유자가 설정한다. `nil`이면 이미지 행에 자리표시 아이콘만 보인다
    var imageStore: ClipboardImageStore?

    /// 상세 미리보기 디코드에 쓸 수 있는 예산. 테스트에서 줄여 가드를 확정적으로 검증한다
    var decodeMemoryBudget = ClipboardImagePolicy.keyboardDecodeMemoryBudget

    /// 해시별 썸네일. 같은 해시는 같은 바이트라 무효화가 필요 없다. 메모리 경고 시 소유자가 `purgeThumbnailCache()`로 비운다
    private let thumbnailCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = ClipboardHistoryPolicy.maxItemCount + ClipboardHistoryPolicy.maxPinnedCount
        return cache
    }()
    /// 안내 토스트를 숨기는 예약 작업
    private var pendingToastHide: DispatchWorkItem?
    /// 토스트 표시 세대. 페이드아웃 완료 시점에 그사이 다시 띄워졌는지 구분한다
    private var toastGeneration = 0

    private static let transientMessageDuration: TimeInterval = 2
    private static let toastFadeInDuration: TimeInterval = 0.15
    private static let toastFadeOutDuration: TimeInterval = 0.25
    private static let thumbnailSize = CGSize(width: 44, height: 44)
    private static let imagePlaceholderSymbolName = "photo"

    /// 현재 표시 중인 항목(최신순). 델리게이트 인덱스는 이 배열 기준이다
    private(set) var items: [ClipboardHistoryItem] = []

    /// 상세 뷰가 보여주는 항목의 id. 목록이 갱신돼 순서가 바뀌어도 같은 항목을 가리킨다
    private var detailItemID: String?
    /// 상세 뷰가 보여주는 항목의 현재 인덱스. 목록에서 사라졌으면 `nil`
    private var detailItemIndex: Int? {
        guard let detailItemID else { return nil }
        return items.firstIndex { $0.id == detailItemID }
    }
    /// 사용자가 "선택"으로 들어간 다중 선택 모드인지. 스와이프 중에도 true가 되는 `tableView.isEditing`과 구분한다
    private(set) var isItemEditing = false
    /// 고정 항목이 섞여 확인을 기다리는 삭제. 인덱스는 `items` 기준이다
    private var pendingDeletion: (indices: [Int], deleteAll: Bool)?

    private static let cellIdentifier = "ClipboardHistoryCell"

    /// 길게 누르기 → 원문 상세 뷰. 편집 모드에서는 인식이 끝날 때까지 셀에 터치를 넘기지 않아(`delaysTouchesBegan`)
    /// 다중 선택 셀의 눌림(회색·체크 표시)이 먼저 그려지지 않는다. 짧은 탭은 인식 실패 시점에 전달돼 선택이 토글된다
    private lazy var longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    /// 테이블 터치의 시작·끝을 지연 없이 관찰한다. 손가락이 모두 떨어진 뒤 남은 행 눌림을 정리하는 기준이다
    private lazy var touchObserver: ClipboardHistoryTouchObserver = {
        let recognizer = ClipboardHistoryTouchObserver()
        recognizer.onAllTouchesEnded = { [weak self] in self?.scheduleStaleHighlightCleanup() }
        return recognizer
    }()
    /// 스와이프 액션은 색 배경 위에 뜨므로 채운 변형을 쓴다
    private static let pinActionSymbolName = "pin.fill"
    private static let unpinActionSymbolName = "pin.slash.fill"
    private static let deleteActionSymbolName = "trash.fill"
    private static let pinnedAccessorySymbolName = "pin.circle.fill"
    private static let headerHeight: CGFloat = 36

    // MARK: - UI Components

    private let headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 4)
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "클립보드 기록", bundle: SYKBDAssets.bundle)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7

        return label
    }()

    private lazy var selectAllButton = makeHeaderButton(title: "") { [weak self] in
        self?.toggleSelectAll()
    }

    private lazy var deleteButton: UIButton = {
        let button = makeHeaderButton(title: "") { [weak self] in
            self?.deleteSelectedItems()
        }
        button.configuration?.baseForegroundColor = .systemRed
        // 선택 개수가 바뀌어도 버튼 폭이 흔들리지 않도록 숫자를 고정폭으로 표시한다
        button.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            // 제목이 갱신될 때마다 현재 Dynamic Type 크기를 읽는다
            attributes.font = UIFont.monospacedDigitSystemFont(
                ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
                weight: .regular
            )
            return attributes
        }

        return button
    }()

    private lazy var editButton = makeHeaderButton(
        title: String(localized: "선택", bundle: SYKBDAssets.bundle)
    ) { [weak self] in
        self?.beginItemEditing()
    }

    private lazy var doneButton = makeHeaderButton(
        title: String(localized: "완료", bundle: SYKBDAssets.bundle),
        weight: .semibold
    ) { [weak self] in
        self?.endItemEditing()
    }

    /// id가 유일하므로 id를 행 식별자로 쓴다. 스냅샷 차이로 삭제·삽입·이동을 애니메이션한다
    private lazy var dataSource = ClipboardHistoryDataSource(tableView: tableView) { [weak self] tableView, indexPath, id in
        self?.makeCell(in: tableView, at: indexPath, id: id) ?? UITableViewCell()
    }

    /// 테스트에서 `UITableViewDelegate` 메서드를 직접 호출할 수 있도록 internal로 둔다
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(ClipboardHistoryCell.self, forCellReuseIdentifier: ClipboardHistoryPanelView.cellIdentifier)

        return tableView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true

        return label
    }()

    /// 결과 안내 토스트. 패널 하단 중앙에 material 알약으로 잠깐 떠서 편집 모드와 무관하게 보이고 터치는 통과시킨다.
    /// 목록 행 위에 겹치므로 상세 뷰와 같은 thick material로 글자 뒤를 충분히 가린다
    private let toastView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.isHidden = true
        view.isUserInteractionEnabled = false

        return view
    }()

    /// 안내 문구는 문장 사이에 줄바꿈을 넣어 모든 기기에서 같은 두 줄로 보인다(375 pt 기기에서도 각 줄이 폭 안에 든다).
    /// 글자 색은 material 위에서 라이트·다크 모두 대비가 맞는 시스템 label 색이다
    private let toastLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakStrategy = .hangulWordPriority

        return label
    }()

    private lazy var detailView: ClipboardHistoryDetailView = {
        let view = ClipboardHistoryDetailView()
        view.isHidden = true
        view.onClose = { [weak self] in self?.hideDetail() }
        view.onPaste = { [weak self] in self?.pasteDetailItem() }
        view.onTogglePin = { [weak self] in self?.toggleDetailItemPin() }
        view.onOpenURL = { [weak self] in
            guard let self, let index = self.detailItemIndex else { return }
            self.delegate?.clipboardPanel(self, didRequestOpenURLAt: index)
        }

        return view
    }()

    /// 키보드 extension은 시스템 알림을 띄울 수 없어 패널 안에서 확인받는다
    private lazy var deleteConfirmView: ClipboardHistoryDeleteConfirmView = {
        let view = ClipboardHistoryDeleteConfirmView()
        view.isHidden = true
        view.onCancel = { [weak self] in self?.cancelPendingDeletion() }
        view.onConfirm = { [weak self] in self?.confirmPendingDeletion() }

        return view
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Methods

    /// 패널 상태를 갱신합니다. 상세 뷰는 닫고, 편집 모드는 유지하되 항목이 없어지면 해제합니다.
    ///
    /// `keepsDetail`이면 상세 뷰를 닫지 않고 보던 항목을 새 목록에서 다시 가리킵니다. 그 항목이 사라졌으면 닫습니다.
    /// 상세 뷰에서 일부를 복사해 기록이 늘어난 경우처럼 사용자가 상세를 보는 중인 갱신에 씁니다.
    ///
    /// 패널이 보이는 중이면 바뀐 행만 삭제·삽입 애니메이션으로 반영하고, 숨겨진 상태면 전체를 다시 그립니다.
    func configure(state: State, keepsDetail: Bool = false) {
        if !keepsDetail { hideDetail() }
        hideDeleteConfirmation()
        let previousItems = items
        switch state {
        case .fullAccessRequired:
            items = []
            messageLabel.text = String(localized: "전체 접근 허용이 필요합니다", bundle: SYKBDAssets.bundle)
        case .empty:
            items = []
            messageLabel.text = String(localized: "복사한 텍스트나 이미지가 여기에 표시됩니다.", bundle: SYKBDAssets.bundle)
        case .items(let newItems):
            items = newItems
        }
        if keepsDetail, detailItemID != nil, detailItemIndex == nil { hideDetail() }
        // 편집 모드 해제 애니메이션이 행 갱신 애니메이션과 겹치지 않도록 먼저 끝낸다
        if items.isEmpty { endItemEditing() }
        applySnapshot(from: previousItems, animated: !self.isHidden && !previousItems.isEmpty)
        updateHeader()
    }

    /// 편집 모드와 상세 뷰를 닫고 스크롤을 맨 위로 되돌립니다. 패널을 닫을 때 호출합니다.
    func resetPresentation() {
        hideDetail(animated: false)
        hideDeleteConfirmation(animated: false)
        hideTransientMessage(animated: false)
        endItemEditing()
        // 열린 스와이프 액션도 닫는다. 스와이프 중에는 tableView.isEditing만 true라 endItemEditing이 건너뛴다
        tableView.setEditing(false, animated: false)
        tableView.setContentOffset(.zero, animated: false)
    }

    // 헤더 버튼 동작. 테스트에서 직접 호출할 수 있도록 internal로 둔다

    func beginItemEditing() {
        guard !items.isEmpty, !isItemEditing else { return }
        isItemEditing = true
        longPressRecognizer.delaysTouchesBegan = true
        // 열린 스와이프가 있으면 먼저 닫아 헤더와 테이블이 함께 편집 모드로 들어간다
        tableView.setEditing(false, animated: false)
        setTableEditingAnimated(true)
        updateHeader()
    }

    /// 편집 모드 전환을 UIKit 내부 애니메이션 대신 터치를 막지 않는 우리 애니메이션으로 수행한다.
    /// `setEditing(_:animated: true)`는 애니메이션 동안 터치를 통째로 무시해 그사이 스크롤·탭·길게 누르기가 되지 않는다
    private func setTableEditingAnimated(_ editing: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            self.tableView.setEditing(editing, animated: false)
            self.tableView.layoutIfNeeded()
        }
    }

    func endItemEditing() {
        guard isItemEditing else { return }
        isItemEditing = false
        longPressRecognizer.delaysTouchesBegan = false
        setTableEditingAnimated(false)
        updateHeader()
    }

    func toggleSelectAll() {
        guard isItemEditing else { return }
        if isAllSelected {
            tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: false) }
        } else {
            (0..<items.count).forEach {
                tableView.selectRow(at: IndexPath(row: $0, section: 0), animated: false, scrollPosition: .none)
            }
        }
        updateHeader()
    }

    func deleteSelectedItems() {
        guard isItemEditing else { return }
        let indices = (tableView.indexPathsForSelectedRows ?? []).map(\.row).sorted()
        guard !indices.isEmpty else { return }

        requestDelete(at: indices, deleteAll: indices.count == items.count)
    }

    /// 고정 항목이 섞여 있으면 패널 안 확인 뷰를 띄우고, 미고정만이면 바로 델리게이트에 넘긴다.
    /// 앱 관리 화면의 삭제 알림과 같은 규칙이다. 바로 지웠으면 `true`, 확인 대기로 갔으면 `false`
    @discardableResult
    func requestDelete(at indices: [Int], deleteAll: Bool) -> Bool {
        let pinnedCount = indices.filter { items.indices.contains($0) && items[$0].isPinned }.count
        guard pinnedCount > 0 else {
            performDelete(at: indices, deleteAll: deleteAll)
            return true
        }
        pendingDeletion = (indices, deleteAll)
        deleteConfirmView.update(pinnedCount: pinnedCount, totalCount: indices.count)
        setOverlayHidden(deleteConfirmView, false, animated: true)
        return false
    }

    func confirmPendingDeletion() {
        guard let pendingDeletion else { return }
        hideDeleteConfirmation(animated: false)
        performDelete(at: pendingDeletion.indices, deleteAll: pendingDeletion.deleteAll)
    }

    func cancelPendingDeletion() {
        hideDeleteConfirmation()
    }

    /// 패널 하단에 `message` 토스트를 페이드인으로 띄우고 2초 뒤 페이드아웃한다. 이미지 복원처럼 패널을 유지한 채
    /// 결과를 알릴 때 쓴다. 편집 모드에서도 뜨며, 표시 중에 다시 부르면 문구를 바꾸고 시간을 새로 센다.
    /// 목록 재조회(`configure`)는 토스트를 건드리지 않는다
    func showTransientMessage(_ message: String) {
        pendingToastHide?.cancel()
        toastGeneration += 1
        toastLabel.text = message
        if toastView.isHidden {
            toastView.alpha = 0
            toastView.isHidden = false
        }
        UIView.animate(withDuration: ClipboardHistoryPanelView.toastFadeInDuration) { self.toastView.alpha = 1 }
        UIAccessibility.post(notification: .announcement, argument: message)

        let workItem = DispatchWorkItem { [weak self] in self?.hideTransientMessage(animated: true) }
        pendingToastHide = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + ClipboardHistoryPanelView.transientMessageDuration,
            execute: workItem
        )
    }

    private func hideTransientMessage(animated: Bool) {
        pendingToastHide?.cancel()
        pendingToastHide = nil
        guard !toastView.isHidden else { return }
        guard animated else {
            toastView.isHidden = true
            return
        }
        let generation = toastGeneration
        UIView.animate(withDuration: ClipboardHistoryPanelView.toastFadeOutDuration, animations: {
            self.toastView.alpha = 0
        }, completion: { [weak self] _ in
            // 페이드아웃 중에 새 안내가 떴으면 그대로 둔다
            guard let self, self.toastGeneration == generation else { return }
            self.toastView.isHidden = true
        })
    }

    /// 안내 토스트가 보이는 중인지. 페이드아웃이 진행 중인 동안도 `true`다. 테스트에서 `showTransientMessage` 결과를 확인하는 용도
    var isTransientMessageVisible: Bool { !toastView.isHidden }
    var transientMessageText: String? { toastLabel.text }

    func purgeThumbnailCache() {
        thumbnailCache.removeAllObjects()
        // 닫힌 상세 뷰가 들고 있던 미리보기(최대 약 5.8 MB)도 놓는다. 보이는 중이면 유지한다
        if detailView.isHidden { detailView.releasePreviewImage() }
    }

    /// 상세 뷰가 보이는 중인지. 테스트에서 `showDetail(at:)` 결과를 확인하는 용도
    var isDetailVisible: Bool { !detailView.isHidden }

    /// `index` 항목의 상세 뷰를 연다. 테스트에서 `handleLongPress`를 거치지 않고 바로 부를 수 있도록 internal로 둔다.
    /// 이미지는 PNG가 ImageIO에서 원본 전체로 디코드될 수 있어(픽셀 × 4바이트) 이 이미지의 예상 디코드 메모리가 키보드 예산을
    /// 넘으면 미리보기 디코드를 건너뛰고 목록에 쓰던 캐시 썸네일로 대신한다(없으면 자리표시 아이콘)
    func showDetail(at index: Int) {
        guard items.indices.contains(index) else { return }
        detailItemID = items[index].id
        let item = items[index]
        let canPin = ClipboardHistoryPolicy.canPin(items)
        switch item.content {
        case .text(let text):
            detailView.update(
                text: text,
                isPinned: item.isPinned,
                canPin: canPin,
                canOpenURL: ClipboardHistoryPolicy.openableURL(in: text) != nil
            )
        case .image(let reference):
            let preview: UIImage?
            if ClipboardImagePolicy.canDecode(
                typeIdentifier: reference.typeIdentifier,
                pixelWidth: reference.pixelWidth,
                pixelHeight: reference.pixelHeight,
                budget: decodeMemoryBudget
            ) {
                preview = imageStore?
                    .previewImage(for: reference, maxPixelSize: ClipboardImagePolicy.keyboardPreviewMaxPixelSize)
                    .map { UIImage(cgImage: $0) }
            } else {
                preview = thumbnail(for: reference)
            }
            detailView.update(image: preview, isPinned: item.isPinned, canPin: canPin)
        }
        setDetailHidden(false, animated: true)
    }

    /// 상세 뷰의 붙여넣기(텍스트)·복사(이미지). 행 탭과 같은 델리게이트 경로다. 테스트에서 직접 호출할 수 있도록 internal로 둔다
    func pasteDetailItem() {
        guard let index = detailItemIndex else { return }
        // 붙여넣기(텍스트)는 이 직후 패널이 닫히지만, 복사(이미지)는 패널이 열린 채 유지된다.
        // 상세 뷰는 여기서 먼저 숨기고, 이미지 쪽은 이어지는 configure() 갱신으로 다시 숨김 상태가 반영된다
        hideDetail(animated: false)
        delegate?.clipboardPanel(self, didSelectItemAt: index)
    }

    /// 상세 뷰의 고정/해제. 테스트에서 직접 호출할 수 있도록 internal로 둔다
    func toggleDetailItemPin() {
        guard let index = detailItemIndex else { return }
        delegate?.clipboardPanel(self, didTogglePinAt: index)
    }
}

// MARK: - UI Methods

private extension ClipboardHistoryPanelView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
        tableView.dataSource = dataSource
        // 셀·테이블 배경이 투명해 기본 애니메이션(.automatic)은 삭제되는 행과 밀려 올라오는 행이 겹쳐 보인다
        dataSource.defaultRowAnimation = .fade
        tableView.delegate = self
        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.addGestureRecognizer(touchObserver)
        updateHeader()
    }

    func setStyles() {
        self.backgroundColor = .clear
    }

    func setHierarchy() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        [titleLabel, selectAllButton, spacer, deleteButton, editButton, doneButton].forEach {
            headerStackView.addArrangedSubview($0)
        }
        toastView.contentView.addSubview(toastLabel)
        [headerStackView, tableView, messageLabel, toastView, detailView, deleteConfirmView].forEach { self.addSubview($0) }
    }

    func setConstraints() {
        [headerStackView, tableView, messageLabel, toastView, toastLabel, detailView, deleteConfirmView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: self.topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            headerStackView.heightAnchor.constraint(equalToConstant: ClipboardHistoryPanelView.headerHeight),

            tableView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            messageLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -16),

            // 하단 중앙 고정 여백이라 어떤 키보드 높이에서도 패널 안에 들어온다
            toastView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            toastView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12),
            toastView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 16),
            toastView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -16),
            toastLabel.topAnchor.constraint(equalTo: toastView.contentView.topAnchor, constant: 8),
            toastLabel.bottomAnchor.constraint(equalTo: toastView.contentView.bottomAnchor, constant: -8),
            toastLabel.leadingAnchor.constraint(equalTo: toastView.contentView.leadingAnchor, constant: 14),
            toastLabel.trailingAnchor.constraint(equalTo: toastView.contentView.trailingAnchor, constant: -14),

            detailView.topAnchor.constraint(equalTo: self.topAnchor),
            detailView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            detailView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            detailView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            deleteConfirmView.topAnchor.constraint(equalTo: self.topAnchor),
            deleteConfirmView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            deleteConfirmView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            deleteConfirmView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

// MARK: - Private Methods

private extension ClipboardHistoryPanelView {
    var isAllSelected: Bool {
        !items.isEmpty && (tableView.indexPathsForSelectedRows?.count ?? 0) == items.count
    }

    /// 캐시에 없으면 썸네일 파일을 읽어 넣는다. 파일이 없으면 `nil`
    func thumbnail(for reference: ClipboardImageReference) -> UIImage? {
        let key = reference.hash as NSString
        if let cached = thumbnailCache.object(forKey: key) { return cached }
        guard let url = imageStore?.thumbnailURL(for: reference),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        thumbnailCache.setObject(image, forKey: key)
        return image
    }

    func updateHeader() {
        let isEditing = isItemEditing
        titleLabel.isHidden = isEditing
        editButton.isHidden = isEditing || items.isEmpty
        selectAllButton.isHidden = !isEditing
        deleteButton.isHidden = !isEditing
        doneButton.isHidden = !isEditing

        let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        selectAllButton.configuration?.title = isAllSelected
        ? String(localized: "선택 해제", bundle: SYKBDAssets.bundle)
        : String(localized: "전체 선택", bundle: SYKBDAssets.bundle)
        deleteButton.configuration?.title = String(localized: "\(selectedCount)개 삭제", bundle: SYKBDAssets.bundle)
        deleteButton.isEnabled = selectedCount > 0
    }

    /// 편집 모드를 끝내는 "완료"는 iOS 편집 툴바처럼 semibold로 강조한다
    func makeHeaderButton(
        title: String,
        weight: UIFont.Weight = .regular,
        handler: @escaping () -> Void
    ) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        if weight != .regular {
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = UIFont.systemFont(
                    ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
                    weight: weight
                )
                return attributes
            }
        }
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in handler() })
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        return button
    }

    /// 패널을 닫을 때는 자판 복귀와 겹치지 않도록 애니메이션 없이 숨긴다
    /// 닫힌 뒤에는 디코드해 둔 미리보기(최대 약 5.8 MB)를 놓는다. 다시 열면 `showDetail(at:)`이 원본에서 다시 디코드한다
    func hideDetail(animated: Bool = true) {
        detailItemID = nil
        setDetailHidden(true, animated: animated) { [weak self] in
            // 전환 중에 다른 항목의 상세가 다시 열렸으면 그 이미지는 유지한다
            guard let self, self.detailView.isHidden else { return }
            self.detailView.releasePreviewImage()
        }
    }

    func setDetailHidden(_ isHidden: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        setOverlayHidden(detailView, isHidden, animated: animated, completion: completion)
    }

    func hideDeleteConfirmation(animated: Bool = true) {
        pendingDeletion = nil
        setOverlayHidden(deleteConfirmView, true, animated: animated)
    }

    func performDelete(at indices: [Int], deleteAll: Bool) {
        if deleteAll {
            delegate?.clipboardPanelDidDeleteAll(self)
        } else {
            delegate?.clipboardPanel(self, didDeleteItemsAt: indices)
        }
    }

    /// 상세 뷰와 삭제 확인 뷰는 패널 전체를 덮으며 크로스페이드로 나타난다
    func setOverlayHidden(_ overlay: UIView, _ isHidden: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        guard overlay.isHidden != isHidden else { completion?(); return }
        guard animated else {
            overlay.isHidden = isHidden
            completion?()
            return
        }
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {
            overlay.isHidden = isHidden
        }, completion: { _ in completion?() })
    }

    /// 현재 `items`로 스냅샷을 만들어 적용한다. 고정 여부만 바뀐 행은 식별자가 같으므로 다시 구성한다
    func applySnapshot(from previousItems: [ClipboardHistoryItem], animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(items.map(\.id))
        // 파일이 손상돼 id가 중복돼도 crash하지 않도록 첫 값을 쓴다
        let previousPinState = Dictionary(previousItems.map { ($0.id, $0.isPinned) }, uniquingKeysWith: { first, _ in first })
        let pinStateChanged = items
            .filter { item in previousPinState[item.id].map { $0 != item.isPinned } ?? false }
            .map(\.id)
        snapshot.reconfigureItems(pinStateChanged)

        // 마지막 행이 사라지는 애니메이션이 끝난 뒤에 테이블을 숨긴다
        dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self else { return }
            self.messageLabel.isHidden = !self.items.isEmpty
            self.tableView.isHidden = self.items.isEmpty
            // 애니메이션 중 선택 상태가 바뀔 수 있으므로 헤더를 다시 맞춘다
            self.updateHeader()
        }
    }

    /// 스냅샷 식별자(id)로 항목을 찾는다. 애니메이션 중에는 이전 스냅샷의 indexPath가 넘어올 수 있어 인덱스를 쓰지 않는다
    func makeCell(in tableView: UITableView, at indexPath: IndexPath, id: String) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ClipboardHistoryPanelView.cellIdentifier, for: indexPath
        ) as? ClipboardHistoryCell else { return UITableViewCell() }
        guard let item = items.first(where: { $0.id == id }) else { return cell }
        var content = cell.defaultContentConfiguration()
        content.textProperties.font = .systemFont(ofSize: 15)
        switch item.content {
        case .text(let text):
            content.text = text
            content.textProperties.numberOfLines = 2
            content.textProperties.lineBreakMode = .byTruncatingTail
        case .image(let reference):
            // 썸네일만 읽는다. 원본은 목록에서 열지 않는다
            content.image = thumbnail(for: reference)
                ?? UIImage(systemName: ClipboardHistoryPanelView.imagePlaceholderSymbolName)
            content.imageProperties.maximumSize = ClipboardHistoryPanelView.thumbnailSize
            content.imageProperties.reservedLayoutSize = ClipboardHistoryPanelView.thumbnailSize
            content.imageProperties.cornerRadius = 4
            content.text = String(localized: "이미지", bundle: SYKBDAssets.bundle)
            content.secondaryText = reference.sizeDescription
            content.secondaryTextProperties.font = .systemFont(ofSize: 12)
            content.secondaryTextProperties.color = .secondaryLabel
        }
        // 고정 항목은 오른쪽 아이콘 자리만큼 본문 여백을 넓혀 글자가 아이콘 밑으로 들어가지 않게 한다
        if item.isPinned {
            content.directionalLayoutMargins.trailing += ClipboardHistoryCell.pinIconSize + ClipboardHistoryCell.pinIconSpacing
        }
        cell.contentConfiguration = content
        cell.updatePinIcon(
            isPinned: item.isPinned,
            image: UIImage(systemName: ClipboardHistoryPanelView.pinnedAccessorySymbolName)
        )
        cell.backgroundColor = .clear
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .suggestionButtonPressed
        cell.selectedBackgroundView = selectedBackgroundView

        return cell
    }

    /// 같은 터치 도중 스와이프가 끝나면 스크롤 뷰가 붙잡아 둔 touchesBegan이 이미 취소된 터치로 다시 전달돼
    /// 눌림만 걸리고 끝 이벤트는 오지 않는다. 다음 runloop에서 손가락이 없고 선택 없이 눌림만 남은 행을 해제한다.
    /// 짧은 탭은 같은 이벤트 처리 안에서 선택·해제가 끝나므로 영향이 없고, 편집 모드는 선택 표시를 쓰므로 건드리지 않는다
    func scheduleStaleHighlightCleanup() {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isItemEditing, self.touchObserver.activeTouchCount == 0 else { return }
            for cell in self.tableView.visibleCells where cell.isHighlighted && !cell.isSelected {
                cell.setHighlighted(false, animated: true)
            }
        }
    }

    /// 편집 모드에서도 연다. 인식되는 순간 테이블 터치가 취소되므로 행 선택은 바뀌지 않는다
    @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        let point = recognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        FeedbackManager.shared.playHaptic()
        showDetail(at: indexPath.row)
    }
}

// MARK: - UITableViewDelegate

extension ClipboardHistoryPanelView: UITableViewDelegate {
    // 델리게이트 메서드의 indexPath.row는 사용자 터치 시점에만 쓰이므로 애니메이션이 끝난 items와 일치한다
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isItemEditing {
            updateHeader()
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
        FeedbackManager.shared.playHaptic()
        delegate?.clipboardPanel(self, didSelectItemAt: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isItemEditing { updateHeader() }
    }

    /// 손가락이 이미 떨어진 뒤의 눌림은 짧은 탭이면 곧바로 선택이 이어지고, 늦게 전달된 터치면 그대로 남는다
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard touchObserver.activeTouchCount == 0 else { return }
        scheduleStaleHighlightCleanup()
    }

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard items.indices.contains(indexPath.row) else { return nil }
        let isPinned = items[indexPath.row].isPinned
        // 고정 한도가 찼으면 미고정 행에는 고정 액션을 만들지 않는다
        guard isPinned || ClipboardHistoryPolicy.canPin(items) else { return nil }

        let pinAction = UIContextualAction(
            style: .normal,
            title: isPinned
            ? String(localized: "고정 해제", bundle: SYKBDAssets.bundle)
            : String(localized: "고정", bundle: SYKBDAssets.bundle)
        ) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            // 소유자가 configure()로 행 이동을 애니메이션한 뒤 액션을 닫는다
            self.delegate?.clipboardPanel(self, didTogglePinAt: indexPath.row)
            completion(true)
        }
        pinAction.backgroundColor = .systemOrange
        pinAction.image = UIImage(
            systemName: isPinned
            ? ClipboardHistoryPanelView.unpinActionSymbolName
            : ClipboardHistoryPanelView.pinActionSymbolName
        )

        return UISwipeActionsConfiguration(actions: [pinAction])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: String(localized: "삭제", bundle: SYKBDAssets.bundle)
        ) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            // 소유자가 configure()에서 deleteRows로 행을 지운 뒤 액션을 닫는다. Apple의 삭제 액션 관례와 같다.
            // 고정 행이면 확인 뷰만 뜨고 행은 남으므로 수행하지 않았다고 알린다
            completion(self.requestDelete(at: [indexPath.row], deleteAll: false))
        }
        deleteAction.image = UIImage(systemName: ClipboardHistoryPanelView.deleteActionSymbolName)

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Supporting Types

/// `UITableViewDiffableDataSource`는 기본적으로 편집을 막으므로 스와이프·편집 모드가 동작하도록 허용한다
private final class ClipboardHistoryDataSource: UITableViewDiffableDataSource<Int, String> {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

/// 터치 수만 세는 인식기. 인식하지 않고, 다른 인식기를 막거나 막히지 않으며, 뷰로 가는 터치를 지연·취소하지 않는다
private final class ClipboardHistoryTouchObserver: UIGestureRecognizer {
    private(set) var activeTouchCount = 0
    var onAllTouchesEnded: (() -> Void)?

    init() {
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        activeTouchCount += touches.count
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        endTouches(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        endTouches(touches)
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    private func endTouches(_ touches: Set<UITouch>) {
        activeTouchCount = max(0, activeTouchCount - touches.count)
        guard activeTouchCount == 0 else { return }
        onAllTouchesEnded?()
        // 인식하지 않으므로 실패로 끝내 다음 터치에서 다시 시작한다
        state = .failed
    }
}

/// 고정 아이콘을 액세서리가 아니라 콘텐츠 영역 오른쪽에 둔 셀.
/// 액세서리로 두면 편집 모드 전환 때 `accessoryView`와 `editingAccessoryView`가 바뀌며 사라졌다 나타나므로, 한 뷰를 제자리에 둔다
private final class ClipboardHistoryCell: UITableViewCell {
    static let pinIconSize: CGFloat = 16
    static let pinIconSpacing: CGFloat = 16

    let pinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true

        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 콘텐츠 설정을 넣은 뒤에 부른다. 설정은 `contentView`를 새 뷰로 바꿀 수 있어, 현재 `contentView`에 아이콘이 없으면 다시 붙인다
    func updatePinIcon(isPinned: Bool, image: UIImage?) {
        pinImageView.image = image
        pinImageView.isHidden = !isPinned
        if pinImageView.superview !== contentView {
            pinImageView.removeFromSuperview()
            pinImageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(pinImageView)
            NSLayoutConstraint.activate([
                pinImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ClipboardHistoryCell.pinIconSpacing),
                pinImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                pinImageView.widthAnchor.constraint(equalToConstant: ClipboardHistoryCell.pinIconSize),
                pinImageView.heightAnchor.constraint(equalToConstant: ClipboardHistoryCell.pinIconSize)
            ])
        }
        // 콘텐츠 설정이 만든 뷰가 아이콘 위에 올라가지 않도록 앞으로 둔다
        contentView.bringSubviewToFront(pinImageView)
    }
}

// MARK: - Supporting Views

/// 길게 누른 항목의 원문 전체를 스크롤로 보여주는 상세 뷰
private final class ClipboardHistoryDetailView: UIView {

    // MARK: - Properties

    var onClose: (() -> Void)?
    var onPaste: (() -> Void)?
    var onTogglePin: (() -> Void)?
    var onOpenURL: (() -> Void)?

    private static let pasteButtonBottomSpacing: CGFloat = 8

    // MARK: - UI Components

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))

    private let headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 4)
        stackView.isLayoutMarginsRelativeArrangement = true

        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "상세", bundle: SYKBDAssets.bundle)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label

        return label
    }()

    private lazy var pinButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onTogglePin?() })
    }()

    private lazy var closeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = String(localized: "닫기", bundle: SYKBDAssets.bundle)
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onClose?() })
    }()

    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        // 길게 누르거나 두 번 탭해 일부를 선택하고 시스템 메뉴로 복사한다. 편집은 막는다
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        return textView
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true

        return imageView
    }()

    private lazy var openURLTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOpenURLTap(_:)))

    private lazy var pasteButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "붙여넣기", bundle: SYKBDAssets.bundle)
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onPaste?() })
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        // 텍스트가 붙여넣기 버튼 뒤로 이어지되, 끝까지 스크롤하면 버튼 위로 올라오도록 버튼 높이만큼 여백을 둔다
        let bottomInset = pasteButton.bounds.height + ClipboardHistoryDetailView.pasteButtonBottomSpacing * 2
        textView.contentInset.bottom = bottomInset
        textView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    /// 선택 영역이 있을 때의 탭은 선택 해제로 쓰이므로 링크를 열지 않는다
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === openURLTapGesture else { return super.gestureRecognizerShouldBegin(gestureRecognizer) }
        return textView.selectedRange.length == 0
    }

    // MARK: - Internal Methods

    /// 고정 한도가 찼으면 미고정 항목의 고정 버튼을 숨긴다. 스와이프 액션과 같은 규칙이다.
    /// 항목 전체가 URL이면 본문을 링크처럼 그리고 탭을 받는다
    func update(text: String, isPinned: Bool, canPin: Bool, canOpenURL: Bool) {
        setImageMode(false)
        // 텍스트 전체가 URL이면 일반 링크처럼 파란 밑줄로 그리고, 본문 탭으로 연다
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.label
        ]
        if canOpenURL {
            attributes[.foregroundColor] = UIColor.link
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        textView.selectedRange = NSRange(location: 0, length: 0)
        textView.setContentOffset(.zero, animated: false)
        openURLTapGesture.isEnabled = canOpenURL
        pinButton.isHidden = !isPinned && !canPin
        pinButton.configuration?.title = isPinned
        ? String(localized: "고정 해제", bundle: SYKBDAssets.bundle)
        : String(localized: "고정", bundle: SYKBDAssets.bundle)
    }

    /// 이미지 항목. 본문 대신 미리보기를 보여주고, 버튼은 "복사"가 된다(키보드는 입력창에 이미지를 넣을 수 없다)
    /// 패널이 닫힐 때 디코드해 둔 미리보기를 놓는다. 다시 열면 원본에서 다시 디코드한다
    func releasePreviewImage() {
        imageView.image = nil
    }

    func update(image: UIImage?, isPinned: Bool, canPin: Bool) {
        setImageMode(true)
        imageView.image = image ?? UIImage(systemName: "photo")
        openURLTapGesture.isEnabled = false
        pinButton.isHidden = !isPinned && !canPin
        pinButton.configuration?.title = isPinned
        ? String(localized: "고정 해제", bundle: SYKBDAssets.bundle)
        : String(localized: "고정", bundle: SYKBDAssets.bundle)
    }
}

// MARK: - UI Methods

private extension ClipboardHistoryDetailView {
    /// 브라우저가 열리면 키보드가 내려가므로 글자가 있는 영역을 탭했을 때만 연다. 빈 여백 탭은 무시한다
    @objc func handleOpenURLTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: textView)
        let inset = textView.textContainerInset
        let usedRect = textView.layoutManager.usedRect(for: textView.textContainer)
            .offsetBy(dx: inset.left, dy: inset.top)
        guard usedRect.contains(point) else { return }
        onOpenURL?()
    }

    func setupUI() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        [titleLabel, spacer, pinButton, closeButton].forEach { headerStackView.addArrangedSubview($0) }
        openURLTapGesture.delegate = self
        textView.addGestureRecognizer(openURLTapGesture)
        [blurView, headerStackView, textView, imageView, pasteButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: self.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            headerStackView.topAnchor.constraint(equalTo: self.topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            headerStackView.heightAnchor.constraint(equalToConstant: 36),

            textView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 4),
            textView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4),
            textView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 4),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            imageView.bottomAnchor.constraint(
                equalTo: pasteButton.topAnchor,
                constant: -ClipboardHistoryDetailView.pasteButtonBottomSpacing
            ),

            pasteButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            pasteButton.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -ClipboardHistoryDetailView.pasteButtonBottomSpacing
            )
        ])
    }

    func setImageMode(_ isImage: Bool) {
        imageView.isHidden = !isImage
        textView.isHidden = isImage
        if !isImage { imageView.image = nil }
        pasteButton.configuration?.title = isImage
        ? String(localized: "복사", bundle: SYKBDAssets.bundle)
        : String(localized: "붙여넣기", bundle: SYKBDAssets.bundle)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ClipboardHistoryDetailView: UIGestureRecognizerDelegate {
    /// 본문 선택용 텍스트 뷰 제스처(길게 누르기·두 번 탭)를 막지 않는다
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return gestureRecognizer === openURLTapGesture
    }
}

// MARK: - Delete Confirmation

/// 고정 항목이 포함된 삭제를 패널 안에서 확인받는 뷰. 앱의 알림과 같은 문구를 쓴다
private final class ClipboardHistoryDeleteConfirmView: UIView {

    // MARK: - Properties

    var onCancel: (() -> Void)?
    var onConfirm: (() -> Void)?

    // MARK: - UI Components

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()

    private lazy var cancelButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.title = String(localized: "취소", bundle: SYKBDAssets.bundle)
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onCancel?() })
    }()

    private lazy var confirmButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "삭제", bundle: SYKBDAssets.bundle)
        config.baseBackgroundColor = .systemRed
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onConfirm?() })
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8

        return stackView
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12

        return stackView
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Methods

    /// 전부 고정이면 고정 항목 개수를, 미고정이 섞였으면 전체 개수를 제목에 쓰고 고정 개수는 설명에 쓴다
    func update(pinnedCount: Int, totalCount: Int) {
        if pinnedCount == totalCount {
            titleLabel.text = String(localized: "고정 항목 \(pinnedCount)개를 삭제할까요?", bundle: SYKBDAssets.bundle)
            messageLabel.text = String(localized: "삭제한 항목은 복구할 수 없습니다.", bundle: SYKBDAssets.bundle)
        } else {
            titleLabel.text = String(localized: "항목 \(totalCount)개를 삭제할까요?", bundle: SYKBDAssets.bundle)
            messageLabel.text = String(
                localized: "고정 항목 \(pinnedCount)개가 포함되어 있습니다.\n삭제한 항목은 복구할 수 없습니다.",
                bundle: SYKBDAssets.bundle
            )
        }
    }
}

// MARK: - UI Methods

private extension ClipboardHistoryDeleteConfirmView {
    func setupUI() {
        [cancelButton, confirmButton].forEach { buttonStackView.addArrangedSubview($0) }
        [titleLabel, messageLabel, buttonStackView].forEach { contentStackView.addArrangedSubview($0) }
        contentStackView.setCustomSpacing(16, after: messageLabel)
        [blurView, contentStackView].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: self.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            contentStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -16)
        ])
    }
}

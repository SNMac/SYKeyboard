//
//  ClipboardHistoryPanelView.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/8/26.
//

import UIKit

import SYKeyboardAssets

/// `ClipboardHistoryPanelView`의 사용자 상호작용을 수신하는 델리게이트
protocol ClipboardHistoryPanelDelegate: AnyObject {
    /// 항목을 탭하거나 상세 뷰에서 붙여넣기를 눌렀을 때 호출됩니다.
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didSelectItemAt index: Int)
    /// 스와이프 삭제 또는 편집 모드에서 일부 항목을 삭제했을 때 호출됩니다. 인덱스는 오름차순입니다.
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didDeleteItemsAt indices: [Int])
    /// 편집 모드에서 전체 선택 후 삭제했을 때 호출됩니다.
    func clipboardPanelDidDeleteAll(_ panel: ClipboardHistoryPanelView)
    /// leading swipe 또는 상세 뷰에서 항목의 고정을 토글했을 때 호출됩니다.
    func clipboardPanel(_ panel: ClipboardHistoryPanelView, didTogglePinAt index: Int)
}

/// 클립보드 기록 목록을 자판 영역에 표시하는 패널
///
/// 저장소를 모르는 표시 전용 뷰다. 상태는 `configure(state:)`로 받고 결정은 델리게이트가 한다.
///
/// ## 동작
/// - 평소: 행 탭은 붙여넣기, trailing swipe는 개별 삭제, leading swipe는 고정/해제, 길게 누르기는 원문 상세 뷰
/// - 편집 모드(`UITableView.isEditing`): 행 탭은 선택 토글, "전체 선택"·"n개 삭제"·"완료"
final class ClipboardHistoryPanelView: UIView {

    enum State: Equatable {
        case fullAccessRequired
        case empty
        case items([ClipboardHistoryItem])
    }

    // MARK: - Properties

    weak var delegate: ClipboardHistoryPanelDelegate?

    /// 현재 표시 중인 항목(최신순). 델리게이트 인덱스는 이 배열 기준이다
    private(set) var items: [ClipboardHistoryItem] = []

    private var detailIndex: Int?

    private static let cellIdentifier = "ClipboardHistoryCell"
    /// 스와이프 액션은 색 배경 위에 뜨므로 채운 변형을 쓴다
    private static let pinActionSymbolName = "pin.fill"
    private static let unpinActionSymbolName = "pin.slash.fill"
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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "클립보드 기록", bundle: .sykeyboardCore)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label

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
        title: String(localized: "편집", bundle: .sykeyboardCore)
    ) { [weak self] in
        self?.beginItemEditing()
    }

    private lazy var doneButton = makeHeaderButton(
        title: String(localized: "완료", bundle: .sykeyboardCore)
    ) { [weak self] in
        self?.endItemEditing()
    }

    /// 테스트에서 `UITableViewDelegate` 메서드를 직접 호출할 수 있도록 internal로 둔다
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ClipboardHistoryPanelView.cellIdentifier)

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

    private lazy var detailView: ClipboardHistoryDetailView = {
        let view = ClipboardHistoryDetailView()
        view.isHidden = true
        view.onClose = { [weak self] in self?.hideDetail() }
        view.onPaste = { [weak self] in
            guard let self, let index = self.detailIndex else { return }
            // 붙여넣기 직후 패널이 닫히므로 상세 뷰는 즉시 숨긴다
            self.hideDetail(animated: false)
            self.delegate?.clipboardPanel(self, didSelectItemAt: index)
        }
        view.onTogglePin = { [weak self] in
            guard let self, let index = self.detailIndex else { return }
            self.delegate?.clipboardPanel(self, didTogglePinAt: index)
        }

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
    func configure(state: State) {
        hideDetail()
        switch state {
        case .fullAccessRequired:
            items = []
            messageLabel.text = String(localized: "전체 접근 허용이 필요합니다", bundle: .sykeyboardCore)
        case .empty:
            items = []
            messageLabel.text = String(localized: "복사한 텍스트가 여기에 표시됩니다", bundle: .sykeyboardCore)
        case .items(let newItems):
            items = newItems
        }
        messageLabel.isHidden = !items.isEmpty
        tableView.isHidden = items.isEmpty
        if items.isEmpty { endItemEditing() }
        tableView.reloadData()
        updateHeader()
    }

    /// 편집 모드와 상세 뷰를 닫고 스크롤을 맨 위로 되돌립니다. 패널을 닫을 때 호출합니다.
    func resetPresentation() {
        hideDetail(animated: false)
        endItemEditing()
        tableView.setContentOffset(.zero, animated: false)
    }

    // 헤더 버튼 동작. 테스트에서 직접 호출할 수 있도록 internal로 둔다

    func beginItemEditing() {
        guard !items.isEmpty, !tableView.isEditing else { return }
        tableView.setEditing(true, animated: true)
        updateHeader()
    }

    func endItemEditing() {
        guard tableView.isEditing else { return }
        tableView.setEditing(false, animated: true)
        updateHeader()
    }

    func toggleSelectAll() {
        guard tableView.isEditing else { return }
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
        guard tableView.isEditing else { return }
        let indices = (tableView.indexPathsForSelectedRows ?? []).map(\.row).sorted()
        guard !indices.isEmpty else { return }

        if indices.count == items.count {
            delegate?.clipboardPanelDidDeleteAll(self)
        } else {
            delegate?.clipboardPanel(self, didDeleteItemsAt: indices)
        }
    }
}

// MARK: - UI Methods

private extension ClipboardHistoryPanelView {
    func setupUI() {
        setStyles()
        setHierarchy()
        setConstraints()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        )
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
        [headerStackView, tableView, messageLabel, detailView].forEach { self.addSubview($0) }
    }

    func setConstraints() {
        [headerStackView, tableView, messageLabel, detailView].forEach {
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

            detailView.topAnchor.constraint(equalTo: self.topAnchor),
            detailView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            detailView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            detailView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

// MARK: - Private Methods

private extension ClipboardHistoryPanelView {
    var isAllSelected: Bool {
        !items.isEmpty && (tableView.indexPathsForSelectedRows?.count ?? 0) == items.count
    }

    func updateHeader() {
        let isEditing = tableView.isEditing
        titleLabel.isHidden = isEditing
        editButton.isHidden = isEditing || items.isEmpty
        selectAllButton.isHidden = !isEditing
        deleteButton.isHidden = !isEditing
        doneButton.isHidden = !isEditing

        let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
        selectAllButton.configuration?.title = isAllSelected
        ? String(localized: "선택 해제", bundle: .sykeyboardCore)
        : String(localized: "전체 선택", bundle: .sykeyboardCore)
        deleteButton.configuration?.title = String(localized: "\(selectedCount)개 삭제", bundle: .sykeyboardCore)
        deleteButton.isEnabled = selectedCount > 0
    }

    func makeHeaderButton(title: String, handler: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        let button = UIButton(configuration: config, primaryAction: UIAction { _ in handler() })
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        return button
    }

    func showDetail(at index: Int) {
        guard items.indices.contains(index) else { return }
        detailIndex = index
        detailView.update(
            text: items[index].text,
            isPinned: items[index].isPinned,
            canPin: ClipboardHistoryPolicy.canPin(items)
        )
        setDetailHidden(false, animated: true)
    }

    /// 패널을 닫을 때는 자판 복귀와 겹치지 않도록 애니메이션 없이 숨긴다
    func hideDetail(animated: Bool = true) {
        detailIndex = nil
        setDetailHidden(true, animated: animated)
    }

    func setDetailHidden(_ isHidden: Bool, animated: Bool) {
        guard detailView.isHidden != isHidden else { return }
        guard animated else {
            detailView.isHidden = isHidden
            return
        }
        UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
            self.detailView.isHidden = isHidden
        }
    }

    func makePinAccessoryView() -> UIView {
        let imageView = UIImageView(image: UIImage(systemName: ClipboardHistoryPanelView.pinnedAccessorySymbolName))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: 16, height: 16)

        return imageView
    }

    @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began, !tableView.isEditing else { return }
        let point = recognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        FeedbackManager.shared.playHaptic()
        showDetail(at: indexPath.row)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ClipboardHistoryPanelView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClipboardHistoryPanelView.cellIdentifier, for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = items[indexPath.row].text
        content.textProperties.font = .systemFont(ofSize: 15)
        content.textProperties.numberOfLines = 2
        content.textProperties.lineBreakMode = .byTruncatingTail
        cell.contentConfiguration = content
        cell.accessoryView = items[indexPath.row].isPinned ? makePinAccessoryView() : nil
        cell.backgroundColor = .clear
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .suggestionButtonPressed
        cell.selectedBackgroundView = selectedBackgroundView

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateHeader()
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
        FeedbackManager.shared.playHaptic()
        delegate?.clipboardPanel(self, didSelectItemAt: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing { updateHeader() }
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
            ? String(localized: "고정 해제", bundle: .sykeyboardCore)
            : String(localized: "고정", bundle: .sykeyboardCore)
        ) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            self.delegate?.clipboardPanel(self, didTogglePinAt: indexPath.row)
            // 삭제와 같은 이유로 목록 갱신은 소유자의 configure()에 맡긴다
            completion(false)
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
            title: String(localized: "삭제", bundle: .sykeyboardCore)
        ) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            self.delegate?.clipboardPanel(self, didDeleteItemsAt: [indexPath.row])
            // 목록 갱신은 소유자의 configure()/reloadData() 단일 경로로만 일어나므로
            // UIKit이 자체 삭제 애니메이션을 수행하지 않도록 completion(false)를 전달한다
            completion(false)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - Supporting Views

/// 길게 누른 항목의 원문 전체를 스크롤로 보여주는 상세 뷰
private final class ClipboardHistoryDetailView: UIView {

    // MARK: - Properties

    var onClose: (() -> Void)?
    var onPaste: (() -> Void)?
    var onTogglePin: (() -> Void)?

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
        label.text = String(localized: "원문", bundle: .sykeyboardCore)
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
        config.title = String(localized: "닫기", bundle: .sykeyboardCore)
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)

        return UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in self?.onClose?() })
    }()

    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        return textView
    }()

    private lazy var pasteButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "붙여넣기", bundle: .sykeyboardCore)
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

    // MARK: - Internal Methods

    /// 고정 한도가 찼으면 미고정 항목의 고정 버튼을 숨긴다. 스와이프 액션과 같은 규칙이다
    func update(text: String, isPinned: Bool, canPin: Bool) {
        textView.text = text
        textView.setContentOffset(.zero, animated: false)
        pinButton.isHidden = !isPinned && !canPin
        pinButton.configuration?.title = isPinned
        ? String(localized: "고정 해제", bundle: .sykeyboardCore)
        : String(localized: "고정", bundle: .sykeyboardCore)
    }
}

// MARK: - UI Methods

private extension ClipboardHistoryDetailView {
    func setupUI() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        [titleLabel, spacer, pinButton, closeButton].forEach { headerStackView.addArrangedSubview($0) }
        [blurView, headerStackView, textView, pasteButton].forEach {
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
            textView.bottomAnchor.constraint(equalTo: pasteButton.topAnchor, constant: -4),

            pasteButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            pasteButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8)
        ])
    }
}

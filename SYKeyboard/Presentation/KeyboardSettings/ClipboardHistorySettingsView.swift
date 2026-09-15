//
//  ClipboardHistorySettingsView.swift
//  SYKeyboard
//
//  Created by Claude on 9/8/26.
//

import SwiftUI

import SYKeyboardCore

/// 키보드 클립보드 패널과 같은 목록을 앱에서 관리하는 화면. 직접 입력한 텍스트를 고정 항목으로 추가할 수 있다
struct ClipboardHistorySettingsView: View {

    // MARK: - Properties

    @Environment(\.scenePhase) private var scenePhase

    private let store = ClipboardHistoryStore()

    /// 저장 순서 그대로(고정 최신순 → 미고정 최신순). id는 정책상 중복이 없다.
    /// 화면 전환 중 빈 상태와 편집 버튼 없는 툴바가 먼저 보이지 않도록 첫 렌더링 전에 읽는다
    @State private var items: [ClipboardHistoryItem]
    @State private var selection = Set<String>()
    @State private var editMode: EditMode = .inactive
    @State private var isAddSheetPresented = false
    @State private var newText = ""
    /// 원문 시트에 넘기는 항목. `sheet(item:)`은 첫 표시에 항목을 직접 받고 닫힘 애니메이션 동안 내용을 유지한다.
    /// `id`는 열 때의 항목 id로 고정해 편집 저장으로 텍스트(= 항목 id)가 바뀌어도 시트가 닫혔다 다시 뜨지 않게 한다
    @State private var detailPresentation: DetailPresentation?
    /// 시트가 열린 사이 키보드가 그 항목을 지운 경우 시트 안에 바로 띄우는 알림. 확인하면 시트가 닫힌다.
    /// 시트는 알림을 띄우는 시점에 편집을 끝내, 알림이 닫히며 편집기가 포커스를 되찾아 키보드가 시트를 밀어 올리는 튐을 막는다
    @State private var isDeletedItemAlertPresented = false
    /// 고정 항목이 포함돼 확인 알림을 기다리는 삭제 대상
    @State private var pendingDeletion: PendingDeletion?

    /// 확인 시트를 어디에 붙일지. 스와이프 삭제는 그 행에서, 편집 모드 삭제는 하단 바 삭제 버튼에서 뜬다
    fileprivate enum DeletionSource: Equatable {
        case row(String)
        case toolbar
    }

    fileprivate struct PendingDeletion {
        let items: [ClipboardHistoryItem]
        let source: DeletionSource
    }
    /// 시트 문구에 쓰는 개수. 시트가 닫히는 동안 `pendingDeletion`이 먼저 비워져도 제목이 "0개"로 바뀌지 않게 따로 둔다
    @State private var deletionCounts = (pinned: 0, total: 0)

    // MARK: - Initializer

    init() {
        _items = State(initialValue: store?.load() ?? [])
    }

    private var canPin: Bool { ClipboardHistoryPolicy.canPin(items) }
    private var pinnedCount: Int { items.filter(\.isPinned).count }
    private var recentCount: Int { items.count - pinnedCount }
    private var isAllSelected: Bool { !items.isEmpty && selection.count == items.count }
    private var selectedItems: [ClipboardHistoryItem] { items.filter { selection.contains($0.id) } }
    private var pinBatch: ClipboardHistoryPolicy.PinBatch {
        ClipboardHistoryPolicy.pinBatch(selectedIDs: selection, in: items)
    }
    /// iOS 26 미만 하단 바에서 고정·삭제 버튼 사이 간격. 묶은 버튼마다 좌우 여백이 붙어 이 값보다 넓게 보이므로, 사진 앱 선택 모드의 휴지통·더보기 중심 거리(약 43pt)에 맞춘 값이다
    private static let legacyBottomBarItemSpacing: CGFloat = 3
    /// iOS 26 미만에서 고정·삭제를 묶은 항목의 오른쪽 보정. 묶은 버튼은 최소 탭 크기 안에서 아이콘이 가운데 놓여
    /// 휴지통 오른쪽에 빈 공간이 생기므로(사진 앱 대비 약 7.6pt), 탭 영역은 그대로 두고 아이콘 위치만 사진 앱에 맞춘다
    private static let legacyBottomBarTrailingAdjustment: CGFloat = -8

    // MARK: - Content

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    VStack(spacing: 8) {
                        Text("복사한 텍스트나 이미지가 여기에 표시됩니다.")
                        limitDescription
                        imageLimitDescription
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                } else {
                    historyList
                }
            }
            // 편집 모드에서 선택이 있으면 제목이 선택 수를 보여준다
            .navigationTitle(
                editMode.isEditing && !selection.isEmpty
                ? Text("\(selection.count)개 선택")
                : Text("클립보드 기록")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            // iOS 16은 bottomBar 항목을 나중에 추가하면 바가 안 뜨므로 항목은 두고 표시만 토글한다
            .toolbar(editMode.isEditing ? .visible : .hidden, for: .bottomBar)
            // 편집 버튼과 List가 같은 편집 상태를 보도록 toolbar 바깥에 둔다
            .environment(\.editMode, $editMode)
            // 시트가 떠 있는 동안 키보드가 기록을 바꿀 수 있으므로 닫힐 때 다시 읽는다
            .sheet(isPresented: $isAddSheetPresented, onDismiss: synchronizeAndReload) { addSheet }
            .sheet(item: $detailPresentation, onDismiss: { isDeletedItemAlertPresented = false }) { detailSheet(for: $0.item) }
            // 스와이프·편집 모드 삭제는 사용자가 의도한 동작이므로 HIG대로 알림이 아니라 action sheet로 확인한다. 취소는 시스템이 붙인다
            .onAppear(perform: synchronizeAndReload)
            .onChange(of: scenePhase) { phase in
                if phase == .active { synchronizeAndReload() }
            }
            // 앱 활성화 동기화(SYKeyboardApp)가 먼저 changeCount를 소비하면 이 화면의 동기화는 건너뛰므로,
            // 백그라운드 저장이 끝난 이미지는 알림으로 받아 목록을 다시 읽는다
            .onReceive(NotificationCenter.default.publisher(for: ClipboardHistoryPasteboardSynchronizer.didRecordImageNotification)) { _ in
                reload()
            }
            // 상세 시트에서 본문 일부를 복사하는 등 앱 안에서 pasteboard가 바뀌면 목록에 바로 반영한다. 열린 시트는 reload가 유지한다.
            // 시트의 "복사" 버튼은 쓴 직후 changeCount를 맞추므로, 그 갱신이 끝난 다음 runloop에서 확인해 중복 기록하지 않는다
            .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
                DispatchQueue.main.async { synchronizeAndReload() }
            }
            .requestReviewOnDetailSettingsReturn()
        }
    }
}

// MARK: - UI Components

private extension ClipboardHistorySettingsView {
    var historyList: some View {
        List(selection: $selection) {
            Section {
                itemRows
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("고정 \(pinnedCount)/\(ClipboardHistoryPolicy.maxPinnedCount) · 최근 \(recentCount)/\(ClipboardHistoryPolicy.maxItemCount)")
                        .monospacedDigit()
                    limitDescription
                    imageLimitDescription
                }
            }
        }
    }

    /// 개수 제한 규칙 안내. 목록 footer와 빈 상태에서 함께 쓴다
    var limitDescription: some View {
        Text("고정 항목은 직접 삭제할 때까지 유지되고, 최근 항목은 \(ClipboardHistoryPolicy.maxItemCount)개를 넘으면 오래된 것부터 지워집니다.")
    }

    /// 이미지 저장 한도와 토글 OFF 규칙 안내. 목록 최하단(footer)과 빈 상태에 토글과 무관하게 항상 보인다
    var imageLimitDescription: some View {
        Text("이미지는 한 장에 \(ClipboardImagePolicy.maxByteSize / (1_024 * 1_024)) MB · \(ClipboardImagePolicy.maxPixelCount / 1_000_000) MP까지 저장합니다. '이미지도 기록'을 끄면 새로 복사한 이미지는 저장하지 않으며, 이미 저장된 이미지는 여기서 삭제할 수 있습니다.")
    }

    var itemRows: some View {
        ForEach(items) { item in
            // 행 전체를 버튼으로 둔다. 기본(automatic) 스타일은 List 행 강조를 쓰며 시트를 띄우는 탭 뒤에 강조가 남는 일이 있어,
            // 누르는 동안 라벨만 살짝 흐려지는 plain 스타일을 쓴다. 라벨은 contentShape(Rectangle())라 행 내용 영역 전체가 터치 범위다.
            // 행 구조는 편집 모드와 무관하게 같아야 선택 UI가 들어오는 전환이 매끄럽다
            Button { presentDetail(item) } label: { row(for: item) }
                .buttonStyle(.plain)
                // 편집 모드에서는 탭이 List 행 선택으로 가도록 버튼이 터치를 가로채지 않게 한다
                .allowsHitTesting(!editMode.isEditing)
                .contentShape(Rectangle())
                // 편집 모드에서 길게 누르면 선택을 바꾸지 않고 원본 시트를 연다. 평소에는 버튼이 처리하므로 아무것도 하지 않는다
                .simultaneousGesture(
                    LongPressGesture().onEnded { _ in
                        if editMode.isEditing { presentDetail(item) }
                    }
                )
                // 보조 기술에서는 길게 누르기 대신 이 액션으로 편집 모드에서도 상세를 연다
                .accessibilityAction(named: Text("상세 보기")) { presentDetail(item) }
                .swipeActions(edge: .leading) {
                    if item.isPinned || canPin {
                        Button {
                            togglePins(selectedIDs: [item.id])
                        } label: {
                            Label(
                                item.isPinned ? "고정 해제" : "고정",
                                systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill"
                            )
                        }
                        .tint(.orange)
                    }
                }
                .swipeActions(edge: .trailing) {
                    // destructive role은 누르는 순간 행 제거 애니메이션을 시작해 행에 붙인 확인 시트를 닫아 버린다.
                    // 삭제 여부는 확인 시트가 결정하므로 role 없이 색만 준다
                    Button {
                        requestRemove([item], source: .row(item.id))
                    } label: {
                        Label("삭제", systemImage: "trash.fill")
                    }
                    .tint(.red)
                }
                // 스와이프 삭제의 확인 시트는 그 행에 붙여, 지원하는 OS에서는 행 근처에서 뜬다.
                // 행마다 하나씩 설치되지만 한 번에 하나만 열리고, 표시 시점에 조건부로 붙이면 SwiftUI가 띄우지 못한다
                .deletionConfirmation(self, source: .row(item.id))
        }
    }

    func row(for item: ClipboardHistoryItem) -> some View {
        HStack {
            switch item.content {
            case .text(let text):
                Text(text)
                    .lineLimit(2)
            case .image(let reference):
                thumbnail(for: reference)
                VStack(alignment: .leading, spacing: 2) {
                    Text("이미지")
                    Text(reference.sizeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if item.isPinned {
                Image(systemName: "pin.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }

    /// 썸네일 파일만 읽는다. 앱 프로세스는 메모리 여유가 있어 캐시 없이 동기 로드한다
    @ViewBuilder
    func thumbnail(for reference: ClipboardImageReference) -> some View {
        if let url = store?.imageStore?.thumbnailURL(for: reference),
           let image = UIImage(contentsOfFile: url.path) {
            // 키보드 패널의 `UIListContentConfiguration`(maximumSize 44×44, aspect fit)과 같은 비율로 보이도록
            // 원본 비율을 유지하고 44×44 안에 맞춘다. 자르지 않는다
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(width: 44, height: 44)
        } else {
            Image(systemName: "photo")
                .frame(width: 44, height: 44)
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                newText = ""
                isAddSheetPresented = true
            } label: {
                Label("추가", systemImage: "plus")
            }
            .disabled(!canPin)
            if !items.isEmpty {
                Button {
                    withAnimation {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                    selection.removeAll()
                } label: {
                    // 두 문구의 폭이 달라 버튼 위치가 흔들리지 않도록 넓은 쪽으로 폭을 고정한다
                    ZStack {
                        Text("선택").hidden()
                        Text("완료").fontWeight(.semibold).hidden()
                        Text(editMode.isEditing ? "완료" : "선택")
                            .fontWeight(editMode.isEditing ? .semibold : .regular)
                    }
                }
            }
        }
        // 툴바의 Label은 아이콘만 보이고 제목은 접근성에 쓰인다. 개수는 제목의 "n개 선택"이 보여준다
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                selection = isAllSelected ? [] : Set(items.map(\.id))
            } label: {
                Label(
                    isAllSelected ? "선택 해제" : "전체 선택",
                    systemImage: isAllSelected ? "checklist.unchecked" : "checklist.checked"
                )
            }
            Spacer()
            if #available(iOS 26, *) {
                bottomBarPinButton
                bottomBarDeleteButton
            } else {
                // iOS 26 미만 SwiftUI 하단 바는 붙은 버튼 사이 고정 간격 API(`ToolbarSpacer`)가 없고 버튼에 준 여백도 무시한다.
                // 두 버튼을 한 항목으로 묶어 간격을 직접 준다. 묶으면 툴바의 아이콘 전용 표시가 풀리므로 다시 지정한다
                HStack(spacing: Self.legacyBottomBarItemSpacing) {
                    bottomBarPinButton
                    bottomBarDeleteButton
                }
                .labelStyle(.iconOnly)
                .padding(.trailing, Self.legacyBottomBarTrailingAdjustment)
            }
        }
    }

    var bottomBarPinButton: some View {
        Button {
            togglePins(selectedIDs: selection)
            finishEditing()
        } label: {
            Label(
                pinBatch.isUnpinning ? "\(pinBatch.targets.count)개 고정 해제" : "\(pinBatch.targets.count)개 고정",
                systemImage: pinBatch.isUnpinning ? "pin.slash" : "pin"
            )
        }
        .disabled(!pinBatch.isAllowed)
    }

    var bottomBarDeleteButton: some View {
        Button(role: .destructive) {
            requestRemove(selectedItems, source: .toolbar)
        } label: {
            Label("\(selection.count)개 삭제", systemImage: "trash")
        }
        .disabled(selection.isEmpty)
        // 편집 모드 삭제의 확인 시트는 삭제 버튼에 붙인다
        .deletionConfirmation(self, source: .toolbar)
    }

    var addSheet: some View {
        NavigationStack {
            TextEditor(text: $newText)
                .padding(.horizontal)
                .navigationTitle("고정 항목 추가")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { isAddSheetPresented = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") { saveNewItem() }
                            .disabled(!canSaveNewItem)
                    }
                }
        }
    }

    var pendingDeletionItems: [ClipboardHistoryItem]? { pendingDeletion?.items }

    /// 전부 고정이면 고정 항목 개수를, 미고정이 섞였으면 전체 개수를 제목에 쓰고 고정 개수는 설명에 쓴다
    var deletionTitle: Text {
        deletionCounts.pinned == deletionCounts.total
        ? Text("고정 항목 \(deletionCounts.pinned)개를 삭제할까요?")
        : Text("항목 \(deletionCounts.total)개를 삭제할까요?")
    }

    var deletionMessage: Text {
        deletionCounts.pinned == deletionCounts.total
        ? Text("삭제한 항목은 복구할 수 없습니다.")
        : Text("고정 항목 \(deletionCounts.pinned)개가 포함되어 있습니다. 삭제한 항목은 복구할 수 없습니다.")
    }

    /// 해당 출처의 확인 시트 표시 여부. 닫히면 대기 중인 삭제를 버린다
    func isDeletionPresented(for source: DeletionSource) -> Binding<Bool> {
        Binding(
            get: { pendingDeletion?.source == source },
            set: { isPresented in
                if !isPresented, pendingDeletion?.source == source { pendingDeletion = nil }
            }
        )
    }

    var canSaveNewItem: Bool {
        !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && newText.count <= ClipboardHistoryPolicy.maxTextLength
        && canPin
    }
}

// MARK: - Private Methods

private extension ClipboardHistorySettingsView {
    /// 화면에 들어오거나 돌아올 때. 앱 활성화 알림과 순서가 보장되지 않으므로 여기서도 동기화한다
    func synchronizeAndReload() {
        if let store, UserDefaultsManager.shared.isClipboardHistoryEnabled {
            ClipboardHistoryPasteboardSynchronizer.synchronizeIfNeeded(
                store: store,
                decodeMemoryBudget: ClipboardImagePolicy.appDecodeMemoryBudget,
                retriesBudgetSkipped: true
            )
        }
        reload()
    }

    /// 파일을 다시 읽는다. 조작 경로에서는 동기화하지 않아 새 항목이 끼어들며 대상이 밀려나지 않게 한다
    func reload(checksPresentedItem: Bool = true) {
        // SwiftUI가 id(텍스트) 차이로 행 삽입·삭제·이동을 애니메이션한다
        withAnimation {
            items = store?.load() ?? []
        }
        selection = selection.intersection(items.map(\.id))
        if items.isEmpty { editMode = .inactive }
        // 시트를 띄운 행이 다시 읽는 사이 사라졌으면 대기 중인 삭제도 버린다. 같은 id가 돌아올 때 시트가 저절로 뜨지 않게 한다
        if case .row(let id)? = pendingDeletion?.source, !items.contains(where: { $0.id == id }) {
            pendingDeletion = nil
        }
        // 시트가 열린 사이 키보드가 바꾼 고정 상태 등을 시트에도 반영한다. 항목이 사라졌으면 시트 안에 삭제 알림을 띄운다.
        // 편집 저장은 id(텍스트)가 바뀌므로 그 경로는 호출자가 새 id로 직접 갱신한다
        if checksPresentedItem, let presented = detailPresentation {
            if items.contains(where: { $0.id == presented.item.id }) {
                refreshDetailItem(id: presented.item.id)
            } else {
                isDeletedItemAlertPresented = true
            }
        }
    }

    /// 편집 모드 하단 바의 고정·삭제가 끝나면 일반 모드로 돌아간다. "완료" 버튼과 같은 동작이다
    func finishEditing() {
        withAnimation { editMode = .inactive }
        selection.removeAll()
    }

    /// 저장소가 파일을 다시 읽어 판단하므로 키보드가 그사이 바꾼 내용과 어긋나지 않는다
    func togglePins(selectedIDs: Set<String>) {
        store?.togglePins(selectedIDs: selectedIDs)
        reload()
    }

    /// 고정 항목이 섞여 있으면 알림으로 확인받고, 아니면 바로 지운다
    func requestRemove(_ removing: [ClipboardHistoryItem], source: DeletionSource) {
        if removing.contains(where: \.isPinned) {
            deletionCounts = (removing.filter(\.isPinned).count, removing.count)
            pendingDeletion = PendingDeletion(items: removing, source: source)
        } else {
            remove(removing, source: source)
        }
    }

    /// 저장소가 id로 지우므로 파일을 미리 다시 읽을 필요가 없다. 편집 모드 하단 바에서 지웠으면 일반 모드로 돌아간다
    func remove(_ removing: [ClipboardHistoryItem], source: DeletionSource) {
        guard !removing.isEmpty else { return }
        store?.remove(ids: Set(removing.map(\.id)))
        if source == .toolbar { finishEditing() }
        reload()
    }

    /// 원문 시트에서 편집한 내용을 저장하고, 시트가 새 내용을 보이도록 표시 항목을 바꾼다
    /// 편집한 내용을 저장한다. 시트가 열린 사이 키보드가 그 항목을 지웠으면 정책이 저장을 거부하므로,
    /// 다시 읽은 목록에 새 텍스트가 없으면 실패를 돌려준다(시트가 알림을 띄우고 닫는다)
    func replaceText(of item: ClipboardHistoryItem, with newText: String) -> Bool {
        guard let oldText = item.text, store?.replaceText(oldText, with: newText) == true else {
            // 시트가 열린 사이 키보드가 항목을 지운 경우(앱이 활성인 채라 재조회 알림이 없었음)
            isDeletedItemAlertPresented = true
            return false
        }
        reload(checksPresentedItem: false)
        refreshDetailItem(id: newText)
        return true
    }

    func presentDetail(_ item: ClipboardHistoryItem) {
        detailPresentation = DetailPresentation(id: item.id, item: item)
    }

    func detailSheet(for item: ClipboardHistoryItem) -> some View {
        ClipboardHistoryDetailView(
            item: item,
            imageStore: store?.imageStore,
            canPin: canPin,
            // 저장 가능 여부만 보므로 시각은 결과에 영향이 없다. body마다 Date()를 만들지 않도록 고정값을 넘긴다.
            // 앱이 활성인 채로 키보드가 항목을 지우면 items는 아직 그 항목을 들고 있어 버튼이 유지되고, 저장 시 store의 거부가 알림으로 이어진다
            canSave: { newText in item.text.flatMap { ClipboardHistoryPolicy.replacingText($0, with: newText, in: items, now: .distantPast) } != nil },
            onTogglePin: { togglePinFromDetail(item) },
            onCopy: { copyFromDetail(item) },
            onSave: { replaceText(of: item, with: $0) },
            isItemDeletedAlertPresented: $isDeletedItemAlertPresented
        )
        // 이미지는 스크롤 없이 한눈에 보이도록 가장 큰 시트 하나만 쓴다. 텍스트는 하프 시트에서 시작한다
        .presentationDetents(item.image != nil ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }

    /// 고정을 바꾸면 시트를 닫는다. 목록에서 행이 고정 영역으로 옮겨지는(또는 빠지는) 것이 결과 피드백이다.
    /// 그사이 키보드가 고정 한도를 채웠으면 정책이 변경을 거부해 변화 없이 닫힌다
    func togglePinFromDetail(_ item: ClipboardHistoryItem) {
        store?.togglePins(selectedIDs: [item.id])
        reload(checksPresentedItem: false)
        detailPresentation = nil
    }

    /// 복사한 항목을 최근 복사한 것처럼 목록 맨 위로 올리고 시트를 닫는다. 맨 위로 올라간 행이 결과 피드백이다.
    /// 동기화가 방금 쓴 pasteboard를 다시 읽지 않도록 changeCount를 맞춘다. 이미지는 원본 바이트를 그대로 pasteboard에 놓는다.
    /// 파일이 없으면 아무것도 하지 않는다
    func copyFromDetail(_ item: ClipboardHistoryItem) {
        let pasteboard = UIPasteboard.general
        switch item.content {
        case .text(let text):
            pasteboard.string = text
        case .image(let reference):
            guard let url = store?.imageStore?.originalURL(for: reference),
                  let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return }
            pasteboard.setData(data, forPasteboardType: reference.typeIdentifier)
        }
        UserDefaultsManager.shared.lastSeenPasteboardChangeCount = pasteboard.changeCount
        store?.record(item.content)
        reload(checksPresentedItem: false)
        detailPresentation = nil
    }

    /// 시트가 열린 채로 저장소가 바뀌면 표시 항목을 새 값으로 바꾼다. 항목이 사라졌으면 그대로 둔다
    func refreshDetailItem(id: String) {
        if let updated = items.first(where: { $0.id == id }) { detailPresentation?.item = updated }
    }

    func saveNewItem() {
        store?.recordPinned(newText)
        isAddSheetPresented = false
        reload()
    }
}

// MARK: - Detail Presentation

/// 원문 시트의 표시 단위. `id`는 시트를 연 시점의 항목 id로 고정한다
private struct DetailPresentation: Identifiable {
    let id: String
    var item: ClipboardHistoryItem
}

// MARK: - Deletion Confirmation

private extension View {
    /// 고정 항목이 섞인 삭제의 확인 시트. `source`에 해당하는 요청일 때만 이 뷰에서 뜬다
    func deletionConfirmation(
        _ screen: ClipboardHistorySettingsView,
        source: ClipboardHistorySettingsView.DeletionSource
    ) -> some View {
        confirmationDialog(
            screen.deletionTitle,
            isPresented: screen.isDeletionPresented(for: source),
            titleVisibility: .visible,
            presenting: screen.pendingDeletionItems
        ) { removing in
            Button("삭제", role: .destructive) { screen.remove(removing, source: source) }
        } message: { _ in
            screen.deletionMessage
        }
    }
}

// MARK: - Detail

/// 항목의 원문 전체를 하프 시트에서 스크롤로 보여주는 화면. 위로 밀어 올리면 전체 높이가 된다.
/// "편집"을 누르면 같은 시트 안에서 내용을 고쳐 저장한다. 키보드 패널에는 편집이 없다
private struct ClipboardHistoryDetailView: View {
    let item: ClipboardHistoryItem
    let imageStore: ClipboardImageStore?
    /// 고정 한도에 여유가 있는지. 없으면 미고정 항목의 고정 버튼을 숨긴다
    let canPin: Bool
    /// 정책상 저장할 수 있는 내용인지(빈 값·길이·중복·원문과 같음)
    let canSave: (String) -> Bool
    let onTogglePin: () -> Void
    let onCopy: () -> Void
    /// 저장 성공 여부를 돌려준다. 실패하면 항목이 이미 지워진 것이고 소유자가 삭제 알림을 켠다
    let onSave: (String) -> Bool
    /// 시트가 열린 사이 항목이 지워졌음을 소유자가 알려 준다. 뜨는 순간 편집을 끝내고, 확인하면 시트를 닫는다
    @Binding var isItemDeletedAlertPresented: Bool

    @State private var isEditing = false
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// 화면 해상도까지 디코드한 원본. body 평가마다 다시 디코드하지 않도록 한 번만 읽어 둔다
    @State private var previewImage: UIImage?

    private var text: String { item.text ?? "" }

    /// 원본을 화면 해상도(`appPreviewMaxPixelSize`)까지 백그라운드에서 디코드한다. 시트 표시 애니메이션을 막지 않는다
    private func loadPreviewImage() async -> UIImage? {
        guard let reference = item.image, let imageStore else { return nil }
        return await Task.detached(priority: .userInitiated) {
            imageStore
                .previewImage(for: reference, maxPixelSize: ClipboardImagePolicy.appPreviewMaxPixelSize)
                .map { UIImage(cgImage: $0) }
        }.value
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    TextEditor(text: $draft)
                        // 시트 배경 위에 흰 사각형이 뜨지 않도록 편집기 배경을 비운다
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal)
                } else if item.image != nil {
                    // 스크롤 없이 시트 안에 이미지 전체가 들어오도록 남은 영역에 맞춘다
                    Group {
                        if let previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    // SwiftUI Text의 선택은 코드로 해제할 수 없어 UITextView로 보여준다. 키보드 패널 상세와 같은 선택·링크 규칙이다
                    ClipboardHistoryDetailTextView(
                        text: text,
                        url: ClipboardHistoryPolicy.openableURL(in: text),
                        onOpenURL: { openURL($0) }
                    )
                }
            }
            .navigationTitle(isEditing ? "편집" : (item.image != nil ? "이미지" : "상세"))
            .navigationBarTitleDisplayMode(.inline)
            // 시트가 열린 사이 키보드가 항목을 지운 경우. 알림이 뜨는 시점에 편집기를 없애 두어야 알림이 닫힐 때 편집기가 포커스를
            // 되찾아 키보드가 시트를 밀어 올렸다 내려가는 튐이 생기지 않는다. 확인하면 더 보여줄 것이 없으므로 시트를 닫는다
            .onChange(of: isItemDeletedAlertPresented) { if $0 { isEditing = false } }
            .alert("항목이 삭제되었습니다", isPresented: $isItemDeletedAlertPresented) {
                Button("확인") { dismiss() }
            }
            .task(id: item.id) {
                let image = await loadPreviewImage()
                // 항목이 바뀌어 취소된 디코드 결과가 새 항목을 덮어쓰지 않게 한다
                guard !Task.isCancelled else { return }
                previewImage = image
            }
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { isEditing = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            // 거부되면(앱이 활성인 채로 항목이 지워진 경우) 소유자가 삭제 알림을 켠다
                            if onSave(draft) { isEditing = false }
                        }
                        .disabled(!canSave(draft))
                    }
                } else {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        if item.isPinned || canPin {
                            Button(action: onTogglePin) {
                                // 현재 상태를 보여준다: 고정이면 채운 핀, 아니면 빈 핀
                                Label(
                                    item.isPinned ? "고정 해제" : "고정",
                                    systemImage: item.isPinned ? "pin.fill" : "pin"
                                )
                            }
                        }
                        if let reference = item.image, let url = imageStore?.originalURL(for: reference) {
                            ShareLink(item: url) {
                                Label("공유", systemImage: "square.and.arrow.up")
                            }
                        } else {
                            ShareLink(item: text) {
                                Label("공유", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: onCopy) {
                            Label("복사", systemImage: "doc.on.doc")
                        }
                        // 이미지는 편집하지 않는다
                        if item.image == nil {
                            Button {
                                draft = text
                                isEditing = true
                            } label: {
                                Label("편집", systemImage: "pencil.line")
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Detail Text

/// 원문 본문. 편집 없이 선택·복사만 허용한다.
/// 선택이 있을 때 선택 밖을 탭하면 선택만 풀리고, 선택이 없을 때 본문 전체가 URL이면 글자 영역을 탭해 연다.
/// 키보드 패널 상세(`ClipboardHistoryPanelView`의 상세 뷰)와 같은 규칙이다
private struct ClipboardHistoryDetailTextView: UIViewRepresentable {
    let text: String
    let url: URL?
    let onOpenURL: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.delegate = context.coordinator
        textView.addGestureRecognizer(tapGesture)
        context.coordinator.textView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.url = url
        context.coordinator.onOpenURL = onOpenURL
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label
        ]
        if url != nil {
            // 텍스트 전체가 URL이면 일반 링크처럼 파란 밑줄로 그린다
            attributes[.foregroundColor] = UIColor.link
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        // SwiftUI가 다시 그릴 때마다 교체하면 선택이 풀리므로 내용이 바뀐 경우에만 넣는다
        guard textView.attributedText != attributedText else { return }
        textView.attributedText = attributedText
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var textView: UITextView?
        var url: URL?
        var onOpenURL: ((URL) -> Void)?

        /// 글자가 있는 영역을 탭했을 때만 연다. 빈 여백 탭은 무시한다
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let textView, let url else { return }
            let point = recognizer.location(in: textView)
            let inset = textView.textContainerInset
            let usedRect = textView.layoutManager.usedRect(for: textView.textContainer)
                .offsetBy(dx: inset.left, dy: inset.top)
            guard usedRect.contains(point) else { return }
            onOpenURL?(url)
        }

        /// 선택 영역이 있을 때의 탭은 선택 해제로 쓰이므로 링크를 열지 않는다
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return (textView?.selectedRange.length ?? 0) == 0
        }

        /// 본문 선택용 텍스트 뷰 제스처(길게 누르기·두 번 탭·선택 해제 탭)를 막지 않는다
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}

// MARK: - Preview

#Preview {
    ClipboardHistorySettingsView()
}

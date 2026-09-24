//
//  ClipboardHistoryPasteboardSynchronizer.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/9/26.
//

import UIKit
import OSLog

/// 동기화기가 쓰는 pasteboard 읽기 동작. `UIPasteboard`가 그대로 만족하며, 접근이 거부된 상태처럼
/// 실제 `UIPasteboard`로는 만들 수 없는 조합을 테스트에서 재현하기 위한 이음매다
public protocol ClipboardPasteboard: AnyObject {
    var changeCount: Int { get }
    var hasStrings: Bool { get }
    var hasImages: Bool { get }
    var string: String? { get }
    var types: [String] { get }
    var itemProviders: [NSItemProvider] { get }
    func contains(pasteboardTypes: [String]) -> Bool
}

extension UIPasteboard: ClipboardPasteboard {}

/// 시스템 pasteboard의 최신 텍스트 또는 이미지를 클립보드 기록에 반영한다. 키보드 extension과 앱이 함께 쓴다
///
/// `changeCount`와 `hasStrings`·`hasImages`·`types` 확인은 iOS 16 붙여넣기 권한 알림을 띄우지 않고,
/// `.string` 읽기와 이미지 데이터 읽기만 띄울 수 있다. 설정 ON·Full Access·미리보기 여부 확인은 호출 측 책임이다.
/// 텍스트가 있으면 텍스트만 기록하고, 텍스트가 없을 때만 이미지를 기록한다
public enum ClipboardHistoryPasteboardSynchronizer {

    /// 비밀번호 관리자가 비밀 항목에 붙이는 pasteboard 타입. 이 타입이 있으면 기록하지 않는다
    public static let concealedPasteboardType = "org.nspasteboard.ConcealedType"
    /// 이미지 항목이 기록된 직후 main 스레드에서 게시한다. 저장은 백그라운드에서 끝나므로 키보드 패널과 앱 목록 화면은
    /// 이 알림으로 목록을 다시 읽는다. 앱은 활성화 동기화(`SYKeyboardApp`)와 목록 화면이 분리돼 있어 콜백으로는 닿지 않는다
    public static let didRecordImageNotification = Notification.Name("ClipboardHistoryPasteboardSynchronizer.didRecordImage")
    /// 이미지가 예산 초과로 건너뛰어져 앱의 재시도에 맡겨진 직후 main 스레드에서 게시한다. 기록 알림의 짝이 되는 결과 이벤트다
    public static let didSkipImageForBudgetNotification = Notification.Name("ClipboardHistoryPasteboardSynchronizer.didSkipImageForBudget")

    /// 이 프로세스가 마지막으로 확인한 changeCount. 프로세스마다 changeCount가 다르게 보일 수 있어
    /// App Group이 아니라 프로세스(번들)별 `UserDefaults.standard`에 둔다
    static var processLastSeenPasteboardChangeCount: Int {
        get {
            UserDefaults.standard.object(forKey: UserDefaultsKeys.processLastSeenPasteboardChangeCount) as? Int
            ?? DefaultValues.lastSeenPasteboardChangeCount
        }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.processLastSeenPasteboardChangeCount) }
    }

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle", category: "ClipboardHistoryPasteboardSynchronizer"
    )

    /// 해시·썸네일 생성을 자판 입력(main)과 경쟁하지 않는 낮은 우선순위로, 한 번에 하나씩 처리한다
    private static let imageProcessingQueue = DispatchQueue(
        label: "com.snmac.sykeyboard.clipboard-image-processing",
        qos: .utility
    )

    /// pasteboard의 `changeCount`가 이 프로세스가 마지막으로 확인한 값과도, 앱·키보드가 직접 쓴 값과도 다를 때만
    /// 내용을 읽어 `store`에 기록한다
    ///
    /// 키보드가 디코드 예산 초과로 건너뛴 이미지는 `budgetSkippedPasteboardChangeCount`에 남고, `retriesBudgetSkipped`가 참인
    /// 호출(앱)은 그 changeCount를 이미 확인했더라도 한 번 더 읽어 앱 예산으로 저장하고, 건너뛴 이미지가 없으면 아예 읽지 않는다.
    ///
    /// - Parameters:
    ///   - decodeMemoryBudget: 이 프로세스가 썸네일 디코드에 쓸 수 있는 예산. 키보드는 기본값, 앱은 `appDecodeMemoryBudget`을 넘긴다
    ///   - retriesBudgetSkipped: 건너뛴 이미지가 남아 있을 때만 읽고 앱 예산으로 다시 시도할지.
    ///   pasteboard가 바뀌었다는 보장 없이 부르는 앱 경로(화면 진입·활성화)가 참을 넘긴다
    ///
    /// 이미지 저장은 백그라운드에서 끝나며 결과는 `didRecordImageNotification`·`didSkipImageForBudgetNotification`으로 알린다.
    /// 텍스트 기록은 동기라 알림이 없다
    public static func synchronizeIfNeeded(
        store: ClipboardHistoryStore,
        pasteboard: any ClipboardPasteboard = UIPasteboard.general,
        settings: UserDefaultsManager = .shared,
        decodeMemoryBudget: Int = ClipboardImagePolicy.keyboardDecodeMemoryBudget,
        retriesBudgetSkipped: Bool = false
    ) {
        let changeCount = pasteboard.changeCount
        // changeCount 0은 pasteboard 접근이 거부됐다는 신호다. 키보드 extension이 foreground가 되기 전에 읽으면
        // pasted가 거부하는데(`PBErrorDomain Code=10`), 이때 changeCount는 0이면서 hasStrings는 참이라 내용 유무로는
        // 걸러지지 않는다. 0을 확인값으로 저장하면 원래 값으로 돌아왔을 때 이미 기록한 내용을 다시 읽는다(#154).
        // 재부팅 직후 changeCount가 0인 첫 복사 하나는 놓치지만, 그 대가로 거부 상태의 반복 읽기를 없앤다
        guard changeCount != 0 else {
            logger.notice("pasteboard 접근이 거부돼(changeCount 0) 동기화를 건너뜀")
            return
        }
        let budgetSkippedChangeCount = settings.budgetSkippedPasteboardChangeCount
        let isBudgetRetry = retriesBudgetSkipped && changeCount == budgetSkippedChangeCount
        // pasteboard가 바뀌었다는 보장 없이 부르는 쪽(앱의 화면 진입·활성화)만 `retriesBudgetSkipped`를 넘긴다.
        // 맥북에서 복사한 원격 항목은 프로세스마다 권한이 새로 필요해 읽을 때마다 배너가 뜨므로, 그런 호출은
        // 키보드가 예산 초과로 건너뛴 이미지가 남아 있을 때만 읽는다(#154). 프로세스마다 changeCount가
        // 다르게 보여(#145) 표시와 정확히 일치하지 않을 수 있으므로 표시의 유무만 본다
        let hasBudgetSkippedImage = budgetSkippedChangeCount != DefaultValues.budgetSkippedPasteboardChangeCount
        guard !retriesBudgetSkipped || hasBudgetSkippedImage else { return }
        // 앱과 키보드 extension은 같은 순간에도 서로 다른 changeCount를 본다(#145). 그래서 확인한 값은 이 프로세스에만
        // 남긴다. 공유 값에 쓰면 다른 프로세스가 그 값을 자기 카운터와 비교해, 같은 내용을 다시 읽어 배너를 반복해 띄우거나
        // 우연히 같은 값이 된 새 복사를 건너뛴다. 공유 값은 앱·키보드가 pasteboard에 직접 쓴 직후에만 맞춰 두고 여기서는 비교만 한다
        let processLastSeen = processLastSeenPasteboardChangeCount
        let hasSeen = changeCount == settings.lastSeenPasteboardChangeCount || changeCount == processLastSeen
        guard !hasSeen || isBudgetRetry else {
            if processLastSeen != changeCount { processLastSeenPasteboardChangeCount = changeCount }
            return
        }
        // 텍스트도 이미지도 없게 보일 때는 확인한 값으로 치지 않는다. 키보드는 잠시 이렇게 보였다가 원래 값으로 돌아오는데,
        // 이 값을 저장하면 돌아왔을 때 이미 기록한 내용을 다시 읽는다. 읽을 것이 없으므로 기록에는 영향이 없다
        guard pasteboard.hasStrings || pasteboard.hasImages else { return }
        // 내용이 있는데 이 프로세스가 본 값보다 작으면 재부팅이나 프로세스별 카운터 차이다. 확인값이 우연히 겹쳐
        // 새 복사를 건너뛰는 일이 실제로 생길 수 있는지 보려고 남긴다(#145)
        if processLastSeen >= 0, changeCount < processLastSeen {
            logger.notice("changeCount 역행: \(processLastSeen) → \(changeCount)")
        }
        // 읽기 실패나 저장 제외여도 같은 값을 반복해 읽지 않도록 먼저 갱신한다. 건너뜀 표시도 여기서 소비한다
        processLastSeenPasteboardChangeCount = changeCount
        settings.budgetSkippedPasteboardChangeCount = DefaultValues.budgetSkippedPasteboardChangeCount

        guard !pasteboard.contains(pasteboardTypes: [concealedPasteboardType]) else { return }

        if pasteboard.hasStrings {
            if let text = pasteboard.string { store.record(text) }
            return
        }

        guard pasteboard.hasImages,
              settings.isClipboardImageHistoryEnabled,
              let imageStore = store.imageStore,
              let typeIdentifier = ClipboardImagePolicy.storableType(in: pasteboard.types),
              let itemProvider = pasteboard.itemProviders.first else { return }

        // 파일로 받아 프로세스 메모리에 바이트를 올리지 않는다. 완료 클로저는 시스템이 정한 백그라운드 스레드에서 오며
        // 시스템 임시 파일은 클로저가 끝나면 사라지므로 그 안에서는 우리 tmp로 옮기기만 하고(rename 한 번),
        // 해시·썸네일은 utility 큐에서 순차 처리해 키보드 입력 응답에 영향을 주지 않게 한다
        itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, _ in
            guard let url,
                  let stagedURL = ClipboardImageStore.stage(temporaryFileURL: url, typeIdentifier: typeIdentifier) else { return }
            imageProcessingQueue.async {
                // 헤더의 픽셀 수로 예상 디코드 메모리를 구해 이 프로세스의 예산 안일 때만 썸네일을 만든다
                let outcome = imageStore.storeOutcome(
                    temporaryFileURL: stagedURL, typeIdentifier: typeIdentifier, decodeMemoryBudget: decodeMemoryBudget
                )
                DispatchQueue.main.async {
                    switch outcome {
                    case .stored(let reference):
                        store.record(.image(reference))
                        // object는 기록한 store. 같은 프로세스에서 다른 store(테스트 호스트 앱)가 게시한 알림과 구분할 수 있게 한다
                        NotificationCenter.default.post(name: didRecordImageNotification, object: store)
                    case .skippedForBudget:
                        // 다시 시도하는 쪽(앱)이 또 건너뛰면 표시하지 않아 활성화마다 반복하지 않는다
                        if !retriesBudgetSkipped { settings.budgetSkippedPasteboardChangeCount = changeCount }
                        NotificationCenter.default.post(name: didSkipImageForBudgetNotification, object: store)
                    case .rejected:
                        break
                    }
                }
            }
        }
    }
}

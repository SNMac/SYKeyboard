//
//  ClipboardHistoryPasteboardSynchronizer.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/9/26.
//

import UIKit
import os

/// 시스템 pasteboard의 최신 텍스트 또는 이미지를 클립보드 기록에 반영한다. 키보드 extension과 앱이 함께 쓴다
///
/// `changeCount`와 `hasStrings`·`hasImages`·`types` 확인은 iOS 16 붙여넣기 권한 알림을 띄우지 않고,
/// `.string` 읽기와 이미지 데이터 읽기만 띄울 수 있다. 설정 ON·Full Access·미리보기 여부 확인은 호출 측 책임이다.
/// 텍스트가 있으면 텍스트만 기록하고, 텍스트가 없을 때만 이미지를 기록한다
public enum ClipboardHistoryPasteboardSynchronizer {

    /// 비밀번호 관리자가 비밀 항목에 붙이는 pasteboard 타입. 이 타입이 있으면 기록하지 않는다
    public static let concealedPasteboardType = "org.nspasteboard.ConcealedType"

    /// 해시·썸네일 생성을 자판 입력(main)과 경쟁하지 않는 낮은 우선순위로, 한 번에 하나씩 처리한다
    private static let imageProcessingQueue = DispatchQueue(
        label: "com.snmac.sykeyboard.clipboard-image-processing",
        qos: .utility
    )

    /// pasteboard의 `changeCount`가 마지막 확인값과 다를 때만 내용을 읽어 `store`에 기록한다
    ///
    /// - Parameters:
    ///   - availableMemory: 캡처 전 남은 메모리(바이트). 기본은 `os_proc_available_memory()`
    ///   - onImageRecorded: 이미지 항목이 기록된 직후 메인 큐에서 한 번 호출된다. 텍스트 기록이나 건너뜀에서는 부르지 않는다
    public static func synchronizeIfNeeded(
        store: ClipboardHistoryStore,
        pasteboard: UIPasteboard = .general,
        settings: UserDefaultsManager = .shared,
        availableMemory: @escaping () -> Int = { Int(os_proc_available_memory()) },
        onImageRecorded: (() -> Void)? = nil
    ) {
        let changeCount = pasteboard.changeCount
        guard changeCount != settings.lastSeenPasteboardChangeCount else { return }
        // 읽기 실패나 저장 제외여도 같은 값을 반복해 읽지 않도록 먼저 갱신한다
        settings.lastSeenPasteboardChangeCount = changeCount

        guard !pasteboard.contains(pasteboardTypes: [concealedPasteboardType]) else { return }

        if pasteboard.hasStrings {
            if let text = pasteboard.string { store.record(text) }
            return
        }

        guard pasteboard.hasImages,
              settings.isClipboardImageHistoryEnabled,
              let imageStore = store.imageStore,
              let typeIdentifier = ClipboardImagePolicy.storableType(in: pasteboard.types),
              ClipboardImagePolicy.hasEnoughMemory(available: availableMemory()),
              let itemProvider = pasteboard.itemProviders.first else { return }

        // 파일로 받아 프로세스 메모리에 바이트를 올리지 않는다. 완료 클로저는 시스템이 정한 백그라운드 스레드에서 오며
        // 시스템 임시 파일은 클로저가 끝나면 사라지므로 그 안에서는 우리 tmp로 옮기기만 하고(rename 한 번),
        // 해시·썸네일은 utility 큐에서 순차 처리해 키보드 입력 응답에 영향을 주지 않게 한다
        itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, _ in
            guard let url,
                  let stagedURL = ClipboardImageStore.stage(temporaryFileURL: url, typeIdentifier: typeIdentifier) else { return }
            imageProcessingQueue.async {
                // 큐에서 기다리는 사이 상황이 바뀔 수 있으므로 무거운 디코드 직전에 다시 확인한다
                guard ClipboardImagePolicy.hasEnoughMemory(available: availableMemory()) else {
                    try? FileManager.default.removeItem(at: stagedURL)
                    return
                }
                guard let reference = imageStore.store(temporaryFileURL: stagedURL, typeIdentifier: typeIdentifier) else { return }
                DispatchQueue.main.async {
                    store.record(.image(reference))
                    onImageRecorded?()
                }
            }
        }
    }
}

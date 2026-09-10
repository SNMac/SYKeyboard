//
//  ClipboardImageStore.swift
//  SYKeyboardCore
//
//  Created by Claude on 9/10/26.
//

import CryptoKit
import Foundation
import ImageIO
import OSLog
import UniformTypeIdentifiers

/// 클립보드 이미지의 원본과 썸네일을 App Group 컨테이너의 `ClipboardImages/`에 해시 이름으로 저장하는 저장소
///
/// UIKit을 쓰지 않는다. 한 번에 올리는 메모리는 64 KB 해시 버퍼와 썸네일 디코드뿐이다.
/// 세 keyboard extension과 앱이 같은 디렉터리를 쓰며, 파일명이 해시라 동시에 같은 이미지를 저장해도 같은 파일이다
public final class ClipboardImageStore {

    // MARK: - Properties

    private let directoryURL: URL
    private let maxByteSize: Int
    private let maxPixelCount: Int
    private let maxPNGPixelCount: Int
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Unknown Bundle",
        category: "ClipboardImageStore"
    )

    private static let hashChunkSize = 64 * 1_024

    // MARK: - Initializer

    init(
        directoryURL: URL,
        maxByteSize: Int = ClipboardImagePolicy.maxByteSize,
        maxPixelCount: Int = ClipboardImagePolicy.maxPixelCount,
        maxPNGPixelCount: Int = ClipboardImagePolicy.maxPNGPixelCount
    ) {
        self.directoryURL = directoryURL
        self.maxByteSize = maxByteSize
        self.maxPixelCount = maxPixelCount
        self.maxPNGPixelCount = maxPNGPixelCount
    }

    /// App Group 컨테이너를 얻지 못하면 `nil`. 호출 측은 이미지 저장을 건너뛴다
    public convenience init?() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: DefaultValues.groupBundleID
        ) else { return nil }
        self.init(directoryURL: containerURL.appendingPathComponent("ClipboardImages", isDirectory: true))
    }

    // MARK: - Public Methods

    /// 임시 파일의 이미지를 검사·해시·저장하고 참조를 돌려준다. 저장 대상이 아니면 `nil`이고 새 파일을 남기지 않는다.
    /// 백그라운드 스레드에서 부른다. 임시 파일은 성공 시 옮겨져 사라진다
    public func store(temporaryFileURL: URL, typeIdentifier: String) -> ClipboardImageReference? {
        // 1. 파일 크기. 바이트를 메모리에 올리지 않는다
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: temporaryFileURL.path),
              let byteSize = attributes[.size] as? Int,
              byteSize > 0, byteSize <= maxByteSize else { return nil }

        // 2. 헤더의 픽셀 크기. 회전(5~8)이면 표시 기준으로 폭·높이를 바꾼다
        guard let source = CGImageSourceCreateWithURL(temporaryFileURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let rawWidth = properties[kCGImagePropertyPixelWidth] as? Int,
              let rawHeight = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        let (pixelWidth, pixelHeight) = orientation >= 5 ? (rawHeight, rawWidth) : (rawWidth, rawHeight)
        // PNG는 썸네일 생성 시 전체 디코드될 수 있어 더 낮은 상한을 쓴다
        let pixelLimit = typeIdentifier == "public.png" ? maxPNGPixelCount : maxPixelCount
        guard pixelWidth > 0, pixelHeight > 0, pixelWidth * pixelHeight <= pixelLimit else { return nil }

        // 3. 스트리밍 해시
        guard let hash = ClipboardImageStore.sha256Hex(of: temporaryFileURL) else { return nil }
        let reference = ClipboardImageReference(
            hash: hash,
            typeIdentifier: typeIdentifier,
            byteSize: byteSize,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight
        )

        // 4. 원본 이동. 이미 있으면 같은 바이트이므로 건너뛴다
        let originalURL = originalURL(for: reference)
        let originalExisted = FileManager.default.fileExists(atPath: originalURL.path)
        if !originalExisted {
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: temporaryFileURL, to: originalURL)
            } catch {
                // 다른 프로세스가 먼저 저장했으면 성공으로 본다
                guard FileManager.default.fileExists(atPath: originalURL.path) else {
                    logger.error("클립보드 이미지 원본 저장 실패: \(error.localizedDescription)")
                    return nil
                }
            }
        }

        // 5. 썸네일. 실패하면 이번에 옮긴 원본을 지운다
        let thumbnailURL = thumbnailURL(for: reference)
        if !FileManager.default.fileExists(atPath: thumbnailURL.path),
           !writeThumbnail(from: originalURL, to: thumbnailURL) {
            if !originalExisted { try? FileManager.default.removeItem(at: originalURL) }
            logger.error("클립보드 이미지 썸네일 생성 실패")
            return nil
        }

        return reference
    }

    public func originalURL(for reference: ClipboardImageReference) -> URL {
        return directoryURL.appendingPathComponent(
            "\(reference.hash).\(ClipboardImagePolicy.fileExtension(for: reference.typeIdentifier))"
        )
    }

    public func thumbnailURL(for reference: ClipboardImageReference) -> URL {
        return directoryURL.appendingPathComponent("\(reference.hash).thumb.jpg")
    }

    /// 원본을 긴 변 `maxPixelSize`까지만 디코드한 미리보기. 회전을 적용한다. 파일이 없거나 손상됐으면 `nil`
    public func previewImage(for reference: ClipboardImageReference, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(originalURL(for: reference) as CFURL, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, ClipboardImageStore.thumbnailOptions(maxPixelSize: maxPixelSize))
    }

    /// 항목이 지워질 때 원본·썸네일을 함께 지운다. 없는 파일은 무시한다
    public func removeFiles(for hashes: Set<String>) {
        guard !hashes.isEmpty,
              let files = try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path) else { return }
        for file in files where hashes.contains(String(file.prefix { $0 != "." })) {
            try? FileManager.default.removeItem(at: directoryURL.appendingPathComponent(file))
        }
    }

    public func removeAllFiles() {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}

// MARK: - Private Methods

private extension ClipboardImageStore {
    /// 64 KB씩 읽어 계산한 SHA-256 hex. 파일을 통째로 올리지 않는다
    static func sha256Hex(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try? handle.read(upToCount: hashChunkSize), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func thumbnailOptions(maxPixelSize: Int) -> CFDictionary {
        return [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ] as CFDictionary
    }

    /// ImageIO 다운샘플링으로 썸네일을 만들어 JPEG로 쓴다. JPEG·HEIC는 축소 디코드라 작고 PNG는 전체 디코드일 수 있다
    func writeThumbnail(from originalURL: URL, to thumbnailURL: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(originalURL as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(
                source, 0, ClipboardImageStore.thumbnailOptions(maxPixelSize: ClipboardImagePolicy.thumbnailMaxPixelSize)
              ),
              let destination = CGImageDestinationCreateWithURL(
                thumbnailURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil
              ) else { return false }
        CGImageDestinationAddImage(destination, thumbnail, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }
}

//
//  ClipboardImageStoreTests.swift
//  SYKeyboardTests
//
//  Created by Claude on 9/10/26.
//

import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import SYKeyboardCore

@Suite("클립보드 이미지 파일 저장소 검증")
struct ClipboardImageStoreTests {

    @Test("PNG 임시 파일을 저장하면 해시 이름의 원본과 썸네일이 생기고 참조가 돌아옴")
    func testPNG저장은_해시원본과썸네일생성() throws {
        let fixture = makeFixture(name: "png")
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 640, height: 480, type: .png, name: "src")
        let expectedHash = SHA256.hash(data: try Data(contentsOf: temporary)).map { String(format: "%02x", $0) }.joined()
        let expectedSize = try FileManager.default.attributesOfItem(atPath: temporary.path)[.size] as? Int

        let reference = try #require(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.png"))

        #expect(reference.hash == expectedHash)
        #expect(reference.typeIdentifier == "public.png")
        #expect(reference.byteSize == expectedSize)
        #expect(reference.pixelWidth == 640)
        #expect(reference.pixelHeight == 480)
        #expect(fixture.store.originalURL(for: reference).lastPathComponent == "\(expectedHash).png")
        #expect(fixture.store.thumbnailURL(for: reference).lastPathComponent == "\(expectedHash).thumb.jpg")
        #expect(FileManager.default.fileExists(atPath: fixture.store.originalURL(for: reference).path))
        #expect(FileManager.default.fileExists(atPath: fixture.store.thumbnailURL(for: reference).path))
        // 임시 파일은 옮겨져 사라진다
        #expect(FileManager.default.fileExists(atPath: temporary.path) == false)

        // 썸네일은 긴 변이 정책 크기 이하
        let source = try #require(CGImageSourceCreateWithURL(fixture.store.thumbnailURL(for: reference) as CFURL, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let width = try #require(properties[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(properties[kCGImagePropertyPixelHeight] as? Int)
        #expect(max(width, height) == ClipboardImagePolicy.thumbnailMaxPixelSize)
        #expect(width > height)
    }

    @Test("같은 바이트를 두 번 저장하면 파일은 하나이고 두 번째도 같은 참조")
    func test같은바이트_두번저장은_파일하나() throws {
        let fixture = makeFixture(name: "dedupe")
        defer { fixture.cleanUp() }
        let first = try makeImageFile(width: 20, height: 20, type: .jpeg, name: "a")
        let second = try makeImageFile(width: 20, height: 20, type: .jpeg, name: "b")

        let firstReference = try #require(fixture.store.store(temporaryFileURL: first, typeIdentifier: "public.jpeg"))
        let secondReference = try #require(fixture.store.store(temporaryFileURL: second, typeIdentifier: "public.jpeg"))

        #expect(firstReference == secondReference)
        let files = try FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)
        #expect(files.sorted() == ["\(firstReference.hash).jpg", "\(firstReference.hash).thumb.jpg"])
    }

    @Test("바이트 한도를 넘는 파일은 저장하지 않고 파일을 남기지 않음")
    func test바이트한도초과는_저장안함() throws {
        let fixture = makeFixture(name: "too-big", maxByteSize: 64)
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 400, height: 400, type: .png, name: "big")

        #expect(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.png") == nil)
        #expect(((try? FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)) ?? []).isEmpty)
    }

    @Test("픽셀 한도를 넘는 JPEG는 헤더만 읽고 저장하지 않음")
    func test픽셀한도초과는_저장안함() throws {
        let fixture = makeFixture(name: "too-many-pixels", maxPixelCount: 100)
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 20, height: 20, type: .jpeg, name: "pixels")

        #expect(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.jpeg") == nil)
        #expect(((try? FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)) ?? []).isEmpty)
    }

    @Test("PNG 전용 픽셀 한도는 PNG에만 적용되고 JPEG는 일반 한도를 따름")
    func testPNG전용픽셀한도() throws {
        let fixture = makeFixture(name: "png-pixels", maxPixelCount: 1_000, maxPNGPixelCount: 100)
        defer { fixture.cleanUp() }
        let png = try makeImageFile(width: 20, height: 20, type: .png, name: "png")
        let jpeg = try makeImageFile(width: 20, height: 20, type: .jpeg, name: "jpeg")

        #expect(fixture.store.store(temporaryFileURL: png, typeIdentifier: "public.png") == nil)
        #expect(fixture.store.store(temporaryFileURL: jpeg, typeIdentifier: "public.jpeg") != nil)
        let files = try FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)
        #expect(files.count == 2)
        #expect(files.allSatisfy { $0.hasSuffix(".jpg") })
    }

    @Test("stage는 시스템 임시 파일을 우리 tmp로 옮기고, 거부된 파일은 store가 지움")
    func testStage후_거부되면_임시파일정리() throws {
        let fixture = makeFixture(name: "stage", maxByteSize: 64)
        defer { fixture.cleanUp() }
        let systemTemporary = try makeImageFile(width: 400, height: 400, type: .png, name: "sys")

        let staged = try #require(ClipboardImageStore.stage(temporaryFileURL: systemTemporary, typeIdentifier: "public.png"))

        #expect(staged.pathExtension == "png")
        #expect(FileManager.default.fileExists(atPath: systemTemporary.path) == false)
        #expect(FileManager.default.fileExists(atPath: staged.path))

        #expect(fixture.store.store(temporaryFileURL: staged, typeIdentifier: "public.png") == nil)
        #expect(FileManager.default.fileExists(atPath: staged.path) == false)
        #expect(((try? FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)) ?? []).isEmpty)
    }

    @Test("같은 바이트를 다시 저장하면 두 번째 임시 파일도 지움")
    func test중복저장은_두번째임시파일도정리() throws {
        let fixture = makeFixture(name: "dedupe-cleanup")
        defer { fixture.cleanUp() }
        let first = try makeImageFile(width: 20, height: 20, type: .jpeg, name: "a")
        let second = try makeImageFile(width: 20, height: 20, type: .jpeg, name: "b")

        _ = try #require(fixture.store.store(temporaryFileURL: first, typeIdentifier: "public.jpeg"))
        _ = try #require(fixture.store.store(temporaryFileURL: second, typeIdentifier: "public.jpeg"))

        #expect(FileManager.default.fileExists(atPath: second.path) == false)
    }

    @Test("이미지가 아닌 파일은 저장하지 않음")
    func test손상파일은_저장안함() throws {
        let fixture = makeFixture(name: "corrupt")
        defer { fixture.cleanUp() }
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).png")
        try Data("not an image".utf8).write(to: temporary)

        #expect(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.png") == nil)
        #expect(((try? FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)) ?? []).isEmpty)
    }

    @Test("EXIF 회전이 있는 JPEG는 표시 기준으로 폭·높이를 바꿔 기록")
    func testEXIF회전은_폭높이교환() throws {
        let fixture = makeFixture(name: "orientation")
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 60, height: 40, type: .jpeg, name: "rotated", orientation: 6)

        let reference = try #require(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.jpeg"))

        #expect(reference.pixelWidth == 40)
        #expect(reference.pixelHeight == 60)
    }

    @Test("미리보기는 긴 변을 요청 크기까지만 디코드")
    func test미리보기는_요청크기까지만() throws {
        let fixture = makeFixture(name: "preview")
        defer { fixture.cleanUp() }
        let temporary = try makeImageFile(width: 800, height: 200, type: .png, name: "wide")
        let reference = try #require(fixture.store.store(temporaryFileURL: temporary, typeIdentifier: "public.png"))

        let preview = try #require(fixture.store.previewImage(for: reference, maxPixelSize: 100))

        #expect(preview.width == 100)
        #expect(preview.height == 25)
    }

    @Test("해시로 지우면 원본·썸네일이 함께 지워지고 없는 해시는 무시")
    func test해시삭제는_원본썸네일함께제거() throws {
        let fixture = makeFixture(name: "remove")
        defer { fixture.cleanUp() }
        let keep = try #require(fixture.store.store(temporaryFileURL: try makeImageFile(width: 10, height: 10, type: .png, name: "keep"), typeIdentifier: "public.png"))
        let gone = try #require(fixture.store.store(temporaryFileURL: try makeImageFile(width: 11, height: 11, type: .png, name: "gone"), typeIdentifier: "public.png"))

        fixture.store.removeFiles(for: [gone.hash, "missing"])

        let files = try FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)
        #expect(files.sorted() == ["\(keep.hash).png", "\(keep.hash).thumb.jpg"])

        fixture.store.removeAllFiles()
        #expect(((try? FileManager.default.contentsOfDirectory(atPath: fixture.directoryURL.path)) ?? []).isEmpty)
    }
}

// MARK: - Fixture

private struct ImageStoreFixture {
    let store: ClipboardImageStore
    let directoryURL: URL

    func cleanUp() {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}

private func makeFixture(
    name: String,
    maxByteSize: Int = ClipboardImagePolicy.maxByteSize,
    maxPixelCount: Int = ClipboardImagePolicy.maxPixelCount,
    maxPNGPixelCount: Int = ClipboardImagePolicy.maxPNGPixelCount
) -> ImageStoreFixture {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("SYKeyboardTests-\(UUID().uuidString)-\(name)", isDirectory: true)
    return ImageStoreFixture(
        store: ClipboardImageStore(directoryURL: directoryURL, maxByteSize: maxByteSize, maxPixelCount: maxPixelCount, maxPNGPixelCount: maxPNGPixelCount),
        directoryURL: directoryURL
    )
}

/// 단색 비트맵을 ImageIO로 인코드한 임시 파일. `orientation`은 EXIF 방향 값(1~8)
private func makeImageFile(width: Int, height: Int, type: UTType, name: String, orientation: Int? = nil) throws -> URL {
    let context = try #require(CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    context.setFillColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let image = try #require(context.makeImage())
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(UUID().uuidString)-\(name).\(type.preferredFilenameExtension ?? "img")")
    let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil))
    var properties: [CFString: Any] = [:]
    if let orientation { properties[kCGImagePropertyOrientation] = orientation }
    CGImageDestinationAddImage(destination, image, properties as CFDictionary)
    #expect(CGImageDestinationFinalize(destination))
    return url
}
